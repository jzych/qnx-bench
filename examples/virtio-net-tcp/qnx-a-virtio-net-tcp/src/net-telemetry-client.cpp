#include <arpa/inet.h>
#include <cerrno>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <csignal>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

namespace {

constexpr const char *kDefaultServerIp = "192.168.10.2";
constexpr std::uint16_t kDefaultPort = 5001;
constexpr unsigned kDefaultPeriodMs = 1000;

// Keep log output immediately visible in the QVM console log. The target-side
// verify script greps for the stable "net-telemetry-client:" prefix.
void logf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    std::vprintf(fmt, args);
    va_end(args);
    std::fflush(stdout);
}

void sleep_ms(unsigned ms)
{
    usleep(ms * 1000U);
}

int connect_to_server(const char *server_ip, std::uint16_t port)
{
    // Create a fresh socket for each attempt. A failed connect leaves the
    // socket unusable for the reconnect loop below.
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd == -1) {
        // Without a socket there is nothing useful to retry inside this helper;
        // the caller will delay and start a new attempt.
        logf("net-telemetry-client: socket failed: %s\n", std::strerror(errno));
        return -1;
    }

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);

    // The example intentionally uses fixed IPv4 guest addresses so the QVM
    // topology stays isolated from host networking.
    if (inet_pton(AF_INET, server_ip, &addr.sin_addr) != 1) {
        // Treat bad command-line input the same as a failed connection attempt
        // so the main loop has one simple error path.
        logf("net-telemetry-client: invalid server ip %s\n", server_ip);
        close(fd);
        return -1;
    }

    if (connect(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) == -1) {
        // Guest B may not have finished booting or listening yet. Close this
        // socket and let the caller's reconnect loop create a clean one.
        logf("net-telemetry-client: connect %s:%u failed: %s\n",
             server_ip, static_cast<unsigned>(port), std::strerror(errno));
        close(fd);
        return -1;
    }

    logf("net-telemetry-client: connected server=%s:%u\n",
         server_ip, static_cast<unsigned>(port));
    return fd;
}

bool send_all(int fd, const char *data, std::size_t size)
{
    // TCP send() may accept only part of the record, so keep writing until the
    // newline-delimited telemetry sample has fully entered the socket buffer.
    std::size_t offset = 0;
    while (offset < size) {
        ssize_t sent = send(fd, data + offset, size - offset, 0);
        if (sent == -1) {
            if (errno == EINTR) {
                // Signals can interrupt send() before it transfers data. Retry
                // the same byte range without treating it as a connection loss.
                continue;
            }
            // Other send failures mean this TCP connection can no longer be
            // trusted; return false so the caller reconnects.
            logf("net-telemetry-client: send failed: %s\n", std::strerror(errno));
            return false;
        }
        if (sent == 0) {
            // A zero-length successful send should not happen for a non-empty
            // buffer. Avoid spinning forever if a stack returns it anyway.
            logf("net-telemetry-client: send returned zero\n");
            return false;
        }
        offset += static_cast<std::size_t>(sent);
    }
    return true;
}

} // namespace

int main(int argc, char **argv)
{
    // If Guest B disappears, a write to the TCP socket should fail through
    // send() so the reconnect path can run instead of terminating the process.
    std::signal(SIGPIPE, SIG_IGN);

    const char *server_ip = kDefaultServerIp;
    std::uint16_t port = kDefaultPort;
    unsigned period_ms = kDefaultPeriodMs;

    // Optional arguments make the binary reusable, while the guest start script
    // runs with the locked example defaults from the runbook.
    if (argc > 1) {
        // Override only the remote endpoint address; interface configuration is
        // owned by the guest start script.
        server_ip = argv[1];
    }
    if (argc > 2) {
        unsigned long parsed = std::strtoul(argv[2], nullptr, 0);
        if (parsed > 0 && parsed <= 65535) {
            // Accept only valid TCP port numbers. Invalid input keeps the
            // default so a typo does not prevent the demo from booting.
            port = static_cast<std::uint16_t>(parsed);
        }
    }
    if (argc > 3) {
        unsigned long parsed = std::strtoul(argv[3], nullptr, 0);
        if (parsed > 0) {
            // A positive period prevents a tight telemetry loop from flooding
            // the guest console and target log storage.
            period_ms = static_cast<unsigned>(parsed);
        }
    }

    // Emit the selected endpoint once before the infinite telemetry loop. This
    // line is useful when confirming the guest image contains the expected app.
    logf("net-telemetry-client: start server=%s:%u period_ms=%u\n",
         server_ip, static_cast<unsigned>(port), period_ms);

    int fd = -1;
    for (std::uint32_t seq = 1;; ++seq) {
        // Guest B can still be booting, so keep reconnecting instead of
        // failing the client process on the first refused connection.
        while (fd == -1) {
            fd = connect_to_server(server_ip, port);
            if (fd == -1) {
                // Keep retry cadence human-readable in the QVM logs while
                // Guest B's server is still coming up.
                sleep_ms(1000);
            }
        }

        // Generate deterministic synthetic telemetry. The values change every
        // record so the receiver log proves the TCP stream is live, not stale.
        const std::time_t now = std::time(nullptr);
        const int temperature_mc = 42000 + static_cast<int>(seq % 250);
        const int voltage_mv = 5000 + static_cast<int>(seq % 20);

        char line[256];
        // Each record is one text line so the server can frame messages by
        // newline without needing a binary protocol or length prefix.
        const int len = std::snprintf(line, sizeof(line),
                                      "seq=%u epoch=%lld temp_mc=%d voltage_mv=%d source=guest-a\n",
                                      seq, static_cast<long long>(now),
                                      temperature_mc, voltage_mv);
        if (len <= 0 || static_cast<std::size_t>(len) >= sizeof(line)) {
            // Formatting failure is unexpected, but closing the socket keeps
            // the recovery path identical to a transport failure.
            logf("net-telemetry-client: format failed seq=%u\n", seq);
            close(fd);
            fd = -1;
            continue;
        }

        if (!send_all(fd, line, static_cast<std::size_t>(len))) {
            // Any incomplete write means the stream framing is unreliable.
            // Reconnect before sending the next telemetry sample.
            close(fd);
            fd = -1;
            sleep_ms(1000);
            continue;
        }

        logf("net-telemetry-client: sent %s", line);
        sleep_ms(period_ms);
    }
}

#include <arpa/inet.h>
#include <cerrno>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>

#ifndef UDP_TELEMETRY_ENABLE_ACK
#define UDP_TELEMETRY_ENABLE_ACK 1
#endif

namespace {

constexpr const char *kDefaultServerIp = "192.168.10.2";
constexpr std::uint16_t kDefaultPort = 5002;
constexpr unsigned kDefaultPeriodMs = 1000;
constexpr unsigned kAckTimeoutMs = 500;

// Keep log output immediately visible in the QVM console log. The target-side
// verify script greps for the stable "udp-telemetry-client:" prefix.
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

int open_connected_udp_socket(const char *server_ip, std::uint16_t port)
{
    // A connected UDP socket keeps the send/recv calls simple while still using
    // datagrams, not a stream. No TCP handshake is performed.
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd == -1) {
        logf("udp-telemetry-client: socket failed: %s\n", std::strerror(errno));
        return -1;
    }

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);

    // The example intentionally uses fixed IPv4 guest addresses so the QVM
    // topology stays isolated from host networking.
    if (inet_pton(AF_INET, server_ip, &addr.sin_addr) != 1) {
        logf("udp-telemetry-client: invalid server ip %s\n", server_ip);
        close(fd);
        return -1;
    }

    if (connect(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) == -1) {
        // For UDP, connect() records the default peer and filters inbound ACKs
        // to that peer. It does not prove Guest B is listening.
        logf("udp-telemetry-client: connect peer=%s:%u failed: %s\n",
             server_ip, static_cast<unsigned>(port), std::strerror(errno));
        close(fd);
        return -1;
    }

    logf("udp-telemetry-client: peer=%s:%u ack=%s\n",
         server_ip, static_cast<unsigned>(port),
         UDP_TELEMETRY_ENABLE_ACK ? "on" : "off");
    return fd;
}

bool send_datagram(int fd, const char *data, std::size_t size)
{
    // UDP preserves datagram boundaries. A short successful send would mean the
    // telemetry record was not emitted as one complete datagram.
    const ssize_t sent = send(fd, data, size, 0);
    if (sent == -1) {
        logf("udp-telemetry-client: send failed: %s\n", std::strerror(errno));
        return false;
    }
    if (static_cast<std::size_t>(sent) != size) {
        logf("udp-telemetry-client: short send sent=%d expected=%u\n",
             static_cast<int>(sent), static_cast<unsigned>(size));
        return false;
    }
    return true;
}

void wait_for_ack(int fd, std::uint32_t seq)
{
#if UDP_TELEMETRY_ENABLE_ACK
    fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(fd, &readfds);

    timeval timeout{};
    timeout.tv_sec = kAckTimeoutMs / 1000U;
    timeout.tv_usec = static_cast<suseconds_t>((kAckTimeoutMs % 1000U) * 1000U);

    // ACKs are optional confirmation. A timeout is logged but does not stop the
    // next telemetry datagram because UDP itself is connectionless.
    const int ready = select(fd + 1, &readfds, nullptr, nullptr, &timeout);
    if (ready == -1) {
        if (errno == EINTR) {
            logf("udp-telemetry-client: ack wait interrupted seq=%u\n", seq);
            return;
        }
        logf("udp-telemetry-client: ack wait failed seq=%u: %s\n",
             seq, std::strerror(errno));
        return;
    }
    if (ready == 0) {
        logf("udp-telemetry-client: ack timeout seq=%u\n", seq);
        return;
    }

    char ack[128];
    const ssize_t received = recv(fd, ack, sizeof(ack) - 1, 0);
    if (received == -1) {
        logf("udp-telemetry-client: ack recv failed seq=%u: %s\n",
             seq, std::strerror(errno));
        return;
    }

    ack[received] = '\0';
    logf("udp-telemetry-client: ack seq=%u payload=%s", seq, ack);
#else
    (void)fd;
    (void)seq;
#endif
}

} // namespace

int main(int argc, char **argv)
{
    const char *server_ip = kDefaultServerIp;
    std::uint16_t port = kDefaultPort;
    unsigned period_ms = kDefaultPeriodMs;

    // Optional arguments make the binary reusable, while the guest start script
    // runs with the locked example defaults from the runbook.
    if (argc > 1) {
        server_ip = argv[1];
    }
    if (argc > 2) {
        unsigned long parsed = std::strtoul(argv[2], nullptr, 0);
        if (parsed > 0 && parsed <= 65535) {
            port = static_cast<std::uint16_t>(parsed);
        }
    }
    if (argc > 3) {
        unsigned long parsed = std::strtoul(argv[3], nullptr, 0);
        if (parsed > 0) {
            period_ms = static_cast<unsigned>(parsed);
        }
    }

    const int fd = open_connected_udp_socket(server_ip, port);
    if (fd == -1) {
        return 1;
    }

    for (std::uint32_t seq = 1;; ++seq) {
        const std::time_t now = std::time(nullptr);
        const int temperature_mc = 42000 + static_cast<int>(seq % 250);
        const int voltage_mv = 5000 + static_cast<int>(seq % 20);

        char line[256];
        // Each UDP datagram carries one newline-delimited telemetry record so
        // the receiver can log the payload directly.
        const int len = std::snprintf(line, sizeof(line),
                                      "seq=%u epoch=%lld temp_mc=%d voltage_mv=%d source=guest-a\n",
                                      seq, static_cast<long long>(now),
                                      temperature_mc, voltage_mv);
        if (len <= 0 || static_cast<std::size_t>(len) >= sizeof(line)) {
            logf("udp-telemetry-client: format failed seq=%u\n", seq);
            sleep_ms(period_ms);
            continue;
        }

        if (send_datagram(fd, line, static_cast<std::size_t>(len))) {
            logf("udp-telemetry-client: sent %s", line);
            wait_for_ack(fd, seq);
        }

        sleep_ms(period_ms);
    }
}

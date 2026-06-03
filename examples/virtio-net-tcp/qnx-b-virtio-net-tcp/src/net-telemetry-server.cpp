#include <arpa/inet.h>
#include <cerrno>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

namespace {

constexpr std::uint16_t kDefaultPort = 5001;

// Keep every status line flushed into the QVM log. The target verify script
// depends on the stable "net-telemetry-server:" prefix.
void logf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    std::vprintf(fmt, args);
    va_end(args);
    std::fflush(stdout);
}

int open_listener(std::uint16_t port)
{
    // Bind a plain IPv4 TCP listener inside Guest B. The direct virtio-net link
    // supplies the network path; no host-side vdevpeer interface is involved.
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd == -1) {
        // If the guest networking stack is not available, fail fast so the QVM
        // log clearly shows why no telemetry server is running.
        logf("net-telemetry-server: socket failed: %s\n", std::strerror(errno));
        return -1;
    }

    int reuse = 1;
    // Allow quick reruns after qvm restarts without waiting for old TCP state
    // to age out.
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(port);

    if (bind(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) == -1) {
        // Bind failures usually mean the port is already in use or networking
        // has not finished initializing. Close the descriptor before exiting.
        logf("net-telemetry-server: bind port=%u failed: %s\n",
             static_cast<unsigned>(port), std::strerror(errno));
        close(fd);
        return -1;
    }

    if (listen(fd, 1) == -1) {
        // Without listen(), Guest A cannot connect. Treat it as fatal for this
        // server process and leave a clear log line.
        logf("net-telemetry-server: listen failed: %s\n", std::strerror(errno));
        close(fd);
        return -1;
    }

    logf("net-telemetry-server: listening address=0.0.0.0 port=%u\n",
         static_cast<unsigned>(port));
    return fd;
}

void log_peer(const sockaddr_in &peer)
{
    char peer_ip[INET_ADDRSTRLEN] = {};
    const char *converted = inet_ntop(AF_INET, &peer.sin_addr, peer_ip, sizeof(peer_ip));
    if (converted == nullptr) {
        // Logging should still show a connection event even if address
        // conversion fails for an unexpected peer structure.
        converted = "unknown";
    }
    logf("net-telemetry-server: client connected peer=%s:%u\n",
         converted, static_cast<unsigned>(ntohs(peer.sin_port)));
}

void serve_client(int client_fd)
{
    // TCP is a byte stream, so a recv() can contain partial lines or multiple
    // telemetry records. Keep pending bytes until a newline terminator arrives.
    std::string pending;
    char buf[256];

    for (;;) {
        // This example accepts one client at a time. When Guest A disconnects,
        // return to the accept loop and wait for its reconnect attempt.
        const ssize_t received = recv(client_fd, buf, sizeof(buf), 0);
        if (received == -1) {
            if (errno == EINTR) {
                // Signals can interrupt recv() without changing connection
                // state, so keep waiting for bytes from the same client.
                continue;
            }
            // Other recv errors end this client session; the outer accept loop
            // remains alive for the client's reconnect path.
            logf("net-telemetry-server: recv failed: %s\n", std::strerror(errno));
            break;
        }
        if (received == 0) {
            // A zero-byte recv is the normal TCP EOF signal from Guest A.
            logf("net-telemetry-server: client disconnected\n");
            break;
        }

        pending.append(buf, static_cast<std::size_t>(received));
        for (;;) {
            const std::string::size_type newline = pending.find('\n');
            if (newline == std::string::npos) {
                // Keep an unterminated record in pending; the next recv() may
                // contain the rest of the line.
                break;
            }

            // Remove one complete line at a time so a single recv() carrying
            // several samples produces several stable log entries.
            const std::string line = pending.substr(0, newline);
            pending.erase(0, newline + 1);
            logf("net-telemetry-server: received %s\n", line.c_str());
        }
    }
}

} // namespace

int main(int argc, char **argv)
{
    std::uint16_t port = kDefaultPort;

    // Optional port override is for bench experimentation; the shipped example
    // scripts use TCP 5001.
    if (argc > 1) {
        unsigned long parsed = std::strtoul(argv[1], nullptr, 0);
        if (parsed > 0 && parsed <= 65535) {
            // Ignore invalid input and keep the default port, matching the
            // client's tolerant argument handling.
            port = static_cast<std::uint16_t>(parsed);
        }
    }

    const int listener_fd = open_listener(port);
    if (listener_fd == -1) {
        // Listener setup already logged the precise failure.
        return 1;
    }

    for (;;) {
        sockaddr_in peer{};
        socklen_t peer_len = sizeof(peer);
        const int client_fd = accept(listener_fd, reinterpret_cast<sockaddr *>(&peer), &peer_len);

        // Interrupted accepts are normal on POSIX systems; keep the server
        // alive so Guest A can reconnect after restarts.
        if (client_fd == -1) {
            if (errno == EINTR) {
                // No client was accepted; simply wait again on the listener.
                continue;
            }
            // Log transient accept errors but keep the server available.
            logf("net-telemetry-server: accept failed: %s\n", std::strerror(errno));
            continue;
        }

        // Process this connection synchronously. A second Guest A instance, if
        // started by mistake, will wait until this session ends.
        log_peer(peer);
        serve_client(client_fd);
        close(client_fd);
    }
}

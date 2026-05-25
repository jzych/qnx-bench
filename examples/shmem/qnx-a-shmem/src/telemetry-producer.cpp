#include <cerrno>
#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>

#include <sys/mman.h>
#include <sys/neutrino.h>
#include <unistd.h>

#include <guest_shm.h>

namespace {

constexpr std::uint64_t kDefaultShmemFactory = 0x1c050000ULL;
constexpr unsigned kDefaultPeriodMs = 1000U;
constexpr const char *kTelemetryRegion = "telemetry";
constexpr unsigned kTelemetryPages = 1U;
constexpr std::uint32_t kTelemetryMagic = 0x54524d59U;

struct TelemetrySample {
    std::uint32_t magic;
    std::uint32_t sequence;
    std::uint64_t epoch_seconds;
    std::int32_t temperature_mc;
    std::int32_t voltage_mv;
    char source[32];
};

class TelemetryRegion {
public:
    int attach(std::uint64_t factory_paddr)
    {
        auto *factory_mapping = mmap(nullptr, 0x1000, PROT_READ | PROT_WRITE,
                                     MAP_SHARED | MAP_PHYS, NOFD, factory_paddr);
        if (factory_mapping == MAP_FAILED) {
            std::fprintf(stderr, "mmap factory 0x%" PRIx64 " failed: %s\n",
                         factory_paddr, std::strerror(errno));
            return -1;
        }

        factory_ = static_cast<volatile guest_shm_factory *>(factory_mapping);
        if (factory_->signature != GUEST_SHM_SIGNATURE) {
            std::fprintf(stderr, "shmem signature mismatch: got 0x%" PRIx64 "\n",
                         factory_->signature);
            return -1;
        }

        strlcpy(const_cast<char *>(factory_->name), kTelemetryRegion, sizeof(factory_->name));
        guest_shm_create(factory_, kTelemetryPages);
        if (factory_->status != GSS_OK) {
            std::fprintf(stderr, "shmem region create/attach failed: %u\n", factory_->status);
            return -1;
        }

        auto *region_mapping = mmap(nullptr, (factory_->size + 1) * 0x1000,
                                    PROT_READ | PROT_WRITE, MAP_SHARED | MAP_PHYS,
                                    NOFD, factory_->shmem);
        if (region_mapping == MAP_FAILED) {
            std::fprintf(stderr, "mmap telemetry region failed: %s\n", std::strerror(errno));
            return -1;
        }

        control_ = static_cast<volatile guest_shm_control *>(region_mapping);
        return 0;
    }

    volatile guest_shm_control *control() const { return control_; }

    volatile TelemetrySample *sample() const
    {
        return reinterpret_cast<volatile TelemetrySample *>(
            reinterpret_cast<std::uintptr_t>(control_) + 0x1000);
    }

private:
    volatile guest_shm_factory *factory_ = nullptr;
    volatile guest_shm_control *control_ = nullptr;
};

} // namespace

int main(int argc, char **argv)
{
    std::uint64_t factory_paddr = kDefaultShmemFactory;
    unsigned period_ms = kDefaultPeriodMs;

    if (argc > 1) {
        factory_paddr = std::strtoull(argv[1], nullptr, 0);
    }
    if (argc > 2) {
        period_ms = std::strtoul(argv[2], nullptr, 0);
    }

    if (ThreadCtl(_NTO_TCTL_IO, nullptr) == -1) {
        std::fprintf(stderr, "ThreadCtl I/O privilege failed: %s\n", std::strerror(errno));
        return 1;
    }

    TelemetryRegion region;
    if (region.attach(factory_paddr) != 0) {
        return 1;
    }

    volatile auto *ctrl = region.control();
    volatile auto *sample = region.sample();
    std::printf("telemetry-producer: region=%s factory=0x%" PRIx64
                " period=%ums idx=%u\n",
                kTelemetryRegion, factory_paddr, period_ms, ctrl->idx);

    for (std::uint32_t seq = 1;; ++seq) {
        sample->magic = kTelemetryMagic;
        sample->sequence = seq;
        sample->epoch_seconds = static_cast<std::uint64_t>(std::time(nullptr));
        sample->temperature_mc = 42000 + static_cast<std::int32_t>(seq % 250);
        sample->voltage_mv = 5000 + static_cast<std::int32_t>(seq % 20);
        strlcpy(const_cast<char *>(sample->source), "guest-1", sizeof(sample->source));

        ctrl->notify = ~0U;
        std::printf("telemetry-producer: seq=%u temp=%dmc voltage=%dmv\n",
                    sample->sequence, sample->temperature_mc, sample->voltage_mv);
        usleep(period_ms * 1000U);
    }
}

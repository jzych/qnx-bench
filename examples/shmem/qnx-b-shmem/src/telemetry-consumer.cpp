#include <cerrno>
#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <sys/mman.h>
#include <sys/neutrino.h>

#include <guest_shm.h>

namespace {

constexpr std::uint64_t kDefaultShmemFactory = 0x1c050000ULL;
constexpr unsigned kDefaultShmemIntr = 38U;
constexpr const char *kTelemetryRegion = "telemetry";
constexpr unsigned kTelemetryPages = 1U;
constexpr int kPulseCodeNotify = 1;
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

void print_sample(volatile const TelemetrySample *sample)
{
    if (sample->magic != kTelemetryMagic) {
        std::printf("telemetry-consumer: waiting for producer data\n");
        return;
    }

    std::printf("telemetry-consumer: seq=%u source=%s temp=%dmc voltage=%dmv time=%" PRIu64 "\n",
                sample->sequence, sample->source, sample->temperature_mc,
                sample->voltage_mv, sample->epoch_seconds);
}

} // namespace

int main(int argc, char **argv)
{
    std::uint64_t factory_paddr = kDefaultShmemFactory;
    unsigned intr = kDefaultShmemIntr;
    std::uint32_t last_sequence = 0;

    if (argc > 1) {
        factory_paddr = std::strtoull(argv[1], nullptr, 0);
    }
    if (argc > 2) {
        intr = std::strtoul(argv[2], nullptr, 0);
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
    const int channel = ChannelCreate(0);
    if (channel == -1) {
        std::fprintf(stderr, "ChannelCreate failed: %s\n", std::strerror(errno));
        return 1;
    }

    const int coid = ConnectAttach(0, 0, channel, _NTO_SIDE_CHANNEL, 0);
    if (coid == -1) {
        std::fprintf(stderr, "ConnectAttach failed: %s\n", std::strerror(errno));
        return 1;
    }

    sigevent event;
    SIGEV_PULSE_INIT(&event, coid, -1, kPulseCodeNotify, 0);
    const int iid = InterruptAttachEvent(intr, &event, _NTO_INTR_FLAGS_TRK_MSK);
    if (iid == -1) {
        std::fprintf(stderr, "InterruptAttachEvent %u failed: %s\n", intr, std::strerror(errno));
        return 1;
    }

    std::printf("telemetry-consumer: region=%s factory=0x%" PRIx64 " intr=%u idx=%u\n",
                kTelemetryRegion, factory_paddr, intr, ctrl->idx);

    for (;;) {
        _pulse pulse;

        if (sample->sequence != last_sequence) {
            last_sequence = sample->sequence;
            print_sample(sample);
        }

        MsgReceivePulse(channel, &pulse, sizeof(pulse), nullptr);
        if (pulse.code == kPulseCodeNotify) {
            const std::uint32_t status = ctrl->status;
            static_cast<void>(status);
            InterruptUnmask(intr, iid);
        }
    }
}

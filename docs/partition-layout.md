# Partition Layout

The partition layout is concrete for the current bench and must not be changed
without an explicit migration decision.

| Partition | Size | Type | Mount/Purpose |
| --- | ---: | --- | --- |
| p1 | 512 MiB | FAT32 | `/boot` |
| p2 | 2 GiB | QNX6 | `/qnx/system_a` |
| p3 | 2 GiB | QNX6 | `/qnx/system_b` |
| p4 | 1 GiB | QNX6 | `/qnx/config` |
| p5 | 4 GiB | QNX6 | `/qnx/var` |
| p6 | 48 GiB | QNX6 | `/vmstore` |
| p7 | rest | QNX6/raw | `/qnx/dumps` or reserved |

The generated QNX6 filesystem images should be created at full partition size,
not as small files that need `chkqnx6fs -x` on first boot.

Current default staging:

- Guest 1 IFS and qvmconf are staged under `/qnx/system_a/guests/qnx-guest-1/`.
- Guest 2 IFS and qvmconf are staged under `/qnx/system_b/guests/qnx-guest-2/`.
- Manual qvm test scripts and qvmconfs are staged under `/qnx/config/qvmtest/`.
- `/vmstore` is reserved for later guest storage.

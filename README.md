# cliffhanger

An automated, source-based build system that bootstraps a minimal Linux system from
upstream tarballs — in the spirit of [Linux From Scratch](https://www.linuxfromscratch.org/) —
with the goal of becoming a bootable, minimal Linux distribution for **servers** and a
foundation for an independent distro.

> **Status: early development.** Stage 1 (cross-toolchain + temporary tools) works.
> The chroot stages (2 and 3) are in progress. The result is not yet bootable.

## Goals

- Reproducible, script-driven builds straight from upstream sources (checksum-verified)
- Minimal, server-oriented base system
- `systemd` as the init system (planned — requires the LFS "systemd" build variant)
- Multi-architecture: `x86_64` and `aarch64` first, `riscv64` and others later

## Repository layout

```
scripts/
├── version_check.sh           # Verifies host toolchain meets LFS prerequisites
├── bootstrap.sh               # Stage 1: cross-toolchain (binutils, GCC, glibc) + temp tools
├── start_chroot_bootstrap.sh  # Enters the chroot (mounts /dev, /proc, ...) and runs a stage
├── chroot_bootstrap.sh        # Stages 2 & 3: builds the full system inside the chroot
├── _move_toolchain.sh         # Relocates the toolchain to a new absolute path
└── data/
    ├── bootstrap-sources.list            # URLs of all source tarballs
    └── bootstrap-sources.list.sha512sum  # SHA-512 checksums for those tarballs
```

## Requirements

A Debian/Ubuntu host (or similar) with:

```
autoconf autoconf2.69 automake autopoint bison build-essential byacc flex
gawk gettext gperf help2man libssl-dev libtool m4 make meson ninja-build
perl pkg-config tree unzip zlib1g-dev
```

Run `./scripts/version_check.sh` to verify your host meets the minimum tool versions.

## Quick start

```bash
# 1. Check the host
./scripts/version_check.sh

# 2. Download and verify all sources
mkdir -p rootfs/tmp/sources
wget -nv -i scripts/data/bootstrap-sources.list -P rootfs/tmp/sources
(cd rootfs/tmp/sources && sha512sum -c "$OLDPWD/scripts/data/bootstrap-sources.list.sha512sum")

# 3. Stage 1: build the cross-toolchain and temporary tools
./scripts/bootstrap.sh

# 4. Stages 2 & 3: build the system inside the chroot (as root)
sudo ./scripts/start_chroot_bootstrap.sh rootfs 2
sudo ./scripts/start_chroot_bootstrap.sh rootfs 3
```

## Configuration

`bootstrap.sh` is controlled by environment variables:

| Variable                     | Default                          | Description                          |
| ---------------------------- | -------------------------------- | ------------------------------------ |
| `TARGET_CPU_ARCH`            | `x86_64`                         | Target CPU architecture              |
| `TARGET_ROOTFS_PATH`         | `$PWD/rootfs`                    | Where the new root filesystem lives  |
| `TARGET_ROOTFS_SOURCES_PATH` | `$ROOTFS/tmp/sources`            | Downloaded tarballs                  |
| `TARGET_ROOTFS_WORK_PATH`    | `$ROOTFS/tmp/work`               | Build scratch directory              |
| `TARGET_TRIPLET`             | `$TARGET_CPU_ARCH-buildroot-linux-gnu` | Cross-compilation triplet       |
| `TOOLCHAIN_PATH`             | `$ROOTFS/toolchain`              | Cross-toolchain install prefix       |
| `EXIT_AFTER_TEMP_TOOLS`      | `false`                          | Stop after the temporary tools       |

`start_chroot_bootstrap.sh` supports `ENTER_CHROOT_STANDALONE=true` to drop into an
interactive shell inside the chroot instead of running a stage.

## CI/CD

Two manually-triggered workflows perform the full build:

- **`.github/workflows/main.yml`** — runs on GitHub-hosted `ubuntu-latest`
- **`.github/workflows/selfhosted.yml`** — runs on a self-hosted Debian runner

Both download and checksum-verify the sources, then execute the bootstrap with
live-filtered log output (` ==> ` progress lines) and a failure log tail.

## Roadmap

- [x] Stage 1: cross-toolchain + temporary tools
- [ ] Stages 2 & 3: complete base system in chroot
- [ ] systemd as init
- [ ] Kernel build + initramfs + bootloader (bootable image)
- [ ] aarch64 support in CI (and riscv64 later)
- [ ] Packaging strategy (TBD)

## License

[MIT](LICENSE) © 2025 John Unland
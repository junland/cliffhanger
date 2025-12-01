#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Locale, directory, and architecture variables
TARGET_CPU_ARCH=${TARGET_CPU_ARCH:-"x86_64"}
TARGET_ROOTFS_PATH=${TARGET_ROOTFS_PATH:-"${PWD}/rootfs"}
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"${TARGET_ROOTFS_PATH}/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"${TARGET_ROOTFS_PATH}/tmp/work"}
TARGET_TRIPLET=${TARGET_TRIPLET:-"${TARGET_CPU_ARCH}-buildroot-linux-gnu"}
TOOLCHAIN_PATH=${TOOLCHAIN_PATH:-"${TARGET_ROOTFS_PATH}/toolchain"}

# Variables with shorter names
ROOTFS="${TARGET_ROOTFS_PATH}"
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/steps/_common.sh"

# Source all step files
source "${SCRIPT_DIR}/steps/*_step.sh"

# Setup PATH
PATH="${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin"

echo "export PATH=${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin" >"$PWD"/.env

# Set CONFIG_SITE for cross-compilation
CONFIG_SITE="${TARGET_ROOTFS_PATH}/usr/share/config.site"

echo "export CONFIG_SITE=${TARGET_ROOTFS_PATH}/usr/share/config.site" >>"$PWD"/.env

# Set locale
LC_ALL=POSIX

echo "export LC_ALL=POSIX" >>"$PWD"/.env

# Export needed variables
export PATH LC_ALL CONFIG_SITE

# Create necessary directories
msg "Creating necessary directories..."
mkdir -vp "${TARGET_ROOTFS_PATH}"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}"
mkdir -vp "${TOOLCHAIN_PATH}"
mkdir -vp "$TARGET_ROOTFS_PATH"/{etc,var} "$TARGET_ROOTFS_PATH"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
	msg "Creating symlink $TARGET_ROOTFS_PATH/$i -> usr/$i"
	ln -sv usr/$i "$TARGET_ROOTFS_PATH"/$i
done

msg "Creating symlink $TARGET_ROOTFS_PATH/lib64 -> usr/lib"
ln -sv usr/lib "$TARGET_ROOTFS_PATH"/lib64

# Clean work directory before starting, just in case
clean_work_dir

msg "Starting bootstrap stage 1..."

# Define all build steps in order
BOOTSTRAP_STEPS=(
	"binutils_pass1"
	"gcc_pass1"
	"linux_headers"
	"glibc"
	"gcc_libstdcxx"
	"m4"
	"ncurses"
	"bash"
	"coreutils"
	"diffutils"
	"file"
	"findutils"
	"gawk"
	"grep"
	"gzip"
	"make"
	"patch"
	"sed"
	"tar"
	"xz"
	"binutils_pass2"
	"gcc_pass2"
)

# Execute each step
for step in "${BOOTSTRAP_STEPS[@]}"; do
	msg "Executing step: ${step}..."
	step_${step}
done

msg "Bootstrap stage 1 completed successfully!"

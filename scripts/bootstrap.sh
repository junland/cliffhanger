#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

CHANNEL_DATE="stable-2025.08-1"
CONFIG_SITE="toolchains/${TARGET_ARCH}/etc/config.site"
LC_ALL=POSIX
TARGET_ARCH="x86_64-v2"
TARGET_ROOTFS_PATH="rootfs"
TARGET_ROOTFS_SOURCES_PATH="${TARGET_ROOTFS_PATH}/tmp/sources"
TARGET_ROOTFS_WORK_PATH="${TARGET_ROOTFS_PATH}/tmp/work"
TARGET_TRIPLET="${TARGET_ARCH}-linux-gnu"
TOOLCHAIN_PATH="$PWD/toolchains/${TARGET_ARCH}"
TOOLCHAIN_TARGET_ARCH="${TARGET_ARCH//_/-}"
TOOLCHAIN_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/${TOOLCHAIN_TARGET_ARCH}/tarballs/${TOOLCHAIN_TARGET_ARCH}--glibc--${CHANNEL_DATE}.tar.xz"

CURL_OPTS="-L -s"

export LC_ALL CONFIG_SITE

# Variables with shorter names
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Versions for temporary tools
M4_VER="1.4.19"
NCURSES_VER="6.5-20250531"
BASH_VER="5.3"
COREUTILS_VER="9.7"

# msg function that will make echo's pretty.
msg() {
    echo "==> $*"
}

echo "Downloading toolchain from ${TOOLCHAIN_URL}..."

# Download the toolchain and extract it to the appropriate directory
mkdir -p "${TOOLCHAIN_PATH}"

curl ${CURL_OPTS} "${TOOLCHAIN_URL}" | tar -xJ -C "${TOOLCHAIN_PATH}" --strip-components=1

# Make sure relocate script is present and executable
if [ ! -f "${TOOLCHAIN_PATH}/relocate-sdk.sh" ]; then
    echo "Error: ${TOOLCHAIN_PATH}/relocate-sdk.sh not found!"
    exit 1
else
    chmod +x "${TOOLCHAIN_PATH}/relocate-sdk.sh"
fi

msg "Relocate the toolchain..."

cd "${TOOLCHAIN_PATH}" && ./relocate-sdk.sh && cd ..

# Create necessary directories
msg "Creating necessary directories..."
mkdir -vp "${TARGET_ROOTFS_PATH}"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}"

# Setup PATH
export PATH="${TOOLCHAIN_PATH}/bin:$PATH"

# Download M4
msg "Downloading M4..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/m4/m4-${M4_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}" --strip-components=1

msg "Copying sources of m4 to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

msg "Configuring M4..."

./configure --prefix=/usr --host=${TARGET_TRIPLET} --build=$(build-aux/config.guess)

msg "Building M4..."

make

msg "Installing M4..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

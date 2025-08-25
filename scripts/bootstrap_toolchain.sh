#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

LC_ALL=POSIX
TARGET_ARCH="x86_64"
TARGET_ROOTFS_PATH="${PWD}/rootfs"
TARGET_ROOTFS_SOURCES_PATH="${TARGET_ROOTFS_PATH}/tmp/sources"
TARGET_ROOTFS_WORK_PATH="${TARGET_ROOTFS_PATH}/tmp/work"
TARGET_TRIPLET="${TARGET_ARCH}-buildroot-linux-gnu"
TOOLCHAIN_TARGET_ARCH="${TARGET_ARCH//_/-}"
TOOLCHAIN_PATH="${PWD}/toolchains/${TARGET_ARCH}"

CURL_OPTS="-L -s"
CONFIG_SITE="${TARGET_ROOTFS_PATH}/usr/share/config.site"

# Variables with shorter names
ROOTFS="${TARGET_ROOTFS_PATH}"
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Versions for temporary tools
BINUTILS_VER="2.45"
GCC_VER="14.2.0"
GLIBC_VER="2.41"
GMP_VER="6.3.0"
LINUX_VER="6.13.4"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"

# msg function that will make echo's pretty.
msg() {
    echo " ==> $*"
}

# clean work directory function
clean_work_dir() {
    cd "${TARGET_ROOTFS_PATH}"
    msg "Cleaning up work directory at ${WORK}..."
    rm -rf "${WORK}"/*
}

# Setup PATH
PATH="${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Export needed variables
export PATH LC_ALL CONFIG_SITE

# Create necessary directories
msg "Creating necessary directories..."
mkdir -vp "${TARGET_ROOTFS_PATH}"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}"
mkdir -vp "${TOOLCHAIN_PATH}"

##
# binutils Step
##

msg "Downloading binutils..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}" --strip-components=1

msg "Copying sources of binutils to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

msg "Configuring binutils..."

mkdir -v build

cd build

../configure \
    --prefix=${TOOLCHAIN_PATH} \
    --target=${TARGET_TRIPLET} \
    --with-sysroot=${TARGET_ROOTFS_PATH} \
    --disable-nls \
    --enable-gprofng=no \
    --disable-werror \
    --enable-new-dtags \
    --enable-default-hash-style=gnu

msg "Building binutils..."

make

msg "Installing binutils..."

make install

clean_work_dir

##
# gcc Step
##

msg "Download gcc..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}/{gmp,mpc,mpfr}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}"

# curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}" --strip-components=1
curl ${CURL_OPTS} "https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-${GCC_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}" --strip-components=1

msg "Copying sources of gcc to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr/"

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

msg "Configuring gcc..."

case $(uname -m) in
x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
esac

mkdir -v build

cd build

../configure \
    --prefix=${TOOLCHAIN_PATH} \
    --target=${TARGET_TRIPLET} \
    --with-glibc-version=${GLIBC_VER} \
    --with-sysroot=${TARGET_ROOTFS_PATH} \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

msg "Building gcc..."

make

msg "Installing gcc..."

make install

cd ..

cat gcc/limitx.h gcc/glimits.h gcc/limity.h >$(dirname $($TARGET_TRIPLET-gcc -print-libgcc-file-name))/include/limits.h

clean_work_dir

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
MPFR_VER="4.2.1"

GLIBC_PATCH_URL="https://www.linuxfromscratch.org/patches/lfs/12.3/glibc-2.41-fhs-1.patch"

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

mkdir -vp "$TARGET_ROOTFS_PATH"/{etc,var} "$TARGET_ROOTFS_PATH"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
    ln -sv usr/$i "$TARGET_ROOTFS_PATH"/$i
done

case $(uname -m) in
x86_64) mkdir -vp "$TARGET_ROOTFS_PATH"/lib64 ;;
esac

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
    --prefix="${TOOLCHAIN_PATH}" \
    --target="${TARGET_TRIPLET}" \
    --with-sysroot="${TARGET_ROOTFS_PATH}" \
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
# gcc Step (1st Pass - Part A)
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
    --prefix="${TOOLCHAIN_PATH}" \
    --target="${TARGET_TRIPLET}" \
    --with-glibc-version="${GLIBC_VER}" \
    --with-sysroot="${TARGET_ROOTFS_PATH}" \
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

##
# linux-headers Step
##

msg "Downloading linux kernel..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/linux-${LINUX_VER}"

curl ${CURL_OPTS} "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_VER%.*.*}.x/linux-${LINUX_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/linux-${LINUX_VER}" --strip-components=1

msg "Copying sources of linux kernel to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/linux-${LINUX_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/linux-${LINUX_VER}"

# Deduce the kernel arch from the target arch.
case ${TARGET_ARCH} in
x86_64)
    KARCH="x86_64"
    ;;
aarch64)
    KARCH="arm64"
    ;;
riscv64)
    KARCH="riscv64"
    ;;
*)
    echo "Unknown architecture: ${TARGET_ARCH}"
    exit 1
    ;;
esac

msg "Confirming files..."

make mrproper -j1 ARCH="${KARCH}"

msg "Building headers..."

make headers -j1 ARCH="${KARCH}"

msg "Installing headers..."

find usr/include -type f ! -name '*.h' -delete

mkdir -vp "${TARGET_ROOTFS_PATH}/usr"

cp -rv usr/include/* "${TARGET_ROOTFS_PATH}/usr"

clean_work_dir

##
# glibc Step
##

msg "Downloading glibc..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/libc/glibc-${GLIBC_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}" --strip-components=1

msg "Copying sources of glibc to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}"

msg "Configuring glibc..."

case ${TARGET_ARCH} in
i?86)
    ln -sfv ld-linux.so.2 "${TARGET_ROOTFS_PATH}"/lib/ld-lsb.so.3
    ;;
x86_64)
    ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}"/lib64
    ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}"/lib64/ld-lsb-x86-64.so.3
    ;;
aarch64)
    ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}"/lib64
    ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}"/lib64/ld-lsb-aarch64.so.3
    ;;
riscv64)
    ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}"/lib64
    ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}"/lib64/ld-lsb-riscv64.so.3
    ;;
*)
    echo "Unknown architecture: ${TARGET_ARCH}"
    exit 1
    ;;
esac

curl ${CURL_OPTS} -o "${TARGET_ROOTFS_SOURCES_PATH}/glibc-2.41-fhs-1.patch" "${GLIBC_PATCH_URL}"

patch -Np1 -i "${TARGET_ROOTFS_SOURCES_PATH}/glibc-2.41-fhs-1.patch"

mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

echo "rootsbindir=/usr/sbin" >configparms

../configure \
    libc_cv_slibdir=/usr/lib \
    --prefix=/usr \
    --host="${TARGET_TRIPLET}" \
    --build=$(../scripts/config.guess) \
    --enable-kernel=5.4 \
    --with-headers="${TARGET_ROOTFS_PATH}/usr/include" \
    --disable-nscd

msg "Building glibc..."

make -j1

msg "Installing glibc..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

sed '/RTLDLIST=/s@/usr@@g' -i "${TARGET_ROOTFS_PATH}"/usr/bin/ldd

msg "Verify that compiling and linking works..."

echo 'int main(){}' | ${TARGET_TRIPLET}-gcc -xc -

readelf -l a.out | grep ld-linux

rm -v a.out

clean_work_dir

##
# gcc - libstdc++ Step (1st Pass - Part B)
##

msg "Setting up gcc for libstdc++..."

mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

tar -xzf "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.gz" -C "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}" --strip-components=1
tar -xzf "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.gz" -C "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp" --strip-components=1
tar -xzf "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" -C "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc" --strip-components=1
tar -xzf "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.gz" -C "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr" --strip-components=1

msg "Configuring gcc for libstdc++..."

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

mkdir -vp build

cd build

../libstdc++-v3/configure \
    --host="${TARGET_TRIPLET}" \
    --build="$(../config.guess)" \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir="/tools/${TARGET_TRIPLET}/include/c++/14.2.0"

msg "Building gcc for libstdc++..."

make

msg "Installing gcc for libstdc++..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/lib{stdc++{,exp,fs},supc++}.la

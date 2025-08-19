#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

CHANNEL_DATE="stable-2025.08-1"
CONFIG_SITE="toolchains/${TARGET_ARCH}/etc/config.site"
LC_ALL=POSIX
TARGET_ARCH="x86_64"
TARGET_ROOTFS_PATH="$PWD/rootfs"
TARGET_ROOTFS_SOURCES_PATH="${TARGET_ROOTFS_PATH}/tmp/sources"
TARGET_ROOTFS_WORK_PATH="${TARGET_ROOTFS_PATH}/tmp/work"
TARGET_TRIPLET="${TARGET_ARCH}-linux-gnu"
TOOLCHAIN_PATH="$PWD/toolchains/${TARGET_ARCH}"
TOOLCHAIN_TARGET_ARCH="${TARGET_ARCH//_/-}"
TOOLCHAIN_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/${TOOLCHAIN_TARGET_ARCH}/tarballs/${TOOLCHAIN_TARGET_ARCH}--glibc--${CHANNEL_DATE}.tar.xz"

CURL_OPTS="-L -s"

# Variables with shorter names
ROOTFS="${TARGET_ROOTFS_PATH}"
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Versions for temporary tools
M4_VER="1.4.19"
NCURSES_VER="6.5"
BASH_VER="5.2.37"
COREUTILS_VER="9.6"
DIFFUTILS_VER="3.11"
FILE_VER="5.46"
FINDUTILS_VER="4.10.0"
GAWK_VER="5.3.1"
GREP_VER="3.11"
GZIP_VER="1.13"

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

##
# Toolchain Setup
##

msg "Downloading toolchain from ${TOOLCHAIN_URL}..."

# Download the toolchain and extract it to the appropriate directory
mkdir -p "${TOOLCHAIN_PATH}"

curl ${CURL_OPTS} "${TOOLCHAIN_URL}" | tar -xJ -C "${TOOLCHAIN_PATH}" --strip-components=1

# Make sure relocate script is present and executable
if [ ! -f "${TOOLCHAIN_PATH}/relocate-sdk.sh" ]; then
    msg "Error: ${TOOLCHAIN_PATH}/relocate-sdk.sh not found!"
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
PATH="${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Export needed variables
export PATH LC_ALL CONFIG_SITE

##
# m4 Step
##

msg "Downloading m4..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/m4/m4-${M4_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}" --strip-components=1

msg "Copying sources of m4 to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

msg "Configuring m4..."

CFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2" ./configure --prefix=/usr --host=${TARGET_TRIPLET} --build=$(build-aux/config.guess)

msg "Building m4..."

make

msg "Installing m4..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# ncurses Step
##

msg "Downloading ncurses..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}" --strip-components=1

msg "Copying sources of ncurses to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

msg "Creating tic program in ncurses..."

mkdir -vp build

pushd build

../configure AWK=gawk

make -C include

make -C progs tic

popd

msg "Configuring ncurses..."

./configure \
    --prefix=/usr \
    --host=${TARGET_TRIPLET} \
    --build=$(./config.guess) \
    --mandir=/usr/share/man \
    --with-manpage-format=normal \
    --with-shared \
    --without-normal \
    --with-cxx-shared \
    --without-debug \
    --without-ada \
    --disable-stripping \
    AWK=gawk

msg "Building ncurses..."

make

msg "Installing ncurses..."

make DESTDIR="${TARGET_ROOTFS_PATH}" TIC_PATH="${TARGET_ROOTFS_WORK_PATH}"/ncurses-${NCURSES_VER}/build/progs/tic install

ln -sv libncursesw.so "${TARGET_ROOTFS_PATH}"/usr/lib/libncurses.so

sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "${TARGET_ROOTFS_PATH}"/usr/include/curses.h

clean_work_dir

##
# bash Step
##

msg "Downloading bash..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/bash-${BASH_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/bash/bash-${BASH_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/bash-${BASH_VER}" --strip-components=1

msg "Copying sources of bash to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/bash-${BASH_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/bash-${BASH_VER}"

msg "Configuring bash..."

./configure \
    --prefix=/usr \
    --build=$(sh support/config.guess) \
    --host=${TARGET_TRIPLET} \
    --without-bash-malloc

msg "Building bash..."

make

msg "Installing bash..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

ln -sv bash "${TARGET_ROOTFS_PATH}"/usr/bin/sh

clean_work_dir

##
# coreutils Step
##

msg "Downloading coreutils..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}" --strip-components=1

msg "Copying sources of coreutils to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/coreutils-${COREUTILS_VER}"

msg "Configuring coreutils..."

./configure \
    --prefix=/usr \
    --host=${TARGET_TRIPLET} \
    --build=$(./config.guess) \
    --enable-install-program=hostname \
    --enable-no-install-program=kill,uptime

msg "Building coreutils..."

make

msg "Installing coreutils..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

mv -v "$TARGET_ROOTFS_PATH"/usr/bin/chroot "$TARGET_ROOTFS_PATH"/usr/sbin
mkdir -pv "$TARGET_ROOTFS_PATH"/usr/share/man/man8
mv -v "$TARGET_ROOTFS_PATH"/usr/share/man/man1/chroot.1 "$TARGET_ROOTFS_PATH"/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' "$TARGET_ROOTFS_PATH"/usr/share/man/man8/chroot.8

clean_work_dir

##
# diffutils
##

msg "Downloading diffutils..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/diffutils-${DIFFUTILS_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/diffutils/diffutils-${DIFFUTILS_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/diffutils-${DIFFUTILS_VER}" --strip-components=1

msg "Copying sources of diffutils to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/diffutils-${DIFFUTILS_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/diffutils-${DIFFUTILS_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring diffutils..."

./configure \
    --prefix=/usr \
    --host=${TARGET_TRIPLET} \
    --build=$(./config.guess)

msg "Building diffutils..."

make

msg "Installing diffutils..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# file Step
##

msg "Downloading file..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/file-${FILE_VER}"

curl ${CURL_OPTS} "https://astron.com/pub/file/file-${FILE_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/file-${FILE_VER}" --strip-components=1

msg "Copying sources of file to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/file-${FILE_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/file-${FILE_VER}"

msg "Configure temp file command..."

mkdir build

pushd build

../configure \
    --disable-bzlib \
    --disable-libseccomp \
    --disable-xzlib \
    --disable-zlib

msg "Building temp file command..."

make

popd

msg "Configuring file..."

./configure --prefix=/usr --host=${TARGET_TRIPLET} --build=$(./config.guess)

msg "Building file..."

make FILE_COMPILE=$(pwd)/build/src/file

msg "Installing file..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/libmagic.la

clean_work_dir

##
# findutils Step
##

msg "Downloading findutils..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/findutils-${FINDUTILS_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/findutils/findutils-${FINDUTILS_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/findutils-${FINDUTILS_VER}" --strip-components=1

msg "Copying sources of findutils to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/findutils-${FINDUTILS_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/findutils-${FINDUTILS_VER}"

msg "Configuring findutils..."

./configure \
    --prefix=/usr \
    --localstatedir=/var/lib/locate \
    --host=${TARGET_TRIPLET} \
    --build=$(build-aux/config.guess)

msg "Building findutils..."

make

msg "Installing findutils..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# gawk Step
##

msg "Downloading gawk..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gawk-${GAWK_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gawk/gawk-${GAWK_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/gawk-${GAWK_VER}" --strip-components=1

msg "Copying sources of gawk to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gawk-${GAWK_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/gawk-${GAWK_VER}"

msg "Configuring gawk..."

sed -i 's/extras//' Makefile.in

./configure \
    --prefix=/usr \
    --host=${TARGET_TRIPLET} \
    --build=$(build-aux/config.guess)

msg "Building gawk..."

make

msg "Installing gawk..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

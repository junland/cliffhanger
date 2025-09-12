#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

LC_ALL=POSIX
TARGET_ARCH="x86_64"
TARGET_ROOTFS_PATH="$PWD/rootfs"
TARGET_ROOTFS_SOURCES_PATH="${TARGET_ROOTFS_PATH}/tmp/sources"
TARGET_ROOTFS_WORK_PATH="${TARGET_ROOTFS_PATH}/tmp/work"
TARGET_TRIPLET="${TARGET_ARCH}-buildroot-linux-gnu"
TOOLCHAIN_PATH="$PWD/toolchain-${TARGET_ARCH}"
TOOLCHAIN_TARGET_ARCH="${TARGET_ARCH//_/-}"
TOOLCHAIN_URL="https://toolchains.bootlin.com/downloads/releases/toolchains/${TOOLCHAIN_TARGET_ARCH}/tarballs/${TOOLCHAIN_TARGET_ARCH}--glibc--${CHANNEL_DATE}.tar.xz"

CURL_OPTS="-L -s"
CONFIG_SITE="${TARGET_ROOTFS_PATH}/usr/share/config.site"

# Variables with shorter names
ROOTFS="${TARGET_ROOTFS_PATH}"
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Versions for temporary tools
BASH_VER="5.3"
BINUTILS_VER="2.45"
COREUTILS_VER="9.7"
DIFFUTILS_VER="3.12"
FILE_VER="5.46"
FINDUTILS_VER="4.10.0"
GAWK_VER="5.3.2"
GCC_VER="15.2.0"
GLIBC_VER="2.42"
GMP_VER="6.3.0"
GREP_VER="3.12"
GZIP_VER="1.13"
M4_VER="1.4.20"
MAKE_VER="4.4.1"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
NCURSES_VER="6.5-20250809"
PATCH_VER="2.7.6"
SED_VER="4.9"
TAR_VER="1.35"
XZ_VER="5.6.2"

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
# Toolchain Setup
##

# msg "Downloading toolchain from ${TOOLCHAIN_URL}..."

# curl ${CURL_OPTS} "${TOOLCHAIN_URL}" | tar -xJ -C "${TOOLCHAIN_PATH}" --strip-components=1

# # Make sure relocate script is present and executable
# if [ ! -f "${TOOLCHAIN_PATH}/relocate-sdk.sh" ]; then
#     msg "Error: ${TOOLCHAIN_PATH}/relocate-sdk.sh not found!"
#     exit 1
# else
#     chmod +x "${TOOLCHAIN_PATH}/relocate-sdk.sh"
# fi

# msg "Relocate the toolchain..."

# cd "${TOOLCHAIN_PATH}" && ./relocate-sdk.sh && cd ..

# msg "Copying toolchain sysroot to ${TARGET_ROOTFS_PATH}..."

# # Move the files within the sysroot directory within the toolchain
# find "${TOOLCHAIN_PATH}" -name "sysroot" -type d -exec cp -r {}/* "${TARGET_ROOTFS_PATH}/" \;

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

./configure --prefix=/usr --host=${TARGET_TRIPLET} --build=$(build-aux/config.guess)

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

curl ${CURL_OPTS} "https://invisible-mirror.net/archives/ncurses/current/ncurses-${NCURSES_VER}.tgz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}" --strip-components=1

msg "Copying sources of ncurses to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

msg "Creating tic program in ncurses..."

mkdir -vp build

pushd build

../configure --prefix=${TARGET_ROOTFS_PATH} AWK=gawk

make -C include

make -C progs tic

install progs/tic ${TOOLCHAIN_PATH}/bin

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

make DESTDIR="${TARGET_ROOTFS_PATH}" install

ln -svf libncursesw.so "${TARGET_ROOTFS_PATH}"/usr/lib/libncurses.so

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

ln -svf bash "${TARGET_ROOTFS_PATH}"/usr/bin/sh

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

# Reconfigure to point to our version of automake
autoreconf -f

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

# Reconfigure to point to our version of automake
autoreconf -f

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

# Reconfigure to point to our version of automake
autoreconf -f

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

# Reconfigure to point to our version of automake
autoreconf -f

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

##
# grep Step
##

msg "Downloading grep..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/grep-${GREP_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/grep/grep-${GREP_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/grep-${GREP_VER}" --strip-components=1

msg "Copying sources of grep to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/grep-${GREP_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/grep-${GREP_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring grep..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess)

msg "Building grep..."

make

msg "Installing grep..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# gzip Step
##

msg "Downloading gzip..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gzip-${GZIP_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gzip/gzip-${GZIP_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/gzip-${GZIP_VER}" --strip-components=1

msg "Copying sources of gzip to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gzip-${GZIP_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/gzip-${GZIP_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring gzip..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET}

msg "Building gzip..."

make

msg "Installing gzip..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# make Step
##

msg "Downloading make..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/make-${MAKE_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/make-${MAKE_VER}" --strip-components=1

msg "Copying sources of make to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/make-${MAKE_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/make-${MAKE_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring make..."

./configure \
	--build=$(build-aux/config.guess) \
	--prefix=/usr \
	--without-guile \
	--host=${TARGET_TRIPLET}

msg "Building make..."

make

msg "Installing make..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# patch Step
##

msg "Downloading patch..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/patch-${PATCH_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/patch/patch-${PATCH_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/patch-${PATCH_VER}" --strip-components=1

msg "Copying sources of patch to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/patch-${PATCH_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/patch-${PATCH_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring patch..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess)

msg "Building patch..."

make

msg "Installing patch..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# sed Step
##

msg "Downloading sed..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/sed-${SED_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/sed/sed-${SED_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/sed-${SED_VER}" --strip-components=1

msg "Copying sources of sed to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/sed-${SED_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/sed-${SED_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring sed..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess)

msg "Building sed..."

make

msg "Installing sed..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# tar Step
##

msg "Downloading tar..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/tar-${TAR_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/tar/tar-${TAR_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/tar-${TAR_VER}" --strip-components=1

msg "Copying sources of tar to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/tar-${TAR_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/tar-${TAR_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring tar..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess)

msg "Building tar..."

make

msg "Installing tar..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

clean_work_dir

##
# xz Step
##

msg "Downloading xz..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/xz-${XZ_VER}"

curl ${CURL_OPTS} "https://github.com/tukaani-project/xz/releases/download/v${XZ_VER}/xz-${XZ_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/xz-${XZ_VER}" --strip-components=1

msg "Copying sources of xz to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/xz-${XZ_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/xz-${XZ_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring xz..."

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess) \
	--disable-static \
	--docdir=/usr/share/doc/xz-5.6.4

msg "Building xz..."

make

msg "Installing xz..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

rm -v ${TARGET_ROOTFS_PATH}/usr/lib/liblzma.la

clean_work_dir

##
# binutils Step
##

msg "Downloading binutils..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}" --strip-components=1

msg "Copying sources of binutils to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}" "${TARGET_ROOTFS_WORK_PATH}/"

cd "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring binutils..."

sed '6031s/$add_dir//' -i ltmain.sh

mkdir -v build

cd build

../configure \
	--prefix=/usr \
	--build=$(../config.guess) \
	--host=${TARGET_TRIPLET} \
	--disable-nls \
	--enable-shared \
	--enable-gprofng=no \
	--disable-werror \
	--enable-64-bit-bfd \
	--enable-new-dtags \
	--enable-default-hash-style=gnu

msg "Building binutils..."

make

msg "Installing binutils..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

rm -v ${TARGET_ROOTFS_PATH}/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

clean_work_dir

# Clean up sources for final step..

rm -rf "${TARGET_ROOTFS_SOURCES_PATH}"

##
# gcc Step
##

msg "Download gcc..."

mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}"
mkdir -vp "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}"

curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" | tar -xJ -C "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}" --strip-components=1
curl ${CURL_OPTS} "https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VER}.tar.gz" | tar -xz -C "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}" --strip-components=1

msg "Copying sources of gcc to work directory..."

cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}" "${TARGET_ROOTFS_WORK_PATH}/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}" "${TARGET_ROOTFS_WORK_PATH}/gmp-${GMP_VER}/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}" "${TARGET_ROOTFS_WORK_PATH}/mpc-${MPC_VER}/"
cp -r "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}" "${TARGET_ROOTFS_WORK_PATH}/mpfr-${MPFR_VER}/"

ln -svf "${TARGET_ROOTFS_WORK_PATH}/gmp-${GMP_VER}/" ${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp
ln -svf "${TARGET_ROOTFS_WORK_PATH}/mpc-${MPC_VER}/" ${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc
ln -svf "${TARGET_ROOTFS_WORK_PATH}/mpfr-${MPFR_VER}/" ${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

msg "Configuring gcc..."

case $(uname -m) in
x86_64)
	sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
	;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build

cd build

../configure \
	--build=$(../config.guess) \
	--host=${TARGET_TRIPLET} \
	--target=${TARGET_TRIPLET} \
	LDFLAGS_FOR_TARGET=-L$PWD/${TARGET_TRIPLET}/libgcc \
	--prefix=/usr \
	--with-build-sysroot=$TARGET_ROOTFS_PATH \
	--enable-default-pie \
	--enable-default-ssp \
	--disable-nls \
	--disable-multilib \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-libvtv \
	--enable-languages=c,c++

msg "Building gcc..."

make

msg "Installing gcc..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

ln -svf gcc ${TARGET_ROOTFS_PATH}/usr/bin/cc

clean_work_dir

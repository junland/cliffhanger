#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Locale, directory, and architecture variables
TARGET_ARCH=${TARGET_ARCH:-"x86_64"}
TARGET_ROOTFS_PATH=${TARGET_ROOTFS_PATH:-"${PWD}/rootfs"}
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"${TARGET_ROOTFS_PATH}/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"${TARGET_ROOTFS_PATH}/tmp/work"}
TARGET_TRIPLET=${TARGET_TRIPLET:-"${TARGET_ARCH}-buildroot-linux-gnu"}
TOOLCHAIN_PATH=${TOOLCHAIN_PATH:-"${TARGET_ROOTFS_PATH}/toolchain"}
TOOLCHAIN_TARGET_ARCH="${TARGET_ARCH//_/-}"

# Runtime variables
CURL_OPTS="-L -s"

EXIT_AFTER_TEMP_TOOLS=${EXIT_AFTER_TEMP_TOOLS:-false}

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
LFS_BOOK_VER="12.4"
LINUX_VER="6.16.1"
M4_VER="1.4.20"
MAKE_VER="4.4.1"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
NCURSES_VER="6.5-20250809"
PATCH_VER="2.7.6"
SED_VER="4.9"
TAR_VER="1.35"
XZ_VER="5.6.2"

GLIBC_PATCH_URL="https://www.linuxfromscratch.org/patches/lfs/${LFS_BOOK_VER}/glibc-${GLIBC_VER}-fhs-1.patch"

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Clean work directory function
clean_work_dir() {
	cd "${TARGET_ROOTFS_PATH}"
	msg "Cleaning up work directory at ${WORK}..."
	rm -rf "${WORK}"/*
}

# Extracts an archive file to a destination directory
extract_file() {
	local archive_file=$1
	local dest_dir=$2

	# Use environment variables with defaults
	local strip_components=${EXTRACT_FILE_STRIP_COMPONENTS:-0}
	local verbose=${EXTRACT_FILE_VERBOSE_EXTRACT:-false}

	# Make sure the archive file exists
	if [ ! -f "${archive_file}" ]; then
		echo "Error: Archive file ${archive_file} does not exist."
		exit 1
	fi

	mkdir -vp "${dest_dir}"

	msg "Extracting to ${dest_dir}..."

	local verbose_flag=""
	if [ "${verbose}" = true ] || [ "${verbose}" = "true" ]; then
		verbose_flag="-v"
	fi

	# Check to see if we have to strip components based on the archive file has a parent directory
	if [ "${strip_components}" -eq 0 ]; then
		if tar -tf "${archive_file}" | head -1 | grep -q '/'; then
			echo "Archive has a parent directory, setting strip_components to 1"
			strip_components=1
		else
			echo "Archive does not have a parent directory, setting strip_components to 0"
			strip_components=0
		fi
	fi

	case ${archive_file} in
	*.tar.bz2 | *.tbz2)
		tar -xjf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.tar.xz | *.txz)
		tar -xJf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.tar.gz | *.tgz)
		tar -xzf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.zip)
		unzip -q "${archive_file}" -d "${dest_dir}"
		;;
	*)
		echo "Unknown archive format: ${archive_file}"
		exit 1
		;;
	esac
}

# Setup PATH
PATH="${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Set CONFIG_SITE for cross-compilation
CONFIG_SITE="${TARGET_ROOTFS_PATH}/usr/share/config.site"

# Set locale
LC_ALL=POSIX

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

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

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

cat gcc/limitx.h gcc/glimits.h gcc/limity.h >$(dirname $($TARGET_TRIPLET-gcc -print-libgcc-file-name))/include/limits.h

clean_work_dir

##
# linux-headers Step
##

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/linux-${LINUX_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/linux-${LINUX_VER}"

msg "Confirming files..."

cd "${TARGET_ROOTFS_WORK_PATH}/linux-${LINUX_VER}"

make mrproper

msg "Building headers..."

make headers

msg "Installing headers..."

find usr/include -type f ! -name '*.h' -delete

mkdir -vp "${TARGET_ROOTFS_PATH}/usr"

cp -rv usr/include "${TARGET_ROOTFS_PATH}/usr"

clean_work_dir

##
# glibc Step
##

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}"

msg "Configuring glibc..."

cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}"

case ${TARGET_ARCH} in
i?86)
	ln -sfv ld-linux.so.2 "${TARGET_ROOTFS_PATH}/lib/ld-lsb.so.3"
	;;
x86_64)
	ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}/lib64"
	ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-x86-64.so.3"
	;;
aarch64)
	ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}/lib64"
	ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-aarch64.so.3"
	;;
riscv64)
	ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}/lib64"
	ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-riscv64.so.3"
	;;
*)
	echo "Unknown architecture: ${TARGET_ARCH}"
	exit 1
	;;
esac

curl ${CURL_OPTS} -o "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}-fhs-1.patch" "${GLIBC_PATCH_URL}"

patch -Np1 -i "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}-fhs-1.patch"

mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

echo "rootsbindir=/usr/sbin" >configparms

../configure \
	--prefix=/usr \
	--host="${TARGET_TRIPLET}" \
	--build=$(../scripts/config.guess) \
	--enable-kernel=5.4 \
	--with-headers="${TARGET_ROOTFS_PATH}/usr/include" \
	--disable-nscd \
	libc_cv_slibdir=/usr/lib

msg "Building glibc..."

make -j1

msg "Installing glibc..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

sed '/RTLDLIST=/s@/usr@@g' -i "${TARGET_ROOTFS_PATH}/usr/bin/ldd"

msg "Verify that compiling and linking works..."

echo 'int main(){}' | ${TARGET_TRIPLET}-gcc -xc -

readelf -l a.out | grep ld-linux

rm -v a.out

clean_work_dir

##
# gcc - libstdc++ Step (1st Pass - Part B)
##

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

msg "Configuring gcc for libstdc++..."

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

TOOLCHAIN_BASE_DIR=$(basename "${TOOLCHAIN_PATH}")

msg "Using toolchain base dir: ${TOOLCHAIN_BASE_DIR}"

mkdir -vp build

cd build

../libstdc++-v3/configure \
	--host="${TARGET_TRIPLET}" \
	--build="$(../config.guess)" \
	--prefix=/usr \
	--disable-multilib \
	--disable-nls \
	--disable-libstdcxx-pch \
	--with-gxx-include-dir="/${TOOLCHAIN_BASE_DIR}/${TARGET_TRIPLET}/include/c++/${GCC_VER}"

msg "Building gcc for libstdc++..."

make

msg "Installing gcc for libstdc++..."

make install DESTDIR="${TARGET_ROOTFS_PATH}"

rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/lib{stdc++{,exp,fs},supc++}.la

clean_work_dir

##
# Temporary Tools Installed
##

##
# m4 Step
##

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

msg "Preparing m4 build environment..."

cd "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/ncurses-${NCURSES_VER}.tgz" "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

msg "Creating tic program in ncurses..."

cd "${TARGET_ROOTFS_WORK_PATH}/ncurses-${NCURSES_VER}"

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/bash-${BASH_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/bash-${BASH_VER}"

msg "Configuring bash..."

cd "${TARGET_ROOTFS_WORK_PATH}/bash-${BASH_VER}"

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/coreutils-${COREUTILS_VER}"

msg "Configuring coreutils..."

cd "${TARGET_ROOTFS_WORK_PATH}/coreutils-${COREUTILS_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

./configure \
	--prefix=/usr \
	--host=${TARGET_TRIPLET} \
	--build=$(build-aux/config.guess) \
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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/diffutils-${DIFFUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/diffutils-${DIFFUTILS_VER}"

msg "Configuring diffutils..."

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/file-${FILE_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/file-${FILE_VER}"

msg "Configuring temp file command..."

cd "${TARGET_ROOTFS_WORK_PATH}/file-${FILE_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/findutils-${FINDUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/findutils-${FINDUTILS_VER}"

msg "Configuring findutils..."

cd "${TARGET_ROOTFS_WORK_PATH}/findutils-${FINDUTILS_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gawk-${GAWK_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gawk-${GAWK_VER}"

msg "Configuring gawk..."

cd "${TARGET_ROOTFS_WORK_PATH}/gawk-${GAWK_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/grep-${GREP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/grep-${GREP_VER}"

msg "Configuring grep..."

cd "${TARGET_ROOTFS_WORK_PATH}/grep-${GREP_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gzip-${GZIP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gzip-${GZIP_VER}"

msg "Configuring gzip..."

cd "${TARGET_ROOTFS_WORK_PATH}/gzip-${GZIP_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/make-${MAKE_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/make-${MAKE_VER}"

msg "Configuring make..."

cd "${TARGET_ROOTFS_WORK_PATH}/make-${MAKE_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/patch-${PATCH_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/patch-${PATCH_VER}"

msg "Configuring patch..."

cd "${TARGET_ROOTFS_WORK_PATH}/patch-${PATCH_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/sed-${SED_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/sed-${SED_VER}"

msg "Configuring sed..."

cd "${TARGET_ROOTFS_WORK_PATH}/sed-${SED_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/tar-${TAR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/tar-${TAR_VER}"

msg "Configuring tar..."

cd "${TARGET_ROOTFS_WORK_PATH}/tar-${TAR_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/xz-${XZ_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/xz-${XZ_VER}"

msg "Configuring xz..."

cd "${TARGET_ROOTFS_WORK_PATH}/xz-${XZ_VER}"

# Reconfigure to point to our version of automake
autoreconf -f

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

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/binutils-${BINUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

msg "Configuring binutils..."

cd "${TARGET_ROOTFS_WORK_PATH}/binutils-${BINUTILS_VER}"

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

##
# gcc Step
##

extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

msg "Configuring gcc..."

cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

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

if [ "${EXIT_AFTER_TEMP_TOOLS}" = true ]; then
	msg "Exiting after temporary tools installation as requested."
	exit 0
fi

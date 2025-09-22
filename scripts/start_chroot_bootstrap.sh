#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <chroot_path>"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "Error: $1 is not a directory"
	exit 1
fi

# Script variables
CHROOT_PATH="$1"
CURL_OPTS="-L -s"
ROOTFS="${CHROOT_PATH}"
WORK="${ROOTFS}/tmp/work"
SOURCES="${ROOTFS}/tmp/sources"

# Version variables
GETTEXT_VER="0.26"
BISON_VER="2.8.2"
PERL_VER="5.42.0"
PYTHON_VER="3.13.7"
TEXINFO_VER="7.2"
UTIL_LINUX_VER="2.41.1"

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Downloads a file from a URL
download_file() {
	local url=$1
	local dest_file=$2

	# Make sure we haven't already downloaded the file
	if [ -f "${dest_file}" ]; then
		msg "File ${dest_file} already exists, skipping download."
		return
	fi

	msg "Downloading ${url}..."
	curl ${CURL_OPTS} -o "${dest_file}" "${url}"
}

# Set locale
LC_ALL=POSIX

# Set TERM
TERM=xterm

# Export needed variables
export LC_ALL TERM

msg "Downloading source files needed for next steps..."

download_file "https://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VER}.tar.xz" "${SOURCES}/gettext-${GETTEXT_VER}.tar.xz"
download_file "https://ftp.gnu.org/pub/gnu/bison/bison-${BISON_VER}.tar.xz" "${SOURCES}/bison-${BISON_VER}.tar.xz"
download_file "https://www.cpan.org/src/5.0/perl-${PERL_VER}.tar.xz" "${SOURCES}/perl-${PERL_VER}.tar.xz"
download_file "https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tar.xz" "${SOURCES}/Python-${PYTHON_VER}.tar.xz"
download_file "https://ftp.gnu.org/pub/gnu/texinfo/texinfo-${TEXINFO_VER}.tar.xz" "${SOURCES}/texinfo-${TEXINFO_VER}.tar.xz"
download_file "https://www.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VER%.*}/util-linux-${UTIL_LINUX_VER}.tar.xz" "${SOURCES}/util-linux-${UTIL_LINUX_VER}.tar.xz"

# Make sure directories have root ownership
echo "Setting ownership of $CHROOT_PATH to root..."
chown -R root:root "$CHROOT_PATH"

# Prepare the chroot environment
echo "Setting up chroot environment in $CHROOT_PATH..."
mkdir -pv $CHROOT_PATH/{dev,proc,sys,run}
mknod -m 600 $CHROOT_PATH/dev/console c 5 1
mknod -m 666 $CHROOT_PATH/dev/null c 1 3
mount -v --bind /dev $CHROOT_PATH/dev
mount -vt devpts devpts $CHROOT_PATH/dev/pts -o gid=5,mode=620
mount -vt proc proc $CHROOT_PATH/proc
mount -vt sysfs sysfs $CHROOT_PATH/sys
mount -vt tmpfs tmpfs $CHROOT_PATH/run

if [ -h $CHROOT_PATH/dev/shm ]; then
	echo "Creating directory for /dev/shm"
	mkdir -pv $CHROOT_PATH/$(readlink $CHROOT_PATH/dev/shm)
else
	echo "Mounting /dev/shm"
	mount -t tmpfs -o nosuid,nodev tmpfs $CHROOT_PATH/dev/shm
fi

# Cleanup function
cleanup() {
	echo "Cleaning up chroot environment..."

	umount -v $CHROOT_PATH/dev/pts || true
	umount -v $CHROOT_PATH/dev/shm || true
	umount -v $CHROOT_PATH/dev || true
	umount -v $CHROOT_PATH/run || true
	umount -v $CHROOT_PATH/proc || true
	umount -v $CHROOT_PATH/sys || true

	rm -v $CHROOT_PATH/dev/console || true
	rm -v $CHROOT_PATH/dev/null || true
}

# Set trap to ensure cleanup always runs
trap cleanup EXIT INT TERM

echo "Entering chroot and starting bootstraping process..."

chroot "$CHROOT_PATH" /usr/bin/env -i \
	HOME=/root \
	TERM="$TERM" \
	PS1='\u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin \
	LC_ALL="$LC_ALL" \
	/bin/bash --login +h \
	-c "sh /tmp/chroot_bootstrap.sh"

# Cleanup will be called automatically by the trap

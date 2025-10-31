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

# Make sure "/tmp/chroot_bootstrap.sh" exists
if [ ! -f "$1/tmp/chroot_bootstrap.sh" ]; then
	echo "Error: $1/tmp/chroot_bootstrap.sh is needed but does not exist"
	exit 1
fi

# Script variables
CHROOT_PATH="$1"
CURL_OPTS="-L -s"
ROOTFS="${CHROOT_PATH}"
WORK="${ROOTFS}/tmp/work"
SOURCES="${ROOTFS}/tmp/sources"
ENTER_CHROOT_STANDALONE=${ENTER_CHROOT_STANDALONE:-"false"}

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Set locale
LC_ALL=POSIX

# Set TERM
TERM=xterm

# Export needed variables
export LC_ALL TERM

msg "Starting chroot bootstrap process in $CHROOT_PATH"

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

if [ "$ENTER_CHROOT_STANDALONE" = "true" ]; then
	msg "Entering chroot in standalone mode..."
	chroot "$CHROOT_PATH" /usr/bin/env -i \
		HOME=/root \
		LC_ALL="$LC_ALL" \
		PATH=/usr/bin:/usr/sbin \
		PS1='\u:\w\$ ' \
		TERM="$TERM" \
		/bin/bash --login +h
else
	msg "Running bootstrap script inside chroot..."
	chroot "$CHROOT_PATH" /usr/bin/env -i \
		HOME=/root \
		LC_ALL="$LC_ALL" \
		PATH=/usr/bin:/usr/sbin:/bin:/sbin \
		PS1='\u:\w\$ ' \
		TERM="$TERM" \
		/bin/bash --login +h -c "/tmp/chroot_bootstrap.sh"
fi

# Cleanup will be called automatically by the trap

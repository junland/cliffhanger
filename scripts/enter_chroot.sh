#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Validate running as root
if [ "$EUID" -ne 0 ]; then
	echo "Error: This script must be run as root"
	exit 1
fi

# Validate arguments
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
	echo "Usage: $0 <chroot_path> [stage_number]"
	echo "  chroot_path   - Path to the chroot directory"
	exit 1
fi

CHROOT_PATH="$1"

# Validate chroot path
if [ ! -d "$CHROOT_PATH" ]; then
	echo "Error: Chroot path '$CHROOT_PATH' is not a directory"
	exit 1
fi

# Make sure we have the chroot command available
if ! command -v chroot &>/dev/null; then
	echo "Error: chroot command not found. Please install it and try again."
	exit 1
fi

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Make sure directories have root ownership
echo "Setting ownership of $CHROOT_PATH to root..."
chown -R root:root "$CHROOT_PATH"

# Prepare the chroot environment
echo "Setting up chroot environment in $CHROOT_PATH..."
mkdir -pv $CHROOT_PATH/{dev,proc,sys,run,root,tmp}
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

touch $CHROOT_PATH/etc/chroot_environment

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

	rm -v $CHROOT_PATH/etc/chroot_environment || true
}

# Set trap to ensure cleanup always runs
trap cleanup EXIT INT TERM

echo "Entering chroot ..."

chroot "$CHROOT_PATH" /usr/bin/env -i \
	HOME=/root \
	LC_ALL="$LC_ALL" \
	PATH=/usr/bin:/usr/sbin \
	PS1='\u:\w\$ ' \
	TERM="$TERM" \
	JOBS="$MAKE_JOBS" \
	/bin/bash --login +h

# Cleanup will be called automatically by the trap

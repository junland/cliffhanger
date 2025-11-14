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
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
	echo "Usage: $0 <chroot_path> [stage_number]"
	echo "  chroot_path   - Path to the chroot directory"
	echo "  stage_number  - Bootstrap stage to run (1 or 2, default: 1)"
	exit 1
fi

CHROOT_PATH="$1"
STAGE="${2:-1}"

# Validate chroot path
if [ ! -d "$CHROOT_PATH" ]; then
	echo "Error: Chroot path '$CHROOT_PATH' is not a directory"
	exit 1
fi

# Validate bootstrap script exists
BOOTSTRAP_SCRIPT="${CHROOT_PATH}/tmp/chroot_bootstrap.sh"
if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
	echo "Error: Bootstrap script not found at '$BOOTSTRAP_SCRIPT'"
	echo "Please ensure the bootstrap script is copied to the chroot environment"
	exit 1
fi

# Validate stage number
if ! [[ "$STAGE" =~ ^[1-2]$ ]]; then
	echo "Error: Invalid stage number '$STAGE'"
	echo "Valid stages are: 1 or 2"
	exit 1
fi

# Environment variables
ENTER_CHROOT_STANDALONE=${ENTER_CHROOT_STANDALONE:-"false"}
LC_ALL=POSIX
TERM=xterm

export LC_ALL TERM

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

msg "Starting chroot bootstrap stage $STAGE in $CHROOT_PATH"

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
		/bin/bash --login +h -c "/tmp/chroot_bootstrap.sh ${STAGE}"
fi

# Cleanup will be called automatically by the trap

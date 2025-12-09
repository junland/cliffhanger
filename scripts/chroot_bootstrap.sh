#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Validate running within chroot
if [ ! -f /etc/chroot_environment ]; then
	echo "Error: This script must be run inside the chroot environment"
	exit 1
fi

# Directory variables
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"/tmp/work"}
TARGET_ROOTFS_STEPS_PATH=${TARGET_ROOTFS_STEPS_PATH:-"/tmp/steps"}
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Source common utilities
source "${TARGET_ROOTFS_STEPS_PATH}/_common.sh"

# Source all chroot step files
for step in ${TARGET_ROOTFS_STEPS_PATH}/*_step.sh; do
	msg "Sourcing step file: $step"
	[ -f "$step" ] && source "$step"
done

# Set locale
LC_ALL=POSIX

# Export needed variables
export LC_ALL

clean_work_dir

bootstrap_stage_2() {

	msg "Starting chroot bootstrap stage 2..."

	# Define stage 2 steps
	local stage2_steps=(
		"setup"
		"gettext"
		"bison"
		"perl_stage2"
		"python_stage2"
		"texinfo"
		"util_linux"
		"cleanup"
		"glibc"
		"tzdata"
		"zlib"
		"bzip2"
		"xz"
		"zstd"
		"file"
		"readline"
		"m4"
		"flex"
		"pkgconf"
		"binutils"
		"gmp"
		"mpfr"
		"mpc"
		"attr"
		"acl"
		"libcap"
		"libxcrypt"
		"shadow"
		"gcc"
		"ncurses"
		"sed"
		"bash"
	)

	# Execute each step
	for step in "${stage2_steps[@]}"; do
		# Make sure function exists before calling it.
		if ! declare -f "step_chroot_${step}" >/dev/null; then
			msg "Error: step_chroot_${step} function not found!"
			exit 1
		fi

		step_chroot_${step}
	done

	clean_work_dir

	msg "Chroot bootstrap stage 2 completed successfully."
}

bootstrap_stage_3() {

	msg "Starting chroot bootstrap stage 3..."

	# Define stage 3 steps
	local stage3_steps=(
		"libtool"
		"gdbm"
		"gperf"
		"expat"
		"perl_stage3"
		"inetutils"
		"less"
		"autoconf"
	)

	# Execute each step
	for step in "${stage3_steps[@]}"; do
		# Make sure function exists before calling it.
		if ! declare -f "step_chroot_${step}" >/dev/null; then
			msg "Error: step_chroot_${step} function not found!"
			exit 1
		fi

		step_chroot_${step}
	done

	STAGE=${1:-2}
	# Validate that STAGE is numeric
	if ! [[ "${STAGE}" =~ ^[0-9]+$ ]]; then
		echo "Error: Stage must be a number"
		exit 1
	fi

	msg "Chroot bootstrap stage 3 completed successfully."
}

# Default to stage 2 if no argument is given
STAGE=${1:-2}
if [ "${STAGE}" -eq 2 ]; then
	bootstrap_stage_2
elif [ "${STAGE}" -eq 3 ]; then
	bootstrap_stage_3
else
	echo "Invalid stage: ${STAGE}. Valid stages are 2 and 3."
	exit 1
fi

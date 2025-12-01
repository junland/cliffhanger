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
source "${TARGET_ROOTFS_STEPS_PATH}/steps/_common.sh"

# Source all chroot step files
source "${TARGET_ROOTFS_STEPS_PATH}/steps/setup_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/gettext_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/bison_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/perl_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/python_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/texinfo_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/util_linux_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/cleanup_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/glibc_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/tzdata_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/zlib_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/bzip2_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/xz_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/zstd_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/file_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/readline_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/m4_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/flex_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/pkgconf_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/binutils_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/gmp_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/mpfr_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/mpc_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/attr_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/acl_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/libcap_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/libxcrypt_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/shadow_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/gcc_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/ncurses_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/sed_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/bash_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/libtool_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/gdbm_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/gperf_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/expat_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/perl_stage3_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/inetutils_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/less_step.sh"
source "${TARGET_ROOTFS_STEPS_PATH}/steps/autoconf_step.sh"

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
		step_chroot_${step}
	done

	clean_work_dir

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

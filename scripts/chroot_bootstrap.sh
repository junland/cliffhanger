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

# Version variables
ACL_VER="2.3.2"
ATTR_VER="2.5.2"
BASH_VER="5.3"
BINUTILS_VER="2.45"
BISON_VER="3.8.2"
BZIP2_VER="1.0.8"
COREUTILS_VER="9.7"
DIFFUTILS_VER="3.12"
EXPAT_VER="2.7.1"
FILE_VER="5.46"
FINDUTILS_VER="4.10.0"
FLEX_VER="2.6.4"
GAWK_VER="5.3.2"
GCC_VER="15.2.0"
GDBM_VER="1.26"
GETTEXT_VER="0.26"
GLIBC_VER="2.42"
GMP_VER="6.3.0"
GPERF_VER="3.3"
GREP_VER="3.12"
GZIP_VER="1.13"
LIBCAP_VER="2.76"
LIBTOOL_VER="2.5.4"
LIBXCRPT_VER="4.4.38"
LINUX_VER="6.16.1"
M4_VER="1.4.20"
MAKE_VER="4.4.1"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
NCURSES_VER="6.5-20250809"
PATCH_VER="2.7.6"
PERL_VER="5.42.0"
PKGCONF_VER="2.5.1"
PYTHON_VER="3.13.7"
READLINE_VER="8.3"
SED_VER="4.9"
SHADOW_VER="4.18.0"
TAR_VER="1.35"
TEXINFO_VER="7.2"
TZ_DATA_VER="2025b"
UTIL_LINUX_VER="2.41.1"
XZ_VER="5.8.1"
ZLIB_VER="1.3.1"
ZSTD_VER="1.5.7"
LESS_VER="679"
INETUTILS_VER="2.6"
AUTOCONF_VER="2.72"

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

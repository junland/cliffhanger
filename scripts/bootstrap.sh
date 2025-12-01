#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Locale, directory, and architecture variables
TARGET_CPU_ARCH=${TARGET_CPU_ARCH:-"x86_64"}
TARGET_ROOTFS_PATH=${TARGET_ROOTFS_PATH:-"${PWD}/rootfs"}
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"${TARGET_ROOTFS_PATH}/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"${TARGET_ROOTFS_PATH}/tmp/work"}
TARGET_TRIPLET=${TARGET_TRIPLET:-"${TARGET_CPU_ARCH}-buildroot-linux-gnu"}
TOOLCHAIN_PATH=${TOOLCHAIN_PATH:-"${TARGET_ROOTFS_PATH}/toolchain"}
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
LINUX_VER="6.16.1"
M4_VER="1.4.20"
MAKE_VER="4.4.1"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
NCURSES_VER="6.5-20250809"
PATCH_VER="2.7.6"
SED_VER="4.9"
TAR_VER="1.35"
XZ_VER="5.8.1"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/steps/_common.sh"

# Source all step files
source "${SCRIPT_DIR}/steps/binutils_pass1_step.sh"
source "${SCRIPT_DIR}/steps/gcc_pass1_step.sh"
source "${SCRIPT_DIR}/steps/linux_headers_step.sh"
source "${SCRIPT_DIR}/steps/glibc_step.sh"
source "${SCRIPT_DIR}/steps/libstdcxx_step.sh"
source "${SCRIPT_DIR}/steps/m4_step.sh"
source "${SCRIPT_DIR}/steps/ncurses_step.sh"
source "${SCRIPT_DIR}/steps/bash_step.sh"
source "${SCRIPT_DIR}/steps/coreutils_step.sh"
source "${SCRIPT_DIR}/steps/diffutils_step.sh"
source "${SCRIPT_DIR}/steps/file_step.sh"
source "${SCRIPT_DIR}/steps/findutils_step.sh"
source "${SCRIPT_DIR}/steps/gawk_step.sh"
source "${SCRIPT_DIR}/steps/grep_step.sh"
source "${SCRIPT_DIR}/steps/gzip_step.sh"
source "${SCRIPT_DIR}/steps/make_step.sh"
source "${SCRIPT_DIR}/steps/patch_step.sh"
source "${SCRIPT_DIR}/steps/sed_step.sh"
source "${SCRIPT_DIR}/steps/tar_step.sh"
source "${SCRIPT_DIR}/steps/xz_step.sh"
source "${SCRIPT_DIR}/steps/binutils_pass2_step.sh"
source "${SCRIPT_DIR}/steps/gcc_pass2_step.sh"

# Setup PATH
PATH="${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin"

echo "export PATH=${TOOLCHAIN_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin" >"$PWD"/.env

# Set CONFIG_SITE for cross-compilation
CONFIG_SITE="${TARGET_ROOTFS_PATH}/usr/share/config.site"

echo "export CONFIG_SITE=${TARGET_ROOTFS_PATH}/usr/share/config.site" >>"$PWD"/.env

# Set locale
LC_ALL=POSIX

echo "export LC_ALL=POSIX" >>"$PWD"/.env

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
	msg "Creating symlink $TARGET_ROOTFS_PATH/$i -> usr/$i"
	ln -sv usr/$i "$TARGET_ROOTFS_PATH"/$i
done

msg "Creating symlink $TARGET_ROOTFS_PATH/lib64 -> usr/lib"
ln -sv usr/lib "$TARGET_ROOTFS_PATH"/lib64

# Clean work directory before starting, just in case
clean_work_dir

msg "Starting bootstrap stage 1..."

##
# binutils Step
##
step_binutils_pass1

##
# gcc Step (1st Pass - Part A)
##
step_gcc_pass1

##
# linux-headers Step
##
step_linux_headers

##
# glibc Step
##
step_glibc

##
# gcc - libstdc++ Step (1st Pass - Part B)
##
step_libstdcxx

##
# Temporary Tools Installed
##

##
# m4 Step
##
step_m4

##
# ncurses Step
##
step_ncurses

##
# bash Step
##
step_bash

##
# coreutils Step
##
step_coreutils

##
# diffutils
##
step_diffutils

##
# file Step
##
step_file

##
# findutils Step
##
step_findutils

##
# gawk Step
##
step_gawk

##
# grep Step
##
step_grep

##
# gzip Step
##
step_gzip

##
# make Step
##
step_make

##
# patch Step
##
step_patch

##
# sed Step
##
step_sed

##
# tar Step
##
step_tar

##
# xz Step
##
step_xz

##
# binutils Step
##
step_binutils_pass2

##
# gcc Step
##
step_gcc_pass2

if [ "${EXIT_AFTER_TEMP_TOOLS}" = true ]; then
	msg "Exiting after temporary tools installation as requested."
	exit 0
fi

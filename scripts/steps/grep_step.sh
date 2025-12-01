#!/bin/bash
# Grep Step - Build and install grep

GREP_VER="3.12"

step_grep() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/grep-${GREP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/grep-${GREP_VER}"

	msg "Configuring grep..."

	cd "${TARGET_ROOTFS_WORK_PATH}/grep-${GREP_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building grep..."

	make

	msg "Installing grep..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

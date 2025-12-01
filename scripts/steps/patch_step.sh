#!/bin/bash
# Patch Step - Build and install patch

PATCH_VER="2.7.6"

step_patch() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/patch-${PATCH_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/patch-${PATCH_VER}"

	msg "Configuring patch..."

	cd "${TARGET_ROOTFS_WORK_PATH}/patch-${PATCH_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building patch..."

	make

	msg "Installing patch..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

#!/bin/bash
# Findutils Step - Build and install findutils

step_findutils() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/findutils-${FINDUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/findutils-${FINDUTILS_VER}"

	msg "Configuring findutils..."

	cd "${TARGET_ROOTFS_WORK_PATH}/findutils-${FINDUTILS_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building findutils..."

	make

	msg "Installing findutils..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

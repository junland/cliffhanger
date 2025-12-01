#!/bin/bash
# Sed Step - Build and install sed

step_sed() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/sed-${SED_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/sed-${SED_VER}"

	msg "Configuring sed..."

	cd "${TARGET_ROOTFS_WORK_PATH}/sed-${SED_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building sed..."

	make

	msg "Installing sed..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

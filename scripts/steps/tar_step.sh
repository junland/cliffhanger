#!/bin/bash
# Tar Step - Build and install tar

TAR_VER="1.35"

step_tar() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/tar-${TAR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/tar-${TAR_VER}"

	msg "Configuring tar..."

	cd "${TARGET_ROOTFS_WORK_PATH}/tar-${TAR_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building tar..."

	make

	msg "Installing tar..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

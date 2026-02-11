#!/bin/bash
# Diffutils Step - Build and install diffutils

DIFFUTILS_VER="3.12"

step_diffutils() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/diffutils-${DIFFUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/diffutils-${DIFFUTILS_VER}"

	msg "Configuring diffutils..."

	cd "${TARGET_ROOTFS_WORK_PATH}/diffutils-${DIFFUTILS_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	msg "Configuring diffutils..."

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(./config.guess)"

	msg "Building diffutils..."

	make

	msg "Installing diffutils..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_diffutils() {
	extract_file "${SOURCES}/diffutils-${DIFFUTILS_VER}.tar.xz" "${WORK}/diffutils-${DIFFUTILS_VER}"

	cd "${WORK}/diffutils-${DIFFUTILS_VER}"

	msg "Configuring diffutils..."

	./configure --prefix=/usr

	msg "Building diffutils..."

	make

	msg "Checking diffutils..."

	make check

	msg "Installing diffutils..."

	make install

	clean_work_dir
}

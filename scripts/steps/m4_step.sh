#!/bin/bash
# M4 Step - Build and install m4

step_m4() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/m4-${M4_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

	msg "Preparing m4 build environment..."

	cd "${TARGET_ROOTFS_WORK_PATH}/m4-${M4_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	msg "Configuring m4..."

	./configure --prefix=/usr --host="${TARGET_TRIPLET}" --build="$(build-aux/config.guess)"

	msg "Building m4..."

	make

	msg "Installing m4..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

step_chroot_m4() {
	extract_file "${SOURCES}/m4-${M4_VER}.tar.xz" "${WORK}/m4-${M4_VER}"

	cd "${WORK}/m4-${M4_VER}"

	msg "Configuring m4..."

	./configure --prefix=/usr

	msg "Building m4..."

	make

	msg "Checking m4..."

	make check

	msg "Installing m4..."

	make install

	clean_work_dir
}

#!/bin/bash
# Gawk Step - Build and install gawk

step_gawk() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gawk-${GAWK_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gawk-${GAWK_VER}"

	msg "Configuring gawk..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gawk-${GAWK_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	sed -i 's/extras//' Makefile.in

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)"

	msg "Building gawk..."

	make

	msg "Installing gawk..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	clean_work_dir
}

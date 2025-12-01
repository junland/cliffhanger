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

step_chroot_sed() {
	extract_file "${SOURCES}/sed-${SED_VER}.tar.xz" "${WORK}/sed-${SED_VER}"

	cd "${WORK}/sed-${SED_VER}"

	msg "Configuring sed..."

	./configure --prefix=/usr

	msg "Building sed..."

	make

	msg "Checking sed..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Installing sed..."

	make install

	clean_work_dir
}

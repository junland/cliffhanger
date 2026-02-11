#!/bin/bash
# Gawk Step - Build and install gawk

GAWK_VER="5.3.2"

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

step_chroot_gawk() {
	extract_file "${SOURCES}/gawk-${GAWK_VER}.tar.xz" "${WORK}/gawk-${GAWK_VER}"

	cd "${WORK}/gawk-${GAWK_VER}"

	msg "Configuring gawk..."

	sed -i 's/extras//' Makefile.in

	./configure --prefix=/usr

	msg "Building gawk..."

	make

	msg "Checking gawk..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Installing gawk..."

	make install

	clean_work_dir
}

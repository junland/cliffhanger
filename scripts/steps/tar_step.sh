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

step_chroot_tar() {
	extract_file "${SOURCES}/tar-${TAR_VER}.tar.xz" "${WORK}/tar-${TAR_VER}"

	cd "${WORK}/tar-${TAR_VER}"

	msg "Configuring tar..."

	FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr

	msg "Building tar..."

	make

	msg "Checking tar..."

	make check

	msg "Installing tar..."

	make install

	clean_work_dir
}

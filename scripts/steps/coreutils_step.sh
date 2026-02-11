#!/bin/bash
# Coreutils Step - Build and install coreutils

COREUTILS_VER="9.7"

step_coreutils() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/coreutils-${COREUTILS_VER}"

	msg "Configuring coreutils..."

	cd "${TARGET_ROOTFS_WORK_PATH}/coreutils-${COREUTILS_VER}"

	msg "Patching coreutils..."

	patch -Np1 -i "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}-upstream_fix-1.patch"
	patch -Np1 -i "${TARGET_ROOTFS_SOURCES_PATH}/coreutils-${COREUTILS_VER}-i18n-1.patch"

	# Reconfigure to point to our version of automake
	autoreconf -f

	./configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(build-aux/config.guess)" \
		--enable-install-program=hostname \
		--enable-no-install-program=kill,uptime

	msg "Building coreutils..."

	make

	msg "Installing coreutils..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	mv -v "$TARGET_ROOTFS_PATH"/usr/bin/chroot "$TARGET_ROOTFS_PATH"/usr/sbin
	mkdir -pv "$TARGET_ROOTFS_PATH"/usr/share/man/man8
	mv -v "$TARGET_ROOTFS_PATH"/usr/share/man/man1/chroot.1 "$TARGET_ROOTFS_PATH"/usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' "$TARGET_ROOTFS_PATH"/usr/share/man/man8/chroot.8

	clean_work_dir
}

step_chroot_coreutils() {
	extract_file "${SOURCES}/coreutils-${COREUTILS_VER}.tar.xz" "${WORK}/coreutils-${COREUTILS_VER}"

	cd "${WORK}/coreutils-${COREUTILS_VER}"

	msg "Patching coreutils..."

	patch -Np1 -i "${SOURCES}/coreutils-${COREUTILS_VER}-upstream_fix-1.patch"
	patch -Np1 -i "${SOURCES}/coreutils-${COREUTILS_VER}-i18n-1.patch"

	msg "Configuring coreutils..."

	./configure \
		--prefix=/usr \
		--enable-install-program=hostname \
		--enable-no-install-program=kill,uptime

	msg "Building coreutils..."

	make

	msg "Checking coreutils..."

	make check

	msg "Installing coreutils..."

	make install

	mv -v /usr/bin/chroot /usr/sbin
	mkdir -pv /usr/share/man/man8
	mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

	clean_work_dir
}

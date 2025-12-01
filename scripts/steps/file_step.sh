#!/bin/bash
# File Step - Build and install file command

FILE_VER="5.46"

step_file() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/file-${FILE_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/file-${FILE_VER}"

	msg "Configuring temp file command..."

	cd "${TARGET_ROOTFS_WORK_PATH}/file-${FILE_VER}"

	# Reconfigure to point to our version of automake
	autoreconf -f

	mkdir build

	pushd build

	../configure \
		--disable-bzlib \
		--disable-libseccomp \
		--disable-xzlib \
		--disable-zlib

	msg "Building temp file command..."

	make

	popd

	msg "Configuring file..."

	./configure --prefix=/usr --host="${TARGET_TRIPLET}" --build="$(./config.guess)"

	msg "Building file..."

	make FILE_COMPILE="$(pwd)/build/src/file"

	msg "Installing file..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/libmagic.la

	clean_work_dir
}

step_chroot_file() {
	extract_file "${SOURCES}/file-${FILE_VER}.tar.gz" "${WORK}/file-${FILE_VER}"

	cd "${WORK}/file-${FILE_VER}"

	msg "Configuring file..."

	./configure --prefix=/usr

	msg "Building file..."

	make

	msg "Checking file..."

	make check

	msg "Installing file..."

	make install

	clean_work_dir
}
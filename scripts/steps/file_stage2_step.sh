#!/bin/bash
# File Step (Stage 2) - Build and install file in chroot

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

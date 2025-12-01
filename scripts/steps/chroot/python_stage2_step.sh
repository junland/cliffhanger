#!/bin/bash
# Python Step (Stage 2) - Build and install Python in chroot

step_chroot_python_stage2() {
	extract_file "${SOURCES}/Python-${PYTHON_VER}.tar.xz" "${WORK}/Python-${PYTHON_VER}"

	cd "${WORK}/Python-${PYTHON_VER}"

	msg "Configuring Python..."

	./configure \
		--prefix=/usr \
		--enable-shared \
		--without-ensurepip \
		--without-static-libpython

	msg "Building Python..."

	make

	msg "Installing Python..."

	make install

	clean_work_dir
}

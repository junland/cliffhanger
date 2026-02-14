#!/bin/bash
# Libpipeline Step - Build and install libpipeline in chroot

LIBPIPELINE_VER="1.5.7"

step_chroot_libpipeline() {
	extract_file "${SOURCES}/libpipeline-${LIBPIPELINE_VER}.tar.gz" "${WORK}/libpipeline-${LIBPIPELINE_VER}"

	cd "${WORK}/libpipeline-${LIBPIPELINE_VER}"

	msg "Configuring libpipeline..."

	./configure --prefix=/usr

	msg "Building libpipeline..."

	make

	msg "Checking libpipeline..."

	make check

	msg "Installing libpipeline..."

	make install

	clean_work_dir
}

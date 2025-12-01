#!/bin/bash
# M4 Step (Stage 2) - Build and install m4 in chroot

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

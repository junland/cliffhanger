#!/bin/bash
# Automake Step - Build and install automake in chroot

AUTOMAKE_VER="1.18.1"

step_chroot_automake() {
	extract_file "${SOURCES}/automake-${AUTOMAKE_VER}.tar.xz" "${WORK}/automake-${AUTOMAKE_VER}"

	cd "${WORK}/automake-${AUTOMAKE_VER}"

	msg "Configuring automake..."

	./configure --prefix=/usr

	msg "Building automake..."

	make

	msg "Checking automake..."

	make -j$(($(nproc) > 4 ? $(nproc) : 4)) check

	msg "Installing automake..."

	make install

	clean_work_dir
}

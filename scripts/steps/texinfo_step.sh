#!/bin/bash
# Texinfo Step - Build and install texinfo in chroot

step_chroot_texinfo() {
	extract_file "${SOURCES}/texinfo-${TEXINFO_VER}.tar.xz" "${WORK}/texinfo-${TEXINFO_VER}"

	cd "${WORK}/texinfo-${TEXINFO_VER}"

	msg "Configuring texinfo..."

	./configure --prefix=/usr

	msg "Building texinfo..."

	make

	msg "Installing texinfo..."

	make install

	clean_work_dir
}

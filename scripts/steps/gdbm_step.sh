#!/bin/bash
# GDBM Step - Build and install gdbm in chroot

step_chroot_gdbm() {
	extract_file "${SOURCES}/gdbm-${GDBM_VER}.tar.gz" "${WORK}/gdbm-${GDBM_VER}"

	cd "${WORK}/gdbm-${GDBM_VER}"

	msg "Configuring gdbm..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--enable-libgdbm-compat

	msg "Building gdbm..."

	make

	msg "Checking gdbm..."

	make check

	msg "Installing gdbm..."

	make install

	clean_work_dir
}

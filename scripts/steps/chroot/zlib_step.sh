#!/bin/bash
# Zlib Step - Build and install zlib in chroot

step_chroot_zlib() {
	extract_file "${SOURCES}/zlib-${ZLIB_VER}.tar.xz" "${WORK}/zlib-${ZLIB_VER}"

	cd "${WORK}/zlib-${ZLIB_VER}"

	msg "Configuring zlib..."

	./configure --prefix=/usr

	msg "Building zlib..."

	make

	msg "Checking zlib..."

	make test

	msg "Installing zlib..."

	make install

	rm -fv /usr/lib/libz.a

	clean_work_dir
}

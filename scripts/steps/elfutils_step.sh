#!/bin/bash
# elfutils Step - Build and install libelf in chroot

ELFUTILS_VER="0.193"

step_chroot_elfutils_lib() {
	extract_file "${SOURCES}/elfutils-${ELFUTILS_VER}.tar.bz2" "${WORK}/elfutils-${ELFUTILS_VER}"

	cd "${WORK}/elfutils-${ELFUTILS_VER}"

	msg "Configuring elfutils-lib..."

	./configure \
		--prefix=/usr \
		--disable-debuginfod \
		--enable-libdebuginfod=dummy

	msg "Building elfutils-lib..."

	make

	msg "Checking elfutils-lib..."

    # Run the test suite but also point the location of libelf to avoid test failures
	LD_LIBRARY_PATH=$(pwd)/libelf make check
	
	msg "Installing elfutils-lib..."

	make -C libelf install

	install -vm644 config/libelf.pc /usr/lib/pkgconfig

	rm -v /usr/lib/libelf.a

	clean_work_dir
}

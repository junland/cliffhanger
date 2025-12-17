#!/bin/bash
# libffi Step - Build and install libffi in chroot

LIBFFI_VER="3.5.2"

step_libffi() {
	extract_file "${SOURCES}/libffi-${LIBFFI_VER}.tar.gz" "${WORK}/libffi-${LIBFFI_VER}"

	cd "${WORK}/libffi-${LIBFFI_VER}"

	msg "Configuring libffi..."

	GCC_ARCH=$(gcc -march=native -Q --help=target | grep march | cut -d' ' -f2)

	msg "Detected GCC architecture: ${GCC_ARCH}"

	./configure \
		--prefix=/usr \
		--disable-static \
		--with-gcc-arch=${GCC_ARCH}

	msg "Building libffi..."

	make

	msg "Checking libffi..."

	make check

	msg "Installing libffi..."

	make install

	clean_work_dir
}

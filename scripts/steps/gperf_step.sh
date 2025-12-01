#!/bin/bash
# Gperf Step - Build and install gperf in chroot

step_chroot_gperf() {
	extract_file "${SOURCES}/gperf-${GPERF_VER}.tar.gz" "${WORK}/gperf-${GPERF_VER}"

	cd "${WORK}/gperf-${GPERF_VER}"

	msg "Configuring gperf..."

	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/gperf-${GPERF_VER}

	msg "Building gperf..."

	make

	msg "Checking gperf..."

	make check

	msg "Installing gperf..."

	make install

	clean_work_dir
}

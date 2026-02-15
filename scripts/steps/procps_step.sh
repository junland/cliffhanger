#!/bin/bash
# Procps-ng Step - Build and install procps-ng in chroot

PROCPS_VER="4.0.5"

step_chroot_procps_ng() {
	extract_file "${SOURCES}/procps-v${PROCPS_VER}.tar.bz2" "${WORK}/procps-v${PROCPS_VER}"

	cd "${WORK}/procps-v${PROCPS_VER}"

	msg "Configuring procps-ng..."

	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/procps-ng-${PROCPS_VER} \
		--disable-static \
		--enable-watch8bit \
		--disable-kill \
		--with-systemd

	msg "Building procps-ng..."

	make

	msg "Checking procps-ng..."

	chown -R tester .
	
    su tester -c "PATH=$PATH make check"

	msg "Installing procps-ng..."

	make install

	clean_work_dir
}

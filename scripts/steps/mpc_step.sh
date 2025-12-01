#!/bin/bash
# MPC Step - Build and install mpc in chroot

step_chroot_mpc() {
	extract_file "${SOURCES}/mpc-${MPC_VER}.tar.gz" "${WORK}/mpc-${MPC_VER}"

	cd "${WORK}/mpc-${MPC_VER}"

	msg "Configuring mpc..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/mpc-${MPC_VER}

	msg "Building mpc..."

	make

	msg "Checking mpc..."

	make check

	msg "Installing mpc..."

	make install

	clean_work_dir
}

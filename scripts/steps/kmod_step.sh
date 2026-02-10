#!/bin/bash
# kmod Step - Build and install kmod in chroot

KMOD_VER="34.2"

step_chroot_kmod() {
	extract_file "${SOURCES}/kmod-${KMOD_VER}.tar.gz" "${WORK}/kmod-${KMOD_VER}"

	cd "${WORK}/kmod-${KMOD_VER}"

	msg "Configuring kmod..."

	mkdir build
	cd    build

	meson setup .. \
		--prefix=/usr \
		--buildtype=release \
		-Dmanpages=false \
		-Ddocs=false

	msg "Building kmod..."

	ninja

	msg "Installing kmod..."

	ninja install

	# Create symlinks for backwards compatibility
	for target in depmod insmod modinfo modprobe rmmod; do
		ln -sfv kmod /usr/bin/$target
	done

	ln -sfv kmod /usr/sbin/lsmod

	clean_work_dir
}

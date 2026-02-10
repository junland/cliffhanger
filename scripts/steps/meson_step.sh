#!/bin/bash
# Meson Step - Build and install meson in chroot

MESON_VER="1.8.3"

step_chroot_meson() {
	extract_file "${SOURCES}/meson-${MESON_VER}.tar.gz" "${WORK}/meson-${MESON_VER}"

	cd "${WORK}/meson-${MESON_VER}"

	msg "Building meson..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing meson..."

	pip3 install --no-index --find-links dist meson

	clean_work_dir
}

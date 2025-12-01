#!/bin/bash
# Linux Headers Step - Install kernel headers

step_linux_headers() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/linux-${LINUX_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/linux-${LINUX_VER}"

	msg "Confirming files..."

	cd "${TARGET_ROOTFS_WORK_PATH}/linux-${LINUX_VER}"

	make mrproper

	msg "Building headers..."

	make headers

	msg "Installing headers..."

	find usr/include -type f ! -name '*.h' -delete

	mkdir -vp "${TARGET_ROOTFS_PATH}/usr"

	cp -rv usr/include "${TARGET_ROOTFS_PATH}/usr"

	clean_work_dir
}

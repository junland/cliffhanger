#!/bin/bash
# python-wheel Step - Build and install wheel module in chroot

PYTHON_WHEEL_VER="0.46.1"

step_chroot_python_wheel() {
	extract_file "${SOURCES}/wheel-${PYTHON_WHEEL_VER}.tar.gz" "${WORK}/wheel-${PYTHON_WHEEL_VER}"

	cd "${WORK}/wheel-${PYTHON_WHEEL_VER}"

	msg "Building wheel..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing wheel..."

	pip3 install --no-index --find-links dist wheel

	clean_work_dir
}
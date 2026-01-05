#!/bin/bash
# python-packaging Step - Build and install packaging module in chroot

PYTHON_PACKAGING_VER="25.0"

step_chroot_python_packaging() {
	extract_file "${SOURCES}/packaging-${PYTHON_PACKAGING_VER}.tar.gz" "${WORK}/packaging-${PYTHON_PACKAGING_VER}"

	cd "${WORK}/packaging-${PYTHON_PACKAGING_VER}"

	msg "Building packaging..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing packaging..."

	pip3 install --no-index --find-links dist packaging

	clean_work_dir
}


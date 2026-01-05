#!/bin/bash
# python-setuptools Step - Build and install setuptools module in chroot

PYTHON_SETUPTOOLS_VER="80.9.0"

step_chroot_python_setuptools() {
	extract_file "${SOURCES}/setuptools-${PYTHON_SETUPTOOLS_VER}.tar.gz" "${WORK}/setuptools-${PYTHON_SETUPTOOLS_VER}"

	cd "${WORK}/setuptools-${PYTHON_SETUPTOOLS_VER}"

	msg "Building setuptools..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing setuptools..."

	pip3 install --no-index --find-links dist setuptools

	clean_work_dir
}
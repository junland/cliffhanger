#!/bin/bash
# flint-core Step - Build and install Flintcore in chroot

FLINT_CORE_VER="3.12.0"

step_chroot_flint_core() {
	extract_file "${SOURCES}/flint_core-${FLINT_CORE_VER}.tar.gz" "${WORK}/flint_core-${FLINT_CORE_VER}"

	cd "${WORK}/flint_core-${FLINT_CORE_VER}"

	msg "Building Flintcore..."

	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

	msg "Installing Flintcore..."

	pip3 install --no-index --find-links dist flit_core

	clean_work_dir
}
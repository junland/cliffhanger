#!/bin/bash
# Python Step (Stage 2) - Build and install Python in chroot

PYTHON_VER="3.13.8"

step_chroot_python_stage2() {
	extract_file "${SOURCES}/Python-${PYTHON_VER}.tar.xz" "${WORK}/Python-${PYTHON_VER}"

	cd "${WORK}/Python-${PYTHON_VER}"

	msg "Configuring Python..."

	./configure \
		--prefix=/usr \
		--enable-shared \
		--without-ensurepip \
		--without-static-libpython

	msg "Building Python..."

	make

	msg "Installing Python..."

	make install

	clean_work_dir
}

step_chroot_python_stage3() {
	extract_file "${SOURCES}/Python-${PYTHON_VER}.tar.xz" "${WORK}/Python-${PYTHON_VER}"

	cd "${WORK}/Python-${PYTHON_VER}"

	msg "Debug before configure - TERM = $TERM"

	msg "Configuring Python..."

	./configure \
		--prefix=/usr \
		--enable-shared \
		--with-system-expat \
		--enable-optimizations \
		--without-static-libpython

	msg "Building Python..."

	msg "Debug before make - TERM = $TERM"

	make

	msg "Debug after make - TERM = $TERM"

	msg "Checking Python..."

	msg "Debug before make test - TERM = $TERM"

	make test TESTOPTS="--timeout 600"

	msg "Installing Python..."

	make install

	cat >/etc/pip.conf <<EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

	clean_work_dir
}

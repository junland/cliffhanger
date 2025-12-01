#!/bin/bash
# GMP Step - Build and install gmp in chroot

step_chroot_gmp() {
	extract_file "${SOURCES}/gmp-${GMP_VER}.tar.xz" "${WORK}/gmp-${GMP_VER}"

	cd "${WORK}/gmp-${GMP_VER}"

	msg "Configuring gmp..."

	sed -i '/long long t1;/,+1s/()/(...)/' configure

	./configure \
		--prefix=/usr \
		--enable-cxx \
		--disable-static \
		--docdir=/usr/share/doc/gmp-${GMP_VER}

	msg "Building gmp..."

	make

	msg "Checking gmp..."

	make check 2>&1 | tee gmp-check-log

	# Also make sure 199 tests passed
	if awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log; then
		msg "All gmp tests passed."
	else
		msg "Error: Some gmp tests failed."
		exit 1
	fi

	msg "Installing gmp..."

	make install

	clean_work_dir
}

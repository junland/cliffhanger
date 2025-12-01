#!/bin/bash
# Bzip2 Step - Build and install bzip2 in chroot

step_chroot_bzip2() {
	extract_file "${SOURCES}/bzip2-${BZIP2_VER}.tar.gz" "${WORK}/bzip2-${BZIP2_VER}"

	cd "${WORK}/bzip2-${BZIP2_VER}"

	msg "Configuring bzip2..."

	sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

	make -f Makefile-libbz2_so

	make clean

	msg "Building bzip2..."

	make

	msg "Installing bzip2..."

	make install PREFIX=/usr

	cp -av libbz2.so.* /usr/lib
	cp -v bzip2-shared /usr/bin/bzip2
	ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

	for i in /usr/bin/{bzcat,bunzip2}; do
		ln -sfv bzip2 $i
	done

	rm -fv /usr/lib/libbz2.a

	clean_work_dir
}

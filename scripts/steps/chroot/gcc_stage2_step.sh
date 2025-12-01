#!/bin/bash
# GCC Step (Stage 2) - Build and install gcc in chroot

step_chroot_gcc() {
	extract_file "${SOURCES}/gcc-${GCC_VER}.tar.xz" "${WORK}/gcc-${GCC_VER}"

	cd "${WORK}/gcc-${GCC_VER}"

	msg "Configuring gcc..."

	case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/i386/t-linux64
		;;
	aarch64)
		sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/aarch64/t-linux64
		;;
	esac

	mkdir -v build

	cd build

	LD=ld \
		../configure \
		--prefix=/usr \
		--enable-languages=c,c++ \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-host-pie \
		--disable-multilib \
		--disable-bootstrap \
		--disable-fixincludes \
		--with-system-zlib

	msg "Building gcc..."

	make

	msg "Setting up for gcc checks..."

	ulimit -s -H unlimited

	sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp

	msg "Checking gcc..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Extractring gcc check results..."

	../contrib/test_summary

	msg "Installing gcc..."

	make install

	chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}

	ln -svr /usr/bin/cpp /usr/lib

	ln -svf ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

	mkdir -pv /usr/share/gdb/auto-load/usr/lib

	mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

	clean_work_dir
}

#!/bin/bash
# GCC Step - Cross-compiler GCC

GCC_VER="15.2.0"
GMP_VER="6.3.0"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
GLIBC_VER="2.42"

step_gcc_pass1() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	msg "Configuring gcc..."

	case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
		;;
	esac

	mkdir -v build

	cd build

	../configure \
		--prefix="${TOOLCHAIN_PATH}" \
		--target="${TARGET_TRIPLET}" \
		--with-glibc-version="${GLIBC_VER}" \
		--with-sysroot="${TARGET_ROOTFS_PATH}" \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libstdcxx \
		--disable-libvtv \
		--disable-multilib \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-languages=c,c++ \
		--with-newlib \
		--without-headers

	msg "Building gcc..."

	make

	msg "Installing gcc..."

	make install

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	cat gcc/limitx.h gcc/glimits.h gcc/limity.h >"$(dirname $("$TARGET_TRIPLET"-gcc -print-libgcc-file-name))/include/limits.h"

	clean_work_dir
}

step_gcc_pass2() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	msg "Configuring gcc..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	case $(uname -m) in
	x86_64)
		sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
		;;
	esac

	sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

	mkdir -v build

	cd build

	../configure \
		--build="$(../config.guess)" \
		--host="${TARGET_TRIPLET}" \
		--target="${TARGET_TRIPLET}" \
		LDFLAGS_FOR_TARGET=-L"$PWD"/"${TARGET_TRIPLET}"/libgcc \
		--prefix=/usr \
		--with-build-sysroot="${TARGET_ROOTFS_PATH}" \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-multilib \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libvtv \
		--enable-languages=c,c++

	msg "Building gcc..."

	make

	msg "Installing gcc..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	ln -svf gcc "${TARGET_ROOTFS_PATH}"/usr/bin/cc

	clean_work_dir
}

step_gcc_libstdcxx() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gcc-${GCC_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/gmp-${GMP_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/gmp"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpc-${MPC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpc"
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/mpfr-${MPFR_VER}.tar.xz" "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}/mpfr"

	msg "Configuring gcc for libstdc++..."

	cd "${TARGET_ROOTFS_WORK_PATH}/gcc-${GCC_VER}"

	TOOLCHAIN_BASE_DIR=$(basename "${TOOLCHAIN_PATH}")

	msg "Using toolchain base dir: ${TOOLCHAIN_BASE_DIR}"

	mkdir -vp build

	cd build

	../libstdc++-v3/configure \
		--host="${TARGET_TRIPLET}" \
		--build="$(../config.guess)" \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir="/${TOOLCHAIN_BASE_DIR}/${TARGET_TRIPLET}/include/c++/${GCC_VER}"

	msg "Building gcc for libstdc++..."

	make

	msg "Installing gcc for libstdc++..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	rm -v "${TARGET_ROOTFS_PATH}"/usr/lib/lib{stdc++{,exp,fs},supc++}.la

	clean_work_dir
}

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

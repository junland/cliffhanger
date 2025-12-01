#!/bin/bash
# Glibc Step - Build and install glibc

step_glibc() {
	extract_file "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}.tar.gz" "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}"

	msg "Configuring glibc..."

	cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}"

	case ${TARGET_CPU_ARCH} in
	i?86)
		ln -sfv ld-linux.so.2 "${TARGET_ROOTFS_PATH}/lib/ld-lsb.so.3"
		;;
	x86_64)
		ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}/lib64"
		ln -sfv ../lib/ld-linux-x86-64.so.2 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-x86-64.so.3"
		;;
	aarch64)
		ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}/lib64"
		ln -sfv ../lib/ld-linux-aarch64.so.1 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-aarch64.so.3"
		;;
	riscv64)
		ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}/lib64"
		ln -sfv ../lib/ld-linux-riscv64.so.1 "${TARGET_ROOTFS_PATH}/lib64/ld-lsb-riscv64.so.3"
		;;
	*)
		echo "Unknown architecture: ${TARGET_CPU_ARCH}"
		exit 1
		;;
	esac

	patch -Np1 -i "${TARGET_ROOTFS_SOURCES_PATH}/glibc-${GLIBC_VER}-fhs-1.patch"

	mkdir -vp "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

	cd "${TARGET_ROOTFS_WORK_PATH}/glibc-${GLIBC_VER}/build"

	# Make sure bash hashing is disabled for glibc build
	unset -f hash

	echo "rootsbindir=/usr/sbin" >configparms

	../configure \
		--prefix=/usr \
		--host="${TARGET_TRIPLET}" \
		--build="$(../scripts/config.guess)" \
		--with-headers="${TARGET_ROOTFS_PATH}/usr/include" \
		--enable-kernel=5.4 \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib

	msg "Building glibc..."

	make

	msg "Installing glibc..."

	make install DESTDIR="${TARGET_ROOTFS_PATH}"

	sed '/RTLDLIST=/s@/usr@@g' -i "${TARGET_ROOTFS_PATH}/usr/bin/ldd"

	msg "Verify that compiling and linking works..."

	echo 'int main(){}' | "${TARGET_TRIPLET}"-gcc -xc -

	readelf -l a.out | grep ld-linux

	rm -v a.out

	clean_work_dir
}

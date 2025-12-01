#!/bin/bash
# Glibc Step (Stage 2) - Build and install glibc in chroot

step_chroot_glibc() {
	extract_file "${SOURCES}/glibc-${GLIBC_VER}.tar.gz" "${WORK}/glibc-${GLIBC_VER}"

	cd "${WORK}/glibc-${GLIBC_VER}"

	msg "Patching glibc..."

	patch -Np1 -i "${SOURCES}/glibc-${GLIBC_VER}-fhs-1.patch"

	msg "Configuring glibc..."

	mkdir -v build

	cd build

	echo "rootsbindir=/usr/sbin" >configparms

	../configure \
		--prefix=/usr \
		--disable-werror \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib \
		--enable-stack-protector=strong \
		--enable-kernel=5.4

	msg "Building glibc..."

	make

	msg "Checking glibc..."

	# Disable io/tst-lchmod test as its known to fail in a chroot.
	sed -i "/\btst-lchmod /d" "${WORK}/glibc-${GLIBC_VER}/io/Makefile"

	# Disable stdlib/test-cxa_atexit-race2 test as it its known to fail in a chroot.
	sed -i "/\btest-cxa_atexit-race2 /d" "${WORK}/glibc-${GLIBC_VER}/stdlib/Makefile"

	TIMEOUTFACTOR=15 make check -j1

	# Disable outdated sanity check.
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

	msg "Installing glibc..."

	make install

	#  Fix a hardcoded path to the executable loader in the ldd script
	sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

	# Add ld.so.conf
	cat >/etc/ld.so.conf <<"EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf
# End /etc/ld.so.conf
EOF
}

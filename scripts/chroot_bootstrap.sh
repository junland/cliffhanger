#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

# Directory variables
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"/tmp/work"}
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

# Version variables
ACL_VER="2.3.2"
ATTR_VER="2.5.2"
BASH_VER="5.3"
BINUTILS_VER="2.45"
BISON_VER="3.8.2"
BZIP2_VER="1.0.8"
COREUTILS_VER="9.7"
DIFFUTILS_VER="3.12"
FILE_VER="5.46"
FINDUTILS_VER="4.10.0"
FLEX_VER="2.6.4"
GAWK_VER="5.3.2"
GCC_VER="15.2.0"
GETTEXT_VER="0.26"
GLIBC_VER="2.42"
GMP_VER="6.3.0"
GREP_VER="3.12"
GZIP_VER="1.13"
LIBCAP_VER="2.76"
LIBTOOL_VER="2.5.4"
LIBXCRPT_VER="4.4.38"
LINUX_VER="6.16.1"
M4_VER="1.4.20"
MAKE_VER="4.4.1"
MPC_VER="1.3.1"
MPFR_VER="4.2.2"
NCURSES_VER="6.5-20250809"
PATCH_VER="2.7.6"
PERL_VER="5.42.0"
PKGCONF_VER="2.5.1"
PYTHON_VER="3.13.7"
READLINE_VER="8.3"
SED_VER="4.9"
SHADOW_VER="4.18.0"
TAR_VER="1.35"
TEXINFO_VER="7.2"
TZ_DATA_VER="2025b"
UTIL_LINUX_VER="2.41.1"
XZ_VER="5.8.1"
ZLIB_VER="1.3.1"
ZSTD_VER="1.5.7"

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Clean work directory function
clean_work_dir() {
	cd ${WORK}
	msg "Cleaning up work directory at ${WORK}..."
	rm -rf "${WORK}"/*
}

# Extracts an archive file to a destination directory
extract_file() {
	local archive_file=$1
	local dest_dir=$2

	# Use environment variables with defaults
	local strip_components=${EXTRACT_FILE_STRIP_COMPONENTS:-0}
	local verbose=${EXTRACT_FILE_VERBOSE_EXTRACT:-false}

	# Make sure the archive file exists, if not find another archive file with a different extension.
	if [ ! -f "${archive_file}" ]; then
		msg "Archive file ${archive_file} does not exist, searching for alternative..."
		archive_file=$(find "${SOURCES}" -name "$(basename "${archive_file}" | sed 's/\.[^.]*$//').*")
		if [ ! -f "${archive_file}" ]; then
			msg "Error: Archive file ${archive_file} does not exist."
			exit 1
		fi
		msg "Found alternative archive file: ${archive_file}"
	fi

	mkdir -vp "${dest_dir}"

	msg "Extracting to ${dest_dir}..."

	local verbose_flag=""
	if [ "${verbose}" = true ] || [ "${verbose}" = "true" ]; then
		verbose_flag="-v"
	fi

	# Check to see if we have to strip components based on the archive file has a parent directory
	if [ "${strip_components}" -eq 0 ]; then
		if tar -tf "${archive_file}" | head -1 | grep -q '/'; then
			msg "Archive has a parent directory, setting strip_components to 1"
			strip_components=1
		else
			msg "Archive does not have a parent directory, setting strip_components to 0"
			strip_components=0
		fi
	fi

	case ${archive_file} in
	*.tar.bz2 | *.tbz2)
		tar -xjf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.tar.xz | *.txz)
		tar -xJf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.tar.gz | *.tgz)
		tar -xzf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ${verbose_flag}
		;;
	*.zip)
		unzip -q "${archive_file}" -d "${dest_dir}"
		;;
	*)
		msg "Unknown archive format: ${archive_file}"
		exit 1
		;;
	esac
}

# Set locale
LC_ALL=POSIX

# Export needed variables
export LC_ALL

clean_work_dir

bootstrap_stage_2() {

	msg "Starting chroot bootstrap stage 2..."

	msg "Creating standard directory tree in chroot..."

	mkdir -pv /{boot,home,mnt,opt,srv}
	mkdir -pv /etc/{opt,sysconfig,ld.so.conf.d}
	mkdir -pv /lib/firmware
	mkdir -pv /media/{floppy,cdrom}
	mkdir -pv /usr/{,local/}{include,src}
	mkdir -pv /usr/local/{bin,lib,sbin}
	mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
	mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
	mkdir -pv /usr/{,local/}share/man/man{1..8}
	mkdir -pv /var/{cache,local,log,mail,opt,spool}
	mkdir -pv /var/lib/{color,misc,locate,hwclock}

	install -dv -m 0750 /root
	install -dv -m 1777 /tmp /var/tmp
	install -vdm 755 /{dev,proc,run/{media/{floppy,cdrom},lock},sys}
	install -vdm 755 /{boot,etc/{opt,sysconfig},home,mnt}
	install -vdm 755 /usr/{,local/}{bin,include,lib,sbin,src}
	install -vdm 755 /usr/libexec
	install -vdm 755 /etc/profile.d
	install -vdm 755 /usr/lib/debug/{lib,bin,sbin,usr}

	msg "Creating essential symlinks..."

	ln -sfv /run /var/run
	ln -sfv /run/lock /var/lock
	ln -sfv bash /bin/sh
	ln -sv /proc/self/mounts /etc/mtab

	msg "Creating essential files..."

	cat >/etc/hosts <<"EOF"
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

	cat >/etc/passwd <<"EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
tester:x:101:101::/home/tester:/bin/bash
EOF

	cat >/etc/group <<"EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
tester:x:101:
EOF

	cat >/etc/nsswitch.conf <<"EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

	cat >/etc/os-release <<"EOF"
NAME="Bootstrap Linux Toolchain"
VERSION="0.0.0"
ID=bootstraplinux
VERSION_ID="0.0"
PRETTY_NAME="Bootstrap Linux"
ANSI_COLOR="1;34"
HOME_URL="https://www.linuxfromscratch.org/"
BUG_REPORT_URL="https://www.linuxfromscratch.org/bugreport.html"
SUPPORT_URL="https://www.linuxfromscratch.org/mail.html"
EOF

	touch /var/log/{btmp,lastlog,faillog,wtmp}
	chgrp -v utmp /var/log/lastlog
	chmod -v 664 /var/log/lastlog
	chmod -v 600 /var/log/btmp

	install -o tester -d /home/tester

	##
	# gettext Step
	##

	extract_file "${SOURCES}/gettext-${GETTEXT_VER}.tar.xz" "${WORK}/gettext-${GETTEXT_VER}"

	cd "${WORK}/gettext-${GETTEXT_VER}"

	msg "Configuring gettext..."

	./configure --disable-shared

	msg "Building gettext..."

	make

	msg "Installing gettext..."

	cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

	clean_work_dir

	##
	# bison Step
	##

	extract_file "${SOURCES}/bison-${BISON_VER}.tar.xz" "${WORK}/bison-${BISON_VER}"

	cd "${WORK}/bison-${BISON_VER}"

	msg "Configuring bison..."

	./configure --prefix=/usr --docdir=/usr/share/doc/bison-${BISON_VER}

	msg "Building bison..."

	make

	msg "Installing bison..."

	make install

	clean_work_dir

	##
	# Perl Step
	##

	extract_file "${SOURCES}/perl-${PERL_VER}.tar.xz" "${WORK}/perl-${PERL_VER}"

	cd "${WORK}/perl-${PERL_VER}"

	msg "Configuring Perl..."

	sh Configure -des \
		-D prefix=/usr \
 -D vendorprefix=/usr \
		-D useshrplib \
		-D privlib=/usr/lib/perl5/5.42/core_perl \
		-D archlib=/usr/lib/perl5/5.42/core_perl \
		-D sitelib=/usr/lib/perl5/5.42/site_perl \
		-D sitearch=/usr/lib/perl5/5.42/site_perl \
		-D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
		-D vendorarch=/usr/lib/perl5/5.42/vendor_perl

	msg "Building Perl..."

	make

	msg "Installing Perl..."

	make install

	clean_work_dir

	##
	# Python Step
	##

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

	##
	# Texinfo Step
	##

	extract_file "${SOURCES}/texinfo-${TEXINFO_VER}.tar.xz" "${WORK}/texinfo-${TEXINFO_VER}"

	cd "${WORK}/texinfo-${TEXINFO_VER}"

	msg "Configuring texinfo..."

	./configure --prefix=/usr

	msg "Building texinfo..."

	make

	msg "Installing texinfo..."

	make install

	clean_work_dir

	##
	# util-linux Step
	##

	extract_file "${SOURCES}/util-linux-${UTIL_LINUX_VER}.tar.xz" "${WORK}/util-linux-${UTIL_LINUX_VER}"

	cd "${WORK}/util-linux-${UTIL_LINUX_VER}"

	msg "Configuring util-linux..."

	ADJTIME_PATH=/var/lib/hwclock/adjtime \
		./configure \
		--disable-chfn-chsh \
		--disable-liblastlog2 \
		--disable-login \
		--disable-nologin \
		--disable-pylibmount \
		--disable-runuser \
		--disable-setpriv \
		--disable-static \
		--disable-su \
		--libdir=/usr/lib \
		--runstatedir=/run \
		--without-python

	msg "Building util-linux..."

	make

	msg "Installing util-linux..."

	make install

	clean_work_dir

	##
	# Cleanup Step
	##

	msg "Cleaning up unnecessary files..."

	rm -rf /usr/share/{info,man,doc}/*

	find /usr/{lib,libexec} -name \*.la -delete

	##
	# glibc Step
	##

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
	#sed -i "/\btest-cxa_atexit-race2 /d" "${WORK}/glibc-${GLIBC_VER}/stdlib/Makefile"

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

	##
	# Timezone Data Step
	##

	extract_file "${SOURCES}/tzdata${TZ_DATA_VER}.tar.gz" "${WORK}/tzdata${TZ_DATA_VER}"

	cd "${WORK}/tzdata${TZ_DATA_VER}"

	msg "Configuring timezone data..."

	ZONE_INFO=/usr/share/zoneinfo
	ZONES="etcetera southamerica northamerica europe africa antarctica asia australasia backward"
	ZONE_DEFAULT="America/New_York"
	mkdir -pv $ZONE_INFO/{posix,right}

	for tz in $ZONES; do
		msg "Installing timezone data for $tz..."
		zic -L /dev/null -d $ZONE_INFO ${tz}
		zic -L /dev/null -d $ZONE_INFO/posix ${tz}
		zic -L leapseconds -d $ZONE_INFO/right ${tz}
	done

	cp -v zone.tab zone1970.tab iso3166.tab $ZONE_INFO

	zic -d $ZONE_INFO -p $ZONE_DEFAULT

	ln -sfv /usr/share/zoneinfo/$ZONE_DEFAULT /etc/localtime

	unset ZONE_INFO tz ZONE_DEFAULT ZONES

	clean_work_dir

	##
	# zlib Step
	##

	extract_file "${SOURCES}/zlib-${ZLIB_VER}.tar.xz" "${WORK}/zlib-${ZLIB_VER}"

	cd "${WORK}/zlib-${ZLIB_VER}"

	msg "Configuring zlib..."

	./configure --prefix=/usr

	msg "Building zlib..."

	make

	msg "Checking zlib..."

	make test

	msg "Installing zlib..."

	make install

	rm -fv /usr/lib/libz.a

	clean_work_dir

	##
	# bzip2 Step
	##

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

	##
	# xz Step
	##

	extract_file "${SOURCES}/xz-${XZ_VER}.tar.xz" "${WORK}/xz-${XZ_VER}"

	cd "${WORK}/xz-${XZ_VER}"

	msg "Configuring xz..."

	./configure --prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/xz-${XZ_VER}

	msg "Building xz..."

	make

	msg "Checking xz..."

	make check

	msg "Installing xz..."

	make install

	clean_work_dir

	##
	# zstd Step
	##

	extract_file "${SOURCES}/zstd-${ZSTD_VER}.tar.gz" "${WORK}/zstd-${ZSTD_VER}"

	cd "${WORK}/zstd-${ZSTD_VER}"

	msg "Building zstd..."

	make prefix=/usr

	msg "Checking zstd..."

	make check

	msg "Installing zstd..."

	make prefix=/usr install

	rm -v /usr/lib/libzstd.a

	clean_work_dir

	##
	# file Step
	##

	extract_file "${SOURCES}/file-${FILE_VER}.tar.gz" "${WORK}/file-${FILE_VER}"

	cd "${WORK}/file-${FILE_VER}"

	msg "Configuring file..."

	./configure --prefix=/usr

	msg "Building file..."

	make

	msg "Checking file..."

	make check

	msg "Installing file..."

	make install

	clean_work_dir

	##
	# readline Step
	##

	extract_file "${SOURCES}/readline-${READLINE_VER}.tar.gz" "${WORK}/readline-${READLINE_VER}"

	cd "${WORK}/readline-${READLINE_VER}"

	msg "Configuring readline..."

	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install
	sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

	./configure --prefix=/usr \
		--disable-static \
		--with-curses \
		--docdir=/usr/share/doc/readline-${READLINE_VER}

	msg "Building readline..."

	make SHLIB_LIBS="-lncursesw"

	msg "Installing readline..."

	make install

	clean_work_dir

	##
	# m4 Step
	##

	extract_file "${SOURCES}/m4-${M4_VER}.tar.xz" "${WORK}/m4-${M4_VER}"

	cd "${WORK}/m4-${M4_VER}"

	msg "Configuring m4..."

	./configure --prefix=/usr

	msg "Building m4..."

	make

	msg "Checking m4..."

	make check

	msg "Installing m4..."

	make install

	clean_work_dir

	##
	# flex Step
	##

	extract_file "${SOURCES}/flex-${FLEX_VER}.tar.gz" "${WORK}/flex-${FLEX_VER}"

	cd "${WORK}/flex-${FLEX_VER}"

	msg "Configuring flex..."

	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/flex-${FLEX_VER} \
		--disable-static

	msg "Building flex..."

	make

	msg "Checking flex..."

	make check

	msg "Installing flex..."

	make install

	ln -sv flex /usr/bin/lex

	clean_work_dir

	##
	# pkgconf Step
	##

	extract_file "${SOURCES}/pkgconf-${PKGCONF_VER}.tar.xz" "${WORK}/pkgconf-${PKGCONF_VER}"

	cd "${WORK}/pkgconf-${PKGCONF_VER}"

	msg "Configuring pkgconf..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/pkgconf-${PKGCONF_VER}

	msg "Building pkgconf..."

	make

	msg "Installing pkgconf..."

	make install

	ln -sv pkgconf /usr/bin/pkg-config

	clean_work_dir

	##
	# binutils Step
	##

	extract_file "${SOURCES}/binutils-${BINUTILS_VER}.tar.xz" "${WORK}/binutils-${BINUTILS_VER}"

	cd "${WORK}/binutils-${BINUTILS_VER}"

	msg "Configuring binutils..."

	mkdir -v build

	cd build

	../configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-ld=default \
		--enable-plugins \
		--enable-shared \
		--disable-werror \
		--enable-64-bit-bfd \
		--enable-new-dtags \
		--with-system-zlib \
		--enable-default-hash-style=gnu

	msg "Building binutils..."

	make tooldir=/usr

	msg "Checking binutils..."

	make -k check

	# Check for build errors and exit failures are found in the files
	grep '^FAIL:' $(find -name '*.log') && {
		msg "Error: Some binutils tests failed."
		exit 1
	}

	msg "Installing binutils..."

	make tooldir=/usr install

	rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a /usr/share/doc/gprofng/

	clean_work_dir

	##
	# gmp Step
	##

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

	##
	# mpfr Step
	##

	extract_file "${SOURCES}/mpfr-${MPFR_VER}.tar.xz" "${WORK}/mpfr-${MPFR_VER}"

	cd "${WORK}/mpfr-${MPFR_VER}"

	msg "Configuring mpfr..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--enable-thread-safe \
		--docdir=/usr/share/doc/mpfr-${MPFR_VER}

	msg "Building mpfr..."

	make

	msg "Checking mpfr..."

	make check

	msg "Installing mpfr..."

	make install

	clean_work_dir

	##
	# mpc Step
	##

	extract_file "${SOURCES}/mpc-${MPC_VER}.tar.gz" "${WORK}/mpc-${MPC_VER}"

	cd "${WORK}/mpc-${MPC_VER}"

	msg "Configuring mpc..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/mpc-${MPC_VER}

	msg "Building mpc..."

	make

	msg "Checking mpc..."

	make check

	msg "Installing mpc..."

	make install

	clean_work_dir

	##
	# attr Step
	##

	extract_file "${SOURCES}/attr-${ATTR_VER}.tar.gz" "${WORK}/attr-${ATTR_VER}"

	cd "${WORK}/attr-${ATTR_VER}"

	msg "Configuring attr..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/attr-${ATTR_VER}

	msg "Building attr..."

	make

	msg "Checking attr..."

	make check

	msg "Installing attr..."

	make install

	clean_work_dir

	##
	# acl Step
	##

	extract_file "${SOURCES}/acl-${ACL_VER}.tar.xz" "${WORK}/acl-${ACL_VER}"

	cd "${WORK}/acl-${ACL_VER}"

	msg "Configuring acl..."

	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/acl-${ACL_VER}

	msg "Building acl..."

	make

	msg "Checking acl..."

	# Disable test/cp.test as it fails in a chroot environment
	sed -e 's|test/cp.test||' -i test/Makemodule.am Makefile.in Makefile

	make check

	msg "Installing acl..."

	make install

	clean_work_dir

	##
	# libcap Step
	##

	extract_file "${SOURCES}/libcap-${LIBCAP_VER}.tar.xz" "${WORK}/libcap-${LIBCAP_VER}"

	cd "${WORK}/libcap-${LIBCAP_VER}"

	msg "Configuring libcap..."

	sed -i '/install -m.*STA/d' libcap/Makefile

	msg "Building libcap..."

	make prefix=/usr lib=lib

	msg "Checking libcap..."

	make test

	msg "Installing libcap..."

	make prefix=/usr lib=lib install

	clean_work_dir

	##
	# libxcrypt Step
	##

	extract_file "${SOURCES}/libxcrypt-${LIBXCRPT_VER}.tar.xz" "${WORK}/libxcrypt-${LIBXCRPT_VER}"

	cd "${WORK}/libxcrypt-${LIBXCRPT_VER}"

	msg "Configuring libxcrypt..."

	./configure --prefix=/usr \
		--enable-hashes=strong,glibc \
		--enable-obsolete-api=no \
		--disable-static \
		--disable-failure-tokens

	msg "Building libxcrypt..."

	make

	msg "Checking libxcrypt..."

	make check

	msg "Installing libxcrypt..."

	make install

	clean_work_dir

	##
	# shadow Step
	##

	extract_file "${SOURCES}/shadow-${SHADOW_VER}.tar.xz" "${WORK}/shadow-${SHADOW_VER}"

	cd "${WORK}/shadow-${SHADOW_VER}"

	msg "Configuring shadow..."

	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

	sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
		-e 's:/var/spool/mail:/var/mail:' \
		-e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
		-i etc/login.defs

	touch /usr/bin/passwd

	./configure \
		--sysconfdir=/etc \
		--disable-static \
		--with-{b,yes}crypt \
		--without-libbsd \
		--with-group-name-max-length=32

	msg "Building shadow..."

	make

	msg "Installing shadow..."

	make exec_prefix=/usr install

	clean_work_dir

	##
	# gcc Step
	##

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

	##
	# ncurses Step
	##

	extract_file "${SOURCES}/ncurses-${NCURSES_VER}.tgz" "${WORK}/ncurses-${NCURSES_VER}"

	cd "${WORK}/ncurses-${NCURSES_VER}"

	msg "Configuring ncurses..."

	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--with-shared \
		--without-debug \
		--without-normal \
		--with-cxx-shared \
		--enable-pc-files \
		--with-pkg-config-libdir=/usr/lib/pkgconfig

	msg "Building ncurses..."

	make

	msg "Installing ncurses..."

	make DESTDIR=$PWD/dest install

	install -vm755 $PWD/dest/usr/lib/libncursesw.so.6.5 /usr/lib

	rm -v $PWD/dest/usr/lib/libncursesw.so.6.5

	sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h

	cp -av dest/* /

	ln -sfv libncursesw.so /usr/lib/libcurses.so

	clean_work_dir

	##
	# sed Step
	##

	extract_file "${SOURCES}/sed-${SED_VER}.tar.xz" "${WORK}/sed-${SED_VER}"

	cd "${WORK}/sed-${SED_VER}"

	msg "Configuring sed..."

	./configure --prefix=/usr

	msg "Building sed..."

	make

	msg "Checking sed..."

	chown -R tester .

	su tester -c "PATH=$PATH make -k check"

	msg "Installing sed..."

	make install

	clean_work_dir

	##
	# bash Step
	##

	extract_file "${SOURCES}/bash-$BASH_VER.tar.gz" "${WORK}/bash-$BASH_VER"

	cd "${WORK}/bash-$BASH_VER"

	msg "Configuring bash..."

	./configure \
		--prefix=/usr \
		--without-bash-malloc \
		--with-installed-readline \
		--docdir=/usr/share/doc/bash-${BASH_VER}

	msg "Building bash..."

	make

	msg "Checking bash..."

	chown -R tester .

	msg "Installing bash..."

	make install

	clean_work_dir

	msg "Chroot bootstrap stage 2 completed successfully."
}

bootstrap_stage_3() {

	msg "Starting chroot bootstrap stage 3..."

	##
	# libtool Step
	##

	extract_file "${SOURCES}/libtool-${LIBTOOL_VER}.tar.xz" "${WORK}/libtool-${LIBTOOL_VER}"

	cd "${WORK}/libtool-${LIBTOOL_VER}"

	msg "Configuring libtool..."

	./configure --prefix=/usr

	msg "Building libtool..."

	make

	msg "Checking libtool..."

	make check

	msg "Installing libtool..."

	make install

	clean_work_dir
}

# Default to stage 1 if no argument is given
STAGE=${1:-1}
if [ "${STAGE}" -eq 2 ]; then
	bootstrap_stage_2
elif [ "${STAGE}" -eq 3 ]; then
	bootstrap_stage_3
else
	echo "Invalid stage: ${STAGE}. Valid stages are 2 and 3."
	exit 1
fi

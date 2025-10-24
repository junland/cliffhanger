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
BINUTILS_VER="2.45"
BISON_VER="3.8.2"
BZIP2_VER="1.0.8"
COREUTILS_VER="9.7"
FILE_VER="5.46"
FLEX_VER="2.6.4"
GETTEXT_VER="0.26"
GLIBC_VER="2.42"
M4_VER="1.4.20"
PERL_VER="5.42.0"
PYTHON_VER="3.13.7"
READLINE_VER="8.3"
TEXINFO_VER="7.2"
TZ_DATA_VER="2025b"
UTIL_LINUX_VER="2.41.1"
XZ_VER="5.8.1"
ZLIB_VER="1.3.1"
ZSTD_VER="1.5.7"
PKGCONF="2.5.1"

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

cat >/etc/hosts <<EOF
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

./configure \
	--libdir=/usr/lib \
	--runstatedir=/run \
	--disable-chfn-chsh \
	--disable-login \
	--disable-nologin \
	--disable-su \
	--disable-setpriv \
	--disable-runuser \
	--disable-pylibmount \
	--disable-static \
	--disable-liblastlog2 \
	--without-python \
	ADJTIME_PATH=/var/lib/hwclock/adjtime \
	--docdir=/usr/share/doc/util-linux-${UTIL_LINUX_VER}

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

msg "Testing glibc..."

# Disable io/tst-lchmod test as its known to fail in a chroot.
sed -i "/\btst-lchmod /d" "${WORK}/glibc-${GLIBC_VER}/io/Makefile"

TIMEOUTFACTOR=16 make check

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
	zic -L leapseconds -d $ZONEZONE_INFOINFO/right ${tz}
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

extract_file "${SOURCES}/pkgconf-${PKGCONF}.tar.xz" "${WORK}/pkgconf-${PKGCONF}"

cd "${WORK}/pkgconf-${PKGCONF}"

msg "Configuring pkgconf..."

./configure \
           --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/pkgconf-${PKGCONF}

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

grep '^FAIL:' $(find -name '*.log')

make -k check

msg "Installing binutils..."

make tooldir=/usr install

rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a /usr/share/doc/gprofng/

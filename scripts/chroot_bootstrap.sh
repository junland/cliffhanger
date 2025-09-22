#!/bin/bash

set +h # Disable hashall to speed up script execution
set -e # Exit on error

umask 022

LC_ALL=POSIX
TARGET_ROOTFS_SOURCES_PATH=${TARGET_ROOTFS_SOURCES_PATH:-"/tmp/sources"}
TARGET_ROOTFS_WORK_PATH=${TARGET_ROOTFS_WORK_PATH:-"/tmp/work"}

# Variables with shorter names
WORK="${TARGET_ROOTFS_WORK_PATH}"
SOURCES="${TARGET_ROOTFS_SOURCES_PATH}"

GETTEXT_VER="0.26"
BISON_VER="2.8.2"
PERL_VER="5.42.0"
PYTHON_VER="3.13.7"
TEXINFO_VER="7.2"
UTIL_LINUX_VER="2.41.1"

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Clean work directory function
clean_work_dir() {
	cd "${TARGET_ROOTFS_PATH}"
	msg "Cleaning up work directory at ${WORK}..."
	rm -rf "${WORK}"/*
}

# Extracts an archive file to a destination directory
extract_file() {
	local archive_file=$1
	local dest_dir=$2
	local strip_components=${3:-1}

	mkdir -vp "${dest_dir}"

	msg "Extracting to ${dest_dir}..."
	case ${archive_file} in
	*.tar.bz2 | *.tbz2) tar -xjf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ;;
	*.tar.xz) tar -xJf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ;;
	*.tar.gz | *.tgz) tar -xzf "${archive_file}" -C "${dest_dir}" --strip-components=${strip_components} ;;
	*.zip) unzip -q "${archive_file}" -d "${dest_dir}" ;;
	*)
		echo "Unknown archive format: ${archive_file}"
		exit 1
		;;
	esac
}

msg "Creating standard directory tree in chroot..."

mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

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

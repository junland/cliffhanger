#!/bin/bash
# Texinfo Step - Build and install texinfo in chroot

TEXINFO_VER="7.2"

step_chroot_texinfo() {
	extract_file "${SOURCES}/texinfo-${TEXINFO_VER}.tar.xz" "${WORK}/texinfo-${TEXINFO_VER}"

	cd "${WORK}/texinfo-${TEXINFO_VER}"

	msg "Configuring texinfo..."

	./configure --prefix=/usr

	msg "Building texinfo..."

	make

	msg "Installing texinfo..."

	make install

	clean_work_dir
}

step_chroot_texinfo_stage3() {
	extract_file "${SOURCES}/texinfo-${TEXINFO_VER}.tar.xz" "${WORK}/texinfo-${TEXINFO_VER}"

	cd "${WORK}/texinfo-${TEXINFO_VER}"

	msg "Configuring texinfo..."

	sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm

	./configure --prefix=/usr

	msg "Building texinfo..."

	make

	msg "Checking texinfo..."

	make check

	msg "Installing texinfo..."

	make install

	msg "Optional installation for texinfo..."

	make TEXMF=/usr/share/texmf install-tex

	pushd /usr/share/info

	rm -v dir

	for f in *; do
		msg "Recreate info docs: $f"
		install-info $f dir 2>/dev/null
	done

	popd

	clean_work_dir
}

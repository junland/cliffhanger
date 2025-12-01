#!/bin/bash
# Common utility functions for bootstrap steps

# msg function that will make echo's pretty.
msg() {
	echo " ==> $*"
}

# Clean work directory function
clean_work_dir() {
	cd "${WORK}" || return 1
	msg "Cleaning up work directory at ${WORK}..."
	rm -rf "${WORK:?}"/*
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
		archive_file=$(find "${SOURCES}" -name "$(basename "${archive_file}" | sed 's/\.[^.]*$//').*" | head -1)
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
		tar -xjf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
		;;
	*.tar.xz | *.txz)
		tar -xJf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
		;;
	*.tar.gz | *.tgz)
		tar -xzf "${archive_file}" -C "${dest_dir}" --strip-components="${strip_components}" "${verbose_flag}"
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

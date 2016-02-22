#!/bin/bash 

quiet()
{
	"${@}" >/dev/null
}

debug()
{
	if test -n "${DEBUG}"; then
		echo "${@}"
	fi
}

generate_gcov()
{
	echo "Generating gcov files..."
	local err=0
	# find all .cc files and call gcov on them
	find "${SRCDIR}" -type f -name "*.cc" -printf "%P\n" | while read ccfile; do
		debug -e "Processing file: ${ccfile}"
		echo -n -e "\\n\\n###> Running GCOV on ${ccfile} <###\\n\\n" >> "${SRCDIR}"/gcov.txt
		# Because gcno store compiler options like -I, we must invoke gcov in the same dir make was invoked
		quiet pushd "${SRCDIR}"
		CMD="${GCOV} --object-directory ${OBJDIR} -b -p ${ccfile} >> gcov.txt 2>&1 "	
		debug $CMD
		eval $CMD
		err="${?}"
		quiet popd
		if test "x${err}" != "x0"; then
			echo -e "\\n\\nAn error occurred while running gcov. Please see the gcov output excerpt (last 100 lines) below:\\n" 1>&2
			tail -n100 "${SRCDIR}/gcov.txt" 1>&2
			return 1
		fi
		if grep -a -F "cannot open source file" "${SRCDIR}/gcov.txt"; then
			echo -e "\\n\\nCould not open source files! Check ${SRCDIR}/gcov.txt for more details." 1>&2
			return 1;
		fi
		rm -f "${SRCDIR}/gcov.txt"
	done

}

move_gcov_files()
{
    # find all gcov files in src dir
	quiet pushd "${SRCDIR}"
	if ! find . -type f -name "*.cc.gcov" -printf "%P\n" > "gcov_file_list.txt"; then
		echo "Cannot \"find\" .cc.gcov files in \"${PWD}\"." 1>&2
		exit 1
	fi
	quiet popd
    quiet pushd .
	if ! tar -C "${SRCDIR}" -c -f - -T "${SRCDIR}"/gcov_file_list.txt | (cd "${OUTDIR}" && tar -xf - ); then
		echo "Cannot copy files with tar from \"${PWD}\" to \"${OUTDIR}\"" 1>&2
		exit 1
	fi
    quiet popd
    rm -f "${SRCDIR}"/gcov_file_list.txt
}


delete_gcov_files()
{
	find "${SRCDIR}" -type f -name "*.gcov" -delete
}

extract_tar_file()
{
	local tar_file="${1}"
	local destination="${2}"
	if ! test -f  "${tar_file}"; then
		echo "Cannot extract \"${tar_file}\" because it does not exist." 1>&2
		exit 1
	fi
	if ! tar -C "${destination}" -x -f "${tar_file}"; then
		echo "Cannot extract tar file \"${tar_file}\" to \"${destination}\"" 1>&2
		exit 1
	fi
}

extract_tar_file_with_transform()
{
	local tar_file="${1}"
	local destination="${2}"
	if ! test -f  "${tar_file}"; then
		echo "Cannot extract \"${tar_file}\" because it does not exist." 1>&2
		exit 1
	fi
	if echo "${destination}" | grep -q ";"; then
		echo "Cannot extract with transformation because prefix (\"${destination}\") contains \';\'." 1>&2
		exit 1
	fi

	tar --transform "s;^.*${destination}/\\?;;" -C "${destination}" -x -f "${tar_file}"
}

delete_gcda_files()
{
	find "${SRCDIR}" -name "*.gcda" -delete
}

### main ###
if test "$#" != 4; then
	echo "Usage: $(basename "${0}") <gcov exec> <src dir> <obj dir relative to src dir> <results dir>"
	exit 1
fi

GCOV="${1}"
SRCDIR="${2}"
OBJDIR="${3}"
RESULTSDIR="${4}"

OUTDIR=

if ! test -d "${SRCDIR}/${OBJDIR}" ; then
	echo "SRCDIR/OBJDIR: ${SRCDIR}/${OBJDIR} is not a directory!" 1>&2
	exit 1
elif ! test -d "${SRCDIR}"; then
	echo "SRCDIR: ${SRCDIR} is not a directory!" 1>&2
	exit 1
elif ! test -d "${RESULTSDIR}"; then
	echo "RESULTSDIR: ${RESULTSDIR} is not a directory!" 1>&2
	exit 1
fi

mkdir -p "${OUTDIR}"

extract_tar_file "${RESULTSDIR}/gcno_files.tar.gz" "${SRCDIR}/${OBJDIR}"

for gcda_dir in "${RESULTSDIR}/gcda/"*; do
	test_name="$(basename "${gcda_dir}")"

	INDIR="${gcda_dir}"
	OUTDIR="${RESULTSDIR}/gcov/${test_name}"

	echo -e "\nProcessing test case: ${test_name}";
	debug -e "Input directory: ${INDIR}"
	debug -e "Output directory: ${OUTDIR}"

	if ! mkdir -p "${OUTDIR}"; then
		echo "Cannot create output directory (${OUTDIR})" 1>&2
		exit 1
	fi

	delete_gcov_files
	delete_gcda_files

	extract_tar_file_with_transform "${INDIR}/gcda.tar.gz" "${SRCDIR}/${OBJDIR}"

	if ! generate_gcov; then
		exit 1
	fi

	move_gcov_files
done

delete_gcov_files
delete_gcda_files

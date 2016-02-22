#!/bin/bash

quiet()
{
        "${@}" >/dev/null
}


prepare_dir()
{
	mkdir -p "${GCDA_PER_TEST_DIR}/${TEST_NAME}"
}

archive_gcda_files()
{
	local test_dir="${GCDA_PER_TEST_DIR}/${TEST_NAME}"
	find "${GCDA_CUR_TEST_DIR}" -type f -name "*.gcda" > "${test_dir}/gcda.list"
	tar -zcf "${test_dir}/gcda.tar.gz" -T "${test_dir}/gcda.list"
	rm -f "${test_dir}/gcda.list"
}

clean_gcda_files()
{
	# Clean the existing/leftover GCDA files.
	quiet pushd "${GCDA_CUR_TEST_DIR}"
	find . -type f -name "*.gcda" -delete
	quiet popd
}

### main ###
set -x

TEST_NAME="${1}"
GCDA_PER_TEST_DIR="${2}"
GCDA_CUR_TEST_DIR="${3}"
if test -z "${TEST_NAME}"; then
	echo "TEST_NAME is not set!" 1>&2
	exit 1
fi
if test -z "${GCDA_CUR_TEST_DIR}"; then
	echo "GCDA_CUR_TEST_DIR is not set!" 1>&2
	exit 1
elif ! test -d "${GCDA_CUR_TEST_DIR}"; then
	echo "GCDA_CUR_TEST_DIR (${GCDA_CUR_TEST_DIR}) is not a directory!" 1>&2
	exit 1
fi

if test -z "${GCDA_PER_TEST_DIR}"; then
	echo "GCDA_PER_TEST_DIR is not set!" 1>&2
	exit 1
fi

echo "gcov-helper invoked for test case: ${TEST_NAME}"
echo "Directory for the current test GCDA: ${GCDA_CUR_TEST_DIR}"
echo "Directory for the per test GCDA:     ${GCDA_PER_TEST_DIR}"

prepare_dir
archive_gcda_files
clean_gcda_files

exit 0

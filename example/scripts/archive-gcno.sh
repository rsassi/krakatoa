#!/bin/bash

archive_gcno_files()
{
        find "${SRCDIR}" -type f -name "*.gcno" > "${RESULTS_DIR}/gcno.list"
        tar -zcf "${RESULTS_DIR}/gcno_files.tar.gz" -T "${RESULTS_DIR}/gcno.list"
        rm -f "${RESULTS_DIR}/gcno.list"
}

SRCDIR="${1}"
RESULTS_DIR="${2}"

echo Archiving gcno from ${SRCDIR} into ${RESULTS_DIR}
archive_gcno_files


#!/bin/bash

DB_USER=smartuser
DB_PASSWORD=password
DB_HOST=localhost

SMARTTEST_REPO=..

POSITION=123
EXECUTION_ID=456
TEST_SUITE=example
TEST_FRAMEWORK=testfw
CSVDIR=results/csv


create_load_mysql()
{
	echo "build_gcov: Creating load_mysql_now.sql"
	local git_commit="$(git --git-dir "${SMARTTEST_REPO}/.git" rev-parse HEAD)"
	cat "${SMARTTEST_REPO}/gcov2covDB/mysql/load_template.sql" | \
		sed "s@_TEST_POSITION_@${POSITION}@g" | \
		sed "s@_TEST_RESULTS_ID_@${EXECUTION_ID}@g" | \
		sed "s@_GIT_COMMIT_@${git_commit}@g" | \
		sed "s@_TEST_FRAMEWORK_@${TEST_FRAMEWORK}@g" | \
		sed "s@_TEST_SUITE_@${TEST_SUITE}@g" | \
		sed "s@_FILE_PATH_@${CSVDIR}@g" > "${CSVDIR}/load_mysql_now.sql"
}

load_mysql()
{
	local CMD="mysql -u ${DB_USER} -p\${DB_PASSWORD} -h ${DB_HOST} < ${CSVDIR}/load_mysql_now.sql"
	echo "build_gcov: load_mysql"
	local ret=
	eval ${CMD}
	ret="${?}"

	if test "x${ret}" != "x0"; then
		echo "Failed to load in MySQL DB. Aborting." 1>&2
		exit 1
	fi
}


create_load_mysql
load_mysql


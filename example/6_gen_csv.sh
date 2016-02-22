#!/bin/bash

SMARTTEST_REPO=..
RESULTSDIR=results

java -jar "${SMARTTEST_REPO}/gcov2covDB/gcov2covDB.jar" \
		"${RESULTSDIR}/gcov/" \
		"${RESULTSDIR}"/tests_summary.yaml \
		"${RESULTSDIR}"/function_map.csv \
		"${SMARTTEST_REPO}/gcov2covDB/func_filter.yaml"

mkdir -p "${RESULTSDIR}"/csv/

mv *.csv "${RESULTSDIR}"/csv/

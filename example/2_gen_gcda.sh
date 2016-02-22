#!/bin/bash

quiet()
{
        "${@}" >/dev/null
}

TESTDATA=results/gcda
RESULTS=results
SRCDIR=src

quiet pushd src
quiet make clean testapp
quiet popd
rm -rf "${TESTDATA}"
mkdir -p "${TESTDATA}"

echo *Archive gcno
./scripts/archive-gcno.sh "${SRCDIR}" "${RESULTS}"

for test in testa testb testc
do
  pushd src
  echo *Execute ${test}
  make "${test}"
  popd
  echo *Archive gcda data for ${test}
  ./scripts/archive-gcda.sh "${test}" "${TESTDATA}" "${SRCDIR}"
done



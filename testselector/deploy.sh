#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Missing argument"
  echo 'usage: deploy.sh <INSTALLDIR> <configfile>'
  echo ' see src/cfg/example_config.yaml'
  exit 1
fi

INSTALLDIR="${1}"
CONFIGFILE="${2}"
LIBINSTALLDIR="${1}/lib/"
BININSTALLDIR="${1}/bin/"

# remove old install:
rm -rf "${BININSTALLDIR}"/testselector
rm -rf "${LIBINSTALLDIR}"/testselector

# install
mkdir -p "${LIBINSTALLDIR}"
mkdir -p "${BININSTALLDIR}"
cp testselector "${BININSTALLDIR}"
cp -r src "${LIBINSTALLDIR}"/testselector
cp "${CONFIGFILE}" "${LIBINSTALLDIR}"/testselector/cfg/config.yaml

chmod uog+rx "${BININSTALLDIR}"/testselector
chmod -R uog+rx "${LIBINSTALLDIR}"/testselector
chmod -R uog+rx "${BININSTALLDIR}"
chmod -R uog+rx "${LIBINSTALLDIR}"

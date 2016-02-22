#!/bin/bash

quiet()
{
        "${@}" >/dev/null
}


quiet pushd src
quiet make clean 
quiet popd

rm -rf results

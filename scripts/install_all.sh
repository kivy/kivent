#!/bin/bash

BUILD_CMD="python setup.py build_ext --inplace --force"
INSTALL_CMD="python setup.py install"
ROOT=$(pwd)

function safe_cmd {
    "$@"
    if [ $? != 0 ]; then
        exit $?
    fi
}

function build_and_install {
    cd "$ROOT/$1"
    safe_cmd ${BUILD_CMD}
    safe_cmd ${INSTALL_CMD}
}

build_and_install modules/core
build_and_install modules/cymunk
build_and_install modules/particles
build_and_install modules/projectiles

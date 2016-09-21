#!/bin/bash

BUILD_CMD="python setup.py build_ext --inplace --force"
INSTALL_CMD="python setup.py install"

function build_and_install {
    (cd $1 && $BUILD_CMD && $INSTALL_CMD)
    if [ $? -ne 0 ]; then
        exit $?
    fi
}

build_and_install modules/core
build_and_install modules/cymunk
build_and_install modules/particles
build_and_install modules/projectiles

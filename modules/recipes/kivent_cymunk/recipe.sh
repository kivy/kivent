#!/bin/bash

VERSION_kivent_cymunk=1.0.0
URL_kivent_cymunk=https://github.com/Kovak/KivEnt/archive/new_rendering.zip
MD5_kivent_cymunk=
DEPS_kivent_cymunk=(python cymunk kivy kivent_core)
BUILD_kivent_cymunk=$BUILD_PATH/kivent_cymunk/new_rendering/modules/cymunk
RECIPE_kivent_cymunk=$RECIPES_PATH/kivent_cymunk

function prebuild_kivent_cymunk() {
	true
}

function build_kivent_cymunk() {
	cd $BUILD_kivent_cymunk

	push_arm

	export LDSHARED="$LIBLINK"
	export PYTHONPATH=$BUILD_kivy/:$PYTHONPATH
	export PYTHONPATH=$BUILD_cymunk/cymunk/python:$PYTHONPATH
	export PYTHONPATH=$BUILD_kivent_core/:$PYTHONPATH
	try find . -iname 'physics.pyx' -exec $CYTHON {} \;
	try find . -iname 'interaction.pyx' -exec $CYTHON {} \;
	try $BUILD_PATH/python-install/bin/python.host setup.py build_ext -v
	try find build/lib.* -name "*.o" -exec $STRIP {} \;

	export PYTHONPATH=$BUILD_hostpython/Lib/site-packages
	try $BUILD_hostpython/hostpython setup.py install -O2 --root=$BUILD_PATH/python-install --install-lib=lib/python2.7/site-packages

	unset LDSHARED
	pop_arm
}

function postbuild_kivent_cymunk() {
	true
}

#!/bin/bash

VERSION_kivent=${VERSION_kivent:-master}
URL_kivent=https://github.com/Kovak/KivEnt/zipball/$VERSION_kivent/kivy-$VERSION_kivent.zip
DEPS_kivent=(cymunk kivy)
MD5_kivent=
BUILD_kivent=$BUILD_PATH/kivent/kivent/
RECIPE_kivent=$RECIPES_PATH/kivent

function prebuild_kivent() {
	true
}

function build_kivent() {
	cd $BUILD_kivent

	push_arm

	export LDSHARED="$LIBLINK"
	export PYTHONPATH=$BUILD_kivy/kivy:$PYTHONPATH
	export PYTHONPATH=$BUILD_cymunk/cymunk/python:$PYTHONPATH
	try find . -iname '*.pyx' -exec cython {} \;
	try $BUILD_PATH/python-install/bin/python.host setup.py build_ext -v
	try find build/lib.* -name "*.o" -exec $STRIP {} \;

	export PYTHONPATH=$BUILD_hostpython/Lib/site-packages
	try $BUILD_hostpython/hostpython setup.py install -O2 --root=$BUILD_PATH/python-install --install-lib=lib/python2.7/site-packages

	unset LDSHARED
	pop_arm
}

function postbuild_kivent() {
	true
}

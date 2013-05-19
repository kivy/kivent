#!/bin/bash

VERSION_kivent_cython=1.0
URL_kivent_cython=
DEPS_kivent_cython=(kivyparticle quadtree cymunk kivy)
MD5_kivent_cython=
BUILD_kivent_cython=$BUILD_PATH/kivent_cython/
RECIPE_kivent_cython=$RECIPES_PATH/kivent_cython

function prebuild_kivent_cython() {
	true
}

function build_kivent_cython() {
	cd $BUILD_kivent_cython

	push_arm

	export LDSHARED="$LIBLINK"

	try find . -iname '*.pyx' -exec cython {} \;
	try $BUILD_PATH/python-install/bin/python.host setup.py build_ext -v
	try find build/lib.* -name "*.o" -exec $STRIP {} \;

	export PYTHONPATH=$BUILD_hostpython/Lib/site-packages
	try $BUILD_hostpython/hostpython setup.py install -O2 --root=$BUILD_PATH/python-install --install-lib=lib/python2.7/site-packages

	unset LDSHARED
	pop_arm
}

function postbuild_kivent_cython() {
	true
}

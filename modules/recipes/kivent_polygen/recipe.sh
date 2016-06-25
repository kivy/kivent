#!/bin/bash

VERSION_kivent_polygen=1.0.0
URL_kivent_polygen=https://github.com/kivy/KivEnt/archive/master.zip
MD5_kivent_polygen=
DEPS_kivent_polygen=(python kivy kivent_core)
BUILD_kivent_polygen=$BUILD_PATH/kivent_polygen/master/modules/polygen
RECIPE_kivent_polygen=$RECIPES_PATH/kivent_polygen

function prebuild_kivent_polygen() {
	true
}

function build_kivent_polygen() {
	cd $BUILD_kivent_polygen

	push_arm

	export LDSHARED="$LIBLINK"
	export PYTHONPATH=$BUILD_kivy/:$PYTHONPATH
	export PYTHONPATH=$BUILD_kivent_core/:$PYTHONPATH
	try find . -iname '*.pyx' -exec $CYTHON {} \;
	try $BUILD_PATH/python-install/bin/python.host setup.py build_ext -v
	try find build/lib.* -name "*.o" -exec $STRIP {} \;

	export PYTHONPATH=$BUILD_PATH/python-install/lib/python2.7/site-packages:$PYTHONPATH
	try $BUILD_hostpython/hostpython setup.py install -O2 --root=$BUILD_PATH/python-install --install-lib=lib/python2.7/site-packages

	unset LDSHARED
	pop_arm
}

function postbuild_kivent_polygen() {
	true
}

#!/bin/bash

VERSION_kivent_particles=1.0.0
URL_kivent_particles=https://github.com/kivy/KivEnt/archive/master.zip
MD5_kivent_particles=
DEPS_kivent_particles=(python kivy)
BUILD_kivent_particles=$BUILD_PATH/kivent_particles/master/modules/particles
RECIPE_kivent_particles=$RECIPES_PATH/kivent_particles

function prebuild_kivent_particles() {
	true
}

function build_kivent_particles() {
	cd $BUILD_kivent_particles

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

function postbuild_kivent_particles() {
	true
}

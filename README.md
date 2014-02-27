KivEnt
======

KivEnt is an Entity Based Game Engine for Kivy

Requires Cymunk in order to run: 
get the master branch from here:https://github.com/tito/cymunk

You will need to compile both the cymunk module as well as the kivent_cython folders code.

I develop using [Kivy 1.8](https://github.com/kivy/kivy) (so current indevelopment branch, this is because there are some great performance enhancements
in the most recent branch)

Cymunk and Kivy must both be in your environment path in order to buld kivent as it must cimport modules from both of these modules.

Do not make install kivy, simply make it and then

export PYTHONPATH=~/path/to/kivy/kivy:$PYTHONPATH 

do the same for cymunk

export PYTHONPATH=~/path/to/cymunk/cymunk/python:$PYTHONPATH



Tested on Asus Transformer TF101, Droid 4, Droid RAZR M, Ubuntu 13.04 

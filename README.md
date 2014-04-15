KivEnt
======
Project Website: https://www.kivent.org

Documentation: https://www.kivent.org/docs

Warning Tutorials Out Dated! Will Fix Soon.
Update: 2_basic_app tutorial and sample_application up to date. 04/10/14

KivEnt is an Entity Based Game Engine for Kivy
https://github.com/Kovak/KivEnt/wiki/An-Introduction-to-KivEnt

Requires Cymunk in order to run: 
get the master branch from here:https://github.com/tito/cymunk

You will need to compile both the cymunk module as well as the kivent_cython folders code.

I develop using [Kivy Master Branch](https://github.com/kivy/kivy)

Cymunk and Kivy must both be in your environment path in order to buld kivent as it must cimport modules from both of these modules.

Do not make install kivy, simply make it and then

export PYTHONPATH=~/path/to/kivy:$PYTHONPATH 

do the same for cymunk
(this is the path to python folder in cymunk)
export PYTHONPATH=~/path/to/cymunk/cymunk/python:$PYTHONPATH



Tested on Asus Transformer TF101, Droid 4, Droid RAZR M, Ubuntu 13.04 

KivEnt
======
Project Website: http://www.kivent.org

Documentation: http://www.kivent.org/docs  
scroll down for extra detailed installation instructions

Warning Tutorials Out Dated! Will Fix Soon.  
Update: 2_basic_app tutorial and sample_application up to date. 04/10/14

Tutorial 3 now function, tutorial 4 partially finished. 04/17/14

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

Extra detailed installation instructions:

first get to a folder to clone a couple of projects, replace /path/to/ with /home/myuser/whateverfolderyouwant

    cd /path/to/
    git clone https://github.com/kivy/kivy.git
    git clone git@github.com:tito/cymunk.git
    git clone https://github.com/Kovak/KivEnt.git

build kivy

    cd kivy
    make
    cd ..

build cymunk

    cd cymunk
    python setup.py build_ext --inplace
    cd ..

add the following lines to ~/.bashrc (or otherwise add them to your pythonpath)

    export PYTHONPATH=/path/to/kivy:$PYTHONPATH 
    export PYTHONPATH=/path/to/cymunk/cymunk/python/:$PYTHONPATH 
    export PYTHONPATH=/path/to/cymunk/:$PYTHONPATH 

if you have opted for .bashrc, you can either open a new term or run

    source ~/.bashrc

you should now be able to build kivent

    cd KivEnt/modules/core
    python setup.py build_ext --inplace
    cd ../../..
    
and kivent_cymunk (unless you *really* don't want physics)

    cd KivEnt/modules/core
    ln -s ../core/kivent_core/ kivent_core
    python setup.py build_ext --inplace
    cd ../../..
    
rather than creating the softlink above, you could probably alter your pythonpath, or other method. But I'll stick with ln for now.

If you have got this far you should be able to run some examples - this first one without cymunk working.

at time of writing, tutorial 2,3 and 8 work.

    cd KivEnt/kivent_tutorials/2_basic_app/
    ln -s ../../modules/core/kivent_core/ kivent_core
    python main.py

and a physics example

    cd KivEnt/kivent_tutorials/3_adding_physics_objects/
    ln -s ../../modules/core/kivent_core/ kivent_core
    ln -s ../../modules/core/kivent_cymunk/ kivent_cymunk
    python main.py

and a game

    cd KivEnt/kivent_tutorials/8_airhockey_table/
    ln -s ../../modules/core/kivent_core/ kivent_core
    ln -s ../../modules/core/kivent_cymunk/ kivent_cymunk
    python main.py

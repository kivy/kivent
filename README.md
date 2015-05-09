KivEnt
======
Project Website: http://www.kivent.org

Mailing List: https://groups.google.com/forum/#!forum/kivent

Documentation: http://www.kivent.org/docs  
scroll down for extra detailed installation instructions

KivEnt is split into modules, the core module, 'kivent_core', is dependent only on Kivy.

Other modules may have other dependecies, listed here:

Kivent_core:
-------------
kivy

kivent_cymunk:
-------------
kivy 
cymunk
kivent_core

cymunk:
-------
get the master branch from here:https://github.com/tito/cymunk

first install all dependencies then:

cd .../KivEnt/modules/core or .../KivEnt/modules/cymunk

python setup.py build_ext install

Tested with [Kivy 1.9](https://github.com/kivy/kivy).

Tested on Asus Transformer TF101, Droid 4, Droid RAZR M, Ubuntu 14.04, and Windows 8.1


Detailed Setup Instructions (if not installing to system python)

export PYTHONPATH=~/path/to/kivy:$PYTHONPATH 

do the same for cymunk  
(this is the path to python folder in cymunk)  
export PYTHONPATH=~/path/to/cymunk/cymunk/python:$PYTHONPATH





##Extra detailed installation instructions:

###dependencies

you may need to do something like this
    sudo apt-get install git

    #kivy deps
    sudo apt-get install pkg-config python-setuptools python-pygame python-opengl   python-gst0.10 python-enchant gstreamer0.10-plugins-good python-dev   build-essential libgl1-mesa-dev libgles2-mesa-dev
    
    #get pip if you don't have it
    sudo easy_install pip
    
    #get cython
    sudo pip install cython
    
###Build and Environment Vars

first get to a folder to clone a couple of projects, replace /path/to/ with /home/myuser/whateverfolderyouwant

    cd /path/to/
    git clone https://github.com/kivy/kivy.git
    git clone https://github.com/tito/cymunk.git
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

    cd KivEnt/modules/cymunk
    ln -s ../core/kivent_core/ kivent_core
    python setup.py build_ext --inplace
    cd ../../..
    
rather than creating the softlink above, you could probably alter your pythonpath, or other method. But I'll stick with ln for now.

###Try it out

If you have got this far you should be able to run some examples - this first one without cymunk working.


    cd KivEnt/examples/2_basic_app/
    ln -s ../../modules/core/kivent_core/ kivent_core
    python main.py

and a physics example

    cd KivEnt/examples/4_adding_physics_objects/
    ln -s ../../modules/core/kivent_core/ kivent_core
    ln -s ../../modules/cymunk/kivent_cymunk/ kivent_cymunk
    python main.py


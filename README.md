KivEnt
======
KivEnt is a framework for building performant, dynamic real-time scenes in [Kivy](http://kivy.org/#home) for Python2 and Python3. At the moment it is 2d oriented. The only dependency for the kivent_core module is Kivy itself. Additional modules may have other requirements, such as kivent_cymunk module being based on [Chipmunk2d](https://chipmunk-physics.net/) and its [cymunk wrapper](https://github.com/tito/cymunk).

An entity-component architecture is used to control game object state and the logic of processing the game objects. This means that your game objects will be made up of collections of independent components that stricly hold data; each component corresponds to a GameSystem that will perform all data processing on the components, in the update loop each frame, and as a result of user interaction or other programmaticaly generated events. All memory for the built-in components is allocated statically: if you would like learn more about memory management, [read here](http://kivent.org/docs/memory_handlers.html).

KivEnt is built with a modular architecture and designed to have both a python api and a c-level cython api that allows more performant access to your game data. This makes it suitable for quickly prototyping a mechanic completely in python, and relatively trivial to then deeply cythonize that GameSystem if you find it to be performance sensitive. This process has already been done for the built-in components meaning they are ready for you to build new, performant game systems on top of them.

The entire framework is made available to you with an MIT license so that you have the freedom to build whatever you want on top of it and monetize it however you like. 

##Project Website: 
http://www.kivent.org

##Mailing List: 
https://groups.google.com/forum/#!forum/kivent

##Documentation: 
http://www.kivent.org/docs  

##Getting Started
Read the [introduction](https://github.com/Kovak/KivEnt/wiki/An-Introduction-to-KivEnt) on the github wiki.

##Dependencies
KivEnt is split into modules, the core module, 'kivent_core', is dependent only on Kivy.

Other modules may have other dependecies, listed here:

###kivent_core:
* [kivy](https://github.com/kivy/kivy)

###kivent_cymunk:
* [kivy](https://github.com/kivy/kivy)
* [cymunk](https://github.com/tito/cymunk)
* [kivent_core](https://github.com/Kovak/KivEnt/tree/master/modules/core)

##Installation
first install all dependencies then:

    cd .../KivEnt/modules/core
    python setup.py build_ext install
or

    cd .../KivEnt/modules/cymunk
    python setup.py build_ext install

If you want to install into a system python on something like ubuntu you may need to:

    sudo python setup.py build_ext install
    
If you would like to instead build the modules in place and use PYTHONPATH to find them:

    cd .../KivEnt/modules/core
    python setup.py build_ext --inplace
    export PYTHONPATH=/path/to/KivEnt/modules/core:$PYTHONPATH 
or:

    cd .../KivEnt/modules/cymunk
    python setup.py build_ext --inplace
    export PYTHONPATH=/path/to/KivEnt/modules/cymunk:$PYTHONPATH 

##Windows Kivy Portable Package Installation:

Open the kivy-2.7.bat (kivy-3.4.bat if using the py3 portable package) command console and type:

    pip install https://github.com/tito/cymunk/archive/master.zip
    
Now either download and extract or git clone the KivEnt source:

    git clone https://github.com/Kovak/KivEnt.git

Assuming you have KivEnt in the root folder for the portable package, in the kivy-2.7.bat console:

    cd KivEnt/modules/core
    python setup.py build_ext install
    #check core install
    cd ../../examples/2_basic_app
    python main.py
    cd ../../modules/cymunk
    python setup.py build_ext install
    #check that cymunk install
    cd ../../examples/6_controlling_the_viewing_area
    python main.py

##Tested On:
Tested with [Kivy 1.9](https://github.com/kivy/kivy). Python 2.7 and Python 3.4.

Tested on Asus Transformer TF101, Droid 4, Droid RAZR M, Ubuntu 14.04, and Windows 8.1

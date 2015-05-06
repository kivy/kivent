.. KivEnt documentation master file, created by
   sphinx-quickstart on Mon Apr 14 20:00:25 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to KivEnt's documentation!
==================================

KivEnt is a framework for developing Kivy widgets with large amounts of 
real-time rendering. At the moment it is 2d oriented, however this will 
probably change in the future as in principal it should be fairly easy to 
support 3d rendering as well. The only dependency for the kivent_core module 
is Kivy itself, making it a relatively lightweight solution for building 
performant scenes in Kivy. Additional modules may have other requirements, 
such as kivent_cymunk module being based on Chipmunk2d and its cymunk wrapper.

An entity-component architecture is used to control game object state and 
the logic of processing the game objects. This means that your game objects
will be made up of collections of independent components that stricly hold data
each component corresponds to a GameSystem that will perform all data processing 
on the components, in the update loop each frame, and as a result of 
user interaction or other programmaticaly generated events. 

KivEnt is built with a modular architecture and designed to have both a python
api and a c-level cython api that allows more performant access to your game 
data. This makes it suitable for quickly prototyping a mechanic 
completely in python and relatively trivial to deeply cythonize that 
GameSystem if you find it to have performance bottlenecks. This process has 
already been done for the built-in components meaning they are ready for you to
build new, performant game systems on top of them.

The entire framework is made available to you with an MIT license so that you 
have the freedom to build whatever you want on top of it and monetize it 
however you like. 


.. toctree::
   :maxdepth: 2

   gameworld
   entity
   gamesystems
   memory_handlers
   rendering
   managers
   physics


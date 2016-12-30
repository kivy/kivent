.. KivEnt documentation master file, created by
   sphinx-quickstart on Mon Apr 14 20:00:25 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to KivEnt's documentation!
==================================

**If you are just starting you may be interested in the** `tutorials <https://github.com/Kovak/KivEnt/wiki/An-Introduction-to-KivEnt>`_.

KivEnt is a framework for building performant, dynamic real-time scenes in Kivy. While not as powerful as something like the Unreal engine or Unity3d, KivEnt is capable of creating games that handle several thousands to tens of thousands of entities, depending on what type of processing we are doing on them. You can easily have a hundreds thousand static sprites rendered in the background if they do not have any dynamic processing. At the same time, almost the entire API is accessible through Python, with a more performant cythonic API for those looking to get closer to the metal. Even without creating any cython gamesystems, you ought to be able to create games that feature up to several thousand game objects at once.

The only dependency for the kivent_core module is `Kivy <http://kivy.org>`_ itself. Additional modules may have other requirements, such as kivent_cymunk module being based on `Chipmunk2d <https://chipmunk-physics.net/>`_ and its `cymunk wrapper <https://github.com/tito/cymunk>`_.

An entity-component architecture is used to control game object state and the logic of processing the game objects. This means that your game objects will be made up of collections of independent components that stricly hold data; each component corresponds to a GameSystem that will perform all data processing on the components, in the update loop each frame, and as a result of user interaction or other programmaticaly generated events. All memory for 
the built-in components is allocated statically: if you would like learn more
about memory management, `read here <http://kivent.org/docs/memory_handlers.html>`_.

KivEnt is built with a modular architecture and designed to have both a python api and a c-level cython api that allows more performant access to your game data. This makes it suitable for quickly prototyping a mechanic completely in python, and relatively trivial to then deeply cythonize that GameSystem if you find it to be performance sensitive. This process has already been done for the built-in components meaning they are ready for you to build new, performant game systems on top of them.

The entire framework is made available to you with an MIT license so that you have the freedom to build whatever you want on top of it and monetize it however you like. 

.. toctree::
   :maxdepth: 2

   gameworld
   entity
   gamesystems
   managers
   physics
   particles
   rendering
   memory_handlers
   tiled

   


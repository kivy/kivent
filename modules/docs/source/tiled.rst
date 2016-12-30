The Maps Module
***************
**These classes have cdefed functions that cannot be read by 
Sphinx. Read the source if you want to find out more about using them.**

This module extends the base functionality of KivEnt by integrating it with 
the Tiled map editor. See example 14_tmx_loader for a practical demonstration
of using these systems.

Tiled Managers
==============
If you are using the kivent_maps module, an additional manager will be
available to aid in the use of Tiled's map format.

.. autoclass:: kivent_maps.map_manager.MapManager
    :members:

Systems
=======
.. autoclass:: kivent_maps.map_system.MapSystem
    :members:

.. autoclass:: kivent_maps.map_system.MapComponent
    :members:

Utils
=====

.. automodule:: kivent_maps.map_utils
    :members:

Map Data
========
.. automodule:: kivent_maps.map_data
    :members:
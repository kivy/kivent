'''
The KivEnt Projectiles module is an experimental module that demonstrates
how many of the various kivent submodules could be brought together to 
produce a complex system. In this case handling the basics of projectiles,
collision logic, and damage. The module is sparsely documented at the moment,
but demonstrates how to bring the projectiles, cymunk, and core modules 
together to produce another cython module that makes use of C level features 
in all 3 modules.
'''
import os

__VERSION__ = '0.0.1'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivent_projectiles import projectiles
    from kivent_projectiles import weapons
    from kivent_projectiles import combatstats
    from kivent_projectiles import weapon_ai

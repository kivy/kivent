import os

__VERSION__ = '1.0.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivent_particles import particle
    from kivent_particles import emitter
    from kivent_particles import particle_renderers
    from kivent_particles import particle_formats

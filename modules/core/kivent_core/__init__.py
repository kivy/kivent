import os

__VERSION__ = '2.1.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivy.core.window import Window
    from kivent_core import memory_handlers
    from kivent_core import rendering
    from kivent_core import managers
    from kivent_core import entity
    from kivent_core import gameworld
    from kivent_core import systems

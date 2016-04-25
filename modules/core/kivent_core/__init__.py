import os

__VERSION__ = '2.1.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivy.core.window import Window
    from . import memory_handlers
    from . import rendering
    from . import managers
    from . import entity
    from . import gameworld
    from . import systems

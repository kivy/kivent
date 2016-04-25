import os

__VERSION__ = '1.0.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from . import physics
    from . import interaction

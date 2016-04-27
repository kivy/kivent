import os

__VERSION__ = '1.0.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivent_cymunk import physics
    from kivent_cymunk import interaction

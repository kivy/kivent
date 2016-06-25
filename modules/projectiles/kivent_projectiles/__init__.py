import os

__VERSION__ = '1.0.0'

if 'KIVENT_PREVENT_INIT' not in os.environ:
    from kivent_projectiles import projectiles
    from kivent_projectiles import weapons
    from kivent_projectiles import combatstats
    from kivent_projectiles import weapon_ai

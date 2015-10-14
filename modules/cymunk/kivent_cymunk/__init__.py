from . import physics
from . import interaction
from os.path import dirname, join

def get_includes():
    root_dir = dirname(__file__)
    return [root_dir, join(root_dir, 'chipmunk')]
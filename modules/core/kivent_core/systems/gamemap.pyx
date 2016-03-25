# cython: embedsignature=True
from gamesystem cimport GameSystem
from kivy.core.window import Window
from kivy.properties import (StringProperty, ListProperty, BooleanProperty)
from kivy.factory import Factory

cdef class GameMap(GameSystem):
    '''
    GameMap is a basic implementation of a map size for your GameWorld that
    limits the scrolling of GameView typically a GameMap does not actually
    have any entities, it simply holds some data and logic for use by
    other GameSystems

    **Attributes:**
        **map_size** (ListProperty): Sets the size of this map, used to
        determine scrolling bounds. If the map size is smaller than the
        window it will be centered inside the window.

        **margins** (ListProperty): The amount of scrolling beyond the size of
        the map in x, y directions to be allowed. If the map is smaller than
        the window. This value is calculated automatically.

        **default_margins** (ListProperty): The amount of margin if the map is
        larger than the window, defaults to (0, 0) which means no scrolling
        beyond edge of GameMap.

    '''
    system_id = StringProperty('default_map')
    map_size = ListProperty((2000., 2000.))
    window_size = ListProperty((0., 0.))
    margins = ListProperty((0., 0.))
    map_color = ListProperty((1., 1., 1., 1.))
    do_components = BooleanProperty(False)
    default_margins = ListProperty((0., 0.))

    def on_map_size(self, instance, value):
        self.check_margins()

    def on_size(self, instance, value):
        self.check_margins()

    def check_margins(self):
        map_size = self.map_size
        window_size = Window.size
        window_larger_x = False
        window_larger_y = False
        if window_size[0] > map_size[0]:
            margin_x = (window_size[0] - map_size[0])/2.
            window_larger_x = True
        if window_size[1] > map_size[1]:
            margin_y = (window_size[1] - map_size[1])/2.
            window_larger_y = True
        if window_larger_x:
            self.margins[0] = margin_x
        if window_larger_y:
            self.margins[1] = margin_y
        if not window_larger_x and not window_larger_y:
            self.margins = self.default_margins


Factory.register('GameMap', cls=GameMap)

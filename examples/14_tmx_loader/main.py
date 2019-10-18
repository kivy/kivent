from kivy.app import App
from kivy.core.window import Window
from kivy.clock import Clock
from kivy.uix.widget import Widget
from kivy.properties import StringProperty
from kivent_core.systems.gamesystem import GameSystem
from kivent_core.managers.resource_managers import texture_manager
from os.path import dirname, join, abspath
from kivent_maps import map_utils
from kivent_maps.map_system import MapSystem
from kivy.logger import Logger

Window.size = (640, 640)

def get_asset_path(asset, asset_loc):
    return join(dirname(dirname(abspath(__file__))), asset_loc, asset)

class TestGame(Widget):
    """Testgame to show off kivent_maps functionality."""

    def on_kv_post(self, *args):

        # Args required for Renderer init
        map_render_args = {
            'zones': ['general'],
            'frame_count': 2,
            'gameview': 'camera1',
            'shader_source': get_asset_path('positionshader.glsl', 'assets/glsl')
        }
        # Args for AnimationSystem init
        map_anim_args = {
            'zones': ['general'],
        }
        # Args for PolyRenderer init
        map_poly_args = {
            'zones': ['general'],
            'frame_count': 2,
            'gameview': 'camera1',
            'shader_source': 'poscolorshader.glsl'
        }

        # Initialise systems for 4 map layers and get the renderer and
        # animator names
        self.map_layers, self.map_layer_animators = \
                map_utils.load_map_systems(4, self.gameworld,
                        map_render_args, map_anim_args, map_poly_args)

        # Set the camera1 render order to render lower layers first
        self.camera1.render_system_order = reversed(self.map_layers)

        # Init gameworld with all the systems
        self.gameworld.init_gameworld(
            ['position', 'color', 'camera1', 'tile_map']
            + self.map_layers
            + self.map_layer_animators,
            callback=self.init_game)


    def init_game(self):
        self.setup_states()
        self.setup_tile_map()
        self.set_state()

    def setup_tile_map(self):
        # The map file to load
        # Change to hexagonal/isometric/isometric_staggered.tmx for other maps
        filename = get_asset_path('orthogonal.tmx','assets/maps')
        map_manager = self.gameworld.managers['map_manager']

        # Load TMX data and create a TileMap from it
        map_name = map_utils.parse_tmx(filename, self.gameworld)

        # Initialise each tile as an entity in the gameworld
        map_utils.init_entities_from_map(map_manager.maps[map_name],
                                       self.gameworld.init_entity)

        self.tilemap = map_manager.maps[map_name]
        Logger.info('timemap set')

    def setup_states(self):
        # We want renderers to be added and unpaused
        # and animators to be unpaused
        self.gameworld.add_state(state_name='main',
                systems_added=self.map_layers,
                systems_unpaused=self.map_layer_animators + self.map_layers)

    def set_state(self):
        self.gameworld.state = 'main'

    def screen_touched(self,event):
        x,y = event.pos
        cx,cy = self.camera1.camera_pos
        x -= self.pos[0] + cx
        y -= self.pos[1] + cy

        Logger.info('Tile %d,%d clicked' % self.tilemap.get_tile_index(x,y))

class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)


class YourAppNameApp(App):
    pass


if __name__ == '__main__':
    YourAppNameApp().run()

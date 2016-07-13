from kivy.app import App
from kivy.core.window import Window
from kivy.uix.widget import Widget
from kivent_core.systems.gamesystem import GameSystem
from kivent_core.managers.resource_managers import texture_manager
from os.path import dirname, join, abspath
from kivent_maps import map_utils
from kivent_maps.map_system import MapSystem

Window.size = (640, 640)

def get_asset_path(asset, asset_loc):
    return join(dirname(dirname(abspath(__file__))), asset_loc, asset)

class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)

        map_render_args = {
            'zones': ['general'],
            'frame_count': 2,
            'gameview': 'camera1',
            'shader_source': get_asset_path('positionshader.glsl', 'assets/glsl')
        }
        map_anim_args = {
            'zones': ['general'],
        }
        self.map_layers, self.map_layer_animators = map_utils.load_map_systems(
                3, self.gameworld, map_render_args, map_anim_args)

        self.camera1.render_system_order = reversed(self.map_layers)

        self.gameworld.init_gameworld(
            ['position', 'camera1', 'tile_map']
            + self.map_layers
            + self.map_layer_animators,
            callback=self.init_game)


    def init_game(self):
        print("init game")
        self.setup_states()
        self.setup_tile_map()
        self.set_state()

    def setup_tile_map(self):
        print("Setting up tilemap")
        filename = get_asset_path('map.tmx','assets')
        map_manager = self.gameworld.managers['map_manager']

        map_name = map_utils.parse_tmx(filename, self.gameworld)
        map_utils.init_entities_from_map(map_manager.maps[map_name],
                                       self.gameworld.init_entity)

    def setup_states(self):
        self.gameworld.add_state(state_name='main',
                systems_added=self.map_layers,
                systems_unpaused=self.map_layer_animators + self.map_layers)

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    pass


if __name__ == '__main__':
    YourAppNameApp().run()

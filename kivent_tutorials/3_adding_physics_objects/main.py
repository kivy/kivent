from kivy.app import App
print('imported kivy')
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint, choice
from math import radians, pi, sin, cos
import kivent_core
import kivent_cymunk
from kivent_core.gameworld import GameWorld
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.rendering.vertmesh import VertMesh
from kivent_core.systems.renderers import PhysicsRenderer
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.rotate_systems import RotateSystem2D
from kivy.properties import StringProperty, NumericProperty
import cProfile
from functools import partial



texture_manager.load_atlas('assets/background_objects.atlas')

class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        print('start app')
        self.gameworld.init_gameworld(['map', 'cymunk_physics', 
            'physics_renderer', 
            'rotate', 'position', 'gameview', 'scale', 'color'],
            callback=self.init_game)
        print('gameworld inited')

    def init_game(self):
        print('in setup')
        self.setup_states()
        self.set_state()



    def draw_game(self):
        self.draw_some_stuff()

    def destroy_created_entity(self, ent_id, dt):
        self.gameworld.remove_entity(ent_id)
        self.app.count -= 1

    def draw_some_stuff(self):
        size = Window.size
        w, h = size[0], size[1]
        create_asteroid = self.create_asteroid
        for x in range(100):
            pos = (randint(0, w), randint(0, h))
            ent_id = create_asteroid(pos)
            Clock.schedule_once(partial(self.destroy_created_entity, ent_id), 1.)
            #print(self.gameworld.entity_manager.get_entity_ids(ent_id))
        self.app.count += 100
        


    def create_asteroid(self, pos):
        x_vel = randint(-500, 500)
        y_vel = randint(-500, 500)
        angle = radians(randint(-360, 360))
        angular_velocity = radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 3, 
            'mass': 50, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 250, 
            'ang_vel_limit': radians(200), 
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'cymunk_physics': physics_component, 
            'physics_renderer': {'texture': 'star1', 
            'size': (6, 6),
            'render': True}, 
            'position': pos, 'rotate': 0, 'color': (1., 1., 1., 1.),
            'scale': 1.}
        component_order = ['position', 'rotate', 'color', 'physics_renderer', 
            'scale', 'cymunk_physics']
        return self.gameworld.init_entity(
            create_component_dict, component_order)

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['physics_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['physics_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)

class YourAppNameApp(App):
    count = NumericProperty(0)

    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    #YourAppNameApp().run()
    cProfile.run('YourAppNameApp().run()', 'prof.prof')

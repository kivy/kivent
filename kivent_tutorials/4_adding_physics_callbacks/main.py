from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from kivent import GameSystem
from random import randint
from math import radians
from functools import partial


class BoundarySystem(GameSystem):


    def begin_collide_with_boundary(self, space, arbiter):
        ent1_id = arbiter.shapes[0].body.data
        ent2_id = arbiter.shapes[1].body.data
        return False

    def catch_boundary_callback(self, space, arbiter):
        gameworld = self.gameworld
        entities = gameworld.entities
        ent1_id = arbiter.shapes[0].body.data
        ent2_id = arbiter.shapes[1].body.data
        map_pos = gameworld.pos
        map_size = gameworld.currentmap.map_size
        asteroid = entities[ent1_id]
        body = asteroid.physics.body
        Clock.schedule_once(partial(self.handle_replacing_asteroid,
            body, space, 
            (map_pos[0]+map_size[0]*.5, map_pos[1]+map_size[1]*.5)))

    def separate_from_boundary(self, space, arbiter):
        ###This algorithm is in the works!
        gameworld = self.gameworld
        entities = gameworld.entities
        ent1_id = arbiter.shapes[0].body.data
        ent2_id = arbiter.shapes[1].body.data
        map_pos = gameworld.pos
        map_size = gameworld.currentmap.map_size
        asteroid = entities[ent1_id]
        pos_system = asteroid.position
        x, y = pos_system.x, pos_system.y
        body = asteroid.physics.body
        new_x, new_y = x, y
        if x <= map_pos[0]:
            new_x = map_size[0] + map_pos[0] + 32
        elif x >= map_pos[0] + map_size[0]:
            new_x = map_pos[0] - 32
        if y <= map_pos[1]:
            new_y = map_size[1] + map_pos[1] + 32
        elif y >= map_size[1] + map_pos[1]:
            new_y = map_pos[1] - 32
        Clock.schedule_once(partial(self.handle_replacing_asteroid, 
            body, space, (new_x, new_y)))
        return False

    def handle_replacing_asteroid(self, body, space, position, dt):
        space.remove(body)
        body.position = position
        space.add(body)

    def generate_boundaries(self):
        gameworld = self.gameworld
        map_pos = gameworld.pos
        map_size = gameworld.currentmap.map_size
        center_of_map = (map_pos[0] + .5*map_size[0], map_pos[1] + .5*map_size[1])
        expanded_size = map_size[0]*1.5, map_size[1]*1.5
        self.generate_boundary(map_size, center_of_map)
        self.generate_catch_boundary(expanded_size, center_of_map)

    def generate_catch_boundary(self, boundary_size, boundary_pos):
        gameworld = self.gameworld
        shape_dict = {'width': boundary_size[0], 
            'height': boundary_size[1], 'mass': 0}
        col_shape_dict = {'shape_type': 'box', 
            'elasticity': 0.0, 'collision_type': 3, 
            'shape_info': shape_dict, 'friction': 0.0}
        physics_component_dict = {'main_shape': 'box', 'velocity': (0, 0), 
            'position': boundary_pos, 'angle':0, 'angular_velocity': 0,
            'mass': 0, 'vel_limit': 0, 'ang_vel_limit': 0, 
            'col_shapes': [col_shape_dict]}
        boundary_system = {}
        create_component_dict = {
            'position': boundary_pos,
            'rotate': 0.,
            'color': (0.0, 0.0, 1.0, .75),
            'physics': physics_component_dict, 
            'boundary': boundary_system,
            'debug_renderer': {'size': boundary_size}}
        component_order = ['position', 'rotate',  'color',
            'physics', 'boundary', 'debug_renderer']
        self.gameworld.init_entity(create_component_dict, component_order)


    def generate_boundary(self, boundary_size, boundary_pos):
        gameworld = self.gameworld
        shape_dict = {'width': boundary_size[0], 
            'height': boundary_size[1], 'mass': 0}
        col_shape_dict = {'shape_type': 'box', 
            'elasticity': 0.0, 'collision_type': 2, 
            'shape_info': shape_dict, 'friction': 0.0}
        physics_component_dict = {'main_shape': 'box', 'velocity': (0, 0), 
            'position': boundary_pos, 'angle':0, 'angular_velocity': 0,
            'mass': 0, 'vel_limit': 0, 'ang_vel_limit': 0, 
            'col_shapes': [col_shape_dict]}
        boundary_system = {}
        create_component_dict = {
            'position': boundary_pos,
            'rotate': 0.,
            'color': (1.0, 0.0, 0.0, .75),
            'physics': physics_component_dict, 
            'boundary': boundary_system,
            'debug_renderer': {'size': boundary_size}}
        component_order = ['position', 'rotate',  'color',
            'physics', 'boundary', 'debug_renderer']
        self.gameworld.init_entity(create_component_dict, component_order)

    def clear(self):
        gameworld = self.gameworld
        remove = gameworld.timed_remove_entity
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(remove, entity_id))


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        self.setup_map()
        self.setup_states()
        self.set_state()
        self.setup_boundary()
        self.setup_collision_callbacks()
        self.draw_some_stuff()
        Clock.schedule_interval(self.update, 0)

    def setup_boundary(self):
        boundary_system = self.gameworld.systems['boundary']
        boundary_system.generate_boundaries()

    def setup_collision_callbacks(self):
        systems = self.gameworld.systems
        physics_system = systems['physics']
        boundary_system = systems['boundary']
        physics_system.add_collision_handler(
            1, 2, 
            begin_func=boundary_system.begin_collide_with_boundary,
            separate_func=boundary_system.separate_from_boundary)
        physics_system.add_collision_handler(2, 2,
            begin_func=boundary_system.begin_collide_with_boundary)
        physics_system.add_collision_handler(
            1, 3, 
            begin_func=boundary_system.begin_collide_with_boundary,
            separate_func=boundary_system.catch_boundary_callback)
        physics_system.add_collision_handler(2, 3,
            begin_func=boundary_system.begin_collide_with_boundary)

    def draw_some_stuff(self):
        size = self.gameworld.currentmap.map_size
        for x in range(20):
            pos = (randint(0, size[0]), randint(0, size[1]))
            self.create_asteroid(pos)

    def create_asteroid(self, pos):
        x_vel = randint(-100, 100)
        y_vel = randint(-100, 100)
        angle = radians(randint(-360, 360))
        angular_velocity = radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 32, 
            'mass': 50, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': 1.0, 
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 0.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 250, 
            'ang_vel_limit': radians(200), 
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'physics_renderer': {'texture': 'asteroid1', 'size': (64 , 64)}, 
            'position': pos, 'rotate': 0}
        component_order = ['position', 'rotate', 
            'physics', 'physics_renderer']
        return self.gameworld.init_entity(create_component_dict, component_order)

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer', 'debug_renderer', 'physics_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'debug_renderer', 'physics_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()

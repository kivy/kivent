from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from random import randint
from math import radians, atan2, degrees
from kivent import GameSystem
import cymunk
from cymunk import PivotJoint, GearJoint, Body
from kivy.properties import NumericProperty, ListProperty
from kivy.vector import Vector



class ControlSystem(GameSystem):
    current_entity = NumericProperty(None)
    target_pos = ListProperty(None)

    def on_touch_down(self, touch):
        self.target_pos = (touch.x, touch.y)

    def create_component(self, entity, args):
        super(ControlSystem, self).create_component(entity, args)
        gameworld = self.gameworld
        systems = gameworld.systems
        physics_system = systems['physics']
        control = entity.control
        parent_id = control.parent
        control.body = control_body = Body(None, None)
        parent_ent = gameworld.entities[parent_id]
        parent_body = parent_ent.physics.body
        parent_position = parent_ent.position
        ent_position = entity.position
        print parent_body.position
        control_body.position = (entity.position.x, entity.position.y)
        pivot = PivotJoint(control_body, parent_body, 
            (0, 0), 
            (0, 0))
        gear = GearJoint(control_body, parent_body,
            0.0, 1.0)
        gear.max_bias = 10.0 #Controls turning speed
        gear.max_force = 750000.0#stronger force needed for faster turning stability
        gear.error_bias = 0.
        pivot.max_force = 10000.0
        pivot.max_bias = 0.0
        pivot.error_bias = 0
        space = physics_system.space
        space.add(pivot)
        space.add(gear)
        control.pivot = pivot
        control.gear = gear
        self.current_entity = entity.entity_id

    def update(self, dt):
        entity_ids = self.entity_ids
        gameworld = self.gameworld
        entities = gameworld.entities
        current_entity = self.current_entity
        entity = entities[current_entity]
        parent_id = entity.control.parent
        parent_ent = entities[parent_id]
        pbody = parent_ent.physics.body
        ent_body = entity.control.body
        parent_pos = pbody.position
        target_pos = self.target_pos
        rot_vector = pbody.rotation_vector
        parent_angle = pbody.angle
        if target_pos:
            v1 = rot_vector
            ad = degrees(parent_angle)
            v2 = target_delta = Vector(target_pos) - Vector(parent_pos)
            turn = v1[0]*v2[0] + v1[1]*v2[1], v1[1]*v2[0] - v1[0]*v2[1]
            amount_to_turn = atan2(turn[1], turn[0])
            difference = parent_angle - amount_to_turn
            ent_body.angle = difference
            print amount_to_turn
            if Vector(target_pos).distance(parent_pos) <= 30.0:
                velocity_rot = (0, 0)
            elif amount_to_turn <= -1.3 or amount_to_turn >= 1.3:
                velocity_rot = (0, 0)
            else:

                velocity_rot = self.rotate_vector(v1, (250, 0)) # Controls the speed of object
            ent_body.velocity = velocity_rot


    def rotate_vector(self, v1, v2):
        return (v1[0]*v2[0] - v1[1]*v2[1], v1[0]*v2[1] + v1[1]*v2[0])

            




class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        self.setup_map()
        self.setup_states()
        self.set_state()
        self.setup_collision_callbacks()
        self.draw_some_stuff()
        Clock.schedule_interval(self.update, 0)

    def draw_some_stuff(self):
        size = Window.size
        for x in range(1):
            pos = (250, 250)
            ship_id = self.create_ship(pos)
            self.create_control_point(pos, ship_id)

    def no_collide(self, space, arbiter):
        return False

    def setup_collision_callbacks(self):
        systems = self.gameworld.systems
        physics_system = systems['physics']
        physics_system.add_collision_handler(
            1, 2, 
            begin_func=self.no_collide)

    def create_control_point(self, pos, ship_id):
        create_component_dict = {'position': pos, 'rotate': 0, 
            'control': {'parent': ship_id}}    
        component_order = ['position', 'rotate', 'control']
        return self.gameworld.init_entity(create_component_dict, component_order)

    def create_ship(self, pos):
        x_vel = 0
        y_vel = 0
        angle = 0
        angular_velocity = 0
        shape_dict = {'inner_radius': 0, 'outer_radius': 45, 
            'mass': 10, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .0, 
            'collision_type': 1, 'shape_info': shape_dict, 'friction': .7}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 750, 
            'ang_vel_limit': radians(900), 
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'physics_renderer': {'texture': 'ship7', 'size': (96 , 88)}, 
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
            systems_added=['renderer', 'physics_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'physics_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()

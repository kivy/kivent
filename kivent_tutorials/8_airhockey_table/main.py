from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from random import randint, choice
from math import radians, pi, sin, cos
from kivent import texture_manager, VertMesh


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def ensure_startup(self):
        systems_to_check = ['map', 'physics', 'renderer', 
            'rotate', 'position', 'gameview']
        systems = self.gameworld.systems
        for each in systems_to_check:
            if each not in systems:
                return False
        return True

    def init_game(self, dt):
        if self.ensure_startup():
            self.setup_map()
            self.setup_states()
            self.set_state()
            self.draw_some_stuff()
            Clock.schedule_interval(self.update, 0)
        else:
            Clock.schedule_once(self.init_game)


    def draw_some_stuff(self):
        size = Window.size
        self.created_entities = created_entities = []
        entities = self.gameworld.entities
        puck_id = self.create_puck((100, 100))
        self.draw_wall(1920., 20., (1920./2., 10.), (0., 1., 0., 1.))
        self.draw_wall(1920., 20., (1920./2., 1080.-10.), (0., 1., 0., 1.))
        self.draw_wall(20., 1080., (10., 1080./2.), (0., 1., 0., 1.))
        self.draw_wall(20., 1080., (1920.-10., 1080./2.), (0., 1., 0., 1.))

    def draw_wall(self, width, height, pos, color):
        x_vel = 0 #randint(-100, 100)
        y_vel = 0 #randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'width': width, 'height': height, 
            'mass': 0, 'offset': (0, 0)}
        col_shape = {'shape_type': 'box', 'elasticity': .5, 
            'collision_type': 2, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'box', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 0., 
            'ang_vel_limit': radians(0.), 
            'mass': 0, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'renderer': {'size': (width, height),'render': True}, 
            'position': pos, 'rotate': 0, 'color': color,}
        component_order = ['position', 'rotate', 'color',
            'physics', 'renderer',]
        return self.gameworld.init_entity(create_component_dict, component_order)


    def draw_regular_polygon(self, sides, radius, color):
        x, y = 0., 0.
        angle = 2. * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        l_pos = list((x, y))
        l_pos.extend(color)
        all_verts_a(l_pos)
        triangles = []
        triangles_a = triangles.extend
        r = radius
        for s in range(sides):
            new_pos = x + r * sin(s * angle), y + r * cos(s * angle)
            l_pos = list(new_pos)
            l_pos.extend((0., 0.))
            l_pos.extend(color)
            all_verts_a(l_pos)
            if s == sides-1:
                triangles_a((s+1, 0, 1))
            else:
                triangles_a((s+1, 0, s+2))
        render_system = self.gameworld.systems['renderer']
        vert_count = len(all_verts)
        index_count = len(triangles)
        vert_mesh =  VertMesh(render_system.attribute_count, 
            vert_count, index_count)
        vert_mesh.indices = triangles
        for i in range(vert_count):
            vert_mesh[i] = all_verts[i]
        return vert_mesh


    def create_puck(self, pos):
        x_vel = 0 #randint(-100, 100)
        y_vel = 0 #randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 75., 
            'mass': 50, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        vert_mesh = self.draw_regular_polygon(30, 75., (1., 0., 0., 1.))
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 1500., 
            'ang_vel_limit': radians(200), 
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'renderer': {#'texture': 'asteroid1', 
            'vert_mesh': vert_mesh, 
            #'size': (64, 64),
            'render': True}, 
            'position': pos, 'rotate': 0, 'color': (1., 0., 0., 1.),}
        component_order = ['position', 'rotate', 'color',
            'physics', 'renderer',]
        return self.gameworld.init_entity(create_component_dict, component_order)

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()

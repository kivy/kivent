import os
os.environ['KIVY_AUDIO'] = 'pygame'

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint, choice
from math import radians, pi, sin, cos
import kivent_core
import kivent_cymunk

from kivent_core.renderers import texture_manager, VertMesh
from kivent_cymunk.physics import CymunkPhysics
from functools import partial

import sounds


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def ensure_startup(self):
        systems_to_check = ['map', 'physics', 'renderer', 
            'rotate', 'position', 'gameview', 'lerp_system']
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
            self.setup_collision_callbacks()
            Clock.schedule_interval(self.update, 0)
        else:
            Clock.schedule_once(self.init_game)
    def getWorldPosFromTuple(self, tup):

        viewport = self.gameworld.systems['gameview']
        return tup[0]*viewport.camera_scale - viewport.camera_pos[0], tup[1]*viewport.camera_scale - viewport.camera_pos[1]
    def on_touch_down(self, touch):
        wp = self.getWorldPosFromTuple(touch.pos)
        if 0.3<touch.spos[1]<0.7:
            xspos = touch.spos[0]
            if xspos<0.08 or xspos>0.92:
                paddleid = self.create_paddle(wp, color=(1.-xspos,0.,xspos,0.65))
        super(TestGame, self).on_touch_down(touch)
    def on_touch_up(self, touch):
        super(TestGame, self).on_touch_up(touch)
        if 0.3<touch.spos[1]<0.7 and 'touched_ent_id' in touch.ud:
            if touch.spos[0]<0.08 or touch.spos[0]>0.92:
                touched_id = touch.ud['touched_ent_id']
                if touched_id in self.paddleIDs:
                    self.remove_entity(touched_id)
    def setup_collision_callbacks(self):
        systems = self.gameworld.systems
        physics_system = systems['physics']
        def rfalse(na,nb):
             return False
        physics_system.add_collision_handler(
            1, 3, 
            begin_func=self.begin_collide_with_airhole,
            separate_func=self.begin_seperate_with_airhole)
        physics_system.add_collision_handler(
            1, 2,
            post_solve_func=self.postsolve_collide_sound)
        physics_system.add_collision_handler(
            1, 4, 
            begin_func=self.begin_collide_with_goal)
        physics_system.add_collision_handler(
            1, 5, 
            begin_func=self.begin_collide_with_real_goal)
        physics_system.add_collision_handler(
            1, 6,
            post_solve_func=self.postsolve_collide_sound)
        physics_system.add_collision_handler(
            6, 6,
            post_solve_func=self.postsolve_collide_sound)
        physics_system.add_collision_handler(
            6, 2,
            post_solve_func=self.postsolve_collide_sound)
        physics_system.add_collision_handler(
            6, 3,
            begin_func=self.begin_collide_with_airhole,
            separate_func=self.begin_seperate_with_airhole)
        physics_system.add_collision_handler(
            6, 4,
            begin_func=rfalse)
        physics_system.add_collision_handler(
            6, 5,
            begin_func=rfalse)

    def begin_collide_with_goal(self, space, arbiter):
        systems = self.gameworld.systems
        ent1_id = arbiter.shapes[0].body.data #puck
        ent2_id = arbiter.shapes[1].body.data #goal
        lerp_system = systems['lerp_system']
        lerp_system.add_lerp_to_entity(ent2_id, 'color', 'r', 1., .3,
            'float', callback=self.lerp_callback_goal_score)
        
        return False

    def begin_collide_with_real_goal(self, space, arbiter):
        ent1_id = arbiter.shapes[0].body.data #puck
        ent2_id = arbiter.shapes[1].body.data #goal
        puck = self.gameworld.entities[ent1_id]
        puckposition = puck.physics.body.position
        #self.create_puck_fader((puckposition.x,puckposition.y))
        self.remove_entity(ent1_id)
        Clock.schedule_once(self.spawn_new_puck, 2.5)
        sounds.play_jingle()
        return False

    def spawn_new_puck(self, dt):
        puck_id = self.create_puck((1920.*.5, 1080.*.5))
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.add_lerp_to_entity(puck_id, 'color', 'g', .4, 5.,
            'float', callback=self.lerp_callback)

    def begin_collide_with_airhole(self, space, arbiter):
        ent1_id = arbiter.shapes[0].body.data #puck
        ent2_id = arbiter.shapes[1].body.data #airhole
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.clear_lerps_from_entity(ent2_id)
        lerp_system.add_lerp_to_entity(ent2_id, 'color', 'a', .85, .2,
            'float', callback=self.lerp_callback_airhole)
        lerp_system.add_lerp_to_entity(ent2_id, 'scale', 's', 1.2, .3,
            'float')#, callback=self.lerp_callback_airhole_scale)#
        if ent1_id not in self.paddleIDs: sounds.play_click(.2)
        #else:
        ent = self.gameworld.entities[ent1_id]
        lerp_system.add_lerp_to_entity(ent2_id, 'color', 'b', ent.color.b, .2,
            'float', callback=self.lerp_callback_airhole)
        lerp_system.add_lerp_to_entity(ent2_id, 'color', 'r', ent.color.r, .2,
            'float', callback=self.lerp_callback_airhole)

        return False
    def postsolve_collide_sound(self, space, arbiter):
        #ent1_id = arbiter.shapes[0].body.data #puck
        #ent2_id = arbiter.shapes[1].body.data #paddle
        crashforce =  arbiter.total_ke
        vol = min(1,crashforce/50000000)
        if vol<0.1:return
        if arbiter.is_first_contact:
            sounds.play_thack(vol)
        else:
            sounds.vol_thack(vol)
        return True

    def lerp_callback_goal_score(self, entity_id, component_name, property_name,
        final_value):
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        if final_value > .95:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .50, .25, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value > .85:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .40, .25, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value > .75:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .30, .25, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value > .65:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .20, .25, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value < .25:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, 0., 1., 'float', )
        elif final_value < .35:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .70, .5, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value < .45:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .80, .5, 'float', 
                callback=self.lerp_callback_goal_score)
        elif final_value < .55:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .90, .5, 'float', 
                callback=self.lerp_callback_goal_score)
        else:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, 0., 1., 'float', )
        

    def lerp_callback_airhole(self, entity_id, component_name, property_name, 
        final_value):
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.add_lerp_to_entity(entity_id, 'color', 'a', .25, 5.5,
            'float')
        lerp_system.add_lerp_to_entity(entity_id, 'scale', 's', .5, 5.5,
            'float')
    '''def lerp_callback_airhole_scale(self, entity_id, component_name, property_name,
        final_value):
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']'''

    def begin_seperate_with_airhole(self, space, arbiter):
        ent1_id = arbiter.shapes[0].body.data #puck
        ent2_id = arbiter.shapes[1].body.data #airhole
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.clear_lerps_from_entity(ent2_id)
        lerp_system.add_lerp_to_entity(ent2_id, 'color', 'a', .25, 2.5,
            'float')
        lerp_system.add_lerp_to_entity(ent2_id, 'scale', 's', .5, 2.5,
            'float')
        return False

    def draw_some_stuff(self):
        size = Window.size
        self.paddleIDs = set()
        self.puckIDs = set()
        self.created_entities = created_entities = []
        entities = self.gameworld.entities
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        puck_id = self.create_puck((1920.*.5, 1080.*.5))
        a_paddle_id = self.create_paddle((1920.*.25, 1080.*.5), color=(1.,0.,0.,0.65))
        a_paddle_id = self.create_paddle((1920.*.75, 1080.*.5), color=(0.,0.,1.,0.65))
        lerp_system.add_lerp_to_entity(puck_id, 'color', 'g', .4, 5.,
            'float', callback=self.lerp_callback)
        goal_height=540
        goal_thickness=150
        wall_height=(1080/2-goal_height/2.)
        wall_middle=wall_height/2.

        #left goal walls
        self.draw_wall(20., wall_height, (goal_thickness, wall_middle), (0., 1., 0., 1.))
        self.draw_wall(20., wall_height, (goal_thickness, 1080-wall_middle), (0., 1., 0., 1.))
        self.draw_wall(20., goal_height, (10, 1080/2), (0., 1., 0., 1.))
        self.draw_wall(goal_thickness, 20., (goal_thickness/2., 1080/2+goal_height/2), (0., 1., 0., 1.))
        self.draw_wall(goal_thickness, 20., (goal_thickness/2., 1080/2-goal_height/2), (0., 1., 0., 1.))

        #right goal walls
        self.draw_wall(20., wall_height, (1920-goal_thickness, wall_middle), (0., 1., 0., 1.))
        self.draw_wall(20., wall_height, (1920-goal_thickness, 1080-wall_middle), (0., 1., 0., 1.))
        self.draw_wall(20., goal_height, (1920-10, 1080/2), (0., 1., 0., 1.))
        self.draw_wall(goal_thickness, 20., (1920-goal_thickness/2., 1080/2+goal_height/2), (0., 1., 0., 1.))
        self.draw_wall(goal_thickness, 20., (1920-goal_thickness/2., 1080/2-goal_height/2), (0., 1., 0., 1.))

        self.draw_wall(1920-goal_thickness*2., 20., (1920./2., 10.), (0., 1., 0., 1.))
        self.draw_wall(1920-goal_thickness*2., 20., (1920./2., 1080.-10.), (0., 1., 0., 1.))
        #self.draw_wall(20., 1080., (10., 1080./2.), (0., 1., 0., 1.))
        #self.draw_wall(20., 1080., (1920.-10., 1080./2.), (0., 1., 0., 1.))
        self.draw_goal((20.+150./2., (1080.-540.)/2. + 540./2.), (150., 540.), 
            (0., 1., 0., 1.0))
        self.draw_goal((20.+100./2., (1080.-450.)/2. + 450./2.), (100., 450.), 
            (1., 0., 0., .25), collision_type=5)
        self.draw_goal((1920. - (20.+150./2.), (1080.-540.)/2. + 540./2.), 
            (150., 540.), (0., 1., 0., 1.0))
        self.draw_goal((1920. - (20.+100./2.), (1080.-450.)/2. + 450./2.), 
            (100., 450.), (1., 0., 0., .25), collision_type=5)
        x1 = 225
        y1 = 95
        for x in range(15):
            for y in range(10):
                pos = (x1 + 104. *x, y1 + 100*y)
                self.create_air_hole(pos)

    def draw_goal(self, pos, size, color, collision_type=4):
        x_vel = 0 #randint(-100, 100)
        y_vel = 0 #randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        width, height = size
        shape_dict = {'width': width, 'height': height, 
            'mass': 0, 'offset': (0, 0)}
        col_shape = {'shape_type': 'box', 'elasticity': .5, 
            'collision_type': collision_type, 'shape_info': shape_dict, 
            'friction': 1.0}
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
            'position': pos, 'rotate': 0, 'color': color,
            'lerp_system': {},
            'scale':1}
        component_order = ['position', 'rotate', 'color',
            'physics', 'renderer', 'lerp_system','scale']
        return self.gameworld.init_entity(create_component_dict, 
            component_order)

    def remove_entity(self, entity_id):
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.clear_lerps_from_entity(entity_id)
        if entity_id in self.paddleIDs:
            self.paddleIDs.remove(entity_id)
        if entity_id in self.puckIDs:
            self.puckIDs.remove(entity_id)
        #self.gameworld.remove_entity(entity_id)
        Clock.schedule_once(partial(
            self.gameworld.timed_remove_entity, entity_id))
    def lerp_callback_remove_ent(self, entity_id, component_name, property_name,
        final_value):
        self.remove_entity(entity_id)
    def lerp_callback(self, entity_id, component_name, property_name, 
        final_value):
        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        if final_value <= .5:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, 1., 5., 'float', callback=self.lerp_callback)
        else:
            lerp_system.add_lerp_to_entity(entity_id, component_name, 
                property_name, .1, 5., 'float', callback=self.lerp_callback)

    def draw_wall(self, width, height, pos, color):
        x_vel = 0 #randint(-100, 100)
        y_vel = 0 #randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'width': width, 'height': height, 
            'mass': 0, 'offset': (0, 0)}
        col_shape = {'shape_type': 'box', 'elasticity': .8,
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
            'position': pos, 'rotate': 0, 'color': color,
            'scale':1}
        component_order = ['position', 'rotate', 'color',
            'physics', 'renderer','scale']
        return self.gameworld.init_entity(create_component_dict, 
            component_order)

    def create_air_hole(self, pos):
        x_vel = 0 #randint(-100, 100)
        y_vel = 0 #randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 40., 
            'mass': 0, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
            'collision_type': 3, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        color=(.25, .25, .25, .25)
        vert_mesh = self.draw_regular_polygon(30, 40., color)
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 0., 
            'ang_vel_limit': radians(0.), 
            'mass': 0, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'renderer': {#'texture': 'asteroid1', 
            'vert_mesh': vert_mesh, 
            #'size': (64, 64),
            'render': True}, 
            'position': pos, 'rotate': 0, 'color': color,
            'lerp_system': {},
            'scale':.5}
        component_order = ['position', 'rotate', 'color',
            'physics', 'renderer', 'lerp_system', 'scale']
        return self.gameworld.init_entity(create_component_dict, 
            component_order)


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
        x_vel = randint(-100, 100)
        y_vel = randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 75., 
            'mass': 50, 'offset': (0., 0.)}
        col_shape = {'shape_type': 'circle', 'elasticity': .8,
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        vert_mesh = self.draw_regular_polygon(30, 75., (0., 1., 0., 1.))
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 1500., 
            'ang_vel_limit': radians(200), 
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component, 
            'puck_renderer': {#'texture': 'asteroid1', 
            'vert_mesh': vert_mesh, 
            #'size': (64, 64),
            'render': True}, 
            'position': pos, 'rotate': 0, 'color': (0., 1., 0., 1.),
            'lerp_system': {},
            'scale':1}
        component_order = ['position', 'rotate', 'color',
            'physics', 'puck_renderer', 'lerp_system','scale']
        a_puck_id =  self.gameworld.init_entity(create_component_dict,
            component_order)

        self.puckIDs.add(a_puck_id)
        return a_puck_id


    def create_puck_fader(self, pos, start_alpha=.5,end_alpha=0.,start_scale=1.,end_scale=.1):
        x_vel = randint(-100, 100)
        y_vel = randint(-100, 100)
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 75.,
            'mass': 50, 'offset': (0., 0.)}
        col_shape = {'shape_type': 'circle', 'elasticity': .8,
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        vert_mesh = self.draw_regular_polygon(30, 75., (1., 0., 0., 1.))
        create_component_dict = {
            'puck_renderer': {#'texture': 'asteroid1',
            'vert_mesh': vert_mesh,
            #'size': (64, 64),
            'render': True},
            'position': pos, 'rotate': 0, 'color': (1., 0., 0., start_alpha),
            'lerp_system': {},
            'scale':start_scale}
        component_order = ['position', 'rotate', 'color',
            'puck_renderer', 'lerp_system','scale']
        eid = self.gameworld.init_entity(create_component_dict,
            component_order)

        systems = self.gameworld.systems
        lerp_system = systems['lerp_system']
        lerp_system.clear_lerps_from_entity(eid)
        lerp_system.add_lerp_to_entity(eid, 'color', 'a', end_alpha, 2.5,
            'float', callback=self.lerp_callback_remove_ent)
        lerp_system.add_lerp_to_entity(eid, 'scale', 's', end_scale, 2.4,
            'float')
        return eid

    def create_paddle(self, pos, color=(1,1,1,0.65)):
        angle = 0 #radians(randint(-360, 360))
        angular_velocity = 0 #radians(randint(-150, -150))
        radius=55
        shape_dict = {'inner_radius': 0, 'outer_radius': radius,
            'mass': 50, 'offset': (0., 0.)}
        col_shape = {'shape_type': 'circle', 'elasticity': .8,
            'collision_type': 6, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        vert_mesh = self.draw_regular_polygon(30, radius, (1., 0., 0., 1.))
        physics_component = {'main_shape': 'circle',
            'velocity': (0,0),
            'position': pos, 'angle': angle,
            'angular_velocity': angular_velocity,
            'vel_limit': 1500.,
            'ang_vel_limit': radians(200),
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'physics': physics_component,
            'puck_renderer': {#'texture': 'asteroid1',
            'vert_mesh': vert_mesh,
            #'size': (64, 64),
            'render': True},
            'position': pos, 'rotate': 0, 'color': color,
            'lerp_system': {},
            'scale':1.}
        component_order = ['position', 'rotate', 'color',
            'physics', 'puck_renderer', 'lerp_system','scale']
        a_paddle_id =  self.gameworld.init_entity(create_component_dict,
            component_order)

        self.paddleIDs.add(a_paddle_id)
        return a_paddle_id

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer', 'puck_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'puck_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    from kivy.utils import platform
    if platform == 'android':pfile='/sdcard/kivocky.prof'
    else:pfile='kivocky.prof'
    import cProfile
    cProfile.run('YourAppNameApp().run()', pfile)
    #YourAppNameApp().run()
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from kivent import GameSystem
from math import pi, cos, sin
import triangle
from numpy import array
from random import random, randint

class BackgroundGenerator(GameSystem):


    def draw_offset_layered_regular_polygon(self, pos, levels, sides, 
        middle_color, radius_color_dict):
        '''
        radius_color_dict = {'level#': (even_r, odd_r), (r,g,b,a))}
        '''
        x, y = pos
        angle = 2 * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        mid = list(pos)
        mid.extend(middle_color)
        all_verts_a(mid)
        r_total_e = 0
        r_total_o = 0
        i = 0
        triangles = []
        vert_count = 1
        tri_count = 0
        tri_a = triangles.append 
        for count in range(levels):
            level = i + 1
            rs, color = radius_color_dict[level]
            even_r, odd_r = rs
            for s in range(sides):
                r = odd_r if not s % 2 else even_r
                r_total = r_total_o if not s % 2 else r_total_e
                new_pos = list((x + (r + r_total) * sin(s * angle), 
                    y + (r + r_total) * cos(s * angle)))
                new_pos.extend(color)
                all_verts_a(new_pos)
                vert_count += 1
            r_total_e += even_r
            r_total_o += odd_r
            c = 1 #side number we are on in loop
            if level == 1:
                for each in range(sides):
                    if c < sides:
                        tri_a((c, 0, c+1))
                    else:
                        tri_a((c, 0, 1))
                    tri_count += 1
                    c += 1
            else:
                for each in range(sides):
                    offset = sides*(i-1)
                    if c < sides:
                        tri_a((c+sides+offset, c+sides+1+offset, c+offset))
                        tri_a((c+offset, c+1+offset, c+sides+1+offset))
                    else:
                        tri_a((c+sides+offset, sides+1+offset, sides+offset))
                        tri_a((sides+offset, 1+offset, sides+1+offset))
                    tri_count += 2
                    c += 1
            i += 1
        return {'triangles': triangles, 'vertices': all_verts, 
            'vert_count': vert_count, 'tri_count': tri_count, 
            'vert_data_count': 6}


    def draw_layered_regular_polygon(self, pos, levels, sides, middle_color,
        radius_color_dict):
        '''
        radius_color_dict = {'level#': (r, (r,g,b,a))}
        '''
        x, y = pos
        angle = 2 * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        mid = list(pos)
        mid.extend(middle_color)
        all_verts_a(mid)
        r_total = 0
        i = 0
        triangles = []
        vert_count = 1
        tri_count = 0
        tri_a = triangles.append 
        for count in range(levels):
            level = i + 1
            r, color = radius_color_dict[level]
            for s in range(sides):
                new_pos = list((x + (r + r_total) * sin(s * angle), 
                    y + (r + r_total) * cos(s * angle)))
                new_pos.extend(color)
                all_verts_a(new_pos)
                vert_count += 1
            r_total +=  r
            c = 1 #side number we are on in loop
            if level == 1:
                for each in range(sides):
                    if c < sides:
                        tri_a((c, 0, c+1))
                    else:
                        tri_a((c, 0, 1))
                    tri_count += 1
                    c += 1
            else:
                for each in range(sides):
                    offset = sides*(i-1)
                    if c < sides:
                        tri_a((c+sides+offset, c+sides+1+offset, c+offset))
                        tri_a((c+offset, c+1+offset, c+sides+1+offset))
                    else:
                        tri_a((c+sides+offset, sides+1+offset, sides+offset))
                        tri_a((sides+offset, 1+offset, sides+1+offset))
                    tri_count += 2
                    c += 1
            i += 1
        return {'triangles': triangles, 'vertices': all_verts, 
            'vert_count': vert_count, 'tri_count': tri_count, 
            'vert_data_count': 6}

    def draw_regular_polygon(self, sides, radius, color, pos):
        x, y = pos
        angle = 2 * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        l_pos = list(pos)
        l_pos.extend(color)
        all_verts_a(l_pos)
        triangles = []
        triangles_a = triangles.append
        r = radius
        for s in range(sides):
            new_pos = x + r * sin(s * angle), y + r * cos(s * angle)
            l_pos = list(new_pos)
            l_pos.extend(color)
            all_verts_a(l_pos)
            if s == sides-1:
                triangles_a((s+1, 0, 1))
            else:
                triangles_a((s+1, 0, s+2))
        return {'triangles': triangles, 'vertices': all_verts, 
            'vert_count': (sides+1), 'tri_count': sides, 'vert_data_count': 6}

    def draw_triangulated_rectangle(self, width, height, pos,
        octaves, persistance, scale, size):
        x, y = pos
        all_verts = [(x, y), (x, y+height), (x+width, y+height), (x+width, y)]
        A = {'vertices':array(all_verts)}
        command = 'cqa' + size
        B = triangle.triangulate(A, command)
        tri_indices = B['triangles']
        new_triangles = []
        new_vertices = []
        tri_verts = B['vertices']
        nv_ap = new_vertices.append
        new_ap = new_triangles.append
        tri_count = 0
        for tri in tri_indices:
            new_ap((tri[0], tri[1], tri[2]))
            tri_count += 1
        vert_count = 0
        for tvert in tri_verts:
            nv_ap([tvert[0], tvert[1], octaves, persistance, scale])
            vert_count += 1
        print vert_count, tri_count
        return {'triangles': new_triangles, 'vertices': new_vertices, 
            'vert_count': vert_count, 'tri_count': tri_count, 
            'vert_data_count': 5}


    def draw_triangulated_regular_polygon(self, sides, radius, pos,
        octaves, persistance, scale, size):
        x, y = pos
        angle = 2 * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        r = radius
        for s in range(sides):
            new_pos = x + r * sin(s * angle), y + r * cos(s * angle)
            all_verts_a(new_pos)
        A = {'vertices':array(all_verts)}
        command = 'cqa' + size + 'YY'
        B = triangle.triangulate(A, command)
        tri_indices = B['triangles']
        new_triangles = []
        new_vertices = []
        tri_verts = B['vertices']
        nv_ap = new_vertices.append
        new_ap = new_triangles.append
        tri_count = 0
        for tri in tri_indices:
            new_ap((tri[0], tri[1], tri[2]))
            tri_count += 1
        vert_count = 0
        for tvert in tri_verts:
            nv_ap([tvert[0], tvert[1], octaves, persistance, scale])
            vert_count += 1
        return {'triangles': new_triangles, 'vertices': new_vertices, 
            'vert_count': vert_count, 'tri_count': tri_count, 
            'vert_data_count': 5}


    def draw_offset_regular_polygon(self, sides, odd_r, even_r, color, pos):
        x, y = pos
        angle = 2 * pi / sides
        all_verts = []
        all_verts_a = all_verts.append
        l_pos = list(pos)
        l_pos.extend(color)
        all_verts_a(l_pos)
        triangles = []
        triangles_a = triangles.append
        for s in range(sides):
            r = odd_r if not s % 2 else even_r
            new_pos = x + r * sin(s * angle), y + r * cos(s * angle)
            l_pos = list(new_pos)
            l_pos.extend(color)
            all_verts_a(l_pos)
            if s == sides-1:
                triangles_a((s+1, 0, 1))
            else:
                triangles_a((s+1, 0, s+2))
        return {'triangles': triangles, 'vertices': all_verts, 
            'vert_count': (sides+1), 'tri_count': sides, 'vert_data_count': 6}



class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        self.setup_map()
        self.setup_states()
        self.set_state()
        self.draw_some_stuff()
        Clock.schedule_interval(self.update, 0)


    def draw_a_blue_star(self, background_system):
        pos = random()*1920., random()*1080.
        levels = 3
        sides = 8
        middle_color = (1., 1., 1., 1.)
        radius_color_dict = {
            1: ((random()*5., random()*5.), (223./255., 253./255., 245./255., 1.0)),
            2: ((random()*2., random()*2.), (87./255., 253./255., 232./255., 1.)),
            3.: ((4., 4.), (87./255., 253./255., 232./255., 0.)),}
        create_dict = background_system.draw_offset_layered_regular_polygon(pos, 
            levels, sides, middle_color, radius_color_dict)
        self.gameworld.init_entity({'renderer': create_dict}, ['renderer'])


    def draw_diamond_star(self, background_system):
        pos = random()*1920., random()*1080.
        levels = 2
        sides = 4
        middle_color = (1., 1., 1., 1.)
        radius_color_dict = {
            1: (random()*8., (0.866666667, 0.443137255, 0.235294118, 1.0)),
            2: (random()*4., (0.866666667, 0.8, 0.9, 0.)),}
        create_dict = background_system.draw_layered_regular_polygon(pos, 
            levels, sides, middle_color, radius_color_dict)
        self.gameworld.init_entity({'renderer': create_dict}, ['renderer'])

    def draw_a_star(self, background_system):
        pos = random()*1920., random()*1080.
        levels = 2
        sides = randint(8, 16)
        middle_color = (1., 1., 1., 1.)
        radius_color_dict = {
            1: ((random()*4., random()*2.), (0.866666667, 0.443137255, 0.235294118, 1.0)),
            2: ((random()*5., random()*2.), (0.866666667, 0.8, 0.9, 0.)),}
        create_dict = background_system.draw_offset_layered_regular_polygon(pos, 
            levels, sides, middle_color, radius_color_dict)
        self.gameworld.init_entity({'renderer': create_dict}, ['renderer'])


    def draw_some_stuff(self):
        background_system = self.gameworld.systems['backgrounds']
        for x in range(100):
            self.draw_a_star(background_system)
        for x in range(25):
            self.draw_diamond_star(background_system)
        for x in range(75):
            self.draw_a_blue_star(background_system)
        create_dict = background_system.draw_triangulated_rectangle(
            1920., 1080., (0., 0.), 4, .5, .0003, '100')
        create_dict['do_texture'] = True
        create_dict['texture'] = 'assets/planetgradient3.png'
        self.gameworld.init_entity({'noise_renderer': create_dict}, 
            ['noise_renderer'])
        for x in range(40):
            self.draw_a_star(background_system)
        for x in range(10):
            self.draw_diamond_star(background_system)

        pos = (150, 150)
        levels = 2
        sides = 20
        middle_color = (1., 1., 1., 1.)
        radius_color_dict = {
            1: (100, (0.866666667, 0.443137255, 0.235294118, 1.0)),
            2: (10, (0.866666667, 0.8, 0.9, 0.)),}
        create_dict = background_system.draw_layered_regular_polygon(pos, 
            levels, sides, middle_color, radius_color_dict)
        self.gameworld.init_entity({'renderer2': create_dict}, ['renderer2'])
        create_dict = background_system.draw_triangulated_regular_polygon(
            20, 100, (150, 150), 6, .5, .001, '75')
        create_dict['do_texture'] = True
        create_dict['texture'] = 'assets/planetgradient.png'
        self.gameworld.init_entity({'noise_renderer2': create_dict}, 
            ['noise_renderer2'])
        create_dict = background_system.draw_triangulated_regular_polygon(
            20, 100, (150, 150), 3, .5, .005, '150')
        create_dict['do_texture'] = True
        create_dict['texture'] = 'assets/planetgradient2.png'
        self.gameworld.init_entity({'noise_renderer2': create_dict}, 
            ['noise_renderer2'])


        pos = (800, 550)
        levels = 2
        sides = 30
        middle_color = (1., 1., 1., 1.)
        radius_color_dict = {
            1: (300, (127./255., 194./255., 21./255., 1.0)),
            2: (25, (255./255., 255./255., 255./255., 0.)),}
        create_dict = background_system.draw_layered_regular_polygon(pos, 
            levels, sides, middle_color, radius_color_dict)
        self.gameworld.init_entity({'renderer2': create_dict}, ['renderer2'])
        create_dict = background_system.draw_triangulated_regular_polygon(
            30, 300, pos, 4, .2, .001, '100')
        create_dict['do_texture'] = True
        create_dict['texture'] = 'assets/planetgradient4.png'
        self.gameworld.init_entity({'noise_renderer2': create_dict}, 
            ['noise_renderer2'])
        create_dict = background_system.draw_triangulated_regular_polygon(
            20, 300, pos, 2, .5, .005, '150')
        create_dict['do_texture'] = True
        create_dict['texture'] = 'assets/planetgradient5.png'
        self.gameworld.init_entity({'noise_renderer2': create_dict}, 
            ['noise_renderer2'])



    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer', 'noise_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'noise_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()

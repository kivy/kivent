from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from kivent_core.systems.gamesystem import GameSystem
from kivent_polygen.renderers import ColorPolyRenderer
from math import pi, cos, sin
from kivy.properties import StringProperty
from random import random, randint, choice, random, uniform, randrange, sample
from kivent_core.rendering.model import VertexModel
from kivent_noise.noise import (
    py_scaled_octave_noise_2d as scaled_octave_noise_2d)
from bisect import bisect_left, bisect_right
# from generate_triangulated_polygons import triangulate_regular_polygon


color_palettes = {
    'violot': {
        1: (246, 225, 255),
        2: (235, 192, 253),
        3: (173, 0, 242),
        4: (111, 42, 124),
        5: (28, 19, 27),
    },
    'indigo': {
        1: (233, 225, 255),
        2: (200, 181, 252),
        3: (89, 29, 255),
        4: (72, 49, 142),
        5: (32, 29, 41),
    },
    'blue': {
        1: (225, 241, 255),
        2: (190, 223, 253),
        3: (43, 153, 255),
        4: (49, 87, 135),
        5: (28, 32, 40),
    },
    'aqua': {
        1: (225, 255, 249),
        2: (190, 254, 243),
        3: (0, 221, 176),
        4: (30, 91, 78),
        5: (21, 30, 28),
    },
    'green': {
        1: (233, 255, 225),
        2: (214, 254, 188),
        3: (93, 226, 0),
        4: (76, 116, 33),
        5: (34, 41, 29),
    },
    'yellow': {
        1: (252, 255, 225),
        2: (249, 254, 186),
        3: (223, 251, 63),
        4: (155, 147, 41),
        5: (41, 44, 20),
    },
    'orange': {
        1: (255, 239, 225),
        2: (253, 220, 189),
        3: (255, 123, 8),
        4: (149, 65, 42),
        5: (58, 29, 22),
    },
}

color_choices = [key for key in color_palettes]
sun_choices = ['orange', 'yellow', 'aqua', 'blue']

def gen_star_color_levels(color):
    color_palette = color_palettes[color]
    color0 = list(color_palette[1])
    color0.append(255)
    color1 = list(color_palette[2])
    color1.append(255)
    color2 = list(color_palette[3])
    color2.append(255)

    return {0: color0, 1: color1, 2: color2, 3: (color2[0], color2[1], 
        color2[3], 0)}

def gen_color_palette(divisions, color1, color2, max_step, color_swaps, 
    do_alpha=False, alpha_low_cutoff=0., alpha_high_cutoff=1., 
    alpha_range=(100, 200), level_choices=[1, 2, 3, 4, 5]):
    current_point = 0.
    palette = []
    pal_a = palette.append
    swap_every = divisions // color_swaps
    swap_count = 0
    current_color = color1
    current_level = 5
    direction_choices = [0, 1, 1]
    direction = 0
    for x in range(divisions):
        color = list(color_palettes[current_color][current_level])
        if do_alpha:
            if current_point < alpha_low_cutoff or (
            current_point > alpha_high_cutoff):
                alpha_v = 0
            else:
                alpha_v = randrange(alpha_range[0], alpha_range[1])
            color.append(alpha_v)
        pal_a((current_point, color))
        current_point = uniform(current_point + max_step/2., 
            current_point + max_step)
        if x == divisions - 2:
            current_point = 1.
        if current_point > 1.:
            current_point == 1.
        last_level = current_level
        while current_level == last_level:
            current_level = choice(level_choices)
        swap_count += 1
        if swap_count >= swap_every:
            swap_count = 0
            if current_color == color1:
                current_color = color2
            else:
                current_color = color1
    return palette

def lerp(v0, v1, t):
    return (1-t)*v0 + t * v1

def lerp_color(col_1, col_2, d):
    return [lerp(c1, c2, d) for c1, c2 in zip(col_1, col_2)]

class PlanetModel(object):

    def __init__(self, name, radius, cloud_name):
        self.radius = radius 
        self.name = name
        self.cloud_name = cloud_name


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        self.planet_register = {}
        self.gameworld.init_gameworld(
            ['back_stars', 'mid_stars', 'position', 'sun1', 'sun2',
            'camera_stars1', 'camera_stars2', 'map', 'planet1', 'planet2',
            'camera_sun1', 'camera_sun2', 'camera_planet1', 'camera_planet2'],
            callback=self.init_game)

    def test_triangulate_polygon(self, sides, radius, area, name):
        t = triangulate_regular_polygon(sides,radius, (0., 0.), area)
        print(sides, radius, area, t['ind_count'], t['vert_count'])
        model_manager = self.gameworld.model_manager
        model_name = model_manager.load_model('vertex_format_2f4ub', 
            t['vert_count'], t['ind_count'], name, 
            indices=t['indices'], vertices=t['vertices'])
        
        return model_name

    def generate_and_save_various_models(self, radii=[], areas=[], sides=40):
        model_manager = self.gameworld.model_manager
        for radius in radii:
            for area in areas:
                name = 'circle_' + str(int(radius)) + '_' + area
                model_name = self.test_triangulate_polygon(sides, radius, 
                    area, name)
                model_manager.pickle_model(model_name, 'triangulated_models')

    def pregenerate_models(self):
        self.generate_and_save_various_models(radii=[100., 200.,],
            areas=['5', '10', '20'])
        self.generate_and_save_various_models(radii=[400.], 
            areas=['10', '20', '30'], sides=60)
        self.generate_and_save_various_models(radii=[800.], 
            areas=['25', '35', '50'], sides=100)

    def populate_model_with_noise(self, model_name, octaves, 
        persistence, scale, offset, radius, colors, transparent_level = 0.,
        default_alpha = 255):
        model_manager = self.gameworld.model_manager
        model = model_manager.models[model_name]
        vertices = model.vertices
        r2 = radius*radius
        ox, oy = offset
        col_keys = [x[0] for x in colors]
        def distance_from_center(pos, center=(0.,0.)):
            x_dist = pos[0] - center[0]
            y_dist = pos[1] - center[1]
            return x_dist*x_dist + y_dist*y_dist
        for vertex in vertices:
            pos = x,y = vertex.pos
            if distance_from_center(pos) > r2:
                zcolor = colors[0][1]
                vertex.v_color = [zcolor[0], zcolor[1], zcolor[2], 0]
            else:
                noise = scaled_octave_noise_2d(octaves, persistence, scale, 0., 
                    1., x+ox, y+oy)
                col_bisect = bisect_left(col_keys, noise)
                left = colors[col_bisect-1]
                right = colors[col_bisect]
                t = (noise - left[0]) / (right[0] - left[0])
                new_color = lerp_color(left[1], right[1], t)
                if len(new_color) == 3:
                    new_color.append(default_alpha)
                if noise < transparent_level:
                    new_color[3] = 0
                vertex.v_color = new_color

    def draw_sun(self, model_name, color_choice, radius):
        divisions = randint(6, 12)
        even_div = 1.0 / divisions
        colors = gen_color_palette(divisions, color_choice, 
            color_choice, uniform(even_div, 2*even_div), randint(1, 6),
            level_choices=[1, 1, 1, 1, 1, 1, 2, 3])
        self.populate_model_with_noise(model_name, 16, uniform(.5, .9),
            uniform(.03, .05), (uniform(radius, 10000.), 
            uniform(radius, 10000.)), radius, colors)

    def draw_offset_layered_regular_polygon(self, pos, levels, sides, 
        middle_color, radius_color_dict):
        '''
        radius_color_dict = {'level#': (even_r, odd_r), (r,g,b,a))}
        '''
        x, y = pos
        angle = 2 * pi / sides
        all_verts = {}
        all_verts[0] = {'pos': pos, 'v_color': middle_color}
        r_total_e = 0
        r_total_o = 0
        i = 0
        indices = []
        vert_count = 1
        ind_count = 0
        ind_a = indices.extend
        for count in range(levels):
            level = i + 1
            rs, color = radius_color_dict[level]
            even_r, odd_r = rs
            for s in range(sides):
                r = odd_r if not s % 2 else even_r
                r_total = r_total_o if not s % 2 else r_total_e
                new_pos = list((x + (r + r_total) * sin(s * angle), 
                    y + (r + r_total) * cos(s * angle)))
                all_verts[vert_count] = {'pos': new_pos, 'v_color': color}
                vert_count += 1
            r_total_e += even_r
            r_total_o += odd_r
            c = 1 #side number we are on in loop
            if level == 1:
                for each in range(sides):
                    if c < sides:
                        ind_a((c, 0, c+1))
                    else:
                        ind_a((c, 0, 1))
                    ind_count += 3
                    c += 1
            else:
                for each in range(sides):
                    offset = sides*(i-1)
                    if c < sides:
                        ind_a((c+sides+offset, c+sides+1+offset, c+offset))
                        ind_a((c+offset, c+1+offset, c+sides+1+offset))
                    else:
                        ind_a((c+sides+offset, sides+1+offset, sides+offset))
                        ind_a((sides+offset, 1+offset, sides+1+offset))
                    ind_count += 6
                    c += 1
            i += 1
        return {'indices': indices, 'vertices': all_verts, 
            'vert_count': vert_count, 'ind_count': ind_count}

    def draw_layered_regular_polygon(self, pos, levels, sides, middle_color,
        radius_color_dict):
        '''
        radius_color_dict = {level#: (r, (r,g,b,a))}
        '''
        x, y = pos
        angle = 2 * pi / sides
        all_verts = {}
        all_verts[0] = {'pos': pos, 'v_color': middle_color}
        r_total = 0
        i = 0
        indices = []
        vert_count = 1
        ind_count = 0
        ind_e = indices.extend 
        for count in range(levels):
            level = i + 1
            r, color = radius_color_dict[level]
            for s in range(sides):
                new_pos = list((x + (r + r_total) * sin(s * angle), 
                    y + (r + r_total) * cos(s * angle)))
                all_verts[vert_count] = {'pos': new_pos, 'v_color': color}
                vert_count += 1
            r_total +=  r
            c = 1 #side number we are on in loop
            if level == 1:
                for each in range(sides):
                    if c < sides:
                        ind_e((c, 0, c+1))
                    else:
                        ind_e((c, 0, 1))
                    ind_count += 3
                    c += 1
            else:
                for each in range(sides):
                    offset = sides*(i-1)
                    if c < sides:
                        ind_e((c+sides+offset, c+sides+1+offset, c+offset))
                        ind_e((c+offset, c+1+offset, c+sides+1+offset))
                    else:
                        ind_e((c+sides+offset, sides+1+offset, sides+offset))
                        ind_e((sides+offset, 1+offset, sides+1+offset))
                    ind_count += 6
                    c += 1
            i += 1
        return {'indices': indices, 'vertices': all_verts, 
            'vert_count': vert_count, 'ind_count': ind_count}

    def generate_star(self, model_name, sides, color, max_radius, 
        do_copy=False):
        colors = gen_star_color_levels(color)
        first_r = uniform(.5, .9)
        final_r = uniform(.01, .1)
        total = first_r + final_r
        remainder = 1.0 - total
        middle_r = uniform(final_r, final_r+remainder)
        radius_color_dict = {
            1: (max_radius*first_r, colors[1]),
            2: (max_radius*middle_r, colors[2]),
            3: (max_radius*final_r, colors[3])}
        star_data = self.draw_layered_regular_polygon((0., 0.), 3, sides, 
            colors[0], radius_color_dict)
        model_manager = self.gameworld.model_manager
        return model_manager.load_model('vertex_format_2f4ub', 
            star_data['vert_count'], star_data['ind_count'], model_name, 
            indices=star_data['indices'], vertices=star_data['vertices'],
            do_copy=do_copy)

    def generate_offset_star(self, model_name, sides, color, max_radius_1, 
        max_radius_2, do_copy=False):
        colors = gen_star_color_levels(color)
        first_r = uniform(.5, .9)
        final_r = uniform(.01, .1)
        total = first_r + final_r
        remainder = 1.0 - total
        middle_r = uniform(final_r, final_r+remainder)
        radius_color_dict = {
            1: ((max_radius_1*first_r, max_radius_2*first_r), colors[1]),
            2: ((max_radius_1*middle_r, max_radius_2*first_r), colors[2]),
            3: ((max_radius_1*final_r, max_radius_2*final_r), colors[3])}
        star_data = self.draw_offset_layered_regular_polygon((0., 0.), 3, sides, 
            colors[0], radius_color_dict)
        model_manager = self.gameworld.model_manager
        return model_manager.load_model('vertex_format_2f4ub', 
            star_data['vert_count'], star_data['ind_count'], model_name, 
            indices=star_data['indices'], vertices=star_data['vertices'],
            do_copy=do_copy)

    def draw_planet(self, model_name, cloud_name, radius, color1, color2):
        divisions = randint(6, 12)
        even_div = 1.0 / divisions
        colors = gen_color_palette(divisions, color1, 
            color2, uniform(even_div, 2*even_div), randint(1, 4),
            level_choices=[2, 3, 4, 4, 5, 5])
        self.populate_model_with_noise(model_name, 16, uniform(.3, .7),
            uniform(.004, .009), 
            (uniform(radius, radius*4), uniform(radius, radius*4)), 
            radius, colors)
        divisions = randint(4, 6)
        even_div = 1.0 / divisions
        colors = gen_color_palette(divisions, color1, 
            color2, uniform(even_div, 2*even_div), 1,
            level_choices=[1, 2, 2, 3, 4, 5], do_alpha=True, 
            alpha_low_cutoff=uniform(.2, .5), 
            alpha_high_cutoff=uniform(.6, .9),
            alpha_range=(0, 200))
        self.populate_model_with_noise(cloud_name, 8, uniform(.2, .4),
            uniform(.001, .004), 
            (uniform(radius, radius*4), uniform(radius, radius*4)), 
            radius, colors)

    def generate_planets(self, starting_radius, min_s, max_s, count, model_name,
        model_file):
        min_scale = min_s/starting_radius
        max_scale = max_s/starting_radius
        model_manager = self.gameworld.model_manager
        model_from_file_name = model_manager.load_model_from_pickle(model_file, 
            model_name=model_name)
        copy_model = model_manager.copy_model
        models = model_manager.models
        cloud_name = model_from_file_name + '_clouds'
        copy_model(model_from_file_name, model_name=cloud_name)
        names = [model_from_file_name]
        names_a = names.append
        planet_register = self.planet_register
        planet_register[model_from_file_name] = PlanetModel(
            model_from_file_name, starting_radius, cloud_name)
        for x in range(count-1):
            scale_factor = uniform(min_scale, max_scale)
            new_name = copy_model(model_from_file_name)
            names_a(new_name)
            model = models[new_name]
            cloud_name = new_name + '_clouds'
            planet_register[new_name] = PlanetModel(new_name, 
                scale_factor*starting_radius, cloud_name)
            model.mult_all_vertex_attribute('pos', scale_factor)
            copy_model(new_name, model_name=cloud_name)
        return names

    def generate_stars(self, min_radius, max_radius, max_offset_radius, 
        color_choices, four_side_count, offset_count, normal_count, min_sides, 
        max_sides):
        stars = {}
        for color in color_choices:
            stars[color] = c_stars = []
            c_stars_a = c_stars.append
            for x in range(four_side_count):
                model_name = 'star_4_' + str(x)
                radius = uniform(min_radius, max_radius)
                c_stars_a(self.generate_star(model_name, 4, color, 
                    radius, do_copy=True))
            for x in range(normal_count):
                side_count = randrange(min_sides, max_sides)
                if side_count % 2 == 1:
                    side_count += 1
                model_name = 'star_' + str(side_count) + '_' + str(x)
                radius = uniform(min_radius, max_radius)
                c_stars_a(self.generate_star(model_name, side_count, color, 
                    radius, do_copy=True))
            for x in range(offset_count):
                side_count = randrange(min_sides, max_sides)
                if side_count % 2 == 1:
                    side_count += 1
                model_name = 'star_' + str(side_count) + '_' + str(x)
                radius1 = uniform(min_radius, max_radius)
                radius2 = uniform(min_radius, max_offset_radius)
                c_stars_a(self.generate_offset_star(model_name, side_count, 
                    color, radius1, radius2, do_copy=True))
        return stars


    def draw_map(self, size, offset, star_count, color1, color2, 
        star_renderer=None,
        planet_renderer=None,
        sun_renderer=None,
        do_stars=True,
        max_color1_chance=.5, max_color2_chance=.25, 
        small_p_counts=[1, 1, 2, 0, 0, 0],
        medium_small_p_counts=[1, 2, 0, 0, 0, 0], 
        medium_large_p_counts=[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
        large_p_counts=[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        small_sun_counts = [1, 0, 0, 0, 0],
        medium_small_sun_counts = [1, 0, 0, 0, 0, 0],
        medium_large_sun_counts = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        large_sun_counts = [0],
        persistence=.3,
        octaves=8,
        scale=.003,
        used_planet_names=None):
        w, h = size
        ox, oy = offset
        if used_planet_names is None:
            used_planet_names = []
        star1_chance = uniform(0, max_color1_chance)
        star2_chance = uniform(0, max_color2_chance)
        star_choices = self.star_names
        star1_choices = star_choices[color1]
        star2_choices = star_choices[color2]
        init_entity = self.gameworld.init_entity
        ent_count = 0
        planet_choices = self.planet_names
        if star_renderer is not None:
            for i in range(star_count):
                chance = random()
                star_name = None
                if 0 < chance < star1_chance:
                    star_name = choice(star1_choices)

                elif star1_chance < chance < star1_chance + star2_chance:
                    star_name = choice(star2_choices)
                if star_name is not None:
                    create_dict = {
                        'position': (uniform(0., w), uniform(0, h)),
                        star_renderer: {'model_key': star_name}
                    }
                    init_entity(create_dict, ['position', star_renderer])
        planet_register = self.planet_register
        if planet_renderer is not None:
            choice_pairs = [
                (small_p_counts, planet_choices['small_planets']), 
                (medium_small_p_counts, planet_choices['medium_small_planets']),
                (medium_large_p_counts, planet_choices['medium_large_planets']),
                (large_p_counts, planet_choices['large_planets'])
                ]
            for counts, choices in choice_pairs:
                for planet_name in sample(choices, choice(counts)):
                    if planet_name in used_planet_names:
                        continue
                    used_planet_names.append(planet_name)
                    planet_data = planet_register[planet_name]
                    self.draw_planet(planet_name, planet_data.cloud_name, 
                        planet_data.radius+50., choice(color_choices), 
                        choice(color_choices))
                    planet_pos = (uniform(0., w), uniform(0, h))
                    create_dict = {
                        'position': planet_pos,
                            planet_renderer: {'model_key': planet_name}
                    }
                    self.gameworld.init_entity(create_dict, ['position', 
                        planet_renderer])
                    create_dict = {
                        'position': planet_pos,
                        planet_renderer: {'model_key': planet_data.cloud_name}
                    }
                    self.gameworld.init_entity(create_dict, ['position', 
                        planet_renderer])
        if sun_renderer is not None:
            choice_pairs = [
                (small_sun_counts, planet_choices['small_planets']), 
                (medium_small_sun_counts, 
                    planet_choices['medium_small_planets']),
                (medium_large_sun_counts, 
                    planet_choices['medium_large_planets']),
                (large_sun_counts, planet_choices['large_planets'])
                ]
            for counts, choices in choice_pairs:
                for planet_name in sample(choices, choice(counts)):
                    if planet_name in used_planet_names:
                        continue
                    used_planet_names.append(planet_name)
                    planet_data = planet_register[planet_name]
                    self.draw_sun(planet_name, choice([color1, color2]), 
                        planet_data.radius - 10.)
                    planet_pos = (uniform(0., w), uniform(0, h))
                    create_dict = {
                        'position': planet_pos,
                        sun_renderer: {'model_key': planet_name}
                    }
                    self.gameworld.init_entity(create_dict, ['position', 
                        sun_renderer])
        return used_planet_names

    def redraw_map(self):
        self.gameworld.clear_entities()
        color1 = choice(sun_choices)
        color2 = choice(sun_choices)
        self.draw_map((2500, 2500), (randrange(0, 50000), randrange(0, 50000)),
            randrange(1000, 3000), color1, color2, 
            star_renderer='back_stars')
        used = self.draw_map((2500, 2500), (randrange(0, 50000), 
            randrange(0, 50000)), randrange(1000, 3000), color1, color2, 
            star_renderer='mid_stars')
        used = self.draw_map((2500, 2500), (randrange(0, 50000), 
            randrange(0, 50000)), randrange(1000, 3000), color1, color2, 
            sun_renderer='sun1', used_planet_names=used,
            small_sun_counts = [1, 0, 0, 0, 0],
            medium_small_sun_counts = [1, 0, 0, 0, 0, 0],
            medium_large_sun_counts = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            large_sun_counts = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],)
        used = self.draw_map((2500, 2500), (randrange(0, 50000), 
            randrange(0, 50000)), randrange(1000, 3000), color1, color2, 
            sun_renderer='sun2', used_planet_names=used)
        used = self.draw_map((2500, 2500), (randrange(0, 50000), 
            randrange(0, 50000)),
            0, color1, color2, planet_renderer='planet1', 
            small_p_counts=[1, 1, 2, 0, 0, 0],
            medium_small_p_counts=[1, 2, 0, 0, 0, 0], 
            medium_large_p_counts=[0], 
            large_p_counts=[0],
            used_planet_names=used)
        used = self.draw_map((2500, 2500), (randrange(0, 50000), 
            randrange(0, 50000)),
            0, color1, color2, planet_renderer='planet2', 
            used_planet_names=used)
            
            
    def init_game(self):
        self.setup_states()
        self.set_state()
        star_names = self.generate_stars(1., 4., 5., sun_choices, 20, 10, 10, 
            20, 30)
        self.star_names = star_names
        self.planet_names = planet_names = {}
        small_planets = self.generate_planets(100., 100., 100., 10, 
            'small_planet','triangulated_models/circle_100_10.kem')
        planet_names['small_planets'] = small_planets
        medium_small_planets = self.generate_planets(200., 175., 350., 5,
            'medium_small_planet', 'triangulated_models/circle_200_10.kem')
        planet_names['medium_small_planets'] = medium_small_planets
        medium_large_planets = self.generate_planets(400., 375., 600., 5,
            'medium_large_planet', 'triangulated_models/circle_400_30.kem')
        planet_names['medium_large_planets'] = medium_large_planets
        large_planets = self.generate_planets(800., 650., 850., 5, 
            'large_planet', 'triangulated_models/circle_800_50.kem')
        planet_names['large_planets'] = large_planets
        self.redraw_map()
        
    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['back_stars', 'mid_stars', 'sun1', 'sun2',
                'planet1', 'planet2'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['back_stars', 'mid_stars', 'sun1', 'sun2',
                'planet1', 'planet2'],
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
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()

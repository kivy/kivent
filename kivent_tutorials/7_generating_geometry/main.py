from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from kivent import GameSystem
from math import pi, cos, sin



class BackgroundGenerator(GameSystem):

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
        print triangles, all_verts
        return {'triangles': triangles, 'vertices': all_verts, 
            'vert_count': (sides+1), 'tri_count': sides, 'vert_data_count': 6}


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
        print triangles, all_verts
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

    def draw_some_stuff(self):
        background_system = self.gameworld.systems['backgrounds']
        create_dict = background_system.draw_regular_polygon(4, 50, 
            [1., 1., 1., 1.], (200, 200))
        ent_id = self.gameworld.init_entity(
            {'renderer': create_dict}, ['renderer'])

        entities = self.gameworld.entities
        ent = entities[ent_id]
        vert_mesh = ent.renderer.vert_mesh
        ent_id2 = self.gameworld.init_entity({'renderer': {'vert_mesh': vert_mesh,
                'vert_count': 5, 'tri_count': 4, 'vert_data_count': 6, 
                'offset': (150, 150)}}, 
                ['renderer'])
        #self.gameworld.remove_entity(ent_id)
        #self.gameworld.remove_entity(ent_id2)

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

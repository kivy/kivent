import kivy
from kivy.app import App
from kivy.uix.widget import Widget
import kivent_core
from kivent_core.rendering.svg_loader import SVG
from kivy.properties import NumericProperty


class TestGame(Widget):
    entity_id = NumericProperty(None)

    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        self.uuids = {}
        self.gameworld.init_gameworld(
            ['position', 'poly_renderer'],
            callback=self.init_game)
        

    def init_game(self):
        self.setup_states()
        self.set_state()
        self.load_svg()

    def on_touch_move(self, touch):
        if self.entity_id is not None:
            entity = self.gameworld.entities[self.entity_id]
            position = entity.position
            position.x += touch.dx
            position.y += touch.dy

    def print_model_data(self, model_key):
        model = self.gameworld.model_manager.models[model_key]
        for vertex in model.vertices:
            print(vertex.pos, vertex.v_color)



    def load_svg(self):
        data = self.gameworld.model_manager.load_svg("tiger.svg")
        # print(data)
        init_entity = self.gameworld.init_entity
        model_data = data['models']
        uuids = self.uuids
        entity_to_copy = None
        uuid_index = data['uuid_index']
        for element_key in model_data:
            model_name = model_data[element_key]
            # self.print_model_data(model_name)
            create_dict = {
                'position': (0, 0),
                'poly_renderer': {'model_key': model_name},
            }
            if entity_to_copy is not None:
                create_dict['position'] = entity_to_copy
            ent = init_entity(create_dict, ['position', 'poly_renderer'])
            if entity_to_copy is None:
                entity_to_copy = self.gameworld.entities[ent]
                self.entity_id = ent
            if element_key in uuid_index:
                uuids[uuid_index[element_key]] = ent
        for each in uuids:
            entity = self.gameworld.entities[uuids[each]]
            model = entity.poly_renderer.model
            model.set_all_vertex_attribute('v_color', [255, 0, 0, 255])


    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=[],
            systems_removed=[], systems_paused=[],
            systems_unpaused=[],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        pass


if __name__ == '__main__':
    YourAppNameApp().run()

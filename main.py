import kivy
kivy.require('1.6.0')

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import StringProperty, ListProperty, NumericProperty, DictProperty, BooleanProperty
import random
from kivy.core.image import Image as CoreImage
from kivy.clock import Clock
from kivy.graphics import PushMatrix, PopMatrix, Translate, Quad, Instruction


class GameWorld(Widget):
    state = StringProperty('initial')
    camera_pos = ListProperty((0, 0))
    number_entities = NumericProperty(0)
    systems = DictProperty({})
    num_children = NumericProperty(0)

    def __init__(self, **kwargs):
        super(GameWorld, self).__init__(**kwargs)
        self.entities = []
        self.deactivated_entities = []
        Clock.schedule_once(self.test_entity, 2.0)
        Clock.schedule_once(self.test_remove_entity, 2.5)
        Clock.schedule_once(self.test_entity, 3.0)

    def test_entity(self, dt):
        self.init_entity(('position', 'position_renderer'))

    def test_remove_entity(self, dt):
        self.remove_entity(0)

    def create_entity(self):
        entity = {'id': self.number_entities}
        self.entities.append(entity)
        self.number_entities += 1
        return entity['id']

    def init_entity(self, components_to_use):
        if self.deactivated_entities == []:
            entity_id = self.create_entity()
        else:
            entity_id = self.deactivated_entities.pop()
        for component in components_to_use:
            self.systems[component].create_component(entity_id)
        
    def remove_entity(self, entity_id):
        entity = self.entities[entity_id]
        components_to_delete = []
        for data in entity:
            if data == 'id':
                pass
            else:
                components_to_delete.append(data)
                self.systems[data].remove_entity(entity_id)
        for component in components_to_delete:
            del self.entities[entity_id][component]
        self.deactivated_entities.append(entity_id)

    def load_entity(self, entity_dict):
        pass

    def save_entity(self, entity):
        entity_dict = {}
        return entity_dict

    def clear_entities(self):
        pass

    def remove_system(self, system_id):
        self.systems[system_id].on_delete_system()
        self.remove_widget(self.systems[system_id])
        del self.systems[system_id]

    def add_widget(self, widget):
        super(GameWorld, self).add_widget(widget)
        if isinstance(widget, GameSystem):
            if widget.system_id not in self.systems:
                self.systems[widget.system_id] = widget
                widget.on_init_system()
            widget.on_add_system()

    def remove_widget(self, widget):
        super(GameWorld, self).remove_widget(widget)
        widget.on_remove_system()

class GameSystem(Widget):
    system_id = StringProperty('default_id')
    updateable = BooleanProperty(False)
    update_time = NumericProperty(0.0)

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self.entity_ids = list()

    def update(self, dt):
        pass

    def create_component(self, entity_id):
        pass

    def save_component(self, entity_id):
        entity_component_dict = {}
        return entity_component_dict

    def load_component(self, entity_component_dict):
        pass

    def remove_entity(self, entity_id):
        print self, 'removing entity'

    def on_init_system(self):
        print self, 'system initialized'

    def on_remove_system(self):
        print self, 'system removed'

    def on_add_system(self):
        print self, 'system added'

    def on_delete_system(self):
        print self, 'deleted system'


class BasicPositionSystem(GameSystem):
    system_id = StringProperty('position')

    def __init__(self, **kwargs):
        super(BasicPositionSystem, self).__init__(**kwargs)

    def generate_component_data(self, entity_component_dict):
        rand_x = random.randint(0, self.width)
        rand_y = random.randint(0, self.height)
        entity_component_dict['x'] = rand_x 
        entity_component_dict['y'] = rand_y

    def create_component(self, entity_id):
        entity = self.parent.entities[entity_id]
        entity[self.system_id] = {'x': 0, 'y': 0}
        self.generate_component_data(entity[self.system_id])
        self.entity_ids.append(entity_id)

class BasicRenderSystem(GameSystem):
    system_id = StringProperty('position_renderer')
    render_information_from = StringProperty('position')

    def __init__(self, **kwargs):
        super(BasicRenderSystem, self).__init__(**kwargs)

    def generate_component_data(self, entity_component_dict):
        entity_component_dict['texture'] = 'star1.png'
        entity_component_dict['render'] = True

    def create_component(self, entity_id):
        entity = self.parent.entities[entity_id]
        entity[self.system_id] = {'texture': None, 'render': False, 'translate': None, 'quad': None}
        self.generate_component_data(entity[self.system_id])
        self.draw_entity(entity)

    def draw_entity(self, entity):
        system_data = entity[self.system_id]
        position = entity[self.render_information_from]
        texture = CoreImage(system_data['texture']).texture
        size = texture.size[0] * .5, texture.size[1] *.5
        with self.canvas:
            PushMatrix()
            system_data['translate'] = Translate()
            system_data['quad'] = Quad(texture = texture, points = (-size[0], -size[1], size[0], -size[1],
                size[0], size[1], -size[0], size[1]))
            system_data['translate'].xy = position['x'], position['y']
            PopMatrix()

    def remove_entity(self, entity_id):
        print 'removing', entity_id
        system_data = self.parent.entities[entity_id][self.system_id]
        for data in system_data:
            if isinstance(system_data[data], Instruction):
                print 'removing instruction', data
                self.canvas.remove(system_data[data])

    def update(self, dt):
        pass

class KivEntApp(App):
    def build(self):
        pass


if __name__ == '__main__':

    KivEntApp().run()
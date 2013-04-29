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
        Clock.schedule_once(self.test_entity, 3.0)
        #Clock.schedule_once(self.test_remove_system, 3.5)
        #Clock.schedule_interval(self.update, .05)
        Clock.schedule_once(self.test_clear_entities, 3.5)

    def test_clear_entities(self, dt):
        self.clear_entities()

    def test_remove_system(self, dt):
        self.remove_system('position_renderer')

    def test_entity(self, dt):
        rand_x = random.randint(0, self.width)
        rand_y = random.randint(0, self.height)
        create_component_dict = {'position': {'x': rand_x, 'y': rand_y}, 'position_renderer': {'texture': 'star1.png', 'render': True}}
        component_order = ['position', 'position_renderer']
        self.init_entity(create_component_dict, component_order)

    def test_remove_entity(self, dt):
        self.remove_entity(0)

    def create_entity(self):
        entity = {'id': self.number_entities}
        self.entities.append(entity)
        self.number_entities += 1
        return entity['id']

    def init_entity(self, components_to_use, component_order):
        if self.deactivated_entities == []:
            entity_id = self.create_entity()
        else:
            entity_id = self.deactivated_entities.pop()
        systems = self.systems
        self.entities[entity_id]['entity_load_order'] = component_order
        for component in component_order:
            systems[component].create_component(entity_id, components_to_use[component])
        print self.entities[entity_id]
        
    def remove_entity(self, entity_id):
        entity = self.entities[entity_id]
        components_to_delete = []
        systems = self.systems
        for data in entity:
            if data == 'id':
                pass
            elif data == 'entity_load_order':
                components_to_delete.append(data)
            else:
                components_to_delete.append(data)
                print entity_id
                systems[data].remove_entity(entity_id)
        for component in components_to_delete:
            del entity[component]
        self.deactivated_entities.append(entity_id)

    def update(self, dt):
        systems = self.systems
        for system_name in systems:
            system = systems[system_name]
            if system.updateable:
                system.update(dt)

    def load_entity(self, entity_dict):
        pass

    def save_entity(self, entity):
        entity_dict = {}
        return entity_dict

    def clear_entities(self):
        for entity in self.entities:
            self.remove_entity(entity['id'])

    def remove_system(self, system_id):
        systems = self.systems
        systems[system_id].on_delete_system()
        self.remove_widget(systems[system_id])
        del systems[system_id]

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
    renderable = BooleanProperty(False)

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self.entity_ids = list()

    def update(self, dt):
        pass

    def generate_component_data(self, entity_component_dict):
        return entity_component_dict

    def create_component(self, entity_id, entity_component_dict):
        entity = self.parent.entities[entity_id]
        entity[self.system_id] = self.generate_component_data(entity_component_dict)
        if self.renderable:
            self.draw_entity(entity_id)
        self.entity_ids.append(entity_id)

    def generate_entity_component_dict(self, entity_id):
        entity = self.parent.entities[entity_id]
        return entity[self.system_id]

    def save_component(self, entity_id):
        entity_component_dict = self.generate_entity_component_dict(entity_id)
        return entity_component_dict

    def remove_entity(self, entity_id):
        self.entity_ids.remove(entity_id)

    def on_init_system(self):
        pass

    def on_remove_system(self):
        pass

    def on_add_system(self):
        pass

    def on_delete_system(self):
        pass

class BasicPositionSystem(GameSystem):
    system_id = StringProperty('position')
    def __init__(self, **kwargs):
        super(BasicPositionSystem, self).__init__(**kwargs)

class BasicRenderSystem(GameSystem):
    system_id = StringProperty('position_renderer')
    render_information_from = StringProperty('position')
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)

    def __init__(self, **kwargs):
        super(BasicRenderSystem, self).__init__(**kwargs)

    def generate_component_data(self, entity_component_dict):
        entity_component_dict['translate'] = None
        entity_component_dict['quad'] = None
        return entity_component_dict

    def generate_entity_component_dict(self, entity_id):
        entity = self.parent.entities[entity_id]
        entity_system_dict = entity[self.system_id]
        entity_component_dict = {'texture': entity_system_dict['texture'], 'render': entity_system_dict['render']}
        return entity_component_dict

    def draw_entity(self, entity_id):
        entity = self.parent.entities[entity_id]
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
        system_data = self.parent.entities[entity_id][self.system_id]
        for data in system_data:
            if isinstance(system_data[data], Instruction):
                print 'removing instruction', data
                self.canvas.remove(system_data[data])
        super(BasicRenderSystem, self).remove_entity(entity_id)

class KivEntApp(App):
    def build(self):
        pass


if __name__ == '__main__':

    KivEntApp().run()
import kivy
kivy.require('1.6.0')

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import StringProperty, ListProperty, NumericProperty, DictProperty, BooleanProperty
import random
from kivy.core.image import Image as CoreImage
from kivy.clock import Clock
from kivy.graphics import PushMatrix, PopMatrix, Translate, Quad


class GameWorld(Widget):
    state = StringProperty('initial')
    camera_pos = ListProperty((0, 0))
    number_entities = NumericProperty(0)
    systems = DictProperty({})
    num_children = NumericProperty(0)

    def __init__(self, **kwargs):
        super(GameWorld, self).__init__(**kwargs)
        self.entities = []
        Clock.schedule_once(self.test_remove_system, .5)
        Clock.schedule_once(self.test_add_system, 1.0)
        Clock.schedule_once(self.test_entity, 2.0)


    def test_entity(self, dt):
        print 'creating entity'
        self.create_entity(('position2', 'position_renderer'))

    def test_remove_system(self, dt):
        print 'systems', self.systems
        self.remove_system('position')

    def test_add_system(self, dt):
        self.add_widget(BasicPositionSystem())

    def create_entity(self, components_to_use):
        entity = {'id': self.number_entities}
        self.entities.append(entity)
        for component in components_to_use:
            self.systems[component].create_component(entity['id'])
        self.number_entities += 1

    def load_entity(self, entity_dict):
        pass

    def save_entity(self, entity):
        entity_dict = {}
        return entity_dict

    def remove_entity(self):
        pass

    def clear_entities(self):
        pass

    def on_state(self, instance, value):
        print value
        
    def remove_system(self, system_id):
        self.systems[system_id].on_remove_system()
        self.remove_widget(self.systems[system_id])
        del self.systems[system_id]

    def on_children(self, instance, value):
        new_child = value[0]
        if len(value) > self.num_children:
            self.num_children += 1
            if isinstance(new_child, GameSystem):
                if new_child.system_id not in self.systems:
                    self.systems[new_child.system_id] = new_child
                    new_child.on_add_system()
                else:
                    self.num_children -= 1
                    self.remove_widget(new_child)
                    
        if len(value) < self.num_children:
            self.num_children -= 1


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
        pass

    def on_remove_system(self):
        print self, 'system removed'

    def on_add_system(self):
        print self, 'system added'


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


class BasicPositionSystem2(BasicPositionSystem):
    system_id = StringProperty('position2')

class BasicRenderSystem(GameSystem):
    system_id = StringProperty('position_renderer')
    render_information_from = StringProperty('position2')

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
        system = entity[self.system_id]
        position = entity[self.render_information_from]
        texture = CoreImage(system['texture']).texture
        size = texture.size[0] * .5, texture.size[1] *.5
        with self.canvas:
            PushMatrix()
            system['translate'] = Translate()
            system['quad'] = Quad(texture = texture, points = (-size[0], -size[1], size[0], -size[1],
                size[0], size[1], -size[0], size[1]))
            system['translate'].xy = position['x'], position['y']
            PopMatrix()

    def update(self, dt):
        pass







class KivEntApp(App):
    def build(self):
        pass


if __name__ == '__main__':

    KivEntApp().run()
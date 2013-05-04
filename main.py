import kivy
kivy.require('1.6.0')

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import StringProperty, ListProperty, NumericProperty, DictProperty, BooleanProperty, ObjectProperty
import random
from kivy.core.image import Image as CoreImage
from kivy.clock import Clock
from kivy.graphics import PushMatrix, PopMatrix, Translate, Quad, Instruction, Rotate, Color, Scale
import cymunk
import math
from kivy.uix.screenmanager import ScreenManager, Screen, FadeTransition

class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)

class GameScreenManager(ScreenManager):
    state = StringProperty('initial')

    def __init__(self, **kwargs):
        super(GameScreenManager, self).__init__(**kwargs)
        self.states = {}

    def on_state(self, instance, value):
        self.current = self.states[value]
        


class GameScreen(Screen):
    name = StringProperty('default_screen_id')

class MainMenuScreen(GameScreen):
    name = StringProperty('main_menu')

class MainGameScreen(GameScreen):
    name = StringProperty('main_game')


class GameWorld(Widget):
    state = StringProperty('initial')
    number_entities = NumericProperty(0)
    systems = DictProperty({})
    map_size = ListProperty((2000, 2000))
    gamescreenmanager = ObjectProperty(None)
    

    def __init__(self, **kwargs):
        super(GameWorld, self).__init__(**kwargs)
        self.entities = []
        self.states = {}
        self.deactivated_entities = []
        for x in range(100):
            Clock.schedule_once(self.test_entity)
        for x in range(25):
            Clock.schedule_once(self.test_physics_entity)
        Clock.schedule_interval(self.update, .03)
        self.add_state(state_name='main_menu', systems_added=[], 
            systems_removed=['position_renderer', 'position', 'physics_renderer', 'cymunk-physics'], 
            systems_paused=[], 
            screenmanager_screen='main_menu')       
        self.add_state(state_name='main_game', systems_added=['position_renderer', 'position', 'physics_renderer', 'cymunk-physics'], 
            systems_removed=[], systems_paused=[], screenmanager_screen='main_game')
        self.state = 'main_menu'

    def add_state(self, state_name, systems_added, systems_removed, systems_paused, screenmanager_screen):
        self.states[state_name] = {'systems_added': systems_added, 
        'systems_removed': systems_removed, 'systems_paused': systems_paused}
        self.gamescreenmanager.states[state_name] = screenmanager_screen


    def on_state(self, instance, value):
        state_dict = self.states[value]
        print state_dict
        self.gamescreenmanager.state = value
        systems = self.systems
        children = self.children
        for system in state_dict['systems_added']:
            if systems[system] in children:
                pass
            else:
                self.add_widget(systems[system])
        for system in state_dict['systems_removed']:
            if systems[system] in children:
                self.remove_widget(systems[system])
        for system in state_dict['systems_paused']:
            systems[system].paused = True
        


    def test_clear_entities(self, dt):
        self.clear_entities()

    def test_remove_system(self, dt):
        self.remove_system('position_renderer')

    def test_physics_entity(self, dt):
        rand_x = random.randint(0, self.map_size[0])
        rand_y = random.randint(0, self.map_size[1])
        x_vel = random.randint(-150, 150)
        y_vel = random.randint(-150, 150)
        angle = math.radians(random.randint(-360, 360))
        angular_velocity = math.radians(random.randint(-360, 360))
        shape_dict = {'inner_radius': 0, 'outer_radius': 45, 'mass': 100, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': 1.0, 
        'collision_type': 1, 'shape_info': shape_dict}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 'velocity': (x_vel, y_vel), 
        'position': (rand_x, rand_y), 'angle': angle, 'angular_velocity': angular_velocity, 
        'mass': 100, 'col_shapes': col_shapes}
        create_component_dict = {'cymunk-physics': physics_component, 
        'physics_renderer': {'texture': 'asteroid2.png', 'render': False}}
        component_order = ['cymunk-physics', 'physics_renderer']
        self.init_entity(create_component_dict, component_order)

    def test_entity(self, dt):
        rand_x = random.randint(0, self.map_size[0])
        rand_y = random.randint(0, self.map_size[1])
        create_component_dict = {'position': {'position': (rand_x, rand_y)}, 
        'position_renderer': {'texture': 'star1.png', 'render': True}}
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
                systems[data].remove_entity(entity_id)
        for component in components_to_delete:
            del entity[component]
        self.deactivated_entities.append(entity_id)

    def update(self, dt):
        systems = self.systems
        for system_name in systems:
            system = systems[system_name]
            if system.updateable and not system.paused:
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
        if isinstance(widget, GameSystem):
            if widget.system_id not in self.systems:
                self.systems[widget.system_id] = widget
                widget.on_init_system()
            widget.on_add_system()
        super(GameWorld, self).add_widget(widget)
        

    def remove_widget(self, widget):
        widget.on_remove_system()
        super(GameWorld, self).remove_widget(widget)

class GameSystem(Widget):
    system_id = StringProperty('default_id')
    updateable = BooleanProperty(False)
    renderable = BooleanProperty(False)
    paused = BooleanProperty(False)
    active = BooleanProperty(True)
    gameworld = ObjectProperty(None)
    viewport = StringProperty('default_gameview')

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self.entity_ids = list()

    def update(self, dt):
        pass

    def draw_entity(self, entity_id):
        pass

    def generate_component_data(self, entity_component_dict):
        return entity_component_dict

    def create_component(self, entity_id, entity_component_dict):
        entity = self.gameworld.entities[entity_id]
        entity[self.system_id] = self.generate_component_data(entity_component_dict)
        if self.renderable:
            self.draw_entity(entity_id)
        self.entity_ids.append(entity_id)

    def generate_entity_component_dict(self, entity_id):
        entity = self.gameworld.entities[entity_id]
        return entity[self.system_id]

    def save_component(self, entity_id):
        entity_component_dict = self.generate_entity_component_dict(entity_id)
        return entity_component_dict

    def remove_entity(self, entity_id):
        self.entity_ids.remove(entity_id)

    def on_init_system(self):
        pass

    def on_remove_system(self):
        self.active = False
        self.paused = True

    def on_add_system(self):
        self.active = True
        self.paused = False

    def on_delete_system(self):
        pass

class GameView(GameSystem):
    system_id = StringProperty('default_gameview')
    lock_scroll = BooleanProperty(True)
    camera_pos = ListProperty((0, 0))

    def on_size(self, instance, value):
        if self.lock_scroll:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y

    def on_camera_pos(self, instance, value):
        systems = self.gameworld.systems
        for system in systems:
            if systems[system].renderable and systems[system].active:
                systems[system].update(None)

    def on_touch_move(self, touch):
        dist_x = touch.dx
        dist_y = touch.dy
        if self.lock_scroll:
            dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
        self.camera_pos[0] += dist_x
        self.camera_pos[1] += dist_y

    def lock_scroll(self, distance_x, distance_y):
        camera_pos = self.camera_pos
        map_size = self.gameworld.map_size
        size = self.size
        pos = self.pos

        if camera_pos[0] + distance_x > pos[0]:
            distance_x = pos[0] - camera_pos[0]
        elif camera_pos[0] + map_size[0] + distance_x <= pos[0] + size[0]:
            distance_x = pos[0] + size[0] - camera_pos[0] - map_size[0]

        if camera_pos[1] + distance_y > pos[1]:
            distance_y = pos[1] - camera_pos[1]
        elif camera_pos[1] + map_size[1] + distance_y <= pos[1] + size[1]:
            distance_y = pos[1] + size[1] - camera_pos[1] - map_size[1]

        return distance_x, distance_y

class BasicPositionSystem(GameSystem):
    system_id = StringProperty('position')
    def __init__(self, **kwargs):
        super(BasicPositionSystem, self).__init__(**kwargs)

class CymunkPhysicsSystem(GameSystem):
    system_id = StringProperty('cymunk-physics')
    space = ObjectProperty(None)
    gravity = ListProperty((0, 0))
    updateable = BooleanProperty(True)


    def __init__(self, **kwargs):
        super(CymunkPhysicsSystem, self).__init__(**kwargs)
        self.current_on_screen = list()
        self.init_physics()

    def init_physics(self):
        # create the space for physics simulation
        self.space = space = cymunk.Space()
        space.iterations = 5
        space.gravity = self.gravity
        space.sleep_time_threshold = 0.5
        
        space.collision_slop = 0.5
        space.register_bb_query_func(self.bb_query_func)

    def test_bb_query(self, dt):
        viewport = self.gameworld.systems[self.viewport]
        camera_pos = viewport.camera_pos
        size = viewport.size
        bb_list = [camera_pos[0], camera_pos[1], size[0], size[1]]
        bb = cymunk.BB(bb_list[0], bb_list[1], bb_list[2], bb_list[3])
        self.space.space_bb_query_func(bb)

    def bb_query_func(self, shape):
        self.current_on_screen.append(shape.body.data)


    def query_on_screen(self):
        viewport = self.gameworld.systems[self.viewport]
        camera_pos = viewport.camera_pos
        size = viewport.size
        bb_list = [-camera_pos[0], -camera_pos[1], -camera_pos[0] + size[0], -camera_pos[1] + size[1]]
        bb = cymunk.BB(bb_list[0], bb_list[1], bb_list[2], bb_list[3])
        self.current_on_screen = []
        self.space.space_bb_query_func(bb)
        return self.current_on_screen
        

    def generate_component_data(self, entity_component_dict):
        '''entity_component_dict of the form {'entity_id': id, 'main_shape': string_shape_name, 
        'velocity': (x, y), 'position': (x, y), 'angle': radians, 
        'angular_velocity': radians, 'mass': float, col_shapes': [col_shape_dicts]}

        col_shape_dicts look like : {'shape_type': string_shape_name, 'elasticity': float, 
        'collision_type': int, 'shape_info': shape_specific_dict}

        shape_info:
        box: {'width': float, 'height': float, 'mass': float}
        circle: {'inner_radius': float, 'outer_radius': float, 'mass': float, 'offset': tuple}
        solid cirlces have an inner_radius of 0

        outputs component dict: {'body': body, 'shapes': array_of_shapes, 
        'position': body.position, angle': body.angle}

        '''
        shape = entity_component_dict['col_shapes'][0]

        if shape['shape_type'] == 'circle':
            moment = cymunk.moment_for_circle(shape['shape_info']['mass'], 
                shape['shape_info']['inner_radius'], shape['shape_info']['outer_radius'], 
                shape['shape_info']['offset'])
        elif shape['shape_type'] == 'box':
            moment = cymunk.moment_for_box(shape['shape_info']['mass'], 
                shape['shape_info']['width'], shape['shape_info']['height'])
        else:
            print 'error: shape ', shape['shape_type'], 'not supported'

        body = cymunk.Body(entity_component_dict['mass'], moment)
        body.position = entity_component_dict['position']
        body.data = entity_component_dict['entity_id']
        body.velocity = entity_component_dict['velocity']
        body.angle = entity_component_dict['angle']
        body.angular_velocity = entity_component_dict['angular_velocity']
        self.space.add(body)
        shapes = []
        for shape in entity_component_dict['col_shapes']:
            shape_info = shape['shape_info']
            if shape['shape_type'] == 'circle':
                new_shape = cymunk.Circle(body, shape_info['outer_radius']) 
            elif shape['shape_type'] == 'box':
                new_shape = cymunk.BoxShape(body, shape_info['width'], shape_info['height'])
            else:
                print 'shape not created'
            new_shape.elasticity = shape['elasticity']
            new_shape.collision_type = shape['collision_type']
            shapes.append(new_shape)
            self.space.add(new_shape)
            
        component_dict = {'body': body, 'shapes': shapes, 'position': body.position, 
        'angle': body.angle, 'shape_type': entity_component_dict['col_shapes'][0]['shape_type']}

        return component_dict

    def create_component(self, entity_id, entity_component_dict):
        entity_component_dict['entity_id'] = entity_id
        super(CymunkPhysicsSystem, self).create_component(entity_id, entity_component_dict)

    def remove_entity(self, entity_id):
        space = self.space
        system_data = self.gameworld.entities[entity_id][self.system_id]
        space.remove(system_data['body'])
        for shape in system_data['shapes']:
            space.remove(shape)
        super(CymunkPhysicsSystem, self).remove_entity(entity_id)

    def check_bounds(self, system_data):
        map_pos = self.gameworld.pos
        map_size = self.gameworld.map_size
        body = system_data['body']
        x_pos, y_pos = body.position
        if system_data['shape_type'] == 'circle':
            size_x = size_y = system_data['shapes'][0].radius
        elif system_data['shape_type'] == 'box':
            size_x, size_y = system_data['shapes'][0].width, system_data['shapes'][0].height
        if x_pos - size_x > map_size[0]:
            body.position = map_pos[0], y_pos
        if x_pos + size_x < map_pos[0]:
            body.position = map_pos[0] + map_size[0], y_pos
        if y_pos - size_y > map_pos[1] + map_size[1]:
            body.position = x_pos, map_pos[1]
        if y_pos + size_y < map_pos[1]:
            body.position = x_pos, map_pos[1] + map_size[1]

    def update(self, dt):
        print 'physics updating'
        entities = self.gameworld.entities
        self.space.step(dt)
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            system_data = entity[self.system_id]
            self.check_bounds(system_data)
            system_data['position'] = system_data['body'].position
            system_data['angle'] = system_data['body'].angle

class QuadRenderer(GameSystem):
    system_id = StringProperty('position_renderer')
    render_information_from = StringProperty('position')
    context_information_from = StringProperty(None)
    off_screen_pos = ListProperty((-100, -100))
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)
    do_rotate = BooleanProperty(False)
    do_color = BooleanProperty(False)
    do_scale = BooleanProperty(False)
    image_mode = StringProperty(None)
    textures = DictProperty(None)

    def __init__(self, **kwargs):
        super(QuadRenderer, self).__init__(**kwargs)

    def generate_component_data(self, entity_component_dict):
        entity_component_dict['translate'] = None
        entity_component_dict['quad'] = None
        entity_component_dict['size'] = None
        if self.do_rotate:
            entity_component_dict['rotate'] = None
        if self.do_color:
            entity_component_dict['color'] = None
        if self.do_scale:
            entity_component_dict['scale'] = None
        return entity_component_dict

    def load_texture(self, texture_str):
        textures = self.textures
        if texture_str not in textures:
            textures[texture_str] = CoreImage(texture_str).texture
        texture = textures[texture_str]
        return texture

    def generate_entity_component_dict(self, entity_id):
        entity = self.gameworld.entities[entity_id]
        entity_system_dict = entity[self.system_id]
        entity_component_dict = {'texture': entity_system_dict['texture'], 'render': entity_system_dict['render']}
        return entity_component_dict

    def draw_entity(self, entity_id):
        parent = self.gameworld
        entity = parent.entities[entity_id]
        system_data = entity[self.system_id]
        render_information = entity[self.render_information_from]
        if self.do_scale or self.do_color:
            context_information = entity[self.context_information_from]
        texture = self.load_texture(system_data['texture'])
        size = texture.size[0] * .5, texture.size[1] *.5
        system_data['size'] = size
        camera_pos = parent.systems[self.viewport].camera_pos
        with self.canvas:
            PushMatrix()
            system_data['translate'] = Translate()
            if self.do_rotate:
                system_data['rotate'] = Rotate()
                system_data['rotate'].angle = render_information['angle']
            if self.do_scale:
                system_data['scale'] = Scale()
                system_data['scale'].x = context_information['scale_x']
                system_data['scale'].y = context_information['scale_y']
            if self.do_color:
                system_data['color'] = Color()
                system_date['color'].rgba = context_information['color']
            system_data['quad'] = Quad(texture = texture, points = (-size[0], -size[1], size[0], -size[1],
                size[0], size[1], -size[0], size[1]))
            system_data['translate'].xy = render_information['position'][0] + camera_pos[0], render_information['position'][1] + camera_pos[1]
            PopMatrix()

    def update_render_state(self):
        parent = self.gameworld
        viewport = parent.systems[self.viewport]
        camera_pos = viewport.camera_pos
        camera_size = viewport.size
        pos = self.pos
        system_id = self.system_id
        entities = parent.entities
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            system_data = entity[system_id]
            render_information = entity[self.render_information_from]
            if render_information['position'][0] + system_data['size'][0] > pos[0] - camera_pos[0] and render_information['position'][0] - system_data['size'][0] < pos[0] - camera_pos[0] + camera_size[0]:
                if render_information['position'][1] + system_data['size'][1] > pos[1] - camera_pos[1] and render_information['position'][1] - system_data['size'][1] < pos[1] - camera_pos[1] + camera_size[1]:
                    if not system_data['render']:
                        system_data['render'] = True
                else:
                    if system_data['render']:
                        system_data['render'] = False
            else:
                if system_data['render']:
                    system_data['render'] = False

    def render(self):
        parent = self.gameworld
        entities = parent.entities
        system_id = self.system_id
        do_color = self.do_color
        do_scale = self.do_scale
        do_rotate = self.do_rotate
        off_screen_pos = self.off_screen_pos
        camera_pos = parent.systems[self.viewport].camera_pos
        render_information_from = self.render_information_from
        if do_scale or do_color:
            context_information_from = self.context_information_from
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            system_data = entity[system_id]
            if system_data['render']:
                render_information = entity[render_information_from]
                if do_scale or do_color:
                    context_information = entity[context_information_from]
                system_data['translate'].xy = render_information['position'][0] + camera_pos[0], render_information['position'][1] + camera_pos[1]
                if do_rotate:
                    system_data['rotate'].angle = math.degrees(render_information['angle'])
                if do_scale:
                    system_data['scale'].x = context_information['scale_x']
                    system_data['scale'].y = context_information['scale_y']
                if do_color:
                    system_data['color'].rgba = context_information['color']
            else:
                if not system_data['translate'].x == off_screen_pos[0]:
                    system_data['translate'].xy = off_screen_pos
            
    def update(self, dt):
        self.update_render_state()
        self.render()


    def remove_entity(self, entity_id):
        system_data = self.gameworld.entities[entity_id][self.system_id]
        for data in system_data:
            if isinstance(system_data[data], Instruction):
                self.canvas.remove(system_data[data])
        super(QuadRenderer, self).remove_entity(entity_id)

class PhysicsRenderer(QuadRenderer):
    system_id = StringProperty('physics_renderer')
    render_information_from = StringProperty('cymunk-physics')
    do_rotate = BooleanProperty(True)

    def update_render_state(self):
        parent = self.gameworld
        entities = parent.entities
        system_id = self.system_id
        entity_ids = self.entity_ids
        physics_system = parent.systems[self.render_information_from]
        on_screen = physics_system.query_on_screen()
        for entity_id in entity_ids:
            entity = entities[entity_id]
            system_data = entity[system_id]
            if not system_data['render'] and entity_id in on_screen:
                system_data['render'] = True
            if system_data['render'] and not entity_id in on_screen:
                system_data['render'] = False


class KivEntApp(App):
    def build(self):
        pass


if __name__ == '__main__':

    KivEntApp().run()
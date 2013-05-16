from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, NumericProperty, 
DictProperty, BooleanProperty, ObjectProperty)
from kivy.graphics import (PushMatrix, PopMatrix, Translate, Quad, Instruction, 
Rotate, Color, Scale)
from kivy.core.image import Image as CoreImage
from gamesystems import GameSystem
import math
from kivy.atlas import Atlas
from quadtree import QuadTree
from kivy.clock import Clock

class QuadRenderer(GameSystem):
    system_id = StringProperty('position_renderer')
    render_information_from = StringProperty('position')
    context_information_from = StringProperty(None)
    off_screen_pos = ListProperty((-1000, -1000))
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)
    do_rotate = BooleanProperty(False)
    do_color = BooleanProperty(False)
    do_scale = BooleanProperty(False)
    image_mode = StringProperty('image')
    textures = DictProperty(None)

    def __init__(self, **kwargs):
        super(QuadRenderer, self).__init__(**kwargs)

    def generate_component_data(self, entity_component_dict):
        entity_component_dict['translate'] = None
        entity_component_dict['quad'] = None
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

    def load_texture_from_atlas(self, atlas_address, key):
        textures = self.textures
        if atlas_address not in textures:
            textures[atlas_address] = Atlas(atlas_address)
        texture = textures[atlas_address]
        return texture[key]

    def generate_entity_component_dict(self, entity_id):
        entity = self.gameworld.entities[entity_id]
        entity_system_dict = entity[self.system_id]
        entity_component_dict = {'texture': entity_system_dict['texture'], 
        'render': entity_system_dict['render']}
        return entity_component_dict

    def remove_entity_from_canvas(self, entity_id):
        self.canvas.remove_group(str(entity_id))
        entity = self.gameworld.entities[entity_id]
        system_data = entity[self.system_id]
        system_data['render'] = False
        system_data['translate'] = None
        system_data['quad'] = None
        if self.do_rotate:
            system_data['rotate'] = None
        if self.do_color:
            system_data['color'] = None
        if self.do_scale:
            system_data['scale'] = None

    def draw_entity(self, entity_id):
        parent = self.gameworld
        entity = parent.entities[entity_id]
        system_data = entity[self.system_id]
        render_information = entity[self.render_information_from]
        if self.do_scale or self.do_color:
            context_information = entity[self.context_information_from]
        if self.image_mode == 'image':
            texture = self.load_texture(system_data['texture'])
        elif self.image_mode == 'atlas':
            texture = self.load_texture_from_atlas(system_data['texture'], system_data['texture_key'])
        size = texture.size[0] * .5, texture.size[1] *.5
        if self.do_scale:
            system_data['size'] = (size[0] * context_information['scale_x'], size[1] * context_information['scale_y'])
        else:
            system_data['size'] = size

        camera_pos = parent.systems[self.viewport].camera_pos
        with self.canvas:
            group_id = str(entity_id)
            PushMatrix(group=group_id)
            system_data['translate'] = Translate(group=group_id)
            if self.do_rotate:
                system_data['rotate'] = Rotate(group=group_id)
                system_data['rotate'].angle = render_information['angle']
            if self.do_scale:
                system_data['scale'] = Scale(group=group_id)
                system_data['scale'].x = context_information['scale_x']
                system_data['scale'].y = context_information['scale_y']
            if self.do_color:
                system_data['color'] = Color(group=group_id)
                system_date['color'].rgba = context_information['color']
            system_data['quad'] = Quad(texture = texture, points = (-size[0], 
                -size[1], size[0], -size[1],
                size[0], size[1], -size[0], size[1]))
            system_data['translate'].xy = (render_information['position'][0] + camera_pos[0], 
            render_information['position'][1] + camera_pos[1])

            PopMatrix(group=group_id)
        system_data['render'] = True

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
            size = system_data['size']
            if size == None:
                print 'problem'
            position = render_information['position']
            if (position[0] + size[0] > pos[0] - camera_pos[0] and position[0] 
                - size[0] < pos[0] - camera_pos[0] + camera_size[0]):
                if (position[1] + size[1] > pos[1] - camera_pos[1] and position[1] - 
                size[1] < pos[1] - camera_pos[1] + camera_size[1]):
                    if not system_data['render']:
                        self.draw_entity(entity_id)
                else:
                    if system_data['render']:
                        self.remove_entity_from_canvas(entity_id)
            else:
                if system_data['render']:                  
                    self.remove_entity_from_canvas(entity_id)

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
                system_data['translate'].xy = (render_information['position'][0] + 
                camera_pos[0], render_information['position'][1] + camera_pos[1])
                if do_rotate:
                    system_data['rotate'].angle = render_information['angle']
                if do_scale:
                    system_data['scale'].x = context_information['scale_x']
                    system_data['scale'].y = context_information['scale_y']
                if do_color:
                    system_data['color'].rgba = context_information['color']
            
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
                self.draw_entity(entity_id)
            if system_data['render'] and not entity_id in on_screen:
                self.remove_entity_from_canvas(entity_id)

class QuadTreeQuadRenderer(QuadRenderer):
    system_id = StringProperty('quadtree_renderer')
    render_information_from = StringProperty('position')
    quadtree = ObjectProperty(None)
    quadtree_size = ListProperty((2000., 2000.))

    def __init__(self, **kwargs):
        super(QuadTreeQuadRenderer, self).__init__(**kwargs)
        Clock.schedule_once(self.setup_quadtree)

    def create_component(self, entity_id, entity_component_dict):
        super(QuadTreeQuadRenderer, self).create_component(entity_id, entity_component_dict)
        self.quadtree.add_items([entity_id], 7)

    def setup_quadtree(self, dt):
        self.quadtree = QuadTree(self.gameworld, self.render_information_from, self.system_id, 
            self.entity_ids, depth=7, bounding_rect=(0, 0, self.quadtree_size[0], self.quadtree_size[1]))

    def draw_entity(self, entity_id):
        super(QuadTreeQuadRenderer, self).draw_entity(entity_id)
        

    def update_render_state(self):
        parent = self.gameworld
        entities = parent.entities
        system_id = self.system_id
        entity_ids = self.entity_ids
        on_screen = self.query_on_screen()
        for entity_id in entity_ids:
            entity = entities[entity_id]
            system_data = entity[system_id]
            if not system_data['render'] and entity_id in on_screen:
                self.draw_entity(entity_id)
            if system_data['render'] and not entity_id in on_screen:
                self.remove_entity_from_canvas(entity_id)

    def query_on_screen(self):
        viewport = self.gameworld.systems[self.viewport]
        camera_pos = viewport.camera_pos
        size = viewport.size
        bb_list = [-camera_pos[0] + size[0], -camera_pos[0],  -camera_pos[1] + size[1], -camera_pos[1]]
        current_on_screen = self.quadtree.bb_hit(bb_list[0], bb_list[1], bb_list[2], bb_list[3])
        return current_on_screen
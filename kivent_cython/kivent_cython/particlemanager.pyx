from kivy.properties import StringProperty, BooleanProperty, ObjectProperty
from math import radians
from xml.dom.minidom import parse as parse_xml
from kivy.core.image import Image as CoreImage
from libc.math cimport trunc, M_PI_2
from kivy.graphics import Fbo, Rectangle, Color, RenderContext, Mesh
from kivy.graphics.opengl import (glEnable, glBlendFunc, GL_SRC_ALPHA, GL_ONE, 
GL_ZERO, GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA, 
GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR,
glDisable)

BLEND_FUNC = {
            0: GL_ZERO,
            1: GL_ONE,
            0x300: GL_SRC_COLOR,
            0x301: GL_ONE_MINUS_SRC_COLOR,
            0x302: GL_SRC_ALPHA,
            0x303: GL_ONE_MINUS_SRC_ALPHA,
            0x304: GL_DST_ALPHA,
            0x305: GL_ONE_MINUS_DST_ALPHA,
            0x306: GL_DST_COLOR,
            0x307: GL_ONE_MINUS_DST_COLOR,
            }


cdef class ParticleComponent:
    cdef int _parent
    cdef keParticleEmitter _particle_emitter
    cdef bool _system_on
    cdef float _offset

    def __cinit__(self, int parent, keParticleEmitter emitter, 
        bool system_on, float offset=0.0):
        self._parent = parent
        self._particle_emitter = emitter
        self._system_on = system_on
        self._offset = offset

    property parent:
        def __get__(self):
            return self._parent
        def __set__(self, int value):
            self._parent = value

    property offset:
        def __get__(self):
            return self._offset
        def __set__(self, float value):
            self._offset = value

    property system_on:
        def __get__(self):
            return self._system_on
        def __set__(self, bool value):
            self._system_on = value

    property particle_emitter:
        def __get__(self):
            return self._particle_emitter
        def __set__(self, keParticleEmitter value):
            self._particle_emitter = value


class ParticleManager(GameSystem):
    system_id = StringProperty('particle_manager')
    max_number_particles = NumericProperty(100)
    position_data_from = StringProperty('cymunk-physics')
    physics_data_from = StringProperty('cymunk-physics')
    render_information_from = StringProperty('physics_renderer')
    shader_source = StringProperty('pointshader.glsl')
    updateable = BooleanProperty(True)
    number_of_effects = NumericProperty(0)
    blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    blend_factor_dest = NumericProperty(GL_ONE)
    atlas_dir = StringProperty(None)
    atlas = StringProperty(None)
    reset_blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    reset_blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    mesh = ObjectProperty(None, allownone=True)

    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True, 
            nocompiler=True)
        if 'shader_source' in kwargs:
            self.canvas.shader.source = kwargs.get('shader_source')
        super(ParticleManager, self).__init__(**kwargs)
        with self.canvas.before:
            Callback(self._set_blend_func)
        with self.canvas.after:
            Callback(self._reset_blend_func)
        self._particle_manager = keParticleManager(self.max_number_particles)
        self.unused_particle_effects = []

    def on_shader_source(self, instance, value):
        self.canvas.shader.source = value

    def on_atlas(self, instance, value):
        pm = self._particle_manager
        pm.atlas_name = value
        pm.atlas_page = value + '-0.png'
        if value and self.atlas_dir:
            self.atlas_image = image = CoreImage(
                self.atlas_dir + value+'-0.png')
            pm.atlas_texture = image.texture

    def on_atlas_dir(self, instance, value):
        pm = self._particle_manager
        pm.atlas_dir = value
        if value and self.atlas:
            self.atlas_image = image = CoreImage(
                self.atlas_dir + value+'-0.png')
            pm.atlas_texture = image.texture
            

    def _set_blend_func(self, instruction):
        glBlendFunc(self.blend_factor_source, self.blend_factor_dest)

    def _reset_blend_func(self, instruction):
        glBlendFunc(self.reset_blend_factor_source, 
            self.reset_blend_factor_dest)

    def on_max_number_particles(self, instance, value):
        pm = self._particle_manager
        if value:
            pm.max_particles = value
        
    def generate_component(self, dict entity_component_dict):
        cdef keParticleManager pm = self._particle_manager
        cdef keParticleEmitter emitter
        particle_configs = pm.particle_configs
        unused_particle_effects = self.unused_particle_effects
        config = entity_component_dict['particle_file']
        if not config in particle_configs:
            pm.load_particle_config(config)
        if len(unused_particle_effects) > 0:
            emitter = unused_particle_effects.pop()
        else:
            emitter = pm.get_emitter()
            pm.add_emitter(emitter)
        emitter = pm.load_particle_system_with_emitter(
            emitter, config)
        cdef ParticleComponent new_component = ParticleComponent.__new__(
            ParticleComponent, entity_component_dict['parent'],
            emitter, False)
        if 'offset' in entity_component_dict:
            new_component._offset = entity_component_dict['offset']
        return new_component

    def load_particle_config(self, config):
        pm = self._particle_manager
        pm.load_particle_config(config)

    def remove_entity(self, entity_id):
        cdef list entities = self.gameworld.entities
        cdef str system_id = self.system_id
        cdef object entity = entities[entity_id]
        cdef ParticleComponent particle_comp = getattr(entity, system_id)
        pm = self._particle_manager
        particle_emitter = particle_comp._particle_emitter
        particle_emitter.paused = True
        self.unused_particle_effects.append(particle_emitter)
        super(ParticleManager, self).remove_entity(entity_id)

    def draw_mesh(self):
        cdef CMesh cmesh
        cdef keParticleManager particle_manager
        particle_manager = <keParticleManager>self._particle_manager
        vertex_format = [
            ('vPosition', 2, 'float'),
            ('vTexCoords0', 2, 'float'),
            ('vCenter', 2, 'float'),
            ('vRotation', 1, 'float'),
            ('vColor', 4, 'float'),
            ('vScale', 1, 'float')
            ]

        mesh = self.mesh
        if mesh == None:
            with self.canvas:
                cmesh = CMesh(fmt=vertex_format,
                    mode='triangles',
                    texture=self.atlas_image.texture)
                self.mesh = cmesh
        cmesh = self.mesh
        cmesh._vertices = particle_manager.frame_info_ptr
        cmesh._indices = particle_manager.indice_info_ptr
        cmesh.vcount = particle_manager.v_count
        cmesh.icount = particle_manager.i_count
        cmesh.flag_update()


    def update(self, dt):
        cdef dict systems = self.gameworld.systems
        cdef list entities = self.gameworld.entities
        cdef str render_information_from = self.render_information_from
        cdef str system_id = self.system_id
        cdef object entity
        cdef RenderComponent render_comp
        cdef ParticleComponent particle_comp
        cdef keParticleEmitter particle_emitter
        cdef keParticleManager pm = self._particle_manager
        cdef RotateComponent rotate_comp
        calculate_particle_offset = self.calculate_particle_offset
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            particle_comp = getattr(entity, system_id)
            particle_emitter = particle_comp._particle_emitter
            paused = particle_emitter.paused
            parent_entity = entities[particle_comp._parent]
            render_comp = getattr(parent_entity, render_information_from)
            if render_comp._on_screen:
                if particle_comp._system_on:
                    if paused:
                        particle_emitter.paused = False
                        new_pos = calculate_particle_offset(
                            parent_entity, particle_comp._offset)
                        particle_emitter.x = new_pos[0]
                        particle_emitter.y = new_pos[1]
                        rotate_comp = parent_entity.rotate
                        particle_emitter.emit_angle = (
                            rotate_comp._r + 3. * M_PI_2)
                    else:
                        if not paused:
                            particle_emitter.paused = True
                else:
                    if not paused:
                        particle_emitter.paused = True
        pm.update(dt)
        self.draw_mesh()

    def calculate_particle_offset(self, object entity, float offset):
        cdef PositionComponent position_data = entity.position
        cdef str physics_system = self.physics_data_from
        cdef tuple effect_pos
        cdef float x = position_data._x
        cdef float y = position_data._y
        cdef PhysicsComponent physics_data 
        if offset != 0.:
            physics_data = getattr(entity, physics_system)
            unit_vector = physics_data.unit_vector
            effect_pos = (x - offset * unit_vector[0], 
                y - offset * unit_vector[1])
        else:
            effect_pos = (x, y)
        return effect_pos

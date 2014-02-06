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


class ParticleManager(GameSystem):
    system_id = StringProperty('particle_manager')
    max_number_particles = NumericProperty(100)
    position_data_from = StringProperty('cymunk-physics')
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
        self.canvas = RenderContext(use_parent_projection=True)
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
        
    def generate_component_data(self, dict entity_component_dict):
        pm = self._particle_manager
        particle_configs = pm.particle_configs
        unused_particle_effects = self.unused_particle_effects
        up = unused_particle_effects.pop
        for particle_effect in entity_component_dict:
            config = entity_component_dict[particle_effect]['particle_file']
            if not config in particle_configs:
                pm.load_particle_config(config)
            if len(unused_particle_effects) > 0:
                emitter = up()
            else:
                emitter = pm.get_emitter()
                pm.add_emitter(emitter)
            entity_component_dict[particle_effect]['particle_system'] = (
                particle_system) = pm.load_particle_system_with_emitter(
                emitter, config)
            entity_component_dict[
                particle_effect]['particle_system_on'] = False
        return entity_component_dict

    def load_particle_config(self, config):
        pm = self._particle_manager
        pm.load_particle_config(config)

    def remove_entity(self, entity_id):
        cdef list entities = self.gameworld.entities
        cdef str system_id = self.system_id
        cdef dict entity = entities[entity_id]
        cdef object particle_system 
        cdef dict particle_systems
        particle_systems = entity[self.system_id]
        pm = self._particle_manager
        unused_particle_effects = self.unused_particle_effects
        ua = unused_particle_effects.append
        for particle_effect in particle_systems:
            particle_system = particle_systems[
                particle_effect]['particle_system']
            particle_system.paused = True
            ua(particle_system)
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
        cdef str position_data_from = self.position_data_from
        cdef str system_data_from = self.system_id
        cdef dict entity
        cdef dict particle_systems
        cdef object particle_system
        pm = self._particle_manager
        calculate_particle_offset = self.calculate_particle_offset
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            particle_systems = entity[system_data_from]
            for particle_effect in particle_systems:
                particle_system = particle_systems[
                    particle_effect]['particle_system']
                paused = particle_system.paused
                if entity[render_information_from]['on_screen']:
                    if particle_systems[particle_effect]['particle_system_on']:
                        if paused:
                            particle_system.paused = False
                        new_pos = calculate_particle_offset(
                            entity_id, particle_effect)
                        particle_system.x = new_pos[0]
                        particle_system.y = new_pos[1]
                        particle_system.emit_angle = entity[
                            position_data_from]['angle'] + 3. * M_PI_2
                    else:
                        if not paused:
                            particle_system.paused = True
                else:
                    if not paused:
                        particle_system.paused = True
        pm.update(dt)
        self.draw_mesh()

    def calculate_particle_offset(self, entity_id, particle_effect):
        cdef dict entity = self.gameworld.entities[entity_id]
        cdef dict position_data = entity[self.position_data_from]
        cdef dict system_data = entity[self.system_id]
        cdef int offset = system_data[particle_effect]['offset']
        cdef tuple effect_pos
        pos = position_data['position']
        if offset != 0.:
            unit_vector = position_data['unit_vector']
            effect_pos = (pos[0] - offset * unit_vector[0], 
                pos[1] - offset * unit_vector[1])
        else:
            effect_pos = (pos[0], pos[1])
        return effect_pos

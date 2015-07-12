from cpython cimport bool
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem,
    MemComponent)
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivy.factory import Factory
from kivy.properties import (ObjectProperty, NumericProperty, ListProperty, 
    BooleanProperty, StringProperty)
from kivent_core.entity cimport Entity

from libc.math cimport trunc, sin, cos, fmin, fmax
from kivent_core.systems.rotate_systems cimport RotateStruct2D
from kivent_core.systems.position_systems cimport PositionStruct2D
from kivent_particles.particle cimport ParticleSystem


include "particle_config.pxi"
include "particle_math.pxi"

cdef class ParticleEmitter:

    def __cinit__(self, str effect_name):
        self._effect_name = effect_name
        self._emit_angle_offset = 0.0
        self._emit_angle = 0.
        self._life_span = 1.0
        self._paused = False
        self._emitter_type = 0
        self._number_of_particles = 0
        self._current_particles = 0
        self._emission_rate = 1.0
        self._frame_time = 0.0
        self._start_scale = 1.
        self._start_scale_variance = 0.0
        self._end_scale = .1
        self._end_scale_variance = 0.0
        self._emit_angle_variance = 0.0
        self._start_rotation = 0.0
        self._start_rotation_variance = 0.0
        self._end_rotation = 0.0
        self._end_rotation_variance = 0.0
        self._life_span_variance = 0.0
        self._speed = 10.0
        self._speed_variance = 0.0
        self._radial_acceleration = 0.0
        self._radial_acceleration_variance = 0.0
        self._tangential_acceleration = 0.0
        self._tangential_acceleration_variance = 0.0
        self._max_radius = 25.0
        self._max_radius_variance = 0.0
        self._min_radius = 0.0
        self._rotate_per_second = 0.0
        self._texture = None
        self._rotate_per_second_variance = 0.0
        cdef int x
        for x in range(2):
            self._gravity[x] = 0.           
            self._pos_variance[x] = 0.
            self._pos_offset[x] = 0.
            self._pos[x] = 0.
        for x in range(4):
            self._start_color[x] = 255
            self._start_color_variance[x] = 255
            self._end_color[x] = 255
            self._end_color_variance[x] = 255

    def calculate_emission_rate(self):
        self._emission_rate = float(
            self._number_of_particles) / self._life_span

    property texture:

        def __get__(self):
            return self._texture

        def __set__(self, str name):
            self._texture = name

    property effect_name:

        def __get__(self):
            return self._effect_name

        def __set__(self, str name):
            self._effect_name = name

    property x_offset:

        def __get__(self):
            return self._pos_offset[0]

        def __set__(self, float value):
            self._pos_offset[0] = value

    property y_offset:
        def __get__(self):
            return self._pos_offset[1]

        def __set__(self, float value):
            self._pos_offset[1] = value

    property pos_offset:

        def __get__(self):
            return [self._pos_offset[i] for i in range(2)]

        def __set__(self, value):
            for i in range(2):
                self._pos_offset[i] = value[i]

    property emit_angle_offset:

        def __get__(self):
            return self._emit_angle_offset

        def __set__(self, float value):
            self._emit_angle_offset = value

    property life_span:

        def __get__(self):
            return self._life_span

        def __set__(self, float value):
            self._life_span = value
            self.calculate_emission_rate()

    property paused:

        def __get__(self):
            return self._paused

        def __set__(self, value):
            self._paused = value

    property emitter_type:

        def __get__(self):
            return self._emitter_type

        def __set__(self, value):
            self._emitter_type = value

    property number_of_particles:

        def __get__(self):
            return self._number_of_particles

        def __set__(self, value):
            self._number_of_particles = value
            self.calculate_emission_rate()

    property life_span_variance:

        def __get__(self):
            return self._life_span_variance

        def __set__(self, value):
            self._life_span_variance = value

    property gravity_x:

        def __get__(self):
            return self._gravity[0]

        def __set__(self, value):
            self._gravity[0] = value

    property gravity_y:

        def __get__(self):
            return self._gravity[1]

        def __set__(self, value):
            self._gravity[1] = value

    property gravity:

        def __get__(self):
            return [self._gravity[i] for i in range(2)]

        def __set__(self, value):
            for i in range(2):
                self._gravity[i] = value[i]

    property start_scale:

        def __get__(self):
            return self._start_scale

        def __set__(self, value):
            self._start_scale = value

    property start_scale_variance:

        def __get__(self):
            return self._start_scale_variance

        def __set__(self, value):
            self._start_scale_variance = value

    property end_scale:

        def __get__(self):
            return self._end_scale

        def __set__(self, value):
            self._end_scale = value

    property end_scale_variance:

        def __get__(self):
            return self._end_scale_variance

        def __set__(self, value):
            self._end_scale_variance = value

    property emit_angle_variance:

        def __get__(self):
            return self._emit_angle_variance

        def __set__(self, value):
            self._emit_angle_variance = value

    property start_rotation:

        def __get__(self):
            return self._start_rotation

        def __set__(self, value):
            self._start_rotation = value

    property start_rotation_variance:

        def __get__(self):
            return self._start_rotation_variance

        def __set__(self, value):
            self._start_rotation_variance = value

    property end_rotation:

        def __get__(self):
            return self._end_rotation

        def __set__(self, value):
            self._end_rotation = value

    property end_rotation_variance:

        def __get__(self):
            return self._end_rotation_variance

        def __set__(self, value):
            self._end_rotation_variance = value

    property x_variance:

        def __get__(self):
            return self._pos_variance[0]

        def __set__(self, value):
            self._pos_variance[0] = value

    property y_variance:

        def __get__(self):
            return self._pos_variance[1]

        def __set__(self, value):
            self._pos_variance[1] = value

    property pos_variance:

        def __get__(self):
            return [self._pos_variance[i] for i in range(2)]

        def __set__(self, value):
            for i in range(2):
                self._pos_variance[i] = value[i]

    property speed:

        def __get__(self):
            return self._speed

        def __set__(self, value):
            self._speed = value

    property speed_variance:

        def __get__(self):
            return self._speed_variance

        def __set__(self, value):
            self._speed_variance = value

    property radial_acceleration:

        def __get__(self):
            return self._radial_acceleration

        def __set__(self, value):
            self._radial_acceleration = value

    property radial_acceleration_variance:

        def __get__(self):
            return self._radial_acceleration_variance

        def __set__(self, value):
            self._radial_acceleration_variance = value

    property tangential_acceleration:

        def __get__(self):
            return self._tangential_acceleration

        def __set__(self, value):
            self._tangential_acceleration = value

    property tangential_acceleration_variance:

        def __get__(self):
            return self._tangential_acceleration_variance

        def __set__(self, value):
            self._tangential_acceleration_variance = value

    property max_radius:

        def __get__(self):
            return self._max_radius

        def __set__(self, value):
            self._max_radius = value

    property max_radius_variance:

        def __get__(self):
            return self._max_radius_variance

        def __set__(self, value):
            self._max_radius_variance = value

    property min_radius:

        def __get__(self):
            return self._min_radius

        def __set__(self, value):
            self._min_radius = value

    property rotate_per_second:

        def __get__(self):
            return self._rotate_per_second

        def __set__(self, value):
            self._rotate_per_second = value

    property rotate_per_second_variance:

        def __get__(self):
            return self._rotate_per_second_variance

        def __set__(self, value):
            self._rotate_per_second_variance = value

    property start_color:

        def __get__(self):
            return [self._start_color[x] for x in range(4)]

        def __set__(self, value):
            for i in range(4):
                self._start_color[i] = value[i]

    property start_color_variance:

        def __get__(self):
            return [self._start_color_variance[x] for x in range(4)]

        def __set__(self, value):
            for i in range(4):
                self._start_color_variance[i] = value[i]

    property end_color:

        def __get__(self):
            return [self._end_color[x] for x in range(4)]

        def __set__(self, value):
            for i in range(4):
                self._end_color[i] = value[i]

    property end_color_variance:

        def __get__(self):
            return [self._end_color_variance[x] for x in range(4)]

        def __set__(self, value):
            for i in range(4):
                self._end_color_variance[i] = value[i]


cdef class EmitterComponent(MemComponent):
    '''The component associated with EmitterSystem

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is 
        unattached.


    '''
    def __cinit__(self, MemoryBlock memory_block, unsigned int index,
            unsigned int offset):
        self._emitters = [None for x in range(MAX_EMITTERS)]

    
    property entity_id:

        def __get__(self):
            cdef EmitterStruct* data = <EmitterStruct*>self.pointer
            return data.entity_id

    property emitters:

        def __get__(self):
            return self._emitters


class TooManyEmitters(Exception):
    pass

cdef class EmitterSystem(StaticMemGameSystem):
    '''
    '''
    system_id = StringProperty('emitters')
    type_size = NumericProperty(sizeof(EmitterStruct))
    component_type = ObjectProperty(EmitterComponent)
    updateable = BooleanProperty(True)
    processor = BooleanProperty(True)
    system_names = ListProperty(['emitters', 'position', 'rotate'])
    particle_system = ObjectProperty(None)    

    def __init__(self, **kwargs):
        super(EmitterSystem, self).__init__(**kwargs)
        self._emitter_prototypes = {}
        self.attributes_to_save = ['effect_name', 'pos_offset',
            'emit_angle_offset', 'gravity', 'pos_variance', 'life_span', 
            'paused', 'emitter_type', 'number_of_particles', 
            'life_span_variance', 'start_scale', 'start_scale_variance', 
            'end_scale', 'end_scale_variance', 'emit_angle_variance', 
            'start_rotation', 'start_rotation_variance', 'end_rotation', 
            'end_rotation_variance', 'emit_angle_variance',
            'speed', 'speed_variance', 'radial_acceleration', 
            'radial_acceleration_variance', 'tangential_acceleration', 
            'tangential_acceleration_variance', 'max_radius', 'min_radius',
            'max_radius_variance', 'rotate_per_second', 
            'rotate_per_second_variance', 'start_color', 'start_color_variance',
            'end_color', 'end_color_variance']
        
    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, args):
        '''
        '''
        cdef EmitterComponent py_component = self.components[component_index]
        cdef EmitterStruct* component = <EmitterStruct*>py_component.pointer
        cdef ParticleEmitter emitter
        component.entity_id = entity_id
        cdef unsigned int ent_comps_ind = self.entity_components.add_entity(
            entity_id, zone)
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int real_index = ent_comps_ind * component_count
        cdef PositionStruct2D* pos_comp = <PositionStruct2D*>component_data[
            real_index+1]
        cdef RotateStruct2D* rot_comp = <RotateStruct2D*>component_data[
            real_index+2]
        cdef float[2] resulting_offset

        for effect_name in args:
            emitter = self.create_effect(effect_name)
            index = self.insert_effect_into_component(emitter, py_component)
            emitter._emit_angle = rot_comp.r + emitter._emit_angle_offset
            rotate_offset(emitter._pos_offset, emitter._emit_angle, 
                resulting_offset)
            emitter._pos[0] = pos_comp.x + resulting_offset[0]
            emitter._pos[1] = pos_comp.y + resulting_offset[1]


    def load_effect(self, str file_name):
        pass

    def update(self, float dt):
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index, e, o, c

        cdef EmitterStruct* emitter_comp
        cdef PositionStruct2D* pos_comp
        cdef RotateStruct2D* rot_comp
        cdef ParticleEmitter emitter

        cdef float angle_offset, time_between_particles
        cdef float[2] resulting_offset
        cdef int number_of_updates

        cdef ParticleSystem particle_system = self.particle_system

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            emitter_comp = <EmitterStruct*>component_data[real_index]
            pos_comp = <PositionStruct2D*>component_data[real_index+1]
            rot_comp = <RotateStruct2D*>component_data[real_index+2]
            for e in range(MAX_EMITTERS):
                if emitter_comp.emitters[e] is NULL:
                    continue
                emitter = <ParticleEmitter>emitter_comp.emitters[e]
                if not emitter._paused:
                    emitter._emit_angle = (
                        rot_comp.r + emitter._emit_angle_offset)
                    rotate_offset(emitter._pos_offset, emitter._emit_angle, 
                        resulting_offset)
                    emitter._pos[0] = pos_comp.x + resulting_offset[0]
                    emitter._pos[1] = pos_comp.y + resulting_offset[1]
                    emitter._frame_time += dt
                    time_between_particles = 1.0 / emitter._emission_rate
                    number_of_updates = <int>(
                        emitter._frame_time / time_between_particles)
                    emitter._frame_time -= (
                        time_between_particles * number_of_updates)
                    for c in range(number_of_updates):
                        if emitter._current_particles < (
                            emitter._number_of_particles):
                            emitter._current_particles += 1
                            particle_system.create_particle(emitter)
                
    def flatten_effect_to_dict(self, ParticleEmitter emitter):
        data = {}
        for key in self.attributes_to_save:
            data[key] = getattr(emitter, key)
        return data

    def load_effect_from_data(self, dict data, str effect_name):
        cdef ParticleEmitter emitter = ParticleEmitter(effect_name)
        for key in data:
            setattr(emitter, key, data[key])
        self._emitter_prototypes[effect_name] = emitter

    def create_effect(self, str effect_name):
        cdef ParticleEmitter prototype = self._emitter_prototypes[effect_name]
        cdef ParticleEmitter new_effect = ParticleEmitter(effect_name)
        self.copy_effect(prototype, new_effect)
        return new_effect

    cdef void copy_effect(self, ParticleEmitter from_emitter, 
        ParticleEmitter to_emitter):
        cdef int i 
        to_emitter._emit_angle_offset = from_emitter._emit_angle_offset
        to_emitter._texture = from_emitter._texture
        cdef float[2] _pos_offset
        for i in range(2):
            to_emitter._pos_offset[i] = from_emitter._pos_offset[i]
            to_emitter._gravity[i] = from_emitter._gravity[i]
            to_emitter._pos_variance[i] = from_emitter._pos_variance[i]
        to_emitter._life_span = from_emitter._life_span
        to_emitter._paused = from_emitter._paused
        to_emitter._emitter_type = from_emitter._emitter_type
        to_emitter._number_of_particles = from_emitter._number_of_particles
        to_emitter._frame_time = from_emitter._frame_time
        to_emitter._start_scale = from_emitter._start_scale
        to_emitter._emission_rate = from_emitter._emission_rate
        to_emitter._start_scale_variance = from_emitter._start_scale_variance
        to_emitter._end_scale = from_emitter._end_scale
        to_emitter._end_scale_variance = from_emitter._end_scale_variance
        to_emitter._emit_angle_variance = from_emitter._emit_angle_variance
        to_emitter._start_rotation = from_emitter._start_rotation
        to_emitter._start_rotation_variance = (
            from_emitter._start_rotation_variance)
        to_emitter._end_rotation = from_emitter._end_rotation
        to_emitter._end_rotation_variance = from_emitter._end_rotation_variance
        to_emitter._life_span_variance = from_emitter._life_span_variance
        to_emitter._speed = from_emitter._speed
        to_emitter._speed_variance = from_emitter._speed_variance
        to_emitter._radial_acceleration = from_emitter._radial_acceleration
        to_emitter._radial_acceleration_variance = (
            from_emitter._radial_acceleration_variance)
        to_emitter._tangential_acceleration = (
            from_emitter._tangential_acceleration)
        to_emitter._tangential_acceleration_variance = (
            from_emitter._tangential_acceleration_variance)
        to_emitter._max_radius = from_emitter._max_radius
        to_emitter._max_radius_variance = from_emitter._max_radius_variance
        to_emitter._min_radius = from_emitter._min_radius
        to_emitter._rotate_per_second = from_emitter._rotate_per_second
        to_emitter._rotate_per_second_variance = (
            from_emitter._rotate_per_second_variance)
        for i in range(4):
            to_emitter._start_color[i] = from_emitter._start_color[i]
            to_emitter._start_color_variance[i] = (
                from_emitter._start_color_variance[i])
            to_emitter._end_color[i] = from_emitter._end_color[i]
            to_emitter._end_color_variance[i] = (
                from_emitter._end_color_variance[i])

    cdef int insert_effect_into_component(self, ParticleEmitter effect, 
        EmitterComponent py_component) except -1:
        cdef list emitters = py_component._emitters
        cdef EmitterStruct* pointer = <EmitterStruct*>py_component.pointer
        cdef int i
        used = 0
        for i in range(MAX_EMITTERS):
            if pointer.emitters[i] is NULL:
                pointer.emitters[i] = <void*>effect
                emitters[i] = effect
                used = i
                break
        else:
            raise TooManyEmitters('Change MAX_EMITTERS in'
                'particles_config.pxi to have more emitters per entity or'
                'use less emitters')
        return used

    def add_effect(self, unsigned int entity_id, str effect_name):
        cdef IndexedMemoryZone components = self.imz_components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef EmitterComponent py_component = self.components[component_index]
        return self.insert_effect_into_component(
            self.create_effect(effect_name), py_component)

    def remove_effect(self, unsigned int entity_id, int index):
        cdef IndexedMemoryZone components = self.imz_components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef EmitterComponent py_component = self.components[component_index]
        py_component._emitters[index] = None
        cdef EmitterStruct* pointer = <EmitterStruct*>py_component.pointer
        pointer.emitters[index] = NULL

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef EmitterStruct* pointer = <EmitterStruct*>(
            memory_zone.get_pointer(component_index))
        cdef EmitterComponent py_component = self.components[component_index]
        pointer.entity_id = -1
        py_component._emitters = [None for x in range(MAX_EMITTERS)]
        cdef int i
        for i in range(MAX_EMITTERS):
            pointer.emitters[i] = NULL
            

Factory.register('EmitterSystem', cls=EmitterSystem)
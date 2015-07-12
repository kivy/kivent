from xml.dom.minidom import parse as parse_xml
import json
from libc.math cimport trunc, sin, cos, fmin, fmax
from kivent_particles.emitter cimport ParticleEmitter
from kivent_core.systems.rotate_systems cimport RotateStruct2D
from kivent_core.systems.color_systems cimport ColorStruct
from kivent_core.systems.position_systems cimport PositionStruct2D
from kivent_core.systems.scale_systems cimport ScaleStruct2D
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)
from kivy.properties import (StringProperty, NumericProperty, ListProperty,
    BooleanProperty, ObjectProperty)
from kivy.factory import Factory
from kivent_core.memory_handlers.zone cimport MemoryZone

include "particle_math.pxi"
include "particle_config.pxi"
    

cdef class ParticleComponent(MemComponent):
    '''The component associated with ParticleSystem

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is 
        unattached.


    '''
    property entity_id:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.entity_id

    property current_time:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.current_time

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.current_time = value

    property total_time:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.total_time

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.total_time = value

    property start_x:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.start_pos[0]

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.start_pos[0] = value

    property start_y:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.start_pos[1]

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.start_pos[1] = value

    property start_pos:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return [data.start_pos[i] for i in range(2)]

        def __set__(self, value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointers
            for i in range(2):
                data.start_pos[i] = value[i]

    property velocity_x:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.velocity[0]

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.velocity[0] = value

    property velocity_y:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.velocity[1]

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.velocity[1] = value

    property velocity:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return [data.velocity[i] for i in range(2)]

        def __set__(self, value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            for i in range(2):
                data.velocity[i] = value[i]

    property radial_acceleration:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.radial_acceleration

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.radial_acceleration = value

    property tangential_acceleration:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.tangential_acceleration

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.tangential_acceleration = value

    property emit_radius:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.emit_radius

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.emit_radius = value

    property emit_radius_delta:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.emit_radius_delta

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.emit_radius_delta = value

    property rotation_delta:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.rotation_delta

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.rotation_delta = value

    property scale_delta:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return data.scale_delta

        def __set__(self, float value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            data.scale_delta = value

    property emitter:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return <ParticleEmitter>data.emitter

    property color_delta:

        def __get__(self):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            return [data.color_delta[i] for i in range(4)]

        def __set__(self, value):
            cdef ParticleStruct* data = <ParticleStruct*>self.pointer
            for i in range(4):
                data.color_delta[i] = value[i]


cdef class ParticleSystem(StaticMemGameSystem):
    system_id = StringProperty('particles')
    updateable = BooleanProperty(True)
    type_size = NumericProperty(sizeof(ParticleStruct))
    component_type = ObjectProperty(ParticleComponent)
    processor = BooleanProperty(True)
    system_names = ListProperty(['particles','position', 'rotate', 'scale',
        'color'])
    renderer_name = StringProperty('particles_renderer')
    particle_zone = StringProperty('particles')

    def __init__(self, **kwargs):
        super(ParticleSystem, self).__init__(**kwargs)
        self._system_names = [x for x in self.system_names]

    cdef int create_particle(self, ParticleEmitter emitter) except -1:
        cdef list system_names = self._system_names
        cdef str renderer_name = self.renderer_name
        create_dict = {
            system_names[0]: emitter,
            system_names[1]: (0., 0.),
            system_names[2]: 0.,
            system_names[3]: 0.,
            system_names[4]: (255, 255, 255, 255),
            renderer_name: {'texture': emitter._texture},
        }
        create_order = [system_names[1], system_names[2], system_names[3], 
                        system_names[4], system_names[0], renderer_name]
        self.gameworld.init_entity(create_dict, create_order, 
            zone=self.particle_zone)
        return 1

    def on_system_names(self, instance, value):
        self._system_names = [x for x in value]

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, ParticleEmitter emitter):
        '''
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ParticleStruct* pointer = <ParticleStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = entity_id
        pointer.emitter = <void*>emitter
        pointer.current_time = 0.0
        pointer.start_pos[0] = emitter._pos[0]
        pointer.start_pos[1] = emitter._pos[1]
        cdef float angle = random_variance(emitter._emit_angle, 
            emitter._emit_angle_variance)
        cdef float speed = random_variance(emitter._speed, 
            emitter._speed_variance)
        pointer.velocity[0] = speed * cos(angle)
        pointer.velocity[1] = speed * sin(angle)
        cdef float life_span = random_variance(emitter._life_span, 
            emitter._life_span_variance)
        while life_span <= 0.0:
            life_span = random_variance(emitter._life_span, 
                emitter._life_span_variance)
        pointer.total_time = life_span
        pointer.emit_radius = random_variance(emitter._max_radius, 
            emitter._max_radius_variance)
        pointer.emit_radius_delta = (emitter._max_radius - 
            emitter._min_radius) / life_span
        pointer.emit_rotation = angle
        pointer.emit_rotation_delta = random_variance(
            emitter._rotate_per_second, emitter._rotate_per_second_variance)
        pointer.radial_acceleration = random_variance(
            emitter._radial_acceleration, emitter._radial_acceleration_variance)
        pointer.tangential_acceleration = random_variance(
            emitter._tangential_acceleration, 
            emitter._tangential_acceleration_variance)
        cdef float start_scale = fmax(MIN_PARTICLE_SIZE, random_variance(
            emitter._start_scale, emitter._start_scale_variance))
        cdef float end_scale = fmax(MIN_PARTICLE_SIZE, random_variance(
            emitter._end_scale, emitter._end_scale_variance))
        pointer.scale_delta = (end_scale - start_scale) / life_span
        cdef unsigned char[4] start_color
        cdef unsigned char[4] end_color
        color_variance(emitter._start_color, emitter._start_color_variance, 
            start_color)
        color_variance(emitter._end_color, emitter._end_color_variance, 
            end_color)
        color_delta(start_color, end_color, pointer.color_delta, life_span)
        cdef float start_rotation = random_variance(emitter._start_rotation, 
            emitter._start_rotation_variance)
        cdef float end_rotation = random_variance(emitter._end_rotation, 
            emitter._end_rotation_variance)
        pointer.rotation_delta = (end_rotation - start_rotation) / life_span

        cdef unsigned int ent_comps_ind = self.entity_components.add_entity(
            entity_id, zone)
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int real_index = ent_comps_ind * component_count
        cdef PositionStruct2D* pos_comp = <PositionStruct2D*>component_data[
            real_index+1]
        cdef RotateStruct2D* rotate_comp = <RotateStruct2D*>component_data[
            real_index+2]
        cdef ScaleStruct2D* scale_comp = <ScaleStruct2D*>component_data[
            real_index+3]
        cdef ColorStruct* color_comp = <ColorStruct*>component_data[
            real_index+4]
 
        #write scale, color, position, and rotate data to components
        pos_comp.x = random_variance(emitter._pos[0], emitter._pos_variance[0])
        pos_comp.y = random_variance(emitter._pos[1], emitter._pos_variance[1])
        scale_comp.sx = start_scale
        scale_comp.sy = start_scale
        rotate_comp.r = start_rotation
        cdef int i
        for i in range(4):
            color_comp.color[i] = start_color[i]

    def remove_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ParticleStruct* pointer = <ParticleStruct*>memory_zone.get_pointer(
            component_index)
        self.entity_components.remove_entity(pointer.entity_id)
        super(ParticleSystem, self).remove_component(component_index)

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ParticleStruct* pointer = <ParticleStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        pointer.current_time = 0.
        pointer.total_time = 0.
        cdef int i 
        for i in range(2):
            pointer.start_pos[i] = 0.
            pointer.velocity[i] = 0.
        pointer.radial_acceleration = 0.
        pointer.tangential_acceleration = 0.
        pointer.emit_radius = 0.
        pointer.emit_radius_delta = 0.
        pointer.emit_rotation = 0.
        pointer.emit_rotation_delta = 0.
        pointer.rotation_delta = 0.
        pointer.scale_delta = 0.
        pointer.emitter = NULL
        for i in range(4):
            pointer.color_delta[i] = 0.

    def update(self, float dt):
        cdef ParticleEmitter emitter
        cdef float passed_time, total_time
        cdef float start_x, start_y
        cdef float current_x, current_y
        cdef float distance_x, distance_y
        cdef float distance_scalar
        cdef float radial_x, radial_y
        cdef float rad_accel
        cdef float tangential_x, tangential_y
        cdef float new_y
        cdef float tan_accel

        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index

        cdef ParticleStruct* particle_comp
        cdef PositionStruct2D* pos_comp
        cdef RotateStruct2D* rotate_comp
        cdef ScaleStruct2D* scale_comp
        cdef ColorStruct* color_comp

        gameworld = self.gameworld
        remove_entity = gameworld.remove_entity

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            particle_comp = <ParticleStruct*>component_data[real_index]
            pos_comp = <PositionStruct2D*>component_data[real_index+1]
            rotate_comp = <RotateStruct2D*>component_data[real_index+2]
            scale_comp = <ScaleStruct2D*>component_data[real_index+3]
            color_comp = <ColorStruct*>component_data[real_index+4]
            passed_time = fmin(dt, 
                particle_comp.total_time - particle_comp.current_time)
            emitter = <ParticleEmitter>particle_comp.emitter
            particle_comp.current_time += passed_time

            if emitter._emitter_type == EMITTER_TYPE_RADIAL:
                particle_comp.emit_rotation += (
                    particle_comp.emit_rotation_delta * passed_time)
                particle_comp.emit_radius -= (
                    particle_comp.emit_radius_delta * passed_time)
                pos_comp.x = (emitter._pos[0] - cos(
                    particle_comp.emit_rotation) * particle_comp.emit_radius)
                pos_comp.y = (emitter._pos[1] - sin(
                    particle_comp.emit_rotation) * particle_comp.emit_radius)

                if particle_comp.emit_radius < emitter._min_radius:
                    particle_comp.current_time = particle_comp.total_time
            else:
                start_x = particle_comp.start_pos[0]
                start_y = particle_comp.start_pos[1]
                current_x = pos_comp.x
                current_y = pos_comp.y
                distance_x = current_x - start_x
                distance_y = current_y - start_y
                distance_scalar = calc_distance(start_x, start_y, 
                    current_x, current_y)
                if distance_scalar < 0.01:
                    distance_scalar = 0.01
                radial_x = distance_x / distance_scalar
                radial_y = distance_y / distance_scalar
                tangential_x = radial_x
                tangential_y = radial_y
                rad_accel = particle_comp.radial_acceleration
                radial_x *= rad_accel
                radial_y *= rad_accel
                new_y = tangential_x
                tan_accel = particle_comp.tangential_acceleration
                tangential_x = -tangential_y * tan_accel
                tangential_y = new_y * tan_accel
                particle_comp.velocity[0] += passed_time * (
                    emitter._gravity[0] + radial_x + tangential_x)
                particle_comp.velocity[1] += passed_time * (
                    emitter._gravity[1] + radial_y + tangential_y)
                pos_comp.x += particle_comp.velocity[0] * passed_time
                pos_comp.y += particle_comp.velocity[1] * passed_time

            scale_comp.sx += particle_comp.scale_delta * passed_time
            scale_comp.sy += particle_comp.scale_delta * passed_time
            rotate_comp.r += particle_comp.rotation_delta * passed_time
            color_integrate(color_comp.color, particle_comp.color_delta, 
                color_comp.color, passed_time)
            if particle_comp.current_time >= particle_comp.total_time:
                emitter._current_particles -= 1
                remove_entity(particle_comp.entity_id)



Factory.register('ParticleSystem', cls=ParticleSystem)

# cdef class ParticleManager:
#     cdef int _max_particles
#     cdef int _taken
#     cdef list _emitters
#     cdef dict _emitter_configs
#     cdef void** _particle_data
#     cdef void** _position_data
#     cdef void** _rotate_data
#     cdef void** _scale_data
#     cdef void** _color_data
#     cdef void** _render_data
#     cdef object _gameworld
#     cdef str _renderer_name
#     cdef str _particles_name
#     cdef int* _entity_ids

#     def __cinit__(self, int max_particles, object gameworld, 
#         str renderer_name, str particles_name):
#         self._max_particles = max_particles
#         self._gameworld = gameworld
#         self._renderer_name = renderer_name
#         self._particles_name = particles_name
#         self._taken = 0
#         self._emitters = []
#         self._emitter_configs = {}
#         self._particle_data = particle_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not particle_data:
#             raise MemoryError()
#         self._position_data = position_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not position_data:
#             raise MemoryError()
#         self._rotate_data = rotate_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not rotate_data:
#             raise MemoryError()
#         self._scale_data = scale_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not scale_data:
#             raise MemoryError()
#         self._color_data = color_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not color_data:
#             raise MemoryError()
#         self._render_data = render_data = <void **>PyMem_Malloc(
#             max_particles * sizeof(void *))
#         if not render_data:
#             raise MemoryError()
#         self._entity_ids = entity_ids = <int *>PyMem_Malloc(max_particles *
#             sizeof(int))
#         if not entity_ids:
#             raise MemoryError()
#         cdef list entities = gameworld.entities
#         cdef object entity
#         cdef int ind
#         cdef int ent_id
#         for ind in range(max_particles):
#             ent_id = self.create_particle(ind)
#             entity = entities[ent_id]
#             self.add_particle(ind, entity)

#     def __dealloc__(self):
#         if self._particle_data != NULL:
#             PyMem_Free(self._particle_data)
#         if self._position_data != NULL:
#             PyMem_Free(self._position_data)
#         if self._rotate_data != NULL:
#             PyMem_Free(self._rotate_data)
#         if self._scale_data != NULL:
#             PyMem_Free(self._scale_data)
#         if self._color_data != NULL:
#             PyMem_Free(self._color_data)
#         if self._render_data != NULL:
#             PyMem_Free(self._render_data)
#         if self._entity_ids != NULL:
#             PyMem_Free(self._entity_ids)

#     cdef void resize_max_particles(self, int new_max):
#         cdef int old_max = self._max_particles
#         cdef int count = new_max - old_max
#         cdef int ind
#         cdef int entity_id
#         cdef int ent_id
#         cdef object entity
#         cdef object gameworld = self._gameworld
#         cdef list entities = gameworld.entities
#         remove_entity = gameworld.remove_entity
#         cdef void** particle_data = self._particle_data
#         cdef void** position_data = self._position_data
#         cdef void** rotate_data = self._rotate_data
#         cdef void** scale_data = self._scale_data
#         cdef void** color_data = self._color_data
#         cdef void** render_data = self._render_data
#         cdef int* entity_ids = self._entity_ids
#         if count < 0:
#             for ind in range(old_max + count, old_max):
#                 entity_id = entity_ids[ind]
#                 remove_entity(entity_id)
#         self._particle_data = particle_data = <void **>PyMem_Realloc(
#             particle_data, new_max * sizeof(void *))
#         if not particle_data:
#             raise MemoryError()
#         self._position_data = position_data = <void **>PyMem_Realloc(
#             position_data, new_max * sizeof(void *))
#         if not position_data:
#             raise MemoryError()
#         self._rotate_data = rotate_data = <void **>PyMem_Realloc(
#             rotate_data, new_max * sizeof(void *))
#         if not rotate_data:
#             raise MemoryError()
#         self._scale_data = scale_data = <void **>PyMem_Realloc(
#             scale_data, new_max * sizeof(void *))
#         if not scale_data:
#             raise MemoryError()
#         self._color_data = color_data = <void **>PyMem_Realloc(
#             color_data, new_max * sizeof(void *))
#         if not color_data:
#             raise MemoryError()
#         self._render_data = render_data = <void **>PyMem_Realloc(
#             render_data, new_max * sizeof(void *))
#         if not render_data:
#             raise MemoryError()
#         self._entity_ids = entity_ids = <int *>PyMem_Realloc(entity_ids, 
#             new_max * sizeof(int))
#         if not entity_ids:
#             raise MemoryError()
#         if count > 0:
#             for ind in range(old_max, old_max+count):
#                 ent_id = self.create_particle(ind)
#                 entity = entities[ent_id]
#                 self.add_particle(ind, entity)

#     cdef void swap_particles_in_memory(self, int from_position, 
#         int to_position):
#         cdef void** particle_data = self._particle_data
#         cdef void** position_data = self._position_data
#         cdef void** rotate_data = self._rotate_data
#         cdef void** scale_data = self._scale_data
#         cdef void** color_data = self._color_data
#         cdef void** render_data = self._render_data
#         cdef int* entity_ids = self._entity_ids
#         cdef void* temp_particle = particle_data[from_position]
#         cdef void* temp_pos = position_data[from_position]
#         cdef void* temp_rotate = rotate_data[from_position]
#         cdef void* temp_scale = scale_data[from_position]
#         cdef void* temp_color = color_data[from_position]
#         cdef void* temp_render = render_data[from_position]
#         temp_render._render = False
#         cdef ParticleComponent from_part = <ParticleComponent>temp_particle
#         cdef ParticleComponent to_part = <ParticleComponent>particle_data[
#             to_position]
#         cdef int temp_ent_id = entity_ids[from_position]
#         from_part._index = to_position
#         to_part._index = from_position
#         particle_data[from_position] = particle_data[to_position]
#         particle_data[to_position] = temp_particle
#         position_data[from_position] = position_data[to_position]
#         particle_data[to_position] = temp_pos
#         rotate_data[from_position] = rotate_data[to_position]
#         rotate_data[to_position] = temp_rotate
#         scale_data[from_position] = scale_data[to_position]
#         scale_data[to_position] = temp_scale
#         color_data[from_position] = color_data[to_position]
#         color_data[to_position] = temp_color
#         render_data[from_position] =  render_data[to_position]
#         render_data[to_position] = temp_render
#         entity_ids[from_position] = entity_ids[to_position]
#         entity_ids[to_position] = temp_ent_id

#     cdef void _expire_particle(self, int index):
#         cdef int last_particle_ind = self._taken - 1
#         self.swap_particles_in_memory(index, last_particle_ind)
#         self._taken -= 1

#     cdef int create_particle(self, int index):
#         cdef str renderer_id = self._renderer_name
#         cdef str particles_name = self._particles_name

#         cdef dict create_component_dict = {
#             renderer_id: {
#                 'texture': None, 
#                 'size': (64, 64),
#                 'render': False,}, 
#             'position': (0, 0), 'rotate': 0, 
#             'color': (1., 1., 1., 1.),
#             particles_name: index}
#         cdef list component_order = ['position', 'rotate', 'color',
#             renderer_id, particles_name]
#         return self.gameworld.init_entity(create_component_dict, 
#             component_order)

#     cdef init_particle(self, int index, ParticleEmitter emitter):
#         cdef EmitterConfig ec = emitter._emitter_config
#         cdef float life_span = random_variance(emitter._life_span, 
#             ec._life_span_variance)

#         if life_span <= 0.0:
#             return self.init_particle(index, emitter)
#         cdef float x = emitter._x
#         cdef float y = emitter._y
#         cdef void** particle_data = self._particle_data
#         cdef ParticleComponent particle_comp = (
#             <ParticleComponent>particle_data[index])
#         particle_comp._current_time = 0.0
#         particle_comp._total_time = life_span
#         particle_comp._start_x = x
#         particle_comp._start_y = y
#         cdef float angle = random_variance(emitter._emit_angle, 
#             ec._emit_angle_variance)
#         cdef float speed = random_variance(ec._speed, ec._speed_variance)
#         particle_comp._velocity_x = speed * cos(angle)
#         particle_comp._velocity_y = speed * sin(angle)
#         particle_comp._emit_radius = random_variance(ec.max_radius, 
#             ec.max_radius_variance)
#         particle_comp._emit_radius_delta = (ec._max_radius - 
#             ec._min_radius) / life_span

#         particle_comp._emit_rotation = random_variance(emitter._emit_angle, 
#             ec._emit_angle_variance)
#         particle_comp._emit_rotation_delta = random_variance(
#             ec._rotate_per_second, ec._rotate_per_second_variance)

#         particle_comp._radial_acceleration = random_variance(
#             ec._radial_acceleration, ec._radial_acceleration_variance)
#         particle_comp._tangent_acceleration = random_variance(
#             ec._tangential_acceleration, ec._tangential_acceleration_variance)
#         cdef float start_scale = random_variance(ec._start_scale, 
#             ec._start_scale_variance)
#         cdef float end_scale = random_variance(ec._end_scale, 
#             ec._end_scale_variance)
#         start_scale = fmax(0.1, start_scale)
#         end_scale = fmax(0.1, end_scale)
#         particle_comp._scale_delta = ((end_scale - start_scale) / life_span) / 2.

#         # colors
#         cdef KEColor start_color = random_color_variance(ec._start_color, 
#             ec._start_color_variance)
#         cdef KEColor end_color = random_color_variance(ec._end_color, 
#             ec._end_color_variance)

#         particle_comp._color_delta = color_delta(
#             start_color, end_color, life_span)

#         # rotation
#         cdef float start_rotation = random_variance(ec.start_rotation, 
#             ec.start_rotation_variance)
#         cdef float end_rotation = random_variance(ec.end_rotation, 
#             ec.end_rotation_variance)
#         particle_comp._rotation_delta = (
#             end_rotation - start_rotation) / life_span
#         cdef void** position_data = self._position_data
#         cdef void** rotate_data = self._rotate_data
#         cdef void** scale_data = self._scale_data
#         cdef void** color_data = self._color_data
#         cdef void** render_data = self._render_data
#         cdef PositionComponent pos_comp = (
#             <PositionComponent>position_data[index])
#         cdef RotateComponent rot_comp = <RotateComponent>rotate_data[index]
#         cdef ScaleComponent scale_comp = <ScaleComponent>scale_data[index]
#         cdef ColorComponent color_comp = <ColorComponent>color_data[index]
#         pos_comp._x = random_variance(x, ec._emitter_x_variance)
#         pos_comp._y = random_variance(y, ec._emitter_y_variance)
#         scale_comp._s = start_scale / 2.
#         rot_comp._r = start_rotation
#         color_comp._r = start_color.r
#         color_comp._g = start_color.g
#         color_comp._b = start_color.b
#         color_comp._a = start_color.a
#         #update texcoords in vertmesh, rebatch

#     cdef void add_emitter(self, ParticleEmitter emitter):
#         cdef list emitters = self._emitters
#         emitters.append(emitter)

#     cdef void remove_emitter(self, ParticleEmitter emitter):
#         cdef list emitters = self._emitters
#         emitters.remove(emitter)

#     cdef void _update_particles(self, float dt):
#         cdef int number_of_particles = self._taken
#         cdef int i
#         cdef ParticleComponent particle_comp
#         cdef RotateComponent rot_comp
#         cdef ScaleComponent scale_comp
#         cdef PositionComponent pos_comp
#         cdef RenderComponent render_comp
#         cdef ColorComponent color_comp
#         cdef void** particle_data = self._particle_data
#         cdef void** position_data = self._position_data
#         cdef void** rotate_data = self._rotate_data
#         cdef void** scale_data = self._scale_data
#         cdef void** color_data = self._color_data
#         cdef void** render_data = self._render_data
#         cdef EmitterConfig ec
#         cdef ParticleEmitter emitter
#         cdef float passed_time, total_time
#         cdef float start_x, start_y
#         cdef float current_x, current_y
#         cdef float distance_x, distance_y
#         cdef float distance_scalar
#         cdef float radial_x, radial_y
#         cdef float rad_accel
#         cdef float tangential_x, tangential_y
#         cdef float new_y
#         cdef float tan_accel

#         for i in range(number_of_particles):
#             particle_comp = <ParticleComponent>particle_data[i]
#             pos_comp = <PositionComponent>position_data[i]
#             rot_comp = <RotateComponent>rotate_data[i]
#             scale_comp = <ScaleComponent>scale_data[i]
#             render_comp = <RenderComponent>render_data[i]
#             color_comp = <ColorComponent>color_data[i]
#             total_time = particle_comp._total_time
#             passed_time = fmin(dt, total_time - particle_comp._current_time)

#             emitter = <ParticleEmitter>particle_comp._emitter_ptr
#             ec = emitter._emitter_config
#             particle_comp._current_time += passed_time
#             if emitter._emitter_type == EMITTER_TYPE_RADIAL:
#                 particle_comp._emit_rotation += (
#                     particle_comp._emit_rotation_delta * passed_time)
#                 particle_comp._emit_radius -= (
#                     particle_comp._emit_radius_delta * passed_time)
#                 pos_comp._x = (emitter._x - cos(
#                     particle_comp._emit_rotation) * particle_comp._emit_radius)
#                 pos_comp._y = (emitter._y - sin(
#                     particle_comp._emit_rotation) * particle_comp._emit_radius)

#                 if particle_comp._emit_radius < ec._min_radius:
#                     particle_comp._current_time = particle_comp._total_time
#             else:
#                 start_x = particle_comp._start_x
#                 start_y = particle_comp._start_y
#                 current_x = pos_comp._x
#                 current_y = pos_comp._y
#                 distance_x = current_x - start_x
#                 distance_y = current_y - start_y
#                 distance_scalar = calc_distance(start_x, start_y, 
#                     current_x, current_y)
#                 if distance_scalar < 0.01:
#                     distance_scalar = 0.01
#                 radial_x = distance_x / distance_scalar
#                 radial_y = distance_y / distance_scalar
#                 tangential_x = radial_x
#                 tangential_y = radial_y
#                 rad_accel = particle_comp._radial_acceleration
#                 radial_x *= rad_accel
#                 radial_y *= rad_accel
#                 new_y = tangential_x
#                 tan_accel = particle_comp._tangent_acceleration
#                 tangential_x = -tangential_y * tan_accel
#                 tangential_y = new_y * tan_accel
#                 particle_comp._velocity_x += passed_time * (ec._gravity_x + 
#                     radial_x + tangential_x)
#                 particle_comp._velocity_y += passed_time * (ec._gravity_y + 
#                     radial_y + tangential_y)
#                 pos_comp._x += particle_comp._velocity_x * passed_time
#                 pos_comp._y += particle_comp._velocity_y * passed_time

#             scale_comp._s += particle_comp._scale_delta * passed_time
#             rot_comp._r += particle_comp._rotation_delta * passed_time
#             color_d = particle_comp._color_delta
#             color_comp._r = color_comp._r + color_d.r * passed_time
#             color_comp._g = color_comp._g + color_d.g * passed_time
#             color_comp._b = color_comp._b + color_d.b * passed_time
#             color_comp._a = color_comp._a + color_d.a * passed_time
#             if particle_comp._current_time >= total_time:
#                 self._expire_particle(particle_comp._index)


#     cdef void add_particle(self, int index, object entity):
#         cdef void** particle_data = self._particle_data
#         cdef void** position_data = self._position_data
#         cdef void** rotate_data = self._rotate_data
#         cdef void** scale_data = self._scale_data
#         cdef void** color_data = self._color_data
#         cdef void** render_data = self._render_data
#         cdef int* entity_ids = self._entity_ids
#         cdef str particles_name = self._particles_name
#         cdef str renderer_name = self._renderer_name
#         cdef int entity_id = entity.entity_id
#         cdef PositionComponent position = entity.position
#         cdef RotateComponent rotate = entity.rotate
#         cdef ScaleComponent scale = entity.scale
#         cdef ColorComponent color = entity.color
#         cdef RenderComponent renderer = getattr(entity, renderer_name)
#         cdef ParticleComponent particle = getattr(entity, particles_name)
#         position_data[index] = <void *>position
#         rotate_data[index] = <void *>rotate
#         scale_data[index] = <void *>scale
#         color_data[index] = <void *>color
#         render_data[index] = <void *>renderer
#         particle_data[index] = <void *>particle
#         entity_ids[index] = entity_id


#     property max_particles:
#         def __get__(self):
#             return self._max_particles
#         def __set__(self, int new_number):
#             self._max_particles = new_number
#             self.resize_particles(new_number)

    # property current_number_of_particles:
    #     def __get__(self):
    #         return self.current_number_of_particles
    #     def __set__(self, int new_number):
    #         self.current_number_of_particles = new_number

    # property particles:
    #     def __get__(self):
    #         particles = <KEParticle *>self.particles_ptr
    #         return_dict = {}
    #         for x in range(self.max_particles):
    #             particle = particles[x]
    #             ri = particle.render_info
    #             return_dict[x] = {'x': ri.x, 'y': ri.y, 
    #                 'id': particle.particle_id}
    #         return return_dict

    # property emitters:
    #     def __get__(self):
    #         return self.emitters

    # property particle_configs:
    #     def __get__(self):
    #         return self.particle_configs



    # cdef _init_particle(self, void* emitter_ptr):
    #     taken = self.taken
    #     if taken < self.max_particles:
    #         particles = <KEParticle *>self.particles_ptr
    #         particle_to_init = particles[taken]
    #         particles[taken] = init_particle(particle_to_init, emitter_ptr, taken)
    #         self.taken += 1
    #     else: 
    #         pass



    # cdef KEParticle init_particle(object particle_entity, void* emitter_ptr, int p_id):
    #     emitter = <KEParticleEmitter>emitter_ptr
    #     particle.emitter_ptr = emitter_ptr
    #     ec = <EmitterConfig>emitter.emitter_config
    #     render_info = particle.render_info
    #     cdef float life_span = random_variance(emitter.life_span, 
    #         ec.life_span_variance)
    #     if life_span <= 0.0:
    #         return init_particle(particle, emitter_ptr, p_id)
    #     x, y = emitter.x, emitter.y
    #     particle.current_time = 0.0
    #     particle.total_time = life_span
    #     particle.particle_id = p_id
    #     particle.start_x = x
    #     particle.start_y = y
    #     cdef float angle = random_variance(emitter.emit_angle, 
    #         ec.emit_angle_variance)
    #     cdef float speed = random_variance(ec.speed, ec.speed_variance)
    #     particle.velocity_x = speed * cos(angle)
    #     particle.velocity_y = speed * sin(angle)
    #     particle.emit_radius = random_variance(ec.max_radius, 
    #         ec.max_radius_variance)
    #     particle.emit_radius_delta = (ec.max_radius - 
    #         ec.min_radius) / life_span

    #     particle.emit_rotation = random_variance(emitter.emit_angle, 
    #         ec.emit_angle_variance)
    #     particle.emit_rotation_delta = random_variance(ec.rotate_per_second, 
    #         ec.rotate_per_second_variance)

    #     particle.radial_acceleration = random_variance(
    #         ec.radial_acceleration, 
    #         ec.radial_acceleration_variance)
    #     particle.tangent_acceleration = random_variance(
    #         ec.tangential_acceleration, 
    #         ec.tangential_acceleration_variance)
    #     cdef float start_scale = random_variance(ec.start_scale, 
    #         ec.start_scale_variance)
    #     cdef float end_scale = random_variance(ec.end_scale, 
    #         ec.end_scale_variance)
    #     start_scale = max(0.1, start_scale)
    #     end_scale = max(0.1, end_scale)
    #     particle.scale_delta = ((end_scale - start_scale) / life_span) / 2.

    #     # colors
    #     cdef KEColor start_color = random_color_variance(ec.start_color, 
    #         ec.start_color_variance)
    #     cdef KEColor end_color = random_color_variance(ec.end_color, 
    #         ec.end_color_variance)

    #     particle.color_delta = color_delta(start_color, end_color, life_span)

    #     # rotation
    #     cdef float start_rotation = random_variance(ec.start_rotation, 
    #         ec.start_rotation_variance)
    #     cdef float end_rotation = random_variance(ec.end_rotation, 
    #         ec.end_rotation_variance)

    #     particle.rotation_delta = (end_rotation - start_rotation) / life_span
    #     render_info.x = random_variance(x, ec.emitter_x_variance)
    #     render_info.y = random_variance(y, ec.emitter_y_variance)
    #     render_info.scale = start_scale / 2.
    #     render_info.rotation = start_rotation
    #     render_info.color = start_color
    #     render_info.tex_info = ec.tex_info
    #     particle.render_info = render_info
    #     return particle

# class ParticleSystem(GameSystems):
#     max_particles = NumericProperty(1000)
#     taken = NumericProperty(0)

#     def __init__(self, **kwargs):
#         self.particles_ptr = particles_ptr = <void *>malloc(
#             sizeof(KEParticle) * max_particles)
#         if not particles_ptr:
#             raise MemoryError()
#         self.emitters = []
#         self.emitter = emitter = KEParticleEmitter()
#         self.max_particles = max_particles
#         self.taken = 0
#         self.particle_configs = {}
#         self.emitters = []
#         self.resize_particles(max_particles)


#     def get_emitter(self):
#         return KEParticleEmitter()

#     def update(self, float dt):
#         cdef list emitters = self.emitters
#         cdef KEParticleEmitter emitter
#         for emitter in emitters:
#             emitter_ptr = <void *>emitter
#             if not emitter.paused:
#                 emitter.frame_time += dt
#                 time_between_particles = (
#                     1.0 / emitter.emission_rate)
#                 number_of_updates = trunc(
#                     emitter.frame_time / time_between_particles)
#                 emitter.frame_time -= (
#                     time_between_particles * number_of_updates)
#                 for x in range(int(number_of_updates)):
#                     self._init_particle(emitter_ptr)
#         self._update_particles(dt)

#     def add_emitter(self, KEParticleEmitter emitter):
#         self.emitters.append(emitter)

#     def remove_emitter(self, KEParticleEmitter emitter):
#         self.emitters.remove(emitter)



#     def resize_particles(self, int number_of_particles):
#         new_size = sizeof(KEParticle) * number_of_particles
#         new_ptr = <void *>realloc(self.particles_ptr, new_size)
#         particles = <KEParticle *>new_ptr
#         for x in range(number_of_particles):
#             particles[x] = KEParticle()
#         self.particles_ptr = new_ptr
#         self.taken = 0






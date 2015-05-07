from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivy.factory import Factory
from kivy.properties import (ObjectProperty, NumericProperty, ListProperty, 
    BooleanProperty, StringProperty)
from kivent_core.systems.position_systems cimport PositionStruct2D


cdef class VelocityComponent2D(MemComponent):

    property entity_id:
        def __get__(self):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            return data.entity_id

    property vx:
        def __get__(self):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            return data.vx
        def __set__(self, float value):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            data.vx = value

    property vy:
        def __get__(self):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            return data.vy
        def __set__(self, float value):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            data.vy = value

    property vel:
        def __get__(self):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            return (data.vx, data.vy)
        def __set__(self, tuple new_vel):
            cdef VelocityStruct2D* data = <VelocityStruct2D*>self.pointer
            data.vx = new_vel[0]
            data.vy = new_vel[1]


cdef class VelocitySystem2D(StaticMemGameSystem):
    system_id = StringProperty('velocity')
    processor = BooleanProperty(True)
    type_size = NumericProperty(sizeof(VelocityStruct2D))
    component_type = ObjectProperty(VelocityComponent2D)
    system_names = ListProperty(['velocity','position'])
        
    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, args):
        cdef float vx = args[0]
        cdef float vy = args[1]
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef VelocityStruct2D* component = <VelocityStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.vx = vx
        component.vy = vy
        return self.entity_components.add_entity(entity_id, zone)

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef VelocityStruct2D* pointer = <VelocityStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.vx = 0.
        pointer.vy = 0.

    def remove_component(self, unsigned int component_index):
        cdef VelocityComponent2D component = self.components[component_index]
        self.entity_components.remove_entity(component.entity_id)
        super(VelocitySystem2D, self).remove_component(component_index)

    def update(self, dt):
        gameworld = self.gameworld
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index
        cdef PositionStruct2D* pos_comp
        cdef VelocityStruct2D* vel_comp

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            vel_comp = <VelocityStruct2D*>component_data[real_index]
            pos_comp = <PositionStruct2D*>component_data[real_index+1]
            pos_comp.x += vel_comp.vx * dt
            pos_comp.y += vel_comp.vy * dt
 

Factory.register('VelocitySystem2D', cls=VelocitySystem2D)
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty

cdef class RotateComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            return data.entity_id

    property r:
        def __get__(self):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            return data.r
        def __set__(self, float value):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            data.r = value


cdef class RotateSystem2D(StaticMemGameSystem):
    '''RotateSystem is optimized to hold a single rotate float for your 
    entities, suitable for handling 2d rotations of sprites. 
    The CymunkPhysics System and Renderers expect this to be an 
    angle in radians.
    '''
    type_size = NumericProperty(sizeof(RotateStruct2D))
    component_type = ObjectProperty(RotateComponent2D)

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, float r):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RotateStruct2D* component = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.r = r

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RotateStruct2D* pointer = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.r = 0.



Factory.register('RotateSystem2D', cls=RotateSystem2D)
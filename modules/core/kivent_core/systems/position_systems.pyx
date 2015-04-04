from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty


cdef class PositionComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.entity_id

    property x:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.x
        def __set__(self, float value):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            data.x = value

    property y:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.y
        def __set__(self, float value):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            data.y = value

    property pos:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return (data.x, data.y)


cdef class PositionSystem2D(StaticMemGameSystem):
    '''PositionSystem is optimized to hold location data for your entities.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects.'''
    type_size = NumericProperty(sizeof(PositionStruct2D))
    component_type = ObjectProperty(PositionComponent2D)
        
    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, args):
        cdef float x = args[0]
        cdef float y = args[1]
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef PositionStruct2D* component = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.x = x
        component.y = y

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef PositionStruct2D* pointer = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.x = 0.
        pointer.y = 0.


Factory.register('PositionSystem2D', cls=PositionSystem2D)
from staticmemgamesystem cimport StaticMemGameSystem
from kivent_core.memory_handlers.indexing cimport MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory


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
        
    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        cdef float x = args[0]
        cdef float y = args[1]
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef PositionStruct2D* component = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.x = x
        component.y = y

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef PositionStruct2D* pointer = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.x = 0.
        pointer.y = 0.

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(PositionStruct2D), 
            reserve_spec, PositionComponent2D)


Factory.register('PositionSystem2D', cls=PositionSystem2D)
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty


cdef class ScaleComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.entity_id

    property s:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return (data.sx + data.sy)/2.
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sx = value
            data.sy = value

    property sx:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.sx
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sx = value

    property sy:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.sy
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sy = value


cdef class ScaleSystem2D(StaticMemGameSystem):
    '''ScaleSystem is optimized to hold 2d scale data for your entities.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects. This object will
    potentially change in the future to support scaling at different
    rates in different directions.'''
    type_size = NumericProperty(sizeof(ScaleStruct2D))
    component_type = ObjectProperty(ScaleComponent2D)

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, args):
        cdef float sx, sy
        if isinstance(args, tuple):
            sx = args[0]
            sy = args[1]
        else:
            sx = args
            sy = args
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ScaleStruct2D* component = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.sx = sx
        component.sy = sy

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ScaleStruct2D* pointer = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.sx = 1.
        pointer.sy = 1.


Factory.register('ScaleSystem2D', cls=ScaleSystem2D)
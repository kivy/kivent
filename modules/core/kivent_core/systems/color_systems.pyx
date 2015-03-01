from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty


cdef class ColorComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.entity_id

    property r:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.r
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.r = value

    property g:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.g
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.g = value

    property b:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.b
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.b = value

    property a:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.a
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.a = value


cdef class ColorSystem(StaticMemGameSystem):
    '''ColorSystem holds r,g,b,a that will be applied to the whole model
    of the Entity using renderers that apply to 
    '''
    type_size = NumericProperty(sizeof(ColorStruct))
    component_type = ObjectProperty(ColorComponent)

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        cdef float r = args[0]
        cdef float g = args[1]
        cdef float b = args[2]
        cdef float a = args[3]
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ColorStruct* component = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        component.entity_id = entity_id
        component.r = r
        component.g = g
        component.b = b
        component.a = a

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ColorStruct* pointer = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        pointer.r = 1.
        pointer.g = 1.
        pointer.b = 1.
        pointer.a = 1.


Factory.register('ColorSystem', cls=ColorSystem)
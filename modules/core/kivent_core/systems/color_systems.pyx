from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty


cdef class ColorComponent(MemComponent):
    '''The component associated with ColorSystem.

    **Attributes:**

        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is 
        unattached.

        **r** (float): The red channel, 0.0 to 1.0.

        **g** (float): The green channel, 0.0 to 1.0.

        **b** (float): The blue channel, 0.0 to 1.0.

        **a** (float): The alpha channel, 0.0 to 1.0.
    '''

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
    '''ColorSystem abstracts color data out into its own system so that all 
    other GameSystem can interact with the color of an Entity without having to 
    know about whatever system is controlling the actual color the entity. It 
    is suitable for controlling a color that is applied over the whole model 
    of an entity tinting its texture or coloring every vertex.

    This GameSystem does no processing of its own, just holding data.
    '''
    type_size = NumericProperty(sizeof(ColorStruct))
    component_type = ObjectProperty(ColorComponent)

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, args):
        '''A color component is always initialized with a tuple (r, g, b, a).
        '''
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
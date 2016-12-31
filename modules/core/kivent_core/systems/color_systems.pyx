# cython: embedsignature=True
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty, StringProperty


cdef class ColorComponent(MemComponent):
    '''The component associated with ColorSystem.

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is
        unattached.

        **r** (unsigned char): The red channel, 0 to 255.

        **g** (unsigned char): The green channel, 0 to 255.

        **b** (unsigned char): The blue channel, 0 to 255.

        **a** (unsigned char): The alpha channel, 0 to 255.

        **rgba** (tuple): 4-tuple of unsigned ints (r,g,b,a)

        **rgb** (tuple): 3-tuple of unsigned ints (r,g,b)
    '''

    property entity_id:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.entity_id

    property r:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.color[0]
        def __set__(self, unsigned char value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.color[0] = value

    property g:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.color[1]
        def __set__(self, unsigned char value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.color[1] = value

    property b:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.color[2]
        def __set__(self, unsigned char value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.color[2] = value

    property a:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.color[3]
        def __set__(self, unsigned char value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.color[3] = value

    property rgba:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return (data.color[0], data.color[1], data.color[2], data.color[3])
        def __set__(self, tuple value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            cdef int i
            for i in range(4):
                data.color[i] = value[i]

    property rgb:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return (data.color[0], data.color[1], data.color[2])
        def __set__(self, tuple value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            cdef int i
            for i in range(3):
                data.color[i] = value[i]


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
    system_id = StringProperty('color')

    def init_component(self, unsigned int component_index,
        unsigned int entity_id, str zone, args):
        '''A color component is always initialized with a tuple (r, g, b, a).
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ColorStruct* component = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        component.entity_id = entity_id
        cdef int i
        for i in range(4):
            component.color[i] = args[i]

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ColorStruct* pointer = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        cdef int i
        for i in range(4):
            pointer.color[i] = 255


Factory.register('ColorSystem', cls=ColorSystem)

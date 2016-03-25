# cython: embedsignature=True
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty, StringProperty


cdef class PositionComponent2D(MemComponent):
    '''The component associated with PositionSystem2D.

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is
        unattached.

        **x** (float): The x position of the center of the entity.

        **y** (float): The y position of the center of the entity.

        **pos** (tuple): A tuple of the (x, y) position.
    '''

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
        def __set__(self, tuple new_pos):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            data.x = new_pos[0]
            data.y = new_pos[1]


cdef class PositionSystem2D(StaticMemGameSystem):
    '''
    PositionSystem2D abstracts 2 dimensional position data out into its own
    system so that all other GameSystem can interact with the position of an
    Entity without having to know specifically about dependent systems such as
    the CymunkPhysics system or any other method of determining the actual
    position. This GameSystem does no processing of its own, just holding data.
    '''
    type_size = NumericProperty(sizeof(PositionStruct2D))
    component_type = ObjectProperty(PositionComponent2D)
    system_id = StringProperty('position')

    def init_component(self, unsigned int component_index,
        unsigned int entity_id, str zone, args):
        '''A PositionComponent2D is initialized with an args tuple of (x, y).
        '''
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

# cython: embedsignature=True
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty, StringProperty

cdef class RotateComponent2D(MemComponent):
    '''The component associated with RotateSystem2D.

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is
        unattached.

        **r** (float): The rotation around center of the entity.
    '''

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
    '''
    RotateSystem2D abstracts 2 dimensional rotation data out into its own
    system so that all other GameSystem can interact with the rotation of an
    Entity without having to know specifically about dependent systems such as
    the CymunkPhysics system or any other method of determining the actual
    rotation. This GameSystem does no processing of its own, just holding data.

    Typically other GameSystems will interpret this rotation as being a
    rotation around the center of the entity.
    '''
    type_size = NumericProperty(sizeof(RotateStruct2D))
    component_type = ObjectProperty(RotateComponent2D)
    system_id = StringProperty('rotate')

    def init_component(self, unsigned int component_index,
        unsigned int entity_id, str zone, float r):
        '''A RotateComponent2D is always initialized with a single float
        representing a rotation in degrees.
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef RotateStruct2D* component = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.r = r

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef RotateStruct2D* pointer = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.r = 0.


Factory.register('RotateSystem2D', cls=RotateSystem2D)

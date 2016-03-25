# cython: embedsignature=True
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import ObjectProperty, NumericProperty, StringProperty


cdef class ScaleComponent2D(MemComponent):
    '''The component associated with ScaleSystem2D.

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is
        unattached.

        **s** (float): The arithmetic average of the x scale and y scale, when
        set the x scale and y scale will be set to the value provided. Useful
        if you want uniform scaling in both axes.

        **sx** (float): The x axis scaling of the entity.

        **sy** (float): The y axis scaling of the entity.
    '''

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
    '''
    ScaleSystem2D abstracts 2 dimensional scale data out into its own
    system so that all other GameSystem can interact with the scale factor of
    an Entity without having to know specifically about dependent systems
    actually controlling the scale. This GameSystem does no processing of its
    own, just holding data.
    '''
    system_id = StringProperty('scale')
    type_size = NumericProperty(sizeof(ScaleStruct2D))
    component_type = ObjectProperty(ScaleComponent2D)

    def init_component(self, unsigned int component_index,
        unsigned int entity_id, str zone, args):
        '''A ScaleComponent2D can be initialized with either a separate
        scaling factor for x axis and y axis or a single scaling factor for
        both. If args is a tuple sx will be args[0] and sy will be args[1],
        otherwise sx = sy = args.
        '''
        cdef float sx, sy
        if isinstance(args, tuple):
            sx = args[0]
            sy = args[1]
        else:
            sx = args
            sy = args
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ScaleStruct2D* component = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.sx = sx
        component.sy = sy

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ScaleStruct2D* pointer = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.sx = 1.
        pointer.sy = 1.


Factory.register('ScaleSystem2D', cls=ScaleSystem2D)

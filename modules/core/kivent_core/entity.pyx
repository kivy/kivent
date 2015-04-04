from kivent_core.systems.staticmemgamesystem cimport MemComponent
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone


cdef class Entity(MemComponent):
    '''Entity is a python object that will hold all of the components
    attached to that particular entity. GameWorld is responsible for creating
    and recycling entities. You should never create an Entity directly or 
    modify an entity_id.
    
    **Attributes:**
        **entity_id** (int): The entity_id will be assigned on creation by the
        GameWorld. You will use this number to refer to the entity throughout
        your Game. 

        **load_order** (list): The load order is the order in which GameSystem
        components should be initialized.


    '''
    def __cinit__(self, MemoryBlock memory_block, unsigned int index,
            unsigned int offset):
        self._load_order = []
        self.system_manager = None

    def __getattr__(self, str name):
        cdef unsigned int system_index = self.system_manager.get_system_index(
            name)
        system = self.system_manager.get_system(name)
        cdef unsigned int* pointer = <unsigned int*>self.pointer
        cdef unsigned int component_index = pointer[system_index+1]
        if component_index == -1:
            raise IndexError()
        cdef IndexedMemoryZone components = system.components
        return components[component_index]

    property entity_id:
        def __get__(self):
            return self._id

    property load_order:
        def __get__(self):
            return self._load_order

        def __set__(self, list value):
            self._load_order = value

    cdef void set_component(self, unsigned int component_id, 
        unsigned int system_id):
        cdef unsigned int* pointer = <unsigned int*>self.pointer
        pointer[system_id+1] = component_id

    cdef unsigned int get_component_index(self, str name):
        cdef unsigned int system_index = self.system_manager.get_system_index(
            name)
        cdef unsigned int* pointer = <unsigned int*>self.pointer
        return pointer[system_index+1]
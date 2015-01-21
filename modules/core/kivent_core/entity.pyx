from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from membuffer cimport (MemComponent, ZoneIndex, MemoryZone, Buffer, 
    MemoryBlock, IndexedMemoryZone)
from system_manager cimport system_manager

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

    def __getattr__(self, name):
        cdef unsigned int system_index = system_manager.get_system_index(name)
        system = system_manager.get_system(name)
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
        cdef unsigned int system_index = system_manager.get_system_index(name)
        system = system_manager.get_system(name)
        cdef unsigned int* pointer = <unsigned int*>self.pointer
        return pointer[system_index+1]

cdef class EntityManager:

    def __cinit__(self, Buffer master_buffer, unsigned int pool_block_size, 
        dict reserve_spec, unsigned int system_count):
        system_count = system_count + 1
        self.memory_index = IndexedMemoryZone(master_buffer, 
            pool_block_size, sizeof(unsigned int)*system_count, reserve_spec, 
            Entity)
        self.system_count = system_count

    cdef void clear_entity(self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        cdef unsigned int system_count = self.system_count
        cdef unsigned int i
        for i in range(system_count):
            pointer[i] = -1

    cdef void set_component(self, unsigned int entity_id, 
        unsigned int component_id, unsigned int system_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        pointer[system_id] = component_id

    cdef void set_entity_active(self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        pointer[0] = entity_id

    cdef unsigned int generate_entity(self, zone):
        cdef IndexedMemoryZone memory_index = self.memory_index
        cdef MemoryZone memory_zone = memory_index.memory_zone
        cdef unsigned int new_id = memory_zone.get_free_slot(zone)
        self.clear_entity(new_id)
        self.set_entity_active(new_id)
        return new_id

    cdef void remove_entity(self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        memory_zone.free_slot(entity_id)

from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from membuffer cimport (MemComponent, ZoneIndex, MemoryZone, Buffer, 
    MemoryBlock)
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
        cdef unsigned int component_index = pointer[system_index]
        if component_index == -1:
            raise IndexError()
        cdef list components = system.get_component(component_index)
        return components[component_index]

    property entity_id:
        def __get__(self):
            return self._id

    property load_order:
        def __get__(self):
            return self._load_order

        def __set__(self, list value):
            self._load_order = value


cdef class entrange:
    cdef unsigned int start
    cdef unsigned int end
    cdef Entities entities

    def __init__(self, Entities entities, start=0, end=None):
        cdef MemoryZone memory_zone = entities.memory_zone
        cdef unsigned int zone_count = memory_zone.count
        self.entities = entities
        self.start = start
        if end > zone_count or end is None:
            self.end = zone_count
        else:
            self.end = end
    
    def __iter__(self):
        return entrange_iter(self.entities, self.start, self.end)

cdef class entrange_iter:
    cdef Entities entities
    cdef unsigned int current
    cdef unsigned int end

    def __init__(self, Entities entities, start, end):
        self.entities = entities
        self.current = start
        self.end = end

    def __iter__(self):
        return self

    def __next__(self):
        
        cdef Entities entities = self.entities
        cdef MemoryZone memory_zone = entities.memory_zone
        cdef ZoneIndex zone_index = entities.zone_index
        cdef unsigned int current = self.current
        cdef unsigned int pool_index, used
        cdef Entity entity

        if current > self.end:
            raise StopIteration
        else:
            pool_index = memory_zone.get_pool_index_from_index(current)
            used = memory_zone.get_pool_end_from_pool_index(pool_index)
            
            entity = zone_index.get_component_from_index(current)
            if current >= used:
                self.current = memory_zone.get_start_of_pool(pool_index+1)
                return self.next()
            else:
                self.current += 1
                return zone_index.get_component_from_index(current)


def test_entities(size_in_kb, pool_block_size, general_count, test_count):
    reserved_spec = {
        'general': 200,
        'test': 200,
    }
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef Entities entities = Entities(master_buffer, 8, pool_block_size,
        reserved_spec)
    cdef unsigned int index
    cdef list indices = []
    i_a = indices.append
    cdef Entity entity
    cdef MemoryZone memory_zone = entities.memory_zone
    cdef int x
    
    for x in range(general_count):
        index = memory_zone.get_free_slot('general')
        i_a(index)
        entity = entities[index]
        print(entity._id, index, 'in creation')

    for x in range(test_count):
        index = memory_zone.get_free_slot('test')
        i_a(index)
        entity = entities[index]
        print(entity._id, index, 'in creation')
        
    for entity in entrange(entities):
        print entity._id


cdef class Entities:
    cdef MemoryZone memory_zone
    cdef ZoneIndex zone_index
    
    def __cinit__(self, Buffer master_buffer, unsigned int system_count, 
        unsigned int block_size, dict reserved_spec):
        cdef MemoryZone memory_zone = MemoryZone(block_size, 
            master_buffer, sizeof(int)*system_count, reserved_spec)
        cdef ZoneIndex zone_index = ZoneIndex(memory_zone, Entity)
        self.zone_index = zone_index
        self.memory_zone = memory_zone

    def __getitem__(self, index):
        return self.zone_index.get_component_from_index(index)

    def __getslice__(self, index_1, index_2):
        cdef ZoneIndex zone_index = self.zone_index
        get_component_from_index = zone_index.get_component_from_index
        return [get_component_from_index(i) for i in range(index_1, index_2)]


cdef class EntityProcessor:
    def __cinit__(self, dict systems, int system_count, int start_count):
        self._count = 0
        self._system_count = system_count
        self._growth_rate = .25
        self._mem_count = start_count
        self._systems = systems

    def __dealloc__(self):
        if self._entity_index != NULL:
            PyMem_Free(self._entity_index)

    property system_count:
        def __get__(self):
            return self._system_count

    cdef Entity generate_entity(self):
        cdef int* entity_index = self._entity_index
        self._count += 1
        cdef int count = self._count
        if count > self._mem_count:
            self.change_allocation(count + int(self._growth_rate*count))
        self.clear_entity(self._count - 1)
        cdef Entity new_entity = Entity.__new__(Entity, self._count - 1, self)
        return new_entity

    cdef void change_allocation(self, int new_count):
        cdef int* entity_index = <int*>PyMem_Realloc(self._entity_index, 
            new_count * self._system_count * sizeof(int))
        if entity_index is NULL:
            raise MemoryError()
        self._entity_index = entity_index
        self._mem_count = new_count

    cdef void clear_entity(self, int entity_id):
        cdef int* entity_index = self._entity_index
        cdef int system_count = self._system_count
        cdef index_offset = system_count * entity_id
        cdef int i
        for i in range(index_offset, index_offset+system_count):
            entity_index[i] = -1

    cdef void set_component(self, int entity_id, int component_id, 
        int system_id):
        cdef int* entity_index = self._entity_index
        cdef int system_count = self._system_count
        cdef int offset_index = entity_id * system_count + system_id
        entity_index[offset_index] = component_id
        


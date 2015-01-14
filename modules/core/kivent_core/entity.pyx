from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free


cdef class EntityProcessor:
    def __cinit__(self, dict systems, int system_count, int start_count):
        self._count = 0
        self._system_count = system_count
        self._growth_rate = .25
        self._entity_index = <int*>PyMem_Malloc( 
            start_count * system_count * sizeof(int))
        self._mem_count = start_count
        self._systems = systems

    def __dealloc__(self):
        if self._entity_index != NULL:
            PyMem_Free(self._entity_index)

    property system_count:
        def __get__(self):
            return self._system_count
        def __set__(self, int new_value):
            cdef int* new_memory
            cdef int* old_memory = self._entity_index
            cdef int count = self._count
            cdef int i
            cdef int system_i
            cdef int old_index
            cdef int new_index
            cdef int mem_count = self._mem_count
            cdef int old_system_count = self._system_count
            if old_system_count != new_value:
                new_memory = <int *>PyMem_Malloc(
                    mem_count * new_value * sizeof(int))
                if new_memory is NULL:
                    raise MemoryError()
                for i in range(0, mem_count):
                    for system_i in range(0, old_system_count):
                        old_index = i * old_system_count + system_i
                        new_index = i * new_value + system_i
                        new_memory[new_index] = old_memory[old_index]
                    for system_i in range(old_system_count, new_value):
                        new_index = i * new_value + system_i
                        new_memory[new_index] = -1


            PyMem_Free(old_memory)
            self._system_count = new_value
            self._entity_index = new_memory

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
        

cdef class Entity:
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
    def __cinit__(self, int entity_id, EntityProcessor processor):
        self._id = entity_id
        self._load_order = []
        self._processor = processor

    def __getattr__(self, name):
        cdef EntityProcessor processor = self._processor
        system = processor._systems[name]
        cdef int system_index = system.system_index
        cdef int* entity_index = processor._entity_index
        cdef int system_count = processor._system_count
        cdef int offset_index = self._id * system_count + system_index
        cdef int component_index = entity_index[offset_index]
        if component_index == -1:
            raise IndexError()
        cdef list components = system.components
        return components[component_index]

    property entity_id:
        def __get__(self):
            return self._id

    property load_order:
        def __get__(self):
            return self._load_order

        def __set__(self, list value):
            self._load_order = value
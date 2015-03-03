from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivy.properties import (NumericProperty, ObjectProperty, ListProperty,
    BooleanProperty)
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.zonedblock cimport ZonedBlock
from gamesystem cimport GameSystem
from kivent_core.managers.system_manager cimport system_manager
from cpython cimport bool


cdef class MemComponent:
    '''The base for a cdef extension that will work with the MemoryBlock 
    memory management system. Will store a pointer to the actual data, 
    and the index of the slot. All of the Python accessible components (and 
    the Entity class) inherit from this class.''' 

    def __cinit__(self, MemoryBlock memory_block, unsigned int index, 
        unsigned int offset):
        self._id = index + offset
        self.pointer = memory_block.get_pointer(index)


class NotAllocatedError(Exception):
    pass


cdef class StaticMemGameSystem(GameSystem):
    size_of_component_block = NumericProperty(4)
    type_size = NumericProperty(0)
    component_type = ObjectProperty(None)
    processor = BooleanProperty(False)
    system_names = ListProperty([])

    def __cinit__(self, **kwargs):
        self.entity_components = None
        self.components = None

    property components:
        def __get__(self):
            if self.components == None:
                raise NotAllocatedError(self.system_id, '''has not been
                    allocated yet''')
            return self.components

    def get_component(self, str zone):
        cdef IndexedMemoryZone components = self.components
        cdef MemoryZone memory_zone = components.memory_zone
        cdef unsigned int new_id = memory_zone.get_free_slot(zone)
        self.clear_component(new_id)
        return new_id

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, self.type_size, 
            reserve_spec, self.component_type)
        if self.processor:
            self.entity_components = ComponentPointerAggregator(
                [x for x in self.system_names], 
                self.components.memory_zone.count, self.gameworld.entities, 
                master_buffer)

    def get_system_size(self):
        return self.components.get_size()

    def get_size_estimate(self, dict reserve_spec):
        cdef unsigned int size_of_zone, block_count, size_per_ent
        cdef unsigned int total = 0
        cdef unsigned int pointer_size_in_kb = 0
        cdef unsigned int count
        cdef unsigned int type_size = self.type_size
        cdef unsigned int block_size_in_kb = self.size_of_component_block
        cdef unsigned int size_in_bytes = (block_size_in_kb * 1024)
        cdef unsigned int slots_per_block = size_in_bytes // type_size
        cdef unsigned int entity_count = 0
        for zone_name in reserve_spec:
            size_of_zone = reserve_spec[zone_name]
            block_count = (size_of_zone//slots_per_block) + 1
            total += block_count*block_size_in_kb
            entity_count += block_count*slots_per_block
        if self.processor:
            count = len(self.system_names)
            size_per_ent = sizeof(void*) * count
            pointer_size_in_kb = ((entity_count * size_per_ent) // 1024) + 1
        return total + pointer_size_in_kb

    def remove_component(self, unsigned int component_id):
        self.clear_component(component_id)
        cdef MemoryZone memory_zone = self.components.memory_zone
        memory_zone.free_slot(component_id)

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        '''Not implemented for StaticMemGameSystem. Use this function to setup
        the initialization of a component's values'''
        pass

    def clear_component(self, unsigned int component_index):
        '''Not implemented for StaticMemGameSystem. Use this function to setup
        the clearing of a component's values for recycling'''
        pass


cdef class ZonedAggregator:
    
    def __cinit__(self, list system_names, list zone_counts,
        IndexedMemoryZone entities, Buffer master_buffer): 
        self.count = len(system_names)
        cdef unsigned int total = 0
        for zone_name, count in zone_counts:
            total += count
        self.total = total
        self.entities = entities
        self.system_names = system_names
        self.entity_block_index = {}
        cdef unsigned int size_per_ent = sizeof(void*) * self.count
        self.memory_block = ZonedBlock(size_per_ent, zone_counts)
        self.memory_block.allocate_memory_with_buffer(master_buffer)
        self.clear()

    cdef bool check_empty(self):
        return self.memory_block.check_empty()

    cdef void free(self):
        self.memory_block.remove_from_buffer()

    cdef unsigned int get_size(self):
        return self.memory_block.size

    cdef void clear(self):
        cdef void** data = <void**>self.memory_block.data
        self.memory_block.clear()
        cdef unsigned int i
        for i in range(self.total*self.count):
            data[i] = NULL
        
    cdef int remove_entity(self, unsigned int entity_id) except 0:
        cdef unsigned int block_index = self.entity_block_index[entity_id]
        cdef unsigned int adjusted_index = block_index * self.count
        cdef void** data = <void**>self.memory_block.data
        cdef unsigned int i
        for i in range(self.count):
            data[adjusted_index+i] = NULL
        self.memory_block.remove_data(block_index, 1)
        del self.entity_block_index[entity_id]
        return 1

    cdef unsigned int add_entity(self, unsigned int entity_id, 
        str zone_name) except -1:
        cdef unsigned int block_index = self.memory_block.add_data(1, zone_name)
        cdef unsigned int* entity = <unsigned int*>self.entities.get_pointer(
            entity_id)
        cdef unsigned int adjusted_index = block_index * self.count
        self.entity_block_index[entity_id] = block_index
        cdef unsigned int system_index, component_index, pointer_loc
        cdef StaticMemGameSystem system
        cdef unsigned int i
        cdef str system_name
        cdef MemoryZone memory_zone
        cdef void** data = <void**>self.memory_block.data
        cdef dict systems = system_manager.systems
        for i, system_name in enumerate(self.system_names):
            pointer_loc = adjusted_index + i
            system_index = system_manager.get_system_index(system_name)
            component_index = entity[system_index+1]
            system = systems[system_index]
            memory_zone = system.components.memory_zone
            data[pointer_loc] = memory_zone.get_pointer(component_index)
        return adjusted_index


cdef class ComponentPointerAggregator:

    def __cinit__(self, list system_names, unsigned int total,
        IndexedMemoryZone entities, Buffer master_buffer):
        cdef unsigned int count = len(system_names)
        self.count = count
        self.total = total
        self.entities = entities
        self.system_names = system_names
        self.entity_block_index = {}
        cdef unsigned int size_per_ent = sizeof(void*) * count
        cdef unsigned int size_in_kb = ((total * size_per_ent) // 1024) + 1 
        self.memory_block = MemoryBlock(size_in_kb*1024, size_per_ent, 1)
        self.memory_block.allocate_memory_with_buffer(master_buffer)
        self.clear()

    cdef bool check_empty(self):
        return self.memory_block.check_empty()

    cdef void free(self):
        self.memory_block.remove_from_buffer()

    cdef unsigned int get_size(self):
        return self.memory_block.real_size

    cdef void clear(self):
        cdef void** data = <void**>self.memory_block.data
        self.memory_block.clear()
        cdef unsigned int i
        for i in range(self.total*self.count):
            data[i] = NULL
        
    cdef int remove_entity(self, unsigned int entity_id) except 0:
        cdef unsigned int block_index = self.entity_block_index[entity_id]
        cdef unsigned int adjusted_index = block_index * self.count
        cdef void** data = <void**>self.memory_block.data
        cdef unsigned int i
        for i in range(self.count):
            data[adjusted_index+i] = NULL
        self.memory_block.remove_data(block_index, 1)
        del self.entity_block_index[entity_id]
        return 1

    cdef unsigned int add_entity(self, unsigned int entity_id) except -1:
        cdef unsigned int block_index = self.memory_block.add_data(1)
        cdef unsigned int* entity = <unsigned int*>self.entities.get_pointer(
            entity_id)
        cdef unsigned int adjusted_index = block_index * self.count
        self.entity_block_index[entity_id] = block_index
        cdef unsigned int system_index, component_index, pointer_loc
        cdef StaticMemGameSystem system
        cdef unsigned int i
        cdef str system_name
        cdef MemoryZone memory_zone
        cdef void** data = <void**>self.memory_block.data
        cdef dict systems = system_manager.systems
        for i, system_name in enumerate(self.system_names):
            pointer_loc = adjusted_index + i
            system_index = system_manager.get_system_index(system_name)
            component_index = entity[system_index+1]
            system = systems[system_index]
            memory_zone = system.components.memory_zone
            data[pointer_loc] = memory_zone.get_pointer(component_index)
        return adjusted_index
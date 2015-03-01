from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.entity cimport Entity

cdef class EntityManager:

    def __cinit__(EntityManager self, Buffer master_buffer,
        unsigned int pool_block_size, dict reserve_spec, 
        unsigned int system_count):
        system_count = system_count + 1
        self.memory_index = IndexedMemoryZone(master_buffer, 
            pool_block_size, sizeof(unsigned int)*system_count, reserve_spec, 
            Entity)
        self.system_count = system_count

    cdef void clear_entity(EntityManager self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        cdef unsigned int system_count = self.system_count
        cdef unsigned int i
        for i in range(system_count):
            pointer[i] = -1

    cdef unsigned int get_size(self):
        return self.memory_index.get_size()

    cdef void set_component(EntityManager self, unsigned int entity_id, 
        unsigned int component_id, unsigned int system_id):

        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        pointer[system_id+1] = component_id

    cdef void set_entity_active(EntityManager self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        cdef unsigned int* pointer = <unsigned int*>(
            memory_zone.get_pointer(entity_id))
        pointer[0] = entity_id

    cdef unsigned int generate_entity(EntityManager self, zone) except -1:
        cdef IndexedMemoryZone memory_index = self.memory_index
        cdef MemoryZone memory_zone = memory_index.memory_zone
        cdef unsigned int new_id = memory_zone.get_free_slot(zone)
        self.clear_entity(new_id)
        self.set_entity_active(new_id)
        return new_id

    def get_entity_ids(self, entity_id):
        cdef unsigned int* pointer = <unsigned int*>(
            self.memory_index.memory_zone.get_pointer(entity_id))
        return [pointer[x] for x in range(self.system_count)]


    cdef void remove_entity(EntityManager self, unsigned int entity_id):
        cdef MemoryZone memory_zone = self.memory_index.memory_zone
        memory_zone.free_slot(entity_id)

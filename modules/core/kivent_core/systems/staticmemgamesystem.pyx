from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivy.properties import NumericProperty
from kivent_core.memory_handlers.membuffer cimport Buffer
from gamesystem cimport GameSystem


cdef class StaticMemGameSystem(GameSystem):
    size_of_component_block = NumericProperty(4)

    property components:
        def __get__(StaticMemGameSystem self):
            return self.components

    def get_component(StaticMemGameSystem self, str zone):
        cdef IndexedMemoryZone components = self.components
        cdef MemoryZone memory_zone = components.memory_zone
        cdef unsigned int new_id = memory_zone.get_free_slot(zone)
        self.clear_component(new_id)
        return new_id

    def remove_component(StaticMemGameSystem self, unsigned int component_id):
        self.clear_component(component_id)
        cdef MemoryZone memory_zone = self.components.memory_zone
        memory_zone.free_slot(component_id)

    def allocate(StaticMemGameSystem self, Buffer master_buffer, 
        dict reserve_spec):
        '''Not implemented for StaticMemGameSystem. Use this function to setup 
        the allocation of your GameSystem's memory. Typically this will involve
        using memory_handlers.indexing.IndexedMemoryZone'''
        pass

    def init_component(StaticMemGameSystem self, unsigned int component_index, 
        unsigned int entity_id, args):
        '''Not implemented for StaticMemGameSystem. Use this function to setup
        the initialization of a component's values'''
        pass

    def clear_component(StaticMemGameSystem self, unsigned int component_index):
        '''Not implemented for StaticMemGameSystem. Use this function to setup
        the clearing of a component's values for recycling'''
        pass
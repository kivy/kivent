from kivent_core.systems.staticmemgamesystem cimport MemComponent
from kivent_core.managers.system_manager cimport SystemManager

cdef class Entity(MemComponent):
    cdef list _load_order
    cdef SystemManager system_manager
    cdef void set_component(self, unsigned int component_id,
        unsigned int system_id)
    cpdef unsigned int get_component_index(self, str name)

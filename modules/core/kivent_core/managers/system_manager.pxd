from kivent_core.managers.game_manager cimport GameManager
cdef unsigned int DEFAULT_SYSTEM_COUNT
cdef unsigned int DEFAULT_COUNT

cdef class ZoneConfig:
    cdef str zone_name
    cdef list systems
    cdef unsigned int count


cdef class SystemConfig:
    cdef dict zone_configs


cdef class SystemManager(GameManager):
    cdef list systems
    cdef dict zones
    cdef dict system_index
    cdef list _update_order
    cdef bint initialized
    cdef list free_indices
    cdef list free_non_component_indices
    cdef unsigned int first_non_component_index
    cdef unsigned int system_count
    cdef unsigned int current_count
    cdef SystemConfig system_config

    cdef unsigned int get_system_index(self, str system_name)

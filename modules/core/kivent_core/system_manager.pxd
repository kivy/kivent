cdef unsigned int DEFAULT_COUNT = 10000
cdef unsigned int DEFAULT_SYSTEM_COUNT = 10

cdef class ZoneConfig:
    cdef str zone_name
    cdef list systems
    cdef unsigned int count


cdef class SystemConfig:
    cdef dict zone_configs


cdef class SystemManager:
    cdef dict systems
    cdef dict zones
    cdef dict system_index
    cdef list update_order
    cdef unsigned int system_count
    cdef unsigned int current_count
    cdef SystemConfig system_config
    cdef unsigned int get_system_index(self, str system_name)

cdef SystemManager system_manager
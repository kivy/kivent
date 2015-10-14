from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)


cdef class ProjectileTemplate:
    cdef str texture
    cdef str model
    cdef float damage
    cdef float armor_pierce
    cdef float width
    cdef float height
    cdef float mass
    cdef int projectile_type
    cdef int collision_type
    cdef float speed
    cdef float rot_speed

ctypedef struct ProjectileStruct:
    unsigned int entity_id
    float damage
    float armor_pierce
    int projectile_type
    unsigned int origin_entity


cdef class ProjectileComponent(MemComponent):
    pass


cdef class ProjectileSystem(StaticMemGameSystem):
    cdef dict projectile_templates
    cdef dict projectile_keys
    cdef int projectile_count
    cdef unsigned int create_projectile(self, int ammo_type, tuple position,
        float rotation, unsigned int firing_entity)

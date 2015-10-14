from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)
include "projectile_config.pxi"


ctypedef struct ProjectileWeapon:
    float reload_time
    int projectile_type
    int ammo_count
    float rate_of_fire
    int in_clip
    int clip_size
    float[MAX_BARRELS*2] barrel_offsets
    float projectile_width
    float projectile_height
    int barrel_count
    int ammo_type
    float accel


cdef class Weapon:
    cdef ProjectileWeapon *weapon_pointer


cdef class WeaponTemplate:
    cdef ProjectileWeapon weapon_data
    cdef Weapon weapon


ctypedef struct ProjectileWeaponStruct:
    unsigned int entity_id
    int current_weapon
    bint firing
    bint reloading
    float cooldown
    ProjectileWeapon[MAX_WEAPONS] weapons


cdef class ProjectileWeaponComponent(MemComponent):
    pass


cdef class ProjectileWeaponSystem(StaticMemGameSystem):
    cdef dict weapon_templates
    cdef void copy_template_to_weapon(self, str template_name, 
        ProjectileWeapon *weapon)
    cdef void fire_projectile(self, unsigned int entity_id, float accel)
from kivent_core.systems.staticmemgamesystem cimport (
    StaticMemGameSystem, MemComponent
    )
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivy.factory import Factory
from kivy.properties import StringProperty, ObjectProperty, NumericProperty
import math
include "projectile_config.pxi"

cdef class ProjectileTemplate:

    def __init__(self, float damage, float armor_pierce, int projectile_type,
        str texture, str model, float width, float height, float mass,
        int collision_type, float speed, float rot_speed):
        self.damage = damage
        self.armor_pierce = armor_pierce
        self.projectile_type = projectile_type
        self.texture = texture
        self.model = model
        self.width = width
        self.height = height
        self.mass = mass
        self.collision_type = collision_type
        self.speed = speed
        self.rot_speed = rot_speed

cdef class ProjectileComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            return data.entity_id

    property damage:
        def __get__(self):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            return data.damage
        def __set__(self, float value):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            data.damage = value

    property armor_pierce:
        def __get__(self):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            return data.armor_pierce
        def __set__(self, float value):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            data.armor_pierce = value

    property projectile_type:
        def __get__(self):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            return data.projectile_type
        def __set__(self, int value):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            data.projectile_type = value

    property origin_entity:
        def __get__(self):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            return data.origin_entity
        def __set__(self, unsigned int value):
            cdef ProjectileStruct* data = <ProjectileStruct*>self.pointer
            data.origin_entity = value


cdef class ProjectileSystem(StaticMemGameSystem):
    system_id = StringProperty('projectiles')
    projectile_types =  {'NO_WEAPON': 0, 'BULLET': 1, 'MISSLE': 2}
    projectile_zone = StringProperty('projectiles')
    type_size = NumericProperty(sizeof(ProjectileStruct))
    component_type = ObjectProperty(ProjectileComponent)

    def __init__(self, **kwargs):
        super(ProjectileSystem, self).__init__(**kwargs)
        self.projectile_templates = {}
        self.projectile_keys = {}
        self.projectile_count = 0

    property projectile_templates:
        def __get__(self):
            return self.projectile_templates

    property projectile_keys:
        def __get__(self):
            return self.projectile_keys

    def register_projectile_template(self, str name, float damage,
        float armor_pierce, int projectile_type, str texture_key,
        str model_key, float width, float height, float mass,
        int collision_type, float speed, float rot_speed):
        count = self.projectile_count
        self.projectile_keys[name] = count
        self.projectile_templates[count] = ProjectileTemplate(
            damage, armor_pierce, projectile_type, texture_key, model_key,
            width, height, mass, collision_type, speed, rot_speed
            )
        self.projectile_count += 1
        return count

    cdef unsigned int create_projectile(self, int ammo_type, tuple position,
        float rotation, unsigned int firing_entity):
        cdef ProjectileTemplate template = self.projectile_templates[ammo_type]
        box_dict = {
            'width': template.width, 
            'height': template.height,
            'mass': template.mass}
        col_shape_dict = {
            'shape_type': 'box', 'elasticity': .5, 
            'collision_type': template.collision_type,
            'shape_info': box_dict, 'friction': 1.0
            }
        physics_component_dict = {
            'main_shape': 'box', 
            'velocity': (0, 0), 'position': position, 'angle': rotation, 
            'angular_velocity': 0, 'mass': template.mass, 
            'vel_limit': template.speed, 
            'ang_vel_limit': math.radians(template.rot_speed), 
            'col_shapes': [col_shape_dict]}
        projectile_dict = {
            'damage': template.damage,
            'projectile_type': template.projectile_type,
            'armor_pierce': template.armor_pierce,
            'origin_entity': firing_entity
        }
        create_component_dict = {
            'position': position,
            'rotate': rotation,
            'cymunk_physics': physics_component_dict,
            'projectiles': projectile_dict,
            'rotate_renderer': {
                'model_key': template.model, 'texture': template.texture
                }
        }
        component_order = [
            'position', 'rotate', 'cymunk_physics', 
            'projectiles', 'rotate_renderer',
            ]
        return self.gameworld.init_entity(
            create_component_dict, component_order, zone=self.projectile_zone,
            )


    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone_name, dict args):
        '''
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ProjectileStruct* component = <ProjectileStruct*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.damage = args.get('damage')
        component.projectile_type = args.get('projectile_type', NO_WEAPON)
        component.armor_pierce = args.get('armor_pierce', 0.)
        component.origin_entity = args.get('origin_entity', -1)

    def clear_component(self, unsigned int component_index):
        '''
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ProjectileStruct* component = <ProjectileStruct*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = -1
        component.origin_entity = -1
        component.projectile_type = NO_WEAPON
        component.damage = 0.
        component.armor_pierce = 0.


Factory.register('ProjectileSystem', cls=ProjectileSystem)
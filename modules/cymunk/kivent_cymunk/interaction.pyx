# cython: profile=True
from cymunk cimport (GearJoint, PivotJoint, Vec2d, cpVect, cpv,
    cpFloat, cpBool, cpvunrotate, cpvrotate, cpvdot, cpvsub, cpvnear,
    cpBody, cpvmult, cpvlerp, Space)
from kivy.properties import (ListProperty, NumericProperty, BooleanProperty,
    StringProperty)
from physics cimport PhysicsComponent
from kivent_core.gamesystems import GameSystem
from kivent_core.gamesystems cimport PositionComponent, RotateComponent
cimport cython
from libc.math cimport atan2, pow as cpow


cdef class CymunkTouchComponent:

    def __cinit__(self, Body touch_body, PivotJoint pivot):
        self._touch_body = touch_body
        self._pivot = pivot

    property max_force:
        def __get__(self):
            return self._pivot.max_force
        def __set__(self, float force):
            self._pivot.max_force = force

    property error_bias:
        def __get__(self):
            return self._pivot.error_bias
        def __set__(self, float error_bias):
            self._pivot.error_bias = error_bias

    property touch_body:
        def __get__(self):
            return self._touch_body
        def __set__(self, Body body):
            self._touch_body = body

    property pivot:
        def __get__(self):
            return self._pivot
        def __set__(self, PivotJoint pivot):
            self._pivot = pivot

class CymunkTouchSystem(GameSystem):
    physics_system = StringProperty(None)
    updateable = BooleanProperty(True)
    gameview_name = StringProperty(None)
    touch_radius = NumericProperty(10.)
    max_force = NumericProperty(2000000.)
    max_bias = NumericProperty(10000.)
    ignore_groups = ListProperty([])
    
    def generate_component(self, dict args):
        cdef Body body = args['body']
        cdef PivotJoint pivot = args['pivot']
        new_component = CymunkTouchComponent.__new__(CymunkTouchComponent, 
            body, pivot)
        return new_component

    def convert_from_screen_to_world(self, tuple touch_pos, tuple camera_pos,
        float camera_scale):
        cdef float x, y, cx, cy, new_x, new_y
        x,y = touch_pos
        cx, cy = camera_pos
        new_x = (x * camera_scale) - cx
        new_y = (y * camera_scale) - cy
        return new_x, new_y

    def on_touch_down(self, touch):
        cdef object gameworld = self.gameworld
        cdef dict systems = gameworld.systems
        cdef object physics_system = systems[self.physics_system]
        cdef object gameview = systems[self.gameview_name]
        cpos = gameview.camera_pos
        cdef tuple camera_pos = (cpos[0], cpos[1])
        cdef tuple touch_pos = (touch.x, touch.y)
        cdef float camera_scale = gameview.camera_scale
        cdef tuple converted_pos = self.convert_from_screen_to_world(touch_pos,
            camera_pos, camera_scale)
        cdef float cx, cy

        cx = converted_pos[0]
        cy = converted_pos[1]
        cdef str system_id = self.system_id
        cdef float max_force = self.max_force
        cdef float max_bias = self.max_bias
        cdef float radius = self.touch_radius
        cdef list touch_box = [cx-radius, cy-radius, cx-radius, cy+radius, 
            cx+radius, cy+radius, cx+radius, cy-radius]
        cdef list touched_ids = physics_system.query_bb(touch_box,
            ignore_groups=self.ignore_groups)
        if len(touched_ids) > 0:
            entity_id = touched_ids[0]
            creation_dict = {system_id: 
                {'entity_id': entity_id, 'touch_pos': converted_pos,
                'max_force': max_force, 'max_bias':max_bias}, 
                'position': converted_pos}
            touch_ent = gameworld.init_entity(creation_dict, ['position', 
                system_id])
            touch.ud['ent_id'] = touch_ent
            touch.ud['touched_ent_id'] = entity_id 

    def on_touch_move(self, touch):
        cdef object gameworld 
        cdef dict systems 
        cdef object gameview
        cdef list entities
        cdef tuple camera_pos
        cdef tuple touch_pos = (touch.x, touch.y)
        cdef float camera_scale 
        cdef tuple converted_pos 
        cdef int entity_id
        cdef object entity
        cdef PositionComponent pos_comp
        if 'ent_id' in touch.ud:
            gameworld = self.gameworld
            systems = gameworld.systems
            entities = gameworld.entities
            entity_id = touch.ud['ent_id']
            gameview = systems[self.gameview_name]
            entity = entities[entity_id]
            pos_comp = entity.position
            cpos = gameview.camera_pos
            camera_pos = (cpos[0], cpos[1])
            camera_scale = gameview.camera_scale
            converted_pos = self.convert_from_screen_to_world(touch_pos,
                camera_pos, camera_scale)

            pos_comp._x = converted_pos[0]
            pos_comp._y = converted_pos[1]
        

    def on_touch_up(self, touch):
        if 'ent_id' in touch.ud:
            self.gameworld.remove_entity(touch.ud['ent_id'])

    def update(self, float dt):
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef list entity_ids = self.entity_ids
        cdef int ent_count = len(entity_ids)
        cdef int entity_id
        cdef object entity
        cdef int entity_index
        cdef PositionComponent position_comp
        cdef float x, y
        cdef str system_id = self.system_id
        cdef CymunkTouchComponent system_component 
        cdef Body body
        cdef cpVect body_pos
        cdef cpBody* cbody
        cdef cpVect new_vel
        cdef cpVect new_point
        for entity_index in range(ent_count):
            entity_id = entity_ids[entity_index]
            entity = entities[entity_id]
            position_comp = entity.position
            system_component = getattr(entity, system_id)
            x = position_comp._x
            y = position_comp._y
            body = system_component._touch_body
            cbody = body._body
            body_pos = cbody.p
            new_point = cpvlerp(body_pos, cpv(x, y), .25)
            new_vel = cpvmult(cpvsub(new_point, body_pos),  60.)
            cbody.v = new_vel
            cbody.p = new_point

    def create_component(self, object entity, dict args):
        cdef object gameworld = self.gameworld
        cdef dict systems = gameworld.systems
        cdef str physics_id = self.physics_system
        cdef object physics_system = systems[physics_id]
        cdef Body touch_body = Body(None, None)
        cdef list entities = gameworld.entities
        cdef int entity_id = args['entity_id']
        cdef tuple touch_pos = args['touch_pos']
        cdef object touched_entity = entities[entity_id]
        cdef PhysicsComponent physics_data = getattr(
            touched_entity, physics_id)
        cdef Body body = physics_data.body
        cdef cpVect body_local = body.world_to_local(touch_pos)
        cdef tuple body_pos = (body_local.x, body_local.y)
        cdef PivotJoint pivot = PivotJoint(touch_body, body, (0., 0.), 
            body_pos)
        touch_body._body.p = cpv(touch_pos[0], touch_pos[1])
        pivot.max_bias = args['max_bias']
        pivot.error_bias = cpow(1.0 - 0.15, 60.0)
        pivot.max_force = args['max_force']
        cdef Space space = physics_system.space
        space.add(pivot)
        new_args = {'body': touch_body, 'pivot': pivot, 
            'linked_entity': touched_entity}
        super(CymunkTouchSystem, self).create_component(entity, new_args)

    def remove_entity(self, int entity_id):
        cdef str system_id = self.system_id
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef object entity = entities[entity_id]
        cdef CymunkTouchComponent system_data = getattr(entity, system_id)
        cdef str physics_id = self.physics_system
        cdef object physics_system = gameworld.systems[physics_id]
        cdef Space space = physics_system.space
        space.remove(system_data._pivot)
        super(CymunkTouchSystem, self).remove_entity(entity_id)
            
            
cdef class SteeringComponent: 

    def __cinit__(self, Body body, PivotJoint pivot, GearJoint gear,
        float speed):
        self._target = (None, None)
        self._steering_body = body
        self._pivot = pivot
        self._gear = gear
        self._speed = speed
        self._active = True

    property steering_body:
        def __get__(self):
            return self._steering_body
        def __set__(self, Body body):
            self._steering_body = body

    property pivot:
        def __get__(self):
            return self._pivot
        def __set__(self, PivotJoint pivot):
            self._pivot = pivot

    property gear:
        def __get__(self):
            return self._gear
        def __set__(self, GearJoint gear):
            self._gear = gear

    property target:
        def __get__(self):
            return self._target
        def __set__(self, tuple target):
            self._target = target

    property turn_speed:
        def __get__(self):
            return self._gear.max_bias
        def __set__(self, float turn_speed):
            self._gear.max_bias = turn_speed

    property active:
        def __get__(self):
            return self._active
        def __set__(self, bool new):
            self._active = new

    property speed:
        def __get__(self):
            return self._speed
        def __set__(self, float speed):
            self._speed = speed

    property stability:
        def __get__(self):
            return self._gear.max_force
        def __set__(self, float stability):
            self._gear.max_force = stability

    property max_force:
        def __get__(self):
            return self._pivot.max_force
        def __set__(self, float force):
            self._pivot.max_force = force


class SteeringSystem(GameSystem):
    physics_system = StringProperty(None)
    updateable = BooleanProperty(True)

    def generate_component(self, dict args):
        cdef Body body = args['body']
        cdef PivotJoint pivot = args['pivot']
        cdef GearJoint gear = args['gear']
        cdef float speed = args['speed']
        new_component = SteeringComponent.__new__(SteeringComponent, 
            body, pivot, gear, speed)
        return new_component

    def create_component(self, object entity, dict args):
        cdef object gameworld = self.gameworld
        cdef dict systems = gameworld.systems
        cdef str physics_id = self.physics_system
        cdef object physics_system = systems[physics_id]
        cdef Body steering_body = Body(None, None)
        cdef PhysicsComponent physics_data = getattr(entity, physics_id)
        cdef Body body = physics_data.body
        cdef PivotJoint pivot = PivotJoint(steering_body, body, (0, 0), (0, 0))
        cdef GearJoint gear = GearJoint(steering_body, body, 0.0, 1.0)
        gear.error_bias = 0.
        pivot.max_bias = 0.0
        pivot.error_bias = 0.
        gear.max_bias = args['turn_speed']
        gear.max_force = args['stability']
        pivot.max_force = args['max_force']
        cdef Space space = physics_system.space
        space.add(pivot)
        space.add(gear)
        new_args = {'body': steering_body, 'pivot': pivot, 'gear': gear,
            'speed': args['speed']}
        super(SteeringSystem, self).create_component(entity, new_args)

    def remove_entity(self, int entity_id):
        cdef str system_id = self.system_id
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef object entity = entities[entity_id]
        cdef SteeringComponent steering_data = getattr(entity, system_id)
        cdef str physics_id = self.physics_system
        cdef object physics_system = gameworld.systems[physics_id]
        cdef Space space = physics_system.space
        space.remove(steering_data._gear)
        space.remove(steering_data._pivot)
        super(SteeringSystem, self).remove_entity(entity_id)
        
    def update(self, dt):
        cdef list entity_ids = self.entity_ids
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef int entity_id
        cdef str system_id = self.system_id
        cdef str physics_id = self.physics_system
        cdef SteeringComponent steering_data
        cdef PhysicsComponent physics_data
        cdef Body body
        cdef Body steering_body
        cdef float angle
        cdef cpVect v1
        cdef cpVect target
        cdef tuple target_pos
        cdef cpVect move_delta
        cdef float turn
        cdef tuple velocity_rot
        cdef float speed
        cdef cpVect unrot
        cdef float x, y
        cdef bool solve

        for entity_id in entity_ids:
            entity = entities[entity_id]
            steering_data = getattr(entity, system_id)
            physics_data = getattr(entity, physics_id)
            if steering_data._active:
                body = physics_data._body
                target_pos = steering_data._target
                steering_body = steering_data._steering_body
                try:
                    x, y = target_pos
                except:
                    steering_body.velocity = (0., 0.)
                    continue
                target = cpv(x, y)
                body_pos = body._body.p
                v1 = body._body.rot
                angle = body.angle
                speed = steering_data._speed
                move_delta = cpvsub(target, body_pos)
                unrot = cpvunrotate(v1, move_delta)
                turn = atan2(unrot.y, unrot.x)
                steering_body.angle = angle - turn
                if cpvnear(target, body_pos, 75.0):
                    velocity_rot = (0., 0.)
                elif turn <= -1.3 or turn >= 1.3:
                    velocity_rot = (0., 0.)
                else:
                    new_vec = cpvrotate(v1, cpv(speed, 0.0))  
                    velocity_rot = (new_vec.x, new_vec.y)
                steering_body.velocity = velocity_rot

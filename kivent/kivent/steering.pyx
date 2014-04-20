
from cymunk cimport (GearJoint, PivotJoint, Vec2d, cpVect, cpv,
    cpFloat, cpBool)

from libc.math cimport atan2

cdef extern from "chipmunk/chipmunk.h":
    cpVect cpvunrotate(const cpVect v1, const cpVect v2)
    cpVect cpvrotate(const cpVect v1, const cpVect v2)
    cpFloat cpvdot(const cpVect v1, const cpVect v2)
    cpVect cpvsub(const cpVect v1, const cpVect v2)
    cpBool cpvnear(const cpVect v1, const cpVect v2, const cpFloat dist)


cdef class SteeringComponent: 
    cdef Body _steering_body
    cdef PivotJoint _pivot
    cdef GearJoint _gear
    cdef tuple _target
    cdef float _speed
    cdef bool _active

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

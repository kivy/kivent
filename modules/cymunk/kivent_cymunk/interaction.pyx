# cython: profile=True
# cython: embedsignature=True
from cymunk.cymunk cimport (GearJoint, PivotJoint, Vec2d, cpVect, cpv,
    cpFloat, cpBool, cpvunrotate, cpvrotate, cpvdot, cpvsub, cpvnear,
    cpBody, cpvmult, cpvlerp, Space)
from kivy.properties import (ListProperty, NumericProperty, BooleanProperty,
    StringProperty, ObjectProperty)
from kivent_cymunk.physics cimport PhysicsComponent
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.systems.position_systems cimport (PositionComponent2D, 
    PositionStruct2D)
from kivent_core.systems.rotate_systems cimport RotateComponent2D
cimport cython
from kivy.factory import Factory
from libc.math cimport atan2, pow as cpow
from kivent_core.managers.system_manager cimport SystemManager


cdef class CymunkTouchComponent(MemComponent):
    '''
    The CymunkTouchComponent keeps track of a PivotJoint and a Body that has 
    not been added to the cymunk Space in order to control physics objects 
    actually added to the world. The PivotJoint is bound to the **touch_body**
    of this component and the Body of the touched Entity.


    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is 
        unattached.

        **touch_body** (Body): This is a rogue body (unattached to the space)
        that influences another Body through a cymunk.constraint interaction.

        **pivot** (PivotJoint): The constraint that acts on this body and the 
        one it is attached to. 

        **max_force** (float): Maximum force the joint can exert on the 
        attached body.

        **error_bias** (float): The rate at which the joint is corrected.

    '''

    def __cinit__(self, MemoryBlock memory_block, unsigned int index,
            unsigned int offset):
        self._touch_body = None
        self._pivot = None

    property entity_id:
        def __get__(self):
            cdef CymunkTouchStruct* data = <CymunkTouchStruct*>self.pointer
            return data.entity_id

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

cdef class CymunkTouchSystem(StaticMemGameSystem):
    '''
    Processing Depends On: PositionSystem2D, CymunkTouchSystem

    The CymunkTouchSystem provides a way to interact with the entities in a 
    CymunkPhysics GameSystem, either through touches or mouse clicks. Touched 
    entities will be 'dragged'. This system will generate new entities when 
    receiving an on_touch_down event that collides with an entity in the 
    space of the CymunkPhysics GameSystem with system_id: **physics_system**.

    The entities will be generated in zone **zone_to_use** so make sure to set 
    this up appropriately. This zone should not need more than 100 entities 
    unless you are planning on receiving very many simultaneous touches.

    This system will be dependent on its own component and a 
    PositionComponent2D (default system_id: 'position') for processing.

    **Attributes:**
        **physics_system** (StringProperty): Name (system_id) of the physics 
        system to use with this system. Defaults to 'cymunk_physics'.

        **touch_radius** (NumericProperty): Size of the touch query to see 
        which entities we are touching. Defaults to 20.

        **max_force** (NumericProperty): Maximum force the PivotJoint will be 
        able to exert. Defaults to 2500000.

        **max_bias** (NumericProperty): The rate at which the joints for 
        touch entities will be corrected. Defaults to 10000.

        **ignore_groups** (ListProperty): List of collision_type (int) to 
        ignore when performing the collision query in on_touch_down. Defaults 
        to [].

        **zone_to_use** (StringProperty): Name of the zone to create entities 
        in. Defaults to 'touch'.

    '''
    system_id = StringProperty('cymunk_touch')
    physics_system = StringProperty('cymunk_physics')
    updateable = BooleanProperty(True)
    touch_radius = NumericProperty(20.)
    max_force = NumericProperty(2500000.)
    max_bias = NumericProperty(10000.)
    ignore_groups = ListProperty([])
    processor = BooleanProperty(True)
    type_size = NumericProperty(sizeof(CymunkTouchStruct))
    component_type = ObjectProperty(CymunkTouchComponent)
    zone_to_use = StringProperty('touch')
    system_names = ListProperty(['cymunk_touch','position'])


    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone, dict args):
        '''
        The entities for this system are typically generated by its 
        on_touch_down event. However, if you do need to create a component 
        the args dict looks like: 

        You will also definitely want to look over how this GameSystem 
        manipulates its components in the on_touch_down, on_touch_move,
        and on_touch_up event handling.

        Args:

            component_index (unsigned int): Index of the component to be 
            initialized. 

            entity_id (usigned int): Identity of the entity we will be 
            adding this component to.

            zone (str): Name of the zone this entities memory will use.

            args (dict): Contains the arguments for creating the PivotJoint.
            Described below.

        Args dict looks like:

        .. code-block:: python

            args = {
                'touch_pos': (float, float), 
                #Tuple of the position this touch is occuring at

                'touched_ent': (unsigned int), 
                #The id of the entity that was touched.

                'max_bias': float,
                #The error correction rate for this connection

                'max_force': float,
                #The maximum amount of force this joint can generate.
                }

        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef CymunkTouchComponent py_component = self.components[
            component_index]
        cdef CymunkTouchStruct* component = <CymunkTouchStruct*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        gameworld = self.gameworld
        cdef SystemManager system_manager = gameworld.system_manager
        cdef str physics_id = self.physics_system
        cdef object physics_system = system_manager[physics_id]
        cdef Body touch_body = Body(None, None)
        cdef IndexedMemoryZone entities = gameworld.entities
        cdef tuple touch_pos = args['touch_pos']
        cdef unsigned int touched_ent = args['touched_ent']
        touched_entity = entities[touched_ent]
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
        py_component._touch_body = touch_body
        py_component._pivot = pivot
        space.add(pivot)
        component.touch_body = touch_body._body
        component.pivot = pivot._pivotjoint
        return self.entity_components.add_entity(entity_id, zone)

    def clear_component(self, unsigned int component_index):
        '''
        Clears the component at **component_index**. We must set the 
        pointers in the C struct to empty and the references in the 
        CymunkTouchComponent to None.

        Args:

            component_index (unsigned int): Component to remove.

        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef CymunkTouchStruct* pointer = <CymunkTouchStruct*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.touch_body = NULL
        pointer.pivot = NULL
        cdef CymunkTouchComponent py_component = self.components[
            component_index]
        py_component._pivot = None
        py_component._touch_body = None

    def remove_component(self, unsigned int component_index):
        '''
        Before we clear the component we perform some cleanup on the 
        physics objects, removing the _pivot PivotJoint from our Space. We 
        also remove our entity from the **entity_components** aggregator at 
        this time.

        Args:

            component_index (unsigned int): Component to remove.
            
        '''
        cdef CymunkTouchComponent component = self.components[component_index]
        self.entity_components.remove_entity(component.entity_id)
        gameworld = self.gameworld
        cdef str physics_id = self.physics_system
        cdef SystemManager system_manager = gameworld.system_manager
        physics_system = system_manager[physics_id]
        cdef Space space = physics_system.space
        space.remove(component._pivot)
        super(CymunkTouchSystem, self).remove_component(component_index)
    
    def on_touch_down(self, touch):
        '''
        The touch down handling for the CymunkTouchSystem queries the 
        CymunkPhysics GameSystem with system_id: **physics_system** to see 
        if any touches occur withtin a square of x +- **touch_radius**, y +-
        **touch_radius**. 

        If we do collide with an entity, we will take the first one and 
        bind a new rogue body (unattached from the physics Space) together 
        with the touched entity's physics Body by creating a PivotJoint.
        The new entity representing the PivotJoint will be created in zone: 
        **zone_to_use**.  

        '''
        cdef object gameworld = self.gameworld
        cdef SystemManager system_manager = gameworld.system_manager
        cdef object physics_system = system_manager[self.physics_system]
        cdef float tx = touch.x 
        cdef float ty = touch.y
        cdef str system_id = self.system_id
        cdef float max_force = self.max_force
        cdef float max_bias = self.max_bias
        cdef float radius = self.touch_radius
        cdef list touch_box = [tx-radius, ty-radius, tx-radius, ty+radius, 
            tx+radius, ty+radius, tx+radius, ty-radius]
        cdef list touched_ids = physics_system.query_bb(touch_box,
            ignore_groups=self.ignore_groups)
        if len(touched_ids) > 0:
            entity_id = touched_ids[0]
            creation_dict = {system_id: 
                {'touched_ent': entity_id, 'touch_pos': (tx, ty),
                'max_force': max_force, 'max_bias':max_bias}, 
                'position': (tx, ty)}
            touch_ent = gameworld.init_entity(creation_dict, ['position', 
                system_id], zone=self.zone_to_use)
            touch.ud['ent_id'] = touch_ent
            touch.ud['touched_ent_id'] = entity_id
            return True
        else:
            return False

    def on_touch_move(self, touch):
        '''
        The touch move handling keeps track of the touch entity generated in 
        on_touch_down, updating its position to the new position of the touch.
        '''

        cdef object gameworld 
        cdef SystemManager system_manager
        cdef object gameview
        cdef IndexedMemoryZone entities
        cdef tuple camera_pos
        cdef tuple touch_pos = (touch.x, touch.y)
        cdef float camera_scale 
        cdef tuple converted_pos 
        cdef unsigned int entity_id
        cdef object entity
        cdef PositionComponent2D pos_comp
        if 'ent_id' in touch.ud:
            gameworld = self.gameworld
            system_manager = gameworld.system_manager
            entities = gameworld.entities
            entity_id = touch.ud['ent_id']
            entity = entities[entity_id]
            pos_comp = entity.position
            pos_comp.pos = touch_pos

    def on_touch_up(self, touch):
        '''
        On touch up, if we have previously set the ud['ent_id'] in 
        on_touch_down we will remove this entity from the GameWorld as the 
        touch is now over.
        '''
        if 'ent_id' in touch.ud:
            self.gameworld.remove_entity(touch.ud['ent_id'])

    def update(self, float dt):
        gameworld = self.gameworld
        cdef CymunkTouchStruct* system_component 
        cdef PositionStruct2D* pos_comp
        cdef cpBody* body
        cdef cpVect p_position
        cdef cpVect body_pos
        cdef cpVect new_vel
        cdef cpVect new_point
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            pos_comp = <PositionStruct2D*>component_data[real_index+1]
            system_component = <CymunkTouchStruct*>component_data[real_index]
            body = system_component.touch_body
            body_pos = body.p
            new_point = cpvlerp(body_pos, cpv(pos_comp.x, pos_comp.y), .25)
            new_vel = cpvmult(cpvsub(new_point, body_pos),  60.)
            body.v = new_vel
            body.p = new_point


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

Factory.register('CymunkTouchSystem', cls=CymunkTouchSystem)

# class SteeringSystem(GameSystem):
#     physics_system = StringProperty(None)
#     updateable = BooleanProperty(True)

#     def generate_component(self, dict args):
#         cdef Body body = args['body']
#         cdef PivotJoint pivot = args['pivot']
#         cdef GearJoint gear = args['gear']
#         cdef float speed = args['speed']
#         new_component = SteeringComponent.__new__(SteeringComponent, 
#             body, pivot, gear, speed)
#         return new_component

#     def create_component(self, object entity, dict args):
#         cdef object gameworld = self.gameworld
#         cdef dict systems = gameworld.systems
#         cdef str physics_id = self.physics_system
#         cdef object physics_system = systems[physics_id]
#         cdef Body steering_body = Body(None, None)
#         cdef PhysicsComponent physics_data = getattr(entity, physics_id)
#         cdef Body body = physics_data.body
#         cdef PivotJoint pivot = PivotJoint(steering_body, body, (0, 0), (0, 0))
#         cdef GearJoint gear = GearJoint(steering_body, body, 0.0, 1.0)
#         gear.error_bias = 0.
#         pivot.max_bias = 0.0
#         pivot.error_bias = 0.
#         gear.max_bias = args['turn_speed']
#         gear.max_force = args['stability']
#         pivot.max_force = args['max_force']
#         cdef Space space = physics_system.space
#         space.add(pivot)
#         space.add(gear)
#         new_args = {'body': steering_body, 'pivot': pivot, 'gear': gear,
#             'speed': args['speed']}
#         super(SteeringSystem, self).create_component(entity, new_args)

#     def remove_entity(self, int entity_id):
#         cdef str system_id = self.system_id
#         cdef object gameworld = self.gameworld
#         cdef list entities = gameworld.entities
#         cdef object entity = entities[entity_id]
#         cdef SteeringComponent steering_data = getattr(entity, system_id)
#         cdef str physics_id = self.physics_system
#         cdef object physics_system = gameworld.systems[physics_id]
#         cdef Space space = physics_system.space
#         space.remove(steering_data._gear)
#         space.remove(steering_data._pivot)
#         super(SteeringSystem, self).remove_entity(entity_id)
        
#     def update(self, dt):
#         cdef list entity_ids = self.entity_ids
#         cdef object gameworld = self.gameworld
#         cdef list entities = gameworld.entities
#         cdef int entity_id
#         cdef str system_id = self.system_id
#         cdef str physics_id = self.physics_system
#         cdef SteeringComponent steering_data
#         cdef PhysicsComponent physics_data
#         cdef Body body
#         cdef Body steering_body
#         cdef float angle
#         cdef cpVect v1
#         cdef cpVect target
#         cdef tuple target_pos
#         cdef cpVect move_delta
#         cdef float turn
#         cdef tuple velocity_rot
#         cdef float speed
#         cdef cpVect unrot
#         cdef float x, y
#         cdef bool solve

#         for entity_id in entity_ids:
#             entity = entities[entity_id]
#             steering_data = getattr(entity, system_id)
#             physics_data = getattr(entity, physics_id)
#             if steering_data._active:
#                 body = physics_data._body
#                 target_pos = steering_data._target
#                 steering_body = steering_data._steering_body
#                 try:
#                     x, y = target_pos
#                 except:
#                     steering_body.velocity = (0., 0.)
#                     continue
#                 target = cpv(x, y)
#                 body_pos = body._body.p
#                 v1 = body._body.rot
#                 angle = body.angle
#                 speed = steering_data._speed
#                 move_delta = cpvsub(target, body_pos)
#                 unrot = cpvunrotate(v1, move_delta)
#                 turn = atan2(unrot.y, unrot.x)
#                 steering_body.angle = angle - turn
#                 if cpvnear(target, body_pos, 75.0):
#                     velocity_rot = (0., 0.)
#                 elif turn <= -1.3 or turn >= 1.3:
#                     velocity_rot = (0., 0.)
#                 else:
#                     new_vec = cpvrotate(v1, cpv(speed, 0.0))  
#                     velocity_rot = (new_vec.x, new_vec.y)
#                 steering_body.velocity = velocity_rot

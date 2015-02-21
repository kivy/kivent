# cython: profile=True
from kivy.uix.widget import Widget
from cwidget cimport CWidget
from kivy.properties import (StringProperty, ListProperty, 
    NumericProperty, DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from math import fabs
from kivy.core.window import Window
from functools import partial
from kivy.graphics import RenderContext
from kivy.graphics.transformation import Matrix
cimport cython
from kivy.vector import Vector
from entity cimport Entity
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from kivy.factory import Factory
from membuffer cimport (IndexedMemoryZone, MemComponent, Buffer, MemoryZone)
from system_manager cimport system_manager

class Component(object):
    
    def __init__(self, component_index, offset):
        self._id = component_index + offset


cdef class GameSystem(CWidget):
    '''GameSystem is the part of your game that holds the logic to operate 
    on the data of your Entity's components. They keep track of the entity_id
    of each entity that has a component for the system. The GameSystem is 
    responsible for the creation and deletion of its corresponding components.

    **Attributes:**
        **system_id** (StringProperty): Name of this gamesystem, used to name 
        entity component attribute, and refer to system.

        **updateable** (BooleanProperty): Boolean to let gameworld know 
        whether or not to run an update tick on this gamesystem. Defaults to 
        False

        **paused** (BooleanProperty): Boolean used to determine whether or not 
        this system should be updated on the current tickif updateable is True

        **gameworld** (ObjectProperty): Reference to the gameworld object, 
        usually bound in kv

        **gameview** (StringProperty): Name of the GameView this system will 
        be rendered too.

        **update_time** (NumericProperty): The 'tick' rate of this system's 
        update. Defaults to 1./60. or 60 FPS

        **entity_ids** (list): a list of entities that have an active
        component for this GameSystem

    '''

    system_id = StringProperty('default_id')
    system_index = NumericProperty(None)
    updateable = BooleanProperty(False)
    paused = BooleanProperty(False)
    gameworld = ObjectProperty(None)
    do_components = BooleanProperty(True)
    gameview = StringProperty(None, allownone=True)
    update_time = NumericProperty(1./60.)
    fields_to_clear = ListProperty([])
    zones = ListProperty([])

    property frame_time:
        def __get__(self):
            return self.frame_time

        def __set__(self, float value):
            self.frame_time = value

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self._frame_time = 0.0

    def on_gameview(self, instance, value):
        if self.parent is not None:
            self.parent.remove_widget(self)
        systems = system_manager.system_index
        if value not in systems:
            Clock.schedule_once(lambda dt: self.on_gameview(instance, value))
            return
        else:
            gameview = system_manager.get_system(value)
            gameview.add_widget(self)

    def update(self, dt):
        '''
        Args:
            dt (float): time argument passed in by Clock. Should be
            equivalent to update_time.

        Override this function to create your gamesystems update logic
        typically looks like:

        .. code-block:: python

            gameworld = self.gameworld
            entities = gameworld.entities
            for entity_id in self.entity_ids:
                entity = entities[entity_id]
                #Do your system logic per entity here
        '''
        pass

    def _update(self, float dt):
        '''
        This function is called internally in order to ensure that no time 
        is lost, excess time that is not quite another update_time
        is added to frame_time and consumed next tick.
        '''
        cdef float frame_time = self._frame_time
        frame_time += dt
        update_time = self.update_time
        update = self.update
        while frame_time >= update_time:
            update(update_time)
            frame_time -= update_time
        self._frame_time = frame_time

    def init_component(self, component, entity_id, args):
        '''Used internally to initialize the component'''
        for each in args:
            setattr(component, each, args[each])

    def clear_component(self, component):
        '''Used internally to recycle the component, every attribute listed
        in **fields_to_clear** will be set to None by default'''
        fields_to_clear = self.fields_to_clear
        for each in fields_to_clear:
            setattr(component, each, None)


    def generate_component(self):
        return Component()

    def create_component(self, entity_id, zone, args):
        component_index = self.get_component(zone)
        self.init_component(component_index, entity_id, args)
        return component_index

    def remove_component(self, int component_index):
        '''
        Args:
            entity_id (int): the entity_id for the entity being removed
            from the GameSystem

        Function used by GameWorld to remove an entity, you should ensure
        all data related to your component is cleaned up or recycled here'''
        # entity_component_index = self.entity_component_index
        # component_to_clear = self.components[component_index]
        # cdef int system_index = self.system_index
        # processor = self.gameworld.entity_processor
        # processor.set_component(entity_id, -1, system_index)
        # self.clear_component(component_to_clear)
        # self.unused_components.append(component_index)
        pass


    def on_remove_system(self):
        '''Function called when a system is removed during a gameworld state 
        change
        '''
        pass

    def on_add_system(self):
        '''Function called when a system is added during a gameworld state
        change'''
        pass

    def on_delete_system(self):
        '''Function called when a system is deleted by gameworld'''
        pass


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


cdef class PositionComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.entity_id

    property x:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.x
        def __set__(self, float value):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            data.x = value

    property y:
        def __get__(self):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            return data.y
        def __set__(self, float value):
            cdef PositionStruct2D* data = <PositionStruct2D*>self.pointer
            data.y = value


cdef class PositionSystem2D(StaticMemGameSystem):
    '''PositionSystem is optimized to hold location data for your entities.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects.'''
        
    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        cdef float x = args[0]
        cdef float y = args[1]
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef PositionStruct2D* component = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.x = x
        component.y = y

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef PositionStruct2D* pointer = <PositionStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.x = 0.
        pointer.y = 0.

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(PositionStruct2D), 
            reserve_spec, PositionComponent2D)


cdef class ScaleComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.entity_id

    property s:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return (data.sx + data.sy)/2.
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sx = value
            data.sy = value

    property sx:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.sx
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sx = value

    property sy:
        def __get__(self):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            return data.sy
        def __set__(self, float value):
            cdef ScaleStruct2D* data = <ScaleStruct2D*>self.pointer
            data.sy = value


cdef class ScaleSystem2D(StaticMemGameSystem):
    '''ScaleSystem is optimized to hold 2d scale data for your entities.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects. This object will
    potentially change in the future to support scaling at different
    rates in different directions.'''

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        cdef float sx, sy
        if isinstance(args, tuple):
            sx = args[0]
            sy = args[1]
        else:
            sx = args
            sy = args
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ScaleStruct2D* component = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.sx = sx
        component.sy = sy

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ScaleStruct2D* pointer = <ScaleStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.sx = 1.
        pointer.sy = 1.

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(ScaleStruct2D), 
            reserve_spec, ScaleComponent2D)


cdef class RotateComponent2D(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            return data.entity_id

    property r:
        def __get__(self):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            return data.r
        def __set__(self, float value):
            cdef RotateStruct2D* data = <RotateStruct2D*>self.pointer
            data.r = value


cdef class RotateSystem2D(StaticMemGameSystem):
    '''RotateSystem is optimized to hold a single rotate float for your 
    entities. The CymunkPhysics System and Renderers expect this to be an 
    angle in radians.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects. This object will
    potentially change in the future to support rotating around arbitrary axes
    '''

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, float r):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RotateStruct2D* component = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.r = r

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RotateStruct2D* pointer = <RotateStruct2D*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.r = 0.

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(RotateStruct2D), 
            reserve_spec, RotateComponent2D)


cdef class ColorComponent(MemComponent):
    
    property entity_id:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.entity_id

    property r:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.r
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.r = value

    property g:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.g
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.g = value

    property b:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.b
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.b = value

    property a:
        def __get__(self):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            return data.a
        def __set__(self, float value):
            cdef ColorStruct* data = <ColorStruct*>self.pointer
            data.a = value


cdef class ColorSystem(StaticMemGameSystem):
    '''RotateSystem is optimized to hold a single rotate float for your 
    entities. The CymunkPhysics System and Renderers expect this to be an 
    angle in radians.
    The rendering systems will be able to interact with this data using the
    underlying C structures rather than the Python objects. This object will
    potentially change in the future to support rotating around arbitrary axes
    '''

    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, args):
        cdef float r = args[0]
        cdef float g = args[1]
        cdef float b = args[2]
        cdef float a = args[3]
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ColorStruct* component = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        component.entity_id = entity_id
        component.r = r
        component.g = g
        component.b = b
        component.a = a

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef ColorStruct* pointer = <ColorStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        pointer.r = 1.
        pointer.g = 1.
        pointer.b = 1.
        pointer.a = 1.

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(ColorStruct), 
            reserve_spec, ColorComponent)


class GameMap(GameSystem):
    '''GameMap is a basic implementation of a map size for your GameWorld that
    limits the scrolling of GameView typically a GameMap does not actually
    have any entities, it simply holds some data and logic for use by
    other GameSystems

    **Attributes:**
        **map_size** (ListProperty): Sets the size of this map, used to 
        determine scrolling bounds. If the map size is smaller than the 
        window it will be centered inside the window.

        **margins** (ListProperty): The amount of scrolling beyond the size of 
        the map in x, y directions to be allowed. If the map is smaller than 
        the window. This value is calculated automatically.

        **default_margins** (ListProperty): The amount of margin if the map is 
        larger than the window, defaults to (0, 0) which means no scrolling 
        beyond edge of GameMap.

    '''
    system_id = StringProperty('default_map')
    map_size = ListProperty((2000., 2000.))
    window_size = ListProperty((0., 0.))
    margins = ListProperty((0., 0.))
    map_color = ListProperty((1., 1., 1., 1.))
    do_components = BooleanProperty(False)
    default_margins = ListProperty((0., 0.))

    def on_map_size(self, instance, value):
        self.check_margins()

    def on_size(self, instance, value):
        self.check_margins()

    def check_margins(self):
        map_size = self.map_size
        window_size = Window.size
        window_larger_x = False
        window_larger_y = False
        if window_size[0] > map_size[0]:
            margin_x = (window_size[0] - map_size[0])/2.
            window_larger_x = True
        if window_size[1] > map_size[1]:
            margin_y = (window_size[1] - map_size[1])/2.
            window_larger_y = True
        if window_larger_x:
            self.margins[0] = margin_x
        if window_larger_y:
            self.margins[1] = margin_y
        if not window_larger_x and not window_larger_y:
            self.margins = self.default_margins
 

cdef class LerpObject:

    def __cinit__(self, str component_name, str property_name, float max_time,
        list start_vals, list end_vals, str lerp_mode, callback=None):
        self._component = component_name
        self._property = property_name
        self._max_time = max_time
        self._current_time = 0.
        self._start_vals = start_vals
        self._end_vals = end_vals
        self._lerp_mode = lerp_mode
        self._callback = callback

    property lerp_mode:
        def __get__(self):
            return self._lerp_mode
        def __set__(self, str value):
            self._lerp_mode = value

    property component:
        def __get__(self):
            return self._component
        def __set__(self, str value):
            self._component = value

    property property_name:
        def __get__(self):
            return self._property
        def __set__(self, str value):
            self._property = value

    property current_time:
        def __get__(self):
            return self._current_time
        def __set__(self, float value):
            self._current_time = value

    property max_time:
        def __get__(self):
            return self._max_time
        def __set__(self, float value):
            self._max_time = value

    property end_val:
        def __get__(self):
            return self._end_val
        def __set__(self, list value):
            self._end_vals = value

    property start_val:
        def __get__(self):
            return self._start_val
        def __set__(self, list value):
            self._start_vals = value

cdef float lerp(float v0, float v1, float t):
    return (1. - t) * v0 + t * v1

cdef class LerpComponent:

    def __cinit__(self):
        self._lerp_objects = []

class LerpSystem(GameSystem):
    '''The LerpSystem can be used to automatically lerp the python value 
    of a component attribute to a set value over time. To start with the
    LerpComponent of your entity will do nothing, you must call 
    **add_lerp_to_entity** to cause behavior to occur.'''

    def add_lerp_to_entity(self, int entity_id, str component_name, 
        str property_name, object end_value, float lerp_time, str lerp_mode,
        callback=None):
        '''Adds a LerpObject to the LerpComponent of Entity entity_id. This 
        will lerp the attribute: property_name of that entity's component_name
        component between its current value and end_value over the time
        lerp_time provided. lerp_mode can be float, tuple, or list. You can
        provide optional callback arg to bind a function that will be called 
        when this lerp completes. The callback will receive args: entity_id, 
        component_name, property_name, final_value'''
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef object entity = entities[entity_id]
        cdef object component = getattr(entity, component_name)
        cdef list end_vals, start_vals
        cdef LerpComponent lerp_comp = getattr(entity, self.system_id)
        if lerp_mode == 'float':
            end_vals = [end_value]
            start_vals = [getattr(component, property_name)]
        else:
            end_vals = [val for val in end_value]
            start_vals = [val for val in getattr(component, property_name)]
        cdef lerp_object = LerpObject(component_name, property_name, lerp_time,
            start_vals, end_vals, lerp_mode, callback=callback)
        cdef list lerp_objects = lerp_comp._lerp_objects
        lerp_objects.append(lerp_object)

    def clear_lerps_from_entity(self, int entity_id):
        '''Removes all LerpObjects from the LerpComponent of Entity entity_id.'''
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef object entity = entities[entity_id]
        cdef LerpComponent lerp_comp = getattr(entity, self.system_id)
        cdef list lerp_objects = lerp_comp._lerp_objects
        del lerp_objects[:]

    def generate_component(self, args):
        new_component = LerpComponent.__new__(LerpComponent)
        return new_component

    def init_component(self, component, entity_id, args):
        '''Used internally to initialize the component'''
        pass

    def clear_component(self, LerpComponent component):
        '''Used internally to recycle the component'''
        component._lerp_objects = []

    
    def update(self, dt):
        cdef object gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef dict systems = gameworld.systems
        cdef str system_id = self.system_id
        cdef int entity_id
        cdef object entity
        cdef LerpComponent lerp_comp
        cdef list entity_ids = self.entity_ids
        cdef int ent_ind
        cdef list lerp_objects
        cdef LerpObject lerp_object
        cdef LerpObject object_to_remove
        cdef int lerp_ind
        cdef int lerp_num
        cdef object to_lerp_comp
        cdef float tot_time, current_time, t_val
        cdef list objects_to_remove
        cdef int remove_ind, remove_len
        cdef int num_entities = len(entity_ids)
        cdef list end_vals, start_vals
        cdef list new_list
        cdef tuple new_tuple
        cdef int new_tuple_int
        cdef int new_tuple_len
        cdef int new_list_ind
        cdef str component
        cdef int new_list_len
        cdef str lerp_mode
        for ent_ind in range(num_entities):
            entity_id = entity_ids[ent_ind]
            entity = entities[entity_id]
            lerp_comp = getattr(entity, system_id)
            lerp_objects = lerp_comp._lerp_objects
            objects_to_remove = []
            objects_a = objects_to_remove.append
            lerp_num = len(lerp_objects)
            for lerp_ind in range(lerp_num):
                lerp_object = lerp_objects[lerp_ind]
                lerp_object._current_time += dt
                tot_time = lerp_object._max_time
                current_time = lerp_object._current_time
                component = lerp_object._component
                to_lerp_comp = getattr(entity, lerp_object._component)
                if current_time >= tot_time:
                    objects_a(lerp_object)
                    callback = lerp_object._callback
                    if callback is not None:
                        callback(entity_id, lerp_object._component,
                            lerp_object._property, getattr(to_lerp_comp, 
                                lerp_object._property))
                t_val = current_time/tot_time
                end_vals = lerp_object._end_vals
                start_vals = lerp_object._start_vals
                
                lerp_mode = lerp_object._lerp_mode
                if lerp_mode == 'float':
                    setattr(to_lerp_comp, lerp_object._property, 
                        lerp(start_vals[0], end_vals[0], t_val))
                elif lerp_mode == 'tuple':
                    new_tuple = tuple()
                    new_tuple_len = len(start_vals)
                    for new_tuple_ind in range(new_tuple_len):
                        new_tuple[new_tuple_ind] = lerp(
                            start_vals[new_tuple_ind],
                            end_vals[new_tuple_ind], t_val)
                else:
                    new_list = []
                    new_list_len = len(start_vals)
                    for new_list_ind in range(new_list_len):
                        new_list[new_list_ind] = lerp(start_vals[new_list_ind], 
                            end_vals[new_list_ind], t_val)
                    setattr(to_lerp_comp, lerp_object._property, new_list)
            remove_len = len(objects_to_remove)
            for remove_ind in range(remove_len):
                object_to_remove = objects_to_remove[remove_ind]
                lerp_objects.remove(object_to_remove)




class GameView(GameSystem):
    '''GameView provides a simple camera system that will control the rendering
    view of any other **GameSystem** that has had the **gameview** property set 
    **GameSystem** that have a **gameview** will be added to the GameView
    canvas instead of the GameWorld canvas. 

    **Attributes:**
        **do_scroll_lock** (BooleanProperty): If True the scrolling will be 
        locked to the bounds of the GameWorld's currentmap.

        **camera_pos** (ListProperty): Current position of the camera
        
        **camera_scale** (NumericProperty): Current scale of the camera. The 
        scale is equal to the amount of the game world that will be shown 
        compared to the physical size of the GameView, therefore 2x will show 
        twice as much of your gameworld, appearing 'zoomed out', while .5 will 
        show half as much of the gameworld, appearing 'zoomed in'.  

        **focus_entity** (BooleanProperty): If True the camera will follow the 
        entity set in entity_to_focus

        **do_scroll** (BooleanProperty): If True touches will scroll the camera

        **entity_to_focus** (NumericProperty): Entity entity_id for the camera 
        to focus on if focus_entity is True.

        **camera_speed_multiplier** (NumericProperty): Time it will take camera 
        to reach focused entity, Speed will be 1.0/camera_speed_multiplier 
        seconds to close the distance

        **render_system_order** (ListProperty): List of **system_id** in the 
        desired order of rendering last to first. **GameSystem** with 
        **system_id** not in **render_system_order** will be inserted at
        position 0. 
 
        **move_speed_multiplier** (NumericProperty): Multiplier to further 
        control the speed of touch dragging of camera. Example Usage: 
        Bind to the size of your gameview divided by the size of the window
        to ensure that apparent dragging speed stays consistent. 

        **do_touch_zoom** (BooleanProperty): If True the camera will zoom with
        2 finger touch interaction.

        **scale_min** (NumericProperty): The minimum scale factor that will be
        allowed when touch zoom is being used. This will be the most 'zoomed
        in' your camera will be allowed to go. This limit do not apply
        when manually manipulated **camera_scale**.

        **scale_max** (NumericProperty): The maximum scale factor that will be
        allowed when touch zoom is being used. This will be the most 'zoomed 
        out' your camera will be allowed to go. This limit do not apply
        when manually manipulated **camera_scale**.

    '''
    system_id = StringProperty('default_gameview')
    do_scroll_lock = BooleanProperty(True)
    camera_pos = ListProperty((0, 0))
    camera_scale = NumericProperty(1.0)
    focus_entity = BooleanProperty(False)
    do_touch_zoom = BooleanProperty(False)
    do_scroll = BooleanProperty(True)
    entity_to_focus = NumericProperty(None, allownone=True)
    updateable = BooleanProperty(True)
    scale_min = NumericProperty(.5)
    scale_max = NumericProperty(8.)
    camera_speed_multiplier = NumericProperty(1.0)
    render_system_order = ListProperty([])
    move_speed_multiplier = NumericProperty(1.0)
    do_components = BooleanProperty(False)
    currentmap = ObjectProperty(None)

    def __init__(self, **kwargs):
        super(GameView, self).__init__(**kwargs)
        self.matrix = Matrix()
        self._touch_count = 0
        self._touches = []
        self.canvas = RenderContext()

    def get_camera_centered(self, map_size, camera_size, camera_scale):
        x = max((camera_size[0]*camera_scale - map_size[0])/2., 0.)
        y = max((camera_size[1]*camera_scale - map_size[1])/2., 0.)
        return (x, y)

    def update_render_state(self):
        '''
        Used internally by gameview to update the projection matrix to properly
        reflect the settings for camera_size, camera_pos, and the pos and size
        of gameview.'''
        camera_pos = self.camera_pos
        camera_size = self.size
        pos = self.pos
        camera_scale = self.camera_scale
        proj = self.matrix.view_clip(
            -camera_pos[0], 
            camera_size[0]*camera_scale + -camera_pos[0], 
            -camera_pos[1], 
            camera_size[1]*camera_scale + -camera_pos[1],
            0., 100, 0)

        self.canvas['projection_mat'] = proj

    def add_widget(self, widget):
        gameworld = self.gameworld
        cdef str system_id
        if isinstance(widget, GameSystem):
            render_system_order = self.render_system_order
            system_id = widget.system_id
            if system_id in render_system_order:
                index=render_system_order.index(system_id)
            else:
                index=0
            super(GameView, self).add_widget(widget, index=index)
            system_index = system_manager.system_index
            if widget.system_id not in system_index:
                Clock.schedule_once(lambda dt: gameworld.add_system(widget))
        else:
            super(GameView, self).add_widget(widget)
        

    def remove_widget(self, widget):
        if isinstance(widget, GameSystem):
            widget.on_remove_system()
        super(GameView, self).remove_widget(widget)


    def on_entity_to_focus(self, instance, value):
        if value ==  None:
            self.focus_entity = False
        else:
            self.focus_entity = True

    def update(self, dt):
        cdef int entity_to_focus
        cdef float dist_x
        cdef float dist_y
        cdef object entity
        cdef float camera_speed_multiplier
        cdef PositionComponent position_data
        gameworld = self.gameworld
        if self.focus_entity:
            entity_to_focus = self.entity_to_focus
            entity = gameworld.entities[entity_to_focus]
            position_data = entity.position
            camera_pos = self.camera_pos
            camera_speed_multiplier = self.camera_speed_multiplier
            camera_size = self.size
            camera_scale = self.camera_scale
            size = camera_size[0] * camera_scale, camera_size[1] * camera_scale 
            dist_x = -camera_pos[0] - position_data._x + size[0]*.5
            dist_y = -camera_pos[1] - position_data._y + size[1]*.5
            if self.do_scroll_lock:
               dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
            self.camera_pos[0] += dist_x*camera_speed_multiplier*dt
            self.camera_pos[1] += dist_y*camera_speed_multiplier*dt
        self.update_render_state()

    def on_size(self, instance, value):
        if self.do_scroll_lock and self.currentmap:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y
        self.update_render_state()

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            touch.grab(self)
            self._touch_count += 1
            self._touches.append(touch)
            camera_pos = self.camera_pos
            size = self.size
            touch.ud['world_pos'] = self.get_camera_center()
            touch.ud['start_pos'] = touch.pos
            touch.ud['start_scale'] = self.camera_scale

    def on_touch_up(self, touch):
        if touch.grab_current is self:
            self._touch_count -= 1
            self._touches.remove(touch)

    def get_camera_center(self):
        '''Returns the current center point of the cameras view'''
        cx, cy = self.camera_pos
        size = self.size
        camera_scale = self.camera_scale
        sw, sh = size[0] * camera_scale *.5, size[1] * camera_scale * .5
        return sw - cx, sh - cy

    def convert_from_screen_to_world(self, pos):
        '''Converts the coordinates of pos from screen space to camera space'''
        #pos of touch
        x,y = pos
        print(pos, self.camera_pos)
        print(self.pos, self.size)
        #pos of widget
        rx, ry = self.pos
        cx, cy = self.camera_pos
        #touch pos converted to widget space
        wx, wy = x - rx, y - ry
        camera_scale = self.camera_scale
        map_x, map_y = (wx * camera_scale) - cx, (wy * camera_scale) - cy

        world_x = map_x
        world_y = map_y
        print(world_x, world_y)
        return world_x, world_y


    def look_at(self, pos):
        '''Set the camera to be focused at pos.'''
        camera_size = self.size
        camera_scale = self.camera_scale
        camera_pos = self.camera_pos
        self.camera_pos[0] = -pos[0] + camera_size[0]*.5*camera_scale
        self.camera_pos[1] = -pos[1] + camera_size[1]*.5*camera_scale


    def on_touch_move(self, touch):
        if touch.grab_current is self:
            move_speed_multiplier = self.move_speed_multiplier
            if not self.focus_entity and self.do_touch_zoom:
                if self._touch_count > 1:

                    points = [Vector(t.x, t.y) for t in self._touches]
                    anchor = max(
                        points[:], key=lambda p: p.distance(touch.pos))
                    an_index = points.index(anchor)
                    anchor_touch = self._touches[an_index]
                    farthest = max(points, key=anchor.distance)
                    if farthest is not points[-1]:
                        return
                    old_line = Vector(*touch.ud['start_pos']) - anchor
                    new_line = Vector(*touch.pos) - anchor
                    if not old_line.length() or not new_line.length():   # div by zero
                        return

                    new_scale = (old_line.length() / new_line.length()) * (
                        touch.ud['start_scale'])
                    if new_scale > self.scale_max:
                        self.camera_scale = self.scale_max
                    elif new_scale < self.scale_min:
                        self.camera_scale = self.scale_min
                    else:
                        self.camera_scale = new_scale
                    self.look_at(anchor_touch.ud['world_pos'])
                    


            if not self.focus_entity and self.do_scroll:
                if self._touch_count == 1:
                    camera_scale = self.camera_scale
                    dist_x = touch.dx * camera_scale * move_speed_multiplier
                    dist_y = touch.dy * camera_scale * move_speed_multiplier
                
                    if self.do_scroll_lock and self.currentmap:
                        dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
                    self.camera_pos[0] += dist_x
                    self.camera_pos[1] += dist_y

    def lock_scroll(self, float distance_x, float distance_y):
        currentmap = self.currentmap
        camera_size = self.size
        pos = self.pos
        scale = self.camera_scale
        size = camera_size[0]*scale, camera_size[1]*scale
        map_size = currentmap.map_size
        margins = currentmap.margins
        camera_pos = self.camera_pos
        cdef float x= pos[0]
        cdef float y = pos[1]
        cdef float w = size[0]
        cdef float h = size[1]
        cdef float mw = map_size[0]
        cdef float mh = map_size[1]
        cdef float marg_x = margins[0]
        cdef float marg_y = margins[1]
        cdef float cx = camera_pos[0]
        cdef float cy = camera_pos[1]

        if cx + distance_x > x + marg_x:
            distance_x = x - cx + marg_x
        elif cx + mw + distance_x <= x + w - marg_x:
            distance_x = x + w - marg_x - cx - mw

        if cy + distance_y > y + marg_y:
            distance_y = y - cy + marg_y 
        elif cy + mh + distance_y <= y + h - marg_y:
            distance_y = y + h - cy - mh  - marg_y

        return distance_x, distance_y

Factory.register('GameSystem', cls=GameSystem)
Factory.register('PositionSystem2D', cls=PositionSystem2D)
Factory.register('RotateSystem2D', cls=RotateSystem2D)
Factory.register('ColorSystem', cls=ColorSystem)
Factory.register('ScaleSystem2D', cls=ScaleSystem2D)
Factory.register('GameView', cls=GameView)
Factory.register('GameMap', cls=GameMap)
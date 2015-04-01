from kivent_core.uix.cwidget cimport CWidget
from kivy.properties import (StringProperty, ListProperty, 
    NumericProperty, BooleanProperty, ObjectProperty)
from kivent_core.managers.system_manager cimport system_manager
from kivy.clock import Clock
from kivy.factory import Factory
from kivent_core.managers.entity_manager cimport EntityManager
from kivy.logger import Logger
from kivent_core.gameworld import debug
from collections import deque

class Component(object):
    '''A component will keep track of the data for your GameSystems logic.
    It keeps track of its own identity (index in the components list), and
    the entity_id of its entity. If the entity_id returned is <unsigned int>-1
    the component is not currently attached to an entity'''
    
    def __init__(self, component_id):
        self._id = component_id
        self.entity_id = <unsigned int>-1


cdef class GameSystem(CWidget):
    '''GameSystem is the part of your game that holds the logic to operate 
    on the data of your Entity's components. It will also manage assembling,
    cleaning up, and destroying the systems component.
    The basic GameSystem keeps track of **Component** objects, which is a 
    regular Python object supporting all the dynamic nature of python but 
    without many static optimizations. 
    The basic setup is that we will create a Component object and release them
    for garbage collection when the entity is done. We will avoid resizing the
    components list by reusing space in the list (a component will be cleared
    to None when removed and an internal free list will provide these spaces
    before growing the list).

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
        be rendered too. If set to None the system will instead be rendered
        to GameWorld's canvas. The default value is None

        **update_time** (NumericProperty): The 'tick' rate of this system's 
        update. Defaults to 1./60. or 60 FPS

        **components** (list): a list of the components currently active. 
        If the list contains None at an index that component has been recently
        released for GC and a free list is being maintained internally. Skip
        these values during processing.

    '''

    system_id = StringProperty(None, allownone=True)
    system_index = NumericProperty(None)
    updateable = BooleanProperty(False)
    paused = BooleanProperty(False)
    gameworld = ObjectProperty(None)
    gameview = StringProperty(None, allownone=True)
    update_time = NumericProperty(1./60.)

    property frame_time:
        def __get__(self):
            return self._frame_time

        def __set__(self, float value):
            self._frame_time = value

    property components:
        def __get__(self):
            return self.py_components

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self.py_components = []
        self.free_indices = deque()
        self.component_count = 0
        self._frame_time = 0.0

    def on_gameview(self, instance, value):
        if self.parent is not None:
            self.parent.remove_widget(self)
        if value is None:
            self.gameworld.add_widget(self)
        systems = system_manager.system_index
        if value not in systems:
            #reschedule if we do not find the gameview created yet.
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
            for component in self.components:
                #make sure to skip released components.
                if component is not None:
                    #If we need other components from the entity let us retrieve
                    it like this:
                    entity_id = component.entity_id
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
            if debug:
                Logger.debug('KivEnt: {system_id} update started'.format(
                    system_id=self.system_id))
            update(update_time)
            frame_time -= update_time
        self._frame_time = frame_time

    def init_component(self, component_index, entity_id, args):
        '''Override this function to provide custom logic for setting up your 
        component, by default each key, val pair of args will be setattr on 
        the component.'''
        component = self.py_components[component_index]
        component.entity_id = entity_id
        for each in args:
            setattr(component, each, args[each])

    def clear_component(self, component_index):
        '''Override this function if we must cleanup the component in some way 
        before destroying or reusing it.'''
        pass

    def get_component(self, zone):
        free = self.free_indices
        if len(free) > 0:
            index = free.popleft()
            self.py_components[index] = Component(index)
        else:
            index = self.component_count
            self.component_count += 1
            self.py_components.append(Component(index))
        return index

    def create_component(self, unsigned int entity_id, str zone, args):
        component_index = self.get_component(zone)
        cdef EntityManager entity_manager = self.gameworld.entity_manager
        cdef unsigned int system_index = self.system_index
        entity_manager.set_component(entity_id, component_index, 
            system_index)
        self.init_component(component_index, entity_id, args)
        return component_index

    def remove_component(self, unsigned int component_index):
        '''
        Typically this will be called automatically by GameWorld. If you want to 
        remove a component without destroying the entity call this function 
        directly. 
        If you want to override the behavior of component cleanup override 
        **clear_component** instead. Only override this function if you
        are working directly with the storage of components for your system.
        Args:
            component_index (int): the component_id to be removed.

        '''
        self.clear_component(component_index)
        self.py_components[component_index] = None
        self.free_indices.append(component_index)
        

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


Factory.register('GameSystem', cls=GameSystem)
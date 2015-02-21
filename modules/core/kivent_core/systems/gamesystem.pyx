from kivent_core.uix.cwidget cimport CWidget
from kivy.properties import (StringProperty, ListProperty, 
    NumericProperty, BooleanProperty, ObjectProperty)
from kivent_core.managers.system_manager cimport system_manager
from kivy.clock import Clock
from kivy.factory import Factory


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


Factory.register('GameSystem', cls=GameSystem)
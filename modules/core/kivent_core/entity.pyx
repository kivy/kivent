from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

cdef class Entity:
    '''Entity is a python object that will hold all of the components
    attached to that particular entity. GameWorld is responsible for creating
    and recycling entities. You should never create an Entity directly or 
    modify an entity_id.
    
    **Attributes:**
        **entity_id** (int): The entity_id will be assigned on creation by the
        GameWorld. You will use this number to refer to the entity throughout
        your Game. 

        **load_order** (list): The load order is the order in which GameSystem
        components should be initialized.


    '''
    def __cinit__(self, int entity_id, int component_count, dict systems):
        self._id = entity_id
        self._load_order = []
        self._component_count = component_count
        self._component_ids = component_ids = <int *>PyMem_Malloc(
            component_count* sizeof(int))
        self._systems = systems
        if not component_ids:
            raise MemoryError()

    def __dealloc__(self):
        if self._component_ids != NULL:
            PyMem_Free(self._component_ids)

    def __getattr__(self, name):
        system = self._systems[name]
        system_index = system.system_index
        component_index = self._component_ids[system_index]
        if component_index == -1:
            raise IndexError()
        return system.components[component_index]

    property entity_id:
        def __get__(self):
            return self._id

    property component_count:

        def __set__(self, int new_count):
            if new_count == self._component_count:
                return
            new_data = <int *>PyMem_Realloc(self._component_ids, 
                new_count * sizeof(int))
            if not new_data:
                raise MemoryError()
            self._component_ids = new_data
            self._component_count = new_count

        def __get__(self):
            return self._component_count

    property load_order:
        def __get__(self):
            return self._load_order

        def __set__(self, list value):
            self._load_order = value
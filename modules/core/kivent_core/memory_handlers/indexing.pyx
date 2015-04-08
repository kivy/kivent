from block cimport MemoryBlock
from zone cimport MemoryZone
from pool cimport MemoryPool
from membuffer cimport Buffer


cdef class BlockIndex:
    '''Ties a single MemoryBlock to a set of block_count MemComponent objects,
    making the data held in MemoryBlock accessible from Python. See 
    systems.staticmemgamesystem.MemComponent for a barebones implementation of 
    such an object.

    **Attributes:**

        **blocks** (list): List of the objects created to wrap the data in 
        MemoryBlock, can be accessed from Cython as **block_objects**. Index
        in this list to get a MemComponent object wrapping the data held in 
        MemoryBlock.
    '''

    def __cinit__(self, MemoryBlock memory_block, unsigned int offset, 
        ComponentToCreate):
        '''
        A ComponentToCreate object will be created for each slot in the 
        MemoryBlock.
        Args:
            memory_block (MemoryBlock): The MemoryBlock that should be indexed.

            offset (unsigned int): If the MemoryBlock is part of a pool it will
            have an offset, determining the actual index of each data object,
            location in the pool = location in block + offset.

            ComponentToCreate (object): The object that we will wrap each 
            slot in the MemoryBlock with. Will receive args: memory_block, index
            in block, offset of block.
        '''
        cdef unsigned int count = memory_block.size 
        self.block_objects = block_objects = []
        block_a = block_objects.append
        cdef unsigned int i
        for i in range(count):
            new_component = ComponentToCreate.__new__(ComponentToCreate, 
                memory_block, i, offset)
            block_a(new_component)

    property blocks:
        def __get__(self):
            return self.block_objects


cdef class PoolIndex:
    '''The PoolIndex will generate a BlockIndex for every MemoryBlock in the 
    MemoryPool, making the data in the entire MemoryPool accessible from Python.

    **Attributes:**

        **block_indices** (list): A list of the BlockIndex for the pool. 
        Accessible in Cython via **_block_indices**. 
    '''

    def __cinit__(self, MemoryPool memory_pool, unsigned int offset, 
        ComponentToCreate):
        '''
        A BlockIndex will be created using ComponentToCreate for every 
        MemoryBlock in the pool.
        Args:
            memory_pool (MemoryPool): The MemoryPool that should be indexed.

            offset (unsigned int): The offset of the MemoryPool if multiple
            MemoryPool are being indexed as is the case with a MemoryZone. Will
            be the starting offset for the first BlockIndex, with each 
            subsequent BlockIndex incrementing the offset by the size of the 
            MemoryBlock being indexed. 

            ComponentToCreate (object): The object that we will wrap each 
            slot in the MemoryBlock with. Will receive args: memory_block, index
            in block, offset of block.
        '''
        cdef unsigned int count = memory_pool.block_count
        cdef list blocks = memory_pool.memory_blocks
        self._block_indices = block_indices = []
        block_ind_a = block_indices.append
        cdef unsigned int i
        cdef unsigned int block_count
        cdef MemoryBlock block
        for i in range(count):
            block = blocks[i]
            block_ind_a(BlockIndex(block, offset, ComponentToCreate))
            offset += block.size

    property block_indices:
        def __get__(self):
            return self._block_indices


cdef class ZoneIndex:
    '''The ZoneIndex will generate a PoolIndex for every MemoryPool in the 
    MemoryZone, making the data in the entire MemoryZone accessible from Python.

    **Attributes:**

        **pool_indices** (list): A list of the PoolIndex for the zone. 
        Accessible in Cython via **_pool_indices**. 
    '''

    def __cinit__(self, MemoryZone memory_zone, ComponentToCreate):
        '''
        A PoolIndex will be created using ComponentToCreate for every 
        MemoryPool in the zone..
        Args:
            memory_zone (MemoryZone): The MemoryZone that should be indexed.

            ComponentToCreate (object): The object that we will wrap each 
            slot in the MemoryBlock with. Will receive args: memory_block, index
            in block, offset of block.
        '''
        cdef unsigned int count = memory_zone.reserved_count
        cdef dict pool_indices = {}
        cdef dict memory_pools = memory_zone.memory_pools
        cdef unsigned int offset = 0
        cdef unsigned int pool_count
        cdef unsigned int i
        self.memory_zone = memory_zone
        cdef MemoryPool pool
        for i in range(count):
            pool = memory_pools[i]
            pool_count = pool.count
            pool_indices[i] = PoolIndex(pool, offset, ComponentToCreate)
            offset += pool_count
        self._pool_indices = pool_indices

    property pool_indices:
        def __get__(self):
            return self._pool_indices

    def get_component_from_index(self, unsigned int index):
        '''Will retrieve a single object of the type ComponentToCreate the 
        ZoneIndex was initialized with.
        Args:
            index (unsigned int): The index of the component you wish to 
            retrieve.
        Return:
            object: Returns a python accessible object wrapping the data found
            in the MemoryZone.
        '''
        pool_i, block_i, slot_i = self.memory_zone.get_pool_block_slot_indices(
            index)
        cdef PoolIndex pool_index = self._pool_indices[pool_i]
        cdef BlockIndex block_index = pool_index._block_indices[block_i]
        return block_index.block_objects[slot_i]


cdef class IndexedMemoryZone:
    '''An IndexedMemoryZone will create both a MemoryZone and a ZoneIndex
    allowing access to your data both from python (via normal list __getitem__
    syntax) and cython (via **get_pointer**). Python slicing syntax is also 
    supported and a list of components will be returned if a slice object is 
    provided to __getitem__.
    In Python:
        component_object = self[component_index]
        or
        component_objects = self[start_index:end_index:step]
    In Cython:
        cdef void* pointer = self.get_pointer(component_index)

    **Attributes:**

        **memory_zone** (MemoryZone): The actual MemoryZone holding the data
        to be indexed.

        **zone_index** (ZoneIndex): The ZoneIndex for the memory_zone.
    '''
    
    def __cinit__(self, Buffer master_buffer, unsigned int block_size,
        unsigned int component_size, dict reserved_spec, ComponentToCreate):
        '''Allocates both a MemoryZone and and a ZoneIndex on initialization.
        Args:
            master_buffer (Buffer): The Buffer from which we will allocate the 
            MemoryZone.

            block_size (unsigned int): The size of the MemoryBlock in the 
            MemoryZone in kibibytes.

            component_size (unsigned int): The size in bytes of the data to be 
            stored in the MemoryZone typically should be the result of a call
            to sizeof().

            reserved_spec (dict): The dict of the zone_name, zone_count in 
            this MemoryZone.

            ComponentToCreate (object): The object we will wrap the data in 
            MemoryZone with for the ZoneIndex.
        '''
        cdef MemoryZone memory_zone = MemoryZone(block_size, 
            master_buffer, component_size, reserved_spec)
        cdef ZoneIndex zone_index = ZoneIndex(memory_zone, ComponentToCreate)
        self.zone_index = zone_index
        self.memory_zone = memory_zone

    def __getitem__(self, value):
        cdef ZoneIndex zone_index
        if isinstance(value, slice):
            zone_index = self.zone_index
            get_component_from_index = zone_index.get_component_from_index
            step = value.step
            if step is None:
                step = 1
            return [get_component_from_index(i) for i in range(value.start,
                value.stop, step)]
        else:
            return self.zone_index.get_component_from_index(value)

    cdef void* get_pointer(self, unsigned int index) except NULL:
        '''Returns a pointer to the data for the slot at index.
        Args:
            index (unsigned int): Index of the slot to get data from.
        Return:
            void*: pointer to the data held at index.
        '''
        return self.memory_zone.get_pointer(index)

    cdef unsigned int get_size(self):
        '''Returns the total size in bytes of the **memory_zone**.
        Return:
            unsigned int: size in bytes
        '''
        return self.memory_zone.get_size()
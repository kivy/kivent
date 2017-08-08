from cpython cimport bool
from libc.stdlib cimport malloc, free

cdef class Buffer:
    '''The KivEnt Buffer allocates a static amount of memory and manages it by
    keeping a list of free_blocks. This type of memory handling is suitable for
    the pooling of objects. The Buffer is the only object of this type that
    calls malloc or free directly. The MemoryBlock, MemoryPool, and MemoryZone
    are all designed to allocate themselves from a Buffer or another
    MemoryBlock. The Buffer does not change its size.

    The physical size of the buffer will be **size_in_bytes** and this will be
    split into **size_in_bytes** // **type_size** 'blocks'.

    You must call **allocate_memory** on a Buffer in order to actually acquire
    the memory. In KivEnt, this will nearly always be done as part of the
    GameWorld.allocate.

    **Attributes: (Cython Access Only)**
        **size** (unsigned int): The number of blocks (**real_size** /
        **type_size**) that will fit in the Buffer.

        **data** (void*): Pointer to the beginning of the data array.

        **used_count** (unsigned int): The number of blocks currently in use,
        use is either actively storing memory or in the free list waiting for
        reuse.

        **free_blocks** (list): A list of previously used blocks or a
        contiguous collection of blocks, each entrant is a tuple of block_index,
        block_count.

        **free_block_count** (unsigned int): The number of entrants in the
        **free_blocks** list, a single entrant could actually be comprised of
        multiple blocks, held contiguously.

        **data_in_free** (unsigned int): The actual number of blocks held in
        the **free_blocks** list.

        **type_size** (unsigned int): The size of a single block in bytes.

        **real_size** (unsigned int): The size in bytes of the entire Buffer.

        **size_in_blocks** (unsigned int): The number of blocks allocated from
        the parent buffer. Unused in the basic Buffer, but used by subclasses
        such as MemoryBlock.
    '''

    def __cinit__(self, unsigned int size_in_blocks, unsigned int type_size,
        unsigned int master_block_size):
        '''When we initialize a buffer we pass in the size we want the buffer
        to be split into 2 parts, the size_in_blocks and the size of the blocks,
        and the size of the type we will be storing in the Buffer.
        The **real_size** of the Buffer will be calculated by
        size_in_blocks*master_block_size.

        When allocating directly typically master_block_size will be 1,
        type_size will be 1, and size_in_blocks will be the number of bytes
        desired for the Buffer. type_size and master_block_size become more
        important for MemoryBlock allocation.

        Args:
            size_in_blocks (unsigned int): The number of blocks to reserve
            from the parent Buffer.

            type_size (unsigned int): The size of a single block.

            master_block_size (unsigned int): The size of the parent block.
        '''
        cdef unsigned int size_in_bytes = size_in_blocks * master_block_size
        self.used_count = 0
        self.data = NULL
        self.free_block_count = 0
        self.size = size_in_bytes // type_size
        self.real_size = size_in_bytes
        self.type_size = type_size
        self.size_in_blocks = size_in_blocks
        self.free_blocks = []
        self.data_in_free = 0

    def __dealloc__(self):
        self.free_blocks = None
        self.size = 0
        self.free_block_count = 0
        self.deallocate_memory()

    cdef bool check_empty(self):
        '''Checks to see if the Buffer is completely unused (No blocks in
            either the **free_blocks** list or actively in use).
        Return:
            bool: True if used_count == 0, else False
        '''
        return self.used_count == 0

    cdef void* allocate_memory(self) except NULL:
        '''Actually allocates the memory, using a regular C malloc. Will raise
        MemoryError if allocation fails (returns NULL).
        Return:
            void*: Pointer to the newly malloced data.
        '''
        self.data = malloc(self.real_size)
        if self.data == NULL:
            raise MemoryError()
        return self.data

    cdef void deallocate_memory(self):
        '''Frees the existing memory located at **data**, typically called
        in the __dealloc__ method.'''
        if self.data != NULL:
            free(self.data)

    cdef unsigned int add_data(self, unsigned int block_count) except -1:
        '''Adds block_count worth of data to the Buffer. The basic process is:
        1. Check if there is enough blocks in the free list. -> If so get one
        chunk which is big enough if available. 
        2. If not 1: Check if we have enough unused blocks. -> Allocate from
        tail.
        3. If not 2: raise MemoryError()

        This process is subject to fragmentation if all blocks aren't equal in
        size. It should be suitable if you are frequently reusing the same size
        of things however.

        Args:
            block_count (unsigned int): The number of blocks to add

        Return:
            unsigned int: The index of the new data.
        '''
        #Optimization notes: We are not as efficient as we could be in the case
        #of pooling the same size objects and we are not super good at pooling
        #different sized objects. Perhaps we need to consider several alternate
        #implementations for different use cases. Or a smarter algorithm.
        cdef unsigned int largest_free_block = 0
        cdef unsigned int index
        cdef unsigned int data_in_free = self.data_in_free
        cdef unsigned int tail_count = self.get_blocks_on_tail()
        if data_in_free >= block_count:
            index = self.get_first_free_block_that_fits(block_count)
            if index != <unsigned int>-1:
                self.data_in_free -= block_count
                self.free_block_count -= 1
                return index
        if block_count <= tail_count:
            index = self.used_count
            self.used_count += block_count
        else:
            raise MemoryError()
        return index

    cdef void remove_data(self, unsigned int block_index,
        unsigned int block_count):
        '''Marks data as free, adding it the **free_blocks**
        (block_index, block_count) will be added to the free list. If
        **data_in_free** become >=  **used_count** (meaning all used blocks are
        also currently free) we will call **clear**, returning the Buffer to its
        empty state.
        Args:
            block_index (unsigned int): The starting index of the data,
            previously returned by **add_data**

            block_count (unsigned int): The number of data blocks that were
            previously allocated, originally passed in to **add_data**
        '''
        self.free_blocks.append((block_index, block_count))
        self.data_in_free += block_count
        self.free_block_count += 1
        if self.data_in_free >= self.used_count:
            self.clear()

    cdef void* get_pointer(self, unsigned int block_index) except NULL:
        '''Returns a pointer to somewhere in the allocated data, performs no
        bounds checking so make sure to ask for the right data.
        Args:
            block_index (unsigned int): Which block to return.

        Return:
            void*: location starting at block_index * **type_size**.
        '''
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]

    cdef unsigned int get_offset(self, unsigned int block_index):
        return block_index*self.type_size

    cdef unsigned int get_largest_free_block(self):
        '''Used internally as part of **add_data** to find the largest available
        block of data
        Return:
            unsigned int: largest individual entry in the **free_blocks**
        '''
        cdef unsigned int free_block_count = self.free_block_count
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, block_count
        cdef list free_blocks = self.free_blocks
        cdef unsigned int largest_block_count = 0
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, block_count = free_block
            if block_count > largest_block_count:
                largest_block_count = block_count
        return largest_block_count

    cdef unsigned int get_first_free_block_that_fits(self,
        unsigned int block_count):
        '''Used internally as part of **add_data**, returns the first entry in
        the free list that is either the size of or larger than block_count.

        Args:
            **block_count** (unsigned int): The number of blocks we are looking
            to allocate.
        '''
        cdef unsigned int free_block_count = self.free_block_count
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, free_block_size
        cdef list free_blocks = self.free_blocks
        cdef unsigned int new_block_count
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, free_block_size = free_block
            if block_count == free_block_size:
                free_blocks.pop(i)
                return index
            elif block_count < free_block_size:
                free_blocks.pop(i)
                new_block_count = free_block_size - block_count
                free_blocks.append((index+block_count, new_block_count))
                self.free_block_count += 1
                return index
        return <unsigned int>-1

    cdef unsigned int get_blocks_on_tail(self):
        '''Return:
            unsigned int: the number of unused blocks'''
        return self.size - self.used_count

    cdef bool can_fit_data(self, unsigned int block_count):
        '''Determines whether an amount of blocks can fit in this Buffer.
        Return:
            bool: True if either enough space on tail or large enough block in
            the free list else False
        '''
        cdef list free_blocks
        cdef unsigned int free_block_count
        cdef unsigned int i
        if self.size - self.used_count >= block_count:
            return True # Space on tail
        if self.data_in_free < block_count:
            return False
        free_blocks = self.free_blocks
        free_block_count = self.free_block_count
        for i in range(free_block_count):
            if free_blocks[i][1] >= block_count:
                return True
        return False

    cdef void clear(self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.free_block_count = 0
        self.data_in_free = 0

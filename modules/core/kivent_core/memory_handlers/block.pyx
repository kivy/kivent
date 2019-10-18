# cython: profile=True
# cython: embedsignature=True
from kivent_core.memory_handlers.membuffer cimport Buffer

cdef class MemoryBlock(Buffer):
    '''The MemoryBlock is like the Buffer, except instead of allocating its
    memory using malloc, it gets it from either a Buffer or another MemoryBlock.
    It is suitable for nesting, for instance during rendering KivEnt will
    allocate one large MemoryBlock to represent the maximum number of frames to
    be rendered something like 20*512*1024 bytes:

    .. code-block:: python

        #allocate the initial space
        buffer = Buffer(100*1024*1024, 1, 1)
        buffer.allocate_memory()
        #allocate our first MemoryBlock, in units of bytes
        mem_block = MemoryBlock(20*512*1024, 512*1024, 1)
        mem_block.allocate_memory_with_buffer(buffer)
        #allocate a block with the mem_block, units in 512 kib blocks
        #will allocate 1 block of mem_block.type_size and split it into
        #mem_block.type_size // other_type_size blocks.
        mem_block2 = MemoryBlock(1, other_type_size, 512*1024)
        mem_block2.allocate_memory_with_buffer(mem_block)


    You must allocate with the function **allocate_memory_with_buffer** instead
    of **allocate_memory**. Deallocation is handled with **remove_from_buffer**.

    **Attributes: (Cython Access Only)**
        **master_buffer** (Buffer): The Buffer from which memory has been
        allocated. Defaults to None, will be set after
        **allocate_memory_with_buffer** has been called.

        **master_index** (unsigned int): The location the data has been
        allocated at in the master_buffer. Defaults to 0, will be set after
        **allocate_memory_with_buffer** has been called.
    '''

    def __cinit__(self, unsigned int size_in_blocks, unsigned int type_size,
        unsigned int master_block_size):
        self.master_index = 0
        self.master_buffer = None

    cdef void* allocate_memory_with_buffer(self,
        Buffer master_buffer) except NULL:
        '''Replaces **allocate_memory**, uses master_buffer.add_data to allocate
        with another Buffer or MemoryBlock.
        Args:
            master_buffer (Buffer): The buffer to allocate from.
        '''
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size_in_blocks)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)
        return self.data

    cdef void remove_from_buffer(self):
        '''Replaces **deallocate_memory** used to free the memory previously
        acquired from **master_buffer**.'''
        self.master_buffer.remove_data(self.master_index, self.size_in_blocks)
        self.master_index = 0
        self.master_buffer = None

    cdef void deallocate_memory(self):
        '''Overridden to do nothing as we no longer need to free'''
        pass

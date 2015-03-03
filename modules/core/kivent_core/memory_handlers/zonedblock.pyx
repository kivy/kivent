from cpython cimport bool
from kivent_core.memory_handlers.membuffer cimport Buffer

cdef class BlockZone:

    def __cinit__(self, str name, unsigned int start, unsigned int total):
        self.used_count = 0
        self.data_in_free
        self.start = start
        self.free_blocks = []
        self.total = total
        self.name = name

    cdef unsigned int add_data(self, unsigned int block_count) except -1:
        cdef unsigned int largest_free_block = 0
        cdef unsigned int index
        cdef unsigned int data_in_free = self.data_in_free
        cdef unsigned int tail_count = self.get_blocks_on_tail()
        if data_in_free >= block_count:
            largest_free_block = self.get_largest_free_block()
        if block_count <= largest_free_block:
            index = self.get_first_free_block_that_fits(block_count)
            self.data_in_free -= block_count
        elif block_count <= tail_count:
            index = self.used_count
            self.used_count += block_count
        else:
            raise MemoryError()
        return index + self.start

    cdef void remove_data(self, unsigned int block_index, 
        unsigned int block_count):
        cdef unsigned int real_index = block_index - self.start
        self.free_blocks.append((real_index, block_count))
        self.data_in_free += block_count
        if self.data_in_free >= self.used_count:
            self.clear()

    cdef unsigned int get_largest_free_block(self):
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, block_count
        cdef list free_blocks = self.free_blocks
        cdef unsigned int free_block_count = len(free_blocks)
        cdef unsigned int largest_block_count = 0
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, block_count = free_block
            if block_count > largest_block_count:
                largest_block_count = block_count
        return largest_block_count

    cdef unsigned int get_first_free_block_that_fits(self, 
        unsigned int block_count):
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, free_block_size
        cdef list free_blocks = self.free_blocks
        cdef unsigned int free_block_count = len(free_blocks)
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
                return index

    cdef unsigned int get_blocks_on_tail(self):
        return self.total - self.used_count

    cdef bool can_fit_data(self, unsigned int block_count):
        cdef unsigned int blocks_on_tail = self.get_blocks_on_tail()
        cdef unsigned int largest_free = self.get_largest_free_block()
        if block_count <= blocks_on_tail or block_count <= largest_free:
            return True
        else:
            return False

    cdef void clear(self):
        '''Clear the whole zone and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.data_in_free = 0


cdef class ZonedBlock:

    def __cinit__(self, unsigned int type_size, list zone_list):
        cdef unsigned int zone_index = 0
        cdef dict zones = {}
        for zone_name, count in zone_list:
            zones[zone_name] = BlockZone(zone_name, zone_index, count)
            zone_index += count

        cdef unsigned int size_in_bytes = zone_index * type_size
        self.data = NULL
        self.master_buffer = None
        self.size = size_in_bytes
        self.master_index = 0
        self.type_size = type_size

    cdef bool check_empty(self):
        cdef unsigned int used = 0
        cdef dict zones = self.zones
        cdef BlockZone zone
        for key in zones:
            zone = zones[key]
            used += zone.used_count
        return used == 0

    cdef void* allocate_memory_with_buffer(self, 
        Buffer master_buffer) except NULL:
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)
        return self.data

    cdef void remove_from_buffer(self):
        self.master_buffer.remove_data(self.master_index, self.size)
        self.master_index = 0

    cdef unsigned int add_data(self, unsigned int block_count, 
        str zone_name) except -1:
        cdef BlockZone zone = self.zones[zone_name]
        return zone.add_data(block_count)

    cdef void remove_data(self, unsigned int block_index, 
        unsigned int block_count):
        cdef BlockZone zone = self.get_zone_from_index(block_index)
        zone.remove_data(block_index, block_count)

    cdef BlockZone get_zone_from_index(self, unsigned int block_index):
        cdef dict zones = self.zones
        cdef BlockZone zone
        cdef str key
        for key in zones:
            zone = zones[key]
            if zone.start <= block_index < zone.start + zone.total:
                return zone
        else:
            raise IndexError()

    cdef void* get_pointer(self, unsigned int block_index) except NULL:
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]

    cdef void clear(self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        cdef dict zones = self.zones
        cdef BlockZone zone
        cdef str key
        for key in zones:
            zone = zones[key]
            zone.clear()
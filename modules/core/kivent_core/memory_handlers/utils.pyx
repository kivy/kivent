# cython: embedsignature=True
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone, ZoneIndex
from kivent_core.memory_handlers.zone cimport MemoryZone

cdef class memrange:
    '''
    Use memrange to iterate a IndexedMemoryZone object and return the active
    game entities' python objects , an active memory object is one that
    currently does not have the first attribute of its struct set to
    <unsigned int>-1. Typically KivEnt store the entity_id for the component
    in this position. Memory objects that have never been allocated are
    skipped.

    Args:

        memory_index (IndexedMemoryZone): The IndexedMemoryZone to iterate.

        start (int): The start of iteration. Defaults 0.

        end (int): The end of iteration. Defaults None. If no end is specified
        we will iterate all memory.

        zone (str): The zone to iterate. Defaults None. If no zone is
        specified we will iterate through all zones.

    You must reference an IndexedMemoryZone, by default we will iterate
    through all the memory. The area of memory iterated can be controlled
    with options *start* and *end*, or you can provide the name of one of
    the reserved zones to iterate that specific memory area.
    '''

    def __init__(self, IndexedMemoryZone memory_index, start=0,
        end=None, zone=None):
        cdef MemoryZone memory_zone = memory_index.memory_zone
        cdef unsigned int zone_count = memory_zone.count
        self.memory_index = memory_index
        if zone is not None:
            start, end = memory_zone.get_pool_range(
                memory_zone.get_pool_index_from_name(zone))
        elif end is None or end > zone_count:
            end = zone_count
        self.start = start
        self.end = end

    def __iter__(self):
        return memrange_iter(self.memory_index, self.start, self.end)

cdef class memrange_iter:

    def __init__(self, IndexedMemoryZone memory_index, int start,
        int end):
        self.memory_index = memory_index
        self.current = start
        self.end = end

    def __iter__(self):
        return self

    def __next__(self):

        cdef IndexedMemoryZone memory_index = self.memory_index
        cdef MemoryZone memory_zone = memory_index.memory_zone
        cdef ZoneIndex zone_index = memory_index.zone_index
        cdef unsigned int current = self.current
        cdef unsigned int pool_index, used
        cdef void* pointer
        if current >= self.end:
            raise StopIteration
        else:
            pool_index = memory_zone.get_pool_index_from_index(current)
            used = memory_zone.get_pool_end_from_pool_index(pool_index)
            if current >= used:
                self.current = memory_zone.get_pool_range(pool_index)[1] + 1
                return next(self)
            else:
                pointer = memory_zone.get_pointer(current)
                self.current += 1
                if <unsigned int>pointer == -1:
                    return next(self)
                return zone_index.get_component_from_index(current)

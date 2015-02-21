from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from gamesystem cimport GameSystem

cdef class StaticMemGameSystem(GameSystem):
    cdef IndexedMemoryZone components
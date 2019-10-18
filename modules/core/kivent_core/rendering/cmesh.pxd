from kivy.graphics.instructions cimport VertexInstruction
from kivent_core.rendering.batching cimport IndexedBatch

cdef class CMesh(VertexInstruction):
    cdef IndexedBatch _batch

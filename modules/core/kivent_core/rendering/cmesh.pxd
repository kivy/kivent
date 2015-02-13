from kivy.graphics.instructions cimport VertexInstruction
from batching cimport IndexedBatch

cdef class CMesh(VertexInstruction):
    cdef IndexedBatch _batch

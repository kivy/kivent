from kivy.graphics.instructions cimport VertexInstruction
from batching cimport IndexedBatch, SimpleBatch

cdef class CMesh(VertexInstruction):
    cdef IndexedBatch _batch


cdef class SimpleMesh(VertexInstruction):
    cdef SimpleBatch _batch

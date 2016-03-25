# cython: profile=True
# cython: embedsignature=True
from kivy.graphics.instructions cimport VertexInstruction
from kivent_core.rendering.batching cimport IndexedBatch
include "opcodes.pxi"
include "common.pxi"


cdef class CMesh(VertexInstruction):

    def __init__(self, **kwargs):
        VertexInstruction.__init__(self, **kwargs)
        cdef IndexedBatch batch = kwargs.get('batch')
        self._batch = batch


    def __dealloc__(self):
        self._batch.clear_frames()

    cdef int apply(self) except -1:
        if self.flags & GI_NEEDS_UPDATE:
            self._batch.current_frame += 1
            self.flag_update_done()
        self._batch.draw_frame()

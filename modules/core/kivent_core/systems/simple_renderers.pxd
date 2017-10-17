from kivent_core.rendering.cmesh cimport CMesh
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.rendering.batching cimport SimpleBatchManager
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.rendering.model cimport VertexModel

cdef class SimpleRenderer(StaticMemGameSystem):
    cdef SimpleBatchManager batch_manager
    cdef object update_trigger
    cdef bint do_texture

    cdef void* _init_component(self, unsigned int component_index,
        unsigned int entity_id, bool render, VertexModel model,
        unsigned int texkey) except NULL
    cdef void* setup_batch_manager(self, Buffer master_buffer) except NULL
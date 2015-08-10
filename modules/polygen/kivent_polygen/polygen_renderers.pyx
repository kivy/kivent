# cython: embedsignature=True
from kivent_core.systems.renderers cimport Renderer, RenderStruct
from kivent_polygen.polygen_formats cimport VertexFormat2F4UB
from kivent_polygen.polygen_formats import vertex_format_2f4ub
from kivy.graphics.c_opengl cimport GLushort
from kivent_core.rendering.batching cimport BatchManager, IndexedBatch
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivent_core.systems.position_systems cimport PositionStruct2D
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.cmesh cimport CMesh
from kivent_core.systems.staticmemgamesystem cimport ComponentPointerAggregator
from kivent_core.rendering.model cimport VertexModel
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import StringProperty, NumericProperty, ListProperty

cdef class ColorPolyRenderer(Renderer):
    '''
    Processing Depends On: PositionSystem2D, ColorPolyRenderer

    The renderer draws with the VertexFormat2F4UB:

    .. code-block:: cython

        ctypedef struct VertexFormat2F4UB:
            GLfloat[2] pos
            GLubyte[4] v_color

    '''
    system_names = ListProperty(['poly_renderer', 'position'])
    system_id = StringProperty('poly_renderer')
    model_format = StringProperty('vertex_format_2f4ub')
    vertex_format_size = NumericProperty(sizeof(VertexFormat2F4UB))
    
    cdef void* setup_batch_manager(self, Buffer master_buffer) except NULL:
        cdef KEVertexFormat batch_vertex_format = KEVertexFormat(
            sizeof(VertexFormat2F4UB), *vertex_format_2f4ub)
        self.batch_manager = BatchManager(
            self.size_of_batches, self.max_batches, self.frame_count, 
            batch_vertex_format, master_buffer, 'triangles', self.canvas,
            [x for x in self.system_names], 
            self.smallest_vertex_count, self.gameworld)
        return <void*>self.batch_manager


    def update(self, force_update, dt):
        cdef IndexedBatch batch
        cdef list batches
        cdef unsigned int batch_key
        cdef unsigned int index_offset, vert_offset
        cdef RenderStruct* render_comp
        cdef PositionStruct2D* pos_comp
        cdef VertexFormat2F4UB* frame_data
        cdef GLushort* frame_indices
        cdef VertexFormat2F4UB* vertex
        cdef VertexModel model
        cdef GLushort* model_indices
        cdef VertexFormat2F4UB* model_vertices
        cdef VertexFormat2F4UB model_vertex
        cdef unsigned int used, i, real_index, component_count, n
        cdef ComponentPointerAggregator entity_components
        cdef BatchManager batch_manager = self.batch_manager
        cdef dict batch_groups = batch_manager.batch_groups
        cdef CMesh mesh_instruction
        cdef MemoryBlock components_block
        cdef void** component_data
        cdef bint static_rendering = self.static_rendering
        
        for batch_key in batch_groups:
            batches = batch_groups[batch_key]
            for batch in batches:
                if not static_rendering or force_update:
                    entity_components = batch.entity_components
                    components_block = entity_components.memory_block
                    used = components_block.used_count
                    component_count = entity_components.count
                    component_data = <void**>components_block.data
                    frame_data = <VertexFormat2F4UB*>batch.get_vbo_frame_to_draw()
                    frame_indices = <GLushort*>batch.get_indices_frame_to_draw()
                    index_offset = 0
                    for i in range(used):
                        real_index = i * component_count
                        if component_data[real_index] == NULL:
                            continue
                        render_comp = <RenderStruct*>component_data[real_index+0]
                        vert_offset = render_comp.vert_index
                        model = <VertexModel>render_comp.model
                        if render_comp.render:
                            pos_comp = <PositionStruct2D*>component_data[
                                real_index+1]
                            model_vertices = <VertexFormat2F4UB*>(
                                model.vertices_block.data)
                            model_indices = <GLushort*>model.indices_block.data
                            for i in range(model._index_count):
                                frame_indices[i+index_offset] = (
                                    model_indices[i] + vert_offset)
                            for n in range(model._vertex_count):
                                vertex = &frame_data[n + vert_offset]
                                model_vertex = model_vertices[n]
                                vertex.pos[0] = pos_comp.x + model_vertex.pos[0]
                                vertex.pos[1] = pos_comp.y + model_vertex.pos[1]
                                vertex.v_color[0] = model_vertex.v_color[0]
                                vertex.v_color[1] = model_vertex.v_color[1]
                                vertex.v_color[2] = model_vertex.v_color[2]
                                vertex.v_color[3] = model_vertex.v_color[3]
                            index_offset += model._index_count
                    batch.set_index_count_for_frame(index_offset)
                mesh_instruction = batch.mesh_instruction
                mesh_instruction.flag_update()


Factory.register('ColorPolyRenderer', cls=ColorPolyRenderer)
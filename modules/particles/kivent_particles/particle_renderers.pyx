# cython: embedsignature=True
from kivent_core.systems.renderers cimport Renderer, RenderStruct
from kivent_particles.particle_formats cimport VertexFormat9F4UB
from kivent_particles.particle_formats import vertex_format_9f4ub
from kivy.graphics.cgl cimport GLushort
from kivent_core.rendering.batching cimport BatchManager, IndexedBatch
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivent_core.systems.position_systems cimport PositionStruct2D
from kivent_core.systems.scale_systems cimport ScaleStruct2D
from kivent_core.systems.rotate_systems cimport RotateStruct2D
from kivent_core.systems.color_systems cimport ColorStruct
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.cmesh cimport CMesh
from kivent_core.systems.staticmemgamesystem cimport ComponentPointerAggregator
from kivent_core.rendering.model cimport VertexModel
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.factory import Factory
from kivy.properties import StringProperty, NumericProperty, ListProperty

cdef class ParticleRenderer(Renderer):
    '''
    Processing Depends On: ParticlesRenderer, PositionSystem2D, ScaleSystem2D,
    RotateSystem2D, ColorSystem

    The renderer draws with the VertexFormat9F4UB:

    .. code-block:: cython

        ctypedef struct VertexFormat9F4UB:
            GLfloat[2] pos
            GLfloat[2] uvs
            GLfloat[2] center
            GLfloat[2] scale
            GLubyte[4] v_color
            GLfloat rotate

    '''
    system_names = ListProperty(['particle_renderer', 'position', 'scale', 
        'rotate', 'color'])
    system_id = StringProperty('particle_renderer')
    model_format = StringProperty('vertex_format_9f4ub')
    vertex_format_size = NumericProperty(sizeof(VertexFormat9F4UB))
    
    cdef void* setup_batch_manager(self, Buffer master_buffer) except NULL:
        cdef KEVertexFormat batch_vertex_format = KEVertexFormat(
            sizeof(VertexFormat9F4UB), *vertex_format_9f4ub)
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
        cdef RotateStruct2D* rot_comp
        cdef ColorStruct* color_comp
        cdef ScaleStruct2D* scale_comp
        cdef VertexFormat9F4UB* frame_data
        cdef GLushort* frame_indices
        cdef VertexFormat9F4UB* vertex
        cdef VertexModel model
        cdef GLushort* model_indices
        cdef VertexFormat9F4UB* model_vertices
        cdef VertexFormat9F4UB model_vertex
        cdef unsigned int used, i, real_index, component_count, n, c
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
                    frame_data = <VertexFormat9F4UB*>(
                        batch.get_vbo_frame_to_draw())
                    frame_indices = <GLushort*>batch.get_indices_frame_to_draw()
                    index_offset = 0
                    for c in range(used):
                        real_index = c * component_count
                        if component_data[real_index] == NULL:
                            continue
                        render_comp = <RenderStruct*>component_data[
                            real_index+0]
                        vert_offset = render_comp.vert_index
                        model = <VertexModel>render_comp.model
                        if render_comp.render:
                            pos_comp = <PositionStruct2D*>component_data[
                                real_index+1]
                            scale_comp = <ScaleStruct2D*>component_data[
                                real_index+2]
                            rot_comp = <RotateStruct2D*>component_data[
                                real_index+3]
                            color_comp = <ColorStruct*>component_data[
                                real_index+4]
                            model_vertices = <VertexFormat9F4UB*>(
                                model.vertices_block.data)
                            model_indices = <GLushort*>model.indices_block.data
                            for i in range(model._index_count):
                                frame_indices[i+index_offset] = (
                                    model_indices[i] + vert_offset)
                            for n in range(model._vertex_count):
                                vertex = &frame_data[n + vert_offset]
                                model_vertex = model_vertices[n]
                                for i in range(2):
                                    vertex.pos[i] = model_vertex.pos[i]
                                    vertex.uvs[i] = model_vertex.uvs[i]
                                vertex.center[0] = pos_comp.x
                                vertex.center[1] = pos_comp.y
                                vertex.scale[0] = scale_comp.sx
                                vertex.scale[1] = scale_comp.sy
                                vertex.rotate = rot_comp.r
                                for i in range(4):
                                    vertex.v_color[i] = color_comp.color[i]
                            index_offset += model._index_count
                    batch.set_index_count_for_frame(index_offset)
                mesh_instruction = batch.mesh_instruction
                mesh_instruction.flag_update()


Factory.register('ParticleRenderer', cls=ParticleRenderer)
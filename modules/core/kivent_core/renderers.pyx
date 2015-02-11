# cython: profile=True
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython cimport bool
from kivy.properties import (BooleanProperty, StringProperty, NumericProperty)
from kivy.graphics import RenderContext, Callback
from cmesh cimport CMesh, VertexFormat4F, BatchManager, Batch, KEVertexFormat
from cmesh import vertex_format
from resource_managers import model_manager, texture_manager
from resource_managers cimport ModelManager, TextureManager
from kivy.graphics.opengl import (glEnable, glBlendFunc, GL_SRC_ALPHA, GL_ONE, 
    GL_ZERO, GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA, 
    GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR,
    glDisable)
cimport cython
from kivy.graphics.c_opengl cimport GLfloat, GLushort
from gamesystems cimport (StaticMemGameSystem, ColorStruct, PositionStruct2D,
    PositionSystem2D, RotateStruct2D, RotateSystem2D, ScaleStruct2D,
    ScaleSystem2D, ColorSystem)
from entity cimport Entity
from vertmesh cimport VertMesh
from kivy.factory import Factory
from libc.math cimport fabs
from membuffer cimport (MemComponent, MemoryZone, IndexedMemoryZone, Buffer,
    memrange)
from system_manager cimport system_manager


cdef class RenderComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef RenderStruct* data = <RenderStruct*>self.pointer
            return data.entity_id


    property width:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            return fabs(vert_mesh[0][0]*2.)

        def __set__(self, float value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            cdef float w
            if value != 0:
                w = .5*value
                set_vertex_attribute = vert_mesh.set_vertex_attribute
                set_vertex_attribute(0,0,-w)
                set_vertex_attribute(1,0,-w)
                set_vertex_attribute(2,0,w)
                set_vertex_attribute(3,0,w)
        

    property height:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            return fabs(vert_mesh[0][1]*2.)

        def __set__(self, float value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            cdef float h
            if value != 0:
                h = .5*value
                set_vertex_attribute = vert_mesh.set_vertex_attribute
                set_vertex_attribute(0,1,-h)
                set_vertex_attribute(1,1,h)
                set_vertex_attribute(2,1,h)
                set_vertex_attribute(3,1,-h)


    property batch_id:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            return component_data.batch_id

        def __set__(self, int value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            component_data.batch_id = value


    property attribute_count:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            return component_data.attrib_count

        def __set__(self, int value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            component_data.attrib_count = value
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            vert_mesh.attribute_count = value


    property texture_key:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            return texture_manager.get_texkey_from_index_key(
                component_data.texkey)

        def __set__(self, str value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef unsigned int texkey = texture_manager.get_texkey_from_name(
                value)
            cdef float u0, v0, u1, v1
            cdef list uv_list = texture_manager.get_uvs(value)
            u0 = uv_list[0]
            v0 = uv_list[1]
            u1 = uv_list[2]
            v1 = uv_list[3]
            component_data.texkey = texkey
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            set_vertex_attribute = vert_mesh.set_vertex_attribute
            set_vertex_attribute(0, 2, u0)
            set_vertex_attribute(0, 3, v0)
            set_vertex_attribute(1, 2, u0)
            set_vertex_attribute(1, 3, v1)
            set_vertex_attribute(2, 2, u1)
            set_vertex_attribute(2, 3, v1)
            set_vertex_attribute(3, 2, u1)
            set_vertex_attribute(3, 3, v0)


    property render:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            return component_data.render

        def __set__(self, bool value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            if value:
                component_data.render = 1
            else:
                component_data.render = 0


    property vertex_count:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            return vert_mesh._vert_count

        def __set__(self, int value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            vert_mesh.vertex_count = value


    property index_count:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            return vert_mesh._index_count

        def __set__(self, int value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            vert_mesh.index_count = value


    property vert_mesh:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            return vert_mesh

        def __set__(self, str vert_mesh_key):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int new_index = model_manager.get_mesh_index(vert_mesh_key)
            component_data.vert_index_key = new_index


cdef class Renderer(StaticMemGameSystem):
    '''The basic KivEnt renderer it draws every entity every frame. Entities 
    will be batched into groups of up to **maximum_vertices**, if they can
    share the source of texture. 

    **Attributes:**
        **shader_source** (StringProperty): Path to the .glsl to be used, do 
        include '.glsl' in the name. You must ensure that your shader matches 
        your vertex format or you will have problems

        **maximum_vertices** (NumericProperty): The maximum number of vertices
         that will be placed in a batch. 

        **attribute_count** (NumericProperty): The number of attributes each 
        vertex will contain. Computed automatically inside 
        calculate_vertex_format.

        **vertex_format** (dict): describes format of data sent to shaders,
        generated automatically based on do_rotate, do_scale, do_color

        **blend_factor_source** (NumericProperty): Sets the Blend Source. for
        a visual exploration of this concept visit : 
        http://www.andersriggelsen.dk/glblendfunc.php
        Options Include:
        GL_SRC_ALPHA, GL_ONE, GL_ZERO, GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, 
        GL_ONE_MINUS_SRC_ALPHA, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, 
        GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR

        **blend_factor_dest** (NumericProperty): Sets the Blend Dest. 
        See blend_factor_sourc for more details.

        **reset_blend_factor_source** (NumericProperty): The blend source
        will be reset to this after drawing this canvas. 
        See blend_factor_source for more details.

        **reset_blend_factor_dest** (NumericProperty): The blend dest
        will be reset to this after drawing this canvas. 
        See blend_factor_source for more details.

    '''
    system_id = StringProperty('renderer')
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)
    max_batches = NumericProperty(20)
    size_of_batches = NumericProperty(256)
    frame_count = NumericProperty(2)
    shader_source = StringProperty('positionshader.glsl')
    blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    reset_blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    reset_blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    cdef unsigned int attribute_count
    cdef BatchManager batch_manager
    cdef KEVertexFormat vertex_format


    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True)
        if 'shader_source' in kwargs:
            self.canvas.shader.source = kwargs.get('shader_source')
        super(Renderer, self).__init__(**kwargs)
        self.attribute_count = 4
        with self.canvas.before:
            Callback(self._set_blend_func)
        with self.canvas.after:
            Callback(self._reset_blend_func)         

    def _set_blend_func(self, instruction):
        glBlendFunc(self.blend_factor_source, self.blend_factor_dest)

    def _reset_blend_func(self, instruction):
        glBlendFunc(self.reset_blend_factor_source, 
            self.reset_blend_factor_dest)

    def _update(self, dt):
        '''
        We only want to update renderer once per frame, so we will override
        the basic GameSystem logic here which accounts appropriately for
        dt.
        '''
        self.update(dt)

    def on_shader_source(self, instance, value):
        self.canvas.shader.source = value

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RenderStruct* pointer = <RenderStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        pointer.attrib_count = 0
        pointer.vert_index_key = -1
        pointer.texkey = -1
        pointer.render = 0
        pointer.batch_id = -1
        pointer.vert_index = -1
        pointer.ind_index = -1

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(RenderStruct), 
            reserve_spec, RenderComponent)
        cdef KEVertexFormat batch_vertex_format = KEVertexFormat(
            sizeof(VertexFormat4F), *vertex_format)
        self.batch_manager = BatchManager(
            self.size_of_batches, self.max_batches, self.frame_count, 
            batch_vertex_format, master_buffer, 'triangles', self.canvas)

    cdef void _init_component(self, unsigned int component_index, 
        unsigned int entity_id, bool render, unsigned int attrib_count, 
        unsigned int vert_index_key, unsigned int texkey):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RenderStruct* pointer = <RenderStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = entity_id
        pointer.attrib_count = attrib_count
        pointer.vert_index_key = vert_index_key
        pointer.texkey = texkey
        if render:
            pointer.render = 1
        else:
            pointer.render = 0
        self._batch_entity(entity_id, pointer)
        
    def init_component(self, unsigned int index, unsigned int entity_id, 
        args):
        cdef float w, h
        cdef int vert_index_key, texkey
        cdef bool copy, render
        cdef int attrib_count = self.attribute_count
        if 'texture' in args:
            texture_key = args['texture']
            texkey = texture_manager.get_texkey_from_name(texture_key)

        else:
            texture_key = str(None)
            texkey = -1
        if 'size' in args:
            w, h = args['size']
        if 'copy' in args:
            copy = args['copy']
        else:
            copy = False
        if 'render' in args:
            render = args['render']
        else:
            render = True
        if 'vert_mesh_key' in args:
            vert_mesh_key = args['vert_mesh_key']
            vert_index_key = model_manager.get_mesh_index(vert_mesh_key)
        else:
            vert_index_key = -1

        if vert_index_key == -1:
            mesh_key = str(attrib_count) + texture_key
            exists = model_manager.does_key_exist(mesh_key)
            if not exists:
                model_manager.load_textured_rectangle(attrib_count, 
                    w, h, texture_key, mesh_key)
            vert_index_key = model_manager.get_mesh_index(mesh_key)

        self._init_component(index, entity_id, render, attrib_count,
            vert_index_key, texkey)

    def update(self, dt):
        '''Update function where all drawing of entities is performed. 
        Override this method in combination with calculate_vertex_format
        if you would like to create a renderer with customized behavior.'''
        cdef Batch batch
        cdef list batches, entity_ids
        cdef unsigned int* entity
        cdef unsigned int entity_id, rend_comp_index, pos_comp_index
        cdef unsigned int batch_key
        cdef unsigned int index_offset, vert_offset
        cdef RenderStruct* render_comp
        cdef PositionStruct2D* pos_comp
        cdef VertexFormat4F* frame_data
        cdef GLushort* frame_indices
        cdef VertMesh vert_mesh
        cdef float* mesh_data
        cdef VertexFormat4F* vertex
        cdef unsigned short* mesh_indices

        
        cdef object gameworld = self.gameworld
        cdef int attribute_count = self.attribute_count
        cdef IndexedMemoryZone entities = gameworld.entities
        cdef BatchManager batch_manager = self.batch_manager
        cdef dict batch_groups = batch_manager.batch_groups
        cdef dict systems = system_manager.systems
        cdef list meshes = model_manager.meshes
        cdef unsigned int position_index = system_manager.get_system_index(
            'position')
        cdef unsigned int system_index = system_manager.get_system_index(
            self.system_id)
        cdef PositionSystem2D pos_system = systems[position_index]
        cdef MemoryZone render_memory = self.components.memory_zone
        cdef MemoryZone entity_memory = entities.memory_zone
        cdef MemoryZone pos_memory = pos_system.components.memory_zone
        cdef CMesh mesh_instruction
    
        for batch_key in batch_groups:
            batches = batch_groups[batch_key]
            for batch in batches:
                entity_ids = batch.entity_ids
                frame_data = <VertexFormat4F*>batch.get_vbo_frame_to_draw()
                frame_indices = <GLushort*>batch.get_indices_frame_to_draw()
                index_offset = 0
                for entity_id in entity_ids:
                    entity = <unsigned int*>entity_memory.get_pointer(
                        entity_id)
                    rend_comp_index = entity[system_index+1]
                    render_comp = <RenderStruct*>render_memory.get_pointer(
                        rend_comp_index)
                    vert_offset = render_comp.vert_index
                    vert_mesh = meshes[render_comp.vert_index_key]
                    vertex_count = vert_mesh._vert_count
                    index_count = vert_mesh._index_count
                    if render_comp.render:
                        pos_comp_index = entity[position_index+1]
                        pos_comp = <PositionStruct2D*>(
                            pos_memory.get_pointer(pos_comp_index))
                        mesh_data = vert_mesh._data
                        mesh_indices = vert_mesh._indices
                        for i in range(index_count):
                            frame_indices[i+index_offset] = (
                                mesh_indices[i] + vert_offset)
                        for n in range(vertex_count):
                            vertex = &frame_data[n + vert_offset]
                            vertex.pos[0] = pos_comp.x + mesh_data[
                                n*attribute_count]
                            vertex.pos[1] = pos_comp.y + mesh_data[
                                n*attribute_count+1]
                            vertex.uvs[0] = mesh_data[n*attribute_count+2]
                            vertex.uvs[1] = mesh_data[n*attribute_count+3]
                        index_offset += index_count
                batch.set_index_count_for_frame(index_offset)
                mesh_instruction = batch.mesh_instruction
                mesh_instruction.flag_update()

    def remove_entity(self, unsigned int entity_id):
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        self._unbatch_entity(entity_id, <RenderStruct*>components.get_pointer(
            component_index))
        super(Renderer, self).remove_entity(entity_id)

    def unbatch_entity(self, unsigned int entity_id):
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        self._unbatch_entity(entity_id, <RenderStruct*>components.get_pointer(
            component_index))

    cdef void _unbatch_entity(self, unsigned int entity_id, 
        RenderStruct* component_data):
        cdef list meshes = model_manager.meshes
        cdef VertMesh vert_mesh = meshes[component_data.vert_index_key]
        cdef unsigned int vert_count = vert_mesh._vert_count
        cdef unsigned int index_count = vert_mesh._index_count
        self.batch_manager.unbatch_entity(entity_id, component_data.batch_id,
            vert_count, index_count, component_data.vert_index,
            component_data.ind_index)
        component_data.batch_id = -1
        component_data.vert_index = -1
        component_data.ind_index = -1

    def batch_entity(self, unsigned int entity_id):
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        self._batch_entity(entity_id, <RenderStruct*>components.get_pointer(
            component_index))

    cdef void _batch_entity(self, unsigned int entity_id, 
        RenderStruct* component_data):
        cdef list meshes = model_manager.meshes
        cdef tuple batch_indices
        cdef VertMesh vert_mesh = meshes[component_data.vert_index_key]
        cdef unsigned int vert_count = vert_mesh._vert_count
        cdef unsigned int index_count = vert_mesh._index_count
        cdef int texkey = texture_manager.get_groupkey_from_texkey(
            component_data.texkey)
        batch_indices = self.batch_manager.batch_entity(entity_id,
            texkey, vert_count, index_count)
        component_data.batch_id = batch_indices[0]
        component_data.vert_index = batch_indices[1]
        component_data.ind_index = batch_indices[2]
        

Factory.register('Renderer', cls=Renderer)
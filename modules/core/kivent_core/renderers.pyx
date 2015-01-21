# cython: profile=True
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython cimport bool
from kivy.properties import (BooleanProperty, StringProperty, NumericProperty)
from kivy.graphics import RenderContext, Callback
from cmesh cimport CMesh
from resource_managers import model_manager, texture_manager
from resource_managers cimport ModelManager, TextureManager
from kivy.graphics.opengl import (glEnable, glBlendFunc, GL_SRC_ALPHA, GL_ONE, 
    GL_ZERO, GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA, 
    GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR,
    glDisable)
cimport cython
from gamesystems cimport (StaticMemGameSystem, ColorStruct, PositionStruct2D,
    PositionSystem2D, RotateStruct2D, RotateSystem2D, ScaleStruct2D,
    ScaleSystem2D, ColorSystem)
from entity cimport Entity
from vertmesh cimport VertMesh
from kivy.factory import Factory
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
            return component_data.width

        def __set__(self, float value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            height = component_data.height
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            cdef float w
            if value != 0 and height != 0:
                w = .5*value
                component_data.width = value
                set_vertex_attribute = vert_mesh.set_vertex_attribute
                set_vertex_attribute(0,0,-w)
                set_vertex_attribute(1,0,-w)
                set_vertex_attribute(2,0,w)
                set_vertex_attribute(3,0,w)
        

    property height:
        def __get__(self):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            return component_data.height

        def __set__(self, float value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            width = component_data.width
            cdef int vert_mesh_index = component_data.vert_index_key
            cdef list meshes = model_manager.meshes
            cdef VertMesh vert_mesh = meshes[vert_mesh_index]
            cdef float h
            if width != 0 and value != 0:
                h = .5*value
                component_data.height = value
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
                component_data.tex_index_key)

        def __set__(self, str value):
            cdef RenderStruct* component_data = <RenderStruct*>self.pointer
            cdef int tex_index_key = texture_manager.get_index_key_from_texkey(
                value)
            cdef float u0, v0, u1, v1
            cdef list uv_list = texture_manager.get_uvs(value)
            u0 = uv_list[0]
            v0 = uv_list[1]
            u1 = uv_list[2]
            v1 = uv_list[3]
            component_data.tex_index_key = tex_index_key
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
        **do_rotate** (BooleanProperty): Determines whether or not vertex 
        format will have a float for rotate

        **do_color** (BooleanProperty): Determines whether or not vertex 
        format will have 4 floats for rgba color

        **do_scale** (BooleanProperty): Determines whether or not vertex 
        format will have a float for scale

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
    do_rotate = BooleanProperty(False)
    do_color = BooleanProperty(False)
    do_scale = BooleanProperty(False)
    maximum_vertices = NumericProperty(20000)
    shader_source = StringProperty('positionshader.glsl')
    blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    reset_blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    reset_blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    cdef unsigned int _do_r_index
    cdef unsigned int _do_g_index
    cdef unsigned int _do_b_index
    cdef unsigned int _do_a_index
    cdef unsigned int _do_rot_index
    cdef unsigned int _do_scale_index
    cdef unsigned int _do_center_x
    cdef unsigned int _do_center_y
    cdef unsigned int _index_count
    cdef list batches
    cdef list vertex_format
    cdef unsigned int attribute_count


    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True)
        if 'shader_source' in kwargs:
            self.canvas.shader.source = kwargs.get('shader_source')
        print('in startup')
        super(Renderer, self).__init__(**kwargs)
        print('finish super')
        self.batches = []
        print('calculating vertex before')
        self.vertex_format = self.calculate_vertex_format()
        print('calculating vertex after')
        self._do_r_index = -1
        self._do_g_index = -1
        self._do_b_index = -1
        self._do_a_index = -1
        self._do_rot_index = -1
        self._do_scale_index = -1
        self._do_center_x = 4
        self._do_center_y = 5
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
        pointer.width = 0.
        pointer.height = 0.
        pointer.vert_index_key = -1
        pointer.tex_index_key = -1
        pointer.render = 0
        pointer.batch_id = -1

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        self.components = IndexedMemoryZone(master_buffer, 
            self.size_of_component_block, sizeof(RenderStruct), 
            reserve_spec, RenderComponent)

    cdef void _init_component(self, unsigned int component_index, 
        unsigned int entity_id, bool render, int attrib_count, 
        int vert_index_key, int tex_index_key, float width, float height):
        cdef MemoryZone memory_zone = self.components.memory_zone
        cdef RenderStruct* pointer = <RenderStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = entity_id
        pointer.attrib_count = attrib_count
        pointer.width = width
        pointer.height = height
        pointer.vert_index_key = vert_index_key
        pointer.tex_index_key = tex_index_key
        if render:
            pointer.render = 1
        else:
            pointer.render = 0

    def init_component(self, unsigned int index, unsigned int entity_id, *args,
        **kwargs):
        cdef float w, h
        cdef int vert_index_key, tex_index_key
        cdef bool copy, render
        cdef int attrib_count = self.attribute_count
        if 'texture' in kwargs:
            texture_key = kwargs['texture']

            tex_index_key = texture_manager.get_index_key_from_texkey(
                texture_key)
        else:
            texture_key = str(None)
            tex_index_key = -1
        if 'size' in kwargs:
            w, h = kwargs['size']
        else:
            w, h = 0., 0.
        if 'copy' in kwargs:
            copy = kwargs['copy']
        else:
            copy = False
        if 'render' in kwargs:
            render = kwargs['render']
        else:
            render = True
        if 'vert_mesh_key' in kwargs:
            vert_mesh_key = kwargs['vert_mesh_key']
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

        #either get model or create model with w/h/tex
        #if no tex set to -1
        self._init_component(index, entity_id, render, attrib_count,
            vert_index_key, tex_index_key, w, h)

    def on_do_rotate(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def on_do_scale(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def on_do_color(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def calculate_vertex_format(self):
        '''Function used internally to calculate the vertex_format.
        Override this method if you would like to create a custom
        vertex format.'''
        vertex_format = [
            ('vPosition', 2, 'float'),
            ('vTexCoords0', 2, 'float'),
            ('vCenter', 2, 'float'),
            ]
        attribute_count = 6
        if self.do_rotate:
            vertex_format.append(('vRotation', 1, 'float'))
            self._do_rot_index = attribute_count
            attribute_count += 1
        if self.do_color:
            vertex_format.append(('vColor', 4, 'float'))
            self._do_r_index = attribute_count
            self._do_g_index = attribute_count + 1
            self._do_b_index = attribute_count + 2
            self._do_a_index = attribute_count + 3
            attribute_count += 4
        if self.do_scale:
            self._do_scale_index = attribute_count
            vertex_format.append(('vScale', 1, 'float'))
            attribute_count += 1
        self.attribute_count = attribute_count
        return vertex_format

    def update(self, dt):
        '''Update function where all drawing of entities is performed. 
        Override this method in combination with calculate_vertex_format
        if you would like to create a renderer with customized behavior.'''
        cdef list batches = self.batches
        cdef int num_batches = len(batches)
        cdef unsigned int system_index = system_manager.get_system_index(
            self.system_id)
        cdef RenderBatch batch
        cdef object gameworld = self.gameworld
        cdef dict systems = system_manager.systems
        cdef unsigned int* entity_pointer
        cdef list meshes = model_manager.meshes
        cdef unsigned int position_index = system_manager.get_system_index(
            'position')
        cdef int vert_offset
        cdef IndexedMemoryZone entities = gameworld.entities
        cdef int attribute_count = self.attribute_count
        cdef int vertex_count
        cdef int index_count
        cdef int index_offset
        cdef int mesh_index_offset
        cdef int n
        cdef int attr_ind
        cdef int i
        cdef bool do_rotate = self.do_rotate
        cdef bool do_scale = self.do_scale
        cdef bool do_color = self.do_color
        cdef unsigned int center_x_index = self._do_center_x
        cdef unsigned int center_y_index = self._do_center_y
        cdef unsigned int rot_index = self._do_rot_index
        cdef unsigned int r_index = self._do_r_index
        cdef unsigned int g_index = self._do_g_index
        cdef unsigned int b_index = self._do_b_index
        cdef unsigned int a_index = self._do_a_index
        cdef unsigned int scale_index = self._do_scale_index
        cdef unsigned int rotate_index, color_index, s_index
        cdef RotateSystem2D rot_system
        cdef ScaleSystem2D scale_system
        cdef ColorSystem color_system
        cdef MemoryZone rot_memory, scale_memory, color_memory
        cdef RotateStruct2D* rot_comp
        cdef ScaleStruct2D* scale_comp
        cdef ColorStruct* color_comp
        if do_rotate:
            rotate_index = system_manager.get_system_index('rotate')
            rot_system = systems[rotate_index]
            rot_memory = rot_system.components.memory_zone
        if do_scale:
            s_index = system_manager.get_system_index('scale')
            scale_system = systems[s_index]
            scale_memory = scale_system.components.memory_zone
        if do_color:
            color_index = system_manager.get_system_index('color')
            color_system = systems[color_index]
            color_memory = color_system.components.memory_zone
        cdef VertMesh vert_mesh
        cdef float* batch_data
        cdef float* mesh_data
        cdef unsigned short* batch_indices
        cdef unsigned short* mesh_indices
        cdef int data_index
        cdef int mesh_index
        cdef int num_entities
        cdef int batch_ind
        cdef int ent_ind
        cdef int entity_offset
        cdef RenderStruct* render_comp
        cdef unsigned int* entity
        cdef PositionStruct2D* pos_comp
        cdef PositionSystem2D position_system = systems[position_index]
        cdef MemoryZone render_memory = self.components.memory_zone
        cdef MemoryZone entity_memory = entities.memory_zone
        cdef MemoryZone position_memory = (
            position_system.components.memory_zone)
        cdef unsigned int rend_comp_index, scale_comp_index, pos_comp_index
        cdef unsigned int rot_comp_index, color_comp_index
        for batch_ind in range(num_batches):
            batch = batches[batch_ind]
            batch.update_batch()
            batch_data = batch._batch_data
            batch_indices = batch._batch_indices
            entity_ids = batch._entity_ids
            num_entities = len(entity_ids)
            index_offset = 0
            vert_offset = 0
            mesh_index_offset = 0
            for ent_ind in range(num_entities):
                entity = <unsigned int*>entity_memory.get_pointer(ent_ind)
                rend_comp_index = entity[system_index+1]
                render_comp = <RenderStruct*>render_memory.get_pointer(
                    rend_comp_index)
                vert_mesh = meshes[render_comp.vert_index_key]
                vertex_count = vert_mesh._vert_count
                index_count = vert_mesh._index_count
                if render_comp.render:
                    pos_comp_index = entity[position_index+1]
                    pos_comp = <PositionStruct2D*>position_memory.get_pointer(
                        pos_comp_index)
                    if do_rotate:
                        rot_comp_index = entity[rotate_index+1]
                        rot_comp = <RotateStruct2D*>rot_memory.get_pointer(
                            rot_comp_index)
                    if do_scale:
                        scale_comp_index = entity[s_index+1]
                        scale_comp = <ScaleStruct2D*>scale_memory.get_pointer(
                            scale_comp_index)
                    if do_color:
                        color_comp_index = entity[color_index+1]
                        color_comp = <ColorStruct*>color_memory.get_pointer(
                            color_comp_index)
                    mesh_data = vert_mesh._data
                    mesh_indices = vert_mesh._indices
                    for i in range(index_count):
                        batch_indices[i+index_offset] = (
                            mesh_indices[i] + mesh_index_offset)
                    for n in range(vertex_count):
                        for attr_ind in range(attribute_count):
                            mesh_index = n*attribute_count + attr_ind
                            data_index = mesh_index + vert_offset
                            if attr_ind == center_x_index:
                                batch_data[data_index] = pos_comp.x
                            elif attr_ind == center_y_index:
                                batch_data[data_index] = pos_comp.y
                            elif attr_ind == rot_index:
                                batch_data[data_index] = rot_comp.r
                            elif attr_ind == r_index:
                                batch_data[data_index] = color_comp.r
                            elif attr_ind == b_index:
                                batch_data[data_index] = color_comp.b
                            elif attr_ind == g_index:
                                batch_data[data_index] = color_comp.g
                            elif attr_ind == a_index:
                                batch_data[data_index] = color_comp.a
                            elif attr_ind == scale_index:
                                batch_data[data_index] = scale_comp.sx
                            else:
                                batch_data[data_index] = mesh_data[mesh_index]
                else:
                    for i in range(index_count):
                        batch_indices[i+index_offset] = -1
                vert_offset += vertex_count * attribute_count
                mesh_index_offset += vertex_count
                index_offset += index_count
            batch._cmesh.flag_update()

    def remove_entity(self, int entity_id):
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef RenderComponent render_comp = components[component_index]
        cdef int batch_id = render_comp.batch_id
        cdef RenderBatch batch = self.batches[batch_id]
        batch.remove_entity(entity_id)
        super(Renderer, self).remove_entity(entity_id)

    def on_attribute_count(self, instance, value):
        cdef RenderBatch batch 
        cdef list batches = self.batches
        for batch in batches:
            batch._attrib_count = value
        self.rebatch_all()

    def update_entity_batch_counts(self, int entity_id):
        '''If you have changed the number of vertices or indices in your
        entities VertMesh, call this function'''
        cdef list batches = self.batches
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef RenderComponent render_comp = components[component_index]
        cdef int batch_id = render_comp.batch_id
        cdef RenderBatch batch = batches[batch_id]
        batch.update_entity_counts(entity_id, render_comp.vertex_count, 
            render_comp.index_count)

    def rebatch_all(self):
        rebatch_entity = self.rebatch_entity
        cdef RenderComponent component
        cdef IndexedMemoryZone components = self.components
        for component in memrange(components):
            rebatch_entity(component.entity_id)

    def remove_entity_from_batch(self, int entity_id):
        cdef IndexedMemoryZone components = self.components
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef RenderComponent render_comp = components[component_index]
        cdef list batches = self.batches
        cdef int batch_id = render_comp.batch_id
        cdef RenderBatch batch = batches[batch_id]
        batch.remove_entity(entity_id)

    def rebatch_entity(self, int entity_id):
        cdef list batches = self.batches
        cdef IndexedMemoryZone entities = self.gameworld.entities
        cdef Entity entity = entities[entity_id]
        cdef unsigned int component_index = entity.get_component_index(
            self.system_id)
        cdef IndexedMemoryZone components = self.components
        cdef RenderComponent render_comp = components[component_index]
        cdef int batch_id = render_comp.batch_id
        cdef RenderBatch batch = batches[batch_id]
        render_comp.attribute_count = self.attribute_count
        batch.remove_entity(entity_id)
        self.batch_entity(entity_id, render_comp.vertex_count, 
            render_comp.index_count, render_comp.texture_key, render_comp)

    def batch_entity(self, int entity_id, int vertex_count, int index_count, 
        str texture_key, RenderComponent render_comp):
        try_existing, batch_id = self.add_to_existing_batch(
            entity_id, vertex_count, index_count, texture_key)
        if not try_existing:
            batch_id = self.create_new_batch(entity_id, self.maximum_vertices, 
                self.attribute_count, vertex_count, index_count, texture_key)
        render_comp.batch_id = batch_id

    def create_component(self, entity_id, zone, *args, **kwargs):
        component_index = super(Renderer, self).create_component(
            entity_id, zone, args)
        cdef IndexedMemoryZone components = self.components
        cdef RenderComponent render_comp = components[component_index]
        cdef int vertex_count = render_comp.vertex_count
        cdef int index_count = render_comp.index_count
        cdef str texture_key = render_comp.texture_key
        self.batch_entity(entity_id, vertex_count, index_count, texture_key,
            render_comp)

    def create_new_batch(self, int entity_id, int max_verts, 
        int attribute_count, int vertex_count, int index_count, 
        str texture_key):
        '''Used internally when no batch exists or has room for the 
        entity being rendered'''
        if texture_key is not None:
            texture_name = texture_manager.get_texname_from_texkey(
                texture_key)
            texture = texture_manager.get_texture(texture_name)
        else:
            texture_name = None
            texture = None
        cdef CMesh cmesh
        with self.canvas:
            cmesh = CMesh(fmt=self.vertex_format, mode='triangles',
                    texture=texture)
        batch_id = len(self.batches)
        cdef RenderBatch new_batch = RenderBatch(max_verts, attribute_count, 
            cmesh, texture_name, batch_id)
        self.batches.append(new_batch)
        added = new_batch.add_entity(entity_id, vertex_count, index_count, 
            texture_key)
        if not added:
            raise Exception(
                'Entity: ' + str(entity_id) + ' not added to batch')
        return batch_id

    def add_to_existing_batch(self, int entity_id, int vertex_count, 
        int index_count, str texture_key):
        '''Used internally when there is an available batch to fit entity in'''
        cdef list batches = self.batches
        cdef RenderBatch batch
        for batch in batches:
            if batch.add_entity(entity_id, vertex_count, 
                index_count, texture_key):
                return True, batch._batch_id
        return False, None


cdef class RenderBatch:

    def __cinit__(self, int maximum_verts, int attribute_count, CMesh cmesh,
            str texture_name, int batch_id):
        self._entity_ids = []
        self._entity_counts = {}
        self._maximum_verts = maximum_verts
        self._batch_data = NULL
        self._batch_indices = NULL
        self._r_index_count = 0
        self._r_vert_count = 0
        self._r_attrib_count = 0
        self._vert_count = 0
        self._index_count = 0
        self._attrib_count = attribute_count
        self._cmesh = cmesh
        self._texture = texture_name
        self._batch_id = batch_id

    def update_batch(self):
        cdef int vert_count = self._vert_count
        cdef int r_vert_count = self._r_vert_count
        cdef int index_count = self._index_count
        cdef int r_index_count = self._r_index_count
        cdef int r_attrib_count = self._r_attrib_count
        cdef float* batch_data = self._batch_data
        cdef int attribute_count = self._attrib_count
        cdef CMesh cmesh = self._cmesh
        cdef unsigned short* batch_indices = self._batch_indices
        if vert_count != r_vert_count or attribute_count != r_attrib_count:
            if not batch_data:
                batch_data = <float *>PyMem_Malloc(
                    vert_count * attribute_count * sizeof(float))
            else:
                batch_data = <float *>PyMem_Realloc(batch_data, 
                    attribute_count * vert_count * sizeof(float))
                if not batch_data:
                    raise MemoryError()
            self._r_vert_count = vert_count
            self._r_attrib_count = attribute_count
            self._batch_data = batch_data
            cmesh._vertices = batch_data
            cmesh.vcount = vert_count*attribute_count
        if index_count != r_index_count:
            if not batch_indices:
                batch_indices = <unsigned short*>PyMem_Malloc(
                    index_count * sizeof(unsigned short))
            else:
                batch_indices = <unsigned short*>PyMem_Realloc(
                    batch_indices, index_count * sizeof(unsigned short))
                if not batch_indices:
                    raise MemoryError()
            self._r_index_count = index_count
            self._batch_indices = batch_indices
            cmesh._indices = batch_indices
            cmesh.icount = index_count


    def __dealloc__(self):
        if self._batch_data != NULL:
            PyMem_Free(self._batch_data)
        if self._batch_indices != NULL:
            PyMem_Free(self._batch_indices)

    def add_entity(self, int entity_id, int num_verts, int num_indices,
        str texture_key):
        if num_verts + self._vert_count > self._maximum_verts or not (
            texture_manager.get_texkey_in_group(texture_key, self._texture)):
            return False
        else:
            self._vert_count += num_verts
            self._index_count += num_indices
            self._entity_ids.append(entity_id)
            self._entity_counts[entity_id] = (num_verts, num_indices)
            return True

    def remove_entity(self, int entity_id):
        self._entity_ids.remove(entity_id)
        entity_counts = self._entity_counts
        num_verts, num_indices = entity_counts[entity_id]
        self._vert_count -= num_verts
        self._index_count -= num_indices
        del entity_counts[entity_id]

    def update_entity_counts(self, int entity_id, int new_vert_count, 
        int new_indices_count):
        entity_counts = self._entity_counts
        num_verts, num_indices = entity_counts[entity_id]
        vert_change = new_vert_count - num_verts
        index_change = new_indices_count - num_indices
        self._vert_count += vert_change
        self._index_count += index_change
        entity_counts[entity_id] = (new_vert_count, new_indices_count)




Factory.register('Renderer', cls=Renderer)
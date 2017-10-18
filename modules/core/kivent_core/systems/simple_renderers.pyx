# cython: profile=True
# cython: embedsignature=True
from cpython cimport bool
from kivy.properties import (
    BooleanProperty, StringProperty, NumericProperty, ListProperty
    )
from kivy.graphics import Callback
from kivy.graphics.instructions cimport RenderContext
from kivent_core.rendering.vertex_formats cimport (
    VertexFormat4F, VertexFormat2F4UB, VertexFormat7F, VertexFormat4F4UB,
    VertexFormat5F4UB, VertexFormat7F4UB
    )
from kivent_core.rendering.vertex_formats import (
    vertex_format_4f, vertex_format_7f, vertex_format_4f4ub,
    vertex_format_2f4ub, vertex_format_5f4ub, vertex_format_7f4ub
    )
from kivent_core.rendering.frame_objects cimport MAX_GL_VERTICES
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivent_core.rendering.cmesh cimport CMesh
from kivent_core.rendering.batching cimport SimpleBatchManager, SimpleBatch
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.managers.resource_managers cimport ModelManager, TextureManager
from kivy.graphics.opengl import (
    glEnable, glDisable, glBlendFunc, GL_SRC_ALPHA, GL_ONE,
    GL_ZERO, GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA,
    GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR,
    )
cimport cython
from kivy.graphics.cgl cimport GLfloat, GLushort
from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.systems.position_systems cimport PositionStruct2D
from kivent_core.systems.rotate_systems cimport RotateStruct2D
from kivent_core.systems.scale_systems cimport ScaleStruct2D
from kivent_core.systems.color_systems cimport ColorStruct
from kivent_core.entity cimport Entity
from kivent_core.rendering.model cimport VertexModel
from kivent_core.systems.renderers cimport RenderStruct, RenderComponent
from kivy.factory import Factory
from libc.math cimport fabs
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.systems.staticmemgamesystem cimport ComponentPointerAggregator
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivy.properties import ObjectProperty, NumericProperty
from kivy.clock import Clock
from kivent_core.rendering.gl_debug cimport gl_log_debug_message
from functools import partial

cdef unsigned char blend_integer_colors(unsigned char color1,
                                        unsigned char color2):
    return <unsigned char>((<float>color1 / 255.) * (
                           <float>color2 / 255.) * 255)

cdef class SimpleRenderer(StaticMemGameSystem):
    '''

    '''
    system_id = StringProperty('simple_renderer')
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)
    processor = BooleanProperty(True)
    max_batches = NumericProperty(10)
    frame_count = NumericProperty(2)
    system_names = ListProperty(['simple_renderer', 'position',
                                 'scale', 'color'])
    shader_source = StringProperty('positionshader.glsl')
    model_format = StringProperty('vertex_format_4f')
    blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    reset_blend_factor_source = NumericProperty(GL_SRC_ALPHA)
    reset_blend_factor_dest = NumericProperty(GL_ONE_MINUS_SRC_ALPHA)
    type_size = NumericProperty(sizeof(RenderStruct))
    component_type = ObjectProperty(RenderComponent)
    vertex_format_size = NumericProperty(sizeof(VertexFormat2F4UB))

    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True,
                                    nocompiler=True)
        if 'shader_source' in kwargs:
            self.canvas.shader.source = kwargs.get('shader_source')
        super(SimpleRenderer, self).__init__(**kwargs)
        with self.canvas.before:
            Callback(self._set_blend_func)
        with self.canvas.after:
            Callback(self._reset_blend_func)
        self.update_trigger = Clock.create_trigger(partial(self.update, True))


    property update_trigger:

        def __get__(self):
            return self.update_trigger

    def _set_blend_func(self, instruction):
        '''
        This function is called internally in a callback on canvas.before
        to set up the blend function, it will obey **blend_factor_source**
        and **blend_factor_dest** properties.
        '''
        gl_log_debug_message('Renderer._set_blend_func-preglBlendFunc')
        glBlendFunc(self.blend_factor_source, self.blend_factor_dest)
        gl_log_debug_message('Renderer._set_blend_func-glBlendFunc')

    def _reset_blend_func(self, instruction):
        '''
        This function is called internally in a callback on canvas.after
        to reset the blend function, it will obey **reset_blend_factor_source**
        and **reset_blend_factor_dest** properties.
        '''
        glBlendFunc(self.reset_blend_factor_source,
            self.reset_blend_factor_dest)
        gl_log_debug_message('Renderer._reset_blend_func-glBlendFunc')

    def _update(self, dt):
        '''
        We only want to update renderer once per frame, so we will override
        the basic GameSystem logic here which accounts appropriately for
        dt.
        '''
        self.update(False, dt)

    def on_shader_source(self, instance, value):
        '''
        Event that sets the canvas.shader.source property when the
        **shader_source** property is set
        '''
        self.canvas.shader.source = value

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef RenderStruct* pointer = <RenderStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = -1
        pointer.model = NULL
        pointer.renderer = NULL
        pointer.texkey = -1
        pointer.render = 0
        pointer.batch_id = -1
        pointer.vert_index = -1
        pointer.ind_index = -1

    cdef void* setup_batch_manager(self, Buffer master_buffer) except NULL:
        '''
        Function called internally during **allocate** to setup the
        BatchManager. The KEVertexFormat should be initialized in this
        function as well.
        '''
        cdef KEVertexFormat batch_vertex_format = KEVertexFormat(
            sizeof(VertexFormat2F4UB), *vertex_format_2f4ub)
        self.batch_manager = SimpleBatchManager(
            self.max_batches, self.frame_count, batch_vertex_format,
            'triangles', self.canvas)
        return <void*>self.batch_manager

    def allocate(self, Buffer master_buffer, dict reserve_spec):
        super(SimpleRenderer, self).allocate(master_buffer, reserve_spec)
        self.setup_batch_manager(master_buffer)

    def get_system_size(self):
        return super(SimpleRenderer, self).get_system_size() \
               + self.batch_manager.get_size()

    def get_size_estimate(self, dict reserve_spec):
        cdef unsigned int total = super(SimpleRenderer, self).get_size_estimate(
            reserve_spec)
        return total

    cdef void* _init_component(self, unsigned int component_index,
        unsigned int entity_id, bool render, VertexModel model,
        unsigned int texkey) except NULL:
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef RenderStruct* pointer = <RenderStruct*>memory_zone.get_pointer(
            component_index)
        pointer.entity_id = entity_id
        pointer.model = <void*>model
        pointer.renderer = <void*>self
        pointer.texkey = texkey
        if render:
            pointer.render = 1
        else:
            pointer.render = 0
        return pointer

    def init_component(self, unsigned int component_index,
        unsigned int entity_id, str zone_name, args):
        '''
        A RenderComponent is initialized with an args dict with many
        optional values.

        Optional Args:

            texture (str): If 'texture' is in args, the appropriate texture
            will be loaded from managers.resource_managers.texture_manager.
            #change to model_key
            vert_mesh_key (str): If 'vert_mesh_key' is in args, the associated
            model from managers.resource_managers.model_manager will be loaded.
            Otherwise, it will be assumed we are rendering a sprite and the
            appropriate model for that sprite will either be generated or
            loaded from the model_manager if it already exists. If this occurs
            the models name will be str(**attribute_count**) + texture_key.

            size (tuple): If size is provided and there is no 'vert_mesh_key'
            and the sprite has not been loaded before the size of the newly
            generated sprite VertMesh will be set to (width, height).

            render (bool): If 'render' is in args, the components render
            attribute will be set to the provided, otherwise it defaults to
            True.

        Keep in mind that all RenderComponent will share the same VertMesh if
        they have the same vert_mesh_key or load the same sprite.
        '''
        cdef float w, h
        cdef int vert_index_key, texkey
        cdef bool copy, render
        if 'texture' in args:
            texture_key = args['texture']
            texkey = texture_manager.get_texkey_from_name(texture_key)
            w, h = texture_manager.get_size(texkey)
        else:
            texture_key = str(None)
            texkey = -1
        if 'size' in args:
            w, h = args['size']
        copy = args.get('copy', False)
        copy_name = args.get('copy_name', None)
        render = args.get('render', True)
        model_key = args.get('model_key', None)
        cdef ModelManager model_manager = self.gameworld.model_manager
        if model_key is None:
            if copy_name is None:
                copy_name = self.model_format + '_' + texture_key
            model_key = model_manager.load_textured_rectangle(
                self.model_format, w, h, texture_key, copy_name,
                do_copy=copy)
        elif model_key is not None and copy:
            model_key = model_manager.copy_model(model_key,
                model_name=copy_name)
        cdef VertexModel model = model_manager._models[model_key]
        model_manager.register_entity_with_model(entity_id, self.system_id,
            model_key)
        self._init_component(component_index, entity_id, render, model, texkey)
        return self.entity_components.add_entity(entity_id, zone_name)

    cdef void write_vertex_data(self, VertexFormat2F4UB* vertex,
                                VertexFormat2F4UB* model_vertex,
                                void** component_data):
        cdef RenderStruct* render_comp = <RenderStruct*>component_data[0]
        cdef PositionStruct2D* pos_comp = <PositionStruct2D*>component_data[1]
        cdef ScaleStruct2D* scale_comp = <ScaleStruct2D*>component_data[2]
        cdef ColorStruct* color_comp = <ColorStruct*>component_data[3]
        vertex.pos[0] = pos_comp.x + (model_vertex.pos[0] * scale_comp.sx)
        vertex.pos[1] = pos_comp.y + (model_vertex.pos[1] * scale_comp.sy)
        vertex.v_color[0] = blend_integer_colors(model_vertex.v_color[0],
                                                 color_comp.color[0])
        vertex.v_color[1] = blend_integer_colors(model_vertex.v_color[1],
                                                 color_comp.color[1])
        vertex.v_color[2] = blend_integer_colors(model_vertex.v_color[2],
                                                 color_comp.color[2])
        vertex.v_color[3] = blend_integer_colors(model_vertex.v_color[3],
                                                 color_comp.color[3])


    def update(self, force_update, dt):
        '''
        Update function where all drawing of entities is performed.
        Override this method if you would like to create a renderer with
        customized behavior. The basic logic is that we iterate through
        each batch getting the entities in that batch, then iterate through
        the vertices in the RenderComponent.vert_mesh, copying every
        vertex into the batches data and combining it with data from other
        components.

        Args:
            dt (float): The time elapsed since last update, not usually
            used in rendering but passed in to maintain a consistent API.
        '''
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index, vert_offset, n, ind
        remove_entity = self.gameworld.remove_entity
        cdef RenderStruct* render_comp
        cdef VertexModel model
        cdef SimpleBatch batch
        cdef SimpleBatchManager batch_manager = self.batch_manager
        cdef GLushort* frame_indices
        cdef GLushort* model_indices
        cdef VertexFormat2F4UB* model_vertices
        cdef VertexFormat2F4UB* vertices
        batch_manager.prepare_frames()
        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            render_comp = <RenderStruct*>component_data[real_index]
            if render_comp.render:
                model = <VertexModel>render_comp.model
                batch = batch_manager.get_batch_with_space(render_comp.texkey,
                                                           model._vertex_count,
                                                           model._index_count)
                frame_indices = <GLushort*>batch.get_current_index_location()
                model_indices = <GLushort*>model.indices_block.data
                model_vertices = <VertexFormat2F4UB*>model.vertices_block.data
                vert_offset = batch.get_current_vertex_offset()
                vertices = <VertexFormat2F4UB*>batch.get_current_vertex_location()
                for ind in range(model._index_count):
                    frame_indices[ind] = model_indices[ind] + vert_offset
                for n in range(model._vertex_count):
                    self.write_vertex_data(&vertices[n], &model_vertices[n],
                                           &component_data[real_index])
                batch.commit_data(model._vertex_count, model._index_count)
        batch_manager.cleanup_empty_frames()



    def remove_component(self, unsigned int component_index):
        cdef IndexedMemoryZone components = self.imz_components
        cdef RenderStruct* pointer = <RenderStruct*>components.get_pointer(
            component_index)
        self.entity_components.remove_entity(pointer.entity_id)
        self.gameworld.model_manager.unregister_entity_with_model(
            pointer.entity_id, (<VertexModel>pointer.model)._name)
        super(SimpleRenderer, self).remove_component(component_index)

Factory.register('SimpleRenderer', cls=SimpleRenderer)
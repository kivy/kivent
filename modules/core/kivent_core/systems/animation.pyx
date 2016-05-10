# cython: embedsignature=True
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem,
    MemComponent)
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.systems.renderers cimport RenderStruct, Renderer
from kivent_core.rendering.animation cimport FrameList, Frame, FrameStruct
from kivent_core.rendering.model cimport VertexModel
from kivent_core.managers.resource_managers import texture_manager
from kivy.properties import (StringProperty, ObjectProperty, NumericProperty,
        BooleanProperty, ListProperty)
from kivy.factory import Factory


cdef class AnimationComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.entity_id

    property current_frame_index:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.current_frame_index

        def __set__(self, unsigned int value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.current_frame_index = value

    property current_duration:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.current_duration

        def __set__(self, unsigned int value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.current_duration = value


cdef class AnimationSystem(StaticMemGameSystem):
    '''Accepts a dict in the following format:
        {
            'frames': [ <array of frame objects> ]
        }

        Where a sinlge frame object is of the format:
        {
            'texture': <texture-name>,
            'model': <model-name>,
            'duration': <duration>
        }'''

    system_id = StringProperty('animation')
    processor = BooleanProperty(True)
    type_size = NumericProperty(sizeof(AnimationStruct))
    component_type = ObjectProperty(AnimationComponent)
    system_names = ListProperty(['animation','renderer'])

    def init_component(self, unsigned int component_index,
                       unsigned int entity_id, str zone, args):
        model_manager = self.gameworld.model_manager
        animation_manager = self.gameworld.animation_manager

        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* component = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        cdef FrameList frame_list = animation_manager.animations[args]
        component.entity_id = entity_id
        component.frames = <void*>frame_list
        component.current_frame_index = <unsigned int>-1
        component.current_duration = 0

        return self.entity_components.add_entity(entity_id, zone)

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* pointer = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.frames = NULL
        pointer.current_frame_index = 0
        pointer.current_duration = 0


    def remove_component(self, unsigned int component_index):
        cdef AnimationComponent component = self.components[component_index]
        self.entity_components.remove_entity(component.entity_id)
        super(AnimationSystem, self).remove_component(component_index)


    def update(self, dt):
        gameworld = self.gameworld
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index
        cdef FrameList frame_list
        cdef AnimationStruct* anim_comp
        cdef RenderStruct* render_comp
        cdef FrameStruct* next_frame
        cdef unsigned int groupkey
        cdef VertexModel new_model
        cdef Renderer renderer
        cdef float u0, u1, v0, v1
        cdef list uv_list

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            anim_comp = <AnimationStruct*>component_data[real_index]
            render_comp = <RenderStruct*>component_data[real_index+1]
            frame_data = anim_comp.frames[anim_comp.current_frame_index]

            anim_comp.current_duration += dt
            if frame_data.duration < anim_comp.current_duration:
                anim_comp.current_duration = 0
                anim_comp.current_frame_index += 1
                frame_list = <FrameList>anim_comp.frames
                next_frame = <FrameStruct*>(frame_list[anim_comp.current_frame_index].frame_pointer)

                groupkey = (texture_manager.get_groupkey_from_texkey(
                                                next_frame.texkey))
                uv_list = texture_manager.get_uvs(next_frame.texkey)
                u0 = uv_list[0]
                v0 = uv_list[1]
                u1 = uv_list[2]
                v1 = uv_list[3]
                same_batch = texture_manager.get_texkey_in_group(next_frame.texkey, groupkey)
                model = <VertexModel>next_frame.model
                renderer = <Renderer>render_comp.renderer
                if not same_batch:
                    renderer._unbatch_entity(render_comp.entity_id,
                        render_comp)
                render_comp.texkey = next_frame.texkey
                render_comp.model = next_frame.model
                model[0].uvs = [u0, v0]
                model[1].uvs = [u0, v1]
                model[2].uvs = [u1, v1]
                model[3].uvs = [u1, v0]
                if not same_batch:
                    renderer._batch_entity(render_comp.entity_id,
                        render_comp)


Factory.register('AnimationSystem', cls=AnimationSystem)

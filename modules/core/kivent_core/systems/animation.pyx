# cython: embedsignature=True
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem,
    MemComponent)
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.systems.renderers cimport RenderStruct
from kivent_core.managers.resource_managers import texture_manager
from kivy.properties import (StringProperty, ObjectProperty, NumericProperty,
        BooleanProperty, ListProperty)
from kivy.factory import Factory


cdef class AnimationComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.entity_id

    property frame_count:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.frame_count

        def __set__(self, unsigned int value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.frame_count = value

    property current_frame:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.current_frame

        def __set__(self, unsigned int value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.current_frame = value

    property current_duration:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.current_duration

        def __set__(self, unsigned int value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.current_duration = value

    cdef FrameStruct* get_current_frame(self):
        cdef AnimationStruct* data = <AnimationStruct*>self.pointer
        return data.frames[data.current_frame]


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
        texture_manager = self.gameworld.texture_manager

        cdef unsigned int frame_count = len(args.frames)
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* component = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = entity_id
        component.frame_count = frame_count
        component.current_frame = 0
        component.current_duration = 0

        cdef FrameStruct* frames_array[100]
        cdef FrameStruct frame
        cdef unsigned int i = 0
        for i in range(frame_count):
            frame_data = args.frames[i]

            frame.texkey = <unsigned int> texture_manager.get_texkey_from_name(frame_data['texture'])
            frame.model = <void*> model_manager.models[frame_data['model']]
            frame.duration = <unsigned int> frame_data['duration']

            frames_array[i] = &frame

        component.frames = <FrameStruct**>frames_array

        return self.entity_components.add_entity(entity_id, zone)

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* pointer = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.frames = NULL
        pointer.frame_count = 0
        pointer.current_frame = 0
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
        cdef AnimationStruct* anim_comp
        cdef RenderStruct* render_comp

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            anim_comp = <AnimationStruct*>component_data[real_index]
            render_comp = <RenderStruct*>component_data[real_index+1]
            current_frame = <FrameStruct*>anim_comp.frames[anim_comp.current_frame]

            anim_comp.current_duration += dt
            if current_frame.duration < anim_comp.current_duration:
                anim_comp.current_duration = 0
                anim_comp.current_frame += 1
                next_frame = <FrameStruct*>anim_comp.frames[anim_comp.current_frame]

                render_comp.texkey = next_frame.texkey
                render_comp.model = next_frame.model


Factory.register('animation', cls=AnimationSystem)

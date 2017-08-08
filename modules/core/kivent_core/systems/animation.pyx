# cython: embedsignature=True
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem,
    MemComponent)
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.systems.renderers cimport RenderStruct, Renderer
from kivent_core.rendering.animation cimport FrameList, Frame, FrameStruct
from kivent_core.rendering.model cimport VertexModel
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.animation_manager cimport AnimationManager
from kivy.properties import (StringProperty, ObjectProperty, NumericProperty,
        BooleanProperty, ListProperty)
from kivy.factory import Factory

cdef class AnimationComponent(MemComponent):
    '''The component associated with AnimationSystem. Stores the current
    state of the sprite's animation: current frame, duration passed while
    on this frame, whether to loop the animation, and a dirty flag to
    indicate frame needs to be rendered.

    **Attributes:**
        **entity_id** (unsigned int): The entity_id this component is currently
        associated with. Will be <unsigned int>-1 if the component is
        unattached.

        **current_frame_index:** (unsigned int): The current frame being
        displayed of the animation and <unsigned int>-1 if the animation
        is stopped.

        **current_duration:** (float): The time in milliseconds the sprite
        has spent on the current frame. Used internally by the system's
        update method to increment this.

        **loop:** (bint): Whether to loop this animation or not.

        **dirty:** (bint): Flag denoting whether this animation
        needs to be re-rendered i.e. the texture and model
        need to be set to the RenderComponent.

        **animation:** (str): Name of the animation which this component
        is playing. You can set this to change the animation of an entity.
        Can only be set, and not read.
    '''


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

        def __set__(self, float value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.current_duration = value

    property loop:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.loop

        def __set__(self, bint value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.loop = value

    property dirty:
        def __get__(self):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            return data.dirty

        def __set__(self, bint value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            data.dirty = value

    property animation:
        def __set__(self, str value):
            cdef AnimationStruct* data = <AnimationStruct*>self.pointer
            cdef AnimationManager manager = <AnimationManager>data.manager
            cdef FrameList frames = manager._animations[value]
            data.frames = <void*>frames
            data.current_frame_index = 0
            data.current_duration = 0
            data.dirty = True


cdef class AnimationSystem(StaticMemGameSystem):
    '''
    Processing depends on: Renderer, AnimationSystem

    This GameSystem updates the model and texkey of the RenderComponent
    as per frames of the animation.
    '''

    system_id = StringProperty('animation')
    processor = BooleanProperty(True)
    updateable = BooleanProperty(True)
    type_size = NumericProperty(sizeof(AnimationStruct))
    component_type = ObjectProperty(AnimationComponent)
    system_names = ListProperty(['animation','renderer'])

    def init_component(self, unsigned int component_index,
                       unsigned int entity_id, str zone, args):
        '''
        Function to initialise an AnimationComponent

        Optional Args:

            name (str): name of the animation which is registered
                        in animation_manager
            loop (bool): whether to loop this animation or not
        '''
        model_manager = self.gameworld.model_manager
        animation_manager = self.gameworld.animation_manager

        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* component = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        cdef FrameList frame_list = animation_manager.animations[args['name']]
        component.entity_id = entity_id
        component.frames = <void*>frame_list
        component.manager = <void*>animation_manager
        component.current_frame_index = 0
        component.current_duration = 0
        component.loop = args['loop']

        return self.entity_components.add_entity(entity_id, zone)

    def clear_component(self, unsigned int component_index):
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef AnimationStruct* pointer = <AnimationStruct*>(
            memory_zone.get_pointer(component_index))
        pointer.entity_id = -1
        pointer.frames = NULL
        pointer.current_frame_index = <unsigned int>-1
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
        cdef Frame frame
        cdef AnimationStruct* anim_comp
        cdef RenderStruct* render_comp
        cdef FrameStruct* frame_data
        cdef unsigned int current_index
        cdef unsigned int groupkey
        cdef Renderer renderer
        cdef ModelManager model_manager = self.gameworld.model_manager


        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue
            anim_comp = <AnimationStruct*>component_data[real_index]
            render_comp = <RenderStruct*>component_data[real_index+1]

            frame_list = <FrameList>anim_comp.frames
            current_index = anim_comp.current_frame_index
            frame = frame_list[current_index]
            frame_data = <FrameStruct*>frame.frame_pointer

            anim_comp.current_duration += dt * 1000

            if frame_data.duration < anim_comp.current_duration:
                # Switch to next frame
                current_index += 1
                if current_index == frame_list.frame_count:
                    if anim_comp.loop:
                        current_index = 0
                    else:
                        current_index = <unsigned int>-1

                anim_comp.current_frame_index = current_index
                # store the difference of current duration and frame duration
                # to account for overshoot errors
                anim_comp.current_duration = (anim_comp.current_duration
                                              - frame_data.duration)
                anim_comp.dirty = True

            if current_index != <unsigned int>-1 and anim_comp.dirty:
                # Animation is dirty
                # update texture and model in RenderComponent
                frame = frame_list[current_index]
                frame_data = <FrameStruct*>frame.frame_pointer
                groupkey = (texture_manager.get_groupkey_from_texkey(
                                                frame_data.texkey))
                same_batch = texture_manager.get_texkey_in_group(
                                                render_comp.texkey,
                                                groupkey)
                model_manager.unregister_entity_with_model(
                    render_comp.entity_id,
                    (<VertexModel>render_comp.model)._name)
                render_comp.model = frame_data.model
                model_manager.register_entity_with_model(
                    render_comp.entity_id, self.system_id,
                    (<VertexModel>render_comp.model)._name)
                renderer = <Renderer>render_comp.renderer
                if not same_batch:
                    renderer._unbatch_entity(render_comp.entity_id,
                        render_comp)
                render_comp.texkey = frame_data.texkey
                if not same_batch:
                    renderer._batch_entity(render_comp.entity_id,
                        render_comp)
                anim_comp.dirty = False


Factory.register('AnimationSystem', cls=AnimationSystem)

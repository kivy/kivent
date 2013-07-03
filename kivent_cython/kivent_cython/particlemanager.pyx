import particlesystem
from kivy.properties import StringProperty, BooleanProperty
from math import radians
from xml.dom.minidom import parse as parse_xml
from kivy.core.image import Image as CoreImage


class ParticleManager(GameSystem):
    ##This widget is currently only designed to work with chipmunk based 
    ##objects
    system_id = StringProperty('particle_manager')
    position_data_from = StringProperty('cymunk-physics')
    render_information_from = StringProperty('physics_renderer')
    updateable = BooleanProperty(True)

    def __init__(self, **kwargs):
        super(ParticleManager, self).__init__(**kwargs)
        self.particle_configs = {}
        self.particle_textures = {}

    def load_particle_config(self, config):
        config_str = config
        config = parse_xml(config)
        particle_configs = self.particle_configs
        particle_textures = self.particle_textures
        particle_configs[config_str] = particle_config = {}
        texture_str = self.parse_data(config, 'texture', 'name')
        particle_config['texture'] = texture_str
        if not texture_str in particle_textures:
            particle_textures[texture_str] = CoreImage(texture_str).texture
        particle_config['emitter_x_variance'] = float(self.parse_data(
            config, 'sourcePositionVariance', 'x'))
        particle_config['emitter_y_variance'] = float(self.parse_data(
            config, 'sourcePositionVariance', 'y'))
        particle_config['gravity_x'] = float(self.parse_data(
            config, 'gravity', 'x'))
        particle_config['gravity_y'] = float(self.parse_data(
            config,'gravity', 'y'))
        particle_config['emitter_type'] = int(self.parse_data(
            config, 'emitterType'))
        particle_config['max_num_particles'] = int(self.parse_data(
            config, 'maxParticles'))
        particle_config['life_span'] = max(0.01, float(self.parse_data(
            config, 'particleLifeSpan')))
        particle_config['life_span_variance'] = float(self.parse_data(
            config, 'particleLifespanVariance'))
        particle_config['start_size'] = float(self.parse_data(
            config, 'startParticleSize'))
        particle_config['start_size_variance'] = float(self.parse_data(
            config, 'startParticleSizeVariance'))
        particle_config['end_size'] = float(self.parse_data(
            config, 'finishParticleSize'))
        particle_config['end_size_variance'] = float(self.parse_data(
            config, 'FinishParticleSizeVariance'))
        particle_config['emit_angle'] = math.radians(float(self.parse_data(
            config, 'angle')))
        particle_config['emit_angle_variance'] = math.radians(float(self.parse_data(
            config, 'angleVariance')))
        particle_config['start_rotation'] = math.radians(float(self.parse_data(
            config, 'rotationStart')))
        particle_config['start_rotation_variance'] = math.radians(float(self.parse_data(
            config, 'rotationStartVariance')))
        particle_config['end_rotation'] = math.radians(float(self.parse_data(
            config, 'rotationEnd')))
        particle_config['end_rotation_variance'] = math.radians(float(self.parse_data(
            config, 'rotationEndVariance')))
        particle_config['speed'] = float(self.parse_data(
            config, 'speed'))
        particle_config['speed_variance'] = float(self.parse_data(
            config, 'speedVariance'))
        particle_config['radial_acceleration'] = float(self.parse_data(
            config, 'radialAcceleration'))
        particle_config['radial_acceleration_variance'] = float(self.parse_data(
            config, 'radialAccelVariance'))
        particle_config['tangential_acceleration'] = float(self.parse_data(
            config, 'tangentialAcceleration'))
        particle_config['tangential_acceleration_variance'] = float(self.parse_data(
            config, 'tangentialAccelVariance'))
        particle_config['max_radius'] = float(self.parse_data(
            config, 'maxRadius'))
        particle_config['max_radius_variance'] = float(self.parse_data(
            config, 'maxRadiusVariance'))
        particle_config['min_radius'] = float(self.parse_data(
            config, 'minRadius'))
        particle_config['rotate_per_second'] = math.radians(float(self.parse_data(
            config, 'rotatePerSecond')))
        particle_config['rotate_per_second_variance'] = math.radians(float(self.parse_data(
            config, 'rotatePerSecondVariance')))
        particle_config['start_color'] = self.parse_color(
            config, 'startColor')
        particle_config['start_color_variance'] = self.parse_color(
            config, 'startColorVariance')
        particle_config['end_color'] = self.parse_color(
            config, 'finishColor')
        particle_config['end_color_variance'] = self.parse_color(
            config, 'finishColorVariance')
        particle_config['blend_factor_source'] = self.parse_blend(
            config, 'blendFuncSource')
        particle_config['blend_factor_dest'] = self.parse_blend(
            config, 'blendFuncDestination')

    def parse_data(self, config, name, attribute='value'):
        return config.getElementsByTagName(
            name)[0].getAttribute(attribute)

    def parse_color(self, config, name):
        return [
            float(self.parse_data(config, name, 'red')), 
            float(self.parse_data(config, name, 'green')), 
            float(self.parse_data(config, name, 'blue')), 
            float(self.parse_data(config, name, 'alpha')),
            ]

    def parse_blend(self, config, name):
        value = int(self.parse_data(config, name))
        return particlesystem.BLEND_FUNC[value]

    def load_particle_system_from_dict(self, config):
        config_dict = self.particle_configs[config]
        return particlesystem.ParticleSystem(
            None, 
            max_num_particles = config_dict['max_num_particles'],
            life_span = config_dict['life_span'],
            texture = self.particle_textures[config_dict['texture']],
            texture_path = config_dict['texture'],
            life_span_variance = config_dict['life_span_variance'],
            start_size = config_dict['start_size'],
            start_size_variance = config_dict['start_size_variance'],
            end_size = config_dict['end_size'],
            end_size_variance = config_dict['end_size_variance'],
            emit_angle = config_dict['emit_angle'],
            emit_angle_variance = config_dict['emit_angle_variance'],
            start_rotation = config_dict['start_rotation'],
            start_rotation_variance = config_dict['start_rotation_variance'],
            end_rotation = config_dict['end_rotation'],
            end_rotation_variance = config_dict['end_rotation_variance'],
            emitter_x_variance = config_dict['emitter_x_variance'],
            emitter_y_variance = config_dict['emitter_y_variance'],
            gravity_x = config_dict['gravity_x'],
            gravity_y = config_dict['gravity_y'],
            speed = config_dict['speed'],
            speed_variance = config_dict['speed_variance'],
            radial_acceleration = config_dict['radial_acceleration'],
            radial_acceleration_variance = config_dict['radial_acceleration_variance'],
            tangential_acceleration = config_dict['tangential_acceleration'],
            tangential_acceleration_variance = config_dict['tangential_acceleration_variance'],
            max_radius = config_dict['max_radius'],
            max_radius_variance = config_dict['max_radius_variance'],
            min_radius = config_dict['min_radius'],
            rotate_per_second = config_dict['rotate_per_second'],
            rotate_per_second_variance = config_dict['rotate_per_second_variance'],
            start_color = config_dict['start_color'],
            start_color_variance = config_dict['start_color_variance'],
            end_color = config_dict['end_color'],
            end_color_variance = config_dict['end_color_variance'],
            blend_factor_source =config_dict['blend_factor_source'],
            blend_factor_dest = config_dict['blend_factor_dest'],
            emitter_type = config_dict['emitter_type'],
            )
        
    def generate_component_data(self, dict entity_component_dict):
        for particle_effect in entity_component_dict:
            config = entity_component_dict[particle_effect]['particle_file']
            if not config in self.particle_configs:
                self.load_particle_config(config)
            entity_component_dict[particle_effect]['particle_system'] = (
                particle_system) = self.load_particle_system_from_dict(config)
            particle_system.stop()
            entity_component_dict[particle_effect]['particle_system_on'] = False
        return entity_component_dict

    def remove_entity(self, entity_id):
        cdef list entities = self.gameworld.entities
        cdef str system_id = self.system_id
        cdef dict entity = entities[entity_id]
        cdef object particle_system 
        cdef dict particle_systems
        particle_systems = entity[self.system_id]
        for particle_effect in particle_systems:
            particle_system = particle_systems[particle_effect]['particle_system']
            particle_system.stop(clear=True)
            del particle_system
        super(ParticleManager, self).remove_entity(entity_id)

    def on_paused(self, instance, value):
        cdef list entities = self.gameworld.entities
        cdef str system_data_from = self.system_id
        cdef dict entity
        cdef dict particle_systems
        cdef object particle_system
        if value == True:
            for entity_id in self.entity_ids:
                entity = entities[entity_id]
                particle_systems = entity[system_data_from]
                for particle_effect in particle_systems:
                    particle_system = particle_systems[particle_effect]['particle_system']
                    particle_system.pause(with_clear = True)

    def update(self, dt):
        cdef dict systems = self.gameworld.systems
        cdef list entities = self.gameworld.entities
        cdef str render_information_from = self.render_information_from
        camera_pos = self.gameworld.systems[self.viewport].camera_pos
        cdef str position_data_from = self.position_data_from
        cdef str system_data_from = self.system_id
        cdef dict entity
        cdef dict particle_systems
        cdef object particle_system
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            particle_systems = entity[system_data_from]
            for particle_effect in particle_systems:
                particle_system = particle_systems[particle_effect]['particle_system']
                if entity[render_information_from]['on_screen']:
                    if particle_systems[particle_effect]['particle_system_on']:
                        particle_system.current_scroll = camera_pos
                        particle_system.pos = self.calculate_particle_offset(entity_id, particle_effect)
                        particle_system.emit_angle = radians(entity[position_data_from]['angle']-90)
                        if particle_system._is_paused:
                            particle_system.resume()
                        if particle_system.emission_time <= 0:
                            particle_system.start()
                        if not particle_system in self.children:
                            self.add_widget(particle_system) 
                    elif particle_system.emission_time > 0:
                        particle_system.stop()
                elif not particle_system._is_paused:
                    particle_system.pause(with_clear = True)
                    if particle_system in self.children:
                        self.remove_widget(particle_system)

    def calculate_particle_offset(self, entity_id, particle_effect):
        cdef dict entity = self.gameworld.entities[entity_id]
        cdef dict position_data = entity[self.position_data_from]
        cdef dict system_data = entity[self.system_id]
        cdef int offset = system_data[particle_effect]['offset']
        pos = position_data['position']
        cdef dict unit_vector = position_data['unit_vector']
        cdef tuple effect_pos = (pos[0] - offset * -unit_vector['x'], pos[1] - offset * -unit_vector['y'])
        return effect_pos
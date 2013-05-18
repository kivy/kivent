import kivyparticle
from kivy.properties import StringProperty, BooleanProperty
from gamesystems import GameSystem
from math import radians

class ParticleManager(GameSystem):
    ##This widget is currently only designed to work with chipmunk based objects
    system_id = StringProperty('particle_manager')
    position_data_from = StringProperty('cymunk-physics')
    render_information_from = StringProperty('physics_renderer')
    updateable = BooleanProperty(True)


    def generate_component_data(self, entity_component_dict):
        entity_component_dict['particle_system'] = particle_system = kivyparticle.ParticleSystem(entity_component_dict['particle_file'])
        particle_system.stop()
        entity_component_dict['particle_system_on'] = False
        return entity_component_dict

    def on_paused(self, instance, value):
        entities = self.gameworld.entities
        system_data_from = self.system_id
        if value == True:
            for entity_id in self.entity_ids:
                entity = entities[entity_id]
                particle_system = entity[system_data_from]['particle_system']
                particle_system.pause(with_clear = True)

    def update(self, dt):
        systems = self.gameworld.systems
        entities = self.gameworld.entities
        render_information_from = self.render_information_from
        camera_pos = self.gameworld.systems[self.viewport].camera_pos
        position_data_from = self.position_data_from
        system_data_from = self.system_id
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            particle_system = entity[system_data_from]['particle_system']
            if entity[render_information_from]['render']:
                if entity[system_data_from]['particle_system_on']:
                    particle_system.current_scroll = camera_pos
                    particle_system.pos = self.calculate_particle_offset(entity_id)
                    particle_system.emit_angle = radians(entity[position_data_from]['angle'])
                    if particle_system._is_paused:
                        particle_system.resume()
                    if particle_system.emission_time <= 0:
                        particle_system.start()
                    if not particle_system in self.children:
                        self.add_widget(particle_system) 
                elif particle_system.emission_time > 0:
                    particle_system.stop()
            elif not particle_system._is_paused:
                print 'removing system'
                particle_system.pause(with_clear = True)
                if particle_system in self.children:
                    self.remove_widget(particle_system)

    def calculate_particle_offset(self, entity_id):
        entity = self.gameworld.entities[entity_id]
        position_data = entity[self.position_data_from]
        system_data = entity[self.system_id]
        offset = system_data['offset']
        pos = position_data['position']
        unit_vector = position_data['unit_vector']
        effect_pos = (pos[0] - offset * -unit_vector['x'], pos[1] - offset * -unit_vector['y'])
        return effect_pos
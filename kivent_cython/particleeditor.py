import kivy
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ObjectProperty, NumericProperty, 
    BooleanProperty)
from kivy.clock import Clock
from kivent_cython import (GameWorld, GameSystem, GameMap, GameView, 
    ParticleManager, QuadRenderer, PhysicsRenderer, CymunkPhysics, 
    PhysicsPointRenderer, QuadTreePointRenderer)

class Effects(GameSystem):
    system_id = StringProperty('effects')

class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)


class ParticleEditor(Widget):
    def __init__(self, **kwargs):
        super(ParticleEditor, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def _init_game(self, dt):
        self.setup_states()
        self.setup_particle_effects()
        self.set_state()
        Clock.schedule_interval(self.update, 1./60.)
        Clock.schedule_once(self.create_particle_effect)

    def init_game(self, dt):
        try: 
            self._init_game(0)
        except:
            print 'failed: rescheduling init'
            Clock.schedule_once(self.init_game)

    def create_particle_effect(self, dt):
        effect_string = 'assets/pexfiles/rocket_burn_effect1.pex'
        particle_system = {'particle_file': effect_string, 'offset': 0}
        particle_systems = {'effect1': particle_system}
        create_dict = {'effects': {'position': (self.size[0]/2., self.size[1]/2.), 'on_screen': True, 'angle': 0.},
        'particle_manager': particle_systems}
        component_order = ['effects', 'particle_manager']
        entity_id = self.gameworld.init_entity(create_dict, component_order)
        self.gameworld.entities[entity_id]['particle_manager']['effect1']['particle_system_on'] = True

    def update(self, dt):
        self.gameworld.update(dt) 

    def setup_particle_effects(self):
        particle_effects = [
        'assets/pexfiles/rocket_burn_effect1.pex',
        'assets/pexfiles/rocket_explosion_1.pex',
        'assets/pexfiles/rocket_burn_effect2.pex',
        'assets/pexfiles/rocket_explosion_2.pex',
        'assets/pexfiles/rocket_burn_effect3.pex',
        'assets/pexfiles/rocket_explosion_3.pex',
        'assets/pexfiles/rocket_burn_effect4.pex',
        'assets/pexfiles/rocket_explosion_4.pex',
        ]
        particle_manager = self.gameworld.systems['particle_manager']
        for effect in particle_effects:
            particle_manager.load_particle_config(effect)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', systems_added=[
            'particle_manager'], 
            systems_removed=[], 
            systems_paused=[], systems_unpaused=['particle_manager'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'



class ParticleEditorApp(App):
    def build(self):
        pass


if __name__ == '__main__':
   ParticleEditorApp().run()
    # sd_card_path = os.path.dirname('/sdcard/profiles/')
    # print sd_card_path
    # if not os.path.exists(sd_card_path):
    #     print 'making directory'
    #     os.mkdir(sd_card_path)
    # print 'path: ', sd_card_path
    # cProfile.run('KivEntApp().run()', sd_card_path + '/asteroidsprof.prof')
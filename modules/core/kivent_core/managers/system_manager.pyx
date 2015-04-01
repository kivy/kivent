cdef unsigned int DEFAULT_SYSTEM_COUNT = 8
cdef unsigned int DEFAULT_COUNT = 10000

cdef class ZoneConfig:

    def __cinit__(self, str name, unsigned int count):
        self.count = count
        self.zone_name = name
        self.systems = []


cdef class SystemConfig:

    def __cinit__(self):
        self.zone_configs = {}

    def get_config_dict(self, system_name):
        cdef ZoneConfig zone_config
        cdef dict zone_configs = self.zone_configs
        cdef return_dict = {}
        for config_name in zone_configs:
            zone_config = zone_configs[config_name]
            if system_name in zone_config.systems:
                if zone_config.zone_name not in return_dict:
                    return_dict[zone_config.zone_name] = zone_config.count
        if 'general' not in return_dict:
            return_dict['general'] = DEFAULT_COUNT
        return return_dict


    def add_system_to_zone(self, system_name, zone_name):
        cdef ZoneConfig config = self.zone_configs[zone_name]
        cdef list systems = config.systems
        assert(system_name not in systems)
        systems.append(system_name)

    def add_zone(self, zone_name, count):
        assert(zone_name not in self.zone_configs)
        self.zone_configs[zone_name] = ZoneConfig(zone_name, count)


cdef class SystemManager:

    def __getitem__(self, str name):
        return self.systems[self.get_system_index(name)]

    def __cinit__(self):
        self.systems = {}
        self.system_count = DEFAULT_SYSTEM_COUNT
        self.current_count = 0
        self.first_non_component_index = DEFAULT_SYSTEM_COUNT
        self.system_index = {}
        self.update_order = []
        self.system_config = SystemConfig()

    def add_zone(self, zone_name, count):
        self.system_config.add_zone(zone_name, count)

    cdef unsigned int get_system_index(self, str system_name):
        return self.system_index[system_name] 

    def set_system_count(self, unsigned int system_count):
        self.system_count = system_count
        self.first_non_component_index = system_count

    def get_system(self, system_name):
        return self.systems[self.get_system_index(system_name)]

    def add_system(self, system_name, system):
        if system.do_components == False:
            self.system_index[system_name] = self.first_non_component_index
            self.systems[self.first_non_component_index] = system
            self.first_non_component_index += 1
        else:
            assert(self.current_count < self.system_count)
            self.systems[self.current_count] = system
            system.system_index = self.current_count
            self.system_index[system_name] = self.current_count
            self.current_count += 1

    def get_system_config_dict(self, system_name):
        return self.system_config.get_config_dict(system_name)

    def remove_system(self, system_name):
        cdef unsigned int system_index = self.get_system_index(system_name)
        del self.systems[system_index]
        del self.system_index[system_name]
        self.current_count -= 1

    def configure_system_allocation(self, system_name):
        system = self.get_system(system_name)
        zones = system.zones
        cdef SystemConfig system_config = self.system_config 
        for zone in zones:
            system_config.add_system_to_zone(system_name, zone)


cdef SystemManager system_manager = SystemManager()

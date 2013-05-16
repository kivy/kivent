
class QuadTree(object):
    def __init__(self, gameworld, position_system, size_system, items, depth=7, bounding_rect=None):
        self.bounding_rect = bounding_rect
        self.center_x = None
        self.center_y = None
        self.nw = None
        self.se = None
        self.sw = None
        self.ne = None
        self.gameworld = gameworld
        self.position_system = position_system
        self.size_system = size_system
        

        depth -= 1
        self.depth = depth 
        if self.depth == 0:
            self.items = items
            return
 
        if bounding_rect:
            l, t, r, b = bounding_rect
        else:
            print 'no bounding_rect given'

        center_x = (l + r) * 0.5
        center_y = (t + b) * 0.5
        self.center_x = center_x
        self.center_y = center_y
        
        self.items = []
        nw_items = []
        ne_items = []
        se_items = []
        sw_items = []
        entities = gameworld.entities
        for entity_id in items:
            entity = entities[entity_id]
            pos = entity[position_system]['position']
            size = entity[size_system]['size']
            left = pos[0] - size[0]
            top = pos[1] + size[1]
            right = pos[0] + size[0]
            bottom = pos[1] - size[1]
            in_nw = left <= center_x and top >= center_y
            in_sw = left <= center_x and bottom <= center_y
            in_ne = right >= center_x and top >= center_y
            in_se = right >= center_x and bottom <= center_y
            if in_nw and in_ne and in_se and in_sw:
                self.items.append(entity_id)
            else:
                if in_nw: nw_items.append(entity_id)
                if in_ne: ne_items.append(entity_id)
                if in_se: se_items.append(entity_id)
                if in_sw: sw_items.append(entity_id)
            
        self.nw = QuadTree(gameworld, position_system, size_system, nw_items, depth, (l, t, center_x, center_y))
        self.ne = QuadTree(gameworld, position_system, size_system, ne_items, depth, (center_x, t, r, center_y))
        self.se = QuadTree(gameworld, position_system, size_system, se_items, depth, (center_x, center_y, r, b))
        self.sw = QuadTree(gameworld, position_system, size_system, sw_items, depth, (l, center_y, center_x, b))

    def add_items(self, list_of_items, depth):
        depth -= 1
        if depth == 0:
            for item in list_of_items:
                self.items.append(item)
            return
        
        nw_items = []
        ne_items = []
        se_items = []
        sw_items = []
        l, t, r, b = self.bounding_rect
        center_x = self.center_x
        center_y = self.center_y

        entities = self.gameworld.entities
        position_system = self.position_system
        size_system = self.size_system

        for entity_id in list_of_items:
            entity = entities[entity_id]
            pos = entity[position_system]['position']
            size = entity[size_system]['size']
            left = pos[0] - size[0]
            top = pos[1] + size[1]
            right = pos[0] + size[0]
            bottom = pos[1] - size[1]
            in_nw = left <= center_x and top >= center_y
            in_sw = left <= center_x and bottom <= center_y
            in_ne = right >= center_x and top >= center_y
            in_se = right >= center_x and bottom <= center_y
            if in_nw and in_ne and in_se and in_sw:
                self.items.append(entity_id)
            else:
                if in_nw: nw_items.append(entity_id)
                if in_ne: ne_items.append(entity_id)
                if in_se: se_items.append(entity_id)
                if in_sw: sw_items.append(entity_id)
        
        if nw_items:
            self.nw.add_items(nw_items, depth)
        if ne_items:
            self.ne.add_items(ne_items, depth)
        if se_items:
            self.se.add_items(se_items, depth)
        if sw_items:
            self.sw.add_items(sw_items, depth)

    def update_quads(self):
        items_to_add = self.check_items()
        self.add_items(items_to_add, self.depth)


    def check_items(self):
        sw = self.sw
        nw = self.nw
        se = self.se
        ne = self.ne
        l, t, r, b = self.bounding_rect
        position_system = self.position_system
        size_system = self.size_system
        entities = self.gameworld.entities

        def is_in_bounding_box(entity_id):
            entity = entities[entity_id]
            pos = entity[position_system]['position']
            size = entity[size_system]['size']
            item_left = pos[0] - size[0]
            item_top = pos[1] + size[1]
            item_right = pos[0] + size[0]
            item_bottom = pos[1] - size[1]

            return item_left >= l and item_right <= r and item_top <= t and item_bottom >= b 

        items_to_re_add = set(item for item in self.items if not is_in_bounding_box(item))
        for item in items_to_re_add:
            self.items.remove(item)
        if nw:
            items_to_re_add |= nw.check_items()
        if sw:
            items_to_re_add |= sw.check_items()
        if ne:
            items_to_re_add |= ne.check_items()
        if se:
            items_to_re_add |= se.check_items()
        
        return items_to_re_add


    def bb_hit(self, right, left, top, bottom):
        test_r = right
        test_l = left
        test_t = top
        test_b = bottom
        position_system = self.position_system
        size_system = self.size_system
        entities = self.gameworld.entities


        def overlaps(entity_id):
            entity = entities[entity_id]
            pos = entity[position_system]['position']
            size = entity[size_system]['size']
            item_left = pos[0] - size[0]
            item_top = pos[1] + size[1]
            item_right = pos[0] + size[0]
            item_bottom = pos[1] - size[1]
            return test_r >= item_left and test_l <= item_right and \
                   test_b <= item_top and test_t >= item_bottom
        
        hits = set(item for item in self.items if overlaps(item))

        center_x = self.center_x
        center_y = self.center_y
        nw = self.nw
        sw = self.sw
        ne = self.ne
        se = self.se
        if nw and test_l <= center_x and test_t >= center_y:
            hits |= nw.bb_hit(right, left, top, bottom)
        if sw and test_l <= center_x and test_b <= center_y:
            hits |= sw.bb_hit(right, left, top, bottom)
        if ne and test_r >= center_x and test_t >= center_y:
            hits |= ne.bb_hit(right, left, top, bottom)
        if se and test_r >= center_x and test_b <= center_y:
            hits |= se.bb_hit(right, left, top, bottom)
        return hits



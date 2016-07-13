import tmx
from os.path import basename, dirname

from kivent_core.systems.renderers import Renderer
from kivent_core.systems.animation import AnimationSystem


def load_map_systems(layers, gameworld, renderargs, animargs):
    rendersystems = ['map_layer%d' % i for i in range(layers)]
    animsystems = ['map_layer%d_animator' % i for i in range(layers)]
    system_count = gameworld.system_count

    for i in range(layers):
        renderargs['system_id'] = rendersystems[i]
        renderargs['system_names'] = [rendersystems[i], 'position']
        animargs['system_id'] = animsystems[i]
        animargs['system_names'] = [animsystems[i],rendersystems[i]]
        r = Renderer()
        a = AnimationSystem()
        r.gameworld = gameworld
        a.gameworld = gameworld
        for k in renderargs:
            setattr(r,k,renderargs[k])
        for k in animargs:
            setattr(a,k,animargs[k])
        gameworld.add_widget(r, system_count)
        gameworld.add_widget(a, system_count)
        system_count += 2

    for c in gameworld.children:
        if c:
            print(c.system_id)

    gameworld.system_count = system_count

    return rendersystems, animsystems


def init_entities_from_map(tile_map, init_entity):
    for j in range(tile_map.size[0]):
        for i in range(tile_map.size[1]):
            tile_layers = tile_map.get_tile(j,i)
            for tile in tile_layers.layers:
                renderer_name = 'map_layer%d' % tile.layer
                animator_name = 'map_layer%d_animator' % tile.layer
                comp_data = {
                    'position': _get_position(i, j, tile_map),
                    'tile_map': {'name': tile_map.name, 'pos': (i,j)},
                    renderer_name: {
                        'model': tile.model,
                        'texture': tile.texture
                        }
                    }
                systems = ['position', 'tile_map', renderer_name]
                if tile.animation:
                    comp_data[animator_name] = {
                        'name': tile.animation,
                        'loop': True,
                            }
                    systems.append(animator_name)

                init_entity(comp_data, systems)


def _get_position(i, j, tile_map):
    w, h = tile_map.size_on_screen
    tw, th = tile_map.tile_size

    if tile_map.orientation == 'orthogonal':
        x, y = (i * tw + tw/2, h - j * th - th/2)
    elif tile_map.orientation in ('staggered', 'hexagonal'):
        ts = 0
        if tile_map.orientation == 'hexagonal':
            ts = tile_map.hex_side_length

        if tile_map.stagger_axis == 'x':
            y = h - (j * th + th/2)
            x = (i * (tw + ts))/2 + tw/2

            if (tile_map.stagger_index == 'even') != ((i+1)%2 == 0):
                y -= th/2
        elif tile_map.stagger_axis == 'y':
            y = h - ((j * (th + ts))/2 + th/2)
            x = i * tw + tw/2

            if (tile_map.stagger_index == 'even') != ((j+1)%2 == 0):
                x += tw/2
    elif tile_map.orientation == 'isometric':
        x, y = ((i - j) * tw/2,
                (i + j) * th/2)

        x += w/2
        y = h - th/2 - y

    return (x,y)


def parse_tmx(filename, gameworld):
    texture_manager = gameworld.managers['texture_manager']
    model_manager = gameworld.managers['model_manager']
    map_manager = gameworld.managers['map_manager']
    animation_manager = gameworld.managers['animation_manager']

    tilemap = tmx.TileMap.load(filename)

    tiles, tile_ids = _load_tile_map(tilemap.layers, tilemap.width,
                                     _load_tile_properties(tilemap.tilesets))
    _load_tilesets(tilemap.tilesets, dirname(filename), tile_ids,
                   texture_manager.load_atlas,
                   model_manager.load_textured_rectangle,
                   animation_manager.load_animation)

    name ='.'.join(basename(filename).split('.')[:-1])
    map_manager.load_map(name, tilemap.width, tilemap.height,
                         tiles, len(tilemap.layers))

    loaded_map = map_manager.maps[name]
    loaded_map.tile_size = (tilemap.tilewidth, tilemap.tileheight)
    loaded_map.orientation = tilemap.orientation
    if hasattr(tilemap, 'staggerindex'):
        loaded_map.stagger_index = tilemap.staggerindex
    if hasattr(tilemap, 'staggeraxis'):
        loaded_map.stagger_axis = tilemap.staggeraxis
    if hasattr(tilemap, 'hexsidelength'):
        loaded_map.hex_side_length = tilemap.hexsidelength

    return name


def _load_tilesets(tilesets, dirname, tile_ids,
                   load_atlas, load_model, load_animation):
    atlas_data = {}
    model_data = {}
    animation_data = {}
    for tileset in tilesets:
        image = tileset.image
        name = image.source
        fgid = int(tileset.firstgid)
        w, h = int(image.width), int(image.height)
        tw, th = int(tileset.tilewidth), int(tileset.tileheight)
        m, s = int(tileset.margin), int(tileset.spacing)

        rows = (w + s)//(tw + 2*m + s)
        cols = (h + s)//(th + 2*m + s)

        for tile in tileset.tiles:
            if tile.animation:
                animation = []
                for frame in tile.animation:
                    animation.append({
                        'texture': 'tile_%d' % (frame.tileid + fgid),
                        'model': 'tile_%d' % (frame.tileid + fgid),
                        'duration': frame.duration
                    })
                    tile_ids.add(frame.tileid + fgid)
                animation_name = 'animation_tile_%d' % (tile.id + fgid)
                animation_data[animation_name] = animation

        atlas_data[name] = {}
        for tile in range(rows*cols):
            if (tile + fgid) in tile_ids:
                x, y = tile % rows, cols - 1 - int(tile / rows)
                px, py = x * (tw + 2*m + s) + m, y * (th + 2*m + s) + m
                atlas_data[name]['tile_%d' % (tile + fgid)] = (px, py, tw, th)
                model_data['tile_%d' % (tile + fgid)] = (tw, th)

    load_atlas(atlas_data, 'dict', dirname)
    for model in model_data:
        tw, th = model_data[model]
        load_model('vertex_format_4f', tw, th, model, model)
    for animation in animation_data:
        frames = animation_data[animation]
        load_animation(animation, len(frames), frames)


def _load_tile_map(layers, width, tile_properties):
    height = int(len(layers[0].tiles)/width)
    tiles = [[[] for j in range(width)] for i in range(height)]
    tile_ids = set()

    for i, layer in enumerate(layers):
        for n, tile in enumerate(layer.tiles):
            if tile.gid > 0:
                tile_ids.add(tile.gid)
                if tile.gid in tile_properties:
                    tile = tile_properties[tile.gid]
                else:
                    tile = {'texture': 'tile_%d' % tile.gid,
                            'model': 'tile_%d' % tile.gid}
                tile['layer'] = i

                tiles[int(n/width)][n%width].append(tile)

    return tiles, tile_ids

def _load_tile_properties(tilesets):
    tile_properties = {}
    for tileset in tilesets:
        for tile in tileset.tiles:
            if tile.animation:
                gid = tile.id + tileset.firstgid
                tile_properties[gid] = {
                        'animation':
                            'animation_tile_%d' % gid
                    }

    return tile_properties

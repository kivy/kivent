# cython: embedsignature=True
from gamesystem cimport GameSystem
from kivy.properties import (StringProperty, ListProperty,
    NumericProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from kivy.vector import Vector
from kivent_core.managers.system_manager cimport SystemManager
from kivy.graphics.transformation cimport Matrix
from kivy.graphics import RenderContext
from kivy.factory import Factory
from kivy.input import MotionEvent
from libc.math cimport sin, cos


cdef class GameView(GameSystem):
    '''
    GameView provides a simple camera system that will control the rendering
    view of any other **GameSystem** that has had the **gameview** property set
    **GameSystem** that have a **gameview** will be added to the GameView
    canvas instead of the GameWorld canvas.

    **Attributes:**
        **do_scroll_lock** (BooleanProperty): If True the scrolling will be
        locked to the bounds of the GameWorld's currentmap.

        **camera_pos** (ListProperty): Current position of the camera

        **camera_scale** (NumericProperty): Current scale of the camera. The
        scale is equal to the amount of the game world that will be shown
        compared to the physical size of the GameView, therefore 2x will show
        twice as much of your gameworld, appearing 'zoomed out', while .5 will
        show half as much of the gameworld, appearing 'zoomed in'.

        **camera_rotate** (NumericProperty): Current angle in radians by which the
        camera is rotated clockwise with respect to the world x-axis.
        Every time this value is updated, the rotation takes place about the
        center of the screen.

        **focus_entity** (BooleanProperty): If True the camera will follow the
        entity set in entity_to_focus

        **do_scroll** (BooleanProperty): If True touches will scroll the camera

        **entity_to_focus** (NumericProperty): Entity entity_id for the camera
        to focus on if focus_entity is True.

        **camera_speed_multiplier** (NumericProperty): Time it will take camera
        to reach focused entity, Speed will be 1.0/camera_speed_multiplier
        seconds to close the distance

        **render_system_order** (ListProperty): List of **system_id** in the
        desired order of rendering last to first. **GameSystem** with
        **system_id** not in **render_system_order** will be inserted at
        position 0.

        **move_speed_multiplier** (NumericProperty): Multiplier to further
        control the speed of touch dragging of camera. Example Usage:
        Bind to the size of your gameview divided by the size of the window
        to ensure that apparent dragging speed stays consistent.

        **do_touch_zoom** (BooleanProperty): If True the camera will zoom with
        2 finger touch interaction.

        **scale_min** (NumericProperty): The minimum scale factor that will be
        allowed when touch zoom is being used. This will be the most 'zoomed
        in' your camera will be allowed to go. This limit do not apply
        when manually manipulated **camera_scale**.

        **scale_max** (NumericProperty): The maximum scale factor that will be
        allowed when touch zoom is being used. This will be the most 'zoomed
        out' your camera will be allowed to go. This limit do not apply
        when manually manipulated **camera_scale**.

    '''
    system_id = StringProperty('default_gameview')
    do_scroll_lock = BooleanProperty(True)
    camera_pos = ListProperty((0, 0))
    camera_scale = NumericProperty(1.0)
    camera_rotate = NumericProperty(0)
    focus_entity = BooleanProperty(False)
    do_touch_zoom = BooleanProperty(False)
    do_scroll = BooleanProperty(True)
    allow_scroll_y = BooleanProperty(True)
    allow_scroll_x = BooleanProperty(True)
    entity_to_focus = NumericProperty(None, allownone=True)
    updateable = BooleanProperty(True)
    scale_min = NumericProperty(.5)
    scale_max = NumericProperty(8.)
    camera_speed_multiplier = NumericProperty(1.0)
    render_system_order = ListProperty([])
    move_speed_multiplier = NumericProperty(1.0)
    do_components = BooleanProperty(False)
    currentmap = ObjectProperty(None)
    window_size = ListProperty((100., 100.))
    touch_pass_through = BooleanProperty(False)


    def __init__(self, **kwargs):
        super(GameView, self).__init__(**kwargs)
        self.matrix = Matrix()
        self._touch_count = 0
        self._touches = []
        self.canvas = RenderContext()

    def _rotate_point(self, point, angle):
        cos_r, sin_r = cos(angle), sin(angle)
        return (cos_r * point[0] + sin_r * point[1],
                -sin_r * point[0] + cos_r * point[1])

    def convert_to_rotated_space(self, point, invert=False):
        '''
        Convert a point from normal to rotated space and back using
        the invert parameter
        '''
        camera_pos = self.camera_pos
        camera_size = self.size
        camera_scale = self.camera_scale
        camera_rotate = self.camera_rotate

        screen_center = (camera_size[0] * camera_scale * 0.5 - camera_pos[0],
                         camera_size[1] * camera_scale * 0.5 - camera_pos[1])
        screen_center_rotated = self._rotate_point(screen_center, -camera_rotate)

        # Translate to screen center
        tr_sc = Matrix().translate(screen_center[0], screen_center[1], 0)
        # Rotate around screen center
        rot_sc = Matrix().rotate(camera_rotate, 0, 0, 1)
        # Translate back to origi Translate back to origin
        tr_or = Matrix().translate(-screen_center_rotated[0],
                                   -screen_center_rotated[1],
                                   0)

        m = tr_or.multiply(rot_sc.multiply(tr_sc))

        if invert:
            m = m.inverse()

        p = (point[0] * m[0] + point[1] * m[4] + m[12],
             point[0] * m[1] + point[1] * m[5] + m[13])
        return p



    def get_camera_centered(self, map_size, camera_size, camera_scale):
        x = max((camera_size[0]*camera_scale - map_size[0])/2., 0.)
        y = max((camera_size[1]*camera_scale - map_size[1])/2., 0.)
        return (x, y)

    def update_render_state(self):
        '''
        Used internally by gameview to update the projection matrix to properly
        reflect the settings for camera_size, camera_pos, and the pos and size
        of gameview.'''

        # Camera left-bottom pos
        px, py = self.camera_pos

        camera_scale = self.camera_scale
        size = self.window_size
        # Camera size
        sx, sy = size[0] * camera_scale/2, size[1] * camera_scale/2

        # Camera center
        cx = -px + sx
        cy = -py + sy

        tm = Matrix().translate(-cx, -cy, 0) # Bring frame to origin
        rm = Matrix().rotate(self.camera_rotate, 0, 0, 1) # Rotate around z
        proj = rm.multiply(tm)
        proj = Matrix().view_clip(-sx, sx, -sy, sy, 0., 100, 0).multiply(proj)

        self.canvas['projection_mat'] = proj

    def add_widget(self, widget):
        gameworld = self.gameworld
        cdef str system_id
        cdef SystemManager system_manager = gameworld.system_manager
        if isinstance(widget, GameSystem):
            widget.on_add_system()
            render_system_order = self.render_system_order
            system_id = widget.system_id
            if system_id in render_system_order:
                index=render_system_order.index(system_id)
            else:
                index=0
            super(GameView, self).add_widget(widget, index=index)
            system_index = system_manager.system_index
            if widget.system_id not in system_index:
                Clock.schedule_once(lambda dt: gameworld.add_system(widget))
        else:
            super(GameView, self).add_widget(widget)


    def remove_widget(self, widget):
        if isinstance(widget, GameSystem):
            widget.on_remove_system()
        super(GameView, self).remove_widget(widget)


    def on_entity_to_focus(self, instance, value):
        if value ==  None:
            self.focus_entity = False
        else:
            self.focus_entity = True

    def update(self, dt):
        cdef int entity_to_focus
        cdef float dist_x
        cdef float dist_y
        cdef object entity
        cdef float camera_speed_multiplier
        gameworld = self.gameworld
        if self.focus_entity \
            and not (self.do_touch_zoom and self._touch_count > 1): #'pause' focus on entity while scaling with touch
            entity_to_focus = self.entity_to_focus
            entity = gameworld.entities[entity_to_focus]
            position_data = entity.position
            camera_pos = self.camera_pos
            camera_speed_multiplier = self.camera_speed_multiplier
            camera_size = self.size
            camera_scale = self.camera_scale
            size = camera_size[0] * camera_scale, camera_size[1] * camera_scale

            screen_center = (size[0]*0.5, size[1]*0.5)
            # screen_center = self._rotate_point(screen_center, -self.camera_rotate)

            dist_x = -camera_pos[0] - position_data.x + screen_center[0]
            dist_y = -camera_pos[1] - position_data.y + screen_center[1]

            if self.do_scroll_lock:
               dist_x, dist_y = self.lock_scroll(dist_x, dist_y)

            # dist_x, dist_y = self.convert_to_rotated_space((dist_x, dist_y))
            self.camera_pos[0] += dist_x*camera_speed_multiplier*dt
            self.camera_pos[1] += dist_y*camera_speed_multiplier*dt
        self.update_render_state()

    def on_size(self, instance, value):
        if self.do_scroll_lock and self.currentmap:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y
        self.update_render_state()

    def collide_point(self, x, y):
        w, h = self.window_size
        px, py = self.pos
        return px <= x <= px + w and py <= y <= py + h

    def on_touch_down(self, touch):
        cx, cy = self.convert_from_screen_to_world(touch.pos)
        old_x, old_y = touch.x, touch.y
        touch.x = cx
        touch.y = cy
        touch.pos = (cx, cy)
        super_result = super(GameView, self).on_touch_down(touch)
        touch.x = old_x 
        touch.y = old_y
        touch.pos = (old_x, old_y)
        if self.collide_point(*touch.pos) and not self.touch_pass_through and not super_result:
            touch.grab(self)
            self._touch_count += 1
            self._touches.append(touch)
            camera_pos = self.camera_pos
            size = self.size
            touch.ud['world_pos'] = self.get_camera_center()
            touch.ud['start_pos'] = touch.pos
            touch.ud['start_scale'] = self.camera_scale
            return True
        else:
            return False

    def on_touch_up(self, touch):
        converted_pos = self.convert_from_screen_to_world(touch.pos)
        old_x, old_y = touch.x, touch.y
        touch.x = converted_pos[0]
        touch.y = converted_pos[1]
        super_result = super(GameView, self).on_touch_up(touch)
        touch.x = old_x
        touch.y = old_y
        if touch.grab_current is self:
            self._touch_count -= 1
            self._touches.remove(touch)
            return True
        else:
            return False

    def get_camera_center(self):
        '''Returns the current center point of the cameras view'''
        cx, cy = self.camera_pos
        size = self.size
        camera_scale = self.camera_scale
        sw, sh = size[0] * camera_scale *.5, size[1] * camera_scale * .5
        return sw - cx, sh - cy

    def convert_from_screen_to_world(self, pos):
        '''Converts the coordinates of pos from screen space to camera space'''
        px, py = self.camera_pos
        proj = self.canvas['projection_mat']
        model = self.canvas['modelview_mat']
        #get the inverse of the current camera
        m = Matrix().multiply(proj).multiply(model)
        inverse = m.inverse()
        size = self.window_size
        # normalize pos in window
        nX = (pos[0])/(size[0])*2.0 - 1.0
        nY = (pos[1])/(size[1])*2.0 - 1.0

        p = inverse.transform_point(nX, nY, 0)
        return p[0], p[1]

    def look_at(self, pos):
        '''Set the camera to be focused at pos.'''
        camera_size = self.size
        camera_scale = self.camera_scale
        self.camera_pos[0] = -pos[0] + camera_size[0]*.5*camera_scale
        self.camera_pos[1] = -pos[1] + camera_size[1]*.5*camera_scale


    def on_touch_move(self, touch):
        converted_pos = self.convert_from_screen_to_world(touch.pos)
        old_x, old_y = touch.x, touch.y
        touch.x = converted_pos[0]
        touch.y = converted_pos[1]
        super_result = super(GameView, self).on_touch_move(touch)
        touch.x = old_x
        touch.y = old_y
        if touch.grab_current is self:
            move_speed_multiplier = self.move_speed_multiplier
            if self.do_touch_zoom and self._touch_count > 1:
                    points = [Vector(t.x, t.y) for t in self._touches]
                    anchor = max(
                        points[:], key=lambda p: p.distance(touch.pos))
                    an_index = points.index(anchor)
                    anchor_touch = self._touches[an_index]
                    farthest = max(points, key=anchor.distance)
                    if farthest is not points[-1]:
                        return
                    old_line = Vector(*touch.ud['start_pos']) - anchor
                    new_line = Vector(*touch.pos) - anchor
                    if not old_line.length() or not new_line.length():   # div by zero
                        return
                    new_scale = (old_line.length() / new_line.length()) * (
                        touch.ud['start_scale'])
                    if new_scale > self.scale_max:
                        self.camera_scale = self.scale_max
                    elif new_scale < self.scale_min:
                        self.camera_scale = self.scale_min
                    else:
                        self.camera_scale = new_scale
                    self.look_at(anchor_touch.ud['world_pos'])
                    return True

            if not self.focus_entity and self.do_scroll:
                if self._touch_count == 1:
                    camera_scale = self.camera_scale
                    dist_x = touch.dx * camera_scale * move_speed_multiplier
                    dist_y = touch.dy * camera_scale * move_speed_multiplier

                    if self.do_scroll_lock and self.currentmap:
                        dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
                    if self.allow_scroll_x:
                        self.camera_pos[0] += dist_x
                    if self.allow_scroll_y:
                        self.camera_pos[1] += dist_y

    def lock_scroll(self, float distance_x, float distance_y):
        currentmap = self.currentmap
        camera_size = self.size
        pos = self.pos
        scale = self.camera_scale
        map_size = currentmap.map_size
        window_size = self.window_size
        margins = currentmap.margins
        camera_pos = self.camera_pos
        cdef float xr = window_size[0] / camera_size[0]
        cdef float xy = window_size[1] / camera_size[1]
        cdef float x= pos[0] * scale
        cdef float y = pos[1] * scale
        cdef float mw = map_size[0]
        cdef float mh = map_size[1]
        cdef float marg_x = margins[0]
        cdef float marg_y = margins[1]
        cdef float cx = camera_pos[0]
        cdef float cy = camera_pos[1]
        cdef float cw = camera_size[0] * scale
        cdef float ch = camera_size[1] * scale
        cdef float camera_right = cx + cw
        cdef float camera_top = cy + ch
        cdef float sw = cw * xr
        cdef float sh = ch * xy
        if mw < sw:
            if cx + distance_x < x:
                distance_x = x - cx
            elif cx + distance_x + mw > x + sw:
                distance_x = x + sw - cx - mw
        else:
            if cx + distance_x > x + marg_x:
                distance_x = x - cx + marg_x
            elif cx + mw + distance_x <= x + sw - marg_x:
                distance_x = x + sw - marg_x - cx - mw

        #desired y position is
        if mh < sh:
            distance_y = ch/2 - (cy + mh/2)
        else:
             if cy + distance_y > y + marg_y:
                 distance_y = y - cy + marg_y 
             elif cy + mh + distance_y <= y + sh - marg_y:
                 distance_y = y + sh - cy - mh  - marg_y

        return distance_x, distance_y


Factory.register('GameView', cls=GameView)

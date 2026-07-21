
-- Buttons
button = {
    touch = {},
    list = {},
}
function button.new(self, id, sx, sy, ex, ey, txt, idle, tap, hold, act_i, act_t, act_h)
    self.list[id or (#self.list + 1)] = {
        sx = sx,
        sy = sy,
        ex = ex,
        ey = ey,
        txt = txt,
        idle = idle, -- texture-idle
        tap = tap, -- texture-tap
        hold = hold, -- texture-hold
        act_i = act_i, -- add params for 3 acts, fix and cooldowns
        act_h = act_h,
        act_t = act_t,
        width = ex - sx,
        height = ey - sy
        }
    end
function button.set_touch(self, id, x, y)
    for i, button in pairs(self.list) do
        if button.sx < x and button.sy < y and button.ex > x and button.ey > y then
            self.touch[id] = button.id
            button:act_t() --add params, fix
            return
        end
    end
end




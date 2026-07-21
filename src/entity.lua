-- ==================== Entity system ======================
entity = {
    spawn_rate = 1,
    rolls = 2,
    max = 20,
    types = {
        name = {},
        index = {}
    },
    spawned = {},
    max = 25
}
function entity.new(self, data)
    local e = data
    e.color = colors[e.color]
    
    self.types.name[name] = e
    self.types.index[#self.types.index + 1] = e
end
function entity.spawn(self, dt)
    if math.random(1, 10000) > (self.spawn_rate * 100 * 60 * dt) or #self.spawned >= self.max then return end
    local type = nil
    local x, y = math.random(1, pa.w), math.random(1, pa.h)
    -- entity
end






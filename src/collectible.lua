-- ==================== Collectibles and items system ======================
collectible = {
    spawn_rate = 0.676767,
    rolls = 2,
    types = {
        name = {},
        index = {}
    },
    spawned = {},
    occupied = {},
    max = 30
}
function collectible.new(self, data_or_name, texture, color, size, chance, inv_slot, value, mults)
    local c = data_or_name
    if type(c) == "string" then
        c = {
            name = c,
            chance = chance, 
            inv_slot = inv_slot,
            value = value,
            mults = mults,
            texture = texture,
            size = size,
            color = color
        }
    end
    c.color = colors[c.color]
    
    self.types.name[c.name] = c
    self.types.index[#self.types.index + 1] = c
end
function collectible.spawn(self, dt)
    if math.random(1, 100 * rng_offset) > (self.spawn_rate * rng_offset * 60 * dt) or #self.spawned >= self.max then return end
    local type = nil
    local x, y = math.random(1, grid.w), math.random(1, grid.h)
    if self.occupied[x] and self.occupied[x][y] then return end
    
    local mult = {
        tb = 1,
        lr = 1,
        d = 1
    }
    if x == 1 or x == grid.w then mult.tb = 10 end
    if y == 1 or y == grid.h then mult.lr = 10 end
    mult.d = 10^(( 100 * math.sqrt( math.abs(player.x - x)^2 + math.abs(player.y - y)^2 ) / grid.s - spawn_boost) / 10)
    -- add the collectibles
    local mul = 1
    for i = 1, self.rolls do
        local no = math.random(1, #self.types.index)
        local coll = self.types.index[no]
        for m = 1, #(coll.mults) do
            mul = mul * mult[coll.mults[m]]
        end
        if math.random(1, 100 * rng_offset) <= coll.chance * rng_offset * mul then
            self.spawned[#self.spawned + 1] = {
                name = coll.name,
                x = x * cell_size,
                y = y * cell_size
            }
            self.occupied[x] = self.occupied[x] or {}
            self.occupied[x][y] = true
            return
        end
    end
    --return tostring(mult.d), ""
end

function collectible.collect(self)
    for i = #self.spawned, 1, -1 do
        c = self.spawned[i]
        cdata = self.types.name[c.name]
        if math.sqrt((player.x - c.x)^2 + (player.y - c.y)^2) <= (player.rad + self.types.name[c.name].size) then
            player.inventory[cdata.inv_slot] = (player.inventory[cdata.inv_slot] or 0) + cdata.value
            table.remove(self.spawned, i)
            
            self.occupied[c.x] = self.occupied[c.x] or {}
            self.occupied[c.x][c.y] = false
        end
    end
end

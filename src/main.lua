

-- ==================== Game settings ====================
local GRID_H, GRID_W = math.floor(love.graphics.getHeight() / 20) - , math.floor(love.graphics.getWidth() / 20)
local CELL_SIZE = 20          -- pixels per cell
local PLAY_AREA_W = GRID_W * CELL_SIZE
local PLAY_AREA_H = GRID_H * CELL_SIZE

-- ==================== Colours ==========================
local colours = {
    grass   = {0.2, 0.8, 0.2},
    border  = {0.8, 0.2, 0.2},
    player  = {0.2, 0.4, 0.8},
    diamond = {0.2, 0.8, 0.8},   -- cyan
    pearl   = {0.9, 0.9, 0.9},   -- white
    amethyst= {0.8, 0.2, 0.8},   -- magenta
    gold    = {0.9, 0.9, 0.2},   -- yellow
}

-- ==================== Player ===========================
local player = {
    x = PLAY_AREA_W / 2,
    y = PLAY_AREA_H / 2,
    rad = CELL_SIZE * 0.7,
    speed = 250,        -- pixels per second
    minspeed = 50,      -- not used here, kept for compatibility
}

-- ==================== Joystick =========================
local joystick = {}
joystick.base_x = love.graphics.getWidth() * 150 / 841
joystick.base_y = love.graphics.getHeight() * (387 - 150) / 387   -- will be set after window created
joystick.radius = 60
joystick.dead_zone = player.minspeed / player.speed   -- ~0.25
joystick.knob_x = joystick.base_x
joystick.knob_y = joystick.base_y
joystick.x = 0
joystick.y = 0
joystick.touch_id = nil

local function update_joystick(touch_x, touch_y)
    local dx = touch_x - joystick.base_x
    local dy = touch_y - joystick.base_y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist > joystick.radius then
        dx = dx / dist * joystick.radius
        dy = dy / dist * joystick.radius
        dist = joystick.radius
    end

    joystick.knob_x = joystick.base_x + dx
    joystick.knob_y = joystick.base_y + dy

    local norm = dist / joystick.radius
    if norm < joystick.dead_zone then
        joystick.x, joystick.y = 0, 0
    else
        joystick.x = dx / joystick.radius
        joystick.y = dy / joystick.radius
    end
end

-- ==================== Coin system ======================
local MAX_COINS = 20
local coins = {}   -- list of {x, y, value, colour, cell_x, cell_y}
local coin_count = 0

-- To avoid spawning on occupied cell
local occupied = {}   -- [cell_x][cell_y] = true

local coin_types = {
    {value = 1500, colour = colours.diamond},
    {value = 400,  colour = colours.pearl},
    {value = 90,  colour = colours.amethyst},
    {value = 10,   colour = colours.gold},
}

-- Spawn one coin (adapted from original logic)
local function spawn_coin()
    if coin_count >= MAX_COINS then return end
    -- chance: 1000 out of 10000 (like original)
    if love.math.random(10000) > 9000 then return end

    local cx = love.math.random(1, GRID_W)
    local cy = love.math.random(1, GRID_H)

    -- Already occupied?
    if occupied[cx] and occupied[cx][cy] then return end

    -- Distance from player (in cells, Manhattan)
    local player_cx = math.floor(player.x / CELL_SIZE) + 1
    local player_cy = math.floor(player.y / CELL_SIZE) + 1
    local diff = math.abs(player_cx - cx) + math.abs(player_cy - cy)

    -- Multiplier from original
    local mult = 1
    if cx == 1 or cx == GRID_W then mult = mult * 10 end
    if cy == 1 or cy == GRID_H then mult = mult * 10 end
    if     diff >= 90 then mult = mult * (diff/16)
    elseif diff >= 65 then mult = mult * 8
    elseif diff >= 50 then mult = mult * 0.8
    elseif diff >= 20 then mult = mult * 0.01
    elseif diff >= 10 then mult = mult * 0.001
    else mult = mult * 0.0001 end

    -- Pick coin type (same thresholds)
    local pick = love.math.random(10000)
    local diamond_thresh = 9 * mult
    local pearl_thresh   = 90 * mult
    local amethyst_thresh = 900 * mult
    local gold_thresh    = 9000 * mult

    local typ
    if pick <= diamond_thresh then
        typ = 1
    elseif pick <= pearl_thresh then
        typ = 2
    elseif pick <= amethyst_thresh then
        typ = 3
    elseif pick <= gold_thresh then
        typ = 4
    else
        return   -- no coin spawned
    end

    -- Create coin
    local coin = {
        cell_x = cx,
        cell_y = cy,
        x = (cx - 1) * CELL_SIZE + CELL_SIZE/2,
        y = (cy - 1) * CELL_SIZE + CELL_SIZE/2,
        value = coin_types[typ].value,
        colour = coin_types[typ].colour,
        rad = CELL_SIZE * 0.35,
    }
    coins[#coins+1] = coin
    coin_count = coin_count + 1

    -- Mark cell as occupied
    if not occupied[cx] then occupied[cx] = {} end
    occupied[cx][cy] = true
end

-- Collect coin if player overlaps it
local function check_collection()
    for i = #coins, 1, -1 do
        local c = coins[i]
        local dx = player.x - c.x
        local dy = player.y - c.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < player.rad + c.rad then
            -- Collect
            player.score = player.score + c.value
            if player.score > player.high_score then
                player.high_score = player.score
            end
            -- Free up cell
            if occupied[c.cell_x] then occupied[c.cell_x][c.cell_y] = nil end
            table.remove(coins, i)
            coin_count = coin_count - 1
        end
    end
end

-- Remove all coins (when restarting)
local function clear_coins()
    coins = {}
    occupied = {}
    coin_count = 0
end

-- ==================== Scoring & Save ===================
player.score = 0
player.high_score = 0
player.last_score = 0

-- Save to a simple file
local function save_game()
    local data = {
        score = player.score,
        high = player.high_score,
        last = player.last_score,
        coins = {},   -- store {cell_x, cell_y, type_index}
        seed = love.math.getRandomSeed(),
    }
    for _, c in ipairs(coins) do
        -- find type index from value
        local typ = 1
        for j, ct in ipairs(coin_types) do
            if ct.value == c.value then typ = j; break end
        end
        data.coins[#data.coins+1] = {c.cell_x, c.cell_y, typ}
    end
    love.filesystem.write("save.lua", table.serialize(data))
end

local function load_game()
    if not love.filesystem.getInfo("save.lua") then return false end
    local content = love.filesystem.read("save.lua")
    local ok, data = pcall(load("return " .. content))
    if not ok or not data then return false end
    -- Restore state
    player.score = data.score or 0
    player.high_score = data.high or 0
    player.last_score = data.last or 0
    clear_coins()
    if data.coins then
        for _, arr in ipairs(data.coins) do
            local cx, cy, typ = arr[1], arr[2], arr[3]
            local ct = coin_types[typ] or coin_types[1]
            local coin = {
                cell_x = cx,
                cell_y = cy,
                x = (cx-1)*CELL_SIZE + CELL_SIZE/2,
                y = (cy-1)*CELL_SIZE + CELL_SIZE/2,
                value = ct.value,
                colour = ct.colour,
                rad = CELL_SIZE * 0.35,
            }
            coins[#coins+1] = coin
            coin_count = coin_count + 1
            if not occupied[cx] then occupied[cx] = {} end
            occupied[cx][cy] = true
        end
    end
    if data.seed then love.math.setRandomSeed(data.seed) end
    return true
end

-- ==================== Keyboard simulation ==============
-- Map arrow keys / WASD to joystick x,y values
local function keyboard_input()
    local x, y = 0, 0
    if love.keyboard.isDown("left")  or love.keyboard.isDown("a") then x = x - 1 end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then x = x + 1 end
    if love.keyboard.isDown("up")    or love.keyboard.isDown("w") then y = y - 1 end
    if love.keyboard.isDown("down")  or love.keyboard.isDown("s") then y = y + 1 end
    -- Normalize to length <= 1
    local len = math.sqrt(x*x + y*y)
    if len > 0 then
        x, y = x/len, y/len
    end
    joystick.x = x
    joystick.y = y
end

-- ==================== LÖVE callbacks ====================
function love.load()
    love.math.setRandomSeed(os.time())
    -- Adjust joystick base position after window resize
    joystick.base_x = love.graphics.getWidth() * 150 / 841
    joystick.base_y = love.graphics.getHeight() * (387 - 150) / 387
    joystick.knob_x, joystick.knob_y = joystick.base_x, joystick.base_y
    
    GRID_H, GRID_W = math.floor(love.graphics.getHeight() / 20), math.floor(love.graphics.getWidth() / 20)
    CELL_SIZE = 20          -- pixels per cell
    PLAY_AREA_W = GRID_W * CELL_SIZE
    PLAY_AREA_H = GRID_H * CELL_SIZE
    
    -- Try to load save, else fresh start
    load_game()
end

function love.update(dt)
    -- Keyboard input (if no touch active)
    if joystick.touch_id == nil then
        keyboard_input()
    end

    -- Move player with speed and joystick
    player.x = player.x + player.speed * joystick.x * dt
    player.y = player.y + player.speed * joystick.y * dt

    -- Clamp to play area (keep inside green, touching border allowed)
    player.x = math.max(player.rad, math.min(PLAY_AREA_W - player.rad, player.x))
    player.y = math.max(player.rad, math.min(PLAY_AREA_H - player.rad, player.y))

    -- Spawn coins (original chance)
    spawn_coin()

    -- Check collection
    check_collection()
end

function love.draw()
    -- Draw play area background (green)
    love.graphics.setColor(colours.grass)
    love.graphics.rectangle("fill", 0, 0, PLAY_AREA_W, PLAY_AREA_H)

    -- Draw red border (4 rectangles)
    love.graphics.setColor(colours.border)
    local border_thick = 4
    love.graphics.rectangle("fill", 0, 0, PLAY_AREA_W, border_thick)   -- top
    love.graphics.rectangle("fill", 0, PLAY_AREA_H - border_thick, PLAY_AREA_W, border_thick)  -- bottom
    love.graphics.rectangle("fill", 0, 0, border_thick, PLAY_AREA_H)   -- left
    love.graphics.rectangle("fill", PLAY_AREA_W - border_thick, 0, border_thick, PLAY_AREA_H)  -- right

    -- Draw coins
    for _, c in ipairs(coins) do
        love.graphics.setColor(c.colour)
        love.graphics.circle("fill", c.x, c.y, c.rad)
    end

    -- Draw player
    love.graphics.setColor(colours.player)
    love.graphics.circle("fill", player.x, player.y, player.rad)

    -- Draw joystick (visual)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", joystick.base_x, joystick.base_y, joystick.radius)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.circle("fill", joystick.knob_x, joystick.knob_y, joystick.radius * 0.4)
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw HUD (score, etc.)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("X: %d   Y: %d   Score: %d   High: %d   Last: %d   Coins: %d",
        math.floor(player.x/20 + 0.5), math.floor(player.y/20 + 0.5), player.score, player.high_score, player.last_score, coin_count), 10, 10)
end

-- ==================== Touch handlers (joystick) =========
function love.touchpressed(id, x, y)
    local dx = x - joystick.base_x
    local dy = y - joystick.base_y
    if math.sqrt(dx*dx + dy*dy) < joystick.radius * 1.5 then
        joystick.touch_id = id
        update_joystick(x, y)
    end
end

function love.touchmoved(id, x, y)
    if id == joystick.touch_id then
        update_joystick(x, y)
    end
end

function love.touchreleased(id)
    if id == joystick.touch_id then
        joystick.touch_id = nil
        joystick.x, joystick.y = 0, 0
        joystick.knob_x, joystick.knob_y = joystick.base_x, joystick.base_y
    end
end

-- ==================== Exit handling =====================
function love.quit()
    player.last_score = player.score
    save_game()
end

-- ==================== Simple table serialisation ========
-- (used by save/load)
function table.serialize(tbl)
    local str = "{"
    for k, v in pairs(tbl) do
        if type(k) == "number" then k = "[" .. k .. "]" end
        if type(v) == "table" then
            str = str .. k .. "=" .. table.serialize(v) .. ","
        elseif type(v) == "string" then
            str = str .. k .. "=\"" .. v .. "\","
        elseif type(v) == "number" then
            str = str .. k .. "=" .. v .. ","
        elseif type(v) == "boolean" then
            str = str .. k .. "=" .. tostring(v) .. ","
        end
    end
    str = str .. "}"
    return str
end
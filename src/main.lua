require("utility")
require("settings")
require("player")
require("collectible")
require("entity")
require("joystick")
require("buttons")
require("menu")






-- ==================== Scoring & Save ===================




-- ==================== LÖVE callbacks ====================
function love.load()
    fps = 0
    try = ""
    cn = ""
    love.math.setRandomSeed(os.time())
    math.randomseed(os.time())
    -- Adjust joystick base position after window resize
    joystick.base_x = love.graphics.getWidth() * 140 / 841
    joystick.base_y = love.graphics.getHeight() * (387 - 140) / 387
    joystick.knob_x, joystick.knob_y = joystick.base_x, joystick.base_y
    
    grid.h, grid.w = math.floor(love.graphics.getHeight() / 20), math.floor(love.graphics.getWidth() / 20)
    cell_size = 20          -- pixels per cell
    grid.s = math.sqrt((grid.h - 1)^2 + (grid.w - 1)^2)
    pa.w = grid.w * cell_size
    pa.h = grid.h * cell_size
    
    collectible:new("gold", nil, "gold", cell_size * 0.4, 30, "Sulfur", 1, {"lr", "tb", "d"} )
    collectible:new("diamond", nil, "diamond", cell_size * 0.4, 0.001, "Diamond", 1, {"lr", "tb", "d"} )
    collectible:new("amethyst", nil, "amethyst", cell_size * 0.4, 2, "Amethyst", 1, {"lr", "tb", "d"} )
    collectible:new("iron", nil, "iron", cell_size * 0.4, 0.9, "Iron", 1, {"lr", "tb", "d"} )
    collectible:new("obsidian", nil, "obsidian", cell_size * 0.4, 0.5, "Obsidian", 1, {"lr", "tb", "d"} )
    collectible:new("mytherite", nil, "mytherite", cell_size * 0.4, 0.000001, "Mytherite", 1, {"lr", "tb", "d"} )
    
    button:new("f3", pa.w - 50, 3, pa.w - 3, 50, "f3", nil, nil, nil, nil, function()
        if f3 then
            f3 = false
        else
            f3 = true
        end
    end, nil)
    -- Try to load save, else fresh start
    --load_game()
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
    player.x = math.max(player.rad, math.min(pa.w - player.rad, player.x))
    player.y = math.max(player.rad, math.min(pa.h - player.rad, player.y))

    -- Spawn coins
    collectible:spawn(dt)
    collectible:collect()
    fps = 1 / dt
    
    
    
end

function love.draw()
    local line = 0
    local font_size = love.graphics.getFont():getHeight()
    -- Draw play area background (green)
    love.graphics.setColor(colors.grass)
    love.graphics.rectangle("fill", 0, 0, pa.w, pa.h)

    -- Draw red border (4 rectangles)
    love.graphics.setColor(colors.border)
    local border_thick = 4
    love.graphics.rectangle("fill", 0, 0, pa.w, border_thick)   -- top
    love.graphics.rectangle("fill", 0, pa.h - border_thick, pa.w, border_thick)  -- bottom
    love.graphics.rectangle("fill", 0, 0, border_thick, pa.h)   -- left
    love.graphics.rectangle("fill", pa.w - border_thick, 0, border_thick, pa.h)  -- right

    -- Draw coins
    for _, c in ipairs(collectible.spawned) do
        love.graphics.setColor(collectible.types.name[c.name].color)
        --love.graphics.setColor(c.color)
        love.graphics.circle("fill", c.x, c.y, collectible.types.name[c.name].size)
    end
    
    -- Draw player
    love.graphics.setColor(colors.player)
    love.graphics.circle("fill", player.x, player.y, player.rad)

    -- Draw joystick (visual)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", joystick.base_x, joystick.base_y, joystick.radius)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.circle("fill", joystick.knob_x, joystick.knob_y, joystick.radius * 0.4)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Buttons
    for id, butt in pairs(button.list) do
        
        love.graphics.setColor(colors.buttback)
        love.graphics.rectangle("fill", butt.sx, butt.sy, butt.width, butt.height)
        
        love.graphics.setColor(colors.button)
        love.graphics.rectangle("fill", butt.sx + 5, butt.sy + 5, butt.width - 10, butt.height - 10)
        
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.printf(butt.txt, butt.sx, (butt.sy + butt.ey)/2 - font_size, butt.width, "center")
    end
    
    -- Draw HUD (score, etc.)
    if f3 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("X, Y: %d, %d \nFPS: %d \nCoins: %d", math.floor(player.x/20 + 0.5), math.floor(player.y/20 + 0.5), fps, #collectible.spawned), 10, line * font_size + 10)
        line = line + 4
        
        for _, name in ipairs(player.inv_order) do
            count = player.inventory[name]
            if count and count > 0 then
                love.graphics.print(name..": "..count, 10, 10 + line * font_size)
                line = line + 1
            end
            
        end
        
    end
end

-- ==================== Touch handlers (joystick) =========
function love.touchpressed(id, x, y)
    local dx = x - joystick.base_x
    local dy = y - joystick.base_y
    if math.sqrt(dx*dx + dy*dy) < joystick.radius * 1.5 then
        joystick.touch_id = id
        update_joystick(x, y)
    end
    button:set_touch(id, x, y)
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
function love.keypressed(key)
    if key == "f3" then
        if f3 then
            f3 = true
        else
            f3 = false
        end
    end
end

-- ==================== Exit handling =====================
function love.quit()
    player.last_score = player.score
    save_game()
end

-- ==================== Simple table serialisation ========
-- (used by save/load)

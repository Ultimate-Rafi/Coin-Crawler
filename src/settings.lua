
-- ==================== Game settings ====================
grid = {}
grid.h, grid.w = math.floor(love.graphics.getHeight() / 20), math.floor(love.graphics.getWidth() / 20)
grid.s = math.floor(math.sqrt(grid.h^2 + grid.w^2))
cell_size = 20          -- pixels per cell
pa = {} -- play area
pa.w = grid.w * cell_size
pa.h = grid.h * cell_size
rng_offset = 6 -- accuracy to _ digits after decimal point
spawn_boost = 80
f3 = true

-- ==================== colors ==========================
colors = {
    grass   = {0.2, 0.8, 0.2, 1},
    border  = {0.8, 0.2, 0.2},
    player  = {0.2, 0.4, 0.8},
    diamond = {0.2, 0.8, 0.8},   -- cyan
    iron   = {0.9, 0.9, 0.9},   -- white
    amethyst= {0.8, 0.2, 0.8},   -- magenta
    gold    = {0.9, 0.9, 0.2},   -- yellow
    obsidian = rgb(27, 3, 30),
    mytherite = rgb(67, 67, 67),
    button = rgb(113, 113, 113, 0.8),
    buttback = rgb(163, 163, 163, 0.6)
}




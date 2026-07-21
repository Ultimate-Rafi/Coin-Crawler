


-- ==================== Player ===========================
player = {
    x = pa.w / 2,
    y = pa.h / 2,
    rad = cell_size * 0.7,
    speed = 250,        -- pixels per second
    minspeed = 50,      -- not used here, kept for compatibility
    inventory = {},
    inv_order = {
        "Sulfur",
        "Amethyst",
        "Iron",
        "Obsidian",
        "Diamond",
        "Mytherite"
    },
    score = 0
}


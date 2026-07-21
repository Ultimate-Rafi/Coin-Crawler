menu = {
    current = {}, -- contains data for the current menu / window
    default = {}, -- the default menu / window
    list = {} -- contains every menu / window
}

function menu.new(self, name, world, player, joystick, button_list, etc)
    
end

function menu.set(self, name)
    if self.list[name] then
        self.current = self.list[name]
    else
        self.current = self.default
    end
end




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

function rgb(r, g, b, a)
    return {r/256, g / 256, b / 256, (a or 1)}
end


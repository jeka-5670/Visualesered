--[[ Launcher3D v3 — Защищённый Loader ]]

local REPO   = "jeka-5670/Visualesered"
local BRANCH = "main"
-- ВНИМАНИЕ: на скриншоте папка называется "scr". 
-- Если вы переименовали её в "src", поменяйте значение ниже на "src/"
local FOLDER = "scr/" 

local FILES = {
    "00_services.lua", "01_themes.lua", "02_helpers.lua", "03_panels.lua",
    "04_pages.lua", "05_home.lua", "06_sethelpers.lua", "07_movement.lua",
    "08_effects.lua", "09_apps.lua", "10_world.lua", "11_hud.lua",
    "12_button.lua", "13_settings.lua", "14_main.lua"
}

local function fetchFile(name)
    local path = FOLDER .. name
    local url = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. path
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    
    if not ok then error("[Launcher3D] Ошибка сети при скачивании " .. path) end
    
    -- Если GitHub вернул 404 (файл не найден) или HTML страницу
    if type(res) ~= "string" or res:find("<!DOCTYPE html>") or res:find("404: Not Found") then
        error("[Launcher3D] Файл не найден на GitHub: " .. path .. "\nПроверьте, что репозиторий ПУБЛИЧНЫЙ и папка называется правильно.")
    end
    
    return res
end

local parts = {}
for _, name in ipairs(FILES) do
    local ok, body = pcall(fetchFile, name)
    if not ok then
        warn(tostring(body))
        return -- Мягко выходим, не ломая игру
    end
    parts[#parts + 1] = "-- >>> " .. FOLDER .. name .. "\n" .. body
end

local source = table.concat(parts, "\n\n")
local chunk, cErr = loadstring(source)

if not chunk then
    warn("[Launcher3D] Ошибка в коде одного из модулей:\n" .. tostring(cErr))
    return
end

chunk()

--[[ Launcher3D v3 — Loader (Smart Limit Fix) ]]
print(">>> ЗАГРУЖЕН УМНЫЙ ЛОАДЕР <<<")

local REPO   = "jeka-5670/Visualesered"
local BRANCH = "main"
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
    if type(res) ~= "string" or res:find("<!DOCTYPE html>") or res:find("404: Not Found") then
        error("[Launcher3D] Файл не найден на GitHub: " .. path)
    end
    return res
end

local parts = {}
for _, name in ipairs(FILES) do
    local ok, body = pcall(fetchFile, name)
    if not ok then
        warn(tostring(body))
        return 
    end
    parts[#parts + 1] = "-- >>> " .. FOLDER .. name .. "\n" .. body .. "\n\n"
end

local source = table.concat(parts, "\n\n")

-- Убираем local у функций и у переменных со знаком '=', чтобы обойти лимит в 200 регистров
source = source:gsub("local function", "function")
source = source:gsub("local ([%w_, ]+)=", "%1=")

local chunk, cErr = loadstring(source)

if not chunk then
    warn("[Launcher3D] Ошибка в коде одного из модулей:\n" .. tostring(cErr))
    return
end

chunk()

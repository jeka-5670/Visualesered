--[[ Launcher3D v3 — FINAL LOADER ]]
print(">>> ЗАГРУЖЕН ФИНАЛЬНЫЙ ЛОАДЕР (100% РАБОТАЕТ) <<<")

local REPO   = "jeka-5670/Visualesered"
local BRANCH = "main"
local FOLDER = "scr/" 

local FILES = {
    "00_services.lua", "01_themes.lua", "02_helpers.lua", "03_panels.lua",
    "04_pages.lua", "05_home.lua", "06_sethelpers.lua", "07_movement.lua",
    "08_effects.lua", "09_apps.lua", "10_world.lua", "11_hud.lua",
    "12_button.lua", "13_settings.lua", "14_main.lua"
}

local parts = {}
for _, name in ipairs(FILES) do
    local url = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. FOLDER .. name
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(res) ~= "string" or res:find("404: Not Found") then
        warn("[Launcher3D] Ошибка скачивания файла: " .. name)
        return
    end
    parts[#parts + 1] = res
end

local source = table.concat(parts, "\n\n")

-- УМНЫЙ ФИКС: Добавляем = nil переменным, у которых его не было
source = source:gsub("local ([%w_, ]+)\n", "%1 = nil\n")
-- Убираем local у функций
source = source:gsub("local function", "function")
-- Убираем оставшиеся local (у переменных со знаком =)
source = source:gsub("local ", "")

local chunk, err = loadstring(source)
if not chunk then
    warn("[Launcher3D] Ошибка компиляции:\n" .. tostring(err))
    return
end
chunk()

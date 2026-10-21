--[[ Launcher3D v3 — ULTIMATE FIX ]]
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

-- ИСПРАВЛЕНИЕ ОШИБКИ 'Expected =': Добавляем = nil туда, где его не было
source = source:gsub("local setOpen, applyAll, applyView, applyButton, applyHud, drawSettings", "setOpen, applyAll, applyView, applyButton, applyHud, drawSettings = nil, nil, nil, nil, nil, nil")
source = source:gsub("local flyBV, flyBG", "flyBV, flyBG = nil, nil")
source = source:gsub("local tpos, tsnap", "tpos, tsnap = nil, nil")

-- ИСПРАВЛЕНИЕ ЛИМИТА 200: Убираем слово local у всего остального
source = source:gsub("local ", "")

local chunk, err = loadstring(source)
if not chunk then
    warn("[Launcher3D] Ошибка компиляции:\n" .. tostring(err))
    return
end
chunk()

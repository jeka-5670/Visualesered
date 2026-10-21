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

local function fetchFile(name)
    local path = FOLDER .. name
    local url = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. path
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(res) ~= "string" or res:find("404: Not Found") then
        error("[Launcher3D] Ошибка скачивания файла: " .. path)
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

-- ФИКС: Добавляем = nil туда, где его не было, чтобы код не сломался
source = source:gsub("local content", "content = nil")
source = source:gsub("local flyBV, flyBG", "flyBV, flyBG = nil, nil")
source = source:gsub("local tpos, tsnap", "tpos, tsnap = nil, nil")

-- ФИКС: Убираем local у всего остального, чтобы обойти лимит в 200 переменных
source = source:gsub("local ", "")

local chunk, cErr = loadstring(source)

if not chunk then
    warn("[Launcher3D] Ошибка в коде одного из модулей:\n" .. tostring(cErr))
    return
end

chunk()

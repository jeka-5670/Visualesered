--[[ Launcher3D v3 — Loader
Скачивает 15 модулей из src/, склеивает в один исходник, исполняет.
Запуск:
loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/Launcher3D/refs/heads/main/launcher.lua"))()
]]

local REPO   = "flazhy/Launcher3D"
local BRANCH = "main"

local FILES = {
    "00_services.lua",
    "01_themes.lua",
    "02_helpers.lua",
    "03_panels.lua",
    "04_pages.lua",
    "05_home.lua",
    "06_sethelpers.lua",
    "07_movement.lua",
    "08_effects.lua",
    "09_apps.lua",
    "10_world.lua",
    "11_hud.lua",
    "12_button.lua",
    "13_settings.lua",
    "14_main.lua",
}

-- Primary: raw.githubusercontent (всегда свежий).
-- Fallback: jsdelivr (если raw заблокирован / rate limit).
local function urls(path)
    return {
        "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. path,
        "https://cdn.jsdelivr.net/gh/" .. REPO .. "@" .. BRANCH .. "/" .. path,
    }
end

local function fetchFile(name)
    local path = "src/" .. name
    local lastErr = "unknown"
    for _, url in ipairs(urls(path)) do
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(res) == "string" and #res > 10 then return res end
        lastErr = tostring(res)
        local ok2, res2 = pcall(function() return game:HttpGet(url) end)
        if ok2 and type(res2) == "string" and #res2 > 10 then return res2 end
    end
    error("[Launcher3D] не удалось скачать " .. path .. ": " .. lastErr)
end

local parts = {}
for _, name in ipairs(FILES) do
    local ok, body = pcall(fetchFile, name)
    if not ok then
        warn("[Launcher3D] " .. tostring(body))
        error("[Launcher3D] загрузка модуля не удалась: " .. name)
    end
    parts[#parts + 1] = "-- >>> src/" .. name .. "\n" .. body
end

local source = table.concat(parts, "\n\n")
local chunk, cErr = loadstring(source)
if not chunk then
    warn("[Launcher3D] ошибка компиляции: " .. tostring(cErr))
    error("[Launcher3D] compile error")
end
chunk()

--[[ ЛАУНЧЕР 3D v3 для Roblox.
Запуск через launcher.lua (см. репозиторий).
Клавиши: L меню, F полёт, N ноуклип, K ESP, H HUD, «+»/«−» масштаб меню. ]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local lp = Players.LocalPlayer
local PG = lp:WaitForChild("PlayerGui")

---------------------------------------------------------------- защита от двойного запуска + очистка
local ENV = (getgenv and getgenv()) or _G
if ENV.__Launcher3D_cleanup then pcall(ENV.__Launcher3D_cleanup) end
local conns, junk, alive = {}, {}, true
local function conn(sig, fn) local c = sig:Connect(fn); conns[#conns + 1] = c; return c end
local function keep(o) junk[#junk + 1] = o; return o end

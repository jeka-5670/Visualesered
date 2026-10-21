---------------------------------------------------------------- темы и состояние
local THEMES = {
	["Тёмная"]  = {bg = Color3.fromRGB(24,26,30), card = Color3.fromRGB(36,39,45), card2 = Color3.fromRGB(50,54,62), text = Color3.fromRGB(245,246,250), sub = Color3.fromRGB(150,156,170), rim = Color3.fromRGB(130,170,225)},
	["Светлая"] = {bg = Color3.fromRGB(238,241,248), card = Color3.fromRGB(255,255,255), card2 = Color3.fromRGB(222,227,239), text = Color3.fromRGB(21,23,28), sub = Color3.fromRGB(107,112,128), rim = Color3.fromRGB(150,175,220)},
	["Океан"]   = {bg = Color3.fromRGB(6,48,72), card = Color3.fromRGB(14,84,108), card2 = Color3.fromRGB(24,110,136), text = Color3.fromRGB(235,250,255), sub = Color3.fromRGB(160,208,222), rim = Color3.fromRGB(110,220,235)},
	["Закат"]   = {bg = Color3.fromRGB(52,30,76), card = Color3.fromRGB(100,46,100), card2 = Color3.fromRGB(140,66,116), text = Color3.fromRGB(255,240,232), sub = Color3.fromRGB(255,200,190), rim = Color3.fromRGB(255,160,130)},
	["Лес"]     = {bg = Color3.fromRGB(18,36,26), card = Color3.fromRGB(28,58,40), card2 = Color3.fromRGB(40,80,56), text = Color3.fromRGB(232,250,238), sub = Color3.fromRGB(160,200,174), rim = Color3.fromRGB(120,220,150)},
	["Неон"]    = {bg = Color3.fromRGB(10,6,24), card = Color3.fromRGB(26,14,52), card2 = Color3.fromRGB(44,22,84), text = Color3.fromRGB(250,240,255), sub = Color3.fromRGB(190,150,240), rim = Color3.fromRGB(255,60,220)},
	["Графит"]  = {bg = Color3.fromRGB(14,14,14), card = Color3.fromRGB(26,26,26), card2 = Color3.fromRGB(40,40,40), text = Color3.fromRGB(235,235,235), sub = Color3.fromRGB(135,135,135), rim = Color3.fromRGB(200,200,200)},
	["Сакура"]  = {bg = Color3.fromRGB(255,238,244), card = Color3.fromRGB(255,255,255), card2 = Color3.fromRGB(252,214,228), text = Color3.fromRGB(70,30,50), sub = Color3.fromRGB(160,100,125), rim = Color3.fromRGB(255,140,180)},
}
local THEME_ORDER = {"Тёмная", "Светлая", "Океан", "Закат", "Лес", "Неон", "Графит", "Сакура"}
local ACCENTS = {Color3.fromRGB(10,132,255), Color3.fromRGB(255,55,95), Color3.fromRGB(48,209,88), Color3.fromRGB(191,90,242), Color3.fromRGB(255,159,10), Color3.fromRGB(0,220,200), Color3.fromRGB(255,235,60), Color3.fromRGB(240,240,240)}
local SHAPES = {round = UDim.new(0,14), circle = UDim.new(0.5,0), square = UDim.new(0,4)}
local SIZES = {S = 44, M = 52, L = 60}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,80,80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,200,60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90,255,120)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70,200,255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150,100,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,80,200))})
local NS, NR = NumberSequence.new, NumberRange.new

local S = {
	theme = "Тёмная", acc = 1, view = "grid", shape = "round", size = "M", labels = true, widgets = true,
	alpha = 0, grad = false, rim = "off", hover = true,
	tilt = 22, zoom = 1, spread = 0, depth = 0, detach = false, parallax = true, blurMenu = false, fov = nil,
	btnStyle = "orb", btnSize = 60, btnIcon = "📱", btnAlpha = 0, btnGlow = true, btnRainbow = false, btnSpin = 1,
	btnSnap = true, btnFade = true, btnHandle = false, btnDot = true,
	hud = true, hudFps = true, hudPing = true, hudExec = true, hudMem = false, hudTime = false, hudPlayers = false,
	hudStack = false, hudScale = 1, hudAlpha = 0.25, hudColor = true,
	weather = "none", wamt = 2, thunder = false, fog = 0,
	cc = "normal", bloom = 0, rays = false, dof = false, cycle = 0, grav = workspace.Gravity,
	trail = false, aura = "none", glow = 0,
	fly = false, flySpeed = 60, noclip = false, ijump = false,
	speedVal = 16, holdSpeed = false, jumpVal = 50, holdJump = false,
	clicktp = false, esp = false, espNames = true, espDist = true, espHp = true, espTeam = false, espFill = 0.6, espMax = 1500,
	bright = false, zoomUnlock = false, fpLock = false,
	cross = false, chStyle = "cross", chSize = 14, chGap = 5, chThick = 2, chColor = 1,
	aclick = false, acps = 10, antiafk = true, boost = false, fpscap = nil,
	keys = {menu = "L", fly = "F", noclip = "N", esp = "K", hud = "H"},
}

local function col(role)
	if role == "acc" then return ACCENTS[S.acc] end
	if role == "white" then return Color3.new(1, 1, 1) end
	return THEMES[S.theme][role]
end
local reg = {}
local function bind(o, prop, role)
	local e = {o, prop, role}
	reg[#reg + 1] = e
	o[prop] = col(role)
	return e
end
local function setRole(e, role) e[3] = role; e[1][e[2]] = col(role) end
local function applyTheme()
	for k = #reg, 1, -1 do
		local r = reg[k]
		if r[1]:IsDescendantOf(game) then r[1][r[2]] = col(r[3]) else table.remove(reg, k) end
	end
end

--[[ ЛАУНЧЕР 3D v3 для Roblox. Один LocalScript (или обычный скрипт для инжектора).
Куда вставить: StarterPlayer > StarterPlayerScripts > LocalScript (весь код). Старые версии удали.
Повторный запуск сам убирает предыдущую копию.
Кнопка меню и панель HUD (FPS, пинг, инжектор) тянутся по всему экрану и видны всегда.
Клавиши по умолчанию: L меню, F полёт, N ноуклип, K ESP, H HUD, «+»/«−» масштаб меню. Меняются в Настройки > Клавиши. ]]

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

---------------------------------------------------------------- темы и состояние
local THEMES = {
	["Тёмная"] = {bg = Color3.fromRGB(24,26,30), card = Color3.fromRGB(36,39,45), card2 = Color3.fromRGB(50,54,62), text = Color3.fromRGB(245,246,250), sub = Color3.fromRGB(150,156,170), rim = Color3.fromRGB(130,170,225)},
	["Светлая"] = {bg = Color3.fromRGB(238,241,248), card = Color3.fromRGB(255,255,255), card2 = Color3.fromRGB(222,227,239), text = Color3.fromRGB(21,23,28), sub = Color3.fromRGB(107,112,128), rim = Color3.fromRGB(150,175,220)},
	["Океан"] = {bg = Color3.fromRGB(6,48,72), card = Color3.fromRGB(14,84,108), card2 = Color3.fromRGB(24,110,136), text = Color3.fromRGB(235,250,255), sub = Color3.fromRGB(160,208,222), rim = Color3.fromRGB(110,220,235)},
	["Закат"] = {bg = Color3.fromRGB(52,30,76), card = Color3.fromRGB(100,46,100), card2 = Color3.fromRGB(140,66,116), text = Color3.fromRGB(255,240,232), sub = Color3.fromRGB(255,200,190), rim = Color3.fromRGB(255,160,130)},
	["Лес"] = {bg = Color3.fromRGB(18,36,26), card = Color3.fromRGB(28,58,40), card2 = Color3.fromRGB(40,80,56), text = Color3.fromRGB(232,250,238), sub = Color3.fromRGB(160,200,174), rim = Color3.fromRGB(120,220,150)},
	["Неон"] = {bg = Color3.fromRGB(10,6,24), card = Color3.fromRGB(26,14,52), card2 = Color3.fromRGB(44,22,84), text = Color3.fromRGB(250,240,255), sub = Color3.fromRGB(190,150,240), rim = Color3.fromRGB(255,60,220)},
	["Графит"] = {bg = Color3.fromRGB(14,14,14), card = Color3.fromRGB(26,26,26), card2 = Color3.fromRGB(40,40,40), text = Color3.fromRGB(235,235,235), sub = Color3.fromRGB(135,135,135), rim = Color3.fromRGB(200,200,200)},
	["Сакура"] = {bg = Color3.fromRGB(255,238,244), card = Color3.fromRGB(255,255,255), card2 = Color3.fromRGB(252,214,228), text = Color3.fromRGB(70,30,50), sub = Color3.fromRGB(160,100,125), rim = Color3.fromRGB(255,140,180)},
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
	-- интерфейс
	theme = "Тёмная", acc = 1, view = "grid", shape = "round", size = "M", labels = true, widgets = true,
	alpha = 0, grad = false, rim = "off", hover = true,
	-- 3D-меню
	tilt = 22, zoom = 1, spread = 0, depth = 0, detach = false, parallax = true, blurMenu = false, fov = nil,
	-- кнопка открытия
	btnStyle = "orb", btnSize = 60, btnIcon = "📱", btnAlpha = 0, btnGlow = true, btnRainbow = false, btnSpin = 1,
	btnSnap = true, btnFade = true, btnHandle = false, btnDot = true,
	-- HUD
	hud = true, hudFps = true, hudPing = true, hudExec = true, hudMem = false, hudTime = false, hudPlayers = false,
	hudStack = false, hudScale = 1, hudAlpha = 0.25, hudColor = true,
	-- погода и мир
	weather = "none", wamt = 2, thunder = false, fog = 0,
	cc = "normal", bloom = 0, rays = false, dof = false, cycle = 0, grav = workspace.Gravity,
	-- персонаж
	trail = false, aura = "none", glow = 0,
	-- функции
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

---------------------------------------------------------------- помощники
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function frame(par, pos, size, role, rad)
	local f = new("Frame", {Position = pos, Size = size, BorderSizePixel = 0}, par)
	bind(f, "BackgroundColor3", role or "card")
	if rad then round(f, rad) end
	return f
end
local function label(par, text, size, role, pos, sz, bold, align)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size,
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 0, size + 6),
		TextXAlignment = align or Enum.TextXAlignment.Left, TextWrapped = true,
	}, par)
	bind(l, "TextColor3", role or "text")
	return l
end
local function button(par, text, cb, size, neutral)
	local b = new("TextButton", {Text = text, TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
		Size = size or UDim2.new(1, 0, 0, 40), BorderSizePixel = 0}, par)
	local eb, et
	if neutral then
		eb = bind(b, "BackgroundColor3", "card2"); et = bind(b, "TextColor3", "text")
	else
		eb = bind(b, "BackgroundColor3", "acc")
	end
	round(b, 12)
	local us = new("UIScale", {}, b)
	b.MouseEnter:Connect(function() if S.hover then TS:Create(us, TweenInfo.new(0.12), {Scale = 1.05}):Play() end end)
	b.MouseLeave:Connect(function() TS:Create(us, TweenInfo.new(0.12), {Scale = 1}):Play() end)
	b.Activated:Connect(cb)
	return b, eb, et
end
local function row(c, defs)
	local r = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, r)
	local n = #defs
	for _, d in ipairs(defs) do
		button(r, d[1], d[2], UDim2.new(1 / n, -8 * (n - 1) / n, 1, 0), d[3])
	end
	return r
end
local function hum() local ch = lp.Character; return ch and ch:FindFirstChildOfClass("Humanoid") end
local function root() local ch = lp.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function detectExecutor()
	local ok, n, v = pcall(function()
		if identifyexecutor then return identifyexecutor() end
		if getexecutorname then return getexecutorname() end
	end)
	if ok and n then return tostring(n) .. (v and (" " .. tostring(v)) or "") end
	if RS:IsStudio() then return "Studio (без инжектора)" end
	return "не определён"
end
local execName = detectExecutor()

local open, rootCF, animT = true, nil, 0
local setOpen, applyAll, applyView, applyButton, applyHud, drawSettings

---------------------------------------------------------------- 3D-панели
local MW, MH = 9.4, 5.2
local panels, panelBGs, rimStrokes, P = {}, {}, {}, {}
local function panel(key, lx, ly, w, h, zf)
	local part = keep(new("Part", {Name = "LauncherPanel", Size = Vector3.new(w, h, 0.05), Anchored = true, CanCollide = false,
		CanTouch = false, CastShadow = false, Transparency = 1}, nil))
	local sg = keep(new("SurfaceGui", {Adornee = part, Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 100, AlwaysOnTop = true, LightInfluence = 0, ResetOnSpawn = false, ClipsDescendants = true}, PG))
	local bg = frame(sg, UDim2.new(), UDim2.new(1, 0, 1, 0), "bg", 18)
	local st = new("UIStroke", {Thickness = 2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, bg)
	bind(st, "Color", "rim")
	new("UIGradient", {Name = "Grad", Rotation = 90, Enabled = false, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 160))}, bg)
	local pan = {part = part, sg = sg, lx = lx, ly = ly, dx = 0, dy = 0, zf = zf, key = key}
	panels[#panels + 1] = pan; panelBGs[#panelBGs + 1] = bg; rimStrokes[#rimStrokes + 1] = st
	P[key] = pan
	return bg
end
local nameBG = panel("name", -3.6, 2.3, 2.2, 0.6, 0.35)
local logBG = panel("log", -3.6, -0.35, 2.2, 4.5, 0.12)
local tabsBG = panel("tabs", 1.2, 2.3, 7.0, 0.6, 0.25)
local mainBG = panel("main", 1.2, -0.35, 7.0, 4.5, 0)

local drag = nil
local function startDrag(key)
	return function(i)
		if isPress(i) then
			drag = key
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = nil end end)
		end
	end
end
local nameBtn = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}, nameBG)
label(nameBG, "👤 " .. lp.DisplayName, 18, "text", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), true, Enum.TextXAlignment.Center).Active = false
nameBtn.InputBegan:Connect(startDrag("name"))
local pills = {}
for _, key in ipairs({"log", "tabs", "main"}) do
	local pill = new("TextButton", {Text = "", Size = UDim2.new(0.3, 0, 0, 9), Position = UDim2.new(0.35, 0, 1, -15), BorderSizePixel = 0,
		Visible = false, ZIndex = 10}, P[key].sg)
	bind(pill, "BackgroundColor3", "rim"); round(pill, 5)
	pill.InputBegan:Connect(startDrag(key))
	pills[#pills + 1] = pill
end
local offX, offY, dist = 0, 0, 10

---------------------------------------------------------------- страницы и вкладки
local pages, tabE, tabT, tabBtns = {}, {}, {}, {}
local PAGE_POS = UDim2.new(0, 12, 0, 12)
local function show(name)
	for k, p in pairs(pages) do
		p.Visible = (k == name)
		if k == name then
			p.Position = UDim2.new(0, 12, 0, 36)
			TS:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = PAGE_POS}):Play()
		end
	end
	for k in pairs(tabBtns) do
		setRole(tabE[k], k == name and "acc" or "card2")
		setRole(tabT[k], k == name and "white" or "text")
	end
end
local function scrollPage(name)
	local sf = new("ScrollingFrame", {Position = PAGE_POS, Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false}, mainBG)
	new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
	pages[name] = sf
	return sf
end
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center}, tabsBG)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, tabsBG)
for _, t in ipairs({{"home", "Главная"}, {"set", "Настройки"}, {"info", "Инфо"}, {"close", "✕ Скрыть"}}) do
	local k = t[1]
	local b, eb, et = button(tabsBG, t[2], function() if k == "close" then setOpen(false) else show(k) end end, UDim2.new(0.25, -8, 0, 40), true)
	if k ~= "close" then tabBtns[k] = b; tabE[k] = eb; tabT[k] = et end
end

---------------------------------------------------------------- журнал и инфо
local LOGS = {
	{"v3.0  HUD и функции", "Всегда видимая панель FPS, пинг и название инжектора. Полёт, ноуклип, ESP, ТП по клику, точки, наблюдение, прицел, автоклик, яркость, буст FPS. Клавиши можно менять."},
	{"v3.0  Новая кнопка", "4 стиля кнопки, анимация, притягивание к краю, гаснет когда не нужна, ручка для изменения размера."},
	{"v2.0  Эффекты", "Погода, туман, цветокоррекция, блум, смена дня и ночи, след и аура персонажа."},
	{"v1.3  Свободное меню", "Масштаб, разнос и отделение панелей."},
}
label(logBG, "Журнал обновлений", 17, "text", UDim2.new(0, 10, 0, 10), UDim2.new(1, -20, 0, 26), true, Enum.TextXAlignment.Center)
frame(logBG, UDim2.new(0.12, 0, 0, 40), UDim2.new(0.76, 0, 0, 2), "rim", 1)
local logList = new("ScrollingFrame", {Position = UDim2.new(0, 8, 0, 52), Size = UDim2.new(1, -16, 1, -66), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, logBG)
new("UIListLayout", {Padding = UDim.new(0, 6)}, logList)
local info = scrollPage("info")
label(info, "Добро пожаловать!", 22, "text", nil, UDim2.new(1, 0, 0, 34), true)
label(info, "Тяни панель с именем, чтобы двигать меню. HUD (FPS, пинг, инжектор) и кнопку меню можно таскать по всему экрану. Нажми запись слева, чтобы прочитать её здесь.", 15, "sub", nil, UDim2.new(1, 0, 0, 74))
local logTitle = label(info, "", 18, "text", nil, UDim2.new(1, 0, 0, 28), true)
local logText = label(info, "", 16, "text", nil, UDim2.new(1, 0, 0, 100))
local function showLog(k) logTitle.Text = LOGS[k][1]; logText.Text = LOGS[k][2]; show("info") end
for k, e in ipairs(LOGS) do
	local b = button(logList, e[1], function() showLog(k) end, UDim2.new(1, 0, 0, 36), true)
	b.TextSize = 14; b.TextXAlignment = Enum.TextXAlignment.Left
	new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
end
showLog(1)

---------------------------------------------------------------- главная: виджеты + две папки
local home = new("Frame", {Position = PAGE_POS, Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1}, mainBG)
pages.home = home
local wrow = new("Frame", {Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1}, home)
local wv = {}
for k, t in ipairs({"Время", "Профиль", "FPS", "Пинг", "Инжектор"}) do
	local w = frame(wrow, UDim2.new((k - 1) * 0.2, (k - 1) * 1.6, 0, 0), UDim2.new(0.2, -6.4, 1, 0), "card", 14)
	label(w, t, 12, "sub", UDim2.new(0, 10, 0, 8), UDim2.new(1, -20, 0, 16))
	wv[k] = label(w, "", 20, "text", UDim2.new(0, 10, 0, 28), UDim2.new(1, -20, 0, 26), true)
	wv[k + 10] = label(w, "", 11, "sub", UDim2.new(0, 10, 0, 56), UDim2.new(1, -20, 0, 16))
end
wv[5].TextSize = 13; wv[5].TextTruncate = Enum.TextTruncate.AtEnd; wv[5].TextWrapped = false
local toolbar = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1}, home)
local hint = label(toolbar, "", 13, "sub", UDim2.new(0, 4, 0, 0), UDim2.new(1, -190, 1, 0))
local moveMode, selected = false, nil
local moveBtn
local fold = new("Frame", {BackgroundTransparency = 1}, home)
local folders, icons = {}, {}
local function makeFolder(key, title, pos)
	local f = new("TextButton", {Text = "", AutoButtonColor = false, Position = pos, Size = UDim2.new(0.5, -4, 1, 0), BorderSizePixel = 0}, fold)
	bind(f, "BackgroundColor3", "card"); round(f, 16)
	label(f, title, 16, "text", UDim2.new(0, 14, 0, 8), UDim2.new(1, -28, 0, 24), true)
	local sc = new("ScrollingFrame", {Position = UDim2.new(0, 6, 0, 38), Size = UDim2.new(1, -12, 1, -44), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, f)
	local g = new("UIGridLayout", {CellPadding = UDim2.fromOffset(2, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sc)
	folders[key] = {frame = f, sc = sc, grid = g}
end
makeFolder("f1", "Движение", UDim2.new())
makeFolder("f2", "Инструменты и игры", UDim2.new(0.5, 4, 0, 0))

local appPage = new("Frame", {Position = PAGE_POS, Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1, Visible = false}, mainBG)
pages.app = appPage
local appTitle = label(appPage, "", 20, "text", UDim2.new(0, 56, 0, 0), UDim2.new(1, -60, 0, 36), true)
local content
local function closeApp() if content then content:Destroy(); content = nil end; show("home") end
button(appPage, "‹", closeApp, UDim2.fromOffset(44, 36))
local RUN = {}
local function openApp(app)
	if content then content:Destroy() end
	content = new("ScrollingFrame", {Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, appPage)
	new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)
	appTitle.Text = app.i .. "  " .. app.n
	show("app")
	RUN[app.id](content)
end

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local APPS = {
	{id = "fly", n = "Полёт", i = "✈️", c = C(10,132,255), f = "f1"},
	{id = "noclip", n = "Ноуклип", i = "👻", c = C(120,120,128), f = "f1"},
	{id = "ijump", n = "Беск. прыжок", i = "🦘", c = C(48,209,88), f = "f1"},
	{id = "speed", n = "Скорость", i = "⚡", c = C(255,159,10), f = "f1"},
	{id = "jump", n = "Прыжок", i = "🚀", c = C(255,69,58), f = "f1"},
	{id = "clicktp", n = "ТП по клику", i = "🖱️", c = C(94,92,230), f = "f1"},
	{id = "points", n = "Точки", i = "📍", c = C(255,55,95), f = "f1"},
	{id = "players", n = "Игроки", i = "👥", c = C(100,210,255), f = "f1"},
	{id = "esp", n = "ESP", i = "👁️", c = C(191,90,242), f = "f2"},
	{id = "bright", n = "Яркость", i = "🔆", c = C(255,214,10), f = "f2"},
	{id = "camera", n = "Камера", i = "🎥", c = C(0,200,180), f = "f2"},
	{id = "spec", n = "Наблюдать", i = "🔭", c = C(72,72,160), f = "f2"},
	{id = "cross", n = "Прицел", i = "🎯", c = C(220,50,50), f = "f2"},
	{id = "aclick", n = "Автоклик", i = "🖲️", c = C(60,160,90), f = "f2"},
	{id = "server", n = "Сервер", i = "🌐", c = C(40,120,220), f = "f2"},
	{id = "perf", n = "Буст FPS", i = "🛠️", c = C(150,150,160), f = "f2"},
	{id = "time", n = "Время", i = "🌗", c = C(90,90,220), f = "f2"},
	{id = "notes", n = "Заметки", i = "📝", c = C(240,200,20), f = "f2"},
	{id = "click", n = "Кликер", i = "💎", c = C(70,190,255), f = "f2"},
	{id = "timer", n = "Секундомер", i = "⏱️", c = C(250,90,80), f = "f2"},
}
local function place(btn, sc, before)
	local list = {}
	for _, ch in ipairs(sc:GetChildren()) do
		if ch:IsA("TextButton") and ch ~= btn then list[#list + 1] = ch end
	end
	table.sort(list, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	local idx = before and table.find(list, before) or #list + 1
	table.insert(list, idx, btn)
	btn.Parent = sc
	for k, ch in ipairs(list) do ch.LayoutOrder = k end
end
local function mark(b, on) b.Ico.Sel.Enabled = on end
local function setMove(v)
	moveMode = v
	if selected then mark(selected, false); selected = nil end
	moveBtn.Text = v and "✋ Готово" or "✋ Перемещать значки"
	hint.Text = v and "Нажми значок, затем другой значок или папку" or ""
end
moveBtn = button(toolbar, "✋ Перемещать значки", function() setMove(not moveMode) end, UDim2.new(0, 180, 1, 0), true)
moveBtn.Position = UDim2.new(1, -180, 0, 0); moveBtn.TextSize = 14
local function onIcon(b, app)
	if not moveMode then openApp(app) return end
	if not selected then selected = b; mark(b, true) return end
	if selected == b then mark(b, false); selected = nil return end
	place(selected, b.Parent, b)
	mark(selected, false); selected = nil
end
for _, f in pairs(folders) do
	f.frame.Activated:Connect(function()
		if moveMode and selected then place(selected, f.sc, nil); mark(selected, false); selected = nil end
	end)
end
for order, app in ipairs(APPS) do
	local b = new("TextButton", {Text = "", BackgroundTransparency = 1, LayoutOrder = order}, folders[app.f].sc)
	local ico = new("TextLabel", {Name = "Ico", Text = app.i, BackgroundColor3 = app.c, BorderSizePixel = 0, Font = Enum.Font.GothamBold}, b)
	new("UICorner", {}, ico)
	new("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 175))}, ico)
	new("UIStroke", {Name = "Sel", Thickness = 3, Enabled = false, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, ico)
	local lbl = label(b, app.n, 12, "text", nil, nil, false, Enum.TextXAlignment.Center)
	lbl.Name = "Lbl"; lbl.TextWrapped = false; lbl.TextTruncate = Enum.TextTruncate.AtEnd
	icons[app.id] = b
	b.Activated:Connect(function() onIcon(b, app) end)
end

function applyView()
	local s = SIZES[S.size]
	for _, bg in ipairs(panelBGs) do
		bg.BackgroundTransparency = S.alpha
		bg.Grad.Enabled = S.grad
	end
	for _, p in ipairs(pills) do p.Visible = S.detach end
	local wy = S.widgets and 92 or 0
	wrow.Visible = S.widgets
	toolbar.Position = UDim2.new(0, 0, 0, wy)
	fold.Position = UDim2.new(0, 0, 0, wy + 36)
	fold.Size = UDim2.new(1, 0, 1, -(wy + 36))
	for _, f in pairs(folders) do
		f.grid.CellSize = S.view == "grid" and UDim2.fromOffset(s + 26, s + (S.labels and 28 or 6)) or UDim2.new(1, -6, 0, math.floor(s * 0.75) + 6)
	end
	for _, b in pairs(icons) do
		local ico, lbl = b.Ico, b.Lbl
		ico:FindFirstChildOfClass("UICorner").CornerRadius = SHAPES[S.shape]
		if S.view == "grid" then
			ico.Size = UDim2.fromOffset(s, s); ico.Position = UDim2.new(0.5, -s / 2, 0, 2); ico.TextSize = s * 0.5
			lbl.Position = UDim2.new(0, 0, 0, s + 4); lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.Visible = S.labels
		else
			local h = math.floor(s * 0.75)
			ico.Size = UDim2.fromOffset(h, h); ico.Position = UDim2.new(0, 2, 0.5, -h / 2); ico.TextSize = h * 0.5
			lbl.Position = UDim2.new(0, h + 10, 0, 0); lbl.Size = UDim2.new(1, -(h + 10), 1, 0)
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Visible = true
		end
	end
end

---------------------------------------------------------------- помощники настроек (общие для вкладки и приложений)
local function reset(c)
	for _, ch in ipairs(c:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
end
local function head(c, t) label(c, t, 13, "sub", nil, UDim2.new(1, 0, 0, 18), true) end
local function chunk(c, defs, n)
	for k = 1, #defs, n do row(c, {table.unpack(defs, k, math.min(k + n - 1, #defs))}) end
end
local function same(a, b)
	if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 0.01 end
	return a == b
end
local function opt(text, key, val, after)
	return {text, function() S[key] = val; applyAll(); (after or drawSettings)() end, not same(S[key], val)}
end
local function tog(text, key, after)
	return {text .. (S[key] and ": ВКЛ" or ": ВЫКЛ"), function() S[key] = not S[key]; applyAll(); (after or drawSettings)() end, not S[key]}
end
local function stepRow(c, title, key, st, lo, hi, fmt, after)
	label(c, title .. ": " .. fmt(S[key]), 15, "text", nil, UDim2.new(1, 0, 0, 22), true)
	local function ch(d) return function() S[key] = math.clamp(math.floor((S[key] + d) * 100 + 0.5) / 100, lo, hi); applyAll(); (after or drawSettings)() end end
	row(c, {{"−", ch(-st), true}, {"+", ch(st), true}})
end
local pct = function(v) return math.floor(v * 100 + 0.5) .. "%" end
local num = function(v) return tostring(v) end
local pxf = function(v) return v .. " px" end

---------------------------------------------------------------- функции: движение, ESP, камера и др.
local ncOrig = {}
local flyBV, flyBG
local flyUp, flyDown = false, false
local function stopFly()
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local h = hum(); if h then h.PlatformStand = false end
end
local function tpTo(pos)
	local r = root(); if r then r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end
end

conn(RS.Heartbeat, function(dt)
	local h, r = hum(), root()
	if S.fly and h and r then
		if not flyBV or flyBV.Parent ~= r then
			stopFly()
			flyBV = new("BodyVelocity", {MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero}, r)
			flyBG = new("BodyGyro", {MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 1e4, CFrame = r.CFrame}, r)
		end
		local cam = workspace.CurrentCamera
		local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
		local fl = Vector3.new(look.X, 0, look.Z); fl = fl.Magnitude > 0.01 and fl.Unit or Vector3.zero
		local rt = Vector3.new(right.X, 0, right.Z); rt = rt.Magnitude > 0.01 and rt.Unit or Vector3.zero
		local md = h.MoveDirection
		local vel = look * md:Dot(fl) + rt * md:Dot(rt)
		if UIS:IsKeyDown(Enum.KeyCode.Space) or flyUp then vel += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or flyDown then vel -= Vector3.yAxis end
		flyBV.Velocity = vel.Magnitude > 0.05 and vel.Unit * S.flySpeed or Vector3.zero
		flyBG.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(look.X, 0, look.Z))
		h.PlatformStand = true
	elseif flyBV then
		stopFly()
	end
	if h then
		if S.holdSpeed then h.WalkSpeed = S.speedVal end
		if S.holdJump then h.UseJumpPower = true; h.JumpPower = S.jumpVal end
	end
end)
conn(RS.Stepped, function()
	local ch = lp.Character
	if S.noclip and ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then ncOrig[p] = true; p.CanCollide = false end
		end
	elseif next(ncOrig) then
		for p in pairs(ncOrig) do
			if p.Parent then p.CanCollide = true end
			ncOrig[p] = nil
		end
	end
end)
conn(UIS.JumpRequest, function()
	if S.ijump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)
local mouse = lp:GetMouse()
conn(UIS.InputBegan, function(i, gp)
	if gp or not S.clicktp then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		if mouse.Hit then tpTo(mouse.Hit.Position) end
	end
end)
conn(UIS.TouchTapInWorld, function(pos, processed)
	if processed or not S.clicktp then return end
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(pos.X, pos.Y)
	local prm = RaycastParams.new()
	prm.FilterDescendantsInstances = {lp.Character}
	prm.FilterType = Enum.RaycastFilterType.Exclude
	local res = workspace:Raycast(ray.Origin, ray.Direction * 2000, prm)
	if res then tpTo(res.Position) end
end)
conn(lp.Idled, function()
	if S.antiafk then
		pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
	end
end)
local acT = 0
conn(RS.Heartbeat, function(dt)
	if not S.aclick then return end
	acT += dt
	if acT >= 1 / S.acps then
		acT = 0
		pcall(function()
			if mouse1click then mouse1click() else VirtualUser:ClickButton1(Vector2.new(0, 0)) end
		end)
	end
end)

-- ESP: подсветка и подписи над игроками
local espFolder = keep(new("Folder", {Name = "LauncherESP"}, PG))
local function clearEsp() espFolder:ClearAllChildren() end
local function updateEsp()
	if not S.esp then if #espFolder:GetChildren() > 0 then clearEsp() end return end
	local myR = root()
	local alivePl = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hd = ch and ch:FindFirstChild("Head")
		local hu = ch and ch:FindFirstChildOfClass("Humanoid")
		if p ~= lp and hrp and hd and hu and (not myR or (hrp.Position - myR.Position).Magnitude <= S.espMax) then
			alivePl[p.Name] = true
			local color = (S.espTeam and p.Team and p.TeamColor.Color) or ACCENTS[S.acc]
			local hl = espFolder:FindFirstChild("HL_" .. p.Name)
			if not hl or hl.Adornee ~= ch then
				if hl then hl:Destroy() end
				hl = new("Highlight", {Name = "HL_" .. p.Name, Adornee = ch, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, OutlineColor = Color3.new(1, 1, 1)}, espFolder)
			end
			hl.FillColor = color; hl.FillTransparency = S.espFill
			local bb = espFolder:FindFirstChild("BB_" .. p.Name)
			if not bb or bb.Adornee ~= hd then
				if bb then bb:Destroy() end
				bb = new("BillboardGui", {Name = "BB_" .. p.Name, Adornee = hd, AlwaysOnTop = true, Size = UDim2.fromOffset(180, 40), StudsOffset = Vector3.new(0, 2.8, 0)}, espFolder)
				new("TextLabel", {Name = "T", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14,
					TextStrokeTransparency = 0.3, TextColor3 = Color3.new(1, 1, 1)}, bb)
			end
			local txt = {}
			if S.espNames then txt[#txt + 1] = p.DisplayName end
			if S.espDist and myR then txt[#txt + 1] = "[" .. math.floor((hrp.Position - myR.Position).Magnitude) .. "м]" end
			if S.espHp then txt[#txt + 1] = "♥" .. math.floor(hu.Health) end
			bb.T.Text = table.concat(txt, " ")
			bb.Enabled = #txt > 0
		end
	end
	for _, o in ipairs(espFolder:GetChildren()) do
		if not alivePl[string.sub(o.Name, 4)] then o:Destroy() end
	end
end
task.spawn(function() while alive do pcall(updateEsp); task.wait(0.25) end end)

-- яркость, камера, буст FPS, прицел
local orig = {fs = Lighting.FogStart, fe = Lighting.FogEnd, fc = Lighting.FogColor, grav = workspace.Gravity, B = Lighting.Brightness,
	A = Lighting.Ambient, OA = Lighting.OutdoorAmbient, GS = Lighting.GlobalShadows, maxZ = lp.CameraMaxZoomDistance}
S.grav = orig.grav
local function applyBright()
	if S.bright then
		Lighting.Brightness = 2; Lighting.Ambient = Color3.fromRGB(190, 190, 190); Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
	else
		Lighting.Brightness = orig.B; Lighting.Ambient = orig.A; Lighting.OutdoorAmbient = orig.OA
	end
	Lighting.GlobalShadows = (S.bright or S.boost) and false or orig.GS
	pcall(function() workspace.Terrain.Decoration = not S.boost end)
end
local crossGui = keep(new("ScreenGui", {Name = "LauncherCross", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40}, PG))
local CROSS_COLORS = {C(255,255,255), C(255,60,60), C(60,255,120), C(80,180,255), C(255,220,60), C(255,80,220)}
local function applyCross()
	crossGui:ClearAllChildren()
	if not S.cross then return end
	local c, s, g, t = CROSS_COLORS[S.chColor], S.chSize, S.chGap, S.chThick
	local function bar(x, y, w, h)
		return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y), Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = c, BorderSizePixel = 0}, crossGui)
	end
	local st = S.chStyle
	if st == "cross" or st == "crossdot" then
		bar(0, -(g + s / 2), t, s); bar(0, g + s / 2, t, s); bar(-(g + s / 2), 0, s, t); bar(g + s / 2, 0, s, t)
	end
	if st == "dot" or st == "crossdot" then
		local d = bar(0, 0, t * 2, t * 2); new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, d)
	end
	if st == "circle" then
		local f = bar(0, 0, s * 2, s * 2); f.BackgroundTransparency = 1
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f); new("UIStroke", {Color = c, Thickness = t}, f)
	end
end
local function applyFunctions()
	applyBright(); applyCross()
	pcall(function()
		lp.CameraMaxZoomDistance = S.zoomUnlock and 10000 or orig.maxZ
		if S.zoomUnlock then lp.CameraMinZoomDistance = 0 end
		lp.CameraMode = S.fpLock and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
	end)
	if S.fpscap and setfpscap then pcall(setfpscap, S.fpscap) end
end

---------------------------------------------------------------- приложения
local function showApp(id) openApp(APPS[1]) end -- заглушка не используется
local function ftog(c, text, key, redraw) row(c, {tog(text, key, redraw)}) end

RUN.fly = function(c)
	local function draw()
		reset(c)
		ftog(c, "✈️ Полёт (клавиша " .. S.keys.fly .. ")", "fly", draw)
		stepRow(c, "Скорость полёта", "flySpeed", 10, 10, 300, num, draw)
		row(c, {{"30", function() S.flySpeed = 30; draw() end, true}, {"60", function() S.flySpeed = 60; draw() end, true},
			{"120", function() S.flySpeed = 120; draw() end, true}, {"200", function() S.flySpeed = 200; draw() end, true}})
		head(c, "Удерживай для высоты (Space / Ctrl на ПК)")
		local r = row(c, {{"▲ Вверх", function() end}, {"▼ Вниз", function() end, true}})
		local btns = {}
		for _, ch in ipairs(r:GetChildren()) do if ch:IsA("TextButton") then btns[#btns + 1] = ch end end
		local function hold(b, set)
			b.InputBegan:Connect(function(i)
				if isPress(i) then
					set(true)
					i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then set(false) end end)
				end
			end)
		end
		hold(btns[1], function(v) flyUp = v end); hold(btns[2], function(v) flyDown = v end)
		label(c, "Вперёд-назад ведёт по взгляду камеры: смотри вверх и лети вверх.", 13, "sub", nil, UDim2.new(1, 0, 0, 36))
	end
	draw()
end
RUN.noclip = function(c)
	local function draw() reset(c); ftog(c, "👻 Ноуклип (клавиша " .. S.keys.noclip .. ")", "noclip", draw)
		label(c, "Проходишь сквозь стены. При выключении столкновения возвращаются.", 13, "sub", nil, UDim2.new(1, 0, 0, 36)) end
	draw()
end
RUN.ijump = function(c)
	local function draw() reset(c); ftog(c, "🦘 Бесконечный прыжок", "ijump", draw)
		label(c, "Можно прыгать в воздухе сколько угодно раз.", 13, "sub", nil, UDim2.new(1, 0, 0, 24)) end
	draw()
end
RUN.speed = function(c)
	local function setSpeed() local h = hum(); if h then h.WalkSpeed = S.speedVal end end
	local function draw()
		reset(c)
		stepRow(c, "Скорость", "speedVal", 4, 0, 500, num, function() setSpeed(); draw() end)
		local p = {}
		for _, v in ipairs({16, 32, 64, 100, 200}) do p[#p + 1] = {tostring(v), function() S.speedVal = v; setSpeed(); draw() end, true} end
		row(c, p)
		ftog(c, "Удерживать (игра не сбросит)", "holdSpeed", draw)
	end
	draw()
end
RUN.jump = function(c)
	local function setJ() local h = hum(); if h then h.UseJumpPower = true; h.JumpPower = S.jumpVal end end
	local function draw()
		reset(c)
		stepRow(c, "Сила прыжка", "jumpVal", 10, 0, 800, num, function() setJ(); draw() end)
		local p = {}
		for _, v in ipairs({50, 80, 120, 200, 400}) do p[#p + 1] = {tostring(v), function() S.jumpVal = v; setJ(); draw() end, true} end
		row(c, p)
		ftog(c, "Удерживать (игра не сбросит)", "holdJump", draw)
	end
	draw()
end
RUN.clicktp = function(c)
	local function draw() reset(c); ftog(c, "🖱️ Телепорт по клику", "clicktp", draw)
		label(c, "ПК: зажми Ctrl и нажми левой кнопкой в точку. Телефон: просто тапни по миру.", 14, "sub", nil, UDim2.new(1, 0, 0, 50)) end
	draw()
end
local points = {}
RUN.points = function(c)
	local function draw()
		reset(c)
		row(c, {{"📍 Сохранить мою позицию", function()
			local r = root()
			if r then points[#points + 1] = {name = "Точка " .. (#points + 1), pos = r.Position}; draw() end
		end}})
		for k, pt in ipairs(points) do
			local r = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
			label(r, pt.name, 15, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.4, 0, 1, 0), true)
			local b1 = button(r, "ТП", function() tpTo(pt.pos) end, UDim2.new(0.25, 0, 0, 32)); b1.Position = UDim2.new(0.45, 0, 0.5, -16)
			local b2 = button(r, "✕", function() table.remove(points, k); draw() end, UDim2.new(0.22, 0, 0, 32), true); b2.Position = UDim2.new(0.74, 0, 0.5, -16)
		end
	end
	draw()
end
local spectating = false
local function spectate(p)
	local ch = p and p.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	if h then workspace.CurrentCamera.CameraSubject = h; spectating = true end
end
local function stopSpectate()
	local h = hum(); if h then workspace.CurrentCamera.CameraSubject = h end
	spectating = false
end
RUN.players = function(c)
	local function draw()
		reset(c)
		row(c, {{"Обновить список", draw, true}})
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then
				local r = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
				label(r, p.DisplayName, 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.38, 0, 1, 0), true)
				local b1 = button(r, "ТП", function()
					local his = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if his then tpTo(his.Position) end
				end, UDim2.new(0.25, 0, 0, 32)); b1.Position = UDim2.new(0.42, 0, 0.5, -16)
				local b2 = button(r, "👁", function() spectate(p) end, UDim2.new(0.25, 0, 0, 32), true); b2.Position = UDim2.new(0.7, 0, 0.5, -16)
			end
		end
	end
	draw()
end
RUN.spec = function(c)
	local function draw()
		reset(c)
		row(c, {{"■ Вернуть камеру себе", function() stopSpectate(); draw() end, not spectating}})
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then row(c, {{"👁 " .. p.DisplayName, function() spectate(p); draw() end, true}}) end
		end
	end
	draw()
end
RUN.esp = function(c)
	local function draw()
		reset(c)
		ftog(c, "👁️ ESP (клавиша " .. S.keys.esp .. ")", "esp", draw)
		row(c, {tog("Имена", "espNames", draw), tog("Дистанция", "espDist", draw)})
		row(c, {tog("Здоровье", "espHp", draw), tog("Цвет команды", "espTeam", draw)})
		stepRow(c, "Прозрачность заливки", "espFill", 0.1, 0, 1, pct, draw)
		stepRow(c, "Макс. дистанция", "espMax", 250, 250, 5000, function(v) return v .. " м" end, draw)
	end
	draw()
end
RUN.bright = function(c)
	local function draw() reset(c); ftog(c, "🔆 Полная яркость", "bright", draw)
		label(c, "Убирает тени и темноту. Туман в этом режиме отключается.", 13, "sub", nil, UDim2.new(1, 0, 0, 36)) end
	draw()
end
RUN.camera = function(c)
	local function draw()
		reset(c)
		ftog(c, "Снять ограничение отдаления", "zoomUnlock", draw)
		ftog(c, "Только от первого лица", "fpLock", draw)
		head(c, "Поле зрения")
		row(c, {{"50", function() S.fov = 50 end, true}, {"70", function() S.fov = 70 end, true}, {"90", function() S.fov = 90 end, true},
			{"110", function() S.fov = 110 end, true}, {"120", function() S.fov = 120 end, true}})
	end
	draw()
end
RUN.cross = function(c)
	local function draw()
		reset(c)
		ftog(c, "🎯 Прицел на экране", "cross", draw)
		head(c, "Стиль")
		row(c, {opt("Крест", "chStyle", "cross", draw), opt("Точка", "chStyle", "dot", draw), opt("Круг", "chStyle", "circle", draw), opt("Крест+точка", "chStyle", "crossdot", draw)})
		stepRow(c, "Размер", "chSize", 2, 4, 60, num, draw)
		stepRow(c, "Зазор", "chGap", 1, 0, 30, num, draw)
		stepRow(c, "Толщина", "chThick", 1, 1, 8, num, draw)
		head(c, "Цвет")
		local ar = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, ar)
		for k, color in ipairs(CROSS_COLORS) do
			local b = new("TextButton", {Text = S.chColor == k and "✓" or "", TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0, 0, 0),
				BackgroundColor3 = color, Size = UDim2.fromOffset(40, 40), BorderSizePixel = 0}, ar)
			round(b, 20)
			b.Activated:Connect(function() S.chColor = k; applyAll(); draw() end)
		end
	end
	draw()
end
RUN.aclick = function(c)
	local function draw()
		reset(c)
		ftog(c, "🖲️ Автокликер", "aclick", draw)
		stepRow(c, "Кликов в секунду", "acps", 1, 1, 30, num, draw)
		label(c, "Кликает по месту, где сейчас курсор. Использует mouse1click, если инжектор его поддерживает.", 13, "sub", nil, UDim2.new(1, 0, 0, 50))
	end
	draw()
end
RUN.server = function(c)
	local function draw()
		reset(c)
		label(c, "PlaceId: " .. game.PlaceId, 15, "text", nil, UDim2.new(1, 0, 0, 22))
		label(c, "JobId: " .. string.sub(game.JobId ~= "" and game.JobId or "локальный", 1, 22), 15, "text", nil, UDim2.new(1, 0, 0, 22))
		label(c, "Игроков: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers, 15, "text", nil, UDim2.new(1, 0, 0, 22))
		ftog(c, "Анти-АФК", "antiafk", draw)
		row(c, {{"🔁 Перезайти", function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end) end},
			{"🎲 Новый сервер", function() pcall(function() TeleportService:Teleport(game.PlaceId, lp) end) end, true}})
		row(c, {{setclipboard and "📋 Скопировать JobId" or "📋 Копирование недоступно", function()
			if setclipboard then pcall(setclipboard, game.JobId) end
		end, true}})
	end
	draw()
end
RUN.perf = function(c)
	local function draw()
		reset(c)
		ftog(c, "🛠️ Буст FPS (без теней и травы)", "boost", draw)
		head(c, "Лимит FPS " .. (setfpscap and "" or "(не поддерживается этим запуском)"))
		if setfpscap then
			row(c, {{"30", function() S.fpscap = 30; applyAll() end, true}, {"60", function() S.fpscap = 60; applyAll() end, true},
				{"144", function() S.fpscap = 144; applyAll() end, true}, {"240", function() S.fpscap = 240; applyAll() end, true},
				{"Без лимита", function() S.fpscap = 0; applyAll() end, true}})
		end
		ftog(c, "Показывать HUD (FPS, пинг, инжектор)", "hud", draw)
	end
	draw()
end
RUN.time = function(c)
	local v = label(c, "", 26, "text", nil, UDim2.new(1, 0, 0, 40), true)
	local function showV() v.Text = "Время: " .. string.format("%02d:00", math.floor(Lighting.ClockTime)) end
	local function set(x) Lighting.ClockTime = x % 24; showV() end
	showV()
	row(c, {{"Утро", function() set(7) end}, {"День", function() set(14) end}, {"Вечер", function() set(18.5) end}, {"Ночь", function() set(0) end}})
	row(c, {{"− 1 ч", function() set(Lighting.ClockTime - 1) end, true}, {"+ 1 ч", function() set(Lighting.ClockTime + 1) end, true}})
end
local noteText = ""
RUN.notes = function(c)
	local tb = new("TextBox", {Size = UDim2.new(1, 0, 0, 300), MultiLine = true, ClearTextOnFocus = false, Text = noteText,
		PlaceholderText = "Пиши здесь…", TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextSize = 16, Font = Enum.Font.Gotham, BorderSizePixel = 0}, c)
	bind(tb, "BackgroundColor3", "card"); bind(tb, "TextColor3", "text"); bind(tb, "PlaceholderColor3", "sub")
	round(tb, 14)
	new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingRight = UDim.new(0, 12)}, tb)
	tb:GetPropertyChangedSignal("Text"):Connect(function() noteText = tb.Text end)
end
local score, pow = 0, 1
RUN.click = function(c)
	local s = label(c, "", 36, "text", nil, UDim2.new(1, 0, 0, 56), true, Enum.TextXAlignment.Center)
	local b, u
	local function showV()
		s.Text = "💎 " .. score; b.Text = "💎  КЛИК  +" .. pow
		u.Text = "Улучшить клик (" .. 10 * pow * pow .. ")"
	end
	b = button(c, "", function() score += pow; showV() end, UDim2.new(1, 0, 0, 90))
	b.TextSize = 26
	u = button(c, "", function()
		local cost = 10 * pow * pow
		if score >= cost then score -= cost; pow += 1 end
		showV()
	end, nil, true)
	showV()
end
RUN.timer = function(c)
	local me = c
	local t0, acc, run = 0, 0, false
	local d = label(c, "00:00.0", 50, "text", nil, UDim2.new(1, 0, 0, 90), true, Enum.TextXAlignment.Center)
	local function upd()
		local e = acc + (run and os.clock() - t0 or 0)
		d.Text = string.format("%02d:%04.1f", math.floor(e / 60), e % 60)
	end
	local startB
	startB = button(c, "Старт", function()
		if run then acc += os.clock() - t0; run = false; startB.Text = "Старт"
		else t0 = os.clock(); run = true; startB.Text = "Стоп" end
	end)
	button(c, "Сброс", function() acc = 0; run = false; startB.Text = "Старт"; upd() end, nil, true)
	task.spawn(function() while content == me do upd(); task.wait(0.1) end end)
end

---------------------------------------------------------------- мир: освещение, пост-эффекты
local function fx(class, name, props)
	local o = Lighting:FindFirstChild(name) or new(class, props, Lighting)
	o.Name = name
	return keep(o)
end
local cc = fx("ColorCorrectionEffect", "LauncherCC", {})
local bloom = fx("BloomEffect", "LauncherBloom", {Enabled = false, Size = 28, Threshold = 0.9, Intensity = 0})
local rays = fx("SunRaysEffect", "LauncherRays", {Enabled = false, Intensity = 0.25, Spread = 0.8})
local dof = fx("DepthOfFieldEffect", "LauncherDOF", {Enabled = false, FarIntensity = 0.35, FocusDistance = 35, InFocusRadius = 40, NearIntensity = 0})
local blur = fx("BlurEffect", "LauncherBlur", {Size = 0})
local flash = fx("ColorCorrectionEffect", "LauncherFlash", {})
local CCS = {
	normal = {"Обычный", 0, 0, 0, Color3.new(1, 1, 1)}, warm = {"Тёплый", 0.02, 0.06, 0.18, C(255,232,205)},
	cold = {"Холодный", 0, 0.06, -0.05, C(200,224,255)}, bw = {"Ч/Б", 0, 0.12, -1, Color3.new(1, 1, 1)},
	vivid = {"Яркий", 0, 0.16, 0.6, Color3.new(1, 1, 1)}, cinema = {"Кино", -0.03, 0.28, -0.15, C(228,236,255)},
	sunset = {"Закатный", 0.02, 0.1, 0.25, C(255,196,160)}, noir = {"Нуар", -0.04, 0.45, -1, Color3.new(1, 1, 1)},
}
local CC_ORDER = {"normal", "warm", "cold", "bw", "vivid", "cinema", "sunset", "noir"}
local FOGS = {{orig.fs, orig.fe, orig.fc}, {40, 500, C(205,215,230)}, {20, 220, C(190,200,215)}, {0, 80, C(120,130,150)}}
local function applyWorld()
	local f = FOGS[S.fog + 1]
	if S.bright then Lighting.FogEnd = 1e5 else Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = f[1], f[2], f[3] end
	local c = CCS[S.cc]
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = c[2], c[3], c[4], c[5]
	bloom.Enabled = S.bloom > 0; bloom.Intensity = ({0, 0.8, 1.8})[S.bloom + 1]
	rays.Enabled = S.rays; dof.Enabled = S.dof
	workspace.Gravity = S.grav
	TS:Create(blur, TweenInfo.new(0.3), {Size = (open and S.blurMenu) and 16 or 0}):Play()
end

---------------------------------------------------------------- погода
local function mkPart() return keep(new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	Transparency = 1, Size = Vector3.new(90, 1, 90)}, workspace)) end
local fxTop, fxLow = mkPart(), mkPart()
fxLow.Size = Vector3.new(70, 1, 70)
local WEATHER = {
	rain = {"🌧 Дождь", true, 380, {Lifetime = NR(0.6, 0.7), Speed = NR(65, 80), Size = NS(0.14), Transparency = NS(0.35), Color = ColorSequence.new(C(170,205,255)),
		LightEmission = 0.4, EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(2, 2), Orientation = Enum.ParticleOrientation.VelocityParallel}},
	snow = {"❄️ Снег", true, 170, {Lifetime = NR(7, 9), Speed = NR(3, 5), Size = NS(0.3), Transparency = NS(0.1), Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 0.3, EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), RotSpeed = NR(-40, 40), Acceleration = Vector3.new(1.5, 0, 0.5)}},
	sakura = {"🌸 Сакура", true, 55, {Lifetime = NR(9, 11), Speed = NR(2, 4), Size = NS(0.5), Color = ColorSequence.new(C(255,170,205)),
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(50, 50), Rotation = NR(0, 360), RotSpeed = NR(-120, 120), Acceleration = Vector3.new(2, 0, 1)}},
	leaves = {"🍂 Листья", true, 50, {Lifetime = NR(8, 10), Speed = NR(3, 5), Size = NS(0.55), Color = ColorSequence.new(C(235,140,30), C(170,70,20)),
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(45, 45), Rotation = NR(0, 360), RotSpeed = NR(-150, 150), Acceleration = Vector3.new(3, 0, 1)}},
	confetti = {"🎉 Конфетти", true, 90, {Lifetime = NR(4, 5), Speed = NR(8, 14), Size = NS(0.35), Color = RAINBOW, LightEmission = 0.2,
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(25, 25), Rotation = NR(0, 360), RotSpeed = NR(-200, 200)}},
	fireflies = {"✨ Светлячки", false, 22, {Lifetime = NR(4, 6), Speed = NR(0.5, 2), Size = NS(0.25), Color = ColorSequence.new(C(210,255,120)), LightEmission = 1,
		Transparency = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1)}),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(180, 180)}},
	bubbles = {"🫧 Пузыри", false, 16, {Lifetime = NR(5, 7), Speed = NR(2, 4), Size = NS({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.9)}),
		Transparency = NS(0.55), Color = ColorSequence.new(C(180,225,255)), LightEmission = 0.3, EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(20, 20)}},
	stars = {"🌠 Звездопад", true, 7, {Lifetime = NR(1.2, 1.6), Speed = NR(45, 60), Size = NS(0.6), Color = ColorSequence.new(C(255,245,190)), LightEmission = 1,
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(25, 0, 0)}},
}
local W_ORDER = {"rain", "snow", "sakura", "leaves", "confetti", "fireflies", "bubbles", "stars"}
local emit = {}
for k, d in pairs(WEATHER) do
	local e = new("ParticleEmitter", d[4], d[2] and fxTop or fxLow)
	e.Rate = d[3]; e.Enabled = false
	emit[k] = e
end
local function applyWeather()
	for k, e in pairs(emit) do
		e.Enabled = (k == S.weather)
		e.Rate = WEATHER[k][3] * S.wamt / 2
	end
end
task.spawn(function()
	while alive do
		task.wait(math.random(4, 10))
		if S.weather == "rain" and S.thunder then
			for _ = 1, math.random(1, 2) do
				flash.Brightness = 0.55
				TS:Create(flash, TweenInfo.new(0.35), {Brightness = 0}):Play()
				task.wait(0.25)
			end
		end
	end
end)

---------------------------------------------------------------- эффекты персонажа
local function applyChar()
	local hrp = root()
	if not hrp then return end
	for _, o in ipairs(hrp:GetChildren()) do
		if string.sub(o.Name, 1, 10) == "LauncherFx" then o:Destroy() end
	end
	local acc = ACCENTS[S.acc]
	if S.trail then
		local a0 = new("Attachment", {Name = "LauncherFxA0", Position = Vector3.new(0, 1, 0)}, hrp)
		local a1 = new("Attachment", {Name = "LauncherFxA1", Position = Vector3.new(0, -1, 0)}, hrp)
		new("Trail", {Name = "LauncherFxTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 0.8, LightEmission = 1, Color = RAINBOW,
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if S.aura == "fire" then new("Fire", {Name = "LauncherFxAura", Size = 7, Heat = 9, Color = acc, SecondaryColor = Color3.new(1, 1, 1)}, hrp)
	elseif S.aura == "smoke" then new("Smoke", {Name = "LauncherFxAura", Size = 6, Opacity = 0.35, Color = acc, RiseVelocity = 3}, hrp)
	elseif S.aura == "sparkles" then new("Sparkles", {Name = "LauncherFxAura", SparkleColor = acc}, hrp)
	elseif S.aura == "orbs" then
		new("ParticleEmitter", {Name = "LauncherFxAura", Rate = 22, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NS(0.4),
			LightEmission = 1, Color = ColorSequence.new(acc), Transparency = NS({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if S.glow > 0 then new("PointLight", {Name = "LauncherFxLight", Color = acc, Brightness = ({0, 2, 5})[S.glow + 1], Range = 18}, hrp) end
end
conn(lp.CharacterAdded, function(ch)
	ch:WaitForChild("HumanoidRootPart"); task.wait(0.3)
	flyBV, flyBG = nil, nil; spectating = false
	applyChar()
end)

---------------------------------------------------------------- HUD: FPS, пинг, инжектор (виден всегда)
local hudGui = keep(new("ScreenGui", {Name = "LauncherHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60}, PG))
local hud = new("Frame", {Position = UDim2.fromOffset(12, 12), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), BorderSizePixel = 0, Active = true}, hudGui)
bind(hud, "BackgroundColor3", "bg"); round(hud, 12)
local hudStroke = new("UIStroke", {Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, hud)
bind(hudStroke, "Color", "rim")
local hudLayout = new("UIListLayout", {Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, hud)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7)}, hud)
local hudScale = new("UIScale", {}, hud)
local hudL, hudKeys = {}, {"fps", "ping", "exec", "mem", "time", "players"}
for k, name in ipairs(hudKeys) do
	hudL[name] = new("TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Font = Enum.Font.GothamBold,
		TextSize = 15, Text = "", LayoutOrder = k}, hud)
	bind(hudL[name], "TextColor3", "text")
end
local hpos = Vector2.new(12, 12)
local function clampHud()
	local a, s = hudGui.AbsoluteSize, hud.AbsoluteSize
	hpos = Vector2.new(math.clamp(hpos.X, 0, math.max(0, a.X - s.X)), math.clamp(hpos.Y, 0, math.max(0, a.Y - s.Y)))
	hud.Position = UDim2.fromOffset(hpos.X, hpos.Y)
end
function applyHud()
	hud.Visible = S.hud
	hudLayout.FillDirection = S.hudStack and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	hudLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	hudScale.Scale = S.hudScale
	hud.BackgroundTransparency = S.hudAlpha
	hudL.fps.Visible = S.hudFps; hudL.ping.Visible = S.hudPing; hudL.exec.Visible = S.hudExec
	hudL.mem.Visible = S.hudMem; hudL.time.Visible = S.hudTime; hudL.players.Visible = S.hudPlayers
	task.defer(clampHud)
end
local hdrag = false
hud.InputBegan:Connect(function(i)
	if isPress(i) then
		hdrag = true
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then hdrag = false end end)
	end
end)
local function getPing()
	local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
	if ok and v then return math.floor(v) end
	return math.floor(lp:GetNetworkPing() * 1000)
end
local function getMem()
	local ok, v = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
	return ok and math.floor(v) or 0
end
local GOOD, MID, BAD = C(110,255,140), C(255,215,90), C(255,95,95)
local function updateHud(fps)
	local ping = getPing()
	hudL.fps.Text = "FPS " .. fps
	hudL.ping.Text = "Пинг " .. ping .. " мс"
	hudL.exec.Text = "💉 " .. execName
	hudL.mem.Text = "RAM " .. getMem() .. " МБ"
	hudL.time.Text = os.date("%H:%M:%S")
	hudL.players.Text = "👥 " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
	if S.hudColor then
		hudL.fps.TextColor3 = fps >= 55 and GOOD or (fps >= 30 and MID or BAD)
		hudL.ping.TextColor3 = ping < 80 and GOOD or (ping < 160 and MID or BAD)
	else
		hudL.fps.TextColor3 = col("text"); hudL.ping.TextColor3 = col("text")
	end
end

---------------------------------------------------------------- кнопка открытия (новый дизайн)
local sgui = keep(new("ScreenGui", {Name = "LauncherToggle", ResetOnSpawn = false, DisplayOrder = 70, IgnoreGuiInset = true}, PG))
local tbtn = new("TextButton", {Text = "", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, AutoButtonColor = false}, sgui)
local tbtnE = bind(tbtn, "BackgroundColor3", "acc")
local tscale = new("UIScale", {}, tbtn)
local tcorner = new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, tbtn)
new("UIGradient", {Rotation = 60, Color = ColorSequence.new(Color3.new(1, 1, 1), C(160, 160, 170))}, tbtn)
local tring = new("UIStroke", {Thickness = 3, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, tbtn)
local tringG = new("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1)),
	Transparency = NS({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 0)})}, tring)
local ticon = new("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "📱", Size = UDim2.new(1, 0, 1, 0)}, tbtn)
local tlabel = new("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "Меню", TextColor3 = Color3.new(1, 1, 1),
	Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), Visible = false, TextXAlignment = Enum.TextXAlignment.Left}, tbtn)
local tdot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.86, 0, 0.14, 0), BorderSizePixel = 0, ZIndex = 3}, tbtn)
new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, tdot)
new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, tdot)
local thandle = new("TextButton", {Text = "⤡", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(26, 26), BorderSizePixel = 0, Visible = false, BackgroundColor3 = C(30, 30, 36)}, sgui)
round(thandle, 13)
local tpos, tsnap
local lastTouch = os.clock()
local function btnDims()
	local s = S.btnSize
	if S.btnStyle == "pill" then return s * 2.4, s * 0.75 end
	return s, s
end
function applyButton()
	local a = sgui.AbsoluteSize
	if a.X < 10 then a = workspace.CurrentCamera.ViewportSize end
	local w, h = btnDims()
	tpos = tpos or Vector2.new(a.X - w / 2 - 16, a.Y - h / 2 - 100)
	tpos = Vector2.new(math.clamp(tpos.X, w / 2, a.X - w / 2), math.clamp(tpos.Y, h / 2, a.Y - h / 2))
	tbtn.Size = UDim2.fromOffset(w, h); tbtn.Position = UDim2.fromOffset(tpos.X, tpos.Y)
	local st = S.btnStyle
	tcorner.CornerRadius = st == "square" and UDim.new(0.24, 0) or UDim.new(0.5, 0)
	setRole(tbtnE, st == "ring" and "bg" or "acc")
	tring.Thickness = st == "ring" and 5 or 3
	tring.Enabled = S.btnGlow or st == "ring"
	tringG.Color = S.btnRainbow and RAINBOW or ColorSequence.new(Color3.new(1, 1, 1))
	ticon.Text = S.btnIcon
	if st == "pill" then
		ticon.Size = UDim2.fromOffset(h, h); ticon.TextSize = h * 0.55
		tlabel.Visible = true; tlabel.Position = UDim2.fromOffset(h, 0); tlabel.Size = UDim2.new(1, -h - 6, 1, 0); tlabel.TextSize = h * 0.42
		tlabel.Text = open and "Закрыть" or "Меню"
	else
		ticon.Size = UDim2.new(1, 0, 1, 0); ticon.TextSize = h * 0.5; tlabel.Visible = false
	end
	local d = math.max(11, S.btnSize * 0.22)
	tdot.Size = UDim2.fromOffset(d, d); tdot.Visible = S.btnDot
	tdot.BackgroundColor3 = open and C(70, 230, 110) or C(255, 90, 90)
	thandle.Visible = S.btnHandle
	thandle.Position = UDim2.fromOffset(tpos.X + w / 2 - 2, tpos.Y + h / 2 - 2)
end
local function ripple()
	local w = btnDims()
	local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(tpos.X, tpos.Y), Size = UDim2.fromOffset(w * 0.6, w * 0.6),
		BackgroundColor3 = ACCENTS[S.acc], BackgroundTransparency = 0.4, BorderSizePixel = 0}, sgui)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, r)
	TS:Create(r, TweenInfo.new(0.45), {Size = UDim2.fromOffset(w * 2, w * 2), BackgroundTransparency = 1}):Play()
	task.delay(0.5, function() r:Destroy() end)
end
local tdrag, tmoved, tacc, hbdrag = false, false, Vector2.new(), false
tbtn.MouseEnter:Connect(function() lastTouch = os.clock() end)
tbtn.InputBegan:Connect(function(i)
	if isPress(i) then
		tdrag, tmoved, tacc, tsnap = true, false, Vector2.new(), nil
		lastTouch = os.clock()
		TS:Create(tscale, TweenInfo.new(0.08), {Scale = 0.9}):Play()
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				tdrag = false
				TS:Create(tscale, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
				if not tmoved then
					ripple(); setOpen(not open)
				elseif S.btnSnap then
					local a, w = sgui.AbsoluteSize, btnDims()
					tsnap = Vector2.new(tpos.X < a.X / 2 and (w / 2 + 10) or (a.X - w / 2 - 10), tpos.Y)
				end
			end
		end)
	end
end)
thandle.InputBegan:Connect(function(i)
	if isPress(i) then
		hbdrag = true
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then hbdrag = false end end)
	end
end)

conn(UIS.InputChanged, function(i)
	if not isMove(i) then return end
	local dx, dy = i.Delta.X, i.Delta.Y
	if tdrag then
		tacc += Vector2.new(dx, dy)
		if tacc.Magnitude > 6 then tmoved = true end
		if tmoved then tpos += Vector2.new(dx, dy); applyButton() end
	end
	if hbdrag then S.btnSize = math.clamp(S.btnSize + (dx + dy) / 2, 36, 140); applyButton() end
	if hdrag then hpos += Vector2.new(dx, dy); clampHud() end
	if drag then
		local cam = workspace.CurrentCamera
		local k = 2 * dist * math.tan(math.rad(cam.FieldOfView) / 2) / cam.ViewportSize.Y
		if S.detach and P[drag] then
			local p = P[drag]
			p.dx = math.clamp(p.dx + dx * k, -9, 9); p.dy = math.clamp(p.dy - dy * k, -6, 6)
		else
			offX = math.clamp(offX + dx * k, -8, 8); offY = math.clamp(offY - dy * k, -5, 5)
		end
	end
end)

---------------------------------------------------------------- настройки (вкладки-категории)
local setPage = scrollPage("set")
local setCat = "ui"
local CATS = {{"ui", "🎨 Вид"}, {"d3", "🧊 Меню 3D"}, {"btn", "🔘 Кнопка"}, {"hud", "📊 HUD"}, {"func", "⚙️ Функции"},
	{"wx", "🌧 Погода"}, {"world", "🌍 Мир"}, {"hero", "🧍 Персонаж"}, {"keys", "⌨️ Клавиши"}}
local listening = nil
local KEYDEF = {{"menu", "Меню"}, {"fly", "Полёт"}, {"noclip", "Ноуклип"}, {"esp", "ESP"}, {"hud", "HUD"}}

function applyAll()
	applyView(); applyButton(); applyHud(); applyWorld(); applyWeather(); applyChar(); applyFunctions(); applyTheme()
	if S.rim == "off" then for _, st in ipairs(rimStrokes) do st.Transparency = 0.35 end end
end

function drawSettings()
	local c = setPage
	reset(c)
	local cd = {}
	for _, k in ipairs(CATS) do cd[#cd + 1] = {k[2], function() setCat = k[1]; drawSettings() end, setCat ~= k[1]} end
	chunk(c, cd, 3)

	if setCat == "ui" then
		head(c, "Тема")
		local th = {}
		for _, name in ipairs(THEME_ORDER) do th[#th + 1] = {name, function() S.theme = name; applyAll(); drawSettings() end, S.theme ~= name} end
		chunk(c, th, 4)
		head(c, "Цвет акцента")
		local ar = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, ar)
		for k, color in ipairs(ACCENTS) do
			local b = new("TextButton", {Text = S.acc == k and "✓" or "", TextSize = 18, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0, 0, 0),
				BackgroundColor3 = color, Size = UDim2.fromOffset(38, 38), BorderSizePixel = 0}, ar)
			round(b, 19)
			b.Activated:Connect(function() S.acc = k; applyAll(); drawSettings() end)
		end
		head(c, "Вид приложений"); row(c, {opt("Сетка", "view", "grid"), opt("Список", "view", "list")})
		head(c, "Форма значков"); row(c, {opt("Скруглённые", "shape", "round"), opt("Круг", "shape", "circle"), opt("Квадрат", "shape", "square")})
		head(c, "Размер значков"); row(c, {opt("S", "size", "S"), opt("M", "size", "M"), opt("L", "size", "L")})
		head(c, "Прозрачность панелей"); row(c, {opt("0%", "alpha", 0), opt("15%", "alpha", 0.15), opt("30%", "alpha", 0.3), opt("50%", "alpha", 0.5)})
		head(c, "Рамка панелей"); row(c, {opt("Обычная", "rim", "off"), opt("Радуга", "rim", "rainbow"), opt("Пульс", "rim", "pulse")})
		head(c, "Прочее")
		row(c, {tog("Подписи", "labels"), tog("Виджеты", "widgets")})
		row(c, {tog("Градиент панелей", "grad"), tog("Анимация кнопок", "hover")})

	elseif setCat == "d3" then
		stepRow(c, "Масштаб меню (клавиши + и −)", "zoom", 0.1, 0.5, 2, pct)
		head(c, "Наклон меню")
		row(c, {opt("0°", "tilt", 0), opt("12°", "tilt", 12), opt("22°", "tilt", 22), opt("32°", "tilt", 32), opt("45°", "tilt", 45)})
		head(c, "Разнос панелей"); row(c, {opt("0", "spread", 0), opt("1", "spread", 1), opt("2", "spread", 2), opt("3", "spread", 3)})
		head(c, "Глубина (панели на разном расстоянии)"); row(c, {opt("0", "depth", 0), opt("1", "depth", 1), opt("2", "depth", 2), opt("3", "depth", 3)})
		head(c, "Отдельные панели")
		row(c, {tog("Отделить панели", "detach"), {"Собрать панели", function()
			for _, p in ipairs(panels) do p.dx, p.dy = 0, 0 end
			S.spread, S.depth, S.detach = 0, 0, false
			applyAll(); drawSettings()
		end, true}})
		head(c, "Прочее")
		row(c, {tog("Наклон за мышью", "parallax"), tog("Размытие мира", "blurMenu")})
		row(c, {{"Меню в центр", function() offX, offY = 0, 0 end, true}})
		head(c, "Поле зрения камеры")
		row(c, {{"50", function() S.fov = 50 end, true}, {"70", function() S.fov = 70 end, true}, {"90", function() S.fov = 90 end, true},
			{"110", function() S.fov = 110 end, true}, {"Свой", function() S.fov = nil end, true}})

	elseif setCat == "btn" then
		head(c, "Стиль кнопки")
		row(c, {opt("Орб", "btnStyle", "orb"), opt("Пилюля", "btnStyle", "pill"), opt("Квадрат", "btnStyle", "square"), opt("Кольцо", "btnStyle", "ring")})
		stepRow(c, "Размер", "btnSize", 8, 36, 140, pxf)
		head(c, "Значок")
		local ic = {}
		for _, e in ipairs({"📱", "🎮", "⚙️", "✨", "🌈", "☰", "🚀", "💎"}) do ic[#ic + 1] = opt(e, "btnIcon", e) end
		chunk(c, ic, 4)
		head(c, "Прозрачность"); row(c, {opt("0%", "btnAlpha", 0), opt("25%", "btnAlpha", 0.25), opt("50%", "btnAlpha", 0.5)})
		head(c, "Вращение кольца"); row(c, {opt("Стоп", "btnSpin", 0), opt("Медленно", "btnSpin", 1), opt("Быстро", "btnSpin", 2)})
		head(c, "Эффекты")
		row(c, {tog("Свечение", "btnGlow"), tog("Радуга", "btnRainbow")})
		row(c, {tog("К краю экрана", "btnSnap"), tog("Гаснет без дела", "btnFade")})
		row(c, {tog("Ручка размера", "btnHandle"), tog("Точка статуса", "btnDot")})
		label(c, "Кнопку можно тянуть в любое место экрана. Ручка ⤡ (снизу справа от кнопки) меняет размер.", 13, "sub", nil, UDim2.new(1, 0, 0, 40))
		row(c, {{"Вернуть в угол", function() tpos = nil; applyButton() end, true}})

	elseif setCat == "hud" then
		row(c, {tog("HUD", "hud")})
		head(c, "Что показывать")
		row(c, {tog("FPS", "hudFps"), tog("Пинг", "hudPing")})
		row(c, {tog("Инжектор", "hudExec"), tog("Память", "hudMem")})
		row(c, {tog("Время", "hudTime"), tog("Игроки", "hudPlayers")})
		head(c, "Вид")
		row(c, {opt("В строку", "hudStack", false), opt("Столбиком", "hudStack", true)})
		stepRow(c, "Масштаб", "hudScale", 0.1, 0.6, 2, pct)
		head(c, "Прозрачность фона"); row(c, {opt("0%", "hudAlpha", 0), opt("25%", "hudAlpha", 0.25), opt("50%", "hudAlpha", 0.5), opt("75%", "hudAlpha", 0.75)})
		row(c, {tog("Цвет по качеству (зелёный/жёлтый/красный)", "hudColor")})
		label(c, "Инжектор: " .. execName .. ". Панель видна всегда, меню открыто оно или нет, и тянется по экрану.", 13, "sub", nil, UDim2.new(1, 0, 0, 40))
		row(c, {{"Вернуть HUD в угол", function() hpos = Vector2.new(12, 12); clampHud() end, true}})

	elseif setCat == "func" then
		head(c, "Движение")
		row(c, {tog("Полёт", "fly"), tog("Ноуклип", "noclip")})
		row(c, {tog("Беск. прыжок", "ijump"), tog("ТП по клику", "clicktp")})
		row(c, {tog("Держать скорость", "holdSpeed"), tog("Держать прыжок", "holdJump")})
		stepRow(c, "Скорость полёта", "flySpeed", 10, 10, 300, num)
		stepRow(c, "Скорость ходьбы", "speedVal", 4, 0, 500, num)
		stepRow(c, "Сила прыжка", "jumpVal", 10, 0, 800, num)
		head(c, "Обзор")
		row(c, {tog("ESP", "esp"), tog("Яркость", "bright")})
		row(c, {tog("Имена", "espNames"), tog("Дистанция", "espDist")})
		row(c, {tog("Здоровье", "espHp"), tog("Цвет команды", "espTeam")})
		stepRow(c, "Прозрачность заливки ESP", "espFill", 0.1, 0, 1, pct)
		stepRow(c, "Дальность ESP", "espMax", 250, 250, 5000, function(v) return v .. " м" end)
		head(c, "Камера и прочее")
		row(c, {tog("Отдалять без лимита", "zoomUnlock"), tog("Первое лицо", "fpLock")})
		row(c, {tog("Автоклик", "aclick"), tog("Анти-АФК", "antiafk")})
		stepRow(c, "Кликов в секунду", "acps", 1, 1, 30, num)
		row(c, {tog("Прицел", "cross"), tog("Буст FPS", "boost")})

	elseif setCat == "wx" then
		head(c, "Погода вокруг тебя")
		local w = {opt("🚫 Нет", "weather", "none")}
		for _, k in ipairs(W_ORDER) do w[#w + 1] = opt(WEATHER[k][1], "weather", k) end
		chunk(c, w, 3)
		stepRow(c, "Интенсивность", "wamt", 1, 1, 4, function(v) return tostring(v) .. " из 4" end)
		head(c, "Туман")
		row(c, {opt("Нет", "fog", 0), opt("Лёгкий", "fog", 1), opt("Густой", "fog", 2), opt("Жуть", "fog", 3)})
		row(c, {tog("Молнии (при дожде)", "thunder")})

	elseif setCat == "world" then
		head(c, "Цветокоррекция")
		local cs = {}
		for _, k in ipairs(CC_ORDER) do cs[#cs + 1] = opt(CCS[k][1], "cc", k) end
		chunk(c, cs, 4)
		head(c, "Свечение (блум)"); row(c, {opt("Выкл", "bloom", 0), opt("Мягкое", "bloom", 1), opt("Сильное", "bloom", 2)})
		row(c, {tog("Лучи солнца", "rays"), tog("Размытие дали", "dof")})
		head(c, "Смена дня и ночи")
		row(c, {opt("Выкл", "cycle", 0), opt("Медленно", "cycle", 1), opt("Средне", "cycle", 2), opt("Быстро", "cycle", 3)})
		head(c, "Гравитация")
		row(c, {opt("Луна", "grav", 40), opt("Обычная", "grav", orig.grav), opt("Тяжёлая", "grav", 320)})

	elseif setCat == "hero" then
		head(c, "След за персонажем"); row(c, {tog("Радужный след", "trail")})
		head(c, "Аура")
		row(c, {opt("Нет", "aura", "none"), opt("🔥 Огонь", "aura", "fire"), opt("💨 Дым", "aura", "smoke")})
		row(c, {opt("✨ Искры", "aura", "sparkles"), opt("🔮 Сферы", "aura", "orbs")})
		head(c, "Свечение вокруг")
		row(c, {opt("Нет", "glow", 0), opt("Слабое", "glow", 1), opt("Сильное", "glow", 2)})
		label(c, "Цвет ауры и света берётся из цвета акцента.", 13, "sub", nil, UDim2.new(1, 0, 0, 24))

	elseif setCat == "keys" then
		head(c, "Нажми на кнопку, затем нужную клавишу (Esc отмена)")
		for _, k in ipairs(KEYDEF) do
			row(c, {{k[2] .. ": " .. (listening == k[1] and "нажми клавишу…" or S.keys[k[1]]), function() listening = k[1]; drawSettings() end, listening ~= k[1]}})
		end
		row(c, {{"Сбросить клавиши", function() S.keys = {menu = "L", fly = "F", noclip = "N", esp = "K", hud = "H"}; listening = nil; drawSettings() end, true}})
		label(c, "Масштаб меню: клавиши «+» и «−».", 13, "sub", nil, UDim2.new(1, 0, 0, 24))
	end
end

---------------------------------------------------------------- главный цикл
local CYCLE = {0.05, 0.25, 1.2}
local fps, facc, fn = 60, 0, 0
local curA = 0
conn(RS.RenderStepped, function(dt)
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	facc += dt; fn += 1
	if facc >= 0.5 then fps = math.floor(fn / facc); facc, fn = 0, 0 end
	if S.fov then cam.FieldOfView = S.fov end
	local fp = cam.Focus.Position
	fxTop.CFrame = CFrame.new(fp + Vector3.new(0, 38, 0)); fxLow.CFrame = CFrame.new(fp + Vector3.new(0, -2, 0))
	if S.cycle > 0 then Lighting.ClockTime = (Lighting.ClockTime + dt * CYCLE[S.cycle]) % 24 end
	local t = os.clock()
	-- анимация рамок панелей
	if S.rim == "rainbow" then
		for k, st in ipairs(rimStrokes) do st.Color = Color3.fromHSV((t * 0.12 + k * 0.1) % 1, 0.65, 1); st.Transparency = 0.2 end
	elseif S.rim == "pulse" then
		for _, st in ipairs(rimStrokes) do st.Transparency = 0.15 + 0.4 * (0.5 + 0.5 * math.sin(t * 3)) end
	end
	-- кнопка: вращающееся кольцо, свечение, притягивание к краю, затухание
	tringG.Rotation = (t * ({0, 90, 240})[S.btnSpin + 1]) % 360
	if S.btnGlow and S.btnStyle ~= "ring" then tring.Thickness = 3 + 1.5 * (0.5 + 0.5 * math.sin(t * 2.5)) end
	if tsnap then
		tpos = tpos:Lerp(tsnap, 1 - math.exp(-dt * 14))
		if (tpos - tsnap).Magnitude < 0.5 then tpos = tsnap; tsnap = nil end
		applyButton()
	end
	local idle = S.btnFade and not tdrag and not open and (t - lastTouch) > 3
	local base = S.btnStyle == "ring" and math.max(0.7, S.btnAlpha) or S.btnAlpha
	local target = idle and math.clamp(base + 0.5, 0, 0.92) or base
	curA += (target - curA) * math.min(1, dt * 6)
	tbtn.BackgroundTransparency = curA
	ticon.TextTransparency = idle and 0.5 or 0
	tlabel.TextTransparency = idle and 0.5 or 0
	if not open then return end
	-- 3D-меню
	animT = math.min(1, animT + dt / 0.4)
	local ease = 1 - (1 - animT) ^ 3
	local th = math.tan(math.rad(cam.FieldOfView) / 2)
	dist = math.max(MW / (2 * th * (vp.X / vp.Y) * 0.92), MH / (2 * th * 0.88)) / S.zoom
	local d = dist * (1 + 0.4 * (1 - ease))
	local px, py = 0, 0
	if S.parallax then
		local m = UIS:GetMouseLocation()
		px = math.clamp(m.X / vp.X - 0.5, -0.5, 0.5); py = math.clamp(m.Y / vp.Y - 0.5, -0.5, 0.5)
	end
	local target3 = cam.CFrame * CFrame.new(offX, offY, -d) * CFrame.Angles(0, math.pi, 0)
		* CFrame.Angles(math.rad(py * 5), math.rad(S.tilt + px * 8), 0)
	rootCF = rootCF and rootCF:Lerp(target3, math.min(1, dt * 14)) or target3
	local f = 1 + 0.06 * S.spread
	for _, p in ipairs(panels) do
		p.part.CFrame = rootCF * CFrame.new(-(p.lx * f + p.dx), p.ly * f + p.dy, -(p.zf * S.depth))
	end
end)

task.spawn(function()
	while alive do
		updateHud(fps)
		if open then
			wv[1].Text = os.date("%H:%M:%S"); wv[11].Text = os.date("%d.%m.%Y")
			wv[2].Text = string.sub(lp.DisplayName, 1, 9); wv[12].Text = "Игроков: " .. #Players:GetPlayers()
			wv[3].Text = tostring(fps); wv[13].Text = "кадров/с"
			wv[4].Text = getPing() .. " мс"; wv[14].Text = "задержка"
			wv[5].Text = execName; wv[15].Text = "запуск"
		end
		task.wait(0.5)
	end
end)

function setOpen(v)
	open = v
	drag = nil
	for _, p in ipairs(panels) do
		p.part.Parent = v and workspace or nil
		p.sg.Enabled = v
	end
	rootCF = nil; animT = 0
	applyWorld(); applyButton()
end

local function zoomBy(d)
	S.zoom = math.clamp(math.floor((S.zoom + d) * 100 + 0.5) / 100, 0.5, 2)
	if setCat == "d3" then drawSettings() end
end
conn(UIS.InputBegan, function(i, gp)
	if listening and i.UserInputType == Enum.UserInputType.Keyboard then
		if i.KeyCode ~= Enum.KeyCode.Escape then S.keys[listening] = i.KeyCode.Name end
		listening = nil; drawSettings()
		return
	end
	if gp then return end
	local k = i.KeyCode
	if k.Name == S.keys.menu then setOpen(not open)
	elseif k.Name == S.keys.fly then S.fly = not S.fly; applyAll()
	elseif k.Name == S.keys.noclip then S.noclip = not S.noclip; applyAll()
	elseif k.Name == S.keys.esp then S.esp = not S.esp; applyAll()
	elseif k.Name == S.keys.hud then S.hud = not S.hud; applyAll()
	elseif open and (k == Enum.KeyCode.Equals or k == Enum.KeyCode.KeypadPlus) then zoomBy(0.1)
	elseif open and (k == Enum.KeyCode.Minus or k == Enum.KeyCode.KeypadMinus) then zoomBy(-0.1) end
end)

---------------------------------------------------------------- очистка при повторном запуске
ENV.__Launcher3D_cleanup = function()
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	stopFly()
	for p in pairs(ncOrig) do if p.Parent then p.CanCollide = true end end
	for _, o in ipairs(junk) do pcall(function() o:Destroy() end) end
	pcall(function()
		Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = orig.fs, orig.fe, orig.fc
		Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = orig.B, orig.A, orig.OA, orig.GS
		workspace.Gravity = orig.grav
		lp.CameraMaxZoomDistance = orig.maxZ
		lp.CameraMode = Enum.CameraMode.Classic
	end)
	local hrp = root()
	if hrp then for _, o in ipairs(hrp:GetChildren()) do if string.sub(o.Name, 1, 10) == "LauncherFx" then o:Destroy() end end end
end

task.defer(applyChar)
drawSettings()
applyAll()
show("home")
setOpen(true)

--[[ VISUALESERED — ВСЁ В ОДНОМ СКРИПТЕ (канал: https://t.me/Visualesered)
     Автосохранение: L3D_autosave.json | чат: L3D_chat.json | плейлист: L3D_music.json
     Чат/друзья/онлайн работают через свой сервер (файл l3d_server.js), адрес вводится в приложении «Чат». ]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local MPS = game:GetService("MarketplaceService")
local GS = game:GetService("GuiService")
local lp = Players.LocalPlayer
local PG = lp:WaitForChild("PlayerGui")

---------------------------------------------------------------- защита от двойного запуска + очистка
local ENV = (getgenv and getgenv()) or _G
if ENV.__Launcher3D_cleanup then pcall(ENV.__Launcher3D_cleanup) end
local conns, junk, alive = {}, {}, true
local M = {cleanup = {}}
local DEFAULT_SERVER = "" -- впиши сюда адрес своего сервера один раз: тогда его не нужно вводить в игре
local function conn(sig, fn) local c = sig:Connect(fn); conns[#conns + 1] = c; return c end
local function keep(o) junk[#junk + 1] = o; return o end

do -- ЭКРАН ЗАГРУЗКИ: прогресс привязан к реальным этапам запуска
	local t = os.date("*t")
	local hw = t.month == 10 or (t.month == 11 and t.day <= 7)
	local gui = keep(Instance.new("ScreenGui"))
	gui.Name = "VisualeseredLoading"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 1000; gui.Parent = PG
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local bg = mk("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = hw and Color3.fromRGB(26, 12, 34) or Color3.fromRGB(10, 12, 22)}, gui)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(hw and Color3.fromRGB(70, 24, 10) or Color3.fromRGB(20, 32, 64), Color3.fromRGB(8, 8, 14))}, bg)
	if hw then
		for i = 1, 14 do
			local l = mk("TextLabel", {BackgroundTransparency = 1, Text = ({"🎃", "👻", "🦇", "🕷"})[i % 4 + 1], TextSize = 28 + (i % 3) * 10, TextTransparency = 0.4,
				Position = UDim2.fromScale((i * 0.071) % 1, -0.1), Size = UDim2.fromOffset(60, 60)}, bg)
			task.spawn(function()
				task.wait(i * 0.15)
				while l.Parent do
					l.Position = UDim2.fromScale((i * 0.071) % 1, -0.1)
					TS:Create(l, TweenInfo.new(5 + (i % 4), Enum.EasingStyle.Linear), {Position = UDim2.fromScale((i * 0.071) % 1, 1.1)}):Play()
					task.wait(5 + (i % 4))
				end
			end)
		end
	end
	local title = mk("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(640, 84),
		Font = Enum.Font.GothamBold, TextSize = 58, Text = "Visualesered", TextColor3 = Color3.new(1, 1, 1)}, bg)
	local tg = mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)), ColorSequenceKeypoint.new(0.5, hw and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(190, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255))})}, title)
	local sub = mk("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(500, 24),
		Font = Enum.Font.GothamMedium, TextSize = 16, Text = "Запуск…", TextColor3 = Color3.fromRGB(180, 188, 205)}, bg)
	local bar = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromOffset(380, 10), BackgroundColor3 = Color3.fromRGB(40, 44, 60), BorderSizePixel = 0}, bg)
	mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, bar)
	local fill = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, bar)
	mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
	mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(90, 170, 255), hw and Color3.fromRGB(255, 130, 30) or Color3.fromRGB(190, 110, 255))}, fill)
	local pctL = mk("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.625), Size = UDim2.fromOffset(100, 20), Font = Enum.Font.GothamBold, TextSize = 14, Text = "0%", TextColor3 = Color3.new(1, 1, 1)}, bg)
	local tip = mk("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.94), Size = UDim2.fromOffset(640, 40), Font = Enum.Font.GothamMedium, TextSize = 14,
		Text = "", TextColor3 = Color3.fromRGB(150, 158, 178), TextWrapped = true}, bg)
	mk("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromOffset(400, 18), Font = Enum.Font.Gotham, TextSize = 12,
		Text = "t.me/Visualesered", TextColor3 = Color3.fromRGB(110, 118, 140)}, bg)
	local TIPS = {"Зажми значок и перетащи на другой: они поменяются местами", "Бинды можно вывести на экран: Настройки → HUD → Бинды на экране", "Питомцы и косметика покупаются в магазине за монеты",
		"Монеты и XP идут за время в игре и ежедневный вход", "Все настройки можно выгрузить кодом: Настройки → Конфиг и сеть"}
	task.spawn(function() local i = 0; while bg.Parent do i += 1; tip.Text = "💡 " .. TIPS[i % #TIPS + 1]; task.wait(2.2) end end)
	local cur, target = 0, 0
	local rc = RS.RenderStepped:Connect(function(dt)
		cur += (target - cur) * math.min(1, dt * 8)
		fill.Size = UDim2.new(math.clamp(cur / 100, 0, 1), 0, 1, 0); pctL.Text = math.floor(cur) .. "%"; tg.Rotation = (os.clock() * 60) % 360
	end)
	M.load = function(p, text)
		target = p
		if text then sub.Text = text end
		if p >= 100 then
			task.delay(0.9, function()
				for _, d in ipairs(gui:GetDescendants()) do
					pcall(function()
						if d:IsA("TextLabel") then TS:Create(d, TweenInfo.new(0.6), {TextTransparency = 1}):Play() end
						if d:IsA("Frame") then TS:Create(d, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play() end
					end)
				end
				task.wait(0.7); rc:Disconnect(); pcall(function() gui:Destroy() end)
			end)
		end
		task.wait(0.07)
	end
	task.delay(45, function() pcall(function() rc:Disconnect(); gui:Destroy() end) end)
end

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
	["Золото"] = {bg = Color3.fromRGB(30,24,10), card = Color3.fromRGB(56,44,16), card2 = Color3.fromRGB(86,68,22), text = Color3.fromRGB(255,244,205), sub = Color3.fromRGB(210,180,110), rim = Color3.fromRGB(255,205,70)},
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
	alpha = 0, grad = false, rim = "off", hover = true, gold = false, iconPos = {},
	-- 3D-меню
	tilt = 22, zoom = 1, spread = 0, depth = 0, detach = false, parallax = true, blurMenu = false, openAnim = "zoom",
	-- кнопка открытия
	btnStyle = "orb", btnSize = 60, btnIcon = "📱", btnAlpha = 0, btnGlow = true, btnRainbow = false, btnSpin = 1,
	btnSnap = true, btnFade = true, btnHandle = false, btnDot = true, btnPosX = 20, btnPosY = 100,
	-- HUD
	hud = true, hudFps = true, hudPing = true, hudExec = true, hudMem = false, hudTime = false, hudPlayers = false,
	hudStack = false, hudScale = 1, hudAlpha = 0.25, hudColor = true, hudPosX = 12, hudPosY = 12,
	-- погода и мир
	weather = "none", wamt = 2, thunder = false, fog = 0,
	cc = "normal", bloom = 0, rays = false, dof = false, cycle = 0, grav = workspace.Gravity,
	-- персонаж
	trail = false, aura = "none", glow = 0, jumpFx = false, jumpFxStyle = "ring",
	orbit = "none", orbitN = 12, orbitR = 4, orbitSpeed = 1, orbitSize = 0.4, orbitColor = 0,
	-- функции
	fly = false, flySpeed = 60, noclip = false, ijump = false,
	speedVal = 16, holdSpeed = false, jumpVal = 50, holdJump = false,
	clicktp = false, esp = false, espNames = true, espDist = true, espHp = true, espTeam = false, espFill = 0.6, espMax = 1500,
	espWalls = true, espOutline = 0, espChams = true, espColorMode = "acc", showTags = true,
	bright = false, zoomUnlock = false, fpLock = false,
	cross = false, chStyle = "cross", chSize = 14, chGap = 5, chThick = 2, chColor = 1,
	aclick = false, acps = 10, antiafk = true, boost = false,
	keys = {menu = "L", fly = "F", noclip = "N", esp = "K", hud = "H", fp = "V", tpv = "B", drone = "G", tpto = "T", aclick = "J", noPart = "P", photo = "O", freecam = "U", mini = "M"},
	-- дрон
	drone = false, droneSpeed = 90, droneFov = 105, droneGlitch = 1, droneOsd = true,
	-- визуалы
	vfx = {}, vfxP = {}, vfxMedia = "",
	-- звук и музыка
	sound = true, uiClick = false, mVol = 0.6, mLoop = "all", mShuffle = false,
	lyricOn = true, popOn = true, lyricStyle = "pop", lyricSize = 34, lyricY = 0.82, lyricColor = 1, lyricFont = "GothamBold",
	-- профиль и сеть
	xp = 0, playMin = 0, status = "", privacy = "all", frame = "ring", avatarUrl = "", showGame = true,
	chatUrl = "", deviceDone = false, coins = 0, owned = {}, badge = "", nameColor = 0, profBg = 0, rankName = "", grantedRole = "", adminGranted = false, lastDaily = "", autoLyrics = true,
	wx = {}, auras = {}, jumpSet = {}, orbits = {}, migrated = false,
	tpLock = false, tpMode = "ctrl", antiFling = false,
	droneCrash = "hurt", droneHurt = 60, droneProps = false, droneFull = false,
	espBox = false, espTracer = false, espBar = false, espTextSize = 14, espNameColor = 1, espOutColor = 1, espFillColor = 0, espTeamCheck = false,
	espFriend = false, espBoxTrans = 0.6, espTracerFrom = "bottom", espTracerThick = 1,
}

local SAVEFILE = "L3D_" .. lp.UserId .. "_autosave.json"
local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) else dst[k] = v end
	end
end
local function clean(v, d)
	d = d or 0
	local t = type(v)
	if t == "number" or t == "string" or t == "boolean" then return v end
	if t == "table" and d < 4 then
		local o = {}
		for k, x in pairs(v) do
			local cx = clean(x, d + 1)
			if cx ~= nil and (type(k) == "string" or type(k) == "number") then o[k] = cx end
		end
		return o
	end
	return nil
end
if readfile and isfile and isfile(SAVEFILE) then
	pcall(function() merge(S, HS:JSONDecode(readfile(SAVEFILE))) end)
end
S.fly, S.drone, S.noclip = false, false, false
if not S.migrated then
	S.migrated = true
	if S.weather and S.weather ~= "none" then S.wx[S.weather] = true end
	if S.aura and S.aura ~= "none" then S.auras[S.aura] = true end
	if S.jumpFx then S.jumpSet[S.jumpFxStyle or "ring"] = true end
	if S.orbit and S.orbit ~= "none" then S.orbits[S.orbit] = true end
end
if not THEMES[S.theme] then S.theme = "Тёмная" end

local isDirty = false
task.spawn(function()
	while alive do
		task.wait(5)
		if isDirty and writefile then
			isDirty = false
			pcall(function() writefile(SAVEFILE, HS:JSONEncode(clean(S))) end)
		end
	end
end)

---------------------------------------------------------------- устройство
local vpInit = workspace.CurrentCamera.ViewportSize
local isTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local deviceName = (not isTouch) and "ПК" or (math.min(vpInit.X, vpInit.Y) < 520 and "Телефон" or "Планшет")
local PERF = deviceName == "ПК" and 1 or 0.5
if not S.deviceDone then
	S.deviceDone = true
	if deviceName == "Телефон" then
		S.size = "L"; S.hudScale = 0.8; S.btnSize = 64; S.parallax = false
	elseif deviceName == "Планшет" then
		S.size = "M"; S.hudScale = 0.9; S.btnSize = 60; S.parallax = false
	end
end

---------------------------------------------------------------- цвета и привязка к теме
local function col(role)
	if role == "acc" then return ACCENTS[S.acc] end
	if role == "white" then return Color3.new(1, 1, 1) end
	return (THEMES[S.theme] or THEMES["Тёмная"])[role]
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
local function tap(b, fn)
	b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then fn() end end)
	b.Activated:Connect(function(i) if i and i.UserInputType == Enum.UserInputType.Touch then fn() end end)
end
local clickSnd = keep(new("Sound", {Name = "LauncherClick", SoundId = "rbxasset://sounds/switch.mp3", Volume = 0.4}, SoundService))
local function button(par, text, cb, size, neutral)
	local b = new("TextButton", {Text = text, TextSize = 16, TextScaled = true, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
		Size = size or UDim2.new(1, 0, 0, 40), BorderSizePixel = 0}, par)
	new("UITextSizeConstraint", {MaxTextSize = 16, MinTextSize = 8}, b)
	new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)}, b)
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
	tap(b, function()
		if S.uiClick and S.sound then pcall(function() clickSnd:Play() end) end
		local ok, e = pcall(cb)
		if not ok then warn("[L3D] " .. tostring(e)) end
	end)
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
local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local PALETTE = {C(255,255,255), C(255,60,60), C(255,160,40), C(255,235,60), C(70,255,120), C(60,220,255), C(80,140,255), C(190,100,255), C(255,80,200), C(0,0,0)}
local function pcolor(idx, t, off)
	if idx == 0 then return ACCENTS[S.acc] end
	if idx < 0 then return Color3.fromHSV(((t or os.clock()) * 0.15 + (off or 0)) % 1, 0.7, 1) end
	return PALETTE[idx] or PALETTE[1]
end

local function textbox(par, ph, text, h, multi)
	local tb = new("TextBox", {Size = UDim2.new(1, 0, 0, h or 38), Text = text or "", PlaceholderText = ph, ClearTextOnFocus = false,
		MultiLine = multi or false, TextWrapped = multi or false, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, TextSize = 15, Font = Enum.Font.Gotham, BorderSizePixel = 0}, par)
	bind(tb, "BackgroundColor3", "card"); bind(tb, "TextColor3", "text"); bind(tb, "PlaceholderColor3", "sub")
	round(tb, 10)
	new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, multi and 8 or 0)}, tb)
	return tb
end

-- уведомления
local toastGui = keep(new("ScreenGui", {Name = "LauncherToast", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 90}, PG))
local toastList = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.new(0, 380, 1, -20), BackgroundTransparency = 1}, toastGui)
new("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, toastList)
local function toast(text, secs, actions)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, actions and 84 or 46), BorderSizePixel = 0, BackgroundTransparency = 0.08}, toastList)
	bind(f, "BackgroundColor3", "card"); round(f, 12)
	bind(new("UIStroke", {Thickness = 1.5, Transparency = 0.35}, f), "Color", "acc")
	label(f, text, 14, "text", UDim2.new(0, 12, 0, 4), UDim2.new(1, -24, 0, 38), true)
	if actions then
		local r = new("Frame", {Position = UDim2.new(0, 8, 1, -38), Size = UDim2.new(1, -16, 0, 32), BackgroundTransparency = 1}, f)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, r)
		for _, a in ipairs(actions) do
			button(r, a[1], function() pcall(function() f:Destroy() end); a[2]() end, UDim2.new(1 / #actions, -6, 1, 0), a[3])
		end
	end
	task.delay(secs or (actions and 20 or 3.5), function() pcall(function() f:Destroy() end) end)
	return f
end
M.toast = toast
M.notifs = {}
function M.notify(text, secs, actions)
	table.insert(M.notifs, 1, {t = text, ts = os.time()})
	if #M.notifs > 40 then M.notifs[41] = nil end
	if S.notifOn ~= false then return toast(text, secs, actions) end
end

-- загрузка картинок / аудио / видео по ссылке (нужен writefile + getcustomasset)
local function hash(s) local h = 5381; for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end; return tostring(h) end
local function fetchAsset(url, ext)
	if url:match("^%d+$") then return "rbxassetid://" .. url end
	if url:match("^rbxasset") then return url end
	if not (getcustomasset and writefile and isfile) then return nil, "инжектор не поддерживает getcustomasset/writefile" end
	if isfile(url) then return getcustomasset(url) end
	if not url:match("^https?://") then return nil, "это не ссылка и не ID" end
	if makefolder and isfolder and not isfolder("L3D_cache") then makefolder("L3D_cache") end
	local path = "L3D_cache/" .. hash(url) .. "." .. (ext or url:lower():match("%.(%w+)$") or "dat")
	if not isfile(path) then
		local data
		local rq = request or http_request or (syn and syn.request)
		if rq then
			local ok, res = pcall(rq, {Url = url, Method = "GET"})
			if ok and res and res.StatusCode == 200 then data = res.Body end
		end
		if not data then
			local ok, d = pcall(function() return game:HttpGet(url) end)
			if ok then data = d end
		end
		if not data or #data < 100 then return nil, "не удалось скачать файл" end
		writefile(path, data)
	end
	return getcustomasset(path)
end

-- РОЛИ ПО НИКУ (работают без сервера). Допиши ники в списки.
local ROLES_BY_NAME = {creator = {"jeka_5670"}, tester = {}, helper = {}, rank = {}}
local function roleOfName(name)
	name = tostring(name):lower()
	for role, list in pairs(ROLES_BY_NAME) do for _, n in ipairs(list) do if n:lower() == name then return role end end end
end
M.isAdmin = function()
	return roleOfName(lp.Name) == "creator" or S.adminGranted or (M.NET and (M.NET.role == "admin" or M.NET.role == "owner")) or false
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64R = {}
for i = 1, 64 do B64R[B64:byte(i)] = i - 1 end
local function b64e(s)
	local out = {}
	for i = 1, #s, 3 do
		local x, y, z = s:byte(i, i + 2)
		local n = x * 65536 + (y or 0) * 256 + (z or 0)
		local c1, c2, c3, c4 = n // 262144 % 64, n // 4096 % 64, n // 64 % 64, n % 64
		out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1) .. (y and B64:sub(c3 + 1, c3 + 1) or "=") .. (z and B64:sub(c4 + 1, c4 + 1) or "=")
	end
	return table.concat(out)
end
local function b64d(s)
	s = s:gsub("[^%w%+/=]", "")
	local out = {}
	for i = 1, #s - 3, 4 do
		local a, b, c3, d = s:byte(i, i + 3)
		local n = (B64R[a] or 0) * 262144 + (B64R[b] or 0) * 4096 + (B64R[c3] or 0) * 64 + (B64R[d] or 0)
		out[#out + 1] = string.char(n // 65536 % 256) .. (c3 ~= 61 and string.char(n // 256 % 256) or "") .. (d ~= 61 and string.char(n % 256) or "")
	end
	return table.concat(out)
end

local function detectExecutor()
	local ok, n, v = pcall(function()
		if identifyexecutor then return identifyexecutor() end
		if getexecutorname then return getexecutorname() end
	end)
	if ok and n then return tostring(n) .. (v and (" " .. tostring(v)) or "") end
	local G = (getgenv and getgenv()) or _G
	for _, g in ipairs({{"Xeno", "Xeno"}, {"KRNL_LOADED", "KRNL"}, {"syn", "Synapse X"}, {"fluxus", "Fluxus"}, {"is_sirhurt_closure", "SirHurt"},
		{"pebc_execute", "ProtoSmasher"}, {"Delta", "Delta"}, {"Wave", "Wave"}, {"Arceus", "Arceus X"}, {"Hydrogen", "Hydrogen"}, {"Solara", "Solara"},
		{"Codex", "Codex"}, {"Electron", "Electron"}, {"MacSploit", "MacSploit"}, {"Volcano", "Volcano"}, {"Ronix", "Ronix"}}) do
		if rawget(G, g[1]) ~= nil then return g[2] end
	end
	if RS:IsStudio() then return "Studio (без инжектора)" end
	return "не определён"
end
local execName = (S.execOverride and S.execOverride ~= "") and S.execOverride or detectExecutor()

local open, rootCF, animT = true, nil, 0
local setOpen, applyAll, applyView, applyButton, applyHud, drawSettings
local wv, RUN, content = {}, {}, nil
local ncOrig, flyUp, flyDown, stopFly, tpTo, orig, CROSS_COLORS, applyFunctions = {}, false, false
local applyWorld, applyWeather, applyChar, fxTop, fxLow, CCS, CC_ORDER, WEATHER, W_ORDER
local updateHud, getPing
local lastTouch = os.clock()
local listeningKey = nil

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
M.nameLabel = label(nameBG, "👤 " .. lp.DisplayName, 17, "text", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), true, Enum.TextXAlignment.Center)
M.nameLabel.Active = false
nameBtn.InputBegan:Connect(startDrag("name"))
local nameTaps, nameTapT = 0, 0
tap(nameBtn, function()
	if os.clock() - nameTapT > 1.5 then nameTaps = 0 end
	nameTapT = os.clock(); nameTaps += 1
	if nameTaps >= 10 then nameTaps = 0; if M.party then M.party() end end
end)
local pills = {}
for _, key in ipairs({"log", "tabs", "main"}) do
	local pill = new("TextButton", {Text = "", Size = UDim2.new(0.3, 0, 0, 9), Position = UDim2.new(0.35, 0, 1, -15), BorderSizePixel = 0,
		Visible = false, ZIndex = 10}, P[key].sg)
	bind(pill, "BackgroundColor3", "rim"); round(pill, 5)
	pill.InputBegan:Connect(startDrag(key))
	pills[#pills + 1] = pill
end
for i, pn in ipairs(panels) do
	panelBGs[i].Active = true
	panelBGs[i].InputBegan:Connect(startDrag(pn.key))
end
local offX, offY, dist = 0, 0, 10
conn(UIS.InputChanged, function(i)
	if not (drag and isMove(i)) then return end
	local cam = workspace.CurrentCamera
	local k = 2 * dist * math.tan(math.rad(cam.FieldOfView) / 2) / cam.ViewportSize.Y
	local dx, dy = i.Delta.X, i.Delta.Y
	if S.detach and P[drag] then
		local p = P[drag]
		p.dx = p.dx + dx * k; p.dy = p.dy - dy * k
	else
		offX = offX + dx * k; offY = offY - dy * k
	end
end)

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
	if name == "esp" and M.espRefresh then task.defer(M.espRefresh) end
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
for _, t in ipairs({{"home", "Главная"}, {"esp", "👁 ESP"}, {"set", "Настройки"}, {"info", "Инфо"}, {"close", "✕ Скрыть"}}) do
	local k = t[1]
	local b, eb, et = button(tabsBG, t[2], function()
		if k == "close" then
			setOpen(false)
		else
			if k == "set" then pcall(drawSettings) end
			show(k)
		end
	end, UDim2.new(0.2, -11, 0, 40), true)
	if k ~= "close" then tabBtns[k] = b; tabE[k] = eb; tabT[k] = et end
end

---------------------------------------------------------------- журнал и инфо
do
local LOGS = {
	{"v4.0  Всё в одном", "ESP-вкладка с превью аватара, 19 настраиваемых визуалов (включай сколько хочешь), музыкальный плеер со словами на экране, игры (2048, змейка, Pac-Man), чат с каналами и группами, друзья, профиль и уровни, дрон FPV, каталог аватара, 12 анимаций меню и 12 анимаций вокруг персонажа."},
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
label(info, "Добро пожаловать в Visualesered!", 22, "text", nil, UDim2.new(1, 0, 0, 34), true)
label(info, "Тяни панель с именем, чтобы двигать меню. HUD (FPS, пинг, инжектор) и кнопку меню можно таскать по всему экрану. Значки на главной можно менять местами: зажми и перетащи на другой.", 15, "sub", nil, UDim2.new(1, 0, 0, 74))
label(info, "Устройство: " .. deviceName .. "   |   Инжектор: " .. execName, 14, "sub", nil, UDim2.new(1, 0, 0, 20))
button(info, "📣 Канал в Telegram: t.me/Visualesered (скопировать ссылку)", function() if setclipboard then pcall(setclipboard, "https://t.me/Visualesered"); toast("Ссылка скопирована", 2) end end, UDim2.new(1, 0, 0, 40), true)
local logTitle = label(info, "", 18, "text", nil, UDim2.new(1, 0, 0, 28), true)
local logText = label(info, "", 16, "text", nil, UDim2.new(1, 0, 0, 120))
local function showLog(k) logTitle.Text = LOGS[k][1]; logText.Text = LOGS[k][2]; show("info") end
for k, e in ipairs(LOGS) do
	local b = button(logList, e[1], function() showLog(k) end, UDim2.new(1, 0, 0, 36), true)
	b.TextXAlignment = Enum.TextXAlignment.Left
end
showLog(1)
end
M.load(12, "Интерфейс…")

---------------------------------------------------------------- главная: виджеты + три папки
do
local home = new("Frame", {Position = PAGE_POS, Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1}, mainBG)
pages.home = home
local wrow = new("Frame", {Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1}, home)
for k, t in ipairs({"Время", "Профиль", "FPS", "Пинг", "Инжектор"}) do
	local w = frame(wrow, UDim2.new((k - 1) * 0.2, (k - 1) * 1.6, 0, 0), UDim2.new(0.2, -6.4, 1, 0), "card", 14)
	label(w, t, 12, "sub", UDim2.new(0, 10, 0, 8), UDim2.new(1, -20, 0, 16))
	wv[k] = label(w, "", 20, "text", UDim2.new(0, 10, 0, 28), UDim2.new(1, -20, 0, 26), true)
	wv[k + 10] = label(w, "", 11, "sub", UDim2.new(0, 10, 0, 56), UDim2.new(1, -20, 0, 16))
end
wv[5].TextSize = 13; wv[5].TextTruncate = Enum.TextTruncate.AtEnd; wv[5].TextWrapped = false
local fold = new("Frame", {BackgroundTransparency = 1}, home)
local folders, icons = {}, {}
local function makeFolder(key, title, idx)
	local f = new("TextButton", {Text = "", AutoButtonColor = false, Position = UDim2.new((idx - 1) / 3, (idx - 1) * 3, 0, 0),
		Size = UDim2.new(1 / 3, -4, 1, 0), BorderSizePixel = 0}, fold)
	bind(f, "BackgroundColor3", "card"); round(f, 16)
	label(f, title, 15, "text", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 24), true)
	local sc = new("ScrollingFrame", {Position = UDim2.new(0, 4, 0, 36), Size = UDim2.new(1, -8, 1, -42), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, f)
	local g = new("UIGridLayout", {CellPadding = UDim2.fromOffset(2, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sc)
	folders[key] = {frame = f, sc = sc, grid = g}
end
makeFolder("f1", "Движение", 1)
makeFolder("f2", "Инструменты", 2)
makeFolder("f3", "Игры и общение", 3)

local appPage = new("Frame", {Position = PAGE_POS, Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1, Visible = false}, mainBG)
pages.app = appPage
local appTitle = label(appPage, "", 20, "text", UDim2.new(0, 56, 0, 0), UDim2.new(1, -60, 0, 36), true)
local function closeApp() if content then pcall(function() content:Destroy() end); content = nil end; show("home") end
button(appPage, "‹", closeApp, UDim2.fromOffset(44, 36))
local function openApp(app)
	if content then pcall(function() content:Destroy() end) end
	content = new("ScrollingFrame", {Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, appPage)
	new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)
	S.appsUsed = S.appsUsed or {}; S.appsUsed[app.id] = true
	appTitle.Text = app.i .. "  " .. app.n
	show("app")
	local ok, e = pcall(RUN[app.id], content)
	if not ok then warn("[L3D] приложение " .. app.id .. ": " .. tostring(e)) end
end
M.openApp = openApp

local APPS = {
	{id = "fly", n = "Полёт", i = "✈️", c = C(10,132,255), f = "f1"},
	{id = "noclip", n = "Ноуклип", i = "👻", c = C(120,120,128), f = "f1"},
	{id = "ijump", n = "Беск. прыжок", i = "🦘", c = C(48,209,88), f = "f1"},
	{id = "speed", n = "Скорость", i = "⚡", c = C(255,159,10), f = "f1"},
	{id = "jump", n = "Прыжок", i = "🚀", c = C(255,69,58), f = "f1"},
	{id = "clicktp", n = "ТП по клику", i = "🖱️", c = C(94,92,230), f = "f1"},
	{id = "points", n = "Точки", i = "📍", c = C(255,55,95), f = "f1"},
	{id = "players", n = "Игроки", i = "👥", c = C(100,210,255), f = "f1"},
	{id = "drone", n = "Дрон FPV", i = "🚁", c = C(60,60,70), f = "f1"},
	{id = "anim", n = "Анимации", i = "🌀", c = C(0,180,220), f = "f1"},
	{id = "emote", n = "Эмоции", i = "💃", c = C(255,105,180), f = "f1"},
	{id = "binds", n = "Бинды", i = "⌨️", c = C(150,150,255), f = "f1"},
	{id = "esp", n = "ESP", i = "👁️", c = C(191,90,242), f = "f2"},
	{id = "vfx", n = "Визуалы", i = "🎆", c = C(255,80,200), f = "f2"},
	{id = "avatar", n = "Аватар", i = "🧍", c = C(240,150,60), f = "f2"},
	{id = "bright", n = "Яркость", i = "🔆", c = C(255,214,10), f = "f2"},
	{id = "camera", n = "Камера", i = "🎥", c = C(0,200,180), f = "f2"},
	{id = "spec", n = "Наблюдать", i = "🔭", c = C(72,72,160), f = "f2"},
	{id = "cross", n = "Прицел", i = "🎯", c = C(220,50,50), f = "f2"},
	{id = "aclick", n = "Автоклик", i = "🖲️", c = C(60,160,90), f = "f2"},
	{id = "server", n = "Сервер", i = "🌐", c = C(40,120,220), f = "f2"},
	{id = "perf", n = "Буст FPS", i = "🛠️", c = C(150,150,160), f = "f2"},
	{id = "time", n = "Время", i = "🌗", c = C(90,90,220), f = "f2"},
	{id = "notes", n = "Заметки", i = "📝", c = C(240,200,20), f = "f2"},
	{id = "music", n = "Музыка", i = "🎵", c = C(255,45,85), f = "f3"},
	{id = "shop", n = "Магазин", i = "🛍", c = C(255,149,0), f = "f3"},
	{id = "browser", n = "Браузер", i = "🌐", c = C(0,122,255), f = "f2"},
	{id = "friends", n = "Друзья", i = "🤝", c = C(10,132,255), f = "f3"},
	{id = "profile", n = "Профиль", i = "🪪", c = C(175,82,222), f = "f3"},
	{id = "scripters", n = "Скриптеры", i = "👾", c = C(88,86,214), f = "f3"},
	{id = "pets", n = "Питомцы", i = "🐾", c = C(255,170,60), f = "f3"},
	{id = "phone", n = "Телефон", i = "📱", c = C(60,60,70), f = "f3"},
	{id = "execinfo", n = "Инжектор", i = "💉", c = C(90,90,100), f = "f2"},
	{id = "ach", n = "Достижения", i = "🏅", c = C(255,190,40), f = "f3"},
	{id = "freecam", n = "Фри-камера", i = "👻", c = C(120,120,200), f = "f1"},
	{id = "parkour", n = "Паркур и защита", i = "🛡", c = C(60,160,200), f = "f1"},
	{id = "ttt", n = "Крестики-нолики", i = "❌", c = C(70,130,230), f = "f3"},
	{id = "mines", n = "Сапёр", i = "💣", c = C(120,120,130), f = "f3"},
	{id = "memory", n = "Память", i = "🧠", c = C(230,120,170), f = "f3"},
	{id = "flappy", n = "Флэппи", i = "🐦", c = C(80,170,230), f = "f3"},
	{id = "wardrobe", n = "Гардероб", i = "🎭", c = C(180,90,220), f = "f2"},
	{id = "halloween", n = "Хэллоуин", i = "🎃", c = C(255,120,20), f = "f3"},
	{id = "ai", n = "ИИ", i = "🤖", c = C(20,180,160), f = "f2"},
	{id = "cmd", n = "Команды", i = "⌨️", c = C(60,60,80), f = "f2"},
	{id = "g2048", n = "2048", i = "🔢", c = C(237,194,46), f = "f3"},
	{id = "snake", n = "Змейка", i = "🐍", c = C(60,170,70), f = "f3"},
	{id = "pacman", n = "Pac-Man", i = "🟡", c = C(30,30,140), f = "f3"},
	{id = "click", n = "Кликер", i = "💎", c = C(70,190,255), f = "f3"},
	{id = "timer", n = "Секундомер", i = "⏱️", c = C(250,90,80), f = "f3"},
}

APPS[#APPS + 1] = {id = "admin", n = "Админ", i = "🛡", c = C(200,30,30), f = "f3"}

-- ПЕРЕТАСКИВАНИЕ ЗНАЧКОВ: зажми значок, потяни на другой и отпусти — они поменяются местами
local function saveIconPos()
	for id, ib in pairs(icons) do S.iconPos[id] = {ib:GetAttribute("f"), ib.LayoutOrder} end
	isDirty = true
end
local function onIconPressed(b, app, input)
	local startPos = input.Position
	local moved = false
	local mc, ec
	mc = UIS.InputChanged:Connect(function(i)
		if isMove(i) and (i.Position - startPos).Magnitude > 14 and not moved then
			moved = true; b.Ico.BackgroundTransparency = 0.55
		end
	end)
	ec = input.Changed:Connect(function()
		if input.UserInputState ~= Enum.UserInputState.End then return end
		mc:Disconnect(); ec:Disconnect()
		b.Ico.BackgroundTransparency = 0
		if not moved then
			openApp(app)
		else
			local tgt = M.hoverIcon
			if tgt and tgt ~= b then
				local po, pp, pf = b.LayoutOrder, b.Parent, b:GetAttribute("f")
				b.LayoutOrder = tgt.LayoutOrder; b.Parent = tgt.Parent; b:SetAttribute("f", tgt:GetAttribute("f"))
				tgt.LayoutOrder = po; tgt.Parent = pp; tgt:SetAttribute("f", pf)
				saveIconPos()
			end
		end
	end)
end

for order, app in ipairs(APPS) do
	local fk, ord = app.f, order
	local sp = S.iconPos[app.id]
	if sp and folders[sp[1]] then fk, ord = sp[1], sp[2] end
	local b = new("TextButton", {Text = "", BackgroundTransparency = 1, LayoutOrder = ord}, folders[fk].sc)
	b:SetAttribute("f", fk)
	local ico = new("TextLabel", {Name = "Ico", Text = app.i, BackgroundColor3 = app.c, BorderSizePixel = 0, Font = Enum.Font.GothamBold}, b)
	new("UICorner", {}, ico)
	new("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 175))}, ico)
	local lbl = label(b, app.n, 11, "text", nil, nil, false, Enum.TextXAlignment.Center)
	lbl.Name = "Lbl"; lbl.TextWrapped = false; lbl.TextTruncate = Enum.TextTruncate.AtEnd
	icons[app.id] = b
	b.InputBegan:Connect(function(input) if isPress(input) then onIconPressed(b, app, input) end end)
	b.MouseEnter:Connect(function() M.hoverIcon = b end)
	b.MouseLeave:Connect(function() if M.hoverIcon == b then M.hoverIcon = nil end end)
end

M.icons = icons
task.spawn(function()
	while alive do
		local ic = icons.admin
		if ic then ic.Visible = (M.isAdmin and M.isAdmin()) and true or false end
		task.wait(1.5)
	end
end)

function applyView()
	local s = SIZES[S.size]
	for _, bg in ipairs(panelBGs) do
		bg.BackgroundTransparency = ((S.menuBg or "") ~= "" and M.menuBgAsset) and 1 or S.alpha
		bg.Grad.Enabled = S.grad
	end
	for _, p in ipairs(pills) do p.Visible = S.detach end
	local wy = S.widgets and 92 or 0
	wrow.Visible = S.widgets
	fold.Position = UDim2.new(0, 0, 0, wy)
	fold.Size = UDim2.new(1, 0, 1, -wy)
	for _, f in pairs(folders) do
		f.grid.CellSize = S.view == "grid" and UDim2.fromOffset(s + 14, s + (S.labels and 24 or 6)) or UDim2.new(1, -6, 0, math.floor(s * 0.75) + 6)
	end
	for _, b in pairs(icons) do
		local ico, lbl = b.Ico, b.Lbl
		ico:FindFirstChildOfClass("UICorner").CornerRadius = SHAPES[S.shape]
		if S.view == "grid" then
			ico.Size = UDim2.fromOffset(s, s); ico.Position = UDim2.new(0.5, -s / 2, 0, 2); ico.TextSize = s * 0.5
			lbl.Position = UDim2.new(0, 0, 0, s + 4); lbl.Size = UDim2.new(1, 0, 0, 18)
			lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.Visible = S.labels
		else
			local h = math.floor(s * 0.75)
			ico.Size = UDim2.fromOffset(h, h); ico.Position = UDim2.new(0, 2, 0.5, -h / 2); ico.TextSize = h * 0.5
			lbl.Position = UDim2.new(0, h + 10, 0, 0); lbl.Size = UDim2.new(1, -(h + 10), 1, 0)
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Visible = true
		end
	end
end
end -- конец секции главной

---------------------------------------------------------------- помощники настроек
local function reset(c)
	for _, ch in ipairs(c:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			pcall(function() ch:Destroy() end)
		end
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
local function setTog(text, tbl, key, after)
	return {text .. (tbl[key] and " ●" or ""), function()
		if tbl[key] then tbl[key] = nil else tbl[key] = true end
		applyAll(); (after or drawSettings)()
	end, not tbl[key]}
end
M.setTog = setTog
local function stepRow(c, title, key, st, lo, hi, fmt, after)
	label(c, title .. ": " .. fmt(S[key]), 15, "text", nil, UDim2.new(1, 0, 0, 22), true)
	local function ch(d) return function() S[key] = math.clamp(math.floor((S[key] + d) * 100 + 0.5) / 100, lo, hi); applyAll(); (after or drawSettings)() end end
	row(c, {{"−", ch(-st), true}, {"+", ch(st), true}})
end
local pct = function(v) return math.floor(v * 100 + 0.5) .. "%" end
local num = function(v) return tostring(v) end
local pxf = function(v) return v .. " px" end
-- универсальный шаг: −− − + ++ (тонкая и грубая настройка)
local function stepFn(c, title, get, set, st, lo, hi, fmt, after)
	fmt = fmt or tostring
	label(c, title .. ": " .. fmt(get()), 15, "text", nil, UDim2.new(1, 0, 0, 22), true)
	local function ch(d)
		return function()
			set(math.clamp(math.floor((get() + d) * 1000 + 0.5) / 1000, lo, hi))
			isDirty = true
			;(after or drawSettings)()
		end
	end
	row(c, {{"−−", ch(-st * 5), true}, {"−", ch(-st), true}, {"+", ch(st), true}, {"++", ch(st * 5), true}})
end
-- ряд цветов: 0 = акцент, -1 = радуга, 1.. = палитра
local function swatches(c, get, set, after)
	local ar = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)}, c)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, ar)
	local list = {0, -1}
	for i = 1, #PALETTE do list[#list + 1] = i end
	for _, idx in ipairs(list) do
		local mark = get() == idx and "✓" or (idx == 0 and "A" or (idx == -1 and "🌈" or ""))
		local b = new("TextButton", {Text = mark, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = idx == 10 and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
			BackgroundColor3 = idx > 0 and PALETTE[idx] or (idx == 0 and ACCENTS[S.acc] or Color3.fromRGB(120, 120, 130)), Size = UDim2.fromOffset(30, 30), BorderSizePixel = 0}, ar)
		round(b, 15)
		tap(b, function() set(idx); isDirty = true; after() end)
	end
end

---------------------------------------------------------------- функции
do
local flyBV, flyBG
function stopFly()
	if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
	local h = hum(); if h then h.PlatformStand = false end
end
function tpTo(pos)
	local r = root()
	if r then
		r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) * (r.CFrame - r.CFrame.Position)
		r.AssemblyLinearVelocity = Vector3.zero
	end
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
		if M.remote and os.clock() < M.remote.exp then h:Move(Vector3.new(M.remote.x, 0, M.remote.z), false) end
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
conn(RS.Stepped, function()
	if not S.antiFling then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Character then
			for _, d in ipairs(p.Character:GetChildren()) do if d:IsA("BasePart") then d.CanCollide = false end end
		end
	end
	local r = root()
	if r and not S.fly and not S.drone then
		local v, w = r.AssemblyLinearVelocity, r.AssemblyAngularVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > 150 or w.Magnitude > 40 then
			r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)
conn(UIS.JumpRequest, function()
	if S.ijump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- эффект при прыжке
local lastJfx = 0
local function ringAt(pos, delay, maxSize, pillar)
	task.delay(delay, function()
		local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Material = Enum.Material.Neon, Color = ACCENTS[S.acc], Transparency = 0.3, Shape = Enum.PartType.Cylinder}, workspace)
		if pillar then
			p.Size = Vector3.new(0.5, 3, 3); p.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			TS:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(12, 4, 4), Transparency = 1}):Play()
		else
			p.Size = Vector3.new(0.15, 1.5, 1.5); p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
			TS:Create(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.15, maxSize, maxSize), Transparency = 1}):Play()
		end
		task.delay(0.8, function() pcall(function() p:Destroy() end) end)
	end)
end
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local function jumpFx()
	local r, h = root(), hum()
	if not (r and h) then return end
	local pos = Vector3.new(r.Position.X, r.Position.Y - (h.HipHeight + r.Size.Y / 2) + 0.15, r.Position.Z)
	local set = S.jumpSet
	local function puff(props, n, life)
		local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, Position = pos}, workspace)
		local e = new("ParticleEmitter", props, p)
		e.Rate = 0; e:Emit(n)
		task.delay(life or 1.8, function() pcall(function() p:Destroy() end) end)
	end
	if set.burst then
		puff({Lifetime = NR(0.5, 0.9), Speed = NR(14, 26), SpreadAngle = Vector2.new(180, 180), EmissionDirection = Enum.NormalId.Top, Size = NS(0.35),
			Color = ColorSequence.new(ACCENTS[S.acc]), LightEmission = 1, Acceleration = Vector3.new(0, -30, 0),
			Transparency = NS({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})}, 36)
	end
	if set.dust then
		puff({Texture = SMOKE_TEX, Lifetime = NR(0.8, 1.4), Speed = NR(4, 9), SpreadAngle = Vector2.new(80, 80), EmissionDirection = Enum.NormalId.Right,
			Size = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)}), Rotation = NR(0, 360), RotSpeed = NR(-40, 40),
			Color = ColorSequence.new(C(190, 180, 165)), Transparency = NS({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})}, 14, 2)
	end
	if set.spiral then
		for k = 1, 14 do
			task.delay(k * 0.03, function()
				local a = k * 0.9
				local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Shape = Enum.PartType.Ball,
					Color = pcolor(-1, os.clock(), k * 0.05), Size = Vector3.one * 0.5, Position = pos + Vector3.new(math.cos(a) * 2.5, 0.2, math.sin(a) * 2.5)}, workspace)
				TS:Create(p, TweenInfo.new(0.7), {Position = p.Position + Vector3.new(0, 4, 0), Transparency = 1, Size = Vector3.one * 0.1}):Play()
				task.delay(0.8, function() pcall(function() p:Destroy() end) end)
			end)
		end
	end
	if set.pillar then ringAt(pos, 0, 0, true) end
	if set.ring then ringAt(pos, 0, 12) end
	if set.double then ringAt(pos, 0, 10); ringAt(pos, 0.15, 7) end
end
conn(UIS.JumpRequest, function()
	if next(S.jumpSet) and os.clock() - lastJfx > 0.15 then lastJfx = os.clock(); jumpFx() end
end)

local mouse = lp:GetMouse()
local function rayTp()
	local m = UIS:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(m.X, m.Y)
	local ign = {lp.Character}
	for _, p in ipairs(panels) do ign[#ign + 1] = p.part end
	local prm = RaycastParams.new()
	prm.FilterDescendantsInstances = ign; prm.FilterType = Enum.RaycastFilterType.Exclude
	local res = workspace:Raycast(ray.Origin, ray.Direction * 5000, prm)
	if res then tpTo(res.Position) else M.toast("Некуда телепортироваться", 1.5) end
end
M.rayTp = rayTp
conn(UIS.InputBegan, function(i)
	if not S.clicktp or open or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if S.tpMode == "always" or UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then rayTp() end
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

-- ESP
local espFolder = keep(new("Folder", {Name = "LauncherESP"}, PG))
local function clearEsp()
	for _, o in ipairs(espFolder:GetChildren()) do pcall(function() o:Destroy() end) end
end
local friendCache = {}
local function isFriendP(p)
	local v = friendCache[p.UserId]
	if v == nil then
		friendCache[p.UserId] = false
		task.spawn(function() local ok, r = pcall(function() return lp:IsFriendsWith(p.UserId) end); friendCache[p.UserId] = ok and r or false end)
		return false
	end
	return v
end
local function espColor(p, hu)
	if S.espFriend and isFriendP(p) then return C(80, 255, 140) end
	local m = S.espColorMode
	if (S.espTeam or m == "team") and p.Team then return p.TeamColor.Color end
	if m == "rainbow" then return Color3.fromHSV((os.clock() * 0.25 + (p.UserId % 10) * 0.1) % 1, 0.8, 1) end
	if m == "health" then return Color3.fromHSV(math.clamp(hu.Health / math.max(hu.MaxHealth, 1), 0, 1) * 0.33, 0.85, 1) end
	if m == "custom" then return pcolor(S.espFillColor, os.clock(), (p.UserId % 10) * 0.1) end
	return ACCENTS[S.acc]
end
M.espColor = espColor
local function skipTeam(p) return S.espTeamCheck and p.Team and p.Team == lp.Team end
local function updateEsp()
	if not S.esp then if #espFolder:GetChildren() > 0 then clearEsp() end return end
	local myR = root()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hd = ch and ch:FindFirstChild("Head")
		local hu = ch and ch:FindFirstChildOfClass("Humanoid")
		if p ~= lp and hrp and hd and hu and not skipTeam(p) then
			local d = myR and (hrp.Position - myR.Position).Magnitude or 0
			if d <= S.espMax then list[#list + 1] = {p = p, ch = ch, hrp = hrp, hd = hd, hu = hu, d = d} end
		end
	end
	table.sort(list, function(a, b) return a.d < b.d end)
	local alivePl = {}
	for idx, e in ipairs(list) do
		alivePl[e.p.Name] = true
		local ok, err = pcall(function()
			local p, ch, hrp, hd, hu = e.p, e.ch, e.hrp, e.hd, e.hu
			local color = espColor(p, hu)
			local useHL = idx <= 28 -- у Roblox лимит ~31 Highlight одновременно: дальние получают рамку вместо заливки
			local hl = espFolder:FindFirstChild("HL_" .. p.Name)
			if useHL then
				if not hl or hl.Adornee ~= ch then
					if hl then hl:Destroy() end
					hl = new("Highlight", {Name = "HL_" .. p.Name, Adornee = ch}, espFolder)
				end
				hl.FillColor = color; hl.OutlineColor = pcolor(S.espOutColor, os.clock())
				hl.FillTransparency = S.espChams and S.espFill or 1
				hl.DepthMode = S.espWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
				hl.OutlineTransparency = S.espOutline
			elseif hl then hl:Destroy() end
			local bx = espFolder:FindFirstChild("BX_" .. p.Name)
			if S.espBox or not useHL then
				if not bx or bx.Adornee ~= hrp then
					if bx then bx:Destroy() end
					bx = new("BoxHandleAdornment", {Name = "BX_" .. p.Name, Adornee = hrp, Size = Vector3.new(4, 5.8, 2), ZIndex = 1}, espFolder)
				end
				bx.Color3 = color; bx.Transparency = S.espBoxTrans; bx.AlwaysOnTop = S.espWalls
			elseif bx then bx:Destroy() end
			local bb = espFolder:FindFirstChild("BB_" .. p.Name)
			if not bb or bb.Adornee ~= hd then
				if bb then bb:Destroy() end
				bb = new("BillboardGui", {Name = "BB_" .. p.Name, Adornee = hd, AlwaysOnTop = true, Size = UDim2.fromOffset(200, 46), StudsOffset = Vector3.new(0, 2.8, 0)}, espFolder)
				new("TextLabel", {Name = "T", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.3}, bb)
				local bar = new("Frame", {Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(100, 5), BackgroundColor3 = C(20, 20, 20), BorderSizePixel = 0}, bb)
				new("Frame", {Name = "F", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, bar)
			end
			local txt = {}
			if S.espNames then txt[#txt + 1] = p.DisplayName end
			if S.espDist and myR then txt[#txt + 1] = "[" .. math.floor(e.d) .. "м]" end
			if S.espHp then txt[#txt + 1] = hu.Health <= 0 and "☠" or ("♥" .. math.floor(hu.Health)) end
			if M.tagOf and M.tagOf(p) then txt[#txt + 1] = "◆" end
			local f = math.clamp(hu.Health / math.max(hu.MaxHealth, 1), 0, 1)
			bb.T.Text = table.concat(txt, " "); bb.T.TextSize = S.espTextSize; bb.T.TextColor3 = pcolor(S.espNameColor, os.clock())
			bb.Bar.Visible = S.espBar; bb.Bar.F.Size = UDim2.fromScale(f, 1); bb.Bar.F.BackgroundColor3 = Color3.fromHSV(f * 0.33, 0.9, 1)
			bb.Enabled = #txt > 0 or S.espBar
		end)
		if not ok then M.espErr = tostring(err) end
	end
	for _, o in ipairs(espFolder:GetChildren()) do
		if not alivePl[string.sub(o.Name, 4)] then pcall(function() o:Destroy() end) end
	end
end
-- трейсеры (линии от низа/центра/верха экрана к игрокам)
local trGui = keep(new("ScreenGui", {Name = "LauncherTracers", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 35}, PG))
local tlines = {}
conn(RS.RenderStepped, function()
	local used = {}
	if S.esp and S.espTracer then
		local cam = workspace.CurrentCamera
		local vp = cam.ViewportSize
		local from = S.espTracerFrom == "center" and vp / 2 or (S.espTracerFrom == "top" and Vector2.new(vp.X / 2, 0) or Vector2.new(vp.X / 2, vp.Y))
		local myR = root()
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p ~= lp and p.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if hrp and not skipTeam(p) and (not myR or (hrp.Position - myR.Position).Magnitude <= S.espMax) then
				local pt, on = cam:WorldToViewportPoint(hrp.Position)
				if on and pt.Z > 0 then
					used[p.Name] = true
					local l = tlines[p.Name]
					if not l then l = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0}, trGui); tlines[p.Name] = l end
					local to = Vector2.new(pt.X, pt.Y)
					local d = to - from
					l.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
					l.Size = UDim2.fromOffset(d.Magnitude, S.espTracerThick)
					l.Rotation = math.deg(math.atan2(d.Y, d.X))
					l.BackgroundColor3 = espColor(p, ch:FindFirstChildOfClass("Humanoid") or {Health = 100, MaxHealth = 100})
					l.Visible = true
				end
			end
		end
	end
	for name, l in pairs(tlines) do if not used[name] then l.Visible = false end end
end)
task.spawn(function() while alive do pcall(updateEsp); task.wait(0.15) end end)

-- яркость, прицел
orig = {fs = Lighting.FogStart, fe = Lighting.FogEnd, fc = Lighting.FogColor, grav = workspace.Gravity, B = Lighting.Brightness,
	A = Lighting.Ambient, OA = Lighting.OutdoorAmbient, GS = Lighting.GlobalShadows, maxZ = lp.CameraMaxZoomDistance, minZ = lp.CameraMinZoomDistance}
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
CROSS_COLORS = {C(255,255,255), C(255,60,60), C(60,255,120), C(80,180,255), C(255,220,60), C(255,80,220)}
local function applyCross()
	for _, o in ipairs(crossGui:GetChildren()) do pcall(function() o:Destroy() end) end
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
function applyFunctions()
	applyBright(); applyCross()
	pcall(function()
		lp.CameraMaxZoomDistance = S.zoomUnlock and 10000 or orig.maxZ
		lp.CameraMinZoomDistance = S.tpLock and 12 or (S.zoomUnlock and 0 or orig.minZ)
		lp.CameraMode = (S.fpLock or S.drone) and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
	end)
	if S.fpscap and setfpscap then pcall(setfpscap, S.fpscap) end
end
end -- конец секции функций
M.load(26, "Приложения…")

---------------------------------------------------------------- приложения
do
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
	local function draw()
		reset(c)
		ftog(c, "🖱️ Телепорт по клику", "clicktp", draw)
		row(c, {opt("Ctrl + клик", "tpMode", "ctrl", draw), opt("Любой клик", "tpMode", "always", draw)})
		row(c, {{"📍 ТП в точку под курсором (клавиша " .. S.keys.tpto .. ")", function() M.rayTp() end, true}})
		label(c, "ПК: включи, зажми Ctrl и кликни в мир (когда меню закрыто). Или наведи курсор и нажми клавишу ТП. Телефон: тап по миру.", 14, "sub", nil, UDim2.new(1, 0, 0, 56))
	end
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
	if h then workspace.CurrentCamera.CameraSubject = h; spectating = true; return true end
	return false
end
local function stopSpectate()
	local h = hum(); if h then workspace.CurrentCamera.CameraSubject = h end
	spectating = false
end
M.spectate, M.stopSpectate = spectate, stopSpectate
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
		label(c, "Полные настройки и превью аватара — на вкладке «👁 ESP» сверху.", 13, "sub", nil, UDim2.new(1, 0, 0, 20))
		row(c, {tog("Имена", "espNames", draw), tog("Дистанция", "espDist", draw)})
		row(c, {tog("Здоровье", "espHp", draw), tog("Сквозь стены", "espWalls", draw)})
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
			tap(b, function() S.chColor = k; applyAll(); draw() end)
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
		M.serverExtra(c, draw)
	end
	draw()
end
RUN.perf = function(c)
	local function draw()
		reset(c)
		ftog(c, "🛠️ Буст FPS (без теней и травы)", "boost", draw)
		ftog(c, "🚫 Скрыть все партиклы в игре (откат кнопкой)", "noParticles", draw)
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
	b:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = 28
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
	task.spawn(function() while content == me and alive do upd(); task.wait(0.1) end end)
end
RUN.binds = function(c)
	local function draw()
		reset(c)
		head(c, "Нажми на кнопку, затем нужную клавишу (Esc — отмена)")
		local KEYDEF = {{"menu", "Меню"}, {"fly", "Полёт"}, {"noclip", "Ноуклип"}, {"esp", "ESP"}, {"hud", "HUD"}, {"fp", "1-е лицо"}, {"tpv", "3-е лицо"}, {"drone", "Дрон FPV"}, {"tpto", "ТП к курсору"}, {"aclick", "Автоклик"}}
		for _, k in ipairs(KEYDEF) do
			local text = k[2] .. ": " .. (listeningKey == k[1] and "нажми клавишу…" or S.keys[k[1]])
			button(c, text, function() listeningKey = k[1]; draw() end, UDim2.new(1, 0, 0, 40), listeningKey ~= k[1])
		end
	end
	M.redrawBinds = draw
	draw()
end
end -- конец приложений

---------------------------------------------------------------- игры
do
local function keyHook(me, fn)
	local k
	k = UIS.InputBegan:Connect(function(i, gp)
		if content ~= me then k:Disconnect(); return end
		if gp or UIS:GetFocusedTextBox() then return end
		fn(i.KeyCode)
	end)
end
local function dpad(c, f)
	row(c, {{"◀", function() f("left") end, true}, {"▲", function() f("up") end, true}, {"▼", function() f("down") end, true}, {"▶", function() f("right") end, true}})
end

-- 2048
RUN.g2048 = function(c)
	local me = c
	local g, score = {}, 0
	for i = 1, 16 do g[i] = 0 end
	local function idx(r, k) return (r - 1) * 4 + k end
	local LINES = {
		left = function(k) return {idx(k,1), idx(k,2), idx(k,3), idx(k,4)} end,
		right = function(k) return {idx(k,4), idx(k,3), idx(k,2), idx(k,1)} end,
		up = function(k) return {idx(1,k), idx(2,k), idx(3,k), idx(4,k)} end,
		down = function(k) return {idx(4,k), idx(3,k), idx(2,k), idx(1,k)} end,
	}
	local sl = label(c, "", 22, "text", nil, UDim2.new(1, 0, 0, 30), true, Enum.TextXAlignment.Center)
	local board = new("Frame", {Size = UDim2.fromOffset(300, 300), BorderSizePixel = 0}, c)
	bind(board, "BackgroundColor3", "card2"); round(board, 12)
	new("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingTop = UDim.new(0, 3)}, board)
	new("UIGridLayout", {CellSize = UDim2.fromOffset(70, 70), CellPadding = UDim2.fromOffset(5, 5), SortOrder = Enum.SortOrder.LayoutOrder}, board)
	local cells = {}
	for i = 1, 16 do
		cells[i] = new("TextLabel", {LayoutOrder = i, Font = Enum.Font.GothamBold, TextSize = 26, BorderSizePixel = 0, Text = ""}, board)
		round(cells[i], 8)
	end
	local function canMove()
		for r = 1, 4 do for k = 1, 4 do
			local v = g[idx(r, k)]
			if v == 0 then return true end
			if k < 4 and g[idx(r, k + 1)] == v then return true end
			if r < 4 and g[idx(r + 1, k)] == v then return true end
		end end
		return false
	end
	local function render()
		for i = 1, 16 do
			local v = g[i]
			cells[i].Text = v > 0 and tostring(v) or ""
			local t = v == 0 and 0 or math.min(math.log(v, 2) / 11, 1)
			cells[i].BackgroundColor3 = v == 0 and C(70, 74, 84) or Color3.fromHSV(0.12 - 0.12 * t, 0.35 + 0.55 * t, 1)
			cells[i].TextColor3 = v <= 4 and C(60, 60, 60) or Color3.new(1, 1, 1)
		end
		sl.Text = canMove() and ("Счёт: " .. score) or ("Игра окончена · Счёт: " .. score)
	end
	local function spawnTile()
		local e = {}
		for i = 1, 16 do if g[i] == 0 then e[#e + 1] = i end end
		if #e > 0 then g[e[math.random(#e)]] = math.random() < 0.9 and 2 or 4 end
	end
	local function move(dir)
		local moved = false
		for k = 1, 4 do
			local ids = LINES[dir](k)
			local vals = {}
			for _, i in ipairs(ids) do if g[i] ~= 0 then vals[#vals + 1] = g[i] end end
			local out, j = {}, 1
			while j <= #vals do
				if vals[j + 1] == vals[j] then out[#out + 1] = vals[j] * 2; score += vals[j] * 2; j += 2
				else out[#out + 1] = vals[j]; j += 1 end
			end
			for n, i in ipairs(ids) do
				local nv = out[n] or 0
				if g[i] ~= nv then moved = true; g[i] = nv end
			end
		end
		if moved then spawnTile() end
		render()
	end
	local function restart()
		for i = 1, 16 do g[i] = 0 end
		score = 0; spawnTile(); spawnTile(); render()
	end
	dpad(c, move)
	row(c, {{"Заново", restart, true}})
	restart()
	local m = {[Enum.KeyCode.Up] = "up", [Enum.KeyCode.Down] = "down", [Enum.KeyCode.Left] = "left", [Enum.KeyCode.Right] = "right",
		[Enum.KeyCode.W] = "up", [Enum.KeyCode.S] = "down", [Enum.KeyCode.A] = "left", [Enum.KeyCode.D] = "right"}
	keyHook(me, function(k) if m[k] then move(m[k]) end end)
end

-- Змейка
RUN.snake = function(c)
	local me = c
	local N, CS = 14, 22
	local sl = label(c, "", 18, "text", nil, UDim2.new(1, 0, 0, 26), true)
	local board = new("Frame", {Size = UDim2.fromOffset(N * CS, N * CS), BorderSizePixel = 0}, c)
	bind(board, "BackgroundColor3", "card2"); round(board, 8)
	local cells = {}
	for i = 1, N * N do
		local x, y = (i - 1) % N, math.floor((i - 1) / N)
		cells[i] = new("Frame", {Size = UDim2.fromOffset(CS - 2, CS - 2), Position = UDim2.fromOffset(x * CS + 1, y * CS + 1), BorderSizePixel = 0, BackgroundTransparency = 1}, board)
		round(cells[i], 4)
	end
	local snake, dir, nd, food, score, over
	local function at(x, y) return y * N + x + 1 end
	local function placeFood()
		local occ, free = {}, {}
		for _, s in ipairs(snake) do occ[at(s[1], s[2])] = true end
		for i = 1, N * N do if not occ[i] then free[#free + 1] = i end end
		local i = free[math.random(#free)]
		food = {(i - 1) % N, math.floor((i - 1) / N)}
	end
	local function render()
		for i = 1, N * N do cells[i].BackgroundTransparency = 1 end
		local f = cells[at(food[1], food[2])]
		f.BackgroundTransparency = 0; f.BackgroundColor3 = C(255, 70, 70)
		for k, s in ipairs(snake) do
			local cell = cells[at(s[1], s[2])]
			cell.BackgroundTransparency = 0
			cell.BackgroundColor3 = k == 1 and ACCENTS[S.acc] or ACCENTS[S.acc]:Lerp(Color3.new(1, 1, 1), 0.35)
		end
		sl.Text = over and ("Игра окончена · Счёт: " .. score) or ("Счёт: " .. score)
	end
	local function restart()
		snake = {{7, 7}, {6, 7}, {5, 7}}; dir = {1, 0}; nd = dir; score = 0; over = false
		placeFood(); render()
	end
	local function turn(dx, dy) if not (dx == -dir[1] and dy == -dir[2]) then nd = {dx, dy} end end
	local function step()
		if over then return end
		dir = nd
		local nx, ny = snake[1][1] + dir[1], snake[1][2] + dir[2]
		if nx < 0 or ny < 0 or nx >= N or ny >= N then over = true; render(); return end
		for k = 1, #snake - 1 do
			if snake[k][1] == nx and snake[k][2] == ny then over = true; render(); return end
		end
		table.insert(snake, 1, {nx, ny})
		if nx == food[1] and ny == food[2] then score += 10; placeFood() else table.remove(snake) end
		render()
	end
	local D = {left = {-1, 0}, right = {1, 0}, up = {0, -1}, down = {0, 1}}
	dpad(c, function(d) turn(D[d][1], D[d][2]) end)
	row(c, {{"Заново", restart, true}})
	restart()
	local m = {[Enum.KeyCode.Up] = "up", [Enum.KeyCode.Down] = "down", [Enum.KeyCode.Left] = "left", [Enum.KeyCode.Right] = "right",
		[Enum.KeyCode.W] = "up", [Enum.KeyCode.S] = "down", [Enum.KeyCode.A] = "left", [Enum.KeyCode.D] = "right"}
	keyHook(me, function(k) if m[k] then turn(D[m[k]][1], D[m[k]][2]) end end)
	task.spawn(function()
		while content == me and alive do
			task.wait(math.max(0.07, 0.17 - score * 0.0015))
			step()
		end
	end)
end

-- Pac-Man (упрощённый)
RUN.pacman = function(c)
	local me = c
	local MAP = {
		"###############", "#o.....#.....o#", "#.###.###.###.#", "#.............#", "#.##.#####.##.#", "#....#   #....#",
		"#.##.## ##.##.#", "#.............#", "#.##.#####.##.#", "#o...........o#", "###############"}
	local W, H, CS = 15, 11, 26
	local sl = label(c, "", 18, "text", nil, UDim2.new(1, 0, 0, 26), true)
	local board = new("Frame", {Size = UDim2.fromOffset(W * CS, H * CS), BorderSizePixel = 0, BackgroundColor3 = C(8, 8, 20)}, c)
	round(board, 8)
	local cells = {}
	for y = 1, H do
		cells[y] = {}
		for x = 1, W do
			cells[y][x] = new("TextLabel", {Size = UDim2.fromOffset(CS, CS), Position = UDim2.fromOffset((x - 1) * CS, (y - 1) * CS), BorderSizePixel = 0,
				BackgroundTransparency = 1, Text = "", TextSize = 17, Font = Enum.Font.GothamBold, TextColor3 = C(255, 230, 150)}, board)
		end
	end
	local grid, pellets, pac, want, ghosts, score, lives, scared, over, tick = {}, 0, nil, {0, 0}, {}, 0, 3, 0, false, 0
	local DIRS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	local function wall(x, y) return not grid[y] or grid[y][x] == nil or grid[y][x] == "#" end
	local function resetPos()
		pac = {x = 8, y = 10, dx = 0, dy = 0}; want = {0, 0}
		ghosts = {{x = 7, y = 6, hx = 7, hy = 6, dx = 0, dy = 0}, {x = 8, y = 6, hx = 8, hy = 6, dx = 0, dy = 0}, {x = 9, y = 6, hx = 9, hy = 6, dx = 0, dy = 0}}
		scared = 0
	end
	local function loadMap()
		grid, pellets = {}, 0
		for y = 1, H do
			grid[y] = {}
			for x = 1, W do
				local ch = MAP[y]:sub(x, x)
				grid[y][x] = ch
				if ch == "." or ch == "o" then pellets += 1 end
			end
		end
	end
	local function render()
		for y = 1, H do
			for x = 1, W do
				local cell, g = cells[y][x], grid[y][x]
				if g == "#" then cell.BackgroundTransparency = 0; cell.BackgroundColor3 = C(40, 60, 190); cell.Text = ""
				else cell.BackgroundTransparency = 1; cell.Text = g == "." and "·" or (g == "o" and "●" or "") end
			end
		end
		for _, gh in ipairs(ghosts) do cells[gh.y][gh.x].Text = scared > 0 and "😱" or "👻" end
		cells[pac.y][pac.x].Text = "🟡"
		sl.Text = (over and "Игра окончена · " or "") .. "Счёт: " .. score .. "   Жизни: " .. string.rep("❤", math.max(lives, 0))
	end
	local function restart() score, lives, over, tick = 0, 3, false, 0; loadMap(); resetPos(); render() end
	local function moveGhost(gh)
		local opts = {}
		for _, d in ipairs(DIRS) do
			local back = (gh.dx ~= 0 or gh.dy ~= 0) and d[1] == -gh.dx and d[2] == -gh.dy
			if not wall(gh.x + d[1], gh.y + d[2]) and not back then opts[#opts + 1] = d end
		end
		if #opts == 0 then opts = {{-gh.dx, -gh.dy}} end
		local pick
		if math.random() < 0.65 then
			local best, bd
			for _, d in ipairs(opts) do
				local dd = math.abs(gh.x + d[1] - pac.x) + math.abs(gh.y + d[2] - pac.y)
				if scared > 0 then dd = -dd end
				if not bd or dd < bd then bd = dd; best = d end
			end
			pick = best
		else
			pick = opts[math.random(#opts)]
		end
		gh.dx, gh.dy = pick[1], pick[2]
		if not wall(gh.x + gh.dx, gh.y + gh.dy) then gh.x += gh.dx; gh.y += gh.dy end
	end
	local function collide()
		for _, gh in ipairs(ghosts) do
			if gh.x == pac.x and gh.y == pac.y then
				if scared > 0 then
					score += 200; gh.x, gh.y, gh.dx, gh.dy = gh.hx, gh.hy, 0, 0
				else
					lives -= 1
					if lives <= 0 then over = true else resetPos() end
					return
				end
			end
		end
	end
	local function step()
		if over then return end
		tick += 1
		if (want[1] ~= 0 or want[2] ~= 0) and not wall(pac.x + want[1], pac.y + want[2]) then pac.dx, pac.dy = want[1], want[2] end
		if not wall(pac.x + pac.dx, pac.y + pac.dy) then pac.x += pac.dx; pac.y += pac.dy end
		local g = grid[pac.y][pac.x]
		if g == "." then grid[pac.y][pac.x] = " "; score += 10; pellets -= 1
		elseif g == "o" then grid[pac.y][pac.x] = " "; score += 50; pellets -= 1; scared = 35 end
		collide()
		if not over and tick % 4 ~= 0 and not (scared > 0 and tick % 2 == 0) then
			for _, gh in ipairs(ghosts) do moveGhost(gh) end
			collide()
		end
		if scared > 0 then scared -= 1 end
		if pellets <= 0 and not over then score += 500; loadMap(); resetPos() end
		render()
	end
	local D = {left = {-1, 0}, right = {1, 0}, up = {0, -1}, down = {0, 1}}
	dpad(c, function(d) want = D[d] end)
	row(c, {{"Заново", restart, true}})
	restart()
	local m = {[Enum.KeyCode.Up] = "up", [Enum.KeyCode.Down] = "down", [Enum.KeyCode.Left] = "left", [Enum.KeyCode.Right] = "right",
		[Enum.KeyCode.W] = "up", [Enum.KeyCode.S] = "down", [Enum.KeyCode.A] = "left", [Enum.KeyCode.D] = "right"}
	keyHook(me, function(k) if m[k] then want = D[m[k]] end end)
	task.spawn(function()
		while content == me and alive do task.wait(0.18); step() end
	end)
end
end -- конец игр
M.load(38, "Мир и погода…")

---------------------------------------------------------------- мир
do
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
CCS = {
	normal = {"Обычный", 0, 0, 0, Color3.new(1, 1, 1)}, warm = {"Тёплый", 0.02, 0.06, 0.18, C(255,232,205)},
	cold = {"Холодный", 0, 0.06, -0.05, C(200,224,255)}, bw = {"Ч/Б", 0, 0.12, -1, Color3.new(1, 1, 1)},
	vivid = {"Яркий", 0, 0.16, 0.6, Color3.new(1, 1, 1)}, cinema = {"Кино", -0.03, 0.28, -0.15, C(228,236,255)},
	sunset = {"Закатный", 0.02, 0.1, 0.25, C(255,196,160)}, noir = {"Нуар", -0.04, 0.45, -1, Color3.new(1, 1, 1)},
}
CC_ORDER = {"normal", "warm", "cold", "bw", "vivid", "cinema", "sunset", "noir"}
local FOGS = {{orig.fs, orig.fe, orig.fc}, {40, 500, C(205,215,230)}, {20, 220, C(190,200,215)}, {0, 80, C(120,130,150)}}
function applyWorld()
	local f = FOGS[S.fog + 1]
	if S.bright then Lighting.FogEnd = 1e5 else Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = f[1], f[2], f[3] end
	local c = CCS[S.cc]
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = c[2], c[3], c[4], c[5]
	bloom.Enabled = S.bloom > 0; bloom.Intensity = ({0, 0.8, 1.8})[S.bloom + 1]
	rays.Enabled = S.rays; dof.Enabled = S.dof
	workspace.Gravity = S.grav
	TS:Create(blur, TweenInfo.new(0.3), {Size = (open and S.blurMenu) and 16 or 0}):Play()
end
local function mkPart() return keep(new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	Transparency = 1, Size = Vector3.new(90, 1, 90)}, workspace)) end
fxTop, fxLow = mkPart(), mkPart()
fxLow.Size = Vector3.new(70, 1, 70)
WEATHER = {
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
WEATHER.smoke = {"💨 Дым", false, 14, {Texture = "rbxasset://textures/particles/smoke_main.dds", Lifetime = NR(5, 7), Speed = NR(1, 3),
	Size = NS({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 9)}), Rotation = NR(0, 360), RotSpeed = NR(-20, 20),
	Transparency = NS({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.3, 0.65), NumberSequenceKeypoint.new(1, 1)}),
	Color = ColorSequence.new(C(190, 190, 205)), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0.6, 0.3, 0)}}
WEATHER.dust = {"🌫 Пыль", false, 40, {Texture = "rbxasset://textures/particles/smoke_main.dds", Lifetime = NR(4, 6), Speed = NR(0.5, 2), Size = NS(0.9),
	Transparency = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(1, 1)}),
	Color = ColorSequence.new(C(210, 190, 150)), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(2, 0, 0.5)}}
WEATHER.embers = {"🔥 Искры", false, 30, {Lifetime = NR(2, 3.5), Speed = NR(2, 6), Size = NS(0.18), LightEmission = 1, Color = ColorSequence.new(C(255, 160, 40), C(255, 60, 20)),
	Transparency = NS({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, 3, 0)}}
W_ORDER = {"rain", "snow", "sakura", "leaves", "confetti", "fireflies", "bubbles", "stars", "smoke", "dust", "embers"}
local emit = {}
for k, d in pairs(WEATHER) do
	local e = new("ParticleEmitter", d[4], d[2] and fxTop or fxLow)
	e.Rate = d[3]; e.Enabled = false
	emit[k] = e
end
function applyWeather()
	for k, e in pairs(emit) do
		e.Enabled = S.wx[k] == true
		e.Rate = WEATHER[k][3] * S.wamt / 2
	end
end
task.spawn(function()
	while alive do
		task.wait(math.random(4, 10))
		if S.wx.rain and S.thunder then
			for _ = 1, math.random(1, 2) do
				flash.Brightness = 0.55
				TS:Create(flash, TweenInfo.new(0.35), {Brightness = 0}):Play()
				task.wait(0.25)
			end
		end
	end
end)
function applyChar()
	local hrp = root()
	if not hrp then return end
	for _, o in ipairs(hrp:GetChildren()) do
		if string.sub(o.Name, 1, 10) == "LauncherFx" then pcall(function() o:Destroy() end) end
	end
	local acc = ACCENTS[S.acc]
	if S.trail then
		local a0 = new("Attachment", {Name = "LauncherFxA0", Position = Vector3.new(0, 1, 0)}, hrp)
		local a1 = new("Attachment", {Name = "LauncherFxA1", Position = Vector3.new(0, -1, 0)}, hrp)
		new("Trail", {Name = "LauncherFxTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 0.8, LightEmission = 1, Color = RAINBOW,
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	local A = S.auras
	local SM = "rbxasset://textures/particles/smoke_main.dds"
	if A.fire then new("Fire", {Name = "LauncherFxAura1", Size = 7, Heat = 9, Color = acc, SecondaryColor = Color3.new(1, 1, 1)}, hrp) end
	if A.smoke then
		new("ParticleEmitter", {Name = "LauncherFxAura2", Texture = SM, Rate = 14, Lifetime = NR(2, 3.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Top, Rotation = NR(0, 360), RotSpeed = NR(-30, 30), Acceleration = Vector3.new(0, 1.5, 0),
			Size = NS({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5)}), Color = ColorSequence.new(acc:Lerp(Color3.new(1, 1, 1), 0.4), C(70, 70, 85)),
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.4, 0.6), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if A.toxic then
		new("ParticleEmitter", {Name = "LauncherFxAura3", Texture = SM, Rate = 18, Lifetime = NR(2, 3), Speed = NR(2, 4), SpreadAngle = Vector2.new(40, 40),
			EmissionDirection = Enum.NormalId.Top, Rotation = NR(0, 360), LightEmission = 0.6, Acceleration = Vector3.new(0, 2, 0),
			Size = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)}), Color = ColorSequence.new(C(120, 255, 90), C(40, 120, 30)),
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if A.ice then
		new("ParticleEmitter", {Name = "LauncherFxAura4", Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 24, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3),
			SpreadAngle = Vector2.new(180, 180), Size = NS({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}), LightEmission = 1,
			Color = ColorSequence.new(C(190, 235, 255), C(90, 170, 255))}, hrp)
	end
	if A.sparkles then new("Sparkles", {Name = "LauncherFxAura5", SparkleColor = acc}, hrp) end
	if A.orbs then
		new("ParticleEmitter", {Name = "LauncherFxAura6", Rate = 22, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NS(0.4),
			LightEmission = 1, Color = ColorSequence.new(acc), Transparency = NS({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if S.glow > 0 then new("PointLight", {Name = "LauncherFxLight", Color = acc, Brightness = ({0, 2, 5})[S.glow + 1], Range = 18}, hrp) end
end
conn(lp.CharacterAdded, function(ch)
	ch:WaitForChild("HumanoidRootPart"); task.wait(0.3)
	stopFly()
	applyChar()
end)
end -- конец мира и погоды

---------------------------------------------------------------- HUD
do
local hudGui = keep(new("ScreenGui", {Name = "LauncherHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60}, PG))
local hud = new("Frame", {Position = UDim2.fromOffset(S.hudPosX, S.hudPosY), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), BorderSizePixel = 0, Active = true}, hudGui)
bind(hud, "BackgroundColor3", "bg"); round(hud, 12)
bind(new("UIStroke", {Thickness = 1.5, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, hud), "Color", "rim")
local hudLayout = new("UIListLayout", {Padding = UDim.new(0, 10), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, hud)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7)}, hud)
local hudScale = new("UIScale", {}, hud)
local hudL, hudKeys = {}, {"fps", "ping", "exec", "mem", "time", "players"}
for k, name in ipairs(hudKeys) do
	hudL[name] = new("TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Font = Enum.Font.GothamBold,
		TextSize = 15, Text = "", LayoutOrder = k}, hud)
	bind(hudL[name], "TextColor3", "text")
end
local hdragStart, hBase = nil, nil
hud.InputBegan:Connect(function(i)
	if isPress(i) then
		hdragStart = i.Position; hBase = Vector2.new(S.hudPosX, S.hudPosY)
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				hdragStart = nil
				S.hudPosX = hud.Position.X.Offset; S.hudPosY = hud.Position.Y.Offset
				isDirty = true
			end
		end)
	end
end)
conn(UIS.InputChanged, function(i)
	if hdragStart and isMove(i) then
		local d = i.Position - hdragStart
		hud.Position = UDim2.fromOffset(hBase.X + d.X, hBase.Y + d.Y)
	end
end)
function applyHud()
	hud.Visible = S.hud
	hudLayout.FillDirection = S.hudStack and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	hudLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	hudScale.Scale = S.hudScale
	hud.BackgroundTransparency = S.hudAlpha
	hudL.fps.Visible = S.hudFps; hudL.ping.Visible = S.hudPing; hudL.exec.Visible = S.hudExec
	hudL.mem.Visible = S.hudMem; hudL.time.Visible = S.hudTime; hudL.players.Visible = S.hudPlayers
	if not hdragStart then hud.Position = UDim2.fromOffset(S.hudPosX, S.hudPosY) end
end
function getPing()
	local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
	if ok and v then return math.floor(v) end
	return math.floor(lp:GetNetworkPing() * 1000)
end
local function getMem()
	local ok, v = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
	return ok and math.floor(v) or 0
end
local GOOD, MID, BAD = C(110,255,140), C(255,215,90), C(255,95,95)
function updateHud(fps)
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
end -- конец HUD

---------------------------------------------------------------- кнопка открытия
do
local sgui = keep(new("ScreenGui", {Name = "LauncherToggle", ResetOnSpawn = false, DisplayOrder = 70, IgnoreGuiInset = true}, PG))
local tbtn = new("TextButton", {Text = "", AnchorPoint = Vector2.new(0, 0), BorderSizePixel = 0, AutoButtonColor = false}, sgui)
local tbtnE = bind(tbtn, "BackgroundColor3", "acc")
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

function applyButton()
	local w, h = S.btnSize, S.btnSize
	if S.btnStyle == "pill" then w = S.btnSize * 2.4; h = S.btnSize * 0.75 end
	tbtn.Size = UDim2.fromOffset(w, h)
	tbtn.Position = UDim2.fromOffset(S.btnPosX, S.btnPosY)
	local st = S.btnStyle
	tcorner.CornerRadius = st == "square" and UDim.new(0.24, 0) or UDim.new(0.5, 0)
	setRole(tbtnE, st == "ring" and "bg" or "acc")
	tbtn.BackgroundTransparency = S.btnAlpha
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
	thandle.Position = UDim2.fromOffset(S.btnPosX + w / 2 - 2, S.btnPosY + h / 2 - 2)
end
applyButton()

local isDragging, dragStartPos, btnStartPos, moved = false, nil, nil, false
tbtn.InputBegan:Connect(function(input)
	if isPress(input) then
		isDragging, moved, dragStartPos, btnStartPos = true, false, input.Position, Vector2.new(S.btnPosX, S.btnPosY)
		lastTouch = os.clock()
	end
end)
conn(UIS.InputChanged, function(input)
	if isDragging and isMove(input) then
		local delta = input.Position - dragStartPos
		if delta.Magnitude > 5 then moved = true end
		if moved then
			S.btnPosX = btnStartPos.X + delta.X
			S.btnPosY = btnStartPos.Y + delta.Y
			applyButton()
		end
	end
end)
conn(UIS.InputEnded, function(input)
	if isPress(input) and isDragging then
		isDragging = false
		if not moved then
			setOpen(not open)
			local w = S.btnSize
			local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(S.btnPosX + tbtn.Size.X.Offset / 2, S.btnPosY + tbtn.Size.Y.Offset / 2),
				Size = UDim2.fromOffset(w * 0.6, w * 0.6), BackgroundColor3 = ACCENTS[S.acc], BackgroundTransparency = 0.4, BorderSizePixel = 0}, sgui)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, r)
			TS:Create(r, TweenInfo.new(0.45), {Size = UDim2.fromOffset(w * 2, w * 2), BackgroundTransparency = 1}):Play()
			task.delay(0.5, function() pcall(function() r:Destroy() end) end)
		else
			isDirty = true
			if S.btnSnap then
				local vp = workspace.CurrentCamera.ViewportSize
				if S.btnPosX < vp.X / 2 then S.btnPosX = 10 else S.btnPosX = vp.X - tbtn.Size.X.Offset - 10 end
				applyButton()
			end
		end
	end
end)
local isResizing, rsStart, rsBase = false, nil, nil
thandle.InputBegan:Connect(function(input)
	if isPress(input) then isResizing = true; rsStart = input.Position; rsBase = S.btnSize end
end)
conn(UIS.InputChanged, function(input)
	if isResizing and isMove(input) then
		local delta = input.Position - rsStart
		S.btnSize = math.clamp(rsBase + (delta.X + delta.Y) / 2, 36, 140)
		applyButton()
	end
end)
conn(UIS.InputEnded, function(input)
	if isPress(input) and isResizing then isResizing = false; isDirty = true end
end)
local curA = 0
conn(RS.RenderStepped, function(dt)
	local t = os.clock()
	tringG.Rotation = (t * ({0, 90, 240})[S.btnSpin + 1]) % 360
	if S.btnGlow and S.btnStyle ~= "ring" then tring.Thickness = 3 + 1.5 * (0.5 + 0.5 * math.sin(t * 2.5)) end
	local idle = S.btnFade and not isDragging and not open and (t - lastTouch) > 3
	local base = S.btnStyle == "ring" and math.max(0.7, S.btnAlpha) or S.btnAlpha
	local target = idle and math.clamp(base + 0.5, 0, 0.92) or base
	curA += (target - curA) * math.min(1, dt * 6)
	tbtn.BackgroundTransparency = curA
	ticon.TextTransparency = idle and 0.5 or 0
	tlabel.TextTransparency = idle and 0.5 or 0
end)
end -- конец кнопки

M.load(50, "Сеть…")

---------------------------------------------------------------- СЕТЬ (необязательный сервер): кто с скриптом, друзья, управление, выдачи
do
local NET = {all = {}, online = {}, friends = {}, friendSet = {}, incoming = {}, role = "user", ok = false, ctlAllow = {}, controlling = {},
	names = {}, ctlLast = 0, indicators = {}}
M.NET = NET
function M.level() return math.floor(math.sqrt((S.xp or 0) / 20)) + 1 end
function M.refreshName() M.nameLabel.Text = "👤 " .. lp.DisplayName .. " · Lv " .. M.level() end
function M.addXp(n) S.xp = (S.xp or 0) + n; isDirty = true; M.refreshName() end
function M.addCoins(n) S.coins = (S.coins or 0) + n; isDirty = true end
M.refreshName()

local function baseUrl()
	local u = tostring((S.chatUrl and S.chatUrl ~= "") and S.chatUrl or DEFAULT_SERVER):gsub("%s+", "")
	u = u:gsub("/+$", "")
	return u
end
M.baseUrl = baseUrl
local function q(s) return HS:UrlEncode(tostring(s)) end
local function req(method, path, body)
	local u = baseUrl()
	local rq = request or http_request or (syn and syn.request)
	if u == "" or not rq then return nil end
	local o = {Url = u .. path, Method = method, Headers = {["Content-Type"] = "application/json"}}
	if body then o.Body = HS:JSONEncode(body) end
	local ok, res = pcall(rq, o)
	if not ok or not res or res.StatusCode ~= 200 then return nil end
	local ok2, d = pcall(HS.JSONDecode, HS, res.Body)
	return ok2 and d or nil
end
NET.req = req

-- роли: creator/tester/helper/rank по нику (без сервера) + роли с сервера
local ROLE = {creator = {"👑 Создатель", "#FFC83C"}, owner = {"👑 Создатель", "#FFC83C"}, admin = {"🛡 Админ", "#FF5050"}, tester = {"🧪 Тестер", "#5CFF8A"},
	helper = {"🛠 Помощник", "#5CB8FF"}, vip = {"⭐ VIP", "#C070FF"}, rank = {"🏅 Ранг", "#FFB070"}}
M.ROLE = ROLE
function M.tagOf(p)
	for _, u in ipairs(NET.online) do
		if u.uid == p.UserId and u.job == game.JobId and u.job ~= "" then return u end
	end
end
function M.roleFor(p)
	local r = roleOfName(p.Name)
	if not r and p == lp and (S.grantedRole or "") ~= "" then r = S.grantedRole end
	if not r then local u = M.tagOf(p); if u and u.role and u.role ~= "user" then r = u.role end end
	return r
end

local DESIGN_KEYS = {"theme", "acc", "view", "shape", "size", "alpha", "grad", "rim", "tilt", "zoom", "spread", "depth", "btnStyle", "btnIcon", "btnGlow",
	"btnRainbow", "hudScale", "hudAlpha", "lyricStyle", "openAnim", "cc", "bloom", "fog", "vfx", "vfxP", "wx", "auras", "orbits"}
local function myDesign() local d = {}; for _, k in ipairs(DESIGN_KEYS) do d[k] = S[k] end; return clean(d) end
local gameName = "?"
task.spawn(function()
	local ok, i = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
	if ok and i then gameName = i.Name; M.gameName = i.Name end
end)
local function hello()
	local d = req("POST", "/hello", {uid = lp.UserId, name = lp.Name, display = lp.DisplayName, place = game.PlaceId, job = game.JobId,
		game = S.showGame and gameName or "", status = S.status or "", level = M.level(), privacy = S.privacy, frame = S.frame, badge = S.badge,
		exec = execName, rank = S.rankName, design = myDesign(), v = 4, dev = deviceName, title = S.profTitle, bio = S.profBio, banner = S.profBanner,
		nameStyle = S.nameStyle, avShape = S.avShape, frameThick = S.frameThick, frameColor = S.frameColor, colors = S.profColors})
	if d then NET.ok = true; NET.role = d.role or "user" else NET.ok = false end
end
local function refreshOnline()
	local d = req("GET", "/online?uid=" .. lp.UserId)
	if d and d.users then
		NET.online = d.users
		for _, u in ipairs(d.users) do NET.names[u.uid] = u.display or u.name end
	end
	local allU = req("GET", "/all?uid=" .. lp.UserId)
	if allU and allU.users then NET.all = allU.users; for _, u in ipairs(allU.users) do NET.names[u.uid] = u.display or u.name end end
	if d and d.users and M.onPresence then pcall(M.onPresence, d.users) end
	local f = req("GET", "/friends?uid=" .. lp.UserId)
	if f then
		local prevN = #NET.incoming
		NET.friends = f.friends or {}; NET.incoming = f.incoming or {}
		if #NET.incoming > prevN then local u = NET.incoming[#NET.incoming]; M.notify("🤝 Запрос в друзья от " .. tostring(u.display or u.name), 6) end
		NET.friendSet = {}
		for _, u in ipairs(NET.friends) do NET.friendSet[u.uid] = true; NET.names[u.uid] = u.display or u.name end
		for _, u in ipairs(NET.incoming) do NET.names[u.uid] = u.display or u.name end
	end
	NET.dirty = true
end
M.refreshOnline = refreshOnline
function NET.friendAction(uid, action)
	task.spawn(function() req("POST", "/friend", {uid = lp.UserId, to = uid, action = action}); refreshOnline() end)
end
-- выдачи от админа: приходят через сервер
local function pollInbox()
	local d = req("GET", "/inbox?uid=" .. lp.UserId)
	if not (d and d.items) then return end
	for _, it in ipairs(d.items) do
		local from = tostring(it.from or "админ")
		if it.type == "coins" then M.addCoins(tonumber(it.n) or 0); toast("🎁 +" .. tostring(it.n) .. " монет от " .. from, 4)
		elseif it.type == "xp" then M.addXp(tonumber(it.n) or 0); toast("🎁 +" .. tostring(it.n) .. " XP от " .. from, 4)
		elseif it.type == "rank" then S.rankName = tostring(it.name or ""); isDirty = true; toast("🏅 Тебе выдали ранг: " .. S.rankName, 4)
		elseif it.type == "role" then S.grantedRole = tostring(it.name or ""); isDirty = true; toast("🎖 Тебе выдана роль: " .. S.grantedRole, 4)
		elseif it.type == "admin" then S.adminGranted = true; isDirty = true; toast("🛡 Тебе выдали админ-меню (перезапусти скрипт)", 6) end
	end
end
function NET.grant(target, typ, n, name)
	if not NET.ok then return false end
	local d = req("POST", "/grant", {uid = lp.UserId, target = target, type = typ, n = n, name = name})
	return d and d.ok
end

-- удалённое управление (только с явного разрешения, всегда можно отключить)
local function sendCtl(to, cmd, data) task.spawn(function() req("POST", "/ctl", {from = lp.UserId, to = to, cmd = cmd, data = data or {}}) end) end
NET.sendCtl = sendCtl
local function revoke(uid)
	NET.ctlAllow[uid] = nil; M.remote = nil
	if NET.indicators[uid] then pcall(function() NET.indicators[uid]:Destroy() end); NET.indicators[uid] = nil end
	sendCtl(uid, "end")
end
local function allow(uid, mode)
	NET.ctlAllow[uid] = mode
	sendCtl(uid, "ok", {mode = mode})
	NET.indicators[uid] = toast("🎮 " .. tostring(NET.names[uid] or uid) .. " подключён (" .. (mode == "move" and "движение" or "просмотр") .. ")", 1e6,
		{{"Отключить", function() revoke(uid) end, true}})
end
local function ctlPoll()
	local d = req("GET", "/ctlpoll?uid=" .. lp.UserId .. "&since=" .. NET.ctlLast)
	if not (d and d.msgs) then return end
	for _, m in ipairs(d.msgs) do
		NET.ctlLast = math.max(NET.ctlLast, m.id)
		local from, data = m.from, m.data or {}
		local nm = tostring(NET.names[from] or from)
		if m.cmd == "req" then
			toast("🎮 " .. nm .. " просит подключиться к твоему персонажу", 25, {
				{"Смотреть", function() allow(from, "view") end, true}, {"Движение", function() allow(from, "move") end}, {"Нет", function() sendCtl(from, "no") end, true}})
		elseif m.cmd == "ok" then
			NET.controlling[from] = data.mode; toast("✅ " .. nm .. " разрешил (" .. tostring(data.mode) .. ")", 3)
			local pl = Players:GetPlayerByUserId(from)
			if pl and M.spectate then M.spectate(pl) end
		elseif m.cmd == "no" then toast("❌ " .. nm .. " отказал", 3)
		elseif m.cmd == "move" and NET.ctlAllow[from] == "move" then
			M.remote = {x = tonumber(data.x) or 0, z = tonumber(data.z) or 0, exp = os.clock() + 0.6}
		elseif m.cmd == "jump" and NET.ctlAllow[from] == "move" then
			local h = hum(); if h then h.Jump = true end
		elseif m.cmd == "ring" then if M.incomingCall then M.incomingCall(from, nm) end
		elseif m.cmd == "ans" then if M.callState then M.callState(from, true) end
		elseif m.cmd == "hang" then if M.callState then M.callState(from, false) end
		elseif m.cmd == "beep" then if M.beep then M.beep(nm) end
		elseif m.cmd == "end" then
			NET.ctlAllow[from] = nil; NET.controlling[from] = nil; M.remote = nil
			if NET.indicators[from] then pcall(function() NET.indicators[from]:Destroy() end); NET.indicators[from] = nil end
			if M.stopSpectate then M.stopSpectate() end
			toast("Сеанс с " .. nm .. " завершён", 3)
		end
	end
end

task.spawn(function()
	local n = 0
	while alive do
		if baseUrl() ~= "" then
			if n % 8 == 0 then hello() end
			if NET.ok then
				if n % 4 == 0 then refreshOnline() end
				if n % 3 == 0 then pollInbox() end
			end
		end
		n += 1
		task.wait(1.5)
	end
end)
task.spawn(function()
	while alive do
		local active = next(NET.ctlAllow) or next(NET.controlling) or M.call or M.callOut
		if NET.ok then pcall(ctlPoll) end
		task.wait(active and 0.35 or 2)
	end
end)
-- опыт и монеты: каждые 30 секунд игры + ежедневная награда
task.spawn(function()
	local today = os.date("%Y%m%d")
	if S.lastDaily ~= today then
		S.lastDaily = today; M.addXp(20); M.addCoins(50); toast("📅 Ежедневная награда: +20 XP и +50 монет", 5)
	end
	while alive do
		task.wait(30)
		S.playMin = (S.playMin or 0) + 0.5
		M.addXp(1); M.addCoins(1)
	end
end)

-- метки над головой: роль по нику (у всех) + значок скрипта у тех, кто с ним играет
local tagFolder = keep(new("Folder", {Name = "LauncherTags"}, PG))
task.spawn(function()
	while alive do
		task.wait(2)
		local want = {}
		if S.showTags then
			for _, p in ipairs(Players:GetPlayers()) do
				local u = p ~= lp and M.tagOf(p)
				local rl = p ~= lp and M.roleFor(p)
				local hd = (u or rl) and p.Character and p.Character:FindFirstChild("Head")
				if hd then
					want[p.Name] = true
					local bb = tagFolder:FindFirstChild(p.Name)
					if not bb or bb.Adornee ~= hd then
						if bb then bb:Destroy() end
						bb = new("BillboardGui", {Name = p.Name, Adornee = hd, AlwaysOnTop = true, Size = UDim2.fromOffset(300, 28), StudsOffset = Vector3.new(0, 4.3, 0)}, tagFolder)
						local pill = new("Frame", {Name = "P", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(14, 14, 22), BackgroundTransparency = 0.2, BorderSizePixel = 0}, bb)
						new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, pill)
						new("UIStroke", {Name = "St", Thickness = 1.5, Transparency = 0.15}, pill)
						local tl = new("TextLabel", {Name = "T", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Font = Enum.Font.GothamBold, TextScaled = true}, pill)
						new("UITextSizeConstraint", {MaxTextSize = 14, MinTextSize = 8}, tl)
					end
					local r = rl and ROLE[rl]
					local parts = {}
					if u then parts[#parts + 1] = (r and r[1] or "Игрок") .. " (скрипт)" elseif r then parts[#parts + 1] = r[1] end
					if u then
						parts[#parts + 1] = "Lv" .. tostring(u.level or 1)
						if (u.exec or "") ~= "" then parts[#parts + 1] = tostring(u.exec) end
						if (u.badge or "") ~= "" then parts[#parts + 1] = tostring(u.badge) end
						if (u.rank or "") ~= "" then parts[#parts + 1] = "[" .. tostring(u.rank) .. "]" end
						if (u.status or "") ~= "" then parts[#parts + 1] = tostring(u.status) end
					end
					local colr = r and Color3.fromHex(r[2]) or Color3.fromRGB(140, 190, 255)
					bb.P.T.Text = table.concat(parts, " · ")
					bb.P.T.TextColor3 = colr
					bb.P.St.Color = colr
				end
			end
		end
		for _, o in ipairs(tagFolder:GetChildren()) do if not want[o.Name] then o:Destroy() end end
	end
end)

---------------- приложение: друзья и онлайн
RUN.friends = function(c)
	local me = c
	local function personCard(u, isFriend)
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 104), "card2", 12)
		local r = ROLE[u.role or ""]
		label(fr, (r and (r[1] .. " ") or "") .. tostring(u.display or u.name) .. "  ·  Lv " .. tostring(u.level or 1) .. ((u.badge or "") ~= "" and ("  " .. u.badge) or "") ..
			(u.online == false and "  (не в сети)" or ""), 15, "text", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 20), true)
		label(fr, ((u.game or "") ~= "" and ("🎮 " .. u.game) or "🎮 скрыто") .. ((u.exec or "") ~= "" and ("   💉 " .. u.exec) or "") .. ((u.status or "") ~= "" and ("   💬 " .. u.status) or ""),
			12, "sub", UDim2.new(0, 10, 0, 26), UDim2.new(1, -20, 0, 18))
		local br = new("Frame", {Position = UDim2.new(0, 6, 0, 50), Size = UDim2.new(1, -12, 0, 46), BackgroundTransparency = 1}, fr)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, br)
		local function B(t, cb, n, w) button(br, t, cb, UDim2.new(w or 0.25, -4, 1, 0), n) end
		if isFriend then
			B("🚪 Зайти", function()
				if u.place and u.job and u.job ~= "" then pcall(function() TeleportService:TeleportToPlaceInstance(u.place, u.job, lp) end) end
			end, true)
			B("🎨 Дизайн", function()
				for k, v in pairs(u.design or {}) do if type(v) == "table" or type(S[k]) == type(v) or S[k] == nil then S[k] = v end end
				applyAll(); M.VFX.all(); toast("Дизайн применён", 2.5)
			end, true)
			B("🎮 Упр.", function() sendCtl(u.uid, "req", {}); M.ctlTarget = u.uid; toast("Запрос отправлен", 2.5); M.openApp({id = "ctl", n = "Управление", i = "🎮"}) end, true)
			B("✕", function() NET.friendAction(u.uid, "remove") end, true)
		else
			B("➕ В друзья", function() NET.friendAction(u.uid, "request"); toast("Запрос отправлен", 2) end, false, 0.5)
		end
	end
	local function draw()
		reset(c)
		label(c, NET.ok and ("✅ Сервер подключён · твоя роль: " .. NET.role) or "⚠ Сервер не подключён. Адрес вводится в «Профиль» → Сеть.", 14, "text", nil, UDim2.new(1, 0, 0, 22), true)
		row(c, {{"🔄 Обновить", function() task.spawn(refreshOnline) end, true}})
		if #NET.incoming > 0 then
			head(c, "Запросы в друзья")
			for _, u in ipairs(NET.incoming) do
				local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
				label(fr, tostring(u.display or u.name), 15, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.45, 0, 1, 0), true)
				local a = button(fr, "Принять", function() NET.friendAction(u.uid, "accept") end, UDim2.new(0.25, 0, 0, 32)); a.Position = UDim2.new(0.5, 0, 0.5, -16)
				local d2 = button(fr, "✕", function() NET.friendAction(u.uid, "decline") end, UDim2.new(0.2, 0, 0, 32), true); d2.Position = UDim2.new(0.77, 0, 0.5, -16)
			end
		end
		head(c, "Друзья")
		if #NET.friends == 0 then label(c, "Пока пусто.", 13, "sub", nil, UDim2.new(1, 0, 0, 20)) end
		for _, u in ipairs(NET.friends) do personCard(u, true) end
		head(c, "Сейчас онлайн со скриптом")
		for _, u in ipairs(NET.online) do
			if u.uid ~= lp.UserId and not NET.friendSet[u.uid] then personCard(u, false) end
		end
	end
	draw()
	task.spawn(function()
		while content == me and alive do
			if NET.dirty then NET.dirty = false; draw() end
			task.wait(0.7)
		end
	end)
end

---------------- приложение: профиль (всё личное для каждого аккаунта)
RUN.profile = function(c)
	local me = c
	local av, stroke, grad
	local function draw()
		reset(c)
		local top = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 130), "card", 16)
		if S.profBg ~= 0 then top.BackgroundColor3 = pcolor(S.profBg) end
		av = new("ImageLabel", {Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(98, 98), BackgroundTransparency = 0, BorderSizePixel = 0}, top)
		bind(av, "BackgroundColor3", "card2"); round(av, 49)
		stroke = new("UIStroke", {Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, av)
		grad = new("UIGradient", {}, stroke)
		task.spawn(function()
			local img
			if S.avatarUrl ~= "" then img = fetchAsset(S.avatarUrl) end
			if not img then
				local ok, i = pcall(function() return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
				if ok then img = i end
			end
			if img and av.Parent then av.Image = img end
		end)
		local rl = M.roleFor(lp)
		local r = rl and ROLE[rl]
		local nm = label(top, (S.badge ~= "" and (S.badge .. " ") or "") .. lp.DisplayName .. (r and ("  " .. r[1]) or "") .. (S.rankName ~= "" and ("  [" .. S.rankName .. "]") or ""), 20, "text", UDim2.new(0, 128, 0, 10), UDim2.new(1, -140, 0, 28), true)
		if S.nameColor ~= 0 then nm.TextColor3 = pcolor(S.nameColor) end
		local lv = M.level()
		local base, nxt = (lv - 1) ^ 2 * 20, lv ^ 2 * 20
		label(top, "Уровень " .. lv .. "  ·  XP " .. (S.xp or 0) .. " / " .. nxt .. "  ·  🪙 " .. (S.coins or 0), 13, "sub", UDim2.new(0, 128, 0, 42), UDim2.new(1, -140, 0, 18))
		local bar = frame(top, UDim2.new(0, 128, 0, 66), UDim2.new(1, -150, 0, 10), "card2", 5)
		frame(bar, UDim2.new(), UDim2.new(math.clamp(((S.xp or 0) - base) / math.max(nxt - base, 1), 0, 1), 0, 1, 0), "acc", 5)
		label(top, "Играет: " .. (S.showGame and gameName or "скрыто") .. "  ·  " .. deviceName .. "  ·  " .. execName, 12, "sub", UDim2.new(0, 128, 0, 86), UDim2.new(1, -140, 0, 36))
		label(c, "Как получать XP: +1 каждые 30 сек в игре, +20 за ежедневный вход, плюс выдачи от админов. Монеты (🪙) идут так же и тратятся в «Магазине».", 12, "sub", nil, UDim2.new(1, 0, 0, 44))
		row(c, {{"🎨 Кастомизация профиля", function() M.openApp({id = "pcust", n = "Кастомизация", i = "🎨"}) end}, {"🌈 Цвета", function() M.openApp({id = "pcolors", n = "Цвета профиля", i = "🌈"}) end, true}, {"🛍 Магазин", function() M.openApp({id = "shop", n = "Магазин", i = "🛍"}) end, true}})
		head(c, "Статус (видят другие пользователи скрипта)")
		local sb = textbox(c, "например: фармлю, го в друзья", S.status, 38)
		sb.FocusLost:Connect(function() S.status = sb.Text:sub(1, 40); isDirty = true end)
		head(c, "Кто видит меня онлайн")
		row(c, {opt("Все", "privacy", "all", draw), opt("Друзья", "privacy", "friends", draw), opt("Скрыт", "privacy", "hidden", draw)})
		row(c, {tog("Показывать игру", "showGame", draw), tog("Метки над головой", "showTags", draw)})
		head(c, "Своя картинка аватара (png/jpg по ссылке; GIF Roblox не умеет)")
		local ub = textbox(c, "https://...png", S.avatarUrl, 38)
		row(c, {{"Применить", function() S.avatarUrl = ub.Text; isDirty = true; draw() end}, {"Сбросить", function() S.avatarUrl = ""; draw() end, true}})
		head(c, "Сеть (необязательно): адрес твоего сервера l3d_server.js")
		local nb = textbox(c, "http://...", S.chatUrl, 38)
		nb.FocusLost:Connect(function() S.chatUrl = nb.Text; isDirty = true end)
		label(c, NET.ok and ("✅ Сервер подключён, роль: " .. NET.role) or (baseUrl() == "" and "Без сервера не видно, кто ещё играет со скриптом, и не работают друзья и выдачи." or "⚠ Нет связи с сервером"), 13, "sub", nil, UDim2.new(1, 0, 0, 34))
		label(c, "Все данные (уровень, монеты, аватар, настройки) хранятся отдельно для каждого аккаунта Roblox.", 12, "sub", nil, UDim2.new(1, 0, 0, 30))
	end
	draw()
	task.spawn(function()
		while content == me and alive do
			local t = os.clock()
			if stroke and stroke.Parent then
				local f = S.frame
				stroke.Enabled = f ~= "none"
				grad.Enabled = f == "rainbow" or f == "neon" or f == "gold"
				stroke.Color = ACCENTS[S.acc]; stroke.Thickness = 4
				if f == "rainbow" then grad.Color = RAINBOW; grad.Rotation = (t * 120) % 360
				elseif f == "neon" then grad.Color = ColorSequence.new(C(255, 60, 220), C(60, 220, 255)); grad.Rotation = (t * 200) % 360; stroke.Thickness = 5
				elseif f == "gold" then grad.Color = ColorSequence.new(C(255, 220, 90), C(190, 130, 20)); grad.Rotation = (t * 60) % 360
				elseif f == "fire" then grad.Color = ColorSequence.new(C(255, 220, 60), C(255, 60, 20)); grad.Rotation = (t * 300) % 360; stroke.Thickness = 4 + math.sin(t * 9)
				elseif f == "pulse" then stroke.Thickness = 3 + 3 * (0.5 + 0.5 * math.sin(t * 4)) end
			end
			task.wait(0.03)
		end
	end)
end

---------------- управление другом (панель)
RUN.ctl = function(c)
	local uid = M.ctlTarget
	local nm = tostring(NET.names[uid] or uid)
	label(c, "Управление: " .. nm, 18, "text", nil, UDim2.new(1, 0, 0, 26), true)
	label(c, NET.controlling[uid] == "move" and "Доступ: движение" or (NET.controlling[uid] == "view" and "Доступ: только просмотр" or "Ждём разрешения от игрока…"), 14, "sub", nil, UDim2.new(1, 0, 0, 20))
	local function hold(b, vx, vz)
		b.InputBegan:Connect(function(i)
			if not isPress(i) then return end
			local held = true
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then held = false end end)
			task.spawn(function()
				while held and alive do
					local cam = workspace.CurrentCamera.CFrame
					local f, rt = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z), Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
					local v = (f.Magnitude > 0 and f.Unit or f) * -vz + (rt.Magnitude > 0 and rt.Unit or rt) * vx
					sendCtl(uid, "move", {x = v.X, z = v.Z}); task.wait(0.25)
				end
			end)
		end)
	end
	local r1 = row(c, {{"", function() end}, {"▲", function() end}, {"", function() end}})
	local r2 = row(c, {{"◀", function() end}, {"▼", function() end}, {"▶", function() end}})
	local b1, b2 = {}, {}
	for _, o in ipairs(r1:GetChildren()) do if o:IsA("TextButton") then b1[#b1 + 1] = o end end
	for _, o in ipairs(r2:GetChildren()) do if o:IsA("TextButton") then b2[#b2 + 1] = o end end
	hold(b1[2], 0, -1); hold(b2[1], -1, 0); hold(b2[2], 0, 1); hold(b2[3], 1, 0)
	row(c, {{"⤒ Прыжок", function() sendCtl(uid, "jump") end}, {"■ Отключиться", function() sendCtl(uid, "end"); NET.controlling[uid] = nil; M.stopSpectate() end, true}})
	label(c, "Двигать можно только если игрок разрешил «Движение» и вы в одном сервере. Он в любой момент может отключить тебя.", 12, "sub", nil, UDim2.new(1, 0, 0, 40))
end
end -- конец сети
M.load(62, "Визуалы и музыка…")

---------------------------------------------------------------- ВИЗУАЛЫ (19 эффектов, включай сколько хочешь)
do
local VFX = {defs = {}, order = {}, active = {}}
M.VFX = VFX
local vgui = keep(new("ScreenGui", {Name = "LauncherVFX", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 30}, PG))
local function vp() return workspace.CurrentCamera.ViewportSize end
local function cnt(n) return math.max(1, math.floor(n * PERF + 0.5)) end
local function mouse() return UIS:GetMouseLocation() end
local function N(k, n, lo, hi, st, d) return {k = k, n = n, kind = "num", min = lo, max = hi, st = st, d = d} end
local function Cc(k, n, d) return {k = k, n = n, kind = "col", d = d} end
local function Bb(k, n, d) return {k = k, n = n, kind = "bool", d = d} end
local function def(id, name, icon, params, build)
	VFX.defs[id] = {id = id, name = name, icon = icon, params = params, build = build}
	VFX.order[#VFX.order + 1] = id
end
local function pv(id, k)
	local p = S.vfxP[id]
	local v = p and p[k]
	if v == nil then
		for _, d in ipairs(VFX.defs[id].params) do if d.k == k then v = d.d end end
	end
	return v
end
local function destroyEff(id)
	local a = VFX.active[id]
	if a then
		pcall(function() if a.cleanup then a.cleanup() end; a.holder:Destroy() end)
		VFX.active[id] = nil
	end
end
function VFX.build(id)
	destroyEff(id)
	if not S.vfx[id] then return end
	local holder = new("Frame", {Name = id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0}, vgui)
	local function Pm(k) return pv(id, k) end
	local ok, upd, cleanup = pcall(VFX.defs[id].build, holder, Pm)
	if ok then VFX.active[id] = {holder = holder, upd = upd, cleanup = cleanup}
	else holder:Destroy(); warn("[L3D] визуал " .. id .. ": " .. tostring(upd)) end
end
function VFX.all() for _, id in ipairs(VFX.order) do VFX.build(id) end end
function VFX.destroyAll() for id in pairs(VFX.active) do destroyEff(id) end end
conn(RS.RenderStepped, function(dt)
	local t = os.clock()
	for id, a in pairs(VFX.active) do
		if a.upd then
			local ok, e = pcall(a.upd, dt, t)
			if not ok then a.upd = nil; warn("[L3D] визуал " .. id .. ": " .. tostring(e)) end
		end
	end
end)
local function loud()
	local s = M.MU and M.MU.sound
	return (s and s.IsPlaying) and math.min(s.PlaybackLoudness / 450, 1) or 0
end

def("vignette", "Виньетка", "◐", {N("size", "Ширина", 0.05, 0.6, 0.05, 0.3), N("dark", "Тёмность", 0.1, 1, 0.05, 0.65), Cc("color", "Цвет", 10)}, function(h, P)
	local s, dk = P("size"), P("dark")
	local seq = NS({NumberSequenceKeypoint.new(0, 1 - dk), NumberSequenceKeypoint.new(1, 1)})
	local fs = {}
	local function edge(pos, size, rot)
		local f = new("Frame", {Position = pos, Size = size, BorderSizePixel = 0}, h)
		new("UIGradient", {Rotation = rot, Transparency = seq}, f); fs[#fs + 1] = f
	end
	edge(UDim2.new(), UDim2.new(1, 0, s, 0), 90); edge(UDim2.new(0, 0, 1 - s, 0), UDim2.new(1, 0, s, 0), 270)
	edge(UDim2.new(), UDim2.new(s * 0.6, 0, 1, 0), 0); edge(UDim2.new(1 - s * 0.6, 0, 0, 0), UDim2.new(s * 0.6, 0, 1, 0), 180)
	return function(dt, t) local c = pcolor(P("color"), t); for _, f in ipairs(fs) do f.BackgroundColor3 = c end end
end)

def("scan", "Линии (CRT)", "≡", {N("gap", "Шаг", 2, 40, 1, 4), N("thick", "Толщина", 1, 12, 1, 1), N("op", "Непрозрачность", 0.02, 1, 0.02, 0.25),
	N("speed", "Скорость", 0, 300, 10, 0), Cc("color", "Цвет", 10)}, function(h, P)
	local gap, th = P("gap"), P("thick")
	local box = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, gap * 2)}, h)
	local n = math.min(math.ceil(vp().Y / gap) + 2, 500)
	local ls = {}
	for i = 0, n - 1 do
		ls[#ls + 1] = new("Frame", {Position = UDim2.fromOffset(0, i * gap), Size = UDim2.new(1, 0, 0, th), BorderSizePixel = 0,
			BackgroundTransparency = 1 - P("op"), BackgroundColor3 = pcolor(P("color"))}, box)
	end
	local dyn = P("color") <= 0
	return function(dt, t)
		box.Position = UDim2.fromOffset(0, -gap + (t * P("speed")) % gap)
		if dyn then local c = pcolor(P("color"), t); for _, l in ipairs(ls) do l.BackgroundColor3 = c end end
	end
end)

def("grain", "Зерно плёнки", "░", {N("count", "Точек", 10, 300, 10, 80), N("size", "Размер", 1, 10, 1, 2), N("op", "Непрозрачность", 0.05, 1, 0.05, 0.3),
	N("rate", "Частота", 2, 60, 2, 20), Cc("color", "Цвет", 1)}, function(h, P)
	local V, n, ds, acc = vp(), cnt(P("count")), {}, 0
	for i = 1, n do ds[i] = new("Frame", {Size = UDim2.fromOffset(P("size"), P("size")), BorderSizePixel = 0}, h) end
	return function(dt, t)
		acc += dt
		if acc < 1 / P("rate") then return end
		acc = 0
		for _, d in ipairs(ds) do
			d.Position = UDim2.fromOffset(math.random(0, V.X), math.random(0, V.Y))
			d.BackgroundTransparency = 1 - P("op") * math.random()
			local g = math.random()
			d.BackgroundColor3 = P("color") == 1 and Color3.new(g, g, g) or pcolor(P("color"), t)
		end
	end
end)

def("border", "Рамка экрана", "▢", {N("thick", "Толщина", 1, 50, 1, 6), N("op", "Непрозрачность", 0.1, 1, 0.05, 0.85), N("speed", "Вращение", 0, 720, 15, 90),
	N("pulse", "Пульс", 0, 1, 0.05, 0.3), Cc("color", "Цвет", -1)}, function(h, P)
	local th = P("thick")
	local f = new("Frame", {Position = UDim2.fromOffset(th, th), Size = UDim2.new(1, -th * 2, 1, -th * 2), BackgroundTransparency = 1}, h)
	local st = new("UIStroke", {Thickness = th, Transparency = 1 - P("op"), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
	local g = new("UIGradient", {Color = P("color") == -1 and RAINBOW or ColorSequence.new(pcolor(P("color")))}, st)
	return function(dt, t)
		g.Rotation = (t * P("speed")) % 360
		st.Thickness = th * (1 + P("pulse") * 0.5 * math.sin(t * 3))
		if P("color") == 0 then g.Color = ColorSequence.new(ACCENTS[S.acc]) end
	end
end)

def("matrix", "Матрица", "ｱ", {N("cols", "Колонок", 4, 90, 2, 30), N("size", "Размер", 8, 40, 1, 18), N("speed", "Скорость", 40, 900, 20, 240),
	N("op", "Непрозрачность", 0.1, 1, 0.05, 0.8), Cc("color", "Цвет", 5)}, function(h, P)
	local V, n, sz = vp(), cnt(P("cols")), P("size")
	local G = {}
	for ch in ("0123456789ABCDEFXYZ#$%&*+<>=?"):gmatch(".") do G[#G + 1] = ch end
	local function rnd() local t = {}; for i = 1, 14 do t[i] = G[math.random(#G)] end; return table.concat(t, "\n") end
	local hh = sz * 14 * 1.15
	local cols = {}
	for i = 1, n do
		local l = new("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = sz, TextWrapped = false, Text = rnd(), TextColor3 = pcolor(P("color")),
			TextTransparency = 1 - P("op"), TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.fromOffset(sz, hh)}, h)
		new("UIGradient", {Rotation = 90, Transparency = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, l)
		cols[i] = {l = l, x = (i - 0.5) / n * V.X, y = -math.random(0, math.floor(V.Y)), v = 0.6 + math.random() * 0.8, tm = 0}
	end
	return function(dt, t)
		local sp, dyn = P("speed"), P("color") <= 0
		for i, c in ipairs(cols) do
			c.y += sp * c.v * dt
			if c.y > V.Y then c.y = -hh end
			c.l.Position = UDim2.fromOffset(c.x, c.y)
			c.tm += dt
			if c.tm > 0.12 then c.tm = 0; c.l.Text = rnd() end
			if dyn then c.l.TextColor3 = pcolor(P("color"), t, i * 0.02) end
		end
	end
end)

def("stars", "Мерцающие звёзды", "★", {N("count", "Количество", 10, 400, 10, 90), N("size", "Размер", 1, 10, 1, 2), N("speed", "Мерцание", 0.2, 10, 0.2, 2), Cc("color", "Цвет", 1)}, function(h, P)
	local n, ss = cnt(P("count")), {}
	for i = 1, n do
		local f = new("Frame", {Size = UDim2.fromOffset(P("size"), P("size")), Position = UDim2.fromScale(math.random(), math.random()), BorderSizePixel = 0}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		ss[i] = {f = f, ph = math.random() * 6.28}
	end
	return function(dt, t)
		local sp = P("speed")
		for i, s in ipairs(ss) do
			s.f.BackgroundTransparency = 0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * sp + s.ph))
			s.f.BackgroundColor3 = pcolor(P("color"), t, i * 0.01)
		end
	end
end)

local function floatDef(id, name, icon, kind, dir, d)
	def(id, name, icon, {N("count", "Количество", 5, 300, 5, d.n), N("size", "Размер", 2, 120, 1, d.s), N("speed", "Скорость", 5, 400, 5, d.v),
		N("sway", "Раскачка", 0, 150, 5, d.w), N("op", "Непрозрачность", 0.1, 1, 0.05, d.o), Cc("color", "Цвет", d.c)}, function(h, P)
		local V, n, ps = vp(), cnt(P("count")), {}
		local c0 = pcolor(P("color"))
		for i = 1, n do
			local sz = math.max(2, P("size") * (0.35 + math.random() * 0.65))
			local f = new("Frame", {Size = UDim2.fromOffset(sz, sz), BorderSizePixel = 0, BackgroundColor3 = c0, BackgroundTransparency = kind == "ring" and 1 or (1 - P("op"))}, h)
			if kind ~= "ember" then new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f) end
			local st
			if kind == "ring" then st = new("UIStroke", {Thickness = 1.5, Color = c0, Transparency = 1 - P("op")}, f) end
			ps[i] = {f = f, st = st, x = math.random() * V.X, y = math.random() * V.Y, v = 0.5 + math.random(), ph = math.random() * 6.28, sz = sz}
		end
		return function(dt, t)
			local sp, sw, dyn, op, ms = P("speed"), P("sway"), P("color") <= 0, P("op"), math.max(P("size"), 1)
			for i, p in ipairs(ps) do
				p.y += dir * sp * p.v * dt * (0.4 + p.sz / ms * 0.8)
				if dir < 0 and p.y < -p.sz then p.y = V.Y + p.sz; p.x = math.random() * V.X
				elseif dir > 0 and p.y > V.Y + p.sz then p.y = -p.sz; p.x = math.random() * V.X end
				p.f.Position = UDim2.fromOffset(p.x + math.sin(t * 0.9 + p.ph) * sw, p.y)
				if kind == "ember" then p.f.BackgroundTransparency = 1 - op * math.clamp(p.y / V.Y, 0, 1) end
				if dyn then
					local c = pcolor(P("color"), t, i * 0.03)
					p.f.BackgroundColor3 = c
					if p.st then p.st.Color = c end
				end
			end
		end
	end)
end
floatDef("bubbles", "Пузыри", "◯", "ring", -1, {n = 30, s = 46, v = 60, w = 25, o = 0.55, c = 6})
floatDef("snow2d", "Снег на экране", "❄", "dot", 1, {n = 80, s = 10, v = 70, w = 30, o = 0.9, c = 1})
floatDef("embers", "Искры", "✦", "ember", -1, {n = 50, s = 7, v = 140, w = 40, o = 0.95, c = 3})

def("trail", "След курсора", "☄", {N("len", "Длина", 3, 60, 1, 18), N("size", "Размер", 3, 60, 1, 16), N("op", "Непрозрачность", 0.1, 1, 0.05, 0.8), Cc("color", "Цвет", -1)}, function(h, P)
	local n, dots, hist = cnt(P("len")), {}, {}
	for i = 1, n do
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f); dots[i] = f
	end
	return function(dt, t)
		table.insert(hist, 1, mouse())
		if #hist > n * 2 + 2 then hist[#hist] = nil end
		for i, f in ipairs(dots) do
			local m = hist[math.min(#hist, i * 2 - 1)]
			local k = 1 - (i - 1) / n
			local s = P("size") * k
			f.Position = UDim2.fromOffset(m.X, m.Y); f.Size = UDim2.fromOffset(s, s)
			f.BackgroundTransparency = 1 - P("op") * k; f.BackgroundColor3 = pcolor(P("color"), t, i * 0.02)
		end
	end
end)

def("ripple", "Волны от кликов", "◎", {N("size", "Размер", 20, 500, 10, 140), N("time", "Время", 0.2, 3, 0.1, 0.7), N("thick", "Толщина", 1, 14, 1, 3), Cc("color", "Цвет", 0)}, function(h, P)
	local c = UIS.InputBegan:Connect(function(i)
		local ut = i.UserInputType
		if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
		local p = ut == Enum.UserInputType.Touch and (Vector2.new(i.Position.X, i.Position.Y) + GS:GetGuiInset()) or mouse()
		local col2 = pcolor(P("color"))
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(4, 4), BackgroundTransparency = 1}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		local st = new("UIStroke", {Thickness = P("thick"), Color = col2}, f)
		local ti = TweenInfo.new(P("time"), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TS:Create(f, ti, {Size = UDim2.fromOffset(P("size"), P("size"))}):Play()
		TS:Create(st, ti, {Transparency = 1}):Play()
		task.delay(P("time") + 0.1, function() pcall(function() f:Destroy() end) end)
	end)
	return nil, function() c:Disconnect() end
end)

def("bars", "Кино-полосы", "▬", {N("h", "Высота", 0.02, 0.3, 0.01, 0.1), N("op", "Непрозрачность", 0.1, 1, 0.05, 1), Cc("color", "Цвет", 10)}, function(h, P)
	for _, top in ipairs({true, false}) do
		new("Frame", {Position = top and UDim2.new() or UDim2.new(0, 0, 1 - P("h"), 0), Size = UDim2.new(1, 0, P("h"), 0), BorderSizePixel = 0,
			BackgroundColor3 = pcolor(P("color")), BackgroundTransparency = 1 - P("op")}, h)
	end
end)

def("tint", "Цветная плёнка", "▒", {N("op", "Сила", 0, 0.8, 0.02, 0.15), N("pulse", "Пульс", 0, 0.5, 0.02, 0.1), N("speed", "Скорость", 0.1, 8, 0.1, 1), Cc("color", "Цвет", 0)}, function(h, P)
	local f = new("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0}, h)
	return function(dt, t)
		f.BackgroundColor3 = pcolor(P("color"), t)
		f.BackgroundTransparency = 1 - math.clamp(P("op") + P("pulse") * math.sin(t * P("speed") * 3), 0, 1)
	end
end)

def("aurora", "Северное сияние", "≈", {N("n", "Полос", 1, 10, 1, 4), N("h", "Высота", 0.1, 1, 0.05, 0.5), N("speed", "Скорость", 0.05, 4, 0.05, 0.5),
	N("op", "Яркость", 0.1, 1, 0.05, 0.6), Cc("color", "Цвет", -1)}, function(h, P)
	local n, bs = cnt(P("n")), {}
	for i = 1, n do
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromScale(0.35 + math.random() * 0.25, P("h")), BorderSizePixel = 0}, h)
		new("UIGradient", {Rotation = 90, Transparency = NS({NumberSequenceKeypoint.new(0, 1 - P("op")), NumberSequenceKeypoint.new(1, 1)})}, f)
		bs[i] = {f = f, ph = math.random() * 6.28, sp = 0.6 + math.random()}
	end
	return function(dt, t)
		for i, b in ipairs(bs) do
			b.f.Position = UDim2.fromScale(0.5 + math.sin(t * P("speed") * b.sp + b.ph) * 0.35, 0)
			b.f.BackgroundColor3 = pcolor(P("color"), t, i / n * 0.35)
		end
	end
end)

def("viz", "Эквалайзер", "▮", {N("bars", "Столбцов", 8, 100, 2, 40), N("h", "Высота", 20, 700, 10, 180), N("gap", "Зазор", 0, 10, 1, 3),
	N("op", "Непрозрачность", 0.1, 1, 0.05, 0.85), Bb("top", "Сверху", false), Cc("color", "Цвет", -1)}, function(h, P)
	local V, n = vp(), cnt(P("bars"))
	local bw, bs, hv, top = V.X / n, {}, {}, P("top")
	for i = 1, n do
		bs[i] = new("Frame", {AnchorPoint = Vector2.new(0, top and 0 or 1), Position = UDim2.fromOffset((i - 1) * bw, top and 0 or V.Y), BorderSizePixel = 0}, h)
		hv[i] = 0
	end
	return function(dt, t)
		local lv = loud()
		for i, b in ipairs(bs) do
			local tg = lv * (0.25 + 0.75 * math.abs(math.sin(t * 2.3 + i * 0.7) * math.cos(t * 1.1 + i * 0.31)))
			hv[i] += (tg - hv[i]) * math.min(1, dt * 14)
			b.Size = UDim2.fromOffset(math.max(1, bw - P("gap")), math.max(2, hv[i] * P("h")))
			b.BackgroundColor3 = pcolor(P("color"), t, i / n * 0.6); b.BackgroundTransparency = 1 - P("op")
		end
	end
end)

def("orb2d", "Орбиты у курсора", "✺", {N("n", "Точек", 2, 40, 1, 8), N("r", "Радиус", 10, 300, 5, 44), N("speed", "Скорость", 0.1, 10, 0.1, 2.2),
	N("size", "Размер", 2, 40, 1, 8), Cc("color", "Цвет", -1)}, function(h, P)
	local n, ds = cnt(P("n")), {}
	for i = 1, n do
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(P("size"), P("size")), BorderSizePixel = 0}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f); ds[i] = f
	end
	return function(dt, t)
		local m = mouse()
		for i, f in ipairs(ds) do
			local a = t * P("speed") + i / n * math.pi * 2
			f.Position = UDim2.fromOffset(m.X + math.cos(a) * P("r"), m.Y + math.sin(a) * P("r"))
			f.BackgroundColor3 = pcolor(P("color"), t, i / n * 0.5)
		end
	end
end)

def("glow", "Свечение курсора", "☀", {N("size", "Размер", 20, 600, 10, 140), N("op", "Яркость", 0.05, 1, 0.05, 0.3), Cc("color", "Цвет", 0)}, function(h, P)
	local rs = {}
	for i = 1, 5 do
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f); rs[i] = f
	end
	return function(dt, t)
		local m, c = mouse(), pcolor(P("color"), t)
		for i, f in ipairs(rs) do
			local s = P("size") * (1 - (i - 1) * 0.18)
			f.Position = UDim2.fromOffset(m.X, m.Y); f.Size = UDim2.fromOffset(s, s)
			f.BackgroundColor3 = c; f.BackgroundTransparency = 1 - P("op") * 0.25
		end
	end
end)

def("media", "Картинка / видео", "🖼", {N("size", "Размер", 40, 1400, 10, 300), N("op", "Непрозрачность", 0.05, 1, 0.05, 1), N("x", "X", 0, 1, 0.01, 0.9),
	N("y", "Y", 0, 1, 0.01, 0.2), N("rot", "Поворот", -180, 180, 5, 0), N("spin", "Вращение/с", -360, 360, 10, 0)}, function(h, P)
	local src = S.vfxMedia or ""
	if src == "" then return end
	local ext = src:lower():match("%.(%w+)$")
	local isVid = ext == "mp4" or ext == "webm"
	local asset, err = fetchAsset(src)
	if not asset then toast("Медиа: " .. tostring(err), 4); return end
	local o
	if isVid then o = new("VideoFrame", {Video = asset, Looped = true, Playing = true, Volume = 0, BackgroundTransparency = 1}, h)
	else o = new("ImageLabel", {Image = asset, BackgroundTransparency = 1, ImageTransparency = 1 - P("op")}, h) end
	o.AnchorPoint = Vector2.new(0.5, 0.5); o.BorderSizePixel = 0
	o.Size = UDim2.fromOffset(P("size"), P("size"))
	return function(dt, t) o.Position = UDim2.fromScale(P("x"), P("y")); o.Rotation = P("rot") + t * P("spin") end
end)

def("beat", "Вспышки в такт", "✸", {N("pow", "Сила", 0.05, 1, 0.05, 0.35), Cc("color", "Цвет", 0)}, function(h, P)
	local f = new("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0}, h)
	return function(dt, t)
		local lv = loud()
		f.BackgroundColor3 = pcolor(P("color"), t); f.BackgroundTransparency = 1 - P("pow") * lv * lv
	end
end)

local GL = {"✨", "🌸", "🍃", "❄️", "🔥", "💧", "⭐", "❤️", "💎", "🎵", "🦋", "👻", "🍂", "🫧", "⚡", "🌈", "🎃", "🦇", "🕷", "💀"}
local function glyphDef(id, name, icon, g, dir, d)
	def(id, name, icon, {N("glyph", "Символ (номер 1-16)", 1, #GL, 1, g), N("count", "Количество", 3, 150, 1, d.n), N("size", "Размер", 10, 90, 1, d.s),
		N("speed", "Скорость", 5, 300, 5, d.v), N("sway", "Раскачка", 0, 150, 5, d.w), N("spin", "Вращение", 0, 360, 10, d.r),
		N("op", "Непрозрачность", 0.1, 1, 0.05, 0.95), Cc("color", "Цвет (для простых знаков)", 1)}, function(h, P)
		local V, n, ps = vp(), cnt(P("count")), {}
		local gl = GL[math.floor(P("glyph"))] or GL[1]
		for i = 1, n do
			local sz = P("size") * (0.5 + math.random() * 0.5)
			local l = new("TextLabel", {BackgroundTransparency = 1, Text = gl, TextSize = sz, Font = Enum.Font.GothamBold, TextColor3 = pcolor(P("color")),
				TextTransparency = 1 - P("op"), Size = UDim2.fromOffset(sz * 1.3, sz * 1.3), AnchorPoint = Vector2.new(0.5, 0.5)}, h)
			ps[i] = {l = l, x = math.random() * V.X, y = math.random() * V.Y, v = 0.5 + math.random(), ph = math.random() * 6.28, rs = (math.random() - 0.5) * 2}
		end
		return function(dt, t)
			local sp, sw, spin = P("speed"), P("sway"), P("spin")
			for _, p in ipairs(ps) do
				p.y += dir * sp * p.v * dt
				if dir < 0 and p.y < -40 then p.y = V.Y + 40; p.x = math.random() * V.X
				elseif dir > 0 and p.y > V.Y + 40 then p.y = -40; p.x = math.random() * V.X end
				p.l.Position = UDim2.fromOffset(p.x + math.sin(t * 0.9 + p.ph) * sw, p.y)
				p.l.Rotation = (t * spin * p.rs) % 360
			end
		end
	end)
end
glyphDef("emoji", "Эмодзи (любой символ)", "✨", 1, 1, {n = 30, s = 28, v = 60, w = 30, r = 40})
glyphDef("hearts", "Сердечки", "❤", 8, -1, {n = 22, s = 30, v = 70, w = 40, r = 20})
glyphDef("leavesfx", "Листопад", "🍃", 3, 1, {n = 26, s = 30, v = 55, w = 60, r = 120})
glyphDef("butter", "Бабочки", "🦋", 11, -1, {n = 12, s = 36, v = 35, w = 90, r = 15})
glyphDef("notes", "Ноты", "🎵", 10, -1, {n = 16, s = 30, v = 60, w = 50, r = 30})
glyphDef("pumpkins", "Тыквы 🎃", "🎃", 17, 1, {n = 14, s = 36, v = 50, w = 40, r = 30})
glyphDef("bats", "Летучие мыши 🦇", "🦇", 18, -1, {n = 14, s = 34, v = 70, w = 90, r = 20})

def("petals", "Лепестки", "🌸", {N("count", "Количество", 5, 150, 5, 40), N("size", "Размер", 6, 40, 1, 16), N("speed", "Скорость", 10, 250, 5, 60),
	N("sway", "Раскачка", 0, 150, 5, 50), N("op", "Непрозрачность", 0.1, 1, 0.05, 0.9), Cc("color", "Цвет", 9)}, function(h, P)
	local V, n, ps = vp(), cnt(P("count")), {}
	for i = 1, n do
		local sz = P("size") * (0.6 + math.random() * 0.4)
		local f = new("Frame", {Size = UDim2.fromOffset(sz, sz * 0.55), BorderSizePixel = 0, BackgroundColor3 = pcolor(P("color"), os.clock(), i * 0.01), BackgroundTransparency = 1 - P("op"), AnchorPoint = Vector2.new(0.5, 0.5)}, h)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		ps[i] = {f = f, x = math.random() * V.X, y = math.random() * V.Y, v = 0.5 + math.random(), ph = math.random() * 6.28, rs = 60 + math.random() * 120}
	end
	return function(dt, t)
		for _, p in ipairs(ps) do
			p.y += P("speed") * p.v * dt
			if p.y > V.Y + 20 then p.y = -20; p.x = math.random() * V.X end
			p.f.Position = UDim2.fromOffset(p.x + math.sin(t + p.ph) * P("sway"), p.y)
			p.f.Rotation = (t * p.rs) % 360
		end
	end
end)

def("lightning", "Молнии", "⚡", {N("rate", "Частота (в минуту)", 1, 60, 1, 12), N("thick", "Толщина", 1, 8, 1, 3), N("flash", "Вспышка экрана", 0, 1, 0.05, 0.35), Cc("color", "Цвет", 6)}, function(h, P)
	local V, segs, life = vp(), {}, 0
	for i = 1, 14 do segs[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, h) end
	local fl = new("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1, 1, 1)}, h)
	return function(dt, t)
		if life > 0 then
			life -= dt
			local a = math.clamp(life / 0.25, 0, 1)
			for _, s in ipairs(segs) do s.BackgroundTransparency = 1 - a end
			fl.BackgroundTransparency = 1 - P("flash") * a * 0.6
			if life <= 0 then for _, s in ipairs(segs) do s.Visible = false end; fl.BackgroundTransparency = 1 end
		elseif math.random() < dt * P("rate") / 60 then
			life = 0.25
			local x, y, c = math.floor(V.X * (0.2 + math.random() * 0.6)), 0, pcolor(P("color"), t)
			for _, s in ipairs(segs) do
				local nx, ny = x + math.random(-60, 60), y + V.Y / 14
				local dx, dy = nx - x, ny - y
				s.Position = UDim2.fromOffset((x + nx) / 2, (y + ny) / 2); s.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 2, P("thick"))
				s.Rotation = math.deg(math.atan2(dy, dx)); s.BackgroundColor3 = c; s.Visible = true
				x, y = nx, ny
			end
		end
	end
end)

def("rainfx", "Дождь (полосы)", "☔", {N("count", "Капель", 20, 400, 10, 160), N("len", "Длина", 8, 80, 2, 34), N("speed", "Скорость", 300, 2500, 50, 1100),
	N("angle", "Наклон", -40, 40, 1, 12), N("op", "Непрозрачность", 0.1, 1, 0.05, 0.55), Cc("color", "Цвет", 6)}, function(h, P)
	local V, n, ps = vp(), cnt(P("count")), {}
	for i = 1, n do
		ps[i] = {f = new("Frame", {Size = UDim2.fromOffset(1.5, P("len")), BorderSizePixel = 0, BackgroundColor3 = pcolor(P("color")), BackgroundTransparency = 1 - P("op"), Rotation = P("angle"), AnchorPoint = Vector2.new(0.5, 0.5)}, h),
			x = math.random() * V.X, y = math.random() * V.Y, v = 0.7 + math.random() * 0.6}
	end
	return function(dt, t)
		local a = math.rad(P("angle"))
		for _, p in ipairs(ps) do
			p.y += P("speed") * p.v * dt * math.cos(a); p.x -= P("speed") * p.v * dt * math.sin(a)
			if p.y > V.Y + 40 then p.y = -40; p.x = math.random() * (V.X + 200) end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
		end
	end
end)

def("shoot", "Падающие звёзды", "🌠", {N("rate", "Частота (в минуту)", 2, 120, 2, 20), N("len", "Длина хвоста", 60, 500, 10, 240), N("speed", "Скорость", 300, 2500, 50, 1200), Cc("color", "Цвет", 1)}, function(h, P)
	local V, ss = vp(), {}
	for i = 1, 4 do
		local f = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), BorderSizePixel = 0, Visible = false, Size = UDim2.fromOffset(P("len"), 3)}, h)
		new("UIGradient", {Transparency = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, f)
		ss[i] = {f = f, on = false, x = 0, y = 0}
	end
	return function(dt, t)
		for _, s in ipairs(ss) do
			if s.on then
				s.x += P("speed") * dt; s.y += P("speed") * dt * 0.55
				s.f.Position = UDim2.fromOffset(s.x, s.y)
				if s.x > V.X + P("len") or s.y > V.Y then s.on = false; s.f.Visible = false end
			elseif math.random() < dt * P("rate") / 60 then
				s.on = true; s.x = math.random() * V.X * 0.7 - 100; s.y = math.random() * V.Y * 0.4
				s.f.Rotation = math.deg(math.atan2(0.55, 1)); s.f.BackgroundColor3 = pcolor(P("color"), t); s.f.Visible = true
			end
		end
	end
end)

def("fog", "Дымка / облака", "🌫", {N("n", "Облаков", 2, 20, 1, 8), N("size", "Размер", 150, 900, 25, 420), N("speed", "Скорость", 2, 80, 2, 18),
	N("op", "Плотность", 0.03, 0.6, 0.01, 0.14), Cc("color", "Цвет", 1)}, function(h, P)
	local V, n, cs = vp(), cnt(P("n")), {}
	for i = 1, n do
		local sz = P("size") * (0.6 + math.random() * 0.6)
		local c = {rings = {}, x = math.random() * V.X, y = math.random() * V.Y, v = 0.5 + math.random(), sz = sz}
		for k = 1, 4 do
			local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Size = UDim2.fromOffset(sz * (1 - (k - 1) * 0.22), sz * (1 - (k - 1) * 0.22) * 0.6),
				BackgroundTransparency = 1 - P("op") / 2, BackgroundColor3 = pcolor(P("color"))}, h)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
			c.rings[k] = f
		end
		cs[i] = c
	end
	return function(dt, t)
		for _, c in ipairs(cs) do
			c.x += P("speed") * c.v * dt
			if c.x > V.X + c.sz then c.x = -c.sz end
			for _, f in ipairs(c.rings) do f.Position = UDim2.fromOffset(c.x, c.y + math.sin(t * 0.3 + c.v * 5) * 20) end
		end
	end
end)

def("plasma", "Плазма (градиент)", "🌈", {N("op", "Яркость", 0.03, 0.8, 0.01, 0.18), N("speed", "Скорость", 1, 200, 1, 30), Cc("color", "Цвет", -1)}, function(h, P)
	local f = new("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 1 - P("op"), BackgroundColor3 = Color3.new(1, 1, 1)}, h)
	local g = new("UIGradient", {}, f)
	return function(dt, t)
		local a, b2 = pcolor(P("color"), t, 0), pcolor(P("color"), t, 0.33)
		g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b2), ColorSequenceKeypoint.new(1, pcolor(P("color"), t, 0.66))})
		g.Rotation = (t * P("speed")) % 360
	end
end)

local PRESETS = {{"Кибер", {"scan", "border", "grain", "vignette"}}, {"Сон", {"aurora", "stars", "fog", "glow"}},
	{"Кино", {"bars", "vignette", "grain"}}, {"Матрица", {"matrix", "scan", "vignette"}}, {"Сакура", {"petals", "plasma", "vignette"}}, {"Шторм", {"rainfx", "lightning", "fog"}}, {"Хэллоуин", {"bats", "pumpkins", "fog", "vignette", "embers"}}}
local function setp(id, k, v) S.vfxP[id] = S.vfxP[id] or {}; S.vfxP[id][k] = v; isDirty = true end

RUN.vfx = function(c)
	local function draw()
		reset(c)
		head(c, "Включай сколько хочешь — эффекты складываются. ⚙ = тонкая настройка каждого")
		local pr = {}
		for _, p in ipairs(PRESETS) do
			pr[#pr + 1] = {p[1], function()
				S.vfx = {}
				for _, id in ipairs(p[2]) do S.vfx[id] = true end
				VFX.all(); isDirty = true; draw()
			end, true}
		end
		pr[#pr + 1] = {"Выкл все", function() S.vfx = {}; VFX.all(); isDirty = true; draw() end, true}
		row(c, pr)
		for _, id in ipairs(VFX.order) do
			local d, on = VFX.defs[id], S.vfx[id]
			local r = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38)}, c)
			button(r, d.icon .. "  " .. d.name .. (on and "   ● ВКЛ" or ""), function()
				if S.vfx[id] then S.vfx[id] = nil else S.vfx[id] = true end
				VFX.build(id); isDirty = true; draw()
			end, UDim2.new(0.82, 0, 1, 0), not on)
			local gb = button(r, "⚙", function() VFX.sel = (VFX.sel == id) and nil or id; draw() end, UDim2.new(0.16, 0, 1, 0), VFX.sel ~= id)
			gb.Position = UDim2.new(0.84, 0, 0, 0)
			if VFX.sel == id then
				for _, p in ipairs(d.params) do
					local after = function() VFX.build(id); draw() end
					if p.kind == "num" then
						stepFn(c, p.n, function() return pv(id, p.k) end, function(v) setp(id, p.k, v) end, p.st, p.min, p.max, nil, after)
					elseif p.kind == "col" then
						label(c, p.n, 15, "text", nil, UDim2.new(1, 0, 0, 20), true)
						swatches(c, function() return pv(id, p.k) end, function(v) setp(id, p.k, v) end, after)
					else
						row(c, {{p.n .. (pv(id, p.k) and ": ВКЛ" or ": ВЫКЛ"), function() setp(id, p.k, not pv(id, p.k)); after() end, not pv(id, p.k)}})
					end
				end
				if id == "media" then
					local ub = textbox(c, "ссылка на png/jpg/mp4 или файл из workspace", S.vfxMedia, 38)
					row(c, {{"Загрузить", function() S.vfxMedia = ub.Text; isDirty = true; VFX.build("media") end}})
					label(c, "GIF Roblox не показывает — для анимации используй mp4 (зависит от инжектора).", 12, "sub", nil, UDim2.new(1, 0, 0, 32))
				end
				row(c, {{"Сбросить параметры", function() S.vfxP[id] = nil; VFX.build(id); draw() end, true}})
			end
		end
	end
	draw()
end
M.cleanup[#M.cleanup + 1] = function() VFX.destroyAll() end
end -- конец визуалов

---------------------------------------------------------------- СЛОВА НА ЭКРАНЕ + МУЗЫКАЛЬНЫЙ ПЛЕЕР
do
local lyGui = keep(new("ScreenGui", {Name = "LauncherLyrics", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 55}, PG))
local lyFrame = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), Position = UDim2.fromScale(0.5, S.lyricY)}, lyGui)
local LY = {gen = 0}
M.LY = LY
LY.STYLES = {{"fade", "Плавно"}, {"slide", "Подъём"}, {"type", "Печать"}, {"wave", "Волна"}, {"pop", "Всплеск"}, {"drop", "Падение"}, {"spread", "Сбор"}, {"glitch", "Глитч"}, {"glow", "Свечение"}}
LY.FONTS = {"GothamBold", "FredokaOne", "Bangers", "Fantasy", "SciFi", "Arcade", "PermanentMarker", "Oswald"}
local function tw(o, t, props, es) TS:Create(o, TweenInfo.new(t, es or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end
function LY.show(text, dur)
	LY.gen += 1
	local gen = LY.gen
	for _, ch in ipairs(lyFrame:GetChildren()) do ch:Destroy() end
	lyFrame.Position = UDim2.fromScale(0.5, S.lyricY)
	local size, style = S.lyricSize, S.lyricStyle
	local ok, font = pcall(function() return Enum.Font[S.lyricFont] end)
	font = ok and font or Enum.Font.GothamBold
	local color = pcolor(S.lyricColor, os.clock())
	local rowF = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), BackgroundTransparency = 1}, lyFrame)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center}, rowF)
	local labs = {}
	if #text > 34 or style == "fade" then
		local l = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromOffset(math.min(workspace.CurrentCamera.ViewportSize.X * 0.9, 1100), size * 2.4), Text = text, TextSize = size,
			Font = font, TextColor3 = color, TextWrapped = true, TextStrokeTransparency = 0.55, TextTransparency = 1}, rowF)
		labs[1] = l
		tw(l, 0.5, {TextTransparency = 0})
	else
		local chars = {}
		for _, cp in utf8.codes(text) do chars[#chars + 1] = utf8.char(cp) end
		for i, chr in ipairs(chars) do
			local w = chr == " " and size * 0.35 or TextService:GetTextSize(chr, size, font, Vector2.new(500, 500)).X
			local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(w + 1, size * 1.3)}, rowF)
			local lab = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = chr, TextSize = size, Font = font, TextColor3 = color,
				TextStrokeTransparency = 0.55, TextTransparency = 1}, holder)
			labs[i] = lab
			task.delay((i - 1) * (style == "type" and 0.05 or 0.035), function()
				if LY.gen ~= gen then return end
				if style == "slide" then lab.Position = UDim2.fromOffset(0, 24); tw(lab, 0.5, {Position = UDim2.new(), TextTransparency = 0})
				elseif style == "type" then lab.TextTransparency = 0
				elseif style == "pop" then
					local u = new("UIScale", {Scale = 0}, lab); lab.TextTransparency = 0; tw(u, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
				elseif style == "drop" then lab.Position = UDim2.fromOffset(0, -60); tw(lab, 0.6, {Position = UDim2.new(), TextTransparency = 0}, Enum.EasingStyle.Bounce)
				elseif style == "spread" then lab.Position = UDim2.fromOffset((i - #chars / 2) * 40, 0); tw(lab, 0.7, {Position = UDim2.new(), TextTransparency = 0}, Enum.EasingStyle.Quint)
				elseif style == "glitch" then
					lab.TextTransparency = 0
					for _ = 1, 6 do
						lab.Text = string.char(math.random(33, 120)); task.wait(0.04)
						if LY.gen ~= gen then return end
					end
					lab.Text = chr
				else tw(lab, 0.4, {TextTransparency = 0}) end
			end)
		end
		if style == "wave" or style == "glow" then
			task.spawn(function()
				local t0 = os.clock()
				while LY.gen == gen and alive do
					local t = os.clock() - t0
					for i, lab in ipairs(labs) do
						if style == "wave" then lab.Position = UDim2.fromOffset(0, math.sin(t * 5 + i * 0.6) * size * 0.18)
						else lab.TextStrokeColor3 = ACCENTS[S.acc]; lab.TextStrokeTransparency = 0.5 + 0.45 * math.sin(t * 4 + i * 0.3) end
					end
					task.wait()
				end
			end)
		end
	end
	task.delay(math.max((dur or 3) - 0.45, 0.8), function()
		if LY.gen ~= gen then return end
		for _, lab in ipairs(labs) do tw(lab, 0.4, {TextTransparency = 1, TextStrokeTransparency = 1}) end
		task.delay(0.5, function() if LY.gen == gen then for _, ch in ipairs(lyFrame:GetChildren()) do ch:Destroy() end end end)
	end)
end

local MU = {list = {}, idx = 0, favOnly = false, status = "", tok = 0}
M.MU = MU
local MF = "L3D_" .. lp.UserId .. "_music.json"
if readfile and isfile and isfile(MF) then pcall(function() MU.list = HS:JSONDecode(readfile(MF)) end) end
local function saveList() if writefile then pcall(function() writefile(MF, HS:JSONEncode(MU.list)) end) end end
local snd = keep(new("Sound", {Name = "LauncherMusic", Volume = 0.5}, SoundService))
MU.sound = snd
function M.applySound() snd.Volume = S.sound and S.mVol or 0; snd.Looped = S.mLoop == "one" end
M.applySound()
local function parseLrc(s)
	local out = {}
	for line in (s or ""):gmatch("[^\r\n]+") do
		local text = line:gsub("%[[^%]]*%]", "")
		text = text:gsub("^%s+", "")
		for m, sc in line:gmatch("%[(%d+):(%d+%.?%d*)%]") do out[#out + 1] = {t = tonumber(m) * 60 + tonumber(sc), text = text} end
	end
	table.sort(out, function(a, b) return a.t < b.t end)
	return out
end
function MU.fetchLyrics(tr, cb)
	task.spawn(function()
		local rq = request or http_request or (syn and syn.request)
		if not rq then cb(false, "инжектор без request"); return end
		local q = (tr.name:gsub("%.%w+$", ""))
		local ok, res = pcall(rq, {Url = "https://lrclib.net/api/search?q=" .. HS:UrlEncode(q), Method = "GET"})
		if not ok or not res or res.StatusCode ~= 200 then cb(false, "сервис слов недоступен"); return end
		local ok2, d = pcall(HS.JSONDecode, HS, res.Body)
		if ok2 and type(d) == "table" then
			for _, it in ipairs(d) do
				if it.syncedLyrics and it.syncedLyrics ~= "" then
					tr.lrc = it.syncedLyrics; saveList()
					cb(true, tostring(it.artistName or "") .. " — " .. tostring(it.trackName or "")); return
				end
			end
		end
		cb(false, "слова не найдены")
	end)
end
function MU.play(i)
	local t = MU.list[i]
	if not t then return end
	MU.idx = i; MU.status = "Загрузка…"; MU.dirty = true
	MU.tok += 1
	local token = MU.tok
	task.spawn(function()
		local asset, err = fetchAsset(t.src)
		if token ~= MU.tok then return end
		if not asset then MU.status = "Ошибка: " .. tostring(err); MU.dirty = true; return end
		snd:Stop(); snd.SoundId = asset
		local t0 = os.clock()
		while not snd.IsLoaded and os.clock() - t0 < 12 and token == MU.tok do task.wait(0.1) end
		if token ~= MU.tok then return end
		if not snd.IsLoaded then MU.status = "Не загрузилось (ID может быть закрыт или ссылка недоступна)"; MU.dirty = true; return end
		M.applySound(); snd:Play()
		MU.status = "Играет"; MU.lyr = parseLrc(t.lrc); MU.lastLine = 0; MU.dirty = true
		if S.popOn then LY.show("♪ " .. t.name, 3.5) end
		if (t.lrc or "") == "" and S.autoLyrics then
			MU.fetchLyrics(t, function(ok2, msg)
				if MU.idx ~= i then return end
				if ok2 then MU.lyr = parseLrc(t.lrc); MU.lastLine = 0; MU.status = "Слова: " .. msg
				else MU.status = "Играет · слов нет (" .. msg .. "), можно вставить LRC в 📝" end
				MU.dirty = true
			end)
		end
	end)
end
local function pick(dir)
	local n = #MU.list
	if n == 0 then return end
	if S.mShuffle and n > 1 then
		local r = MU.idx
		while r == MU.idx do r = math.random(n) end
		return r
	end
	local i = MU.idx + dir
	if i > n then i = 1 elseif i < 1 then i = n end
	return i
end
function MU.next() local i = pick(1); if i then MU.play(i) end end
function MU.prev() local i = pick(-1); if i then MU.play(i) end end
function MU.toggle()
	if snd.IsPlaying then snd:Pause(); MU.status = "Пауза"
	elseif snd.IsPaused then snd:Resume(); MU.status = "Играет"
	elseif MU.idx > 0 then MU.play(MU.idx)
	elseif #MU.list > 0 then MU.play(1) end
	MU.dirty = true
end
conn(snd.Ended, function()
	if S.mLoop == "one" then return end
	if S.mLoop == "off" and MU.idx >= #MU.list and not S.mShuffle then MU.status = "Конец плейлиста"; MU.dirty = true; return end
	MU.next()
end)
task.spawn(function()
	while alive do
		task.wait(0.1)
		if snd.IsPlaying and MU.lyr and #MU.lyr > 0 and S.lyricOn then
			local pos, k = snd.TimePosition, 0
			for i, l in ipairs(MU.lyr) do if l.t <= pos then k = i else break end end
			if k > 0 and k ~= MU.lastLine then
				MU.lastLine = k
				local cur, nx = MU.lyr[k], MU.lyr[k + 1]
				if cur.text ~= "" then LY.show(cur.text, nx and math.clamp(nx.t - cur.t, 1.2, 8) or 4) end
			end
		end
	end
end)
M.cleanup[#M.cleanup + 1] = function() pcall(function() snd:Stop() end) end

-- ===== СЕРВИСЫ МУЗЫКИ (внутри существующей вкладки Music) =====
-- Audius и Jamendo: официальные публичные API, умеют отдавать аудиопоток -> играет прямо в Roblox.
-- Spotify: официальный OAuth (PKCE, без пароля и без секрета). Spotify НЕ отдаёт аудиопоток сторонним приложениям,
--          поэтому скрипт лишь управляет твоим приложением Spotify (нужен Premium и открытый Spotify на устройстве).
-- Токены в памяти; refresh-токен на диске лишь обфусцирован (XOR), это НЕ шифрование.
local MS = {cfg = {audius = true, jamendoId = "", spotifyId = "", redirect = "http://127.0.0.1:8888/callback", svc = "audius"}, sp = {}, d = {}, results = {}, pls = {}}
M.MS = MS
local SF = "L3D_" .. lp.UserId .. "_svc.json"
local function okey() return hash(tostring(lp.UserId) .. "L3D-svc") end
local function obf(s)
	local key, o = okey(), {}
	for i = 1, #s do o[i] = string.format("%02x", bit32.bxor(s:byte(i), key:byte((i - 1) % #key + 1))) end
	return table.concat(o)
end
local function deobf(h)
	local key, o, k = okey(), {}, 0
	for i = 1, #h - 1, 2 do
		k += 1
		o[k] = string.char(bit32.bxor(tonumber(h:sub(i, i + 1), 16) or 0, key:byte((k - 1) % #key + 1)))
	end
	return table.concat(o)
end
if readfile and isfile and isfile(SF) then
	pcall(function()
		local d = HS:JSONDecode(readfile(SF))
		for k, v in pairs(d.cfg or {}) do MS.cfg[k] = v end
		if d.refresh and d.refresh ~= "" then MS.sp.refresh = deobf(d.refresh) end
		MS.pls = d.pls or {}
	end)
end
local function saveSvc()
	if writefile then
		pcall(function() writefile(SF, HS:JSONEncode({cfg = MS.cfg, refresh = MS.sp.refresh and obf(MS.sp.refresh) or "", pls = MS.pls})) end)
	end
end
local function enc(s) return HS:UrlEncode(tostring(s)) end
local function rq(o)
	local f = request or http_request or (syn and syn.request)
	if not f then return nil, "в инжекторе нет request" end
	local ok, res = pcall(f, o)
	if not ok then return nil, tostring(res) end
	return res
end
local function jget(url, headers)
	local res, err = rq({Url = url, Method = "GET", Headers = headers or {}})
	if not res then return nil, err end
	if res.StatusCode ~= 200 then return nil, "HTTP " .. tostring(res.StatusCode) end
	local ok, d = pcall(HS.JSONDecode, HS, res.Body)
	if not ok then return nil, "ответ не JSON" end
	return d
end

-- SHA-256 (нужен для PKCE) и base64url
local K = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2}
local function sha256(s)
	local H = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
	local len = #s
	s = s .. "\128" .. string.rep("\0", (55 - len) % 64) .. string.pack(">I8", len * 8)
	local M32 = 4294967296
	for i = 1, #s, 64 do
		local w = {}
		for j = 0, 15 do w[j] = string.unpack(">I4", s, i + j * 4) end
		for j = 16, 63 do
			local a, b = w[j - 15], w[j - 2]
			local s0 = bit32.bxor(bit32.rrotate(a, 7), bit32.rrotate(a, 18), bit32.rshift(a, 3))
			local s1 = bit32.bxor(bit32.rrotate(b, 17), bit32.rrotate(b, 19), bit32.rshift(b, 10))
			w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % M32
		end
		local a, b, c2, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
		for j = 0, 63 do
			local S1 = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25))
			local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
			local t1 = (h + S1 + ch + K[j + 1] + w[j]) % M32
			local S0 = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22))
			local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c2), bit32.band(b, c2))
			local t2 = (S0 + maj) % M32
			h, g, f, e, d, c2, b, a = g, f, e, (d + t1) % M32, c2, b, a, (t1 + t2) % M32
		end
		local v = {a, b, c2, d, e, f, g, h}
		for k = 1, 8 do H[k] = (H[k] + v[k]) % M32 end
	end
	return string.pack(">I4I4I4I4I4I4I4I4", H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8])
end
MS.sha256 = sha256
local function b64url(raw) return (b64e(raw):gsub("%+", "-"):gsub("/", "_"):gsub("=", "")) end

-- ---------- поиск ----------
function MS.searchAudius(q)
	local d, err = jget("https://api.audius.co/v1/tracks/search?limit=15&app_name=L3D&query=" .. enc(q))
	if not d or not d.data then return nil, err or "пустой ответ" end
	local out = {}
	for _, t in ipairs(d.data) do
		out[#out + 1] = {name = (t.user and t.user.name or "?") .. " — " .. tostring(t.title), src = "https://api.audius.co/v1/tracks/" .. tostring(t.id) .. "/stream?app_name=L3D&f=.mp3", svc = "Audius"}
	end
	return out
end
function MS.searchJamendo(q)
	if MS.cfg.jamendoId == "" then return nil, "Jamendo не подключён: введи Client ID" end
	local d, err = jget("https://api.jamendo.com/v3.0/tracks/?format=json&limit=15&audioformat=mp32&client_id=" .. enc(MS.cfg.jamendoId) .. "&search=" .. enc(q))
	if not d or not d.results then return nil, err or "пустой ответ" end
	local out = {}
	for _, t in ipairs(d.results) do
		if t.audio and t.audio ~= "" then
			out[#out + 1] = {name = tostring(t.artist_name) .. " — " .. tostring(t.name), src = t.audio .. (t.audio:find("?", 1, true) and "&" or "?") .. "f=.mp3", svc = "Jamendo"}
		end
	end
	return out
end

-- ---------- Spotify (OAuth PKCE) ----------
function MS.spotifyStart()
	if MS.cfg.spotifyId == "" then return nil, "введи Client ID Spotify" end
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	local v = {}
	for i = 1, 96 do local k = math.random(#chars); v[i] = chars:sub(k, k) end
	MS.sp.verifier = table.concat(v)
	local base = M.baseUrl and M.baseUrl() or ""
	local stp = ""
	if base ~= "" then
		MS.cfg.redirect = base .. "/spotify/callback"
		local sv = {}
		for i = 1, 24 do local k = math.random(#chars); sv[i] = chars:sub(k, k) end
		MS.sp.state = table.concat(sv)
		stp = "&state=" .. MS.sp.state
	else MS.sp.state = nil end
	return "https://accounts.spotify.com/authorize?response_type=code&client_id=" .. enc(MS.cfg.spotifyId) ..
		"&scope=" .. enc("user-read-playback-state user-modify-playback-state user-read-private") ..
		"&redirect_uri=" .. enc(MS.cfg.redirect) .. "&code_challenge_method=S256&code_challenge=" .. b64url(sha256(MS.sp.verifier)) .. stp
end
local function tokenCall(body)
	local res, err = rq({Url = "https://accounts.spotify.com/api/token", Method = "POST", Headers = {["Content-Type"] = "application/x-www-form-urlencoded"}, Body = body})
	if not res then return nil, err end
	local ok, d = pcall(HS.JSONDecode, HS, res.Body)
	if res.StatusCode ~= 200 or not ok or not d.access_token then return nil, "Spotify отказал (" .. tostring(res.StatusCode) .. "): " .. tostring(ok and d.error_description or "") end
	MS.sp.token = d.access_token; MS.sp.exp = os.clock() + (d.expires_in or 3600) - 60
	if d.refresh_token then MS.sp.refresh = d.refresh_token end
	return true
end
function MS.spotifyFinish(pasted)
	local code = pasted:match("[?&]code=([^&%s#]+)")
	if not code then return nil, "в адресе нет параметра code=" end
	if not MS.sp.verifier then return nil, "сначала нажми «Подключить» (шаг 1)" end
	local ok, err = tokenCall("client_id=" .. enc(MS.cfg.spotifyId) .. "&grant_type=authorization_code&code=" .. enc(code) ..
		"&redirect_uri=" .. enc(MS.cfg.redirect) .. "&code_verifier=" .. enc(MS.sp.verifier))
	if ok then MS.sp.verifier = nil; saveSvc() end
	return ok, err
end
function MS.autoWait(done)
	local state, base = MS.sp.state, M.baseUrl and M.baseUrl() or ""
	if not state or base == "" then return end
	task.spawn(function()
		for _ = 1, 150 do
			if MS.sp.state ~= state or not alive then return end
			local d = jget(base .. "/spotify/code?state=" .. state)
			if d and d.code then
				MS.sp.state = nil
				local ok, err = MS.spotifyFinish("?code=" .. d.code)
				if ok then MS.spProfile() end
				done(ok, err); return
			end
			task.wait(2)
		end
		done(false, "время ожидания вышло (5 минут)")
	end)
end
function MS.spToken()
	if MS.sp.token and os.clock() < (MS.sp.exp or 0) then return MS.sp.token end
	if MS.sp.refresh and MS.cfg.spotifyId ~= "" then
		if tokenCall("client_id=" .. enc(MS.cfg.spotifyId) .. "&grant_type=refresh_token&refresh_token=" .. enc(MS.sp.refresh)) then saveSvc(); return MS.sp.token end
	end
end
local function sp(method, path, body)
	local tok = MS.spToken()
	if not tok then return nil, "Spotify не подключён" end
	local res, err = rq({Url = "https://api.spotify.com/v1" .. path, Method = method, Headers = {Authorization = "Bearer " .. tok, ["Content-Type"] = "application/json"}, Body = body and HS:JSONEncode(body) or nil})
	if not res then return nil, err end
	local sc = res.StatusCode
	if sc == 204 or sc == 202 then return true end
	if sc == 404 then return nil, "нет активного устройства: открой Spotify и запусти любой трек" end
	if sc == 403 then return nil, "нужен Spotify Premium" end
	if sc == 429 then return nil, "лимит запросов Spotify, подожди" end
	if sc ~= 200 then return nil, "HTTP " .. tostring(sc) end
	local ok, d = pcall(HS.JSONDecode, HS, res.Body)
	return ok and d or true
end
MS.sp_call = sp
function MS.spProfile()
	local d, err = sp("GET", "/me")
	if d and d ~= true then MS.sp.who = tostring(d.display_name or d.id) .. (d.product and (" · " .. d.product) or "") end
	return d, err
end
function MS.spPoll()
	local d = sp("GET", "/me/player")
	if d and d ~= true and d.item then
		MS.sp.now = {name = d.item.name, artist = d.item.artists and d.item.artists[1] and d.item.artists[1].name or "", playing = d.is_playing,
			pos = d.progress_ms or 0, len = d.item.duration_ms or 0, vol = d.device and d.device.volume_percent or 50, shuffle = d.shuffle_state, rep = d.repeat_state}
	else MS.sp.now = nil end
end
function MS.searchSpotify(q)
	local d, err = sp("GET", "/search?type=track&limit=10&q=" .. enc(q))
	if not d or d == true or not d.tracks then return nil, err or "пустой ответ" end
	local out = {}
	for _, t in ipairs(d.tracks.items) do out[#out + 1] = {name = (t.artists[1] and t.artists[1].name or "?") .. " — " .. t.name, uri = t.uri, svc = "Spotify"} end
	return out
end

-- ---------- локальные файлы ----------
function MS.scanLocal()
	if not (listfiles and isfolder and makefolder) then return nil, "инжектор не поддерживает listfiles" end
	if not isfolder("L3D_music") then makefolder("L3D_music") end
	local n = 0
	for _, f in ipairs(listfiles("L3D_music")) do
		local ext = f:lower():match("%.(%w+)$")
		if ext == "mp3" or ext == "ogg" or ext == "wav" then
			local dup = false
			for _, t in ipairs(MU.list) do if t.src == f then dup = true end end
			if not dup then MU.list[#MU.list + 1] = {name = f:match("([^/\\]+)%.%w+$") or f, src = f, fav = false, lrc = ""}; n += 1 end
		end
	end
	saveList()
	return n
end
local function inLibrary(r)
	for i, t in ipairs(MU.list) do if t.src == r.src then return i end end
	MU.list[#MU.list + 1] = {name = r.name, src = r.src, fav = false, lrc = ""}
	saveList()
	return #MU.list
end

-- ---------- интерфейс (добавляется внутрь существующей вкладки Music) ----------
function MS.drawUI(c, redraw)
	head(c, "Музыкальные сервисы, поиск и плейлисты")
	row(c, {{MS.open and "▼ Скрыть" or "▶ Показать сервисы, поиск, плейлисты", function() MS.open = not MS.open; redraw() end, not MS.open}})
	if not MS.open then return end
	local function say(t) MS.msg = t; redraw() end
	label(c, MS.msg or "Статус каждого сервиса показан в его кнопке.", 12, "sub", nil, UDim2.new(1, 0, 0, 32))
	-- Audius
	local aon = MS.cfg.audius ~= false
	row(c, {{"Audius: " .. (aon and "● включён (ключ не нужен)" or "○ выключен"), function() MS.cfg.audius = not aon; saveSvc(); redraw() end, not aon}})
	-- Jamendo
	local jt = textbox(c, "Jamendo Client ID (бесплатно: devportal.jamendo.com)", MS.d.jid or MS.cfg.jamendoId, 36)
	jt:GetPropertyChangedSignal("Text"):Connect(function() MS.d.jid = jt.Text end)
	local jc = MS.cfg.jamendoId ~= ""
	row(c, {{jc and "Jamendo: ● подключён" or "Jamendo: ○ подключить", function()
		if jc then return end
		local id = (jt.Text:gsub("%s+", ""))
		if id == "" then say("Введи Client ID Jamendo"); return end
		task.spawn(function()
			local d, err = jget("https://api.jamendo.com/v3.0/tracks/?format=json&limit=1&client_id=" .. enc(id))
			if d and d.headers and d.headers.status == "success" then MS.cfg.jamendoId = id; saveSvc(); say("Jamendo подключён")
			else say("Jamendo отклонил ключ: " .. tostring(err or (d and d.headers and d.headers.error_message) or "?")) end
		end)
	end, jc}, {"Отключить", function() MS.cfg.jamendoId = ""; MS.d.jid = ""; saveSvc(); redraw() end, true}})
	-- Spotify
	local sid = textbox(c, "Spotify Client ID (developer.spotify.com; секрет НЕ нужен)", MS.d.sid or MS.cfg.spotifyId, 36)
	sid:GetPropertyChangedSignal("Text"):Connect(function() MS.d.sid = sid.Text end)
	local base = M.baseUrl and M.baseUrl() or ""
	label(c, base ~= "" and ("ПРОСТОЙ ВХОД: в настройках приложения Spotify добавь Redirect URI:\n" .. base .. "/spotify/callback\nПотом вставь Client ID и нажми «Подключить»: ссылка откроется в браузере, нажми «Agree», и скрипт сам получит доступ.")
		or "Задай адрес сервера скрипта (Настройки → Конфиг и сеть): тогда вход в Spotify станет в один клик. Без сервера: вставь свой Redirect URI и вручную скопируй адрес после разрешения.", 12, "sub", nil, UDim2.new(1, 0, 0, 74))
	if base ~= "" then row(c, {{"📋 Скопировать Redirect URI", function() if setclipboard then pcall(setclipboard, base .. "/spotify/callback"); say("Redirect URI скопирован") end end, true}}) end
	local srd = textbox(c, "Redirect URI (как в настройках приложения Spotify)", MS.d.srd or MS.cfg.redirect, 36)
	srd:GetPropertyChangedSignal("Text"):Connect(function() MS.d.srd = srd.Text end)
	local spc = MS.sp.token or MS.sp.refresh
	row(c, {{spc and ("Spotify: ● " .. (MS.sp.who or "подключён")) or "Spotify: ○ подключить (шаг 1)", function()
		if spc then return end
		MS.cfg.spotifyId = (sid.Text:gsub("%s+", "")); MS.cfg.redirect = (srd.Text:gsub("%s+", "")); saveSvc()
		local url, err = MS.spotifyStart()
		if not url then say(err); return end
		MS.d.auth = url
		if setclipboard then pcall(setclipboard, url) end
		if MS.sp.state then
			MS.autoWait(function(ok2, err2) if content == c then say(ok2 and "Spotify подключён" or ("Ошибка: " .. tostring(err2))) end end)
			say("Ссылка скопирована. Открой её в браузере и нажми «Agree»/«Разрешить»: остальное скрипт сделает сам (ждёт до 5 минут)")
		else
			say(setclipboard and "Ссылка авторизации скопирована: открой её в браузере, разреши доступ, потом скопируй адрес, на который перекинет, и вставь ниже" or "Нет setclipboard: скопируй ссылку из поля ниже вручную")
		end
	end, spc}, {"Отключить", function() MS.sp = {}; saveSvc(); say("Spotify отключён") end, true}})
	if not spc then
		if MS.d.auth then local at = textbox(c, "", MS.d.auth, 36); at.TextEditable = false end
		local pt = textbox(c, "Шаг 2: вставь адрес после разрешения (в нём ?code=…)", MS.d.paste or "", 36)
		pt:GetPropertyChangedSignal("Text"):Connect(function() MS.d.paste = pt.Text end)
		row(c, {{"Завершить подключение", function()
			task.spawn(function()
				local ok, err = MS.spotifyFinish(pt.Text)
				if ok then MS.d.paste = ""; MS.d.auth = nil; MS.spProfile(); say("Spotify подключён") else say("Ошибка: " .. tostring(err)) end
			end)
		end}})
	else
		task.spawn(function() if not MS.sp.who then MS.spProfile(); if content == c then redraw() end end end)
	end
	-- поиск
	head(c, "Поиск по названию и исполнителю")
	local qt = textbox(c, "например: daft punk one more time", MS.d.q or "", 38)
	qt:GetPropertyChangedSignal("Text"):Connect(function() MS.d.q = qt.Text end)
	row(c, {{"Audius", function() MS.cfg.svc = "audius"; redraw() end, MS.cfg.svc ~= "audius"}, {"Jamendo", function() MS.cfg.svc = "jamendo"; redraw() end, MS.cfg.svc ~= "jamendo"},
		{"Spotify", function() MS.cfg.svc = "spotify"; redraw() end, MS.cfg.svc ~= "spotify"}})
	row(c, {{"🔎 Найти", function()
		if qt.Text == "" then return end
		task.spawn(function()
			local f = MS.cfg.svc == "jamendo" and MS.searchJamendo or (MS.cfg.svc == "spotify" and MS.searchSpotify or MS.searchAudius)
			local r, err = f(qt.Text)
			MS.results = r or {}
			if content == c then say(r and ("Найдено: " .. #r) or ("Поиск не удался: " .. tostring(err))) end
		end)
	end}})
	for i, r in ipairs(MS.results) do
		if i > 12 then break end
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
		label(fr, r.name:sub(1, 46), 13, "text", UDim2.new(0, 10, 0, 0), UDim2.new(0.58, 0, 1, 0), true)
		if r.uri then
			local b = button(fr, "▶ в Spotify", function()
				task.spawn(function() local ok, err = sp("PUT", "/me/player/play", {uris = {r.uri}}); say(ok and "Запущено в приложении Spotify" or tostring(err)) end)
			end, UDim2.new(0.36, 0, 0, 32)); b.Position = UDim2.new(0.62, 0, 0.5, -16)
		else
			local b1 = button(fr, "▶", function() local k = inLibrary(r); MU.play(k); redraw() end, UDim2.new(0.16, 0, 0, 32)); b1.Position = UDim2.new(0.6, 0, 0.5, -16)
			local b2 = button(fr, "➕", function() inLibrary(r); say("Добавлено в библиотеку") end, UDim2.new(0.16, 0, 0, 32), true); b2.Position = UDim2.new(0.78, 0, 0.5, -16)
		end
	end
	-- управление Spotify
	if spc then
		head(c, "Spotify: управление твоим приложением (звук идёт из Spotify, не из Roblox)")
		MS.spLabel = label(c, MS.sp.now and (MS.sp.now.artist .. " — " .. MS.sp.now.name) or "Нет активного воспроизведения", 14, "text", nil, UDim2.new(1, 0, 0, 22), true)
		local function act(method, path, body) task.spawn(function() local ok, err = sp(method, path, body); if not ok then say(tostring(err)) else MS.spPoll(); redraw() end end) end
		local n = MS.sp.now
		row(c, {{"⏮", function() act("POST", "/me/player/previous") end, true}, {(n and n.playing) and "⏸" or "▶", function() act("PUT", (n and n.playing) and "/me/player/pause" or "/me/player/play") end},
			{"⏭", function() act("POST", "/me/player/next") end, true}})
		row(c, {{"🔉 −10", function() act("PUT", "/me/player/volume?volume_percent=" .. math.clamp((n and n.vol or 50) - 10, 0, 100)) end, true},
			{"🔊 +10", function() act("PUT", "/me/player/volume?volume_percent=" .. math.clamp((n and n.vol or 50) + 10, 0, 100)) end, true},
			{"⏪ −10с", function() act("PUT", "/me/player/seek?position_ms=" .. math.max(0, (n and n.pos or 0) - 10000)) end, true},
			{"⏩ +10с", function() act("PUT", "/me/player/seek?position_ms=" .. ((n and n.pos or 0) + 10000)) end, true}})
		local nextRep = {off = "context", context = "track", track = "off"}
		row(c, {{"🔁 повтор: " .. tostring(n and n.rep or "off"), function() act("PUT", "/me/player/repeat?state=" .. nextRep[n and n.rep or "off"]) end, true},
			{"🔀 " .. ((n and n.shuffle) and "вкл" or "выкл"), function() act("PUT", "/me/player/shuffle?state=" .. tostring(not (n and n.shuffle))) end, true}})
		MS.pollTok = (MS.pollTok or 0) + 1
		local my = MS.pollTok
		task.spawn(function()
			while alive and content == c and MS.pollTok == my do
				MS.spPoll()
				if MS.spLabel and MS.spLabel.Parent then MS.spLabel.Text = MS.sp.now and (MS.sp.now.artist .. " — " .. MS.sp.now.name .. (MS.sp.now.playing and "  ▶" or "  ⏸")) or "Нет активного воспроизведения" end
				task.wait(3)
			end
		end)
	end
	-- локальные файлы
	head(c, "Локальные файлы")
	row(c, {{"📁 Сканировать папку workspace/L3D_music", function()
		local n, err = MS.scanLocal()
		say(n and ("Добавлено файлов: " .. n .. " (mp3/ogg/wav)") or tostring(err))
	end, true}})
	-- плейлисты
	head(c, "Мои плейлисты")
	local nt = textbox(c, "название нового плейлиста", MS.d.pl or "", 36)
	nt:GetPropertyChangedSignal("Text"):Connect(function() MS.d.pl = nt.Text end)
	row(c, {{"➕ Создать плейлист", function()
		if nt.Text ~= "" then MS.pls[#MS.pls + 1] = {name = nt.Text, items = {}}; MS.d.pl = ""; saveSvc(); redraw() end
	end}})
	for pi, pl in ipairs(MS.pls) do
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
		local nb = button(fr, (MS.plOpen == pi and "▼ " or "▶ ") .. pl.name .. " (" .. #pl.items .. ")", function() MS.plOpen = (MS.plOpen == pi) and nil or pi; redraw() end, UDim2.new(0.5, 0, 0, 32), MS.plOpen ~= pi)
		nb.Position = UDim2.new(0.01, 0, 0.5, -16)
		local ab = button(fr, "➕ текущий", function()
			local t = MU.list[MU.idx]
			if t then pl.items[#pl.items + 1] = {name = t.name, src = t.src}; saveSvc(); redraw() else say("Сначала включи трек") end
		end, UDim2.new(0.26, 0, 0, 32), true); ab.Position = UDim2.new(0.53, 0, 0.5, -16)
		local xb = button(fr, "✕", function() table.remove(MS.pls, pi); MS.plOpen = nil; saveSvc(); redraw() end, UDim2.new(0.14, 0, 0, 32), true); xb.Position = UDim2.new(0.84, 0, 0.5, -16)
		if MS.plOpen == pi then
			for ii, it in ipairs(pl.items) do
				local r2 = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 38), "card", 10)
				local pb = button(r2, "▶ " .. it.name:sub(1, 40), function() local k = inLibrary(it); MU.play(k); redraw() end, UDim2.new(0.8, 0, 0, 28), true); pb.Position = UDim2.new(0.01, 0, 0.5, -14)
				local rb = button(r2, "✕", function() table.remove(pl.items, ii); saveSvc(); redraw() end, UDim2.new(0.15, 0, 0, 28), true); rb.Position = UDim2.new(0.83, 0, 0.5, -14)
			end
		end
	end
	label(c, "Плейлисты играют как набор треков из библиотеки: следующий/предыдущий идут по общей библиотеке (существующая логика плеера не менялась).", 11, "sub", nil, UDim2.new(1, 0, 0, 34))
end

local function fmtT(s) s = math.floor(s or 0); return string.format("%d:%02d", s // 60, s % 60) end
RUN.music = function(c)
	local me = c
	local fill, tl, st
	local function draw()
		reset(c)
		local t = MU.list[MU.idx]
		label(c, t and ("🎵 " .. t.name) or "🎵 Ничего не играет", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		st = label(c, MU.status, 13, "sub", nil, UDim2.new(1, 0, 0, 18))
		local bar = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 10), "card2", 5)
		fill = frame(bar, UDim2.new(), UDim2.new(0, 0, 1, 0), "acc", 5)
		local seek = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, -7)}, bar)
		tap(seek, function()
			if snd.TimeLength > 0 then
				local x = (UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
				snd.TimePosition = math.clamp(x, 0, 1) * snd.TimeLength
			end
		end)
		tl = label(c, "0:00 / 0:00", 13, "sub", nil, UDim2.new(1, 0, 0, 18))
		local lp2 = {off = "↻ выкл", all = "🔁 все", one = "🔂 один"}
		row(c, {{"⏮", MU.prev, true}, {snd.IsPlaying and "⏸" or "▶", function() MU.toggle(); draw() end}, {"⏭", MU.next, true},
			{lp2[S.mLoop], function() S.mLoop = S.mLoop == "all" and "one" or (S.mLoop == "one" and "off" or "all"); M.applySound(); isDirty = true; draw() end, true},
			{S.mShuffle and "🔀 вкл" or "🔀 выкл", function() S.mShuffle = not S.mShuffle; isDirty = true; draw() end, not S.mShuffle}})
		stepFn(c, "Громкость", function() return S.mVol end, function(v) S.mVol = v; M.applySound() end, 0.05, 0, 1, pct, draw)
		row(c, {tog("🔊 Звук скрипта", "sound", draw)})
		head(c, "Плейлист")
		row(c, {{"Все", function() MU.favOnly = false; draw() end, MU.favOnly}, {"⭐ Избранное", function() MU.favOnly = true; draw() end, not MU.favOnly}})
		for i, tr in ipairs(MU.list) do
			if not MU.favOnly or tr.fav then
				local r = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
				local nb = button(r, (MU.idx == i and "▶ " or "") .. tr.name, function() MU.play(i) end, UDim2.new(0.55, 0, 0, 34), MU.idx ~= i); nb.Position = UDim2.new(0.01, 0, 0.5, -17)
				local fb = button(r, tr.fav and "⭐" or "☆", function() tr.fav = not tr.fav; saveList(); draw() end, UDim2.new(0.11, 0, 0, 34), true); fb.Position = UDim2.new(0.58, 0, 0.5, -17)
				local lb = button(r, "📝", function() MU.editLrc = (MU.editLrc == i) and nil or i; draw() end, UDim2.new(0.11, 0, 0, 34), true); lb.Position = UDim2.new(0.7, 0, 0.5, -17)
				local xb = button(r, "✕", function()
					table.remove(MU.list, i); if MU.idx == i then snd:Stop(); MU.idx = 0 elseif MU.idx > i then MU.idx -= 1 end
					MU.editLrc = nil; saveList(); draw()
				end, UDim2.new(0.11, 0, 0, 34), true); xb.Position = UDim2.new(0.82, 0, 0.5, -17)
				if MU.editLrc == i then
					head(c, "Слова в формате LRC: [00:12.50]строка (по одной на строку)")
					local lt = textbox(c, "[00:12.00]Первая строка\n[00:16.50]Вторая строка", tr.lrc or "", 150, true)
					row(c, {{"🔎 Найти автоматически", function()
						MU.status = "Ищу слова…"
						MU.fetchLyrics(tr, function(ok2, msg)
							MU.status = ok2 and ("Слова найдены: " .. msg) or ("Слова: " .. msg)
							if ok2 and MU.idx == i then MU.lyr = parseLrc(tr.lrc); MU.lastLine = 0 end
							MU.editLrc = nil; MU.dirty = true
						end)
					end, true}})
					row(c, {{"Сохранить слова", function() tr.lrc = lt.Text; saveList(); if MU.idx == i then MU.lyr = parseLrc(tr.lrc) end; MU.editLrc = nil; draw() end}})
				end
			end
		end
		head(c, "Добавить трек: число = ID аудио Roblox, ссылка на .mp3/.ogg, или файл из папки workspace")
		local nm = textbox(c, "Название", MU.dName or "", 38)
		local sr = textbox(c, "ID / ссылка / файл", MU.dSrc or "", 38)
		nm:GetPropertyChangedSignal("Text"):Connect(function() MU.dName = nm.Text end)
		sr:GetPropertyChangedSignal("Text"):Connect(function() MU.dSrc = sr.Text end)
		row(c, {{"➕ Добавить", function()
			local s = (sr.Text:gsub("^%s+", "")); s = (s:gsub("%s+$", ""))
			if s == "" then return end
			MU.list[#MU.list + 1] = {name = nm.Text ~= "" and nm.Text or ("Трек " .. (#MU.list + 1)), src = s, fav = false, lrc = ""}
			MU.dName, MU.dSrc = "", ""; saveList(); draw()
		end}})
		label(c, "Spotify, Яндекс.Музыку и YouTube подключить нельзя: у них закрытое DRM и нет доступа из Roblox. Работают прямые ссылки на аудиофайлы и ID из каталога Roblox (часть ID закрыта).", 12, "sub", nil, UDim2.new(1, 0, 0, 50))
		MS.drawUI(c, draw)
		head(c, "Слова и название на экране")
		row(c, {tog("Слова (LRC)", "lyricOn", draw), tog("Название при старте", "popOn", draw)})
		row(c, {tog("Искать слова сам", "autoLyrics", draw)})
		local sb = {}
		for _, s in ipairs(LY.STYLES) do sb[#sb + 1] = opt(s[2], "lyricStyle", s[1], draw) end
		chunk(c, sb, 3)
		local fb2 = {}
		for _, f in ipairs(LY.FONTS) do fb2[#fb2 + 1] = opt(f, "lyricFont", f, draw) end
		chunk(c, fb2, 4)
		stepFn(c, "Размер текста", function() return S.lyricSize end, function(v) S.lyricSize = v end, 2, 14, 90, nil, draw)
		stepFn(c, "Позиция по высоте", function() return S.lyricY end, function(v) S.lyricY = v end, 0.02, 0.05, 0.95, pct, draw)
		label(c, "Цвет текста", 15, "text", nil, UDim2.new(1, 0, 0, 20), true)
		swatches(c, function() return S.lyricColor end, function(v) S.lyricColor = v end, draw)
		row(c, {{"Показать пример", function() LY.show("Пример красивой строки", 3.5) end, true}})
	end
	draw()
	task.spawn(function()
		while content == me and alive do
			local len = snd.TimeLength
			if fill and fill.Parent then
				fill.Size = UDim2.new(len > 0 and math.clamp(snd.TimePosition / len, 0, 1) or 0, 0, 1, 0)
				tl.Text = fmtT(snd.TimePosition) .. " / " .. fmtT(len)
				st.Text = MU.status
			end
			if MU.dirty then MU.dirty = false; if not MU.editLrc then draw() end end
			task.wait(0.2)
		end
	end)
end
end -- конец музыки
M.load(72, "Анимации и дрон…")

---------------------------------------------------------------- АНИМАЦИИ: меню (12) и вокруг персонажа (12)
do
local function E(a) return 1 - (1 - a) ^ 3 end
M.OA_ORDER = {{"zoom", "Приближение"}, {"spin", "Вращение"}, {"flip", "Переворот"}, {"left", "Слева"}, {"right", "Справа"}, {"drop", "Падение"},
	{"rise", "Всплытие"}, {"swing", "Качели"}, {"bounce", "Пружина"}, {"spiral", "Спираль"}, {"wobble", "Дрожь"}, {"warp", "Варп"}, {"unfold", "Раскрытие"}}
M.OA = {
	zoom = function(a) return CFrame.new(), 1 + 0.4 * (1 - E(a)) end,
	spin = function(a) return CFrame.Angles(0, (1 - E(a)) * math.pi * 2, 0), 1 + 0.2 * (1 - E(a)) end,
	flip = function(a) return CFrame.Angles((1 - E(a)) * math.pi, 0, 0), 1 end,
	left = function(a) return CFrame.new(-(1 - E(a)) * 14, 0, 0), 1 end,
	right = function(a) return CFrame.new((1 - E(a)) * 14, 0, 0), 1 end,
	drop = function(a) return CFrame.new(0, (1 - E(a)) * 9, 0), 1 end,
	rise = function(a) return CFrame.new(0, -(1 - E(a)) * 9, 0), 1 end,
	swing = function(a) return CFrame.Angles(0, 0, (1 - E(a)) * 1.4 * math.cos(a * 8)), 1 end,
	bounce = function(a) return CFrame.new(), 1 + 0.8 * (1 - a) ^ 2 * math.cos(a * 14) end,
	spiral = function(a) return CFrame.Angles(0, (1 - E(a)) * math.pi * 4, 0), 1 + 0.8 * (1 - E(a)) end,
	wobble = function(a) return CFrame.Angles(math.sin(a * 30) * (1 - a) * 0.4, math.sin(a * 24) * (1 - a) * 0.4, 0), 1 end,
	warp = function(a) return CFrame.new(), 1 + 2 * (1 - E(a)) ^ 2 end,
	unfold = function(a) return CFrame.Angles((1 - E(a)) * 1.2, -(1 - E(a)) * 1.2, 0), 1 end,
}

local fold = keep(new("Folder", {Name = "LauncherOrbit"}, workspace))
local pools = {}
local tau = math.pi * 2
local OS = {
	orbit = function(i, n, t, R) local a = t * S.orbitSpeed * 2 + i / n * tau; return Vector3.new(math.cos(a) * R, 0, math.sin(a) * R) end,
	halo = function(i, n, t, R) local a = t * S.orbitSpeed * 2 + i / n * tau; return Vector3.new(math.cos(a) * R * 0.4, 2.8, math.sin(a) * R * 0.4) end,
	helix = function(i, n, t, R) local a = t * S.orbitSpeed * 2 + (i % 2) * math.pi + i * 0.35; return Vector3.new(math.cos(a) * R * 0.5, (i / n * 2 - 1) * R * 0.8, math.sin(a) * R * 0.5) end,
	saturn = function(i, n, t, R) local a = t * S.orbitSpeed * 1.5 + i / n * tau; return Vector3.new(math.cos(a) * R, math.sin(a) * R * 0.35, math.sin(a) * R * 0.93) end,
	shell = function(i, n, t, R)
		local ph = math.acos(1 - 2 * (i + 0.5) / n); local th = math.pi * (1 + 5 ^ 0.5) * (i + 0.5) + t * S.orbitSpeed
		return Vector3.new(math.cos(th) * math.sin(ph), math.cos(ph), math.sin(th) * math.sin(ph)) * R
	end,
	wings = function(i, n, t, R)
		local side = (i % 2 == 0) and 1 or -1; local k = math.floor(i / 2) / math.max(n / 2, 1)
		return Vector3.new(side * (0.8 + k * R * 1.1), 0.5 + math.sin(k * math.pi) * R * 0.9 + math.sin(t * S.orbitSpeed * 3) * 0.4 * k * 2, 0.8 + k * 0.3)
	end,
	tornado = function(i, n, t, R) local a = t * S.orbitSpeed * 3 + i * 0.7; return Vector3.new(math.cos(a) * (0.5 + i / n * R), i / n * R * 1.8 - 1.5, math.sin(a) * (0.5 + i / n * R)) end,
	pulse = function(i, n, t, R) local a = i / n * tau; local r = ((t * S.orbitSpeed * 0.6) % 1) * R * 1.6 + 0.5; return Vector3.new(math.cos(a) * r, -2.5, math.sin(a) * r) end,
	rain = function(i, n, t, R)
		local a = i * 2.399; local r = R * 0.3 + ((i * 37) % 10) / 10 * R * 0.7
		return Vector3.new(math.cos(a) * r, R * 1.2 - ((t * S.orbitSpeed * 0.5 + i * 0.173) % 1) * R * 1.8, math.sin(a) * r)
	end,
	blades = function(i, n, t, R) local a = t * S.orbitSpeed * 3 + i / n * tau; return Vector3.new(math.cos(a) * R, math.sin(t * 2 + i) * 0.5, math.sin(a) * R) end,
	infinity = function(i, n, t, R)
		local u = t * S.orbitSpeed + i / n * tau; local d = 1 + math.sin(u) ^ 2
		return Vector3.new(R * math.cos(u) / d, 0.5, R * math.sin(u) * math.cos(u) / d)
	end,
	atom = function(i, n, t, R)
		local k = i % 3; local a = t * S.orbitSpeed * 2 + i / n * tau
		local v = Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		return CFrame.Angles(0, k * math.pi / 3, k * math.pi / 3):VectorToWorldSpace(v)
	end,
}
M.ORBITS = {{"none", "Выкл"}, {"orbit", "Орбита"}, {"halo", "Нимб"}, {"helix", "Спираль"}, {"saturn", "Сатурн"}, {"shell", "Сфера"}, {"wings", "Крылья"},
	{"tornado", "Торнадо"}, {"pulse", "Волна"}, {"rain", "Дождь сфер"}, {"blades", "Лезвия"}, {"infinity", "Бесконечность"}, {"atom", "Атом"}}
function M.applyOrbit()
	for style, pool in pairs(pools) do
		if not S.orbits[style] then for _, p in ipairs(pool) do p:Destroy() end; pools[style] = nil end
	end
	for style in pairs(S.orbits) do
		if OS[style] then
			local pool = pools[style]
			if not pool then pool = {}; pools[style] = pool end
			local want = math.max(1, math.floor(S.orbitN * PERF + 0.5))
			while #pool > want do pool[#pool]:Destroy(); pool[#pool] = nil end
			while #pool < want do
				pool[#pool + 1] = new("Part", {Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Anchored = true, CanCollide = false, CanQuery = false,
					CanTouch = false, CastShadow = false}, fold)
			end
			for _, p in ipairs(pool) do p.Size = Vector3.one * S.orbitSize end
		end
	end
end
conn(RS.RenderStepped, function()
	if not next(pools) then return end
	local r = root()
	if not r then return end
	local t = os.clock()
	for style, pool in pairs(pools) do
		local fn, n = OS[style], #pool
		for i, p in ipairs(pool) do
			p.Position = r.Position + fn(i - 1, n, t, S.orbitR)
			p.Color = pcolor(S.orbitColor, t, i / n * 0.5)
		end
	end
end)

RUN.anim = function(c)
	local function draw()
		reset(c)
		head(c, "Анимации вокруг персонажа — включай несколько сразу (видны только тебе)")
		local o = {}
		for _, s in ipairs(M.ORBITS) do if s[1] ~= "none" then o[#o + 1] = M.setTog(s[2], S.orbits, s[1], draw) end end
		chunk(c, o, 3)
		stepFn(c, "Количество", function() return S.orbitN end, function(v) S.orbitN = v; M.applyOrbit() end, 1, 1, 60, nil, draw)
		stepFn(c, "Радиус", function() return S.orbitR end, function(v) S.orbitR = v end, 0.5, 1, 15, nil, draw)
		stepFn(c, "Скорость", function() return S.orbitSpeed end, function(v) S.orbitSpeed = v end, 0.1, 0.1, 5, nil, draw)
		stepFn(c, "Размер шариков", function() return S.orbitSize end, function(v) S.orbitSize = v; M.applyOrbit() end, 0.05, 0.1, 2, nil, draw)
		label(c, "Цвет", 15, "text", nil, UDim2.new(1, 0, 0, 20), true)
		swatches(c, function() return S.orbitColor end, function(v) S.orbitColor = v end, draw)
		head(c, "Анимация открытия меню")
		local a = {}
		for _, s in ipairs(M.OA_ORDER) do a[#a + 1] = opt(s[2], "openAnim", s[1], draw) end
		chunk(c, a, 3)
		row(c, {{"▶ Проиграть", function() setOpen(false); task.wait(0.25); setOpen(true) end, true}})
	end
	draw()
end
end -- конец анимаций

---------------------------------------------------------------- ДРОН FPV
do
local DR = {on = false, roll = 0}
M.DR = DR
local folder = keep(new("Folder", {Name = "LauncherDrone"}, workspace))
local gui = keep(new("ScreenGui", {Name = "LauncherDroneOSD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 45, Enabled = false}, PG))
local osd = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, gui)
local GREEN = C(230, 255, 230)
local function T(pos, anchor, align)
	return new("TextLabel", {BackgroundTransparency = 1, Position = pos, AnchorPoint = anchor, Size = UDim2.fromOffset(300, 48), Font = Enum.Font.Code, TextSize = 14,
		TextColor3 = GREEN, TextStrokeTransparency = 0.4, TextXAlignment = align, TextYAlignment = Enum.TextYAlignment.Top}, osd)
end
local recL = T(UDim2.new(0, 24, 0, 18), Vector2.new(0, 0), Enum.TextXAlignment.Left)
local batL = T(UDim2.new(1, -24, 0, 18), Vector2.new(1, 0), Enum.TextXAlignment.Right)
local altL = T(UDim2.new(0, 24, 1, -18), Vector2.new(0, 1), Enum.TextXAlignment.Left); altL.TextYAlignment = Enum.TextYAlignment.Bottom
local sigL = T(UDim2.new(1, -24, 1, -18), Vector2.new(1, 1), Enum.TextXAlignment.Right); sigL.TextYAlignment = Enum.TextYAlignment.Bottom
local function line(x, y, w, h) return new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = GREEN, BackgroundTransparency = 0.25, BorderSizePixel = 0}, osd) end
local fullEls = {line(0, 0, 3, 3), line(-14, 0, 14, 2), line(14, 0, 14, 2), line(0, -14, 2, 14), line(0, 14, 2, 14)}
local horizon = line(0, 0, 240, 2); horizon.BackgroundTransparency = 0.5
fullEls[#fullEls + 1] = horizon
local frameBox = new("Frame", {Position = UDim2.fromOffset(18, 18), Size = UDim2.new(1, -36, 1, -36), BackgroundTransparency = 1}, osd)
new("UIStroke", {Thickness = 1.5, Color = GREEN, Transparency = 0.6}, frameBox)
fullEls[#fullEls + 1] = frameBox
local crashGui = keep(new("ScreenGui", {Name = "LauncherCrash", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 80}, PG))
local crashF = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0}, crashGui)
local crashT = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 40, Text = "", TextColor3 = C(255, 80, 80)}, crashF)
local glitch = {}
for i = 1, 6 do glitch[i] = new("Frame", {Visible = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 10)}, osd) end
local parts, props = {}, {}
local function mk(size, color, shape, mat)
	return new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = size, Color = color,
		Material = mat or Enum.Material.Metal, Shape = shape or Enum.PartType.Block}, folder)
end
local OFFS = {Vector3.new(1.15, 0.2, 1.15), Vector3.new(-1.15, 0.2, 1.15), Vector3.new(1.15, 0.2, -1.15), Vector3.new(-1.15, 0.2, -1.15)}
local function buildModel()
	parts.body = mk(Vector3.new(1.3, 0.35, 1.5), C(30, 30, 36))
	parts.a = mk(Vector3.new(3.3, 0.12, 0.2), C(60, 60, 70))
	parts.b = mk(Vector3.new(3.3, 0.12, 0.2), C(60, 60, 70))
	for i = 1, 4 do props[i] = mk(Vector3.new(0.06, 1.7, 1.7), i <= 2 and C(255, 70, 70) or C(80, 255, 140), Enum.PartType.Cylinder, Enum.Material.Neon); props[i].Transparency = 0.45 end
end
local acc, tOsd, hide = 0, 0, {}
local function step(dt)
	local cam, r, h = workspace.CurrentCamera, root(), hum()
	if not (r and h) or h.Health <= 0 then DR.set(false); return end
	for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
	local look = cam.CFrame.LookVector
	local fl = Vector3.new(look.X, 0, look.Z)
	if fl.Magnitude < 0.01 then fl = Vector3.new(0, 0, -1) end
	local vel = r.AssemblyLinearVelocity
	local sp = vel.Magnitude
	local target = -math.clamp(vel:Dot(cam.CFrame.RightVector) * 0.006, -0.4, 0.4)
	DR.roll += (target - DR.roll) * math.min(1, dt * 8)
	local pos = r.Position + Vector3.new(0, S.droneProps and 1.2 or -1.6, 0)
	local base = CFrame.lookAt(pos, pos + fl) * CFrame.Angles(math.clamp(sp * 0.003, 0, 0.45), 0, DR.roll)
	parts.body.CFrame = base
	parts.a.CFrame = base * CFrame.Angles(0, math.rad(45), 0); parts.b.CFrame = base * CFrame.Angles(0, math.rad(-45), 0)
	local ang = os.clock() * 60
	for i, p in ipairs(props) do p.CFrame = base * CFrame.new(OFFS[i]) * CFrame.Angles(0, ang * (i % 2 == 0 and 1 or -1), 0) * CFrame.Angles(0, 0, math.pi / 2) end
	local shake = math.clamp(sp / 400, 0, 0.5) * S.droneGlitch
	cam.CFrame = cam.CFrame * CFrame.Angles(math.noise(os.clock() * 9, 1) * 0.01 * shake * 10, math.noise(os.clock() * 9, 5) * 0.01 * shake * 10, DR.roll)
	horizon.Rotation = -math.deg(DR.roll) * 2
	-- столкновение: быстрый полёт + касание твёрдого объекта или резкая остановка
	if S.droneCrash ~= "off" and os.clock() - DR.t0 > 1.2 then
		local hit = DR.prev and DR.prev > 45 and sp < 8
		if not hit and sp > 28 then
			local ps = OverlapParams.new()
			ps.FilterDescendantsInstances = {lp.Character, folder}; ps.FilterType = Enum.RaycastFilterType.Exclude
			for _, pt in ipairs(workspace:GetPartBoundsInRadius(r.Position, 2.8, ps)) do
				if pt.CanCollide and pt.Transparency < 1 then hit = true; break end
			end
		end
		if hit then DR.crash(r.Position); return end
	end
	DR.prev = sp
	acc += dt
	if acc < 0.1 then return end
	acc = 0
	osd.Visible = S.droneOsd
	for _, e in ipairs(fullEls) do e.Visible = S.droneFull end
	local el = os.clock() - DR.t0
	local dist = (r.Position - DR.home).Magnitude
	local sig = math.clamp(1 - dist / 2000, 0, 1)
	local bat = math.max(0, 100 - el / 6)
	recL.Text = (math.floor(el * 2) % 2 == 0 and "● " or "○ ") .. "REC " .. string.format("%02d:%02d", math.floor(el / 60), math.floor(el % 60)) .. "\n4K 60FPS"
	batL.Text = "🔋 " .. math.floor(bat) .. "%" .. (bat < 15 and "  LOW" or "") .. "\nANGLE"
	altL.Text = "ALT " .. string.format("%.1f", r.Position.Y) .. " m\nSPD " .. math.floor(sp * 0.9) .. " km/h"
	local bars = math.floor(sig * 4 + 0.5)
	sigL.Text = "SIGNAL " .. string.rep("▮", bars) .. string.rep("▯", 4 - bars) .. "\nDIST " .. math.floor(dist) .. " m"
	local chance = ((1 - sig) ^ 2 * 0.7 + sp / 500 * 0.15) * S.droneGlitch
	for _, g in ipairs(glitch) do
		if math.random() < chance then
			g.Visible = true; g.Position = UDim2.new(0, 0, math.random(), 0); g.Size = UDim2.new(1, 0, 0, math.random(3, 22))
			g.BackgroundColor3 = math.random() < 0.5 and C(0, 255, 255) or C(255, 0, 200); g.BackgroundTransparency = 0.55 + math.random() * 0.3
		else g.Visible = false end
	end
end
function DR.crash(pos)
	DR.set(false)
	pcall(function()
		local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, Position = pos}, workspace)
		local ex = Instance.new("Explosion")
		ex.Position = pos; ex.BlastRadius = 10; ex.BlastPressure = 0; ex.DestroyJointRadiusPercent = 0; ex.Visible = true; ex.Parent = workspace
		new("ParticleEmitter", {Texture = "rbxasset://textures/particles/smoke_main.dds", Rate = 0, Lifetime = NR(1, 2), Speed = NR(8, 20), SpreadAngle = Vector2.new(180, 180),
			Size = NS({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8)}), Color = ColorSequence.new(C(60, 60, 60)),
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})}, p):Emit(30)
		new("ParticleEmitter", {Rate = 0, Lifetime = NR(0.4, 0.9), Speed = NR(20, 45), SpreadAngle = Vector2.new(180, 180), Size = NS(0.5), LightEmission = 1,
			Color = ColorSequence.new(C(255, 200, 60), C(255, 70, 20)), Transparency = NS({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Acceleration = Vector3.new(0, -40, 0)}, p):Emit(50)
		local s = new("Sound", {SoundId = "rbxasset://sounds/impact_explosion_03.mp3", Volume = 1}, p); s:Play()
		task.delay(3, function() pcall(function() p:Destroy() end) end)
	end)
	crashF.BackgroundTransparency = 0; crashT.Text = "SIGNAL LOST"
	TS:Create(crashF, TweenInfo.new(1.4), {BackgroundTransparency = 1}):Play()
	task.delay(1.4, function() crashT.Text = "" end)
	local h = hum()
	if S.droneCrash == "hurt" and h then
		local nh = h.Health - S.droneHurt
		if nh <= 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Dead) end) else pcall(function() h.Health = nh end) end
		crashF.BackgroundColor3 = C(255, 40, 40)
		task.delay(1.5, function() crashF.BackgroundColor3 = Color3.new(1, 1, 1) end)
	end
end
function DR.set(on)
	if on == DR.on then return end
	local r = root()
	if on and not r then S.drone = false; return end
	DR.on = on; S.drone = on
	if on then
		DR.home = r.Position; DR.t0 = os.clock(); DR.roll = 0; DR.prev = nil; DR.flyWas = S.fly; DR.speedBak = S.flySpeed
		DR.fov0 = workspace.CurrentCamera.FieldOfView
		S.fly = true; S.flySpeed = S.droneSpeed
		buildModel(); gui.Enabled = true
		RS:BindToRenderStep("L3D_Drone", Enum.RenderPriority.Camera.Value + 2, step)
	else
		pcall(function() RS:UnbindFromRenderStep("L3D_Drone") end)
		S.fly = DR.flyWas or false; S.flySpeed = DR.speedBak or S.flySpeed
		for _, p in pairs(parts) do p:Destroy() end; parts = {}
		for _, p in pairs(props) do p:Destroy() end; props = {}
		gui.Enabled = false
		pcall(function()
			for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
			if not S.fov and DR.fov0 then workspace.CurrentCamera.FieldOfView = DR.fov0 end
		end)
	end
	applyFunctions()
end
M.cleanup[#M.cleanup + 1] = function() if DR.on then DR.set(false) end; pcall(function() RS:UnbindFromRenderStep("L3D_Drone") end) end
RUN.drone = function(c)
	local function draw()
		reset(c)
		row(c, {{S.drone and "🚁 Дрон: ВКЛ (нажми, чтобы выйти)" or "🚁 Включить дрон FPV", function() DR.set(not S.drone); draw() end, not S.drone}})
		label(c, "Ты становишься дроном: вид от первого лица, пропеллеры по углам, наклон камеры, помехи при удалении и скорости, экран-OSD (REC, батарея, высота). Управление как у полёта: WASD + Space/Ctrl (на телефоне джойстик и кнопки в приложении «Полёт»). Дрон виден только тебе.", 13, "sub", nil, UDim2.new(1, 0, 0, 80))
		stepFn(c, "Скорость", function() return S.droneSpeed end, function(v) S.droneSpeed = v; if DR.on then S.flySpeed = v end end, 10, 20, 300, nil, draw)
		stepFn(c, "Поле зрения", function() return S.droneFov end, function(v) S.droneFov = v end, 5, 60, 130, nil, draw)
		stepFn(c, "Сила помех", function() return S.droneGlitch end, function(v) S.droneGlitch = v end, 0.25, 0, 3, nil, draw)
		row(c, {tog("Экран OSD", "droneOsd", draw), tog("Полный интерфейс", "droneFull", draw)})
		row(c, {tog("Показывать корпус и винты", "droneProps", draw)})
		head(c, "При столкновении")
		row(c, {opt("Ничего", "droneCrash", "off", draw), opt("Взрыв", "droneCrash", "boom", draw), opt("Взрыв + урон", "droneCrash", "hurt", draw)})
		stepFn(c, "Урон при ударе", function() return S.droneHurt end, function(v) S.droneHurt = v end, 10, 10, 200, nil, draw)
		label(c, "Чтобы подняться/опуститься на телефоне — зажимай ▲/▼ в приложении «Полёт».", 12, "sub", nil, UDim2.new(1, 0, 0, 30))
	end
	draw()
end
end -- конец дрона

---------------------------------------------------------------- ВКЛАДКА ESP (в стиле меню, с превью твоего скина)
do
local espPage = scrollPage("esp")
local tok = 0
local draw
local function drawInner()
	reset(espPage)
	tok += 1
	local my = tok
	local top = new("Frame", {Size = UDim2.new(1, 0, 0, 236), BackgroundTransparency = 1}, espPage)
	local vf = new("ViewportFrame", {Size = UDim2.fromOffset(230, 230), BackgroundTransparency = 0.3, BorderSizePixel = 0, Ambient = C(170, 170, 180), LightColor = Color3.new(1, 1, 1)}, top)
	bind(vf, "BackgroundColor3", "card"); round(vf, 14)
	local cam = new("Camera", {FieldOfView = 40}, vf)
	vf.CurrentCamera = cam
	local model
	local ch = lp.Character
	if ch then pcall(function() local a = ch.Archivable; ch.Archivable = true; model = ch:Clone(); ch.Archivable = a end) end
	local origs = {}
	if model then
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
		model.Parent = vf
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then origs[d] = {d.Color, d.Material, d.Transparency} end
		end
	end
	local wall = new("Part", {Size = Vector3.new(2.6, 5.5, 0.4), Anchored = true, Color = C(120, 125, 140), Material = Enum.Material.Concrete}, vf)
	local parts = {}
	if S.espNames then parts[#parts + 1] = lp.DisplayName end
	if S.espDist then parts[#parts + 1] = "[12м]" end
	if S.espHp then parts[#parts + 1] = "♥100" end
	local pl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 6), Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3, Text = table.concat(parts, " ")}, vf)
	label(top, "Превью твоего скина", 16, "text", UDim2.new(0, 246, 0, 6), UDim2.new(1, -256, 0, 22), true)
	label(top, "Слева — как будут выглядеть игроки в ESP с текущими настройками: заливка (чамсы), контур, подписи. Стена показывает разницу «сквозь стены» / «только когда видно».", 13, "sub", UDim2.new(0, 246, 0, 32), UDim2.new(1, -256, 0, 80))
	label(top, "Режим: " .. (S.espWalls and "виден сквозь стены" or "только в прямой видимости") .. "\nЗаливка: " .. (S.espChams and pct(1 - S.espFill) or "выкл") .. "   Контур: " .. pct(1 - S.espOutline) ..
		"\nЦвет: " .. ({acc = "акцент", team = "команда", rainbow = "радуга", health = "здоровье", custom = "свой"})[S.espColorMode] or "акцент", 14, "text", UDim2.new(0, 246, 0, 120), UDim2.new(1, -256, 0, 70))
	task.spawn(function()
		local t0 = os.clock()
		while alive and open and tok == my and espPage.Visible and vf.Parent do
			local t = os.clock() - t0
			if model then pcall(function() model:PivotTo(CFrame.new(0, 3, 0) * CFrame.Angles(0, t * 0.8, 0)) end) end
			cam.CFrame = CFrame.lookAt(Vector3.new(0, 3.6, 10), Vector3.new(0, 3, 0))
			wall.CFrame = CFrame.new(1.6, 3, 4); wall.Transparency = S.espWalls and 0.7 or 0
			local m = S.espColorMode
			local color = m == "rainbow" and Color3.fromHSV((t * 0.25) % 1, 0.8, 1) or (m == "health" and Color3.fromHSV(0.33 * (0.5 + 0.5 * math.sin(t)), 0.85, 1) or ACCENTS[S.acc])
			for part, o in pairs(origs) do
				if S.espChams then part.Color = color; part.Material = Enum.Material.Neon; part.Transparency = math.clamp(S.espFill * 0.85, 0, 0.95)
				else part.Color = o[1]; part.Material = o[2]; part.Transparency = o[3] end
			end
			task.wait(0.03)
		end
	end)
	row(espPage, {tog("ESP (" .. S.keys.esp .. ")", "esp", draw), tog("Сквозь стены", "espWalls", draw)})
	row(espPage, {tog("Заливка (чамсы)", "espChams", draw), tog("Метки скрипта ◆", "showTags", draw)})
	head(espPage, "Цвет игроков")
	row(espPage, {opt("Акцент", "espColorMode", "acc", draw), opt("Команда", "espColorMode", "team", draw), opt("Радуга", "espColorMode", "rainbow", draw)})
	row(espPage, {opt("Здоровье", "espColorMode", "health", draw), opt("Свой цвет", "espColorMode", "custom", draw)})
	label(espPage, "Свой цвет заливки", 14, "text", nil, UDim2.new(1, 0, 0, 20), true)
	swatches(espPage, function() return S.espFillColor end, function(v) S.espFillColor = v; S.espColorMode = "custom" end, draw)
	stepRow(espPage, "Прозрачность заливки", "espFill", 0.1, 0, 1, pct, draw)
	stepRow(espPage, "Прозрачность контура", "espOutline", 0.1, 0, 1, pct, draw)
	stepRow(espPage, "Дальность", "espMax", 250, 250, 5000, function(v) return v .. " м" end, draw)
	label(espPage, "Цвет контура", 14, "text", nil, UDim2.new(1, 0, 0, 20), true)
	swatches(espPage, function() return S.espOutColor end, function(v) S.espOutColor = v end, draw)
	head(espPage, "Дополнительно")
	row(espPage, {tog("Рамки (боксы)", "espBox", draw), tog("Трейсеры", "espTracer", draw), tog("Полоска HP", "espBar", draw)})
	row(espPage, {tog("Не показывать команду", "espTeamCheck", draw), tog("Друзья зелёным", "espFriend", draw)})
	stepRow(espPage, "Прозрачность рамок", "espBoxTrans", 0.1, 0, 1, pct, draw)
	row(espPage, {opt("Трейсер снизу", "espTracerFrom", "bottom", draw), opt("От центра", "espTracerFrom", "center", draw), opt("Сверху", "espTracerFrom", "top", draw)})
	stepRow(espPage, "Толщина трейсера", "espTracerThick", 1, 1, 6, num, draw)
	stepRow(espPage, "Размер подписей", "espTextSize", 1, 8, 28, num, draw)
	label(espPage, "Цвет подписей", 14, "text", nil, UDim2.new(1, 0, 0, 20), true)
	swatches(espPage, function() return S.espNameColor end, function(v) S.espNameColor = v end, draw)
	head(espPage, "Подписи")
	row(espPage, {tog("Имена", "espNames", draw), tog("Дистанция", "espDist", draw), tog("Здоровье", "espHp", draw)})
end
draw = function()
	local ok, err = pcall(drawInner)
	if not ok then
		reset(espPage)
		label(espPage, "Ошибка вкладки ESP: " .. tostring(err), 14, "text", nil, UDim2.new(1, 0, 0, 80))
		row(espPage, {{"Сбросить режим цвета", function() S.espColorMode = "acc"; draw() end}})
	end
end
M.espRefresh = function() if pages.esp.Visible then draw() end end
end -- конец вкладки ESP
M.load(80, "Игроки и магазин…")

---------------------------------------------------------------- СПИСОК ИГРОКОВ: создатель / тестеры / помощники / ранги / все
do
local function section(role)
	if role == "creator" or role == "owner" then return 1 end
	if role == "tester" then return 2 end
	if role == "helper" or role == "admin" then return 3 end
	if role then return 4 end
	return 5
end
local TITLES = {"👑 Создатель", "🧪 Тестеры", "🛠 Помощники", "🏅 Ранги", "👥 Все игроки"}
local card
RUN.players = function(c)
	local me = c
	local function showCard(name, userId, p)
		card = {name = name, userId = userId, p = p}
	end
	local function draw()
		reset(c)
		if card then
			row(c, {{"‹ К списку", function() card = nil; draw() end, true}})
			local top = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 150), "card", 16)
			local av = new("ImageLabel", {Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(110, 110), BackgroundTransparency = 0, BorderSizePixel = 0}, top)
			bind(av, "BackgroundColor3", "card2"); round(av, 55)
			task.spawn(function()
				local id = card.userId
				if not id then local ok, r = pcall(function() return Players:GetUserIdFromNameAsync(card.name) end); id = ok and r or nil end
				if id then
					local ok, img = pcall(function() return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
					if ok and av.Parent then av.Image = img end
				end
			end)
			local role = roleOfName(card.name) or (card.p and M.roleFor(card.p))
			local r = role and M.ROLE[role]
			local u = card.p and M.tagOf(card.p)
			label(top, card.name, 22, "text", UDim2.new(0, 142, 0, 12), UDim2.new(1, -152, 0, 30), true)
			if r then label(top, r[1], 16, "text", UDim2.new(0, 142, 0, 44), UDim2.new(1, -152, 0, 22), true).TextColor3 = Color3.fromHex(r[2]) end
			local info = {}
			if u then
				info[#info + 1] = "◆ Играет с L3D · Lv " .. tostring(u.level or 1)
				if (u.exec or "") ~= "" then info[#info + 1] = "💉 " .. u.exec end
				if (u.game or "") ~= "" then info[#info + 1] = "🎮 " .. u.game end
				if (u.status or "") ~= "" then info[#info + 1] = "💬 " .. u.status end
			else
				info[#info + 1] = "Нет данных о скрипте (сервер не подключён или игрок без скрипта)"
			end
			label(top, table.concat(info, "\n"), 13, "sub", UDim2.new(0, 142, 0, 70), UDim2.new(1, -152, 0, 76))
			if role == "creator" then
				S.claudeSecret = true; isDirty = true
				label(c, "Создатель и автор этого лаунчера. Спасибо, что играешь! 💛", 15, "text", nil, UDim2.new(1, 0, 0, 40), true)
				label(c, "🤖 Ты открыл секрет: в разделе «Помощники» появился Claude — ИИ, который помогал писать этот скрипт.", 13, "sub", nil, UDim2.new(1, 0, 0, 40))
			end
			return
		end
		row(c, {{"🔄 Обновить", draw, true}})
		local groups = {{}, {}, {}, {}, {}}
		local seen = {}
		-- создатель всегда закреплён сверху
		for _, n in ipairs(ROLES_BY_NAME.creator) do
			local pl = Players:FindFirstChild(n)
			groups[1][#groups[1] + 1] = {name = n, p = pl, pinned = true}
			seen[n:lower()] = true
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if not seen[p.Name:lower()] then
				local role = M.roleFor(p)
				local sec = section(role)
				if sec == 5 and p ~= lp then end
				groups[sec][#groups[sec] + 1] = {name = p.Name, display = p.DisplayName, p = p, role = role}
			end
		end
		if S.claudeSecret then table.insert(groups[3], 1, {name = "Claude", display = "Claude 🤖", secret = true}) end
		for sec = 1, 5 do
			if #groups[sec] > 0 then
				head(c, TITLES[sec] .. " (" .. #groups[sec] .. ")")
				for _, e in ipairs(groups[sec]) do
					local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
					local u = e.p and M.tagOf(e.p)
					label(fr, (e.display or e.name) .. (e.p == lp and " (ты)" or "") .. (e.pinned and not e.p and "  · не в этом сервере" or "") .. (u and "  (скрипт)" or ""), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.42, 0, 1, 0), true)
					if e.secret then
						local b = button(fr, "Привет!", function() toast("🤖 Я Claude — помогал писать этот лаунчер. Приятной игры!", 5) end, UDim2.new(0.3, 0, 0, 32)); b.Position = UDim2.new(0.68, 0, 0.5, -16)
					else
						local x = 0.44
						if e.p and e.p ~= lp then
							local b1 = button(fr, "ТП", function() local his = e.p.Character and e.p.Character:FindFirstChild("HumanoidRootPart"); if his then tpTo(his.Position) end end, UDim2.new(0.16, 0, 0, 32)); b1.Position = UDim2.new(x, 0, 0.5, -16)
							local b2 = button(fr, "👁", function() M.spectate(e.p) end, UDim2.new(0.12, 0, 0, 32), true); b2.Position = UDim2.new(x + 0.17, 0, 0.5, -16)
							x = x + 0.30
						end
						local b3 = button(fr, "Профиль", function() showCard(e.name, e.p and e.p.UserId, e.p); draw() end, UDim2.new(0.26, 0, 0, 32), true); b3.Position = UDim2.new(0.73, 0, 0.5, -16)
					end
				end
			end
		end
	end
	card = nil
	draw()
end
end -- конец списка игроков

---------------------------------------------------------------- МАГАЗИН УКРАШЕНИЙ ПРОФИЛЯ
do
local SHOP = {
	{"frame", "Рамка: радуга", 150, "rainbow"}, {"frame", "Рамка: неон", 250, "neon"}, {"frame", "Рамка: золото", 400, "gold"}, {"frame", "Рамка: огонь", 600, "fire"}, {"frame", "Рамка: пульс", 100, "pulse"},
	{"badge", "Значок ⭐", 50, "⭐"}, {"badge", "Значок 🔥", 100, "🔥"}, {"badge", "Значок 🦄", 200, "🦄"}, {"badge", "Значок 💎", 300, "💎"}, {"badge", "Значок 🐉", 400, "🐉"}, {"badge", "Значок 👑", 500, "👑"},
	{"nameColor", "Ник красный", 80, 2}, {"nameColor", "Ник зелёный", 80, 5}, {"nameColor", "Ник голубой", 80, 6}, {"nameColor", "Ник розовый", 80, 9}, {"nameColor", "Ник радужный", 300, -1},
	{"profBg", "Фон: тёмно-синий", 60, 7}, {"profBg", "Фон: фиолетовый", 60, 8}, {"profBg", "Фон: красный", 60, 2}, {"profBg", "Фон: радужный", 250, -1},
}
local KINDS = {frame = "Рамки аватара", badge = "Значки у ника", nameColor = "Цвет ника", profBg = "Фон профиля"}
RUN.shop = function(c)
	local function draw()
		reset(c)
		label(c, "🪙 Монеты: " .. (S.coins or 0), 22, "text", nil, UDim2.new(1, 0, 0, 30), true)
		label(c, "Монеты капают за время в игре и ежедневный вход. Купленное можно надевать и снимать.", 12, "sub", nil, UDim2.new(1, 0, 0, 30))
		for _, kind in ipairs({"frame", "badge", "nameColor", "profBg"}) do
			head(c, KINDS[kind])
			row(c, {{"Снять", function() S[kind] = (kind == "frame") and "ring" or ((kind == "badge") and "" or 0); draw() end, true}})
			for _, it in ipairs(SHOP) do
				if it[1] == kind then
					local id = kind .. ":" .. tostring(it[4])
					local own, on = S.owned[id], S[kind] == it[4]
					local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
					label(fr, it[2] .. (own and "" or ("   🪙 " .. it[3])), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.6, 0, 1, 0), true)
					local b = button(fr, on and "Надето" or (own and "Надеть" or "Купить"), function()
						if own then S[kind] = it[4]
						elseif (S.coins or 0) >= it[3] then S.coins -= it[3]; S.owned[id] = true; S[kind] = it[4]; toast("Куплено: " .. it[2], 2.5)
						else toast("Не хватает монет", 2.5) end
						isDirty = true; draw()
					end, UDim2.new(0.3, 0, 0, 32), on)
					b.Position = UDim2.new(0.68, 0, 0.5, -16)
				end
			end
		end
		if M.zooUI then M.zooUI(c, draw) end
	end
	draw()
end
end -- конец магазина

---------------------------------------------------------------- АДМИН-МЕНЮ (видно создателю и тем, кому выдали)
do
RUN.admin = function(c)
	if not M.isAdmin() then label(c, "Нет доступа.", 18, "text", nil, UDim2.new(1, 0, 0, 30), true); return end
	local target = M.adminTarget
	local roleTb, rankTb, idTb
	local function draw()
		reset(c)
		label(c, "🛡 Админ-меню", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		label(c, "Выдача другим людям идёт через твой сервер (нужен l3d_server.js, адрес в «Профиль»). Себе можно без сервера.", 12, "sub", nil, UDim2.new(1, 0, 0, 34))
		head(c, "Себе")
		row(c, {{"+100 🪙", function() M.addCoins(100); draw() end}, {"+1000 🪙", function() M.addCoins(1000); draw() end}, {"+10000 🪙", function() M.addCoins(10000); draw() end}})
		row(c, {{"+100 XP", function() M.addXp(100); draw() end, true}, {"+1000 XP", function() M.addXp(1000); draw() end, true}, {"Обнулить XP", function() S.xp = 0; M.refreshName(); draw() end, true}})
		label(c, "Монеты: " .. (S.coins or 0) .. "  ·  XP: " .. (S.xp or 0) .. "  ·  Lv " .. M.level(), 13, "sub", nil, UDim2.new(1, 0, 0, 20))
		head(c, "Выбрать игрока")
		local pr = {}
		for _, p in ipairs(Players:GetPlayers()) do
			pr[#pr + 1] = {p.DisplayName, function() target = {id = p.UserId, name = p.Name}; M.adminTarget = target; draw() end, not (target and target.id == p.UserId)}
		end
		if #pr > 0 then chunk(c, pr, 3) end
		idTb = textbox(c, "или UserId числом", "", 36)
		row(c, {{"Выбрать по UserId", function() local n = tonumber(idTb.Text); if n then target = {id = n, name = "ID " .. n}; M.adminTarget = target; draw() end end, true}})
		if target then
			label(c, "Цель: " .. target.name .. " (" .. target.id .. ")", 15, "text", nil, UDim2.new(1, 0, 0, 22), true)
			local function give(typ, n, name)
				task.spawn(function()
					local ok = M.NET.grant(target.id, typ, n, name)
					toast(ok and "✅ Выдано" or "⚠ Выдача другим идёт через сервер: задай адрес в «Настройки → Конфиг и сеть» и убедись, что игрок онлайн со скриптом", 5)
				end)
			end
			row(c, {{"+100 🪙", function() give("coins", 100) end}, {"+1000 🪙", function() give("coins", 1000) end}, {"+500 XP", function() give("xp", 500) end}})
			rankTb = textbox(c, "название ранга (например: Легенда)", "", 36)
			row(c, {{"Выдать ранг", function() give("rank", 0, rankTb.Text) end}})
			row(c, {{"Роль: тестер", function() give("role", 0, "tester") end, true}, {"Роль: помощник", function() give("role", 0, "helper") end, true}, {"Роль: VIP", function() give("role", 0, "vip") end, true}})
			row(c, {{"Выдать админ-меню", function() give("admin", 0) end}, {"Снять роль", function() give("role", 0, "") end, true}})
		end
		head(c, "Список ролей по нику (локально, у тебя на экране)")
		label(c, "Создатель: " .. table.concat(ROLES_BY_NAME.creator, ", ") .. "\nТестеры: " .. (#ROLES_BY_NAME.tester > 0 and table.concat(ROLES_BY_NAME.tester, ", ") or "—") ..
			"\nПомощники: " .. (#ROLES_BY_NAME.helper > 0 and table.concat(ROLES_BY_NAME.helper, ", ") or "—"), 13, "sub", nil, UDim2.new(1, 0, 0, 60))
		roleTb = textbox(c, "ник Roblox", "", 36)
		row(c, {{"→ тестер", function() table.insert(ROLES_BY_NAME.tester, roleTb.Text); draw() end, true}, {"→ помощник", function() table.insert(ROLES_BY_NAME.helper, roleTb.Text); draw() end, true},
			{"→ ранг", function() table.insert(ROLES_BY_NAME.rank, roleTb.Text); draw() end, true}})
		label(c, "Чтобы роли сохранялись навсегда и у всех — впиши ники в таблицу ROLES_BY_NAME в начале файла скрипта.", 12, "sub", nil, UDim2.new(1, 0, 0, 34))
	end
	draw()
end
end -- конец админки

---------------------------------------------------------------- БРАУЗЕР (текстовый: поиск и чтение страниц)
do
local function http(url)
	local rq = request or http_request or (syn and syn.request)
	if rq then
		local ok, res = pcall(rq, {Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"}})
		if ok and res and res.StatusCode and res.StatusCode < 400 then return res.Body end
	end
	local ok, b = pcall(function() return game:HttpGet(url) end)
	if ok then return b end
end
local function unesc(s)
	s = s:gsub("<[^>]+>", "")
	s = s:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&#x27;", "'"):gsub("&#39;", "'"):gsub("&nbsp;", " ")
	return s
end
local function urldecode(s)
	s = s:gsub("+", " ")
	s = s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
	return s
end
local function search(qs)
	local html = http("https://html.duckduckgo.com/html/?q=" .. HS:UrlEncode(qs))
	if not html then return nil, "нет ответа (проверь интернет и request в инжекторе)" end
	local res = {}
	local function add(href, title)
		local real = href:match("uddg=([^&]+)")
		real = real and urldecode(real) or href
		if real:sub(1, 2) == "//" then real = "https:" .. real end
		res[#res + 1] = {url = real, title = unesc(title)}
	end
	for href, title in html:gmatch('<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.-)</a>') do add(href, title) end
	if #res == 0 then for href, title in html:gmatch('<a[^>]*href="([^"]+)"[^>]*class="result__a"[^>]*>(.-)</a>') do add(href, title) end end
	local i = 0
	for sn in html:gmatch('class="result__snippet"[^>]*>(.-)</a>') do i += 1; if res[i] then res[i].snip = unesc(sn) end end
	if #res == 0 then return nil, "ничего не найдено или поисковик не отдал страницу" end
	return res
end
local function readPage(url)
	local html = http(url)
	if not html then return nil, "страница не открылась" end
	local links = {}
	for href, t in html:gmatch('<a[^>]-href="(https?://[^"]+)"[^>]*>(.-)</a>') do
		local tx = unesc(t):gsub("%s+", " ")
		if #tx > 2 and #links < 14 then links[#links + 1] = {url = href, title = tx:sub(1, 60)} end
	end
	local body = html:gsub("<script.-</script>", ""):gsub("<style.-</style>", ""):gsub("<!%-%-.-%-%->", "")
	body = body:gsub("<br%s*/?>", "\n"):gsub("</p>", "\n"):gsub("</div>", "\n"):gsub("</li>", "\n"):gsub("</h%d>", "\n")
	body = unesc(body)
	body = body:gsub("[ \t]+", " "):gsub("\n%s*\n%s*\n+", "\n\n")
	return body:sub(1, 5000), links
end
M.br = {http = http, unesc = unesc, urldecode = urldecode, search = search, readPage = readPage}
local hist = {}
RUN.browser = function(c)
	local me = c
	local view = M.brView or {mode = "home"}
	M.brView = view
	local qtb
	local function draw()
		reset(c)
		qtb = textbox(c, "Поиск или адрес сайта (https://…)", view.q or "", 40)
		row(c, {{"🔎 Найти", function()
			local t = qtb.Text
			if t == "" then return end
			view.q = t
			if t:match("^https?://") then view.go(t) else view.find(t) end
		end}, {"‹ Назад", function() local b = table.remove(hist); if b then view.mode, view.items, view.page, view.links, view.url = b.mode, b.items, b.page, b.links, b.url; draw() end end, true},
			{"📋 Ссылка", function() if setclipboard and view.url then pcall(setclipboard, view.url) end end, true}})
		local function push() hist[#hist + 1] = {mode = view.mode, items = view.items, page = view.page, links = view.links, url = view.url} end
		function view.find(t)
			label(c, "Ищу…", 14, "sub", nil, UDim2.new(1, 0, 0, 20))
			task.spawn(function()
				local r, err = search(t)
				push()
				if r then view.mode, view.items, view.err = "results", r, nil else view.mode, view.items, view.err = "error", nil, err end
				if content == me then draw() end
			end)
		end
		function view.go(u)
			label(c, "Открываю…", 14, "sub", nil, UDim2.new(1, 0, 0, 20))
			task.spawn(function()
				local txt, links = readPage(u)
				push()
				if txt then view.mode, view.page, view.links, view.url, view.err = "page", txt, links, u, nil
				else view.mode, view.err = "error", links end
				if content == me then draw() end
			end)
		end
		if view.mode == "home" then
			label(c, "Текстовый браузер: поиск через DuckDuckGo и чтение страниц как текст (без картинок и JavaScript). Нужен request/HttpGet в инжекторе.", 13, "sub", nil, UDim2.new(1, 0, 0, 50))
		elseif view.mode == "error" then
			label(c, "⚠ " .. tostring(view.err), 14, "text", nil, UDim2.new(1, 0, 0, 40))
		elseif view.mode == "results" then
			for _, it in ipairs(view.items) do
				local b = button(c, it.title:sub(1, 90), function() view.url = it.url; view.go(it.url) end, UDim2.new(1, 0, 0, 38), true)
				b.TextXAlignment = Enum.TextXAlignment.Left
				if it.snip then label(c, it.snip:sub(1, 220), 12, "sub", nil, UDim2.new(1, 0, 0, 36)) end
			end
		elseif view.mode == "page" then
			label(c, tostring(view.url), 12, "sub", nil, UDim2.new(1, 0, 0, 18))
			local l = label(c, view.page, 14, "text", nil, UDim2.new(1, -4, 0, 0))
			l.AutomaticSize = Enum.AutomaticSize.Y; l.TextYAlignment = Enum.TextYAlignment.Top
			if view.links and #view.links > 0 then
				head(c, "Ссылки на странице")
				for _, lk in ipairs(view.links) do
					local b = button(c, lk.title, function() view.url = lk.url; view.go(lk.url) end, UDim2.new(1, 0, 0, 34), true)
					b.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
		end
	end
	draw()
end
end -- конец браузера

---------------------------------------------------------------- ЭМОЦИИ И ПАКЕТЫ АНИМАЦИЙ
do
local EMOTES = {{"👋 Привет", 507770239}, {"👉 Показать", 507770453}, {"💃 Танец 1", 507771019}, {"🕺 Танец 2", 507776043}, {"🎶 Танец 3", 507777268}, {"😂 Смех", 507770818}, {"🙌 Ура", 507770677}}
local PACKS = {
	{"Ниндзя", {idle = 656117400, walk = 656121766, run = 656118852, jump = 656117878, fall = 656115606, climb = 656114359}},
	{"Зомби", {idle = 616158929, walk = 616168032, run = 616163682, jump = 616161997, fall = 616157476, climb = 616156119}},
	{"Супергерой", {idle = 616111295, walk = 616122287, run = 616117076, jump = 616115533, fall = 616108001, climb = 616104706}},
	{"Робот", {idle = 616088211, walk = 616095330, run = 616091570, jump = 616090535, fall = 616087089, climb = 616086039}},
	{"Мультяшный", {idle = 742637544, walk = 742640026, run = 742638842, jump = 742637942, fall = 742637151, climb = 742636889}},
	{"Игрушка", {idle = 782841498, walk = 782843345, run = 782842708, jump = 782847020, fall = 782846423, climb = 782843869}},
	{"Вампир", {idle = 1083445855, walk = 1083473930, run = 1083462077, jump = 1083455352, fall = 1083443587, climb = 1083439238}},
}
local SLOTS = {{"idle", "Стойка"}, {"walk", "Ходьба"}, {"run", "Бег"}, {"jump", "Прыжок"}, {"fall", "Падение"}, {"climb", "Лазание"}}
local track
local function stopEmote() if track then pcall(function() track:Stop(0.2) end); track = nil end end
local function playAnim(id, loop)
	stopEmote()
	local h = hum()
	if not h then return false, "нет персонажа" end
	local an = h:FindFirstChildOfClass("Animator") or h:FindFirstChild("Animator")
	if not an then return false, "у персонажа нет Animator" end
	local rig = h.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
	local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, t = pcall(function() return an:LoadAnimation(a) end)
	if not ok or not t then return false, "LoadAnimation: " .. tostring(t) end
	t.Priority = Enum.AnimationPriority.Action4; t.Looped = loop
	t:Play(0.2)
	local t0 = os.clock()
	while t.Length == 0 and os.clock() - t0 < 2 do task.wait(0.1) end
	if t.Length == 0 then
		pcall(function() t:Stop() end)
		return false, "анимация не загрузилась (rig: " .. rig .. "). Причины: ID чужой и недоступен в этой игре, не тот тип (R6/R15) или это не анимация, а набор"
	end
	track = t
	return true, "rig " .. rig
end
local function setSlot(slot, id)
	local ch = lp.Character
	local an = ch and ch:FindFirstChild("Animate")
	if not an then return false end
	local map = {idle = {"idle", "Animation1"}, walk = {"walk", "WalkAnim"}, run = {"run", "RunAnim"}, jump = {"jump", "JumpAnim"}, fall = {"fall", "FallAnim"}, climb = {"climb", "ClimbAnim"}}
	local m = map[slot]
	local grp = an:FindFirstChild(m[1])
	local obj = grp and grp:FindFirstChild(m[2])
	if obj then obj.AnimationId = "rbxassetid://" .. tostring(id); if slot == "idle" then local o2 = grp:FindFirstChild("Animation2"); if o2 then o2.AnimationId = obj.AnimationId end end; return true end
	return false
end
RUN.emote = function(c)
	local msg = ""
	local function draw()
		reset(c)
		label(c, msg ~= "" and msg or "Анимации видят и другие игроки (проигрываются на твоём персонаже). Требуется R15.", 13, "sub", nil, UDim2.new(1, 0, 0, 34))
		head(c, "Эмоции")
		local e = {}
		for _, it in ipairs(EMOTES) do e[#e + 1] = {it[1], function() local ok, why = playAnim(it[2], true); msg = ok and ("▶ Играет (" .. why .. ")") or ("⚠ " .. tostring(why)); draw() end, true} end
		chunk(c, e, 3)
		local idb = textbox(c, "ID своей анимации (число)", "", 38)
		row(c, {{"▶ Своя анимация", function() local ok, why = playAnim(idb.Text, true); msg = ok and ("▶ Играет (" .. why .. ")") or ("⚠ " .. tostring(why)); draw() end}, {"■ Стоп", function() stopEmote(); msg = "Остановлено"; draw() end, true}})
		head(c, "Пакеты анимаций (стойка, ходьба, бег, прыжок…)")
		local p = {}
		for _, pk in ipairs(PACKS) do
			p[#p + 1] = {pk[1], function()
				local okc = 0
				for slot, id in pairs(pk[2]) do if setSlot(slot, id) then okc += 1 end end
				msg = okc > 0 and ("Пакет «" .. pk[1] .. "» применён (" .. okc .. "/6). Подвигайся, чтобы увидеть.") or "⚠ у персонажа нет Animate (нужен R15 и стандартные анимации)"
				draw()
			end, true}
		end
		chunk(c, p, 3)
		label(c, "ID паков взяты по памяти: если какой-то слот не поменялся, вставь свой ID ниже.", 12, "sub", nil, UDim2.new(1, 0, 0, 30))
		head(c, "Свой ID на слот")
		local slotTb = textbox(c, "ID анимации", "", 38)
		local s = {}
		for _, sl in ipairs(SLOTS) do s[#s + 1] = {sl[2], function() msg = setSlot(sl[1], slotTb.Text) and ("Слот «" .. sl[2] .. "» заменён") or "⚠ не удалось"; draw() end, true} end
		chunk(c, s, 3)
	end
	draw()
end
end -- конец эмоций

---------------------------------------------------------------- АВАТАР (работает без ApplyDescription: примерка через модель внешности)
do
local msg = ""
local function strip(ch)
	for _, o in ipairs(ch:GetChildren()) do
		if o:IsA("Accoutrement") or o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") or o:IsA("BodyColors") then o:Destroy() end
	end
end
local function putFace(model)
	local ch = lp.Character
	local head = ch and ch:FindFirstChild("Head")
	local mh = model:FindFirstChild("Head")
	if head and mh then
		local f = mh:FindFirstChildOfClass("Decal")
		if f then local old = head:FindFirstChildOfClass("Decal"); if old then old:Destroy() end; f:Clone().Parent = head end
	end
end
local function applyModel(model)
	local ch, h = lp.Character, hum()
	if not (ch and h and model) then return false end
	strip(ch)
	for _, o in ipairs(model:GetChildren()) do
		if o:IsA("Accoutrement") then pcall(function() h:AddAccessory(o:Clone()) end)
		elseif o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") or o:IsA("BodyColors") then o:Clone().Parent = ch end
	end
	putFace(model)
	for _, mp in ipairs(model:GetChildren()) do
		if mp:IsA("MeshPart") then
			local mine = ch:FindFirstChild(mp.Name)
			if mine and mine:IsA("MeshPart") then pcall(function() mine.MeshId = mp.MeshId; mine.TextureID = mp.TextureID end) end
		end
	end
	local mh, hh = model:FindFirstChild("Head"), ch:FindFirstChild("Head")
	if mh and hh then
		local ms, hs = mh:FindFirstChildOfClass("SpecialMesh"), hh:FindFirstChildOfClass("SpecialMesh")
		if ms and hs then pcall(function() hs.MeshId = ms.MeshId; hs.TextureId = ms.TextureId; hs.Scale = ms.Scale end) end
	end
	return true
end
local function wearObj(o, h, ch)
	if o:IsA("Accoutrement") then
		if o:IsA("Accessory") then
			for _, a in ipairs(ch:GetChildren()) do if a:IsA("Accessory") and a.AccessoryType == o.AccessoryType then a:Destroy() end end
		end
		pcall(function() h:AddAccessory(o) end)
	elseif o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then
		for _, a in ipairs(ch:GetChildren()) do if a.ClassName == o.ClassName then a:Destroy() end end
		o.Parent = ch
	elseif o:IsA("Decal") and o.Name == "face" then
		local head = ch:FindFirstChild("Head")
		if head then local old = head:FindFirstChild("face"); if old then old:Destroy() end; o.Parent = head end
	else
		for _, k in ipairs(o:GetChildren()) do wearObj(k, h, ch) end
	end
end
local function wearAsset(id)
	local ch, h = lp.Character, hum()
	if not (ch and h) then return false, "нет персонажа" end
	local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
	if not ok or not objs then return false, "инжектор не умеет GetObjects или предмет недоступен" end
	for _, o in ipairs(objs) do wearObj(o, h, ch) end
	return true
end
local SC = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale", "BodyTypeScale", "BodyProportionScale"}
local function copyScales(p)
	local th, mh = p.Character and p.Character:FindFirstChildOfClass("Humanoid"), hum()
	if th and mh then
		for _, n in ipairs(SC) do
			local a, b = th:FindFirstChild(n), mh:FindFirstChild(n)
			if a and b then b.Value = a.Value end
		end
	end
end
local function copyUser(userId)
	local errs = {}
	local ok, model = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
	if ok and model then
		local r = applyModel(model)
		pcall(function() model:Destroy() end)
		local pl = Players:GetPlayerByUserId(userId)
		if pl and pl ~= lp then pcall(copyScales, pl) end
		if r then return true, "способ A: модель внешности" end
	else errs[#errs + 1] = "A: " .. tostring(model) end
	local ok2, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
	if ok2 and desc then
		local h = hum()
		local ok3, e3 = pcall(function() h:ApplyDescription(desc) end)
		if ok3 then return true, "способ B: ApplyDescription" end
		errs[#errs + 1] = "B: " .. tostring(e3)
		local n = 0
		for _, f in ipairs({"HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory", "ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory"}) do
			for id in tostring(desc[f] or ""):gmatch("%d+") do if wearAsset(id) then n += 1 end end
		end
		for _, f in ipairs({"Shirt", "Pants", "GraphicTShirt", "Face"}) do
			if desc[f] and desc[f] ~= 0 and wearAsset(desc[f]) then n += 1 end
		end
		if n > 0 then return true, "способ C: по ID предметов (" .. n .. ")" end
		errs[#errs + 1] = "C: ни один предмет не загрузился (инжектор без GetObjects?)"
	else errs[#errs + 1] = "B: " .. tostring(desc) end
	return false, table.concat(errs, " | ")
end
local SKIN = {C(255, 224, 189), C(241, 194, 125), C(198, 134, 66), C(141, 85, 36), C(92, 58, 30), C(255, 214, 0), C(120, 200, 120), C(120, 160, 255)}
local SCALES = {{"BodyHeightScale", "Рост"}, {"BodyWidthScale", "Ширина"}, {"BodyDepthScale", "Глубина"}, {"HeadScale", "Голова"}, {"BodyTypeScale", "Тип тела"}, {"BodyProportionScale", "Пропорции"}}
local function scaleVal(name) local h = hum(); return h and h:FindFirstChild(name) end
RUN.avatar = function(c)
	local results = M.avResults or {}
	local function draw()
		reset(c)
		label(c, msg ~= "" and msg or "Изменения внешности клиентские: видишь только ты. Работает на R15.", 13, "sub", nil, UDim2.new(1, 0, 0, 34))
		row(c, {{"↩ Вернуть мой настоящий вид", function() local ok, why = copyUser(lp.UserId); msg = ok and ("✅ Вид возвращён · " .. why) or ("⚠ " .. tostring(why)); draw() end, true}})
		head(c, "Скопировать вид игрока на сервере")
		local pr = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then pr[#pr + 1] = {p.DisplayName, function() task.spawn(function() local ok, why = copyUser(p.UserId); msg = ok and ("✅ " .. p.DisplayName .. " · " .. why) or ("⚠ " .. tostring(why)); draw() end) end, true} end
		end
		if #pr == 0 then label(c, "Других игроков нет.", 13, "sub", nil, UDim2.new(1, 0, 0, 18)) else chunk(c, pr, 3) end
		head(c, "Вид по нику Roblox")
		local nb = textbox(c, "ник", "", 38)
		row(c, {{"Применить", function()
			task.spawn(function()
				local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(nb.Text) end)
				local ok2, why = false, "ник не найден"; if ok then ok2, why = copyUser(id) end; msg = ok2 and ("✅ Применено · " .. why) or ("⚠ " .. tostring(why))
				draw()
			end)
		end}})
		head(c, "Предмет по ID (шапки, волосы, одежда, лицо…)")
		local ib = textbox(c, "ID предмета из каталога (число)", "", 38)
		row(c, {{"Надеть", function() local ok, e = wearAsset(ib.Text); msg = ok and "✅ Надето" or ("⚠ " .. tostring(e)); draw() end}})
		head(c, "Поиск в каталоге Roblox")
		local kb = textbox(c, "например: crown, hoodie, wings", "", 38)
		row(c, {{"🔎 Искать", function()
			task.spawn(function()
				M.avResults = {}
				local rq = request or http_request or (syn and syn.request)
				if not rq then msg = "⚠ у инжектора нет request"; draw(); return end
				local ok, res = pcall(rq, {Url = "https://catalog.roblox.com/v1/search/items/details?Keyword=" .. HS:UrlEncode(kb.Text) .. "&Limit=30&SortType=0", Method = "GET"})
				if ok and res and res.StatusCode == 200 then
					local ok2, d = pcall(HS.JSONDecode, HS, res.Body)
					if ok2 and d and d.data then
						for _, it in ipairs(d.data) do if it.itemType == "Asset" then M.avResults[#M.avResults + 1] = {id = it.id, name = it.name} end end
					end
					msg = "Найдено: " .. #M.avResults
				else msg = "⚠ каталог не ответил" end
				draw()
			end)
		end, true}})
		for i, it in ipairs(M.avResults or {}) do
			if i > 12 then break end
			row(c, {{tostring(it.name):sub(1, 40) .. "  (" .. tostring(it.id) .. ")", function() local ok, e = wearAsset(it.id); msg = ok and ("✅ Надето: " .. tostring(it.name)) or ("⚠ " .. tostring(e)); draw() end, true}})
		end
		head(c, "Цвет кожи")
		local sr = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)}, c)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, sr)
		for _, colr in ipairs(SKIN) do
			local b = new("TextButton", {Text = "", BackgroundColor3 = colr, Size = UDim2.fromOffset(32, 32), BorderSizePixel = 0}, sr)
			round(b, 16)
			tap(b, function()
				local ch = lp.Character
				if ch then
					local bc = ch:FindFirstChildOfClass("BodyColors") or new("BodyColors", {}, ch)
					bc.HeadColor3, bc.TorsoColor3, bc.LeftArmColor3, bc.RightArmColor3, bc.LeftLegColor3, bc.RightLegColor3 = colr, colr, colr, colr, colr, colr
					msg = "✅ Цвет изменён"; draw()
				end
			end)
		end
		head(c, "Пропорции тела (R15)")
		for _, sc in ipairs(SCALES) do
			if scaleVal(sc[1]) then
				stepFn(c, sc[2], function() local v = scaleVal(sc[1]); return v and v.Value or 1 end,
					function(x) local v = scaleVal(sc[1]); if v then v.Value = x end end, 0.05, 0.5, 1.5, nil, draw)
			end
		end
	end
	draw()
end
end -- конец аватара
M.load(86, "Питомцы и профиль…")

---------------------------------------------------------------- ПИТОМЦЫ + ЗОО-МАГАЗИН + ТЕЛЕФОН
do
local PETS = {
	cat = {"🐱 Кот", 300, C(235, 160, 80), 1.6, 0.5}, dog = {"🐶 Собака", 300, C(170, 120, 75), 0.8, 0.45}, rabbit = {"🐰 Кролик", 400, C(240, 240, 240), 2.0, 1.2},
	fox = {"🦊 Лиса", 800, C(255, 110, 30), 1.3, 0.6}, duck = {"🦆 Утка", 200, C(255, 220, 60), 1.1, 0.2}, panda = {"🐼 Панда", 1500, C(245, 245, 245), 0.6, 0.3},
	neko = {"😺 Кошко-девочка", 1200, C(255, 200, 225), 1.9, 0.5},
}
local PORDER = {"duck", "cat", "dog", "rabbit", "fox", "panda", "neko"}
S.petOwned = S.petOwned or {}; S.petActive = S.petActive or ""; S.petHunger = S.petHunger or 100; S.petFood = S.petFood or 0; S.petSoundId = S.petSoundId or ""
local folder = keep(new("Folder", {Name = "LauncherPets"}, workspace))
local pet
local function build(kind)
	if pet then for _, p in ipairs(pet.parts) do p[1]:Destroy() end; pet = nil end
	if not PETS[kind] then return end
	local col, parts = PETS[kind][3], {}
	local function add(size, color, off, shape)
		parts[#parts + 1] = {new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = size, Color = color,
			Material = Enum.Material.SmoothPlastic, Shape = shape or Enum.PartType.Block}, folder), off}
	end
	local eh = PETS[kind][5]
	if kind == "neko" then
		local skin, hair, cloth = C(255, 224, 205), C(255, 150, 200), C(255, 120, 170)
		local function addL(size, color, off, pivot, sign)
			parts[#parts + 1] = {new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = size, Color = color, Material = Enum.Material.SmoothPlastic}, folder), off, pivot, sign}
		end
		add(Vector3.new(1.3, 1.5, 0.7), cloth, CFrame.new(0, 0, 0))
		add(Vector3.new(1.6, 0.5, 0.9), cloth, CFrame.new(0, -0.85, 0))
		add(Vector3.new(1.3, 1.3, 1.3), skin, CFrame.new(0, 1.35, 0))
		add(Vector3.new(1.4, 0.5, 1.4), hair, CFrame.new(0, 1.9, 0.05))
		add(Vector3.new(0.4, 0.7, 0.3), hair, CFrame.new(-0.5, 2.35, 0)); add(Vector3.new(0.4, 0.7, 0.3), hair, CFrame.new(0.5, 2.35, 0))
		add(Vector3.new(0.2, 0.2, 0.1), C(30, 30, 60), CFrame.new(-0.3, 1.4, -0.66)); add(Vector3.new(0.2, 0.2, 0.1), C(30, 30, 60), CFrame.new(0.3, 1.4, -0.66))
		add(Vector3.new(0.3, 0.3, 1.4), hair, CFrame.new(0, -0.4, 0.9))
		addL(Vector3.new(0.45, 1.3, 0.45), skin, CFrame.new(-0.9, 0.65, 0), Vector3.new(-0.9, 1.3, 0), 1)
		addL(Vector3.new(0.45, 1.3, 0.45), skin, CFrame.new(0.9, 0.65, 0), Vector3.new(0.9, 1.3, 0), -1)
		addL(Vector3.new(0.5, 1.4, 0.5), skin, CFrame.new(-0.35, -1.55, 0), Vector3.new(-0.35, -0.85, 0), -1)
		addL(Vector3.new(0.5, 1.4, 0.5), skin, CFrame.new(0.35, -1.55, 0), Vector3.new(0.35, -0.85, 0), 1)
		pet = {parts = parts, kind = kind, bob = 0, hh = 4.6}
		return
	end
	add(Vector3.new(1.2, 1, 2), col, CFrame.new(0, 0, 0))
	add(Vector3.new(1.1, 1.1, 1.1), col, CFrame.new(0, 0.6, -1.2))
	add(Vector3.new(0.3, eh, 0.3), col, CFrame.new(-0.4, 1.15 + eh / 2, -1.2)); add(Vector3.new(0.3, eh, 0.3), col, CFrame.new(0.4, 1.15 + eh / 2, -1.2))
	add(Vector3.new(0.2, 0.2, 0.2), C(20, 20, 20), CFrame.new(-0.25, 0.75, -1.78)); add(Vector3.new(0.2, 0.2, 0.2), C(20, 20, 20), CFrame.new(0.25, 0.75, -1.78))
	add(Vector3.new(0.3, 0.3, 1), col, CFrame.new(0, 0.4, 1.4))
	for _, o in ipairs({Vector3.new(-0.4, -0.7, -0.7), Vector3.new(0.4, -0.7, -0.7), Vector3.new(-0.4, -0.7, 0.7), Vector3.new(0.4, -0.7, 0.7)}) do
		add(Vector3.new(0.35, 0.5, 0.35), col:Lerp(C(0, 0, 0), 0.15), CFrame.new(o))
	end
	if kind == "duck" then add(Vector3.new(0.5, 0.2, 0.4), C(255, 140, 0), CFrame.new(0, 0.5, -1.9)) end
	if kind == "panda" then add(Vector3.new(0.5, 0.5, 0.2), C(20, 20, 20), CFrame.new(-0.3, 0.8, -1.7)); add(Vector3.new(0.5, 0.5, 0.2), C(20, 20, 20), CFrame.new(0.3, 0.8, -1.7)) end
	pet = {parts = parts, kind = kind, bob = 0}
end
function M.petReset(r) if pet then pet.cf = r.CFrame * CFrame.new(2.6, 0, 3.4) end end
function M.setPet(kind) S.petActive = kind or ""; build(S.petActive); isDirty = true end
local ps = keep(new("Sound", {Name = "LauncherPetSound", Volume = 0.5}, SoundService))
function M.petSound()
	if not S.sound then return end
	local id = S.petSoundId
	ps.SoundId = id ~= "" and ("rbxassetid://" .. id) or "rbxasset://sounds/electronicpingshort.wav"
	ps.PlaybackSpeed = id ~= "" and 1 or ((PETS[S.petActive] or {})[4] or 1)
	ps:Play()
end
local gp = RaycastParams.new(); gp.FilterType = Enum.RaycastFilterType.Exclude
conn(RS.RenderStepped, function(dt)
	if not pet then return end
	local r = root()
	if not r then return end
	local hungry = S.petHunger <= 0
	local want = (S.petStay and M.petStayPos) or (r.CFrame * CFrame.new(2.6, 0, 3.4)).Position
	gp.FilterDescendantsInstances = {lp.Character, folder}
	local hit = workspace:Raycast(want + Vector3.new(0, 8, 0), Vector3.new(0, -60, 0), gp)
	local half = pet.hh and pet.hh / 2 or 1.1
	local gy = hit and (hit.Position.Y + half) or (r.Position.Y - 2.5 + half)
	local target = Vector3.new(want.X, gy, want.Z)
	if not pet.cf then pet.cf = CFrame.new(target) end
	local cur = pet.cf.Position
	local d = (Vector3.new(cur.X, 0, cur.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude
	if d > 70 then cur = target; d = 0 end
	local moving = d > 1.2 and not hungry
	local nx = moving and cur:Lerp(target, math.min(1, dt * (d > 12 and 8 or 3))) or cur
	local ny = cur.Y + (gy - cur.Y) * math.min(1, dt * 10)
	local pos = Vector3.new(nx.X, ny, nx.Z)
	local look = moving and Vector3.new(target.X, pos.Y, target.Z) or Vector3.new(r.Position.X, pos.Y, r.Position.Z)
	if (look - pos).Magnitude > 0.05 then pet.cf = CFrame.lookAt(pos, look) else pet.cf = CFrame.new(pos) * (pet.cf - pet.cf.Position) end
	pet.bob += dt * (moving and 12 or 2)
	local y = pet.hh and 0 or (math.abs(math.sin(pet.bob)) * (moving and 0.4 or 0.04) - (hungry and 0.3 or 0))
	local sw = moving and math.sin(pet.bob) * 0.7 or 0
	for _, p in ipairs(pet.parts) do
		if p[3] then p[1].CFrame = pet.cf * CFrame.new(p[3]) * CFrame.Angles(sw * p[4], 0, 0) * CFrame.new(-p[3]) * p[2]
		else p[1].CFrame = pet.cf * CFrame.new(0, y, 0) * p[2] end
	end
end)
task.spawn(function()
	local warned = false
	while alive do
		task.wait(60)
		if pet then
			S.petHunger = math.max(0, S.petHunger - 2); isDirty = true
			if S.petHunger <= 0 and not warned then warned = true; M.notify("🐾 Питомец голоден и перестал ходить за тобой! Покорми его в «Питомцах».", 6) end
			if S.petHunger > 20 then warned = false end
		end
	end
end)
task.spawn(function()
	while alive do
		task.wait(math.random(40, 90))
		if pet and S.petHunger > 0 then M.petSound() end
	end
end)
task.defer(function() if S.petActive ~= "" then build(S.petActive) end end)

function M.zooUI(c, redraw)
	head(c, "🐾 Зоо-магазин и техника")
	label(c, "Питомцы ходят за тобой (видишь только ты). Звук — стандартный писк с разной высотой: настоящие «мяу/гав» требуют ID аудио Roblox, его можно вписать в «Питомцах».", 12, "sub", nil, UDim2.new(1, 0, 0, 44))
	for _, k in ipairs(PORDER) do
		local p = PETS[k]
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
		label(fr, p[1] .. (S.petOwned[k] and "" or ("   🪙 " .. p[2])), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.6, 0, 1, 0), true)
		local b = button(fr, S.petOwned[k] and "Есть" or "Купить", function()
			if S.petOwned[k] then return end
			if (S.coins or 0) >= p[2] then S.coins -= p[2]; S.petOwned[k] = true; M.setPet(k); toast("Куплено: " .. p[1], 2.5) else toast("Не хватает монет", 2.5) end
			redraw()
		end, UDim2.new(0.3, 0, 0, 32), S.petOwned[k]); b.Position = UDim2.new(0.68, 0, 0.5, -16)
	end
	local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
	label(fr, "🐟 Корм (+30 сытости)  🪙 20   · есть: " .. S.petFood, 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.6, 0, 1, 0), true)
	local fb = button(fr, "Купить", function()
		if (S.coins or 0) >= 20 then S.coins -= 20; S.petFood += 1; isDirty = true else toast("Не хватает монет", 2.5) end
		redraw()
	end, UDim2.new(0.3, 0, 0, 32)); fb.Position = UDim2.new(0.68, 0, 0.5, -16)
	local fr2 = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
	label(fr2, "📱 Телефон  " .. (S.owned.phone and "" or "🪙 1"), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.6, 0, 1, 0), true)
	local pb = button(fr2, S.owned.phone and "Есть" or "Купить", function()
		if S.owned.phone then return end
		if (S.coins or 0) >= 1 then S.coins -= 1; S.owned.phone = true; isDirty = true; toast("📱 Телефон куплен: приложение «Телефон»", 3) else toast("Не хватает монет", 2.5) end
		redraw()
	end, UDim2.new(0.3, 0, 0, 32), S.owned.phone); pb.Position = UDim2.new(0.68, 0, 0.5, -16)
end

RUN.pets = function(c)
	local function draw()
		reset(c)
		label(c, "🐾 Питомцы   ·   🪙 " .. (S.coins or 0) .. "   ·   🐟 корма: " .. S.petFood, 17, "text", nil, UDim2.new(1, 0, 0, 26), true)
		local bar = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 12), "card2", 6)
		frame(bar, UDim2.new(), UDim2.new(math.clamp(S.petHunger / 100, 0, 1), 0, 1, 0), "acc", 6)
		label(c, "Сытость: " .. math.floor(S.petHunger) .. "% " .. (S.petHunger <= 0 and "— голоден, не ходит за тобой" or ""), 13, "sub", nil, UDim2.new(1, 0, 0, 20))
		row(c, {{"🐟 Покормить", function()
			if S.petActive == "" then toast("Сначала выбери питомца", 2); return end
			if S.petFood > 0 then S.petFood -= 1; S.petHunger = math.min(100, S.petHunger + 30); isDirty = true; M.petSound() else toast("Нет корма: купи в магазине", 2.5) end
			draw()
		end}, {"🔊 Позвать", function() M.petSound() end, true}})
		row(c, {{S.petStay and "📍 Стоит здесь (нажми, чтобы вести за собой)" or "📍 Оставить питомца здесь", function()
			local r = root()
			if S.petStay then S.petStay = false elseif r and S.petActive ~= "" then S.petStay = true; M.petStayPos = r.Position + r.CFrame.LookVector * 3 end
			draw()
		end, not S.petStay}, {"🏃 Позвать к себе", function() S.petStay = false; local r = root(); if r and M.petReset then M.petReset(r) end end, true}})
		head(c, "Мои питомцы")
		local list = {}
		for _, k in ipairs(PORDER) do if S.petOwned[k] then list[#list + 1] = {PETS[k][1], function() M.setPet(S.petActive == k and "" or k); draw() end, S.petActive ~= k} end end
		if #list == 0 then label(c, "Пока нет питомцев. Загляни в «Магазин» → Зоо-магазин.", 13, "sub", nil, UDim2.new(1, 0, 0, 20)) else chunk(c, list, 3) end
		head(c, "Свой звук (ID аудио Roblox, необязательно)")
		local sb = textbox(c, "ID аудио, например мяуканье", S.petSoundId, 36)
		sb.FocusLost:Connect(function() S.petSoundId = (sb.Text:gsub("%D", "")); isDirty = true end)
	end
	draw()
end

RUN.phone = function(c)
	if not S.owned.phone then label(c, "📵 Телефона нет. Купи его в «Магазине» (раздел Зоо-магазин и техника), 🪙 1.", 15, "text", nil, UDim2.new(1, 0, 0, 50), true); return end
	local tab, disp, acc, op, fresh = M.phoneTab or "home", "0", nil, nil, true
	local function draw()
		reset(c)
		row(c, {{"🏠", function() M.phoneTab = "home"; tab = "home"; draw() end, tab ~= "home"}, {"🔔", function() M.phoneTab = "notif"; tab = "notif"; draw() end, tab ~= "notif"},
			{"🧮", function() M.phoneTab = "calc"; tab = "calc"; draw() end, tab ~= "calc"}})
		if tab == "home" then
			label(c, "📱 " .. os.date("%H:%M") .. "   " .. os.date("%d.%m.%Y"), 24, "text", nil, UDim2.new(1, 0, 0, 36), true)
			label(c, "Уведомлений: " .. #M.notifs, 14, "sub", nil, UDim2.new(1, 0, 0, 22))
			row(c, {{"🤝 Друзья", function() M.openApp({id = "friends", n = "Друзья", i = "🤝"}) end, true}, {"👾 Скриптеры", function() M.openApp({id = "scripters", n = "Скриптеры", i = "👾"}) end, true},
				{"🎵 Музыка", function() M.openApp({id = "music", n = "Музыка", i = "🎵"}) end, true}})
			row(c, {{"🌐 Браузер", function() M.openApp({id = "browser", n = "Браузер", i = "🌐"}) end, true}, {"🐾 Питомцы", function() M.openApp({id = "pets", n = "Питомцы", i = "🐾"}) end, true}})
		elseif tab == "notif" then
			row(c, {{"Очистить", function() M.notifs = {}; draw() end, true}})
			if #M.notifs == 0 then label(c, "Нет уведомлений", 14, "sub", nil, UDim2.new(1, 0, 0, 22)) end
			for _, n in ipairs(M.notifs) do label(c, os.date("%H:%M", n.ts) .. "  " .. n.t, 14, "text", nil, UDim2.new(1, 0, 0, 38)) end
		else
			local lbl = label(c, disp, 36, "text", nil, UDim2.new(1, 0, 0, 52), true, Enum.TextXAlignment.Right)
			local function press(k)
				if k:match("%d") or k == "." then
					if fresh then disp = k; fresh = false else disp = (disp == "0" and k ~= ".") and k or (disp .. k) end
				elseif k == "C" then disp, acc, op, fresh = "0", nil, nil, true
				else
					local v = tonumber(disp) or 0
					if acc and op and not fresh then
						if op == "+" then acc += v elseif op == "−" then acc -= v elseif op == "×" then acc *= v elseif op == "÷" then acc = v ~= 0 and acc / v or 0 end
					else acc = v end
					if k == "=" then op = nil else op = k end
					disp = tostring(math.floor(acc * 1e6 + 0.5) / 1e6); fresh = true
				end
				lbl.Text = disp
			end
			for _, rw in ipairs({{"7", "8", "9", "÷"}, {"4", "5", "6", "×"}, {"1", "2", "3", "−"}, {"C", "0", ".", "+"}, {"="}}) do
				local d = {}
				for _, k in ipairs(rw) do d[#d + 1] = {k, function() press(k) end, k:match("%d") ~= nil} end
				row(c, d)
			end
		end
	end
	draw()
end
end -- конец питомцев и телефона

---------------------------------------------------------------- КАРТОЧКИ ПРОФИЛЯ, КАСТОМИЗАЦИЯ, СКРИПТЕРЫ
do
S.profTitle = S.profTitle or ""; S.profBio = S.profBio or ""; S.profBanner = S.profBanner or 0; S.nameStyle = S.nameStyle or "none"
S.avShape = S.avShape or "circle"; S.frameThick = S.frameThick or 4; S.frameColor = S.frameColor or -2
local anim = {}
task.spawn(function()
	while alive do
		local t = os.clock()
		for i = #anim, 1, -1 do
			local a = anim[i]
			if not a.l.Parent then table.remove(anim, i)
			elseif a.s == "rainbow" then a.l.TextColor3 = Color3.fromHSV((t * 0.3) % 1, 0.7, 1)
			elseif a.s == "pulse" then a.l.TextTransparency = 0.45 * (0.5 + 0.5 * math.sin(t * 4))
			elseif a.s == "glitch" then a.l.TextColor3 = math.random() < 0.15 and C(255, 60, 120) or (math.random() < 0.1 and C(60, 255, 255) or col("text")) end
		end
		task.wait(0.05)
	end
end)
local RAD = {circle = 0.5, round = 0.2, square = 0.04}
function M.profileCard(par, d)
	local top = new("Frame", {Size = UDim2.new(1, 0, 0, 172), BorderSizePixel = 0}, par)
	bind(top, "BackgroundColor3", "card"); round(top, 16)
	local ban = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BorderSizePixel = 0, BackgroundColor3 = pcolor(d.banner or 0)}, top)
	round(ban, 16)
	local av = new("ImageLabel", {Position = UDim2.fromOffset(16, 28), Size = UDim2.fromOffset(88, 88), BorderSizePixel = 0}, top)
	bind(av, "BackgroundColor3", "card2")
	new("UICorner", {CornerRadius = UDim.new(RAD[d.avShape or "circle"] or 0.5, 0)}, av)
	local colors = d.colors or {}
	local function rgb(t) return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255) end
	local function unbind(o) for i = #reg, 1, -1 do if reg[i][1] == o then table.remove(reg, i) end end end
	if colors.banner then ban.BackgroundColor3 = rgb(colors.banner) end
	if colors.card then unbind(top); top.BackgroundColor3 = rgb(colors.card) end
	local fcol = colors.frame and rgb(colors.frame) or ((d.frameColor or -2) ~= -2 and pcolor(d.frameColor) or ACCENTS[S.acc])
	if (d.frame or "ring") ~= "none" then new("UIStroke", {Thickness = d.frameThick or 4, Color = fcol, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, av) end
	task.spawn(function()
		local img
		if d.avatarUrl and d.avatarUrl ~= "" then img = fetchAsset(d.avatarUrl) end
		if not img and d.userId then
			local ok, i = pcall(function() return Players:GetUserThumbnailAsync(d.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
			if ok then img = i end
		end
		if img and av.Parent then av.Image = img end
	end)
	local r = d.role and M.ROLE[d.role]
	local nm = label(top, ((d.badge or "") ~= "" and (d.badge .. " ") or "") .. tostring(d.name) .. (r and ("  " .. r[1]) or "") .. ((d.rank or "") ~= "" and ("  [" .. d.rank .. "]") or ""),
		19, "text", UDim2.new(0, 116, 0, 62), UDim2.new(1, -126, 0, 26), true)
	if colors.name then unbind(nm); nm.TextColor3 = rgb(colors.name) end
	if (d.nameStyle or "none") ~= "none" then anim[#anim + 1] = {l = nm, s = d.nameStyle} end
	if (d.title or "") ~= "" then label(top, d.title, 13, "sub", UDim2.new(0, 116, 0, 88), UDim2.new(1, -126, 0, 18), true) end
	local info = {"Уровень " .. tostring(d.level or 1)}
	if (d.game or "") ~= "" then info[#info + 1] = "🎮 " .. d.game end
	if (d.exec or "") ~= "" then info[#info + 1] = "💉 " .. d.exec end
	if (d.status or "") ~= "" then info[#info + 1] = "💬 " .. d.status end
	label(top, table.concat(info, "  ·  "), 12, "sub", UDim2.new(0, 116, 0, 106), UDim2.new(1, -126, 0, 30))
	if (d.bio or "") ~= "" then local bl = label(top, d.bio:sub(1, 140), 12, "text", UDim2.new(0, 16, 0, 124), UDim2.new(1, -32, 0, 44)); if colors.bio then unbind(bl); bl.TextColor3 = rgb(colors.bio) end end
	return top
end
function M.myCard()
	return {name = lp.DisplayName, userId = lp.UserId, title = S.profTitle, bio = S.profBio, banner = S.profBanner, nameStyle = S.nameStyle, avShape = S.avShape,
		frame = S.frame, frameThick = S.frameThick, frameColor = S.frameColor, level = M.level(), role = M.roleFor(lp), rank = S.rankName, badge = S.badge,
		exec = execName, game = S.showGame and "" or "", status = S.status, avatarUrl = S.avatarUrl, colors = S.profColors}
end

RUN.pcust = function(c)
	local function draw()
		reset(c)
		label(c, "🎨 Кастомизация профиля", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		M.profileCard(c, M.myCard())
		head(c, "Титул под ником")
		local tt = textbox(c, "например: Король фермы", S.profTitle, 36)
		tt.FocusLost:Connect(function() S.profTitle = tt.Text:sub(1, 30); isDirty = true; draw() end)
		head(c, "О себе")
		local bt = textbox(c, "пара слов о себе (до 140 символов)", S.profBio, 74, true)
		bt.FocusLost:Connect(function() S.profBio = bt.Text:sub(1, 140); isDirty = true; draw() end)
		head(c, "Цвет баннера")
		swatches(c, function() return S.profBanner end, function(v) S.profBanner = v end, draw)
		head(c, "Стиль ника")
		row(c, {opt("Обычный", "nameStyle", "none", draw), opt("Радуга", "nameStyle", "rainbow", draw), opt("Пульс", "nameStyle", "pulse", draw), opt("Глитч", "nameStyle", "glitch", draw)})
		head(c, "Форма аватара")
		row(c, {opt("Круг", "avShape", "circle", draw), opt("Скруглённый", "avShape", "round", draw), opt("Квадрат", "avShape", "square", draw)})
		head(c, "Рамка")
		local fr = {}
		for _, f in ipairs({{"none", "Нет"}, {"ring", "Кольцо"}, {"rainbow", "Радуга"}, {"neon", "Неон"}, {"gold", "Золото"}, {"fire", "Огонь"}, {"pulse", "Пульс"}}) do
			fr[#fr + 1] = {f[2], function() if f[1] == "ring" or f[1] == "none" or S.owned["frame:" .. f[1]] then S.frame = f[1]; isDirty = true; draw() else toast("Эта рамка продаётся в магазине", 2.5) end end, S.frame ~= f[1]}
		end
		chunk(c, fr, 4)
		stepFn(c, "Толщина рамки", function() return S.frameThick end, function(v) S.frameThick = v end, 1, 0, 14, nil, draw)
		label(c, "Цвет рамки", 14, "text", nil, UDim2.new(1, 0, 0, 20), true)
		row(c, {{"По стилю рамки", function() S.frameColor = -2; draw() end, S.frameColor ~= -2}})
		swatches(c, function() return S.frameColor end, function(v) S.frameColor = v end, draw)
		label(c, "Ещё больше: рамки, значки, цвет ника и фон — в «Магазине». Карточку видят другие пользователи скрипта через сервер.", 12, "sub", nil, UDim2.new(1, 0, 0, 34))
	end
	draw()
end

RUN.scripters = function(c)
	local me = c
	local card
	local function allUsers()
		local seen, list = {}, {}
		for _, u in ipairs(M.NET.online) do if not seen[u.uid] then seen[u.uid] = true; list[#list + 1] = u end end
		for _, u in ipairs(M.NET.friends) do if not seen[u.uid] then seen[u.uid] = true; list[#list + 1] = u end end
		for _, u in ipairs(M.NET.all or {}) do if not seen[u.uid] and u.uid ~= lp.UserId then seen[u.uid] = true; list[#list + 1] = u end end
		return list
	end
	local function cardOf(u)
		return {name = u.display or u.name, userId = u.uid, title = u.title, bio = u.bio, banner = u.banner, nameStyle = u.nameStyle, avShape = u.avShape, frame = u.frame,
			frameThick = u.frameThick, frameColor = u.frameColor, colors = u.colors, level = u.level, role = u.role, rank = u.rank, badge = u.badge, exec = u.exec, game = u.game, status = u.status}
	end
	local function draw()
		reset(c)
		if card then
			row(c, {{"‹ К таблице", function() card = nil; draw() end, true}})
			M.profileCard(c, cardOf(card))
			local isF = M.NET.friendSet[card.uid]
			row(c, {{isF and "✓ В друзьях" or "➕ Пригласить в друзья", function() if not isF then M.NET.friendAction(card.uid, "request"); M.notify("Приглашение отправлено: " .. tostring(card.display or card.name), 3) end end, isF},
				{(S.follows and S.follows[tostring(card.uid)]) and "🔔 Подписан" or "🔔 Подписаться", function()
					S.follows = S.follows or {}
					local k = tostring(card.uid)
					if S.follows[k] then S.follows[k] = nil else S.follows[k] = tostring(card.display or card.name) end
					isDirty = true; draw()
				end, not (S.follows and S.follows[tostring(card.uid)])},
				{"🚪 Зайти к нему", function() if card.place and card.job and card.job ~= "" then pcall(function() TeleportService:TeleportToPlaceInstance(card.place, card.job, lp) end) end end, true}})
			row(c, {{"🎨 Скопировать дизайн", function()
				for k, v in pairs(card.design or {}) do if type(v) == "table" or type(S[k]) == type(v) or S[k] == nil then S[k] = v end end
				applyAll(); M.VFX.all(); toast("Дизайн применён", 2.5)
			end, true}})
			return
		end
		label(c, M.NET.ok and ("✅ Сервер подключён. Пользователей скрипта сейчас: " .. #M.NET.online + 1) or "⚠ Сервер не подключён: таблица пуста. Адрес сервера — «Настройки → Конфиг и сеть».", 14, "text", nil, UDim2.new(1, 0, 0, 40), true)
		row(c, {{"🔄 Обновить", function() task.spawn(M.refreshOnline) end, true}})
		local hdr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 24), "card", 8)
		label(hdr, "Игрок", 12, "sub", UDim2.new(0, 10, 0, 3), UDim2.new(0.32, 0, 0, 18), true); label(hdr, "Lv", 12, "sub", UDim2.new(0.34, 0, 0, 3), UDim2.new(0.08, 0, 0, 18), true)
		label(hdr, "Игра", 12, "sub", UDim2.new(0.43, 0, 0, 3), UDim2.new(0.3, 0, 0, 18), true); label(hdr, "Инжектор", 12, "sub", UDim2.new(0.74, 0, 0, 3), UDim2.new(0.25, 0, 0, 18), true)
		for _, u in ipairs(allUsers()) do
			local r = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 40), "card2", 10)
			label(r, (M.NET.friendSet[u.uid] and "🤝 " or "") .. tostring(u.display or u.name), 13, "text", UDim2.new(0, 10, 0, 0), UDim2.new(0.32, 0, 1, 0), true)
			label(r, tostring(u.level or 1), 13, "text", UDim2.new(0.34, 0, 0, 0), UDim2.new(0.08, 0, 1, 0))
			local ago = u.ago or 0
			local when = (u.online ~= false and ago < 60) and (tostring(u.game or "") ~= "" and tostring(u.game) or "в сети") or (ago < 3600 and ("был(а) " .. math.floor(ago / 60) .. " мин назад") or (ago < 86400 and ("был(а) " .. math.floor(ago / 3600) .. " ч назад") or ("был(а) " .. math.floor(ago / 86400) .. " дн назад")))
			label(r, when, 12, "sub", UDim2.new(0.43, 0, 0, 0), UDim2.new(0.3, 0, 1, 0))
			label(r, tostring(u.exec or ""), 12, "sub", UDim2.new(0.74, 0, 0, 0), UDim2.new(0.25, 0, 1, 0))
			local btn = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, r)
			tap(btn, function() card = u; draw() end)
		end
	end
	draw()
	task.spawn(function()
		while content == me and alive do
			if M.NET.dirty and not card then M.NET.dirty = false; draw() end
			task.wait(0.8)
		end
	end)
end
end -- конец карточек и скриптеров

---------------------------------------------------------------- ЧУЖИЕ ЭФФЕКТЫ (только у пользователей скрипта в твоём сервере, через сервер) + СЛЕДЫ
do
local applied = {}
local SM = "rbxasset://textures/particles/smoke_main.dds"
local function clearOn(char) if char then for _, o in ipairs(char:GetDescendants()) do if o.Name:sub(1, 12) == "LauncherFxO_" then o:Destroy() end end end end
local function applyTo(char, A, accIdx)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	clearOn(char)
	local acc = ACCENTS[tonumber(accIdx) or 1] or ACCENTS[1]
	if A.fire then new("Fire", {Name = "LauncherFxO_1", Size = 7, Heat = 9, Color = acc, SecondaryColor = Color3.new(1, 1, 1)}, hrp) end
	if A.smoke then new("ParticleEmitter", {Name = "LauncherFxO_2", Texture = SM, Rate = 14, Lifetime = NR(2, 3.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top, Size = NS({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5)}), Color = ColorSequence.new(acc:Lerp(Color3.new(1, 1, 1), 0.4), C(70, 70, 85)),
		Transparency = NS({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1)})}, hrp) end
	if A.toxic then new("ParticleEmitter", {Name = "LauncherFxO_3", Texture = SM, Rate = 16, Lifetime = NR(2, 3), Speed = NR(2, 4), EmissionDirection = Enum.NormalId.Top, LightEmission = 0.6,
		Size = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)}), Color = ColorSequence.new(C(120, 255, 90), C(40, 120, 30)),
		Transparency = NS({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)})}, hrp) end
	if A.ice then new("ParticleEmitter", {Name = "LauncherFxO_4", Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 22, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3),
		SpreadAngle = Vector2.new(180, 180), Size = NS({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}), LightEmission = 1, Color = ColorSequence.new(C(190, 235, 255), C(90, 170, 255))}, hrp) end
	if A.sparkles then new("Sparkles", {Name = "LauncherFxO_5", SparkleColor = acc}, hrp) end
	if A.orbs then new("ParticleEmitter", {Name = "LauncherFxO_6", Rate = 20, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NS(0.4), LightEmission = 1,
		Color = ColorSequence.new(acc), Transparency = NS({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})}, hrp) end
end
task.spawn(function()
	while alive do
		task.wait(2)
		local seen = {}
		for _, u in ipairs(M.NET.online) do
			local p = u.job == game.JobId and u.job ~= "" and Players:GetPlayerByUserId(u.uid)
			if p and p ~= lp and p.Character and u.design and S.showOthersFx ~= false then
				seen[p.UserId] = true
				local A = u.design.auras or {}
				local key = HS:JSONEncode(A) .. tostring(u.design.acc) .. tostring(p.Character)
				if applied[p.UserId] ~= key then applied[p.UserId] = key; pcall(applyTo, p.Character, A, u.design.acc) end
			end
		end
		for uid in pairs(applied) do
			if not seen[uid] then
				applied[uid] = nil
				local p = Players:GetPlayerByUserId(uid)
				if p then clearOn(p.Character) end
			end
		end
	end
end)
M.cleanup[#M.cleanup + 1] = function() for _, p in ipairs(Players:GetPlayers()) do clearOn(p.Character) end end

-- следы за персонажем: лента, следы ног, искры
S.trails = S.trails or {}
local feet = keep(new("Folder", {Name = "LauncherFeet"}, workspace))
local lastFoot = 0
task.spawn(function()
	while alive do
		task.wait(1)
		local r = root()
		if r then
			local rb = r:FindFirstChild("LauncherFxTrailR")
			if S.trails.ribbon and not rb then
				local a0 = r:FindFirstChild("LauncherFxA0r") or new("Attachment", {Name = "LauncherFxA0r", Position = Vector3.new(0, 1.2, 0)}, r)
				local a1 = r:FindFirstChild("LauncherFxA1r") or new("Attachment", {Name = "LauncherFxA1r", Position = Vector3.new(0, -1.2, 0)}, r)
				new("Trail", {Name = "LauncherFxTrailR", Attachment0 = a0, Attachment1 = a1, Lifetime = 1.2, LightEmission = 1, Color = ColorSequence.new(ACCENTS[S.acc], ACCENTS[S.acc]:Lerp(Color3.new(1, 1, 1), 0.5)),
					Transparency = NS({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, r)
			elseif not S.trails.ribbon and rb then rb:Destroy() end
			local sp = r:FindFirstChild("LauncherFxSparks")
			if S.trails.sparks and not sp then
				new("ParticleEmitter", {Name = "LauncherFxSparks", Rate = 0, Lifetime = NR(0.5, 1), Speed = NR(2, 6), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Bottom,
					Size = NS({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}), LightEmission = 1, Color = ColorSequence.new(ACCENTS[S.acc], C(255, 255, 255)), Acceleration = Vector3.new(0, -8, 0)}, r)
			elseif not S.trails.sparks and sp then sp:Destroy() end
		end
	end
end)
conn(RS.Heartbeat, function()
	local r, h = root(), hum()
	if not (r and h) then return end
	local moving = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude > 4
	local sp = r:FindFirstChild("LauncherFxSparks")
	if sp then sp.Rate = (S.trails.sparks and moving) and 40 or 0 end
	if S.trails.feet and moving and h.FloorMaterial ~= Enum.Material.Air and os.clock() - lastFoot > 0.3 then
		lastFoot = os.clock()
		local side = (math.floor(os.clock() / 0.3) % 2 == 0) and 0.6 or -0.6
		local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = ACCENTS[S.acc], Transparency = 0.3,
			Size = Vector3.new(0.9, 0.08, 1.3), CFrame = (r.CFrame * CFrame.new(side, -(h.HipHeight + r.Size.Y / 2) + 0.06, 0)) * CFrame.Angles(0, 0, 0)}, feet)
		TS:Create(p, TweenInfo.new(2), {Transparency = 1}):Play()
		task.delay(2.1, function() pcall(function() p:Destroy() end) end)
	end
end)

---------------------------------------------------------------- СЕРВЕРЫ ROBLOX (список, смена) + КОНФИГ + СЕТЬ
function M.serverExtra(c, redraw)
	head(c, "Информация о сервере")
	local up = math.floor(workspace.DistributedGameTime)
	local n = 1
	for _, p in ipairs(Players:GetPlayers()) do if p ~= lp and M.tagOf and M.tagOf(p) then n += 1 end end
	label(c, "Игра: " .. tostring(M.gameName or game.PlaceId) .. "\nИгроков: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers .. "   ·   Мой пинг: " .. getPing() .. " мс" ..
		"\nСервер работает: " .. string.format("%d:%02d:%02d", up // 3600, up // 60 % 60, up % 60) .. "   ·   Со скриптом тут: " .. n, 13, "text", nil, UDim2.new(1, 0, 0, 62))
	label(c, "Пинг и «читерство» других игроков скрипт определить не может: Roblox не отдаёт клиенту эти данные.", 11, "sub", nil, UDim2.new(1, 0, 0, 28))
	head(c, "Другие серверы этой игры")
	row(c, {{"📋 Показать серверы", function()
		task.spawn(function()
			local rq = request or http_request or (syn and syn.request)
			M.srvList, M.srvErr = nil, nil
			if not rq then M.srvErr = "в инжекторе нет request"
			else
				local ok, res = pcall(rq, {Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25", Method = "GET"})
				if ok and res and res.StatusCode == 200 then
					local ok2, d = pcall(HS.JSONDecode, HS, res.Body)
					M.srvList = ok2 and d.data or nil
				else M.srvErr = "Roblox не ответил (" .. tostring(ok and res and res.StatusCode or "ошибка") .. ")" end
			end
			redraw()
		end)
	end, true}, {"🎯 Самый пустой", function()
		if M.srvList then
			for _, sv in ipairs(M.srvList) do if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, lp) end); return end end
		else toast("Сначала нажми «Показать серверы»", 2.5) end
	end, true}})
	row(c, {{setclipboard and "🔗 Ссылка на этот сервер" or "🔗 Копирование недоступно", function()
		if setclipboard then pcall(setclipboard, "roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId); toast("Ссылка скопирована", 2) end
	end, true}})
	if M.srvErr then label(c, "⚠ " .. M.srvErr, 13, "text", nil, UDim2.new(1, 0, 0, 22)) end
	for i, sv in ipairs(M.srvList or {}) do
		if i > 15 then break end
		row(c, {{(sv.id == game.JobId and "● этот  " or "") .. sv.playing .. "/" .. sv.maxPlayers .. "  пинг " .. tostring(sv.ping or "?") .. "  fps " .. tostring(math.floor(sv.fps or 0)),
			function() if sv.id ~= game.JobId then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, lp) end) end end, sv.id ~= game.JobId}})
	end
end

local BLACK = {coins = 1, xp = 1, playMin = 1, owned = 1, lastDaily = 1, chatUrl = 1, avatarUrl = 1, status = 1, adminGranted = 1, grantedRole = 1, rankName = 1,
	petOwned = 1, petFood = 1, petHunger = 1, petActive = 1, petSoundId = 1, deviceDone = 1, migrated = 1, claudeSecret = 1, execOverride = 1}
local function exportCfg()
	local t = clean(S)
	for k in pairs(BLACK) do t[k] = nil end
	return HS:JSONEncode(t)
end
local function importCfg(json)
	local ok, d = pcall(HS.JSONDecode, HS, json)
	if not ok or type(d) ~= "table" then return false end
	for k in pairs(BLACK) do d[k] = nil end
	merge(S, d)
	return true
end
function M.drawCfg(c, redraw)
	head(c, "Инжектор (если определился неверно — впиши вручную)")
	label(c, "Сейчас определён: " .. execName, 13, "sub", nil, UDim2.new(1, 0, 0, 20))
	local eb = textbox(c, "например: Xeno, Delta, Wave, Arceus X", S.execOverride or "", 36)
	eb.FocusLost:Connect(function() S.execOverride = eb.Text; isDirty = true; toast("Имя инжектора применится после перезапуска скрипта", 3) end)
	head(c, "Сервер скрипта (для таблицы скриптеров, друзей, выдач, чужих эффектов)")
	local sb = textbox(c, "http://…  (задай один раз, дальше сохраняется)", S.chatUrl, 36)
	sb.FocusLost:Connect(function() S.chatUrl = sb.Text; isDirty = true end)
	label(c, (M.NET.ok and "✅ Подключён · роль: " .. M.NET.role or "⚠ Нет связи или адрес не задан") .. (DEFAULT_SERVER ~= "" and "   (есть адрес по умолчанию в скрипте)" or ""), 12, "sub", nil, UDim2.new(1, 0, 0, 20))
	row(c, {tog("Показывать чужие эффекты", "showOthersFx", redraw), tog("Уведомления", "notifOn", redraw)})
	head(c, "Конфиг: экспорт и импорт кодом")
	local ct = textbox(c, "код конфига (появится после экспорта; сюда вставляй чужой)", M.cfgCode or "", 60, true)
	row(c, {{"📤 Экспорт кода", function()
		M.cfgCode = b64e(exportCfg())
		if setclipboard then pcall(setclipboard, M.cfgCode) end
		toast(setclipboard and "Код скопирован в буфер" or "Код показан в поле", 2.5); redraw()
	end}, {"📥 Импорт кода", function()
		local ok = importCfg(b64d(ct.Text))
		if ok then applyAll(); M.VFX.all(); toast("✅ Конфиг применён", 2.5); redraw() else toast("⚠ Код неверный", 2.5) end
	end, true}})
	local fn = textbox(c, "имя файла, например my_cfg", M.cfgName or "my_cfg", 36)
	fn:GetPropertyChangedSignal("Text"):Connect(function() M.cfgName = fn.Text end)
	row(c, {{"💾 Сохранить в файл", function()
		if writefile then pcall(writefile, "L3D_cfg_" .. (fn.Text:gsub("[^%w_%-]", "")) .. ".json", exportCfg()); toast("Сохранено в workspace/L3D_cfg_" .. fn.Text .. ".json", 3) else toast("Нет writefile", 2.5) end
	end, true}, {"📂 Загрузить из файла", function()
		local p = "L3D_cfg_" .. (fn.Text:gsub("[^%w_%-]", "")) .. ".json"
		if readfile and isfile and isfile(p) and importCfg(readfile(p)) then applyAll(); M.VFX.all(); toast("✅ Загружено", 2.5) else toast("⚠ Файл не найден", 2.5) end
	end, true}})
end
end -- конец следов, серверов и конфига
M.load(91, "Графика и виджеты…")

---------------------------------------------------------------- БИНДЫ (GUI), ГРАФИКА, НЕБО, ФОН МЕНЮ, ПАРТИКЛЫ
do
M.KEYDEF = {{"menu", "Меню"}, {"fly", "Полёт"}, {"noclip", "Ноуклип"}, {"esp", "ESP"}, {"hud", "HUD"}, {"fp", "1-е лицо"}, {"tpv", "3-е лицо"}, {"drone", "Дрон FPV"},
	{"tpto", "ТП к курсору"}, {"aclick", "Автоклик"}, {"noPart", "Без партиклов"}, {"photo", "Фото-режим"}, {"freecam", "Фри-камера"}, {"mini", "Мини-плеер"}}
M.DEFKEYS = {menu = "L", fly = "F", noclip = "N", esp = "K", hud = "H", fp = "V", tpv = "B", drone = "G", tpto = "T", aclick = "J", noPart = "P", photo = "O", freecam = "U", mini = "M"}
for k, v in pairs(M.DEFKEYS) do if S.keys[k] == nil then S.keys[k] = v end end

RUN.binds = function(c)
	local function draw()
		reset(c)
		label(c, "⌨️ Бинды", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		label(c, listeningKey and "Нажми нужную клавишу… (Esc — отмена, Backspace — снять бинд)" or "Нажми на плитку, потом на клавишу. Красная рамка — клавиша уже занята другим действием.", 13, "sub", nil, UDim2.new(1, 0, 0, 34))
		local used = {}
		for _, k in ipairs(M.KEYDEF) do local v = S.keys[k[1]]; if v and v ~= "" then used[v] = (used[v] or 0) + 1 end end
		for i = 1, #M.KEYDEF, 3 do
			local r = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 82)}, c)
			new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, r)
			for j = i, math.min(i + 2, #M.KEYDEF) do
				local k = M.KEYDEF[j]
				local active = listeningKey == k[1]
				local tile = new("TextButton", {Text = "", Size = UDim2.new(1 / 3, -6, 1, 0), BorderSizePixel = 0, AutoButtonColor = false}, r)
				bind(tile, "BackgroundColor3", active and "acc" or "card2"); round(tile, 12)
				label(tile, k[2], 13, active and "white" or "text", UDim2.new(0, 8, 0, 6), UDim2.new(1, -16, 0, 18), true)
				local v = S.keys[k[1]]
				local cap = new("TextLabel", {Text = active and "…" or ((v and v ~= "") and v or "—"), Size = UDim2.fromOffset(70, 34), Position = UDim2.new(0.5, -35, 1, -42), Font = Enum.Font.GothamBold,
					TextSize = 18, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C(28, 28, 34), BorderSizePixel = 0}, tile)
				round(cap, 8)
				new("UIStroke", {Thickness = 2, Color = (v and v ~= "" and (used[v] or 0) > 1) and C(255, 70, 70) or C(90, 90, 105)}, cap)
				tap(tile, function() listeningKey = k[1]; draw() end)
			end
		end
		row(c, {{"Сбросить все", function() S.keys = {}; for k, v in pairs(M.DEFKEYS) do S.keys[k] = v end; listeningKey = nil; isDirty = true; draw() end, true}})
	end
	M.redrawBinds = draw
	draw()
end

-- ---------- графика: гибкие настройки ----------
S.gfx = S.gfx or {}
local O = {B = Lighting.Brightness, E = Lighting.ExposureCompensation, A = Lighting.Ambient, OA = Lighting.OutdoorAmbient, T = Lighting.ClockTime, GS = Lighting.GlobalShadows}
local function fxo(class, name, props)
	local o = Lighting:FindFirstChild(name) or new(class, props, Lighting)
	o.Name = name
	return keep(o)
end
local gcc = fxo("ColorCorrectionEffect", "LauncherGfxCC", {})
local gblur = fxo("BlurEffect", "LauncherGfxBlur", {Size = 0})
local gbloom = fxo("BloomEffect", "LauncherGfxBloom", {Enabled = false, Intensity = 0, Size = 24, Threshold = 1})
local gatm = nil
local GFX = {
	{"bright", "Яркость мира", 0, 10, 0.25}, {"exposure", "Экспозиция", -3, 3, 0.25}, {"ambient", "Окружающий свет (0-255)", 0, 255, 10}, {"outdoor", "Свет снаружи (0-255)", 0, 255, 10},
	{"clock", "Время суток (ч)", 0, 24, 0.5}, {"sat", "Насыщенность", -1, 2, 0.1}, {"contrast", "Контраст", -1, 1, 0.1}, {"cbright", "Яркость картинки", -0.5, 0.5, 0.05},
	{"blur", "Размытие", 0, 40, 2}, {"bloom", "Свечение (блум)", 0, 3, 0.1}, {"haze", "Дымка (Atmosphere)", 0, 10, 0.5}, {"density", "Плотность атмосферы", 0, 1, 0.05},
}
local GDEF = {bright = O.B, exposure = O.E, ambient = 128, outdoor = 128, clock = O.T, sat = 0, contrast = 0, cbright = 0, blur = 0, bloom = 0, haze = 0, density = 0.3}
function M.applyGfx()
	local g = S.gfx
	if g.bright ~= nil then Lighting.Brightness = g.bright end
	if g.exposure ~= nil then Lighting.ExposureCompensation = g.exposure end
	if g.ambient ~= nil then local v = g.ambient; Lighting.Ambient = Color3.fromRGB(v, v, v) end
	if g.outdoor ~= nil then local v = g.outdoor; Lighting.OutdoorAmbient = Color3.fromRGB(v, v, v) end
	if g.clock ~= nil and S.cycle == 0 then Lighting.ClockTime = g.clock end
	gcc.Saturation = g.sat or 0; gcc.Contrast = g.contrast or 0; gcc.Brightness = g.cbright or 0
	gcc.TintColor = (g.tint and g.tint ~= 0) and pcolor(g.tint) or Color3.new(1, 1, 1)
	gblur.Size = g.blur or 0
	gbloom.Enabled = (g.bloom or 0) > 0; gbloom.Intensity = g.bloom or 0
	if (g.haze or 0) > 0 or g.density ~= nil then
		if not gatm then gatm = Lighting:FindFirstChildOfClass("Atmosphere") or keep(new("Atmosphere", {Name = "LauncherAtmosphere"}, Lighting)) end
		if g.haze ~= nil then gatm.Haze = g.haze end
		if g.density ~= nil then gatm.Density = g.density end
	end
end
local function gfxReset()
	S.gfx = {}
	Lighting.Brightness, Lighting.ExposureCompensation, Lighting.Ambient, Lighting.OutdoorAmbient = O.B, O.E, O.A, O.OA
	M.applyGfx()
end

-- ---------- небо (12 пресетов, без текстур: звёзды + атмосфера + свет) ----------
local SKIES = {
	{"none", "Обычное"}, {"space", "🌌 Космос"}, {"night", "🌙 Ночь"}, {"sunset", "🌇 Закат"}, {"hell", "🔥 Ад"}, {"neon", "💜 Неон"}, {"matrix", "🟩 Матрица"},
	{"dawn", "🌅 Рассвет"}, {"storm", "⛈ Шторм"}, {"ice", "❄ Лёд"}, {"toxic", "☣ Токсик"}, {"candy", "🍬 Конфетное"}, {"halloween", "🎃 Хэллоуин"},
}
local SKYD = {
	space = {0, 5000, nil, C(25, 25, 45)}, night = {0, 3000, {C(30, 40, 80), C(10, 10, 30), 0.3, 1}, C(40, 45, 70)},
	sunset = {18.2, 0, {C(255, 150, 90), C(200, 80, 60), 0.45, 2}, C(160, 110, 90)}, hell = {0, 0, {C(255, 60, 20), C(120, 10, 0), 0.5, 3}, C(120, 30, 20), C(255, 180, 160)},
	neon = {0, 1500, {C(255, 60, 220), C(60, 20, 140), 0.4, 2}, C(90, 40, 140), C(255, 200, 255)}, matrix = {0, 0, {C(20, 255, 90), C(0, 80, 20), 0.4, 2}, C(20, 90, 40), C(180, 255, 200)},
	dawn = {5.8, 0, {C(255, 190, 150), C(255, 140, 120), 0.35, 1.5}, C(150, 130, 130)}, storm = {14, 0, {C(90, 95, 110), C(60, 65, 80), 0.55, 4}, C(90, 95, 105)},
	ice = {12, 0, {C(180, 220, 255), C(140, 190, 240), 0.35, 2}, C(150, 180, 210), C(210, 230, 255)}, toxic = {0, 0, {C(140, 255, 60), C(60, 120, 0), 0.45, 3}, C(70, 110, 30)},
	candy = {14, 0, {C(255, 170, 220), C(255, 210, 240), 0.3, 1}, C(200, 150, 190)},
	halloween = {0, 2500, {C(255, 110, 20), C(90, 20, 110), 0.45, 3}, C(110, 50, 30), C(255, 200, 150)},
}
local oldSky, ourSky, ourAtm
function M.setSky(id)
	S.sky = id
	if ourSky then ourSky:Destroy(); ourSky = nil end
	if ourAtm then ourAtm:Destroy(); ourAtm = nil end
	if id == "none" or not SKYD[id] then
		if oldSky and not oldSky.Parent then oldSky.Parent = Lighting end
		Lighting.Ambient = O.A; Lighting.OutdoorAmbient = O.OA
		gcc.TintColor = Color3.new(1, 1, 1)
		M.applyGfx()
		return
	end
	local d = SKYD[id]
	local cur = Lighting:FindFirstChildOfClass("Sky")
	if cur and cur ~= ourSky then oldSky = cur; cur.Parent = nil end
	ourSky = keep(new("Sky", {Name = "LauncherSky", SkyboxBk = "", SkyboxDn = "", SkyboxFt = "", SkyboxLf = "", SkyboxRt = "", SkyboxUp = "", StarCount = d[2], CelestialBodiesShown = d[2] > 0}, Lighting))
	Lighting.ClockTime = d[1]
	if d[3] then ourAtm = keep(new("Atmosphere", {Name = "LauncherSkyAtm", Color = d[3][1], Decay = d[3][2], Density = d[3][3], Haze = d[3][4], Glare = 0.4}, Lighting)) end
	Lighting.Ambient = d[4]; Lighting.OutdoorAmbient = d[4]
	gcc.TintColor = d[5] or Color3.new(1, 1, 1)
end
M.cleanup[#M.cleanup + 1] = function() if oldSky and not oldSky.Parent then oldSky.Parent = Lighting end end

-- ---------- фон меню ----------
function M.applyMenuBg()
	local url = S.menuBg or ""
	for _, pn in ipairs(panels) do
		local im = pn.sg:FindFirstChild("MenuBg") -- картинка лежит в SurfaceGui, а не в панели с авто-раскладкой: кнопки больше не выталкиваются
		if url == "" or not M.menuBgAsset then
			if im then im:Destroy() end
		else
			if not im then
				if M.menuBgVideo then im = new("VideoFrame", {Name = "MenuBg", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Looped = true, Playing = true, Volume = 0, ZIndex = 0, Video = M.menuBgAsset}, pn.sg)
				else im = new("ImageLabel", {Name = "MenuBg", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 0, Image = M.menuBgAsset}, pn.sg) end
				new("UICorner", {CornerRadius = UDim.new(0, 18)}, im)
			end
			if not M.menuBgVideo then im.ImageTransparency = S.menuBgAlpha or 0.35 end
		end
	end
	if applyView then applyView() end
end
function M.setMenuBg(url)
	S.menuBg = url; M.menuBgAsset = nil
	for _, pn in ipairs(panels) do local im = pn.sg:FindFirstChild("MenuBg"); if im then im:Destroy() end end
	if url == "" then if applyView then applyView() end return end
	local ext = url:lower():match("%.(%w+)$")
	M.menuBgVideo = (ext == "mp4" or ext == "webm")
	task.spawn(function()
		local a, err = fetchAsset(url)
		if a then M.menuBgAsset = a; M.applyMenuBg() else toast("Фон меню: " .. tostring(err), 4) end
	end)
end
task.defer(function() if (S.menuBg or "") ~= "" then M.setMenuBg(S.menuBg) end end)

-- ---------- скрыть все партиклы (отключает, не удаляет: откат кнопкой) ----------
local pstate = {}
local PCLASS = {ParticleEmitter = true, Smoke = true, Fire = true, Trail = true, Sparkles = true}
local function kill(o)
	if PCLASS[o.ClassName] and not pstate[o] and o.Name:sub(1, 8) ~= "Launcher" and o.Parent ~= fxTop and o.Parent ~= fxLow and o.Enabled then
		pstate[o] = true; o.Enabled = false
	end
end
function M.applyParticles()
	if S.noParticles == M.lastNoPart then return end
	M.lastNoPart = S.noParticles
	if S.noParticles then
		task.spawn(function()
			local n = 0
			for _, o in ipairs(workspace:GetDescendants()) do
				kill(o); n += 1
				if n % 400 == 0 then task.wait() end
			end
		end)
		if not M.partConn then M.partConn = workspace.DescendantAdded:Connect(kill) end
	else
		if M.partConn then M.partConn:Disconnect(); M.partConn = nil end
		for o in pairs(pstate) do if o.Parent then pcall(function() o.Enabled = true end) end; pstate[o] = nil end
	end
end
M.cleanup[#M.cleanup + 1] = function() S.noParticles = false; M.lastNoPart = nil; M.applyParticles() end

function M.drawGfx(c, redraw)
	head(c, "Графика: пусто = как в игре. Любое значение можно менять и сбросить")
	for _, g in ipairs(GFX) do
		stepFn(c, g[2], function() local v = S.gfx[g[1]]; if v == nil then return GDEF[g[1]] end; return v end,
			function(v) S.gfx[g[1]] = v; M.applyGfx() end, g[5], g[3], g[4], nil, redraw)
	end
	label(c, "Оттенок картинки", 14, "text", nil, UDim2.new(1, 0, 0, 20), true)
	swatches(c, function() return S.gfx.tint or 0 end, function(v) S.gfx.tint = (v == 0) and nil or v; M.applyGfx() end, redraw)
	row(c, {{"↩ Сбросить всё", function() gfxReset(); redraw() end, true}})
	head(c, "Небо")
	local sk = {}
	for _, s in ipairs(SKIES) do sk[#sk + 1] = {s[2], function() M.setSky(s[1]); redraw() end, (S.sky or "none") ~= s[1]} end
	chunk(c, sk, 3)
	head(c, "Фон меню (png/jpg/mp4 по ссылке; GIF Roblox не умеет)")
	local ub = textbox(c, "https://…", S.menuBg or "", 36)
	row(c, {{"Применить", function() M.setMenuBg(ub.Text) end}, {"Убрать", function() M.setMenuBg(""); redraw() end, true}})
	stepFn(c, "Прозрачность картинки", function() return S.menuBgAlpha or 0.35 end, function(v) S.menuBgAlpha = v; M.applyMenuBg() end, 0.05, 0, 0.95, pct, redraw)
	head(c, "Партиклы")
	row(c, {tog("🚫 Скрыть все партиклы в игре", "noParticles", redraw)})
end
end -- конец бинды/графика

---------------------------------------------------------------- ВИДЖЕТЫ: K/D, флип-часы, мини-плеер, друзья зашли, достижения
do
local wg = keep(new("ScreenGui", {Name = "LauncherWidgets", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 58}, PG))
S.wpos = S.wpos or {}
S.kills = S.kills or 0; S.deaths = S.deaths or 0; S.stats = S.stats or {dist = 0, jumps = 0}; S.medals = S.medals or {}
local function draggable(f, key, dx, dy)
	f.Active = true
	local p = S.wpos[key]
	f.Position = UDim2.fromOffset(p and p[1] or dx, p and p[2] or dy)
	local st, base
	f.InputBegan:Connect(function(i)
		if isPress(i) then
			st = i.Position; base = f.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then st = nil; S.wpos[key] = {f.Position.X.Offset, f.Position.Y.Offset}; isDirty = true end
			end)
		end
	end)
	conn(UIS.InputChanged, function(i)
		if st and isMove(i) then local d = i.Position - st; f.Position = UDim2.fromOffset(base.X.Offset + d.X, base.Y.Offset + d.Y) end
	end)
end
local function pill(w, h)
	local f = new("Frame", {Size = UDim2.fromOffset(w, h), BackgroundColor3 = C(16, 16, 24), BackgroundTransparency = 0.2, BorderSizePixel = 0}, wg)
	round(f, 12)
	bind(new("UIStroke", {Thickness = 1.5, Transparency = 0.3}, f), "Color", "acc")
	return f
end
-- K/D
local kd = pill(150, 34)
draggable(kd, "kd", 12, 60)
local kdl = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.new(1, 1, 1)}, kd)
local function hookChar(p)
	local function onChar(ch)
		local h = ch:WaitForChild("Humanoid", 5)
		if not h then return end
		h.Died:Connect(function()
			if p == lp then S.deaths += 1
			else
				local tag = h:FindFirstChild("creator")
				if tag and tag.Value == lp then S.kills += 1 end
			end
			isDirty = true
		end)
	end
	if p.Character then task.spawn(onChar, p.Character) end
	conn(p.CharacterAdded, onChar)
end
for _, p in ipairs(Players:GetPlayers()) do hookChar(p) end
conn(Players.PlayerAdded, hookChar)
conn(Players.PlayerAdded, function(p)
	if p == lp then return end
	task.spawn(function()
		local ok, f = pcall(function() return lp:IsFriendsWith(p.UserId) end)
		if ok and f then M.notify("🤝 " .. p.DisplayName .. " зашёл в игру", 4) end
	end)
end)
-- флип-часы
local clk = pill(236, 54)
draggable(clk, "clock", 12, 100)
local cells = {}
local function mkCell(x)
	local f = new("Frame", {Position = UDim2.fromOffset(x, 8), Size = UDim2.fromOffset(24, 38), BackgroundColor3 = C(34, 34, 46), BorderSizePixel = 0, ClipsDescendants = true}, clk)
	round(f, 6)
	local function L(y) return new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, y), Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = Color3.new(1, 1, 1), Text = "0"}, f) end
	return {cur = L(0), nxt = L(1), v = "0"}
end
local xs = {10, 36, 70, 96, 130, 156}
for i = 1, 6 do cells[i] = mkCell(xs[i]) end
for _, x in ipairs({62, 122}) do new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 8), Size = UDim2.fromOffset(8, 38), Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = Color3.new(1, 1, 1), Text = ":"}, clk) end
new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(186, 8), Size = UDim2.fromOffset(46, 38), Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C(170, 170, 190), Text = os.date("%d.%m"), Name = "D"}, clk)
local function flip(cell, v)
	if cell.v == v then return end
	cell.v = v; cell.nxt.Text = v
	TS:Create(cell.cur, TweenInfo.new(0.25), {Position = UDim2.fromScale(0, -1)}):Play()
	TS:Create(cell.nxt, TweenInfo.new(0.25), {Position = UDim2.fromScale(0, 0)}):Play()
	task.delay(0.27, function() cell.cur.Text = v; cell.cur.Position = UDim2.fromScale(0, 0); cell.nxt.Position = UDim2.fromScale(0, 1) end)
end
-- мини-плеер
local mp = new("Frame", {Size = UDim2.fromOffset(310, 112), BackgroundColor3 = C(16, 16, 24), BackgroundTransparency = 0.15, BorderSizePixel = 0}, wg)
round(mp, 14); bind(new("UIStroke", {Thickness = 1.5, Transparency = 0.25}, mp), "Color", "acc")
draggable(mp, "mini", 12, 170)
local mt = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 20), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "Ничего не играет"}, mp)
local pbar = new("Frame", {Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = C(50, 50, 64), BorderSizePixel = 0}, mp); round(pbar, 3)
local pfill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0}, pbar); round(pfill, 3); bind(pfill, "BackgroundColor3", "acc")
local function mb(txt, x, w, cb) local b = new("TextButton", {Text = txt, Position = UDim2.fromOffset(x, 42), Size = UDim2.fromOffset(w, 28), BackgroundColor3 = C(40, 40, 54), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0}, mp); round(b, 8); tap(b, cb) end
mb("⏮", 12, 44, function() M.MU.prev() end); mb("⏯", 62, 54, function() M.MU.toggle() end); mb("⏭", 122, 44, function() M.MU.next() end)
mb("🔉", 190, 40, function() S.mVol = math.clamp((S.mVol or 0.6) - 0.1, 0, 1); M.applySound() end); mb("🔊", 236, 40, function() S.mVol = math.clamp((S.mVol or 0.6) + 0.1, 0, 1); M.applySound() end)
local eq = {}
for i = 1, 24 do eq[i] = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(12 + (i - 1) * 12, 106), Size = UDim2.fromOffset(9, 4), BorderSizePixel = 0}, mp); bind(eq[i], "BackgroundColor3", "acc") end
-- ВНИМАНИЕ: старые K/D и часы получают значения тут
conn(RS.RenderStepped, function(dt)
	kd.Visible = S.wKD == true; clk.Visible = S.wClock == true; mp.Visible = S.miniPlayer == true
	if kd.Visible then kdl.Text = "☠ K " .. S.kills .. "  /  D " .. S.deaths end
	if clk.Visible then
		local t = os.date("%H%M%S")
		for i = 1, 6 do flip(cells[i], t:sub(i, i)) end
	end
	if mp.Visible then
		local MU = M.MU
		local tr = MU.list[MU.idx]
		mt.Text = tr and ("🎵 " .. tr.name) or "Ничего не играет"
		local len = MU.sound.TimeLength
		pfill.Size = UDim2.new(len > 0 and math.clamp(MU.sound.TimePosition / len, 0, 1) or 0, 0, 1, 0)
		local lv = MU.sound.IsPlaying and math.min(MU.sound.PlaybackLoudness / 450, 1) or 0
		local t = os.clock()
		for i, b in ipairs(eq) do
			local h = 4 + lv * 52 * (0.3 + 0.7 * math.abs(math.sin(t * 3 + i * 0.7) * math.cos(t * 1.7 + i * 0.4)))
			b.Size = UDim2.fromOffset(9, h)
		end
	end
end)
-- достижения: расстояние и прыжки
local lastPos
conn(RS.Heartbeat, function()
	local r = root()
	if r then
		if lastPos then local d = (r.Position - lastPos).Magnitude; if d < 40 then S.stats.dist += d end end
		lastPos = r.Position
	end
end)
conn(UIS.JumpRequest, function() S.stats.jumps += 1 end)
local MEDALS = {
	{"dist", "Путешественник", {1000, 10000, 100000}, function() return S.stats.dist end, "стадов пройдено"},
	{"jumps", "Прыгун", {50, 500, 5000}, function() return S.stats.jumps end, "прыжков"},
	{"kills", "Охотник", {1, 10, 50}, function() return S.kills end, "убийств"},
	{"deaths", "Стойкий", {1, 25, 100}, function() return S.deaths end, "смертей"},
	{"min", "Старожил", {10, 60, 600}, function() return S.playMin or 0 end, "минут в игре"},
}
M.MEDALS = MEDALS
task.spawn(function()
	while alive do
		task.wait(5)
		for _, m in ipairs(MEDALS) do
			for lvl, th in ipairs(m[3]) do
				local id = m[1] .. lvl
				if m[4]() >= th and not S.medals[id] then S.medals[id] = true; M.notify("🏅 Достижение: " .. m[2] .. " " .. ({"🥉", "🥈", "🥇"})[lvl], 5); isDirty = true end
			end
		end
	end
end)
RUN.ach = function(c)
	label(c, "🏅 Достижения", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
	label(c, "Убийства считаются, если игра ставит стандартную метку «creator» на Humanoid. В других играх счётчик убийств может не работать.", 12, "sub", nil, UDim2.new(1, 0, 0, 34))
	for _, m in ipairs(MEDALS) do
		local v = m[4]()
		local nxt, got = nil, 0
		for lvl, th in ipairs(m[3]) do if v >= th then got = lvl elseif not nxt then nxt = th end end
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 58), "card2", 12)
		label(fr, m[2] .. "  " .. (got > 0 and ({"🥉", "🥈", "🥇"})[got] or "—"), 15, "text", UDim2.new(0, 12, 0, 4), UDim2.new(0.6, 0, 0, 22), true)
		label(fr, math.floor(v) .. " " .. m[5] .. (nxt and (" / " .. nxt) or "  ✔ максимум"), 12, "sub", UDim2.new(0, 12, 0, 26), UDim2.new(0.9, 0, 0, 16))
		local bar = frame(fr, UDim2.new(0, 12, 1, -12), UDim2.new(1, -24, 0, 6), "card", 3)
		frame(bar, UDim2.new(), UDim2.new(nxt and math.clamp(v / nxt, 0, 1) or 1, 0, 1, 0), "acc", 3)
	end
	row(c, {{"Сбросить K/D", function() S.kills, S.deaths = 0, 0; isDirty = true end, true}})
end
end -- конец виджетов

---------------------------------------------------------------- ТОЧКИ ПО ИГРАМ
do
S.pts = S.pts or {}
RUN.points = function(c)
	local key = tostring(game.PlaceId)
	local function entry() local e = S.pts[key]; if not e then e = {name = M.gameName or key, list = {}}; S.pts[key] = e end; if M.gameName then e.name = M.gameName end; return e end
	local function draw()
		reset(c)
		local e = entry()
		label(c, "📍 Точки: " .. tostring(e.name), 18, "text", nil, UDim2.new(1, 0, 0, 26), true)
		label(c, "Точки сохраняются отдельно для каждой игры и остаются после перезахода.", 12, "sub", nil, UDim2.new(1, 0, 0, 20))
		local nb = textbox(c, "название новой точки", "", 36)
		row(c, {{"📍 Сохранить мою позицию", function()
			local r = root()
			if r then e.list[#e.list + 1] = {name = nb.Text ~= "" and nb.Text or ("Точка " .. (#e.list + 1)), x = r.Position.X, y = r.Position.Y, z = r.Position.Z}; isDirty = true; draw() end
		end}})
		for i, pt in ipairs(e.list) do
			local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
			local tb = new("TextBox", {Text = pt.name, Size = UDim2.new(0.45, 0, 0, 32), Position = UDim2.new(0, 8, 0.5, -16), BackgroundTransparency = 1, TextColor3 = col("text"), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}, fr)
			bind(tb, "TextColor3", "text")
			tb.FocusLost:Connect(function() pt.name = tb.Text; isDirty = true end)
			local b1 = button(fr, "ТП", function() tpTo(Vector3.new(pt.x, pt.y, pt.z)) end, UDim2.new(0.22, 0, 0, 32)); b1.Position = UDim2.new(0.5, 0, 0.5, -16)
			local b2 = button(fr, "✕", function() table.remove(e.list, i); isDirty = true; draw() end, UDim2.new(0.2, 0, 0, 32), true); b2.Position = UDim2.new(0.76, 0, 0.5, -16)
		end
		local others = {}
		for k, v in pairs(S.pts) do if k ~= key and #v.list > 0 then others[#others + 1] = tostring(v.name) .. " (" .. #v.list .. ")" end end
		if #others > 0 then head(c, "Сохранено в других играх"); label(c, table.concat(others, "\n"), 13, "sub", nil, UDim2.new(1, 0, 0, 18 * #others)) end
	end
	draw()
end
end -- конец точек

---------------------------------------------------------------- ИНЖЕКТОР: информация и совместимость
do
RUN.execinfo = function(c)
	local G = (getgenv and getgenv()) or _G
	local CH = {
		{"request / http_request", (request or http_request or (syn and syn.request)) ~= nil, "музыкальные сервисы, браузер, сервер скрипта, каталог аватара, слова песен"},
		{"writefile / readfile / isfile", writefile ~= nil and readfile ~= nil and isfile ~= nil, "автосохранение настроек, плейлисты, конфиги, кэш"},
		{"makefolder / isfolder", makefolder ~= nil and isfolder ~= nil, "папки кэша и музыки"},
		{"listfiles", listfiles ~= nil, "сканирование локальной музыки"},
		{"getcustomasset", getcustomasset ~= nil, "музыка по ссылке, картинки/видео по URL, фон меню"},
		{"setclipboard", setclipboard ~= nil, "копирование ссылок, кодов конфига"},
		{"setfpscap", setfpscap ~= nil, "лимит FPS"},
		{"mouse1click", mouse1click ~= nil, "автокликер (иначе запасной способ)"},
		{"queue_on_teleport", queue_on_teleport ~= nil, "перезапуск скрипта после телепорта (пока не используется)"},
		{"getgenv", getgenv ~= nil, "защита от двойного запуска"},
		{"identifyexecutor", identifyexecutor ~= nil, "определение названия инжектора"},
		{"Drawing", Drawing ~= nil, "не используется (на будущее)"},
		{"hookfunction", hookfunction ~= nil, "не используется (на будущее)"},
	}
	local ok, n = 0, #CH
	for _, x in ipairs(CH) do if x[2] then ok += 1 end end
	label(c, "💉 Инжектор: " .. execName, 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
	label(c, "Как определён: " .. (identifyexecutor and "функция identifyexecutor() самого инжектора" or ((S.execOverride or "") ~= "" and "вручную (настройки)" or "по признакам глобальных переменных")) ..
		"\nУстройство: " .. deviceName .. "   ·   Совместимость: " .. ok .. " из " .. n, 13, "sub", nil, UDim2.new(1, 0, 0, 52))
	local bar = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 10), "card2", 5)
	frame(bar, UDim2.new(), UDim2.new(ok / n, 0, 1, 0), "acc", 5)
	for _, x in ipairs(CH) do
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 50), "card2", 10)
		label(fr, (x[2] and "✅ " or "❌ ") .. x[1], 14, "text", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 20), true)
		label(fr, "Нужно для: " .. x[3], 12, "sub", UDim2.new(0, 10, 0, 26), UDim2.new(1, -20, 0, 20))
	end
	row(c, {{"📋 Скопировать отчёт", function()
		local t = {"Инжектор: " .. execName .. " (" .. deviceName .. ")"}
		for _, x in ipairs(CH) do t[#t + 1] = (x[2] and "[+] " or "[-] ") .. x[1] end
		if setclipboard then pcall(setclipboard, table.concat(t, "\n")); toast("Отчёт скопирован", 2) end
	end, true}})
	label(c, "Если имя определилось неверно — впиши его вручную: «Настройки → Конфиг и сеть». Скрипт показывает то, что вернул сам инжектор: если он выдаёт чужое имя, это его особенность.", 12, "sub", nil, UDim2.new(1, 0, 0, 50))
end
end -- конец инжектор-инфо

---------------------------------------------------------------- ТЕЛЕФОН (приложения, звонки-сигналы, рация)
do
S.phoneNote = S.phoneNote or ""
local ringSnd = keep(new("Sound", {Name = "LauncherRing", SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6}, SoundService))
local callGui = keep(new("ScreenGui", {Name = "LauncherCall", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 85}, PG))
local callBar = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(300, 44), BackgroundColor3 = C(20, 140, 70), BorderSizePixel = 0, Visible = false}, callGui)
round(callBar, 22)
local callL = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left}, callBar)
local hang = new("TextButton", {Text = "📵", Position = UDim2.new(1, -66, 0.5, -16), Size = UDim2.fromOffset(52, 32), BackgroundColor3 = C(220, 50, 50), TextSize = 18, BorderSizePixel = 0}, callBar); round(hang, 16)
local function ringLoop(flag)
	task.spawn(function()
		while alive and flag() do pcall(function() ringSnd:Play() end); task.wait(1.2) end
	end)
end
local function endCall(send)
	local uid = (M.call and M.call.uid) or M.callOut
	M.call, M.callOut = nil, nil
	callBar.Visible = false
	if send and uid then M.NET.sendCtl(uid, "hang") end
end
tap(hang, function() endCall(true) end)
function M.callState(uid, ok)
	local nm = tostring(M.NET.names[uid] or uid)
	if ok then
		if M.callOut == uid then M.callOut = nil; M.call = {uid = uid, t0 = os.clock(), name = nm}; callBar.Visible = true; M.notify("📞 " .. nm .. " ответил(а)", 3) end
	else
		if M.call or M.callOut then endCall(false); M.notify("📵 Вызов завершён: " .. nm, 3) end
	end
end
function M.incomingCall(uid, nm)
	if M.call then M.NET.sendCtl(uid, "hang"); return end
	M.callOut = nil
	local answered = false
	M.notify("📞 Звонит " .. nm, 20, {
		{"Принять", function() answered = true; M.call = {uid = uid, t0 = os.clock(), name = nm}; callBar.Visible = true; M.NET.sendCtl(uid, "ans") end},
		{"Отклонить", function() answered = true; M.NET.sendCtl(uid, "hang") end, true}})
	ringLoop(function() return not answered and not M.call end)
end
function M.ringOut(uid)
	if M.call or M.callOut then return end
	M.callOut = uid
	S.callsMade = (S.callsMade or 0) + 1
	M.NET.sendCtl(uid, "ring")
	M.notify("📞 Звоню " .. tostring(M.NET.names[uid] or uid) .. "…", 3)
	ringLoop(function() return M.callOut == uid end)
	task.delay(30, function() if M.callOut == uid then M.callOut = nil; M.notify("Не ответил(а)", 3) end end)
end
function M.beep(nm) pcall(function() ringSnd:Play() end); M.notify("📻 Рация от " .. nm, 3) end
conn(RS.Heartbeat, function()
	if M.call then
		local el = os.clock() - M.call.t0
		callL.Text = "📞 " .. tostring(M.call.name) .. "   " .. string.format("%02d:%02d", math.floor(el / 60), math.floor(el % 60))
	end
end)

local flashlight
RUN.phone = function(c)
	if not S.owned.phone then label(c, "📵 Телефона нет. Купи его в «Магазине» (Зоо-магазин и техника) за 🪙 1.", 15, "text", nil, UDim2.new(1, 0, 0, 50), true); return end
	local tab = M.phoneTab or "home"
	local disp, acc, op, fresh = "0", nil, nil, true
	local sw = {t0 = 0, acc = 0, run = false}
	local me = c
	local function draw()
		reset(c)
		row(c, {{"🏠", function() M.phoneTab = "home"; tab = "home"; draw() end, tab ~= "home"}, {"📞", function() M.phoneTab = "calls"; tab = "calls"; draw() end, tab ~= "calls"},
			{"🔔 " .. #M.notifs, function() M.phoneTab = "notif"; tab = "notif"; draw() end, tab ~= "notif"}, {"⚙", function() M.phoneTab = "set"; tab = "set"; draw() end, tab ~= "set"}})
		if tab == "home" then
			label(c, os.date("%H:%M"), 40, "text", nil, UDim2.new(1, 0, 0, 52), true, Enum.TextXAlignment.Center)
			label(c, os.date("%A, %d.%m.%Y"), 13, "sub", nil, UDim2.new(1, 0, 0, 18), false, Enum.TextXAlignment.Center)
			local A = {
				{"🧮 Калькулятор", "calc"}, {"⏱ Секундомер", "stop"}, {"📝 Заметки", "note"}, {"🔦 Фонарик", "light"}, {"🧭 Компас", "compass"}, {"📸 Камера", "cam"},
				{"🎵 Музыка", "app:music"}, {"🌐 Браузер", "app:browser"}, {"🤝 Друзья", "app:friends"}, {"👾 Скриптеры", "app:scripters"}, {"🐾 Питомцы", "app:pets"}, {"🏅 Достижения", "app:ach"},
			}
			local defs = {}
			for _, a in ipairs(A) do
				defs[#defs + 1] = {a[1], function()
					if a[2]:sub(1, 4) == "app:" then local id = a[2]:sub(5); M.openApp({id = id, n = a[1], i = ""})
					elseif a[2] == "light" then
						local r = root()
						if flashlight then flashlight:Destroy(); flashlight = nil; toast("Фонарик выкл", 1.5)
						elseif r then flashlight = new("PointLight", {Name = "LauncherFxFlash", Range = 40, Brightness = 4, Color = C(255, 244, 214)}, r); toast("Фонарик вкл", 1.5) end
					elseif a[2] == "cam" then if M.photo then M.photo() end
					else M.phoneTab = a[2]; tab = a[2]; draw() end
				end, true}
			end
			chunk(c, defs, 3)
		elseif tab == "calls" then
			label(c, "📞 Звонки и рация (только друзья со скриптом, онлайн)", 14, "text", nil, UDim2.new(1, 0, 0, 22), true)
			label(c, "Это вызов-сигнал: звонок, ответ, таймер и звуковой сигнал «рации». Голос Roblox скрипту передавать не даёт — для разговора включи голосовой чат игры.", 12, "sub", nil, UDim2.new(1, 0, 0, 44))
			if M.call then label(c, "В разговоре: " .. tostring(M.call.name), 14, "text", nil, UDim2.new(1, 0, 0, 22), true); row(c, {{"📵 Завершить", function() endCall(true); draw() end}}) end
			if not M.NET.ok then label(c, "⚠ Нужен сервер скрипта.", 13, "text", nil, UDim2.new(1, 0, 0, 20)) end
			for _, u in ipairs(M.NET.friends) do
				if u.online ~= false then
					local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 46), "card2", 12)
					label(fr, tostring(u.display or u.name), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.4, 0, 1, 0), true)
					local b1 = button(fr, "📞", function() M.ringOut(u.uid) end, UDim2.new(0.2, 0, 0, 32)); b1.Position = UDim2.new(0.45, 0, 0.5, -16)
					local b2 = button(fr, "📻", function() M.NET.sendCtl(u.uid, "beep"); toast("Сигнал отправлен", 1.5) end, UDim2.new(0.2, 0, 0, 32), true); b2.Position = UDim2.new(0.68, 0, 0.5, -16)
				end
			end
		elseif tab == "notif" then
			row(c, {{"Очистить", function() M.notifs = {}; draw() end, true}})
			if #M.notifs == 0 then label(c, "Нет уведомлений", 14, "sub", nil, UDim2.new(1, 0, 0, 22)) end
			for _, n in ipairs(M.notifs) do label(c, os.date("%H:%M", n.ts) .. "  " .. n.t, 14, "text", nil, UDim2.new(1, 0, 0, 38)) end
		elseif tab == "set" then
			row(c, {tog("Уведомления", "notifOn", draw), tog("Звук скрипта", "sound", draw)})
			row(c, {tog("Мини-плеер", "miniPlayer", draw), tog("Флип-часы", "wClock", draw)})
			row(c, {tog("K/D счётчик", "wKD", draw), tog("Без партиклов", "noParticles", draw)})
			stepFn(c, "Яркость мира", function() return S.gfx.bright or Lighting.Brightness end, function(v) S.gfx.bright = v; M.applyGfx() end, 0.25, 0, 10, nil, draw)
			stepFn(c, "Громкость музыки", function() return S.mVol end, function(v) S.mVol = v; M.applySound() end, 0.1, 0, 1, pct, draw)
		elseif tab == "calc" then
			local lbl = label(c, disp, 36, "text", nil, UDim2.new(1, 0, 0, 52), true, Enum.TextXAlignment.Right)
			local function press(k)
				if k:match("%d") or k == "." then
					if fresh then disp = k; fresh = false else disp = (disp == "0" and k ~= ".") and k or (disp .. k) end
				elseif k == "C" then disp, acc, op, fresh = "0", nil, nil, true
				else
					local v = tonumber(disp) or 0
					if acc and op and not fresh then
						if op == "+" then acc += v elseif op == "−" then acc -= v elseif op == "×" then acc *= v elseif op == "÷" then acc = v ~= 0 and acc / v or 0 end
					else acc = v end
					op = (k ~= "=") and k or nil
					disp = tostring(math.floor(acc * 1e6 + 0.5) / 1e6); fresh = true
				end
				lbl.Text = disp
			end
			for _, rw in ipairs({{"7", "8", "9", "÷"}, {"4", "5", "6", "×"}, {"1", "2", "3", "−"}, {"C", "0", ".", "+"}, {"="}}) do
				local d = {}
				for _, k in ipairs(rw) do d[#d + 1] = {k, function() press(k) end, k:match("%d") ~= nil} end
				row(c, d)
			end
		elseif tab == "stop" then
			local lbl = label(c, "00:00.0", 48, "text", nil, UDim2.new(1, 0, 0, 70), true, Enum.TextXAlignment.Center)
			local sb
			sb = button(c, "Старт", function() if sw.run then sw.acc += os.clock() - sw.t0; sw.run = false; sb.Text = "Старт" else sw.t0 = os.clock(); sw.run = true; sb.Text = "Стоп" end end)
			button(c, "Сброс", function() sw.acc = 0; sw.run = false; sb.Text = "Старт"; lbl.Text = "00:00.0" end, nil, true)
			task.spawn(function()
				while content == me and tab == "stop" and alive do
					local e = sw.acc + (sw.run and os.clock() - sw.t0 or 0)
					lbl.Text = string.format("%02d:%04.1f", math.floor(e / 60), e % 60); task.wait(0.1)
				end
			end)
		elseif tab == "note" then
			local nb = textbox(c, "заметка…", S.phoneNote, 220, true)
			nb:GetPropertyChangedSignal("Text"):Connect(function() S.phoneNote = nb.Text; isDirty = true end)
		elseif tab == "compass" then
			local lbl = label(c, "", 22, "text", nil, UDim2.new(1, 0, 0, 90), true, Enum.TextXAlignment.Center)
			task.spawn(function()
				while content == me and tab == "compass" and alive do
					local r, cam = root(), workspace.CurrentCamera
					if r then
						local look = cam.CFrame.LookVector
						local deg = (math.deg(math.atan2(look.X, -look.Z)) + 360) % 360
						local dirs = {"С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"}
						lbl.Text = dirs[math.floor((deg + 22.5) / 45) % 8 + 1] .. "  " .. math.floor(deg) .. "°\nX " .. math.floor(r.Position.X) .. "  Y " .. math.floor(r.Position.Y) .. "  Z " .. math.floor(r.Position.Z)
					end
					task.wait(0.15)
				end
			end)
		end
	end
	draw()
end
end -- конец телефона

---------------------------------------------------------------- ПАРКУР И ЗАЩИТА, ФРИ-КАМЕРА, ФОТО, ТРЯСКА
do
S.airwalk = S.airwalk or false
local aw, lastSafe, awY = nil, nil, 0
conn(RS.Heartbeat, function()
	local r, h = root(), hum()
	if not (r and h) then return end
	if S.airwalk then
		if not aw then
			aw = keep(new("Part", {Anchored = true, Size = Vector3.new(6, 0.5, 6), Transparency = 0.8, Material = Enum.Material.Neon, Color = ACCENTS[S.acc], CanQuery = false, CanTouch = false}, workspace))
			awY = r.Position.Y - (h.HipHeight + r.Size.Y / 2) - 0.25
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then awY += 0.25 elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then awY -= 0.25 end
		aw.CFrame = CFrame.new(r.Position.X, awY, r.Position.Z)
	elseif aw then aw:Destroy(); aw = nil end
	if h.FloorMaterial ~= Enum.Material.Air and h.Health > 0 then lastSafe = r.Position end
	if S.antiVoid and lastSafe and r.Position.Y < workspace.FallenPartsDestroyHeight + 40 then
		r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = CFrame.new(lastSafe + Vector3.new(0, 4, 0))
	end
end)
conn(GS.ErrorMessageChanged, function()
	if S.autoRejoin then
		task.wait(1.5)
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)
	end
end)
function M.shake(power, dur)
	local t0 = os.clock()
	pcall(function() RS:UnbindFromRenderStep("L3D_Shake") end)
	RS:BindToRenderStep("L3D_Shake", Enum.RenderPriority.Camera.Value + 3, function()
		local k = 1 - (os.clock() - t0) / dur
		if k <= 0 then RS:UnbindFromRenderStep("L3D_Shake"); return end
		local cam = workspace.CurrentCamera
		local t = os.clock() * 30
		cam.CFrame = cam.CFrame * CFrame.Angles(math.noise(t, 1) * power * k * 0.05, math.noise(t, 7) * power * k * 0.05, math.noise(t, 13) * power * k * 0.02)
	end)
end
function M.photo()
	local wasOpen, hudWas = open, S.hud
	setOpen(false); S.hud = false; applyHud()
	local hidden = {}
	for _, g in ipairs({"LauncherWidgets", "LauncherToast"}) do local o = PG:FindFirstChild(g); if o and o.Enabled then o.Enabled = false; hidden[#hidden + 1] = o end end
	task.delay(0.5, function()
		local ok = pcall(function() game:GetService("CaptureService"):CaptureScreenshot(function() end) end)
		toast(ok and "📸 Снимок сделан (папка Captures Roblox; в папку инжектора сохранить нельзя)" or "📸 Автосъёмка недоступна: нажми системную кнопку скриншота Roblox", 4)
		task.delay(1.2, function()
			S.hud = hudWas; applyHud()
			for _, o in ipairs(hidden) do o.Enabled = true end
			if wasOpen then setOpen(true) end
		end)
	end)
end
-- фри-камера (локальный «призрак»: камера летает, тело стоит)
local fc = {on = false, yaw = 0, pitch = 0}
function M.freecam(on)
	local cam = workspace.CurrentCamera
	local h = hum()
	if on and not fc.on then
		fc.on = true; fc.pos = cam.CFrame.Position
		local look = cam.CFrame.LookVector
		fc.yaw = math.atan2(-look.X, -look.Z); fc.pitch = math.asin(look.Y)
		fc.type = cam.CameraType; cam.CameraType = Enum.CameraType.Scriptable
		if h then fc.ws = h.WalkSpeed; h.WalkSpeed = 0 end
		RS:BindToRenderStep("L3D_FreeCam", Enum.RenderPriority.Camera.Value + 4, function(dt)
			local sp = (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 90 or 30) * dt
			local cf = CFrame.new(fc.pos) * CFrame.Angles(0, fc.yaw, 0) * CFrame.Angles(fc.pitch, 0, 0)
			local mv = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.E) then mv += Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.Q) then mv -= Vector3.yAxis end
			fc.pos += mv * sp
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
				local d = UIS:GetMouseDelta()
				fc.yaw -= d.X * 0.004; fc.pitch = math.clamp(fc.pitch - d.Y * 0.004, -1.5, 1.5)
			else UIS.MouseBehavior = Enum.MouseBehavior.Default end
			cam.CFrame = CFrame.new(fc.pos) * CFrame.Angles(0, fc.yaw, 0) * CFrame.Angles(fc.pitch, 0, 0)
			if S.ghostHide and lp.Character then for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end end
		end)
	elseif not on and fc.on then
		fc.on = false
		pcall(function() RS:UnbindFromRenderStep("L3D_FreeCam") end)
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		cam.CameraType = fc.type or Enum.CameraType.Custom
		if h then h.WalkSpeed = fc.ws or 16 end
		if lp.Character then for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end end
	end
end
M.cleanup[#M.cleanup + 1] = function() M.freecam(false); pcall(function() RS:UnbindFromRenderStep("L3D_Shake") end) end
M.fcOn = function() return fc.on end
RUN.freecam = function(c)
	local function draw()
		reset(c)
		label(c, "👻 Фри-камера (призрак)", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		row(c, {{fc.on and "Выключить фри-камеру" or "Включить фри-камеру", function() M.freecam(not fc.on); draw() end, not fc.on}})
		row(c, {tog("Прятать своего персонажа", "ghostHide", draw)})
		label(c, "ПК: WASD — движение, Q/E — вниз/вверх, Shift — быстрее, правая кнопка мыши — поворот. Камера летает, тело стоит на месте. Для других игроков ты НЕ становишься невидимым: Roblox этого клиенту не позволяет, скрывается только твой персонаж на твоём экране.", 13, "sub", nil, UDim2.new(1, 0, 0, 100))
	end
	draw()
end
RUN.parkour = function(c)
	local function draw()
		reset(c)
		label(c, "🛡 Паркур и защита", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		row(c, {tog("Ходьба по воздуху (Space/Ctrl — выше/ниже)", "airwalk", draw)})
		row(c, {tog("Анти-бездна (вернёт, если упал за карту)", "antiVoid", draw)})
		row(c, {tog("Авто-реконнект при выбросе из игры", "autoRejoin", draw)})
		row(c, {tog("Анти-флинг", "antiFling", draw)})
		head(c, "Съёмка")
		row(c, {{"📸 Фото-режим (спрячет меню и снимет кадр)", function() M.photo() end}})
	end
	draw()
end
end -- конец паркура и защиты
M.load(96, "Игры, браузер, ИИ…")

---------------------------------------------------------------- БИНДЫ НА ЭКРАНЕ (видны, когда меню скрыто)
do
S.wpos = S.wpos or {}
local g = keep(new("ScreenGui", {Name = "VisualeseredBinds", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 57}, PG))
local f = new("Frame", {Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C(14, 14, 22), BackgroundTransparency = 0.25, BorderSizePixel = 0, Active = true}, g)
round(f, 12)
bind(new("UIStroke", {Thickness = 1.5, Transparency = 0.3}, f), "Color", "acc")
new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, f)
new("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, f)
local p0 = S.wpos.binds
f.Position = UDim2.fromOffset(p0 and p0[1] or 12, p0 and p0[2] or 240)
local st, base
f.InputBegan:Connect(function(i)
	if isPress(i) then
		st = i.Position; base = f.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then st = nil; S.wpos.binds = {f.Position.X.Offset, f.Position.Y.Offset}; isDirty = true end end)
	end
end)
conn(UIS.InputChanged, function(i) if st and isMove(i) then local d = i.Position - st; f.Position = UDim2.fromOffset(base.X.Offset + d.X, base.Y.Offset + d.Y) end end)
local STATE = {fly = function() return S.fly end, noclip = function() return S.noclip end, esp = function() return S.esp end, hud = function() return S.hud end,
	fp = function() return S.fpLock end, tpv = function() return S.tpLock end, drone = function() return S.drone end, aclick = function() return S.aclick end,
	noPart = function() return S.noParticles end, freecam = function() return M.fcOn and M.fcOn() end, mini = function() return S.miniPlayer end}
local sig = ""
task.spawn(function()
	while alive do
		task.wait(0.25)
		local vis = S.bindHud == true and not open
		f.Visible = vis
		if vis then
			local parts = {}
			for _, k in ipairs(M.KEYDEF) do
				local key = S.keys[k[1]]
				if key and key ~= "" then parts[#parts + 1] = k[1] .. key .. tostring(STATE[k[1]] and STATE[k[1]]() or "") end
			end
			local s2 = table.concat(parts, "|")
			if s2 ~= sig then
				sig = s2
				for _, ch in ipairs(f:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
				local n = 0
				for _, k in ipairs(M.KEYDEF) do
					local key = S.keys[k[1]]
					if key and key ~= "" then
						n += 1
						local r = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = n}, f)
						local cap = new("TextLabel", {Size = UDim2.fromOffset(34, 20), Text = key, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = C(34, 34, 48), BorderSizePixel = 0}, r)
						round(cap, 5)
						local on = STATE[k[1]] and STATE[k[1]]()
						new("TextLabel", {Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
							TextColor3 = on and C(110, 255, 150) or C(220, 222, 235), Text = k[2]}, r)
						if STATE[k[1]] then new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = on and C(110, 255, 150) or C(90, 90, 105), BorderSizePixel = 0}, r)
						end
					end
				end
			end
		end
	end
end)
end -- конец бинд-панели

---------------------------------------------------------------- ИГРЫ: крестики-нолики, сапёр, память, флэппи
do
local function keyHook(me, fn)
	local k
	k = UIS.InputBegan:Connect(function(i, gp)
		if content ~= me then k:Disconnect(); return end
		if gp or UIS:GetFocusedTextBox() then return end
		fn(i.KeyCode)
	end)
end
RUN.ttt = function(c)
	local b, over, msg = {}, false, "Твой ход (✕)"
	for i = 1, 9 do b[i] = "" end
	local LN = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {1, 4, 7}, {2, 5, 8}, {3, 6, 9}, {1, 5, 9}, {3, 5, 7}}
	local function win(bd) for _, l in ipairs(LN) do local a = bd[l[1]]; if a ~= "" and a == bd[l[2]] and a == bd[l[3]] then return a end end end
	local function full(bd) for i = 1, 9 do if bd[i] == "" then return false end end return true end
	local function mm(bd, turn)
		local w = win(bd)
		if w == "O" then return 1 elseif w == "X" then return -1 elseif full(bd) then return 0 end
		local best = turn == "O" and -2 or 2
		for i = 1, 9 do
			if bd[i] == "" then
				bd[i] = turn
				local s2 = mm(bd, turn == "O" and "X" or "O")
				bd[i] = ""
				best = turn == "O" and math.max(best, s2) or math.min(best, s2)
			end
		end
		return best
	end
	local function bot()
		local e = {}
		for i = 1, 9 do if b[i] == "" then e[#e + 1] = i end end
		if #e == 0 then return end
		if not M.tttHard and math.random() < 0.4 then b[e[math.random(#e)]] = "O"; return end
		local bi, bs = e[1], -2
		for _, i in ipairs(e) do b[i] = "O"; local s2 = mm(b, "X"); b[i] = ""; if s2 > bs then bs, bi = s2, i end end
		b[bi] = "O"
	end
	local function check()
		local w = win(b)
		if w then over = true; msg = w == "X" and "🎉 Ты победил!" or "🤖 Победил бот"
		elseif full(b) then over = true; msg = "Ничья" end
	end
	local draw
	function draw()
		reset(c)
		label(c, msg, 18, "text", nil, UDim2.new(1, 0, 0, 26), true)
		for r = 1, 3 do
			local defs = {}
			for k = 1, 3 do
				local i = (r - 1) * 3 + k
				defs[#defs + 1] = {b[i] == "" and "·" or (b[i] == "X" and "✕" or "○"), function()
					if over or b[i] ~= "" then return end
					b[i] = "X"; check()
					if not over then bot(); check() end
					draw()
				end, b[i] == ""}
			end
			row(c, defs).Size = UDim2.new(1, 0, 0, 64)
		end
		row(c, {{"Заново", function() for i = 1, 9 do b[i] = "" end; over = false; msg = "Твой ход (✕)"; draw() end, true}, {M.tttHard and "Бот: сложный" or "Бот: лёгкий", function() M.tttHard = not M.tttHard; draw() end, true}})
	end
	draw()
end

RUN.mines = function(c)
	local N, MINES = 8, 10
	local mine, opened, flag, cnt, over, first, flagMode, left = {}, {}, {}, {}, false, true, false, 0
	local cells = {}
	local info = label(c, "", 16, "text", nil, UDim2.new(1, 0, 0, 24), true)
	local board = new("Frame", {Size = UDim2.fromOffset(N * 38, N * 38), BackgroundTransparency = 1}, c)
	new("UIGridLayout", {CellSize = UDim2.fromOffset(36, 36), CellPadding = UDim2.fromOffset(2, 2), SortOrder = Enum.SortOrder.LayoutOrder}, board)
	local function nb(i) local t = {}; local x, y = (i - 1) % N, (i - 1) // N; for dx = -1, 1 do for dy = -1, 1 do if (dx ~= 0 or dy ~= 0) and x + dx >= 0 and x + dx < N and y + dy >= 0 and y + dy < N then t[#t + 1] = (y + dy) * N + x + dx + 1 end end end return t end
	local function render()
		local fl = 0
		for i = 1, N * N do
			local cl = cells[i]
			if flag[i] then fl += 1 end
			if opened[i] then
				cl.BackgroundColor3 = mine[i] and C(200, 50, 50) or C(60, 64, 76)
				cl.Text = mine[i] and "💣" or (cnt[i] > 0 and tostring(cnt[i]) or "")
				cl.TextColor3 = ({C(80, 160, 255), C(80, 220, 120), C(255, 100, 100), C(180, 120, 255), C(255, 180, 60), C(80, 220, 220), C(255, 255, 255), C(150, 150, 150)})[cnt[i] or 1] or Color3.new(1, 1, 1)
			else cl.BackgroundColor3 = C(95, 100, 120); cl.Text = flag[i] and "🚩" or "" end
		end
		info.Text = over and (left == 0 and "🎉 Победа!" or "💥 Бум!") or ("Мин: " .. (MINES - fl))
	end
	local function reveal(i)
		local stack = {i}
		while #stack > 0 do
			local j = table.remove(stack)
			if not opened[j] and not flag[j] then
				opened[j] = true
				if not mine[j] and cnt[j] == 0 then for _, k in ipairs(nb(j)) do stack[#stack + 1] = k end end
			end
		end
	end
	local function click(i)
		if over then return end
		if flagMode then if not opened[i] then flag[i] = not flag[i] end render(); return end
		if flag[i] or opened[i] then return end
		if first then
			first = false
			local safe = {[i] = true}
			for _, k in ipairs(nb(i)) do safe[k] = true end
			local placed = 0
			while placed < MINES do local r = math.random(N * N); if not mine[r] and not safe[r] then mine[r] = true; placed += 1 end end
			for k = 1, N * N do local n2 = 0; for _, j in ipairs(nb(k)) do if mine[j] then n2 += 1 end end cnt[k] = n2 end
		end
		if mine[i] then
			over = true
			for k = 1, N * N do if mine[k] then opened[k] = true end end
		else
			reveal(i)
			left = 0
			for k = 1, N * N do if not mine[k] and not opened[k] then left += 1 end end
			if left == 0 then over = true end
		end
		render()
	end
	for i = 1, N * N do
		local b2 = new("TextButton", {LayoutOrder = i, Text = "", Font = Enum.Font.GothamBold, TextSize = 18, BorderSizePixel = 0, BackgroundColor3 = C(95, 100, 120), TextColor3 = Color3.new(1, 1, 1)}, board)
		round(b2, 6); tap(b2, function() click(i) end); cells[i] = b2
	end
	row(c, {{"🚩 Режим флажка: ВЫКЛ", function() end, true}, {"Заново", function() mine, opened, flag, cnt, over, first = {}, {}, {}, {}, false, true; render() end, true}})
	local frow = c:GetChildren()
	local fb = frow[#frow]:FindFirstChildOfClass("TextButton")
	tap(fb, function() flagMode = not flagMode; fb.Text = flagMode and "🚩 Режим флажка: ВКЛ" or "🚩 Режим флажка: ВЫКЛ" end)
	render()
end

RUN.memory = function(c)
	local E = {"🍎", "🍌", "🍇", "🍒", "🥝", "🍉", "🍋", "🍑"}
	local deck = {}
	for _, e in ipairs(E) do deck[#deck + 1] = e; deck[#deck + 1] = e end
	for i = #deck, 2, -1 do local j = math.random(i); deck[i], deck[j] = deck[j], deck[i] end
	local shown, done, first, lock, moves = {}, {}, nil, false, 0
	local info = label(c, "Ходов: 0", 16, "text", nil, UDim2.new(1, 0, 0, 24), true)
	local board = new("Frame", {Size = UDim2.fromOffset(4 * 80, 4 * 80), BackgroundTransparency = 1}, c)
	new("UIGridLayout", {CellSize = UDim2.fromOffset(76, 76), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder}, board)
	local cells = {}
	local function render()
		for i = 1, 16 do
			cells[i].Text = (shown[i] or done[i]) and deck[i] or "❔"
			cells[i].BackgroundColor3 = done[i] and C(60, 150, 90) or C(70, 76, 98)
		end
		local d = 0
		for _ in pairs(done) do d += 1 end
		info.Text = d == 16 and ("🎉 Победа за " .. moves .. " ходов!") or ("Ходов: " .. moves)
	end
	for i = 1, 16 do
		local b2 = new("TextButton", {LayoutOrder = i, Text = "❔", TextSize = 34, BorderSizePixel = 0, BackgroundColor3 = C(70, 76, 98)}, board)
		round(b2, 10)
		tap(b2, function()
			if lock or shown[i] or done[i] then return end
			shown[i] = true; render()
			if not first then first = i
			else
				moves += 1
				if deck[first] == deck[i] then done[first] = true; done[i] = true; shown[first] = nil; shown[i] = nil; first = nil; render()
				else
					lock = true
					local a = first; first = nil
					task.delay(0.7, function() shown[a] = nil; shown[i] = nil; lock = false; if content == c.Parent or true then render() end end)
				end
			end
		end)
		cells[i] = b2
	end
	row(c, {{"Заново", function() M.openApp({id = "memory", n = "Память", i = "🧠"}) end, true}})
	render()
end

RUN.flappy = function(c)
	local me = c
	local W, H = 300, 360
	local info = label(c, "Тап / Space — взмах", 16, "text", nil, UDim2.new(1, 0, 0, 24), true)
	local field = new("Frame", {Size = UDim2.fromOffset(W, H), BackgroundColor3 = C(80, 170, 230), BorderSizePixel = 0, ClipsDescendants = true}, c)
	round(field, 10)
	local bird = new("TextLabel", {Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(60, 150), BackgroundTransparency = 1, Text = "🐦", TextSize = 26}, field)
	local by, vy, pipes, score, dead, t = 150, 0, {}, 0, false, 0
	local function mkPipe()
		local gy = math.random(70, H - 110)
		local top = new("Frame", {Position = UDim2.fromOffset(W, 0), Size = UDim2.fromOffset(44, gy - 50), BackgroundColor3 = C(60, 190, 80), BorderSizePixel = 0}, field)
		local bot = new("Frame", {Position = UDim2.fromOffset(W, gy + 50), Size = UDim2.fromOffset(44, H - gy - 50), BackgroundColor3 = C(60, 190, 80), BorderSizePixel = 0}, field)
		pipes[#pipes + 1] = {x = W, gy = gy, top = top, bot = bot, passed = false}
	end
	local function flap() if dead then return end vy = -250 end
	local function restart() for _, p in ipairs(pipes) do p.top:Destroy(); p.bot:Destroy() end; pipes = {}; by, vy, score, dead, t = 150, 0, 0, false, 0; info.Text = "Тап / Space — взмах" end
	row(c, {{"⬆ Взмах", flap}, {"Заново", restart, true}})
	keyHook(me, function(k) if k == Enum.KeyCode.Space then flap() end end)
	task.spawn(function()
		while content == me and alive do
			local dt = 0.03
			task.wait(dt)
			if not dead then
				t += dt
				if #pipes == 0 or pipes[#pipes].x < W - 170 then mkPipe() end
				vy += 700 * dt; by += vy * dt
				bird.Position = UDim2.fromOffset(60, by)
				for i = #pipes, 1, -1 do
					local p = pipes[i]
					p.x -= 120 * dt
					p.top.Position = UDim2.new(0, p.x, 0, 0); p.bot.Position = UDim2.new(0, p.x, 0, p.gy + 50)
					if p.x < 90 and p.x + 44 > 56 and (by < p.gy - 50 or by + 28 > p.gy + 50) then dead = true end
					if not p.passed and p.x + 44 < 60 then p.passed = true; score += 1; info.Text = "Счёт: " .. score end
					if p.x < -60 then p.top:Destroy(); p.bot:Destroy(); table.remove(pipes, i) end
				end
				if by < -10 or by > H - 30 then dead = true end
				if dead then info.Text = "💥 Игра окончена · счёт " .. score end
			end
		end
	end)
end
end -- конец игр

---------------------------------------------------------------- БРАУЗЕР (улучшенный: DuckDuckGo, Википедия, закладки, история, страницы)
do
S.bookmarks = S.bookmarks or {}
local V = {engine = "ddg", mode = "home", page = 1, hist = {}}
local ENG = {ddg = "🦆 DuckDuckGo", wru = "📚 Википедия RU", wen = "📚 Wikipedia EN"}
local NEXT = {ddg = "wru", wru = "wen", wen = "ddg"}
local CH = 3200
local function wikiSearch(q, lang)
	local body = M.br.http("https://" .. lang .. ".wikipedia.org/w/api.php?action=query&list=search&srlimit=12&format=json&utf8=1&srsearch=" .. HS:UrlEncode(q))
	if not body then return nil, "нет ответа Википедии" end
	local ok, d = pcall(HS.JSONDecode, HS, body)
	if not ok or not d.query then return nil, "ответ не разобрался" end
	local r = {}
	for _, it in ipairs(d.query.search) do r[#r + 1] = {title = it.title, snip = M.br.unesc(it.snippet or ""), kind = "wiki", lang = lang} end
	if #r == 0 then return nil, "ничего не найдено" end
	return r
end
local function wikiPage(title, lang)
	local body = M.br.http("https://" .. lang .. ".wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exsectionformat=plain&format=json&utf8=1&redirects=1&titles=" .. HS:UrlEncode(title))
	if not body then return nil, "нет ответа" end
	local ok, d = pcall(HS.JSONDecode, HS, body)
	if not ok or not d.query then return nil, "не разобралось" end
	for _, p in pairs(d.query.pages) do if p.extract then return p.extract end end
	return nil, "статья пуста"
end
RUN.browser = function(c)
	local me = c
	local qtb
	local draw
	local function pushHist(e) table.insert(V.hist, 1, e); if #V.hist > 30 then V.hist[31] = nil end end
	local function openItem(it)
		V.mode = "loading"; V.cur = it; draw()
		task.spawn(function()
			local txt, links, err
			if it.kind == "wiki" then txt, err = wikiPage(it.title, it.lang); links = {}
			else txt, links = M.br.readPage(it.url); if not txt then err = links; links = {} end end
			if content ~= me then return end
			if txt then V.text, V.links, V.page, V.mode = txt, links, 1, "page"; pushHist({title = it.title or it.url, kind = it.kind, lang = it.lang, url = it.url})
			else V.mode, V.err = "error", err end
			draw()
		end)
	end
	local function find(q)
		V.q = q; V.mode = "loading"; draw()
		task.spawn(function()
			local r, err
			if V.engine == "ddg" then r, err = M.br.search(q) else r, err = wikiSearch(q, V.engine == "wru" and "ru" or "en") end
			if content ~= me then return end
			if r then for _, it in ipairs(r) do it.kind = it.kind or "web" end; V.items, V.mode = r, "results" else V.mode, V.err = "error", err end
			draw()
		end)
	end
	function draw()
		reset(c)
		qtb = textbox(c, "Поиск или адрес сайта (https://…)", V.q or "", 40)
		qtb.FocusLost:Connect(function(enter) if enter and qtb.Text ~= "" then V.q = qtb.Text; if qtb.Text:match("^https?://") then openItem({kind = "web", url = qtb.Text, title = qtb.Text}) else find(qtb.Text) end end end)
		row(c, {{"🔎 Найти", function() local t = qtb.Text; if t == "" then return end; V.q = t; if t:match("^https?://") then openItem({kind = "web", url = t, title = t}) else find(t) end end},
			{ENG[V.engine], function() V.engine = NEXT[V.engine]; draw() end, true}, {"★", function()
				if V.cur then
					local k = V.cur.url or (V.cur.lang .. ":" .. V.cur.title)
					for i, b in ipairs(S.bookmarks) do if b.k == k then table.remove(S.bookmarks, i); isDirty = true; draw(); return end end
					S.bookmarks[#S.bookmarks + 1] = {k = k, title = V.cur.title or k, kind = V.cur.kind, url = V.cur.url, lang = V.cur.lang}; isDirty = true; toast("Добавлено в закладки", 1.5)
				end
			end, true}})
		row(c, {{"🏠", function() V.mode = "home"; draw() end, true}, {"📖 Закладки", function() V.mode = "bm"; draw() end, true}, {"🕘 История", function() V.mode = "hist"; draw() end, true},
			{setclipboard and "📋 Ссылка" or "—", function() if setclipboard and V.cur and V.cur.url then pcall(setclipboard, V.cur.url); toast("Скопировано", 1.5) end end, true}})
		if V.mode == "home" then
			label(c, "Текстовый браузер: читает страницы как текст (без картинок и JavaScript). Википедия показывается чисто и удобно.", 13, "sub", nil, UDim2.new(1, 0, 0, 44))
			head(c, "Быстрые сайты")
			local q2 = {{"Википедия", function() V.engine = "wru"; find("Roblox") end}, {"Roblox Wiki", function() openItem({kind = "web", url = "https://roblox.fandom.com/wiki/Roblox_Wiki", title = "Roblox Wiki"}) end},
				{"Новости", function() openItem({kind = "web", url = "https://lite.cnn.com", title = "CNN Lite"}) end}}
			local defs = {}
			for _, x in ipairs(q2) do defs[#defs + 1] = {x[1], x[2], true} end
			row(c, defs)
		elseif V.mode == "loading" then label(c, "Загрузка…", 16, "sub", nil, UDim2.new(1, 0, 0, 30))
		elseif V.mode == "error" then label(c, "⚠ " .. tostring(V.err), 14, "text", nil, UDim2.new(1, 0, 0, 44))
		elseif V.mode == "results" then
			for _, it in ipairs(V.items) do
				local b2 = button(c, tostring(it.title):sub(1, 90), function() openItem(it) end, UDim2.new(1, 0, 0, 38), true)
				b2.TextXAlignment = Enum.TextXAlignment.Left
				if it.snip then label(c, it.snip:sub(1, 200), 12, "sub", nil, UDim2.new(1, 0, 0, 34)) end
			end
		elseif V.mode == "bm" then
			if #S.bookmarks == 0 then label(c, "Закладок нет. Открой страницу и нажми ★.", 14, "sub", nil, UDim2.new(1, 0, 0, 24)) end
			for i, b in ipairs(S.bookmarks) do
				local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 40), "card2", 10)
				local o = button(fr, "★ " .. tostring(b.title):sub(1, 44), function() openItem({kind = b.kind, url = b.url, title = b.title, lang = b.lang}) end, UDim2.new(0.8, 0, 0, 30), true); o.Position = UDim2.new(0.01, 0, 0.5, -15)
				local x = button(fr, "✕", function() table.remove(S.bookmarks, i); isDirty = true; draw() end, UDim2.new(0.15, 0, 0, 30), true); x.Position = UDim2.new(0.83, 0, 0.5, -15)
			end
		elseif V.mode == "hist" then
			for _, h in ipairs(V.hist) do
				local b2 = button(c, tostring(h.title):sub(1, 70), function() openItem({kind = h.kind, url = h.url, title = h.title, lang = h.lang}) end, UDim2.new(1, 0, 0, 34), true)
				b2.TextXAlignment = Enum.TextXAlignment.Left
			end
		elseif V.mode == "page" then
			local pages = math.max(1, math.ceil(#V.text / CH))
			V.page = math.clamp(V.page, 1, pages)
			label(c, tostring(V.cur and V.cur.title or ""), 16, "text", nil, UDim2.new(1, 0, 0, 24), true)
			local l = label(c, V.text:sub((V.page - 1) * CH + 1, V.page * CH), S.brSize or 14, "text", nil, UDim2.new(1, -4, 0, 0))
			l.AutomaticSize = Enum.AutomaticSize.Y; l.TextYAlignment = Enum.TextYAlignment.Top
			row(c, {{"◀", function() V.page -= 1; draw() end, true}, {V.page .. " / " .. pages, function() end, true}, {"▶", function() V.page += 1; draw() end, true},
				{"A−", function() S.brSize = math.max(10, (S.brSize or 14) - 1); draw() end, true}, {"A+", function() S.brSize = math.min(24, (S.brSize or 14) + 1); draw() end, true}})
			if V.links and #V.links > 0 then
				head(c, "Ссылки")
				for _, lk in ipairs(V.links) do
					local b2 = button(c, lk.title, function() openItem({kind = "web", url = lk.url, title = lk.title}) end, UDim2.new(1, 0, 0, 32), true)
					b2.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
		end
	end
	draw()
end
end -- конец браузера

---------------------------------------------------------------- ЗАМЕТКИ (несколько, с поиском)
do
S.noteList = S.noteList or {}
RUN.notes = function(c)
	local sel, q = nil, ""
	local draw
	function draw()
		reset(c)
		local n = sel and S.noteList[sel]
		if n then
			row(c, {{"‹ К списку", function() sel = nil; draw() end, true}, {"📋 Копировать", function() if setclipboard then pcall(setclipboard, n.t .. "\n\n" .. n.b); toast("Скопировано", 1.5) end end, true},
				{"🗑 Удалить", function() table.remove(S.noteList, sel); sel = nil; isDirty = true; draw() end, true}})
			local tt = textbox(c, "Заголовок", n.t, 38)
			tt:GetPropertyChangedSignal("Text"):Connect(function() n.t = tt.Text; n.ts = os.time(); isDirty = true end)
			local bt = textbox(c, "Текст заметки…", n.b, 280, true)
			local cl = label(c, #n.b .. " символов", 12, "sub", nil, UDim2.new(1, 0, 0, 18))
			bt:GetPropertyChangedSignal("Text"):Connect(function() n.b = bt.Text; n.ts = os.time(); cl.Text = #n.b .. " символов"; isDirty = true end)
			return
		end
		label(c, "📝 Заметки (" .. #S.noteList .. ")", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		local sb = textbox(c, "Поиск по заметкам", q, 36)
		sb:GetPropertyChangedSignal("Text"):Connect(function() q = sb.Text end)
		row(c, {{"➕ Новая заметка", function() S.noteList[#S.noteList + 1] = {t = "Заметка " .. (#S.noteList + 1), b = "", ts = os.time()}; sel = #S.noteList; isDirty = true; draw() end}, {"🔎 Искать", draw, true}})
		local order = {}
		for i, nn in ipairs(S.noteList) do if q == "" or (nn.t .. " " .. nn.b):lower():find(q:lower(), 1, true) then order[#order + 1] = i end end
		table.sort(order, function(a, b2) return (S.noteList[a].ts or 0) > (S.noteList[b2].ts or 0) end)
		for _, i in ipairs(order) do
			local nn = S.noteList[i]
			local b2 = button(c, nn.t .. "   ·   " .. os.date("%d.%m %H:%M", nn.ts or 0) .. "\n" .. nn.b:sub(1, 50):gsub("\n", " "), function() sel = i; draw() end, UDim2.new(1, 0, 0, 52), true)
			b2.TextXAlignment = Enum.TextXAlignment.Left
		end
		if #order == 0 then label(c, "Заметок нет.", 14, "sub", nil, UDim2.new(1, 0, 0, 22)) end
	end
	draw()
end
end -- конец заметок

---------------------------------------------------------------- ЦВЕТА: своя тема, свой акцент, цвета профиля (RGB / HEX)
do
local function cnt(t) local n = 0; for _ in pairs(t or {}) do n += 1 end; return n end
S.customTheme = S.customTheme or {}; S.profColors = S.profColors or {}
local function mkCustom()
	local t = {}
	for k, v in pairs(THEMES["Тёмная"]) do local o = S.customTheme[k]; t[k] = o and Color3.fromRGB(o[1], o[2], o[3]) or v end
	return t
end
THEMES["Своя"] = mkCustom(); THEME_ORDER[#THEME_ORDER + 1] = "Своя"
THEMES["Хэллоуин"] = {bg = C(22, 10, 28), card = C(46, 22, 50), card2 = C(72, 34, 62), text = C(255, 238, 220), sub = C(225, 160, 110), rim = C(255, 120, 30)}
local t0 = os.date("*t")
if t0.month == 10 or (t0.month == 11 and t0.day <= 7) or S.hwClaimed then THEME_ORDER[#THEME_ORDER + 1] = "Хэллоуин" end
local ca = S.customAccent
ACCENTS[9] = ca and Color3.fromRGB(ca[1], ca[2], ca[3]) or C(255, 120, 30)
local TARGETS = {
	{"t:bg", "Фон панелей"}, {"t:card", "Карточки"}, {"t:card2", "Кнопки"}, {"t:text", "Текст"}, {"t:sub", "Доп. текст"}, {"t:rim", "Рамка панелей"}, {"acc", "Акцент"},
	{"p:banner", "Баннер профиля"}, {"p:name", "Ник в профиле"}, {"p:frame", "Рамка аватара"}, {"p:bio", "Текст «о себе»"}, {"p:card", "Фон карточки"},
}
local function getRGB(tg)
	local kind, key = tg:match("^(%a+):?(.*)$")
	if kind == "t" then local c2 = THEMES["Своя"][key]; return {math.floor(c2.R * 255 + 0.5), math.floor(c2.G * 255 + 0.5), math.floor(c2.B * 255 + 0.5)} end
	if kind == "acc" then local c2 = ACCENTS[9]; return {math.floor(c2.R * 255 + 0.5), math.floor(c2.G * 255 + 0.5), math.floor(c2.B * 255 + 0.5)} end
	return S.profColors[key] or {120, 160, 255}
end
local function setRGB(tg, r, g, b)
	local kind, key = tg:match("^(%a+):?(.*)$")
	local col2 = Color3.fromRGB(r, g, b)
	if kind == "t" then
		S.customTheme[key] = {r, g, b}; THEMES["Своя"][key] = col2; S.theme = "Своя"; applyAll()
	elseif kind == "acc" then
		S.customAccent = {r, g, b}; ACCENTS[9] = col2; S.acc = 9; applyAll()
	else S.profColors[key] = {r, g, b}; isDirty = true end
	isDirty = true
end
function M.drawColors(c, redraw, mode)
	local tgs = {}
	for _, t in ipairs(TARGETS) do if mode ~= "profile" or t[1]:sub(1, 2) == "p:" then tgs[#tgs + 1] = t end end
	M.colTarget = M.colTarget or tgs[1][1]
	local okT = false
	for _, t in ipairs(tgs) do if t[1] == M.colTarget then okT = true end end
	if not okT then M.colTarget = tgs[1][1] end
	head(c, "Что красим")
	local defs = {}
	for _, t in ipairs(tgs) do defs[#defs + 1] = {t[2], function() M.colTarget = t[1]; redraw() end, M.colTarget ~= t[1]} end
	chunk(c, defs, 3)
	local rgb = getRGB(M.colTarget)
	local sw = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(rgb[1], rgb[2], rgb[3]), BorderSizePixel = 0}, c)
	round(sw, 10)
	for i, nm in ipairs({"Красный", "Зелёный", "Синий"}) do
		stepFn(c, nm, function() return rgb[i] end, function(v) rgb[i] = v; setRGB(M.colTarget, rgb[1], rgb[2], rgb[3]) end, 5, 0, 255, nil, redraw)
	end
	local hx = textbox(c, "HEX, например FF7A00", string.format("%02X%02X%02X", rgb[1], rgb[2], rgb[3]), 36)
	row(c, {{"Применить HEX", function()
		local h = hx.Text:gsub("#", "")
		if #h == 6 and tonumber(h, 16) then setRGB(M.colTarget, tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)); redraw() else toast("Нужен HEX из 6 символов", 2) end
	end}})
	head(c, "Быстрая палитра")
	local pd = {}
	for i, col2 in ipairs(PALETTE) do pd[#pd + 1] = {"", function() setRGB(M.colTarget, math.floor(col2.R * 255 + 0.5), math.floor(col2.G * 255 + 0.5), math.floor(col2.B * 255 + 0.5)); redraw() end, true} end
	local pr = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34)}, c)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, pr)
	for _, col2 in ipairs(PALETTE) do
		local b2 = new("TextButton", {Text = "", BackgroundColor3 = col2, Size = UDim2.fromOffset(30, 30), BorderSizePixel = 0}, pr)
		round(b2, 15)
		tap(b2, function() setRGB(M.colTarget, math.floor(col2.R * 255 + 0.5), math.floor(col2.G * 255 + 0.5), math.floor(col2.B * 255 + 0.5)); redraw() end)
	end
	row(c, {{"Сбросить профиль", function() S.profColors = {}; isDirty = true; redraw() end, true}, {"Сбросить тему «Своя»", function() S.customTheme = {}; THEMES["Своя"] = mkCustom(); applyAll(); redraw() end, true}})
	if mode ~= "profile" then label(c, "Тема «Своя» применяется сразу и сохраняется. Любой цвет можно подобрать RGB-ползунками или HEX.", 12, "sub", nil, UDim2.new(1, 0, 0, 34)) end
end
RUN.pcolors = function(c)
	local function draw() reset(c); label(c, "🌈 Цвета профиля", 20, "text", nil, UDim2.new(1, 0, 0, 28), true); M.profileCard(c, M.myCard()); M.drawColors(c, draw, "profile") end
	draw()
end
end -- конец цветов

---------------------------------------------------------------- ГАРДЕРОБ: визуальные вещи (видишь только ты), Хэллоуин
do
S.wearOwned = S.wearOwned or {}; S.wear = S.wear or {}
local folder = keep(new("Folder", {Name = "LauncherWear"}, workspace))
local function P(att, size, off, color, mat, shape, hinge, hs) return {att = att, size = size, off = off, color = color, mat = mat or Enum.Material.SmoothPlastic, shape = shape, hinge = hinge, hs = hs} end
local function wing(color, bat)
	local t = {}
	for _, side in ipairs({-1, 1}) do
		local hinge = Vector3.new(side * 0.6, 0.4, 0.5)
		for k = 0, 2 do t[#t + 1] = P("T", Vector3.new(1.4 - k * 0.25, 0.1, bat and 1.1 - k * 0.2 or 0.9), CFrame.new(side * (0.9 + k * 0.7), 0.5 + (bat and -k * 0.25 or k * 0.2), 0.7) * CFrame.Angles(0, 0, side * (bat and -0.4 * k or 0.25 * k)), color, Enum.Material.Neon, nil, hinge, side) end
	end
	return t
end
local ITEMS = {
	halo = {"😇 Нимб", 150, function() return {P("H", Vector3.new(0.12, 2.2, 2.2), CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2), C(255, 230, 120), Enum.Material.Neon, Enum.PartType.Cylinder)} end},
	crown = {"👑 Корона", 300, function()
		local t = {P("H", Vector3.new(1.4, 0.35, 1.4), CFrame.new(0, 0.85, 0), C(255, 205, 60), Enum.Material.Metal)}
		for i = 0, 4 do local a = i / 5 * math.pi * 2; t[#t + 1] = P("H", Vector3.new(0.25, 0.5, 0.25), CFrame.new(math.cos(a) * 0.55, 1.2, math.sin(a) * 0.55), C(255, 205, 60), Enum.Material.Metal) end
		return t
	end},
	ears = {"🐱 Кошачьи уши", 120, function() return {P("H", Vector3.new(0.5, 0.6, 0.15), CFrame.new(-0.45, 0.95, 0) * CFrame.Angles(0, 0, 0.3), C(255, 170, 200)), P("H", Vector3.new(0.5, 0.6, 0.15), CFrame.new(0.45, 0.95, 0) * CFrame.Angles(0, 0, -0.3), C(255, 170, 200))} end},
	horns = {"😈 Рожки", 100, function() return {P("H", Vector3.new(0.2, 0.7, 0.2), CFrame.new(-0.4, 0.95, 0) * CFrame.Angles(0, 0, 0.35), C(220, 30, 40)), P("H", Vector3.new(0.2, 0.7, 0.2), CFrame.new(0.4, 0.95, 0) * CFrame.Angles(0, 0, -0.35), C(220, 30, 40))} end},
	angel = {"🪽 Крылья ангела", 500, function() return wing(C(245, 245, 255), false) end},
	batwings = {"🦇 Крылья летучей мыши", 80, function() return wing(C(90, 40, 130), true) end, true},
	pumpkin = {"🎃 Тыква на голове", 60, function()
		return {P("H", Vector3.new(2.3, 2.3, 2.3), CFrame.new(0, 0.1, 0), C(255, 130, 20), nil, Enum.PartType.Ball), P("H", Vector3.new(0.3, 0.5, 0.3), CFrame.new(0, 1.35, 0), C(60, 130, 40)),
			P("H", Vector3.new(0.4, 0.4, 0.1), CFrame.new(-0.5, 0.3, -1.1), C(20, 10, 0), Enum.Material.Neon), P("H", Vector3.new(0.4, 0.4, 0.1), CFrame.new(0.5, 0.3, -1.1), C(20, 10, 0), Enum.Material.Neon),
			P("H", Vector3.new(1.1, 0.25, 0.1), CFrame.new(0, -0.35, -1.1), C(20, 10, 0), Enum.Material.Neon)}
	end, true},
	pack = {"🎒 Рюкзак", 90, function() return {P("T", Vector3.new(1.2, 1.6, 0.6), CFrame.new(0, 0, 0.85), C(70, 110, 200))} end},
	visor = {"🕶 Визор", 130, function() return {P("H", Vector3.new(1.35, 0.35, 0.1), CFrame.new(0, 0.05, -0.62), C(0, 230, 255), Enum.Material.Neon)} end},
	tail = {"🦊 Хвост", 110, function()
		local t = {}
		for k = 1, 4 do t[#t + 1] = P("T", Vector3.new(0.35, 0.35, 0.5), CFrame.new(0, -0.7 + k * 0.12, 0.6 + k * 0.4), k == 4 and C(255, 255, 255) or C(255, 130, 40)) end
		return t
	end},
}
M.WEAR = ITEMS
local ORDER = {"halo", "crown", "ears", "horns", "angel", "batwings", "pumpkin", "pack", "visor", "tail"}
local active = {}
local function destroyItem(id) if active[id] then for _, p in ipairs(active[id]) do p.part:Destroy() end; active[id] = nil end end
function M.applyWear()
	for _, id in ipairs(ORDER) do
		if S.wear[id] and not active[id] then
			local list = {}
			for _, spec in ipairs(ITEMS[id][3]()) do
				local p = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Size = spec.size, Color = spec.color, Material = spec.mat, Shape = spec.shape or Enum.PartType.Block}, folder)
				spec.part = p; list[#list + 1] = spec
			end
			active[id] = list
		elseif not S.wear[id] then destroyItem(id) end
	end
end
conn(RS.RenderStepped, function()
	if not next(active) then return end
	local ch = lp.Character
	if not ch then return end
	local head = ch:FindFirstChild("Head")
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	local flap = math.sin(os.clock() * 4) * 0.35
	for _, list in pairs(active) do
		for _, sp in ipairs(list) do
			local a = sp.att == "H" and head or torso
			if a then
				local cf = a.CFrame
				if sp.hinge then cf = cf * CFrame.new(sp.hinge) * CFrame.Angles(0, sp.hs * flap, 0) * CFrame.new(-sp.hinge) end
				sp.part.CFrame = cf * sp.off
			end
		end
	end
end)
task.defer(M.applyWear)
M.cleanup[#M.cleanup + 1] = function() for id in pairs(active) do destroyItem(id) end end
RUN.wardrobe = function(c)
	local function draw()
		reset(c)
		label(c, "🎭 Гардероб  ·  🪙 " .. (S.coins or 0), 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		label(c, "Вещи надеваются на твоего персонажа и видны только тебе. Можно носить несколько сразу.", 12, "sub", nil, UDim2.new(1, 0, 0, 30))
		row(c, {{"Снять всё", function() S.wear = {}; M.applyWear(); draw() end, true}})
		for _, id in ipairs(ORDER) do
			local it = ITEMS[id]
			local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
			label(fr, it[1] .. (it[4] and "  🎃" or "") .. (S.wearOwned[id] and "" or ("   🪙 " .. it[2])), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.62, 0, 1, 0), true)
			local b = button(fr, S.wear[id] and "Снять" or (S.wearOwned[id] and "Надеть" or "Купить"), function()
				if S.wearOwned[id] then S.wear[id] = (not S.wear[id]) or nil
				elseif (S.coins or 0) >= it[2] then S.coins -= it[2]; S.wearOwned[id] = true; S.wear[id] = true; toast("Куплено: " .. it[1], 2.5)
				else toast("Не хватает монет", 2.5) end
				isDirty = true; M.applyWear(); draw()
			end, UDim2.new(0.3, 0, 0, 32), not S.wear[id]); b.Position = UDim2.new(0.68, 0, 0.5, -16)
		end
	end
	draw()
end

-- Хэллоуин
local function hw() local t = os.date("*t"); return t.month == 10 or (t.month == 11 and t.day <= 7) end
M.hwActive = hw
task.spawn(function() while alive do local ic = M.icons and M.icons.halloween; if ic then ic.Visible = hw() or S.hwClaimed == true end; task.wait(2) end end)
RUN.halloween = function(c)
	local function draw()
		reset(c)
		label(c, "🎃 Хэллоуин 2026", 22, "text", nil, UDim2.new(1, 0, 0, 30), true)
		label(c, hw() and "Событие идёт до 7 ноября. Награда и вещи доступны сейчас." or "Событие закончилось, но полученное остаётся с тобой.", 13, "sub", nil, UDim2.new(1, 0, 0, 22))
		row(c, {{S.hwClaimed and "✅ Подарок получен" or "🎁 Забрать подарок (+200 🪙, значок 🎃, тема)", function()
			if S.hwClaimed or not hw() then return end
			S.hwClaimed = true; S.coins = (S.coins or 0) + 200; S.badge = "🎃"; S.owned["badge:🎃"] = true
			THEME_ORDER[#THEME_ORDER + 1] = "Хэллоуин"; isDirty = true; toast("🎃 Подарок получен!", 3); draw()
		end, S.hwClaimed}})
		row(c, {{"🎃 Включить хэллоуинский режим", function()
			S.theme = "Хэллоуин"; S.acc = 5
			if M.setSky then M.setSky("halloween") end
			S.vfx = {bats = true, pumpkins = true, fog = true, vignette = true, embers = true}; M.VFX.all(); applyAll(); draw()
		end}, {"Выключить", function() S.theme = "Тёмная"; S.acc = 1; M.setSky("none"); S.vfx = {}; M.VFX.all(); applyAll(); draw() end, true}})
		head(c, "Хэллоуинские вещи (цены события)")
		for _, id in ipairs({"pumpkin", "batwings", "horns"}) do
			local it = M.WEAR[id]
			local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 44), "card2", 12)
			label(fr, it[1] .. (S.wearOwned[id] and "" or ("   🪙 " .. it[2])), 14, "text", UDim2.new(0, 12, 0, 0), UDim2.new(0.62, 0, 1, 0), true)
			local b = button(fr, S.wear[id] and "Снять" or (S.wearOwned[id] and "Надеть" or "Купить"), function()
				if S.wearOwned[id] then S.wear[id] = (not S.wear[id]) or nil
				elseif (S.coins or 0) >= it[2] then S.coins -= it[2]; S.wearOwned[id] = true; S.wear[id] = true
				else toast("Не хватает монет", 2.5) end
				isDirty = true; M.applyWear(); draw()
			end, UDim2.new(0.3, 0, 0, 32), not S.wear[id]); b.Position = UDim2.new(0.68, 0, 0.5, -16)
		end
		label(c, "В «Визуалах» есть пресет «Хэллоуин», в «Небо» — 🎃 Хэллоуин, в «Магазине» — рамка «Огонь».", 12, "sub", nil, UDim2.new(1, 0, 0, 34))
	end
	draw()
end
end -- конец гардероба и Хэллоуина

---------------------------------------------------------------- ДОСТИЖЕНИЯ (расширенные), ПОДПИСКИ
do
S.places = S.places or {}; S.themesUsed = S.themesUsed or {}; S.follows = S.follows or {}; S.appsUsed = S.appsUsed or {}
local function cnt(t) local n = 0; for _ in pairs(t or {}) do n += 1 end; return n end
local function has(t) return function() return cnt(t()) end end
local GAMES = {g2048 = 1, snake = 1, pacman = 1, ttt = 1, mines = 1, memory = 1, flappy = 1}
local SP = {
	{"friend1", "🤝 Первый друг", "Добавь друга", function() return #M.NET.friends, 1 end}, {"friend5", "🤝 Душа компании", "5 друзей", function() return #M.NET.friends, 5 end},
	{"follow", "🔔 Подписчик", "Подпишись на игрока", function() return cnt(S.follows), 1 end}, {"admin", "🛡 Встретил админа", "Будь на сервере с админом", function() return S.metAdmin and 1 or 0, 1 end},
	{"creator", "👑 Встретил создателя", "Будь на сервере с создателем", function() return S.metCreator and 1 or 0, 1 end}, {"phone", "📱 На связи", "Купи телефон", function() return S.owned.phone and 1 or 0, 1 end},
	{"call", "📞 Первый звонок", "Позвони другу", function() return S.callsMade or 0, 1 end}, {"pet", "🐾 Хозяин", "Заведи питомца", function() return cnt(S.petOwned), 1 end},
	{"zoo", "🦁 Зоопарк", "Собери всех 7 питомцев", function() return cnt(S.petOwned), 7 end}, {"coins1", "🪙 Копилка", "100 монет", function() return S.coins or 0, 100 end},
	{"coins2", "💰 Богач", "5000 монет", function() return S.coins or 0, 5000 end}, {"lv5", "⭐ Уровень 5", "Достигни 5 уровня", function() return M.level(), 5 end},
	{"lv10", "🌟 Уровень 10", "Достигни 10 уровня", function() return M.level(), 10 end}, {"lv25", "💫 Уровень 25", "Достигни 25 уровня", function() return M.level(), 25 end},
	{"tracks", "🎵 Меломан", "Включи 10 треков", function() return M.MU and M.MU.tok or 0, 10 end}, {"pl", "📂 Плейлист", "Создай плейлист", function() return #(M.MS and M.MS.pls or {}), 1 end},
	{"spotify", "🟢 Spotify", "Подключи Spotify", function() return (M.MS and M.MS.sp.refresh) and 1 or 0, 1 end}, {"owl", "🦉 Ночная сова", "Зайди ночью (0–5 ч)", function() local h = tonumber(os.date("%H")); return (h >= 0 and h < 5) and 1 or (S.owl and 1 or 0), 1 end},
	{"theme", "🎨 Дизайнер", "Попробуй 5 тем", function() return cnt(S.themesUsed), 5 end}, {"vfx", "🎆 Визуальщик", "Включи 5 визуалов", function() return cnt(S.vfx), 5 end},
	{"places", "🌍 Путешественник по играм", "Зайди в 5 разных игр", function() return cnt(S.places), 5 end}, {"notes", "📝 Писатель", "5 заметок", function() return #(S.noteList or {}), 5 end},
	{"apps", "🧭 Исследователь", "Открой 15 приложений", function() return cnt(S.appsUsed), 15 end}, {"games", "🎮 Игрок", "Попробуй 5 мини-игр", function()
		local n = 0; for k in pairs(S.appsUsed) do if GAMES[k] then n += 1 end end; return n, 5 end},
	{"wear", "🎭 Модник", "Надень 3 вещи", function() return cnt(S.wear), 3 end}, {"net", "🌐 В сети", "Подключись к серверу скрипта", function() return M.NET.ok and 1 or 0, 1 end},
	{"ai", "🤖 С ИИ на «ты»", "Задай вопрос ИИ", function() return S.aiAsked or 0, 1 end}, {"halloween", "🎃 Хэллоуин 2026", "Забери хэллоуинский подарок", function() return S.hwClaimed and 1 or 0, 1 end},
}
M.SP = SP
task.spawn(function()
	while alive do
		task.wait(4)
		S.places[tostring(game.PlaceId)] = true; S.themesUsed[S.theme] = true
		if tonumber(os.date("%H")) < 5 then S.owl = true end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then
				local r = M.roleFor and M.roleFor(p)
				if r == "admin" or r == "owner" or r == "creator" then S.metAdmin = true end
				if r == "creator" or r == "owner" then S.metCreator = true end
			end
		end
		for _, a in ipairs(SP) do
			local ok, cur, tg = pcall(a[4])
			if ok and cur >= tg and not S.medals[a[1]] then
				S.medals[a[1]] = true; S.coins = (S.coins or 0) + 25; isDirty = true
				M.notify("🏅 Достижение: " .. a[2] .. "  (+25 🪙)", 5)
			end
		end
	end
end)
conn(Players.PlayerAdded, function(p)
	if S.follows[tostring(p.UserId)] then M.notify("🔔 " .. p.DisplayName .. " зашёл в твой сервер", 5) end
end)
local lastOn, first = {}, true
function M.onPresence(users)
	local now = {}
	for _, u in ipairs(users) do
		local k = tostring(u.uid)
		now[k] = true
		if S.follows[k] and not lastOn[k] and not first then M.notify("🔔 " .. tostring(u.display or u.name) .. " теперь в сети со скриптом", 5) end
	end
	lastOn = now; first = false
end
RUN.ach = function(c)
	local done = 0
	for _, a in ipairs(SP) do if S.medals[a[1]] then done += 1 end end
	label(c, "🏅 Достижения  " .. done .. " / " .. #SP, 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
	label(c, "За каждое достижение +25 🪙. Убийства считаются, если игра ставит стандартную метку «creator» на Humanoid.", 12, "sub", nil, UDim2.new(1, 0, 0, 32))
	for _, a in ipairs(SP) do
		local ok, cur, tg = pcall(a[4])
		cur, tg = ok and cur or 0, ok and tg or 1
		local got = S.medals[a[1]]
		local fr = frame(c, UDim2.new(), UDim2.new(1, 0, 0, 56), "card2", 12)
		label(fr, (got and "✅ " or "🔒 ") .. a[2], 14, "text", UDim2.new(0, 12, 0, 4), UDim2.new(1, -24, 0, 20), true)
		label(fr, a[3] .. "  ·  " .. math.min(math.floor(cur), tg) .. " / " .. tg, 12, "sub", UDim2.new(0, 12, 0, 24), UDim2.new(1, -24, 0, 16))
		local bar = frame(fr, UDim2.new(0, 12, 1, -12), UDim2.new(1, -24, 0, 6), "card", 3)
		frame(bar, UDim2.new(), UDim2.new(math.clamp(cur / tg, 0, 1), 0, 1, 0), "acc", 3)
	end
	head(c, "Счётчики")
	for _, m in ipairs(M.MEDALS or {}) do
		local v = m[4]()
		local got = 0
		for lvl, th in ipairs(m[3]) do if v >= th then got = lvl end end
		label(c, m[2] .. " " .. (got > 0 and ({"🥉", "🥈", "🥇"})[got] or "—") .. "  ·  " .. math.floor(v) .. " " .. m[5], 13, "text", nil, UDim2.new(1, 0, 0, 20))
	end
	row(c, {{"Сбросить K/D", function() S.kills, S.deaths = 0, 0; isDirty = true end, true}})
end
end -- конец достижений

---------------------------------------------------------------- ИИ-ПОМОЩНИК (свой API-ключ) + КОМАНДНАЯ СТРОКА
do
local AF = "L3D_" .. lp.UserId .. "_ai.json"
local AI = {cfg = {provider = "claude", model = "claude-haiku-5-5", url = "https://api.openai.com/v1/chat/completions", key = ""}, hist = {}}
local function okey() return hash(tostring(lp.UserId) .. "L3D-ai") end
local function obf(s) local k, o = okey(), {}; for i = 1, #s do o[i] = string.format("%02x", bit32.bxor(s:byte(i), k:byte((i - 1) % #k + 1))) end; return table.concat(o) end
local function deobf(h) local k, o, n = okey(), {}, 0; for i = 1, #h - 1, 2 do n += 1; o[n] = string.char(bit32.bxor(tonumber(h:sub(i, i + 1), 16) or 0, k:byte((n - 1) % #k + 1))) end; return table.concat(o) end
if readfile and isfile and isfile(AF) then
	pcall(function() local d = HS:JSONDecode(readfile(AF)); for k, v in pairs(d) do AI.cfg[k] = v end; if d.key then AI.cfg.key = deobf(d.key) end end)
end
local function saveAI() if writefile then pcall(function() local t = {}; for k, v in pairs(AI.cfg) do t[k] = v end; t.key = obf(AI.cfg.key or ""); writefile(AF, HS:JSONEncode(t)) end) end end
local SYS = "Ты ИИ-помощник внутри Roblox-скрипта Visualesered (канал t.me/Visualesered). Отвечай кратко и по-русски, если не просят иначе. Ты не можешь запускать код и менять скрипт, только объяснять, переводить, придумывать идеи и помогать с вопросами."
local function ask(messages, system)
	local rq = request or http_request or (syn and syn.request)
	if not rq then return nil, "в инжекторе нет request" end
	local cfg = AI.cfg
	if (cfg.key or "") == "" then return nil, "не введён API-ключ" end
	local url, headers, body
	if cfg.provider == "claude" then
		url = "https://api.anthropic.com/v1/messages"
		headers = {["x-api-key"] = cfg.key, ["anthropic-version"] = "2023-06-01", ["content-type"] = "application/json"}
		body = {model = cfg.model, max_tokens = 1500, system = system or SYS, messages = messages}
	else
		url = cfg.url
		headers = {Authorization = "Bearer " .. cfg.key, ["content-type"] = "application/json"}
		local m = {{role = "system", content = system or SYS}}
		for _, x in ipairs(messages) do m[#m + 1] = x end
		body = {model = cfg.model, messages = m, max_tokens = 1500}
	end
	local ok, res = pcall(rq, {Url = url, Method = "POST", Headers = headers, Body = HS:JSONEncode(body)})
	if not ok or not res then return nil, "запрос не прошёл" end
	local ok2, d = pcall(HS.JSONDecode, HS, res.Body)
	if res.StatusCode ~= 200 then return nil, "HTTP " .. tostring(res.StatusCode) .. ((ok2 and d.error and d.error.message) and (": " .. tostring(d.error.message)) or "") end
	if not ok2 then return nil, "ответ не JSON" end
	local txt = cfg.provider == "claude" and (d.content and d.content[1] and d.content[1].text) or (d.choices and d.choices[1] and d.choices[1].message and d.choices[1].message.content)
	return txt, txt and nil or "пустой ответ"
end
M.AIask = ask
RUN.ai = function(c)
	local me = c
	local view = M.aiView or "chat"
	local draw
	function draw()
		reset(c)
		label(c, "🤖 ИИ-помощник", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		row(c, {{"💬 Чат", function() M.aiView = "chat"; view = "chat"; draw() end, view ~= "chat"}, {"🌐 Перевод слов песни", function() M.aiView = "tr"; view = "tr"; draw() end, view ~= "tr"}, {"⚙ Ключ", function() M.aiView = "set"; view = "set"; draw() end, view ~= "set"}})
		if view == "set" then
			label(c, "Нужен твой собственный API-ключ: Claude (console.anthropic.com) или любой OpenAI-совместимый сервис. Ключ хранится на диске обфусцированным (это не шифрование), в игре не показывается, запросы идут напрямую в сервис.", 12, "sub", nil, UDim2.new(1, 0, 0, 74))
			row(c, {{"Claude (Anthropic)", function() AI.cfg.provider = "claude"; AI.cfg.model = "claude-haiku-5-5"; saveAI(); draw() end, AI.cfg.provider ~= "claude"}, {"OpenAI-совместимый", function() AI.cfg.provider = "openai"; AI.cfg.model = "gpt-4o-mini"; saveAI(); draw() end, AI.cfg.provider ~= "openai"}})
			local mt = textbox(c, "модель", AI.cfg.model, 36)
			mt.FocusLost:Connect(function() AI.cfg.model = mt.Text; saveAI() end)
			if AI.cfg.provider ~= "claude" then local ut = textbox(c, "URL (…/v1/chat/completions)", AI.cfg.url, 36); ut.FocusLost:Connect(function() AI.cfg.url = ut.Text; saveAI() end) end
			local kt = textbox(c, (AI.cfg.key ~= "") and "ключ сохранён (введи новый, чтобы заменить)" or "вставь API-ключ", "", 36)
			row(c, {{"Сохранить ключ", function() if kt.Text ~= "" then AI.cfg.key = (kt.Text:gsub("%s+", "")); saveAI(); toast("Ключ сохранён", 2); draw() end end}, {"Удалить ключ", function() AI.cfg.key = ""; saveAI(); draw() end, true}})
			label(c, AI.cfg.key ~= "" and "✅ Ключ задан" or "⚠ Ключ не задан", 13, "text", nil, UDim2.new(1, 0, 0, 20))
		elseif view == "tr" then
			local tr = M.MU and M.MU.list[M.MU.idx]
			label(c, tr and ("Трек: " .. tr.name) or "Сначала включи трек с найденными словами (вкладка «Музыка»).", 14, "text", nil, UDim2.new(1, 0, 0, 24), true)
			local langs = {{"Русский", "русский"}, {"English", "английский"}, {"Español", "испанский"}, {"Deutsch", "немецкий"}, {"Français", "французский"}, {"日本語", "японский"}, {"한국어", "корейский"}, {"中文", "китайский"}, {"Türkçe", "турецкий"}}
			local defs = {}
			for _, l in ipairs(langs) do
				defs[#defs + 1] = {l[1], function()
					if not (tr and (tr.lrc or "") ~= "") then toast("У трека нет слов", 2.5); return end
					toast("Перевожу…", 3)
					task.spawn(function()
						local txt, err = ask({{role = "user", content = "Переведи слова песни на " .. l[2] .. " язык. Сохрани строки и метки времени вида [00:12.50] без изменений, переводи только текст. Верни только результат.\n\n" .. tr.lrc}}, "Ты переводчик текстов песен.")
						if txt then tr.lrcOrig = tr.lrcOrig or tr.lrc; tr.lrc = txt; M.MU.lyr = nil; toast("Слова переведены", 3) else toast("Ошибка: " .. tostring(err), 4) end
					end)
				end, true}
			end
			chunk(c, defs, 3)
			row(c, {{"↩ Вернуть оригинал", function() if tr and tr.lrcOrig then tr.lrc = tr.lrcOrig; toast("Оригинал возвращён", 2) end end, true}})
			label(c, "Это перевод готовых слов (с lrclib). Распознавать речь из аудио ИИ здесь не может. После перевода перезапусти трек.", 12, "sub", nil, UDim2.new(1, 0, 0, 44))
		else
			local box = new("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 230), BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, c)
			bind(box, "BackgroundColor3", "card"); round(box, 12)
			new("UIListLayout", {Padding = UDim.new(0, 6)}, box); new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, box)
			for _, m in ipairs(AI.hist) do
				local l = label(box, (m.role == "user" and "Ты: " or "ИИ: ") .. m.content, 14, m.role == "user" and "sub" or "text", nil, UDim2.new(1, -8, 0, 0))
				l.AutomaticSize = Enum.AutomaticSize.Y
			end
			task.defer(function() if box.Parent then box.CanvasPosition = Vector2.new(0, 1e6) end end)
			local ir = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
			local tb = textbox(ir, "Спроси что угодно…", "", 40); tb.Size = UDim2.new(1, -92, 1, 0)
			local function send()
				local t = tb.Text
				if t == "" then return end
				AI.hist[#AI.hist + 1] = {role = "user", content = t}
				tb.Text = ""; S.aiAsked = (S.aiAsked or 0) + 1
				draw()
				task.spawn(function()
					local msgs = {}
					for i = math.max(1, #AI.hist - 12), #AI.hist do msgs[#msgs + 1] = {role = AI.hist[i].role, content = AI.hist[i].content} end
					local txt, err = ask(msgs)
					AI.hist[#AI.hist + 1] = {role = "assistant", content = txt or ("⚠ " .. tostring(err))}
					if content == me then draw() end
				end)
			end
			local sb = button(ir, "Отпр.", send, UDim2.fromOffset(84, 40)); sb.Position = UDim2.new(1, -84, 0, 0)
			tb.FocusLost:Connect(function(enter) if enter then send() end end)
			row(c, {{"Очистить чат", function() AI.hist = {}; draw() end, true}})
		end
	end
	draw()
end

-- командная строка (в стиле известных админ-скриптов)
local out = {}
local CMD
CMD = {
	help = function() return "fly, unfly, noclip, clip, esp, unesp, speed N, jump N, fov N, grav N, tp ИМЯ, to ИМЯ, view ИМЯ, unview, time N, bright, rejoin, reset, sit, hide, show" end,
	fly = function() S.fly = true; applyAll(); return "полёт вкл" end, unfly = function() S.fly = false; applyAll(); return "полёт выкл" end,
	noclip = function() S.noclip = true; applyAll(); return "ноуклип вкл" end, clip = function() S.noclip = false; applyAll(); return "ноуклип выкл" end,
	esp = function() S.esp = true; applyAll(); return "ESP вкл" end, unesp = function() S.esp = false; applyAll(); return "ESP выкл" end,
	speed = function(a) local h = hum(); local n = tonumber(a); if h and n then S.speedVal = n; S.holdSpeed = true; h.WalkSpeed = n; return "скорость " .. n end return "нужно число" end,
	jump = function(a) local h = hum(); local n = tonumber(a); if h and n then S.jumpVal = n; S.holdJump = true; h.UseJumpPower = true; h.JumpPower = n; return "прыжок " .. n end return "нужно число" end,
	fov = function(a) local n = tonumber(a); if n then S.fov = n; return "FOV " .. n end return "нужно число" end,
	grav = function(a) local n = tonumber(a); if n then S.grav = n; applyAll(); return "гравитация " .. n end return "нужно число" end,
	time = function(a) local n = tonumber(a); if n then Lighting.ClockTime = n; return "время " .. n end return "нужно число" end,
	bright = function() S.bright = not S.bright; applyAll(); return "яркость " .. (S.bright and "вкл" or "выкл") end,
	rejoin = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end); return "перезаход…" end,
	reset = function() local h = hum(); if h then h.Health = 0 end return "сброс" end,
	sit = function() local h = hum(); if h then h.Sit = true end return "сел" end,
	hide = function() if lp.Character then for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end end return "персонаж скрыт (только у тебя)" end,
	show = function() if lp.Character then for _, d in ipairs(lp.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end end return "показан" end,
}
local function findPlayer(n) n = (n or ""):lower(); for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower():find(n, 1, true) or p.DisplayName:lower():find(n, 1, true) then return p end end end
CMD.tp = function(a) local p = findPlayer(a); local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if r then tpTo(r.Position); return "тп к " .. p.DisplayName end return "игрок не найден" end
CMD.to = CMD.tp
CMD.view = function(a) local p = findPlayer(a); if p and M.spectate(p) then return "смотришь на " .. p.DisplayName end return "игрок не найден" end
CMD.unview = function() M.stopSpectate(); return "камера возвращена" end
RUN.cmd = function(c)
	local me = c
	local lbl
	local function draw()
		reset(c)
		label(c, "⌨ Командная строка", 20, "text", nil, UDim2.new(1, 0, 0, 28), true)
		local tb = textbox(c, "команда, например: speed 50 или tp ник  (help — список)", "", 38)
		local function run()
			local t = tb.Text
			if t == "" then return end
			local name, arg = t:match("^;?(%S+)%s*(.*)$")
			local f = name and CMD[name:lower()]
			local ok, res = true, "неизвестная команда (help)"
			if f then ok, res = pcall(f, arg) end
			table.insert(out, 1, "> " .. t .. "\n" .. tostring(ok and res or ("ошибка: " .. tostring(res))))
			if #out > 12 then out[13] = nil end
			tb.Text = ""; draw()
		end
		tb.FocusLost:Connect(function(enter) if enter then run() end end)
		row(c, {{"▶ Выполнить", run}, {"help", function() tb.Text = "help"; run() end, true}})
		for _, o in ipairs(out) do label(c, o, 13, "text", nil, UDim2.new(1, 0, 0, 40)) end
	end
	draw()
end
end -- конец ИИ и команд

---------------------------------------------------------------- настройки
do
local setPage = scrollPage("set")
local setCat = "ui"
local CATS = {{"ui", "🎨 Вид"}, {"d3", "🧊 Меню 3D"}, {"btn", "🔘 Кнопка"}, {"hud", "📊 HUD"}, {"func", "⚙️ Функции"},
	{"wx", "🌧 Погода"}, {"world", "🌍 Мир"}, {"hero", "🧍 Персонаж"}, {"snd", "🔊 Звук"}, {"keys", "⌨️ Клавиши"}, {"cfg", "💾 Конфиг и сеть"}, {"gfx", "🎚 Графика"}, {"colors", "🎨 Цвета"}}
local KEYDEF = M.KEYDEF

function applyAll()
	isDirty = true
	applyView(); applyButton(); applyHud(); applyWorld(); applyWeather(); applyChar(); applyFunctions(); applyTheme()
	if M.applyOrbit then M.applyOrbit() end
	if M.applySound then M.applySound() end
	if M.applyGfx then M.applyGfx() end
	if M.applyMenuBg then M.applyMenuBg() end
	if M.applyParticles then M.applyParticles() end
	if S.rim == "off" then for _, st in ipairs(rimStrokes) do st.Transparency = 0.35 end end
end

function M.party()
	S.gold = true; S.theme = "Золото"
	local pw, pr = S.weather, S.rim
	S.weather = "confetti"; S.rim = "rainbow"
	applyAll(); toast("🥚 Секрет найден! Тема «Золото» открыта", 5)
	task.delay(8, function() S.weather = pw; S.rim = pr; applyAll() end)
end

function drawSettings()
	local c = setPage
	reset(c)
	local cd = {}
	for _, k in ipairs(CATS) do cd[#cd + 1] = {k[2], function() setCat = k[1]; drawSettings() end, setCat ~= k[1]} end
	chunk(c, cd, 3)

	if setCat == "ui" then
		head(c, "Тема")
		local order = {table.unpack(THEME_ORDER)}
		if S.gold then order[#order + 1] = "Золото" end
		local th = {}
		for _, name in ipairs(order) do th[#th + 1] = {name, function() S.theme = name; applyAll(); drawSettings() end, S.theme ~= name} end
		chunk(c, th, 4)
		head(c, "Цвет акцента")
		local ar = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, ar)
		for k, color in ipairs(ACCENTS) do
			local b = new("TextButton", {Text = S.acc == k and "✓" or "", TextSize = 18, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(0, 0, 0),
				BackgroundColor3 = color, Size = UDim2.fromOffset(38, 38), BorderSizePixel = 0}, ar)
			round(b, 19)
			tap(b, function() S.acc = k; applyAll(); drawSettings() end)
		end
		head(c, "Вид приложений"); row(c, {opt("Сетка", "view", "grid"), opt("Список", "view", "list")})
		head(c, "Форма значков"); row(c, {opt("Скруглённые", "shape", "round"), opt("Круг", "shape", "circle"), opt("Квадрат", "shape", "square")})
		head(c, "Размер значков"); row(c, {opt("S", "size", "S"), opt("M", "size", "M"), opt("L", "size", "L")})
		head(c, "Прозрачность панелей"); row(c, {opt("0%", "alpha", 0), opt("15%", "alpha", 0.15), opt("30%", "alpha", 0.3), opt("50%", "alpha", 0.5)})
		head(c, "Рамка панелей"); row(c, {opt("Обычная", "rim", "off"), opt("Радуга", "rim", "rainbow"), opt("Пульс", "rim", "pulse")})
		head(c, "Прочее")
		row(c, {tog("Подписи", "labels"), tog("Виджеты", "widgets")})
		row(c, {tog("Градиент панелей", "grad"), tog("Анимация кнопок", "hover")})
		row(c, {{"Сбросить порядок значков", function() S.iconPos = {}; toast("Порядок сбросится после перезапуска скрипта", 3) end, true}})
		label(c, "Устройство: " .. deviceName .. " — размеры подобраны автоматически при первом запуске.", 13, "sub", nil, UDim2.new(1, 0, 0, 20))

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
		head(c, "Анимация открытия (больше — в приложении «Анимации»)")
		local a = {}
		for _, s in ipairs(M.OA_ORDER) do a[#a + 1] = opt(s[2], "openAnim", s[1]) end
		chunk(c, a, 4)
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
		row(c, {{"Вернуть в угол", function() S.btnPosX = 20; S.btnPosY = 100; applyButton(); isDirty = true end, true}})

	elseif setCat == "hud" then
		row(c, {tog("HUD", "hud")})
		head(c, "Что показывать")
		row(c, {tog("FPS", "hudFps"), tog("Пинг", "hudPing")})
		row(c, {tog("Инжектор", "hudExec"), tog("Память", "hudMem")})
		row(c, {tog("Время", "hudTime"), tog("Игроки", "hudPlayers")})
		row(c, {tog("K/D счётчик", "wKD"), tog("Флип-часы", "wClock")})
		row(c, {tog("Бинды на экране (когда меню скрыто)", "bindHud")})
		head(c, "Вид")
		row(c, {opt("В строку", "hudStack", false), opt("Столбиком", "hudStack", true)})
		stepRow(c, "Масштаб", "hudScale", 0.1, 0.6, 2, pct)
		head(c, "Прозрачность фона"); row(c, {opt("0%", "hudAlpha", 0), opt("25%", "hudAlpha", 0.25), opt("50%", "hudAlpha", 0.5), opt("75%", "hudAlpha", 0.75)})
		row(c, {tog("Цвет по качеству (зелёный/жёлтый/красный)", "hudColor")})
		label(c, "Инжектор: " .. execName .. ". Панель видна всегда и тянется по экрану.", 13, "sub", nil, UDim2.new(1, 0, 0, 40))
		row(c, {{"Вернуть HUD в угол", function() S.hudPosX = 12; S.hudPosY = 12; applyHud(); isDirty = true end, true}})

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
		label(c, "Подробные настройки ESP — на вкладке «👁 ESP».", 13, "sub", nil, UDim2.new(1, 0, 0, 20))
		head(c, "Камера и прочее")
		row(c, {tog("Отдалять без лимита", "zoomUnlock"), tog("Первое лицо", "fpLock")})
		row(c, {tog("Только 3-е лицо", "tpLock"), tog("Анти-флинг", "antiFling")})
		row(c, {tog("Автоклик", "aclick"), tog("Анти-АФК", "antiafk")})
		stepRow(c, "Кликов в секунду", "acps", 1, 1, 30, num)
		row(c, {tog("Прицел", "cross"), tog("Буст FPS", "boost")})

	elseif setCat == "wx" then
		head(c, "Погода вокруг тебя")
		head(c, "Включай несколько сразу")
		local w = {{"🚫 Выключить всё", function() S.wx = {}; applyAll(); drawSettings() end, true}}
		for _, k in ipairs(W_ORDER) do w[#w + 1] = M.setTog(WEATHER[k][1], S.wx, k) end
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
		label(c, "Экранные визуалы (19 штук) — в приложении «Визуалы».", 13, "sub", nil, UDim2.new(1, 0, 0, 20))

	elseif setCat == "hero" then
		head(c, "След за персонажем"); row(c, {tog("Радужный след", "trail")})
		head(c, "Аура (можно несколько)")
		row(c, {M.setTog("🔥 Огонь", S.auras, "fire"), M.setTog("💨 Дым", S.auras, "smoke"), M.setTog("☣ Токсик", S.auras, "toxic")})
		row(c, {M.setTog("❄ Лёд", S.auras, "ice"), M.setTog("✨ Искры", S.auras, "sparkles"), M.setTog("🔮 Сферы", S.auras, "orbs")})
		head(c, "Свечение вокруг")
		row(c, {opt("Нет", "glow", 0), opt("Слабое", "glow", 1), opt("Сильное", "glow", 2)})
		head(c, "Эффект при прыжке (можно несколько)")
		row(c, {M.setTog("Круг", S.jumpSet, "ring"), M.setTog("Двойной", S.jumpSet, "double"), M.setTog("Столб", S.jumpSet, "pillar")})
		row(c, {M.setTog("Взрыв искр", S.jumpSet, "burst"), M.setTog("Пыль", S.jumpSet, "dust"), M.setTog("Спираль", S.jumpSet, "spiral")})
		label(c, "Цвет берётся из акцента. Анимации вокруг персонажа — в приложении «Анимации».", 13, "sub", nil, UDim2.new(1, 0, 0, 36))

	elseif setCat == "snd" then
		row(c, {tog("🔊 Звук скрипта", "sound"), tog("Клики интерфейса", "uiClick")})
		row(c, {tog("Мини-плеер на экране", "miniPlayer")})
		stepRow(c, "Громкость музыки", "mVol", 0.1, 0, 1, pct)
		label(c, "Плеер и слова на экране — в приложении «Музыка».", 13, "sub", nil, UDim2.new(1, 0, 0, 20))

	elseif setCat == "colors" then
		M.drawColors(c, drawSettings, "all")

	elseif setCat == "gfx" then
		M.drawGfx(c, drawSettings)

	elseif setCat == "cfg" then
		M.drawCfg(c, drawSettings)

	elseif setCat == "keys" then
		head(c, "Нажми на кнопку, затем нужную клавишу (Esc — отмена)")
		for _, k in ipairs(KEYDEF) do
			row(c, {{k[2] .. ": " .. (listeningKey == k[1] and "нажми клавишу…" or S.keys[k[1]]), function() listeningKey = k[1]; drawSettings() end, listeningKey ~= k[1]}})
		end
		row(c, {{"Сбросить клавиши", function() S.keys = {}; for k, v in pairs(M.DEFKEYS) do S.keys[k] = v end; listeningKey = nil; drawSettings() end, true}})
		label(c, "Масштаб меню: клавиши «+» и «−».", 13, "sub", nil, UDim2.new(1, 0, 0, 24))
	end
end

---------------------------------------------------------------- главный цикл
local CYCLE = {0.05, 0.25, 1.2}
local fps, facc, fn = 60, 0, 0
conn(RS.RenderStepped, function(dt)
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	facc += dt; fn += 1
	if facc >= 0.5 then fps = math.floor(fn / facc); facc, fn = 0, 0 end
	local fv = S.drone and S.droneFov or S.fov
	if fv then cam.FieldOfView = fv end
	local fp = cam.Focus.Position
	fxTop.CFrame = CFrame.new(fp + Vector3.new(0, 38, 0)); fxLow.CFrame = CFrame.new(fp + Vector3.new(0, -2, 0))
	if S.cycle > 0 then Lighting.ClockTime = (Lighting.ClockTime + dt * CYCLE[S.cycle]) % 24 end
	local t = os.clock()
	if S.rim == "rainbow" then
		for k, st in ipairs(rimStrokes) do st.Color = Color3.fromHSV((t * 0.12 + k * 0.1) % 1, 0.65, 1); st.Transparency = 0.2 end
	elseif S.rim == "pulse" then
		for _, st in ipairs(rimStrokes) do st.Transparency = 0.15 + 0.4 * (0.5 + 0.5 * math.sin(t * 3)) end
	end
	if not open then return end
	animT = math.min(1, animT + dt / 0.45)
	local th = math.tan(math.rad(cam.FieldOfView) / 2)
	dist = math.max(MW / (2 * th * (vp.X / vp.Y) * 0.92), MH / (2 * th * 0.88)) / S.zoom
	local offcf, dm = (M.OA[S.openAnim] or M.OA.zoom)(animT)
	local d = dist * dm
	local px, py = 0, 0
	if S.parallax then
		local m = UIS:GetMouseLocation()
		px = math.clamp(m.X / vp.X - 0.5, -0.5, 0.5); py = math.clamp(m.Y / vp.Y - 0.5, -0.5, 0.5)
	end
	local target3 = cam.CFrame * CFrame.new(offX, offY, -d) * offcf * CFrame.Angles(0, math.pi, 0)
		* CFrame.Angles(math.rad(py * 2), math.rad(S.tilt + px * 3), 0)
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
			wv[2].Text = string.sub(lp.DisplayName, 1, 9); wv[12].Text = "Lv " .. M.level() .. " · игроков " .. #Players:GetPlayers()
			wv[3].Text = tostring(fps); wv[13].Text = "кадров/с"
			wv[4].Text = getPing() .. " мс"; wv[14].Text = "задержка"
			wv[5].Text = execName; wv[15].Text = deviceName
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
	if not v then
		local h = hum(); if h and not S.fly then h.PlatformStand = false end
	elseif M.espRefresh then
		task.defer(M.espRefresh)
	end
end

local function zoomBy(d)
	S.zoom = math.clamp(math.floor((S.zoom + d) * 100 + 0.5) / 100, 0.5, 2)
	if setCat == "d3" then drawSettings() end
end
local KONAMI = {Enum.KeyCode.Up, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.B, Enum.KeyCode.A}
local kpos = 0
conn(UIS.InputBegan, function(i, gp)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if UIS:GetFocusedTextBox() then return end
	if listeningKey then
		if i.KeyCode == Enum.KeyCode.Backspace then S.keys[listeningKey] = ""
		elseif i.KeyCode ~= Enum.KeyCode.Escape then S.keys[listeningKey] = i.KeyCode.Name end
		listeningKey = nil; isDirty = true
		pcall(drawSettings)
		if M.redrawBinds and content then pcall(M.redrawBinds) end
		return
	end
	if i.KeyCode == KONAMI[kpos + 1] then
		kpos += 1
		if kpos == #KONAMI then kpos = 0; M.party() end
	else
		kpos = (i.KeyCode == KONAMI[1]) and 1 or 0
	end
	if gp then return end
	local k = i.KeyCode
	if k.Name == S.keys.menu then setOpen(not open)
	elseif k.Name == S.keys.fly then S.fly = not S.fly; applyAll()
	elseif k.Name == S.keys.noclip then S.noclip = not S.noclip; applyAll()
	elseif k.Name == S.keys.esp then S.esp = not S.esp; applyAll()
	elseif k.Name == S.keys.hud then S.hud = not S.hud; applyAll()
	elseif k.Name == S.keys.fp then S.fpLock = not S.fpLock; if S.fpLock then S.tpLock = false end; applyAll()
	elseif k.Name == S.keys.tpv then S.tpLock = not S.tpLock; if S.tpLock then S.fpLock = false end; applyAll()
	elseif k.Name == S.keys.drone then M.DR.set(not S.drone); applyAll()
	elseif k.Name == S.keys.tpto then M.rayTp()
	elseif k.Name == S.keys.noPart then S.noParticles = not S.noParticles; applyAll(); toast("Партиклы: " .. (S.noParticles and "скрыты" or "показаны"), 1.5)
	elseif k.Name == S.keys.photo then M.photo()
	elseif k.Name == S.keys.freecam then M.freecam(not M.fcOn())
	elseif k.Name == S.keys.mini then S.miniPlayer = not S.miniPlayer; isDirty = true
	elseif k.Name == S.keys.aclick then S.aclick = not S.aclick; applyAll(); toast("Автоклик: " .. (S.aclick and "ВКЛ" or "ВЫКЛ"), 1.5)
	elseif open and (k == Enum.KeyCode.Equals or k == Enum.KeyCode.KeypadPlus) then zoomBy(0.1)
	elseif open and (k == Enum.KeyCode.Minus or k == Enum.KeyCode.KeypadMinus) then zoomBy(-0.1) end
end)
end -- конец настроек и цикла

---------------------------------------------------------------- очистка при повторном запуске
ENV.__Launcher3D_cleanup = function()
	alive = false
	if isDirty and writefile then pcall(function() writefile(SAVEFILE, HS:JSONEncode(clean(S))) end) end
	for _, f in ipairs(M.cleanup) do pcall(f) end
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
	if hrp then for _, o in ipairs(hrp:GetChildren()) do if string.sub(o.Name, 1, 10) == "LauncherFx" then pcall(function() o:Destroy() end) end end end
end

task.defer(applyChar)
drawSettings()
applyAll()
task.spawn(function() M.VFX.all() end)
show("home")
setOpen(true)
M.load(100, "Готово")

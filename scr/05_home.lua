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

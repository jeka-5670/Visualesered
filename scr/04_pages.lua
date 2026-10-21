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
local logText  = label(info, "", 16, "text", nil, UDim2.new(1, 0, 0, 100))
local function showLog(k) logTitle.Text = LOGS[k][1]; logText.Text = LOGS[k][2]; show("info") end
for k, e in ipairs(LOGS) do
	local b = button(logList, e[1], function() showLog(k) end, UDim2.new(1, 0, 0, 36), true)
	b.TextSize = 14; b.TextXAlignment = Enum.TextXAlignment.Left
	new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
end
showLog(1)

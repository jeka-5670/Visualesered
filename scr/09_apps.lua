---------------------------------------------------------------- приложения
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
RUN.config = function(c)
	local function draw()
		reset(c)
		label(c, "📁 Сохранения и Конфиги", 22, "text", nil, UDim2.new(1, 0, 0, 30), true)
		local tb = new("TextBox", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = col("card2"), TextColor3 = col("text"), PlaceholderText = "Имя конфига (например: my_settings)", Text = "", Font = Enum.Font.Gotham, BorderSizePixel = 0}, c)
		round(tb, 10)
		new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, tb)
		row(c, {
			{"💾 Сохранить", function()
				if writefile then
					local cfg = {}
					for k, v in pairs(S) do
						if type(v) ~= "table" and type(v) ~= "userdata" and type(v) ~= "function" then cfg[k] = v end
					end
					writefile("L3D_" .. tb.Text .. ".json", game:GetService("HttpService"):JSONEncode(cfg))
					warn("Конфиг сохранен!")
				else warn("Твой инжектор не поддерживает сохранения (writefile)") end
			end},
			{"📂 Загрузить", function()
				if readfile and isfile and isfile("L3D_" .. tb.Text .. ".json") then
					local data = game:GetService("HttpService"):JSONDecode(readfile("L3D_" .. tb.Text .. ".json"))
					for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
					applyAll(); drawSettings(); draw()
					warn("Конфиг успешно загружен!")
				else warn("Конфиг с таким именем не найден") end
			end, true}
		})
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

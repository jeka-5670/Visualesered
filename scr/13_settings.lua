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

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

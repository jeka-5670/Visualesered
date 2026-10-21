---------------------------------------------------------------- яркость, камера, буст FPS, прицел
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

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

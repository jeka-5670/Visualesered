---------------------------------------------------------------- функции: движение, ESP
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
		local hd  = ch and ch:FindFirstChild("Head")
		local hu  = ch and ch:FindFirstChildOfClass("Humanoid")
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

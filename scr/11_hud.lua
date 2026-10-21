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

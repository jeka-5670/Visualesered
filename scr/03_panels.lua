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
local logBG  = panel("log",  -3.6,-0.35, 2.2, 4.5, 0.12)
local tabsBG = panel("tabs",  1.2, 2.3, 7.0, 0.6, 0.25)
local mainBG = panel("main",  1.2,-0.35, 7.0, 4.5, 0)

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
label(nameBG, "👤 " .. lp.DisplayName, 18, "text", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), true, Enum.TextXAlignment.Center).Active = false
nameBtn.InputBegan:Connect(startDrag("name"))
local pills = {}
for _, key in ipairs({"log", "tabs", "main"}) do
	local pill = new("TextButton", {Text = "", Size = UDim2.new(0.3, 0, 0, 9), Position = UDim2.new(0.35, 0, 1, -15), BorderSizePixel = 0,
		Visible = false, ZIndex = 10}, P[key].sg)
	bind(pill, "BackgroundColor3", "rim"); round(pill, 5)
	pill.InputBegan:Connect(startDrag(key))
	pills[#pills + 1] = pill
end
local offX, offY, dist = 0, 0, 10

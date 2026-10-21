---------------------------------------------------------------- помощники
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function frame(par, pos, size, role, rad)
	local f = new("Frame", {Position = pos, Size = size, BorderSizePixel = 0}, par)
	bind(f, "BackgroundColor3", role or "card")
	if rad then round(f, rad) end
	return f
end
local function label(par, text, size, role, pos, sz, bold, align)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size,
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 0, size + 6),
		TextXAlignment = align or Enum.TextXAlignment.Left, TextWrapped = true,
	}, par)
	bind(l, "TextColor3", role or "text")
	return l
end
local function button(par, text, cb, size, neutral)
	local b = new("TextButton", {Text = text, TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
		Size = size or UDim2.new(1, 0, 0, 40), BorderSizePixel = 0}, par)
	local eb, et
	if neutral then
		eb = bind(b, "BackgroundColor3", "card2"); et = bind(b, "TextColor3", "text")
	else
		eb = bind(b, "BackgroundColor3", "acc")
	end
	round(b, 12)
	local us = new("UIScale", {}, b)
	b.MouseEnter:Connect(function() if S.hover then TS:Create(us, TweenInfo.new(0.12), {Scale = 1.05}):Play() end end)
	b.MouseLeave:Connect(function() TS:Create(us, TweenInfo.new(0.12), {Scale = 1}):Play() end)
	b.Activated:Connect(cb)
	return b, eb, et
end
local function row(c, defs)
	local r = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, c)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, r)
	local n = #defs
	for _, d in ipairs(defs) do
		button(r, d[1], d[2], UDim2.new(1 / n, -8 * (n - 1) / n, 1, 0), d[3])
	end
	return r
end
local function hum() local ch = lp.Character; return ch and ch:FindFirstChildOfClass("Humanoid") end
local function root() local ch = lp.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function detectExecutor()
	local ok, n, v = pcall(function()
		if identifyexecutor then return identifyexecutor() end
		if getexecutorname then return getexecutorname() end
	end)
	if ok and n then return tostring(n) .. (v and (" " .. tostring(v)) or "") end
	if RS:IsStudio() then return "Studio (без инжектора)" end
	return "не определён"
end
local execName = detectExecutor()

local open, rootCF, animT = true, nil, 0
local setOpen, applyAll, applyView, applyButton, applyHud, drawSettings

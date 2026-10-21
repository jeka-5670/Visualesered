---------------------------------------------------------------- помощники настроек (общие для вкладки и приложений)
local function reset(c)
	for _, ch in ipairs(c:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
end
local function head(c, t) label(c, t, 13, "sub", nil, UDim2.new(1, 0, 0, 18), true) end
local function chunk(c, defs, n)
	for k = 1, #defs, n do row(c, {table.unpack(defs, k, math.min(k + n - 1, #defs))}) end
end
local function same(a, b)
	if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 0.01 end
	return a == b
end
local function opt(text, key, val, after)
	return {text, function() S[key] = val; applyAll(); (after or drawSettings)() end, not same(S[key], val)}
end
local function tog(text, key, after)
	return {text .. (S[key] and ": ВКЛ" or ": ВЫКЛ"), function() S[key] = not S[key]; applyAll(); (after or drawSettings)() end, not S[key]}
end
local function stepRow(c, title, key, st, lo, hi, fmt, after)
	label(c, title .. ": " .. fmt(S[key]), 15, "text", nil, UDim2.new(1, 0, 0, 22), true)
	local function ch(d) return function() S[key] = math.clamp(math.floor((S[key] + d) * 100 + 0.5) / 100, lo, hi); applyAll(); (after or drawSettings)() end end
	row(c, {{"−", ch(-st), true}, {"+", ch(st), true}})
end
local pct = function(v) return math.floor(v * 100 + 0.5) .. "%" end
local num = function(v) return tostring(v) end
local pxf = function(v) return v .. " px" end

---------------------------------------------------------------- мир: освещение, пост-эффекты
local function fx(class, name, props)
	local o = Lighting:FindFirstChild(name) or new(class, props, Lighting)
	o.Name = name
	return keep(o)
end
local cc = fx("ColorCorrectionEffect", "LauncherCC", {})
local bloom = fx("BloomEffect", "LauncherBloom", {Enabled = false, Size = 28, Threshold = 0.9, Intensity = 0})
local rays = fx("SunRaysEffect", "LauncherRays", {Enabled = false, Intensity = 0.25, Spread = 0.8})
local dof = fx("DepthOfFieldEffect", "LauncherDOF", {Enabled = false, FarIntensity = 0.35, FocusDistance = 35, InFocusRadius = 40, NearIntensity = 0})
local blur = fx("BlurEffect", "LauncherBlur", {Size = 0})
local flash = fx("ColorCorrectionEffect", "LauncherFlash", {})
local CCS = {
	normal = {"Обычный", 0, 0, 0, Color3.new(1, 1, 1)}, warm = {"Тёплый", 0.02, 0.06, 0.18, C(255,232,205)},
	cold = {"Холодный", 0, 0.06, -0.05, C(200,224,255)}, bw = {"Ч/Б", 0, 0.12, -1, Color3.new(1, 1, 1)},
	vivid = {"Яркий", 0, 0.16, 0.6, Color3.new(1, 1, 1)}, cinema = {"Кино", -0.03, 0.28, -0.15, C(228,236,255)},
	sunset = {"Закатный", 0.02, 0.1, 0.25, C(255,196,160)}, noir = {"Нуар", -0.04, 0.45, -1, Color3.new(1, 1, 1)},
}
local CC_ORDER = {"normal", "warm", "cold", "bw", "vivid", "cinema", "sunset", "noir"}
local FOGS = {{orig.fs, orig.fe, orig.fc}, {40, 500, C(205,215,230)}, {20, 220, C(190,200,215)}, {0, 80, C(120,130,150)}}
local function applyWorld()
	local f = FOGS[S.fog + 1]
	if S.bright then Lighting.FogEnd = 1e5 else Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = f[1], f[2], f[3] end
	local c = CCS[S.cc]
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = c[2], c[3], c[4], c[5]
	bloom.Enabled = S.bloom > 0; bloom.Intensity = ({0, 0.8, 1.8})[S.bloom + 1]
	rays.Enabled = S.rays; dof.Enabled = S.dof
	workspace.Gravity = S.grav
	TS:Create(blur, TweenInfo.new(0.3), {Size = (open and S.blurMenu) and 16 or 0}):Play()
end

---------------------------------------------------------------- погода
local function mkPart() return keep(new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	Transparency = 1, Size = Vector3.new(90, 1, 90)}, workspace)) end
local fxTop, fxLow = mkPart(), mkPart()
fxLow.Size = Vector3.new(70, 1, 70)
local WEATHER = {
	rain = {"🌧 Дождь", true, 380, {Lifetime = NR(0.6, 0.7), Speed = NR(65, 80), Size = NS(0.14), Transparency = NS(0.35), Color = ColorSequence.new(C(170,205,255)),
		LightEmission = 0.4, EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(2, 2), Orientation = Enum.ParticleOrientation.VelocityParallel}},
	snow = {"❄️ Снег", true, 170, {Lifetime = NR(7, 9), Speed = NR(3, 5), Size = NS(0.3), Transparency = NS(0.1), Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 0.3, EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), RotSpeed = NR(-40, 40), Acceleration = Vector3.new(1.5, 0, 0.5)}},
	sakura = {"🌸 Сакура", true, 55, {Lifetime = NR(9, 11), Speed = NR(2, 4), Size = NS(0.5), Color = ColorSequence.new(C(255,170,205)),
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(50, 50), Rotation = NR(0, 360), RotSpeed = NR(-120, 120), Acceleration = Vector3.new(2, 0, 1)}},
	leaves = {"🍂 Листья", true, 50, {Lifetime = NR(8, 10), Speed = NR(3, 5), Size = NS(0.55), Color = ColorSequence.new(C(235,140,30), C(170,70,20)),
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(45, 45), Rotation = NR(0, 360), RotSpeed = NR(-150, 150), Acceleration = Vector3.new(3, 0, 1)}},
	confetti = {"🎉 Конфетти", true, 90, {Lifetime = NR(4, 5), Speed = NR(8, 14), Size = NS(0.35), Color = RAINBOW, LightEmission = 0.2,
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(25, 25), Rotation = NR(0, 360), RotSpeed = NR(-200, 200)}},
	fireflies = {"✨ Светлячки", false, 22, {Lifetime = NR(4, 6), Speed = NR(0.5, 2), Size = NS(0.25), Color = ColorSequence.new(C(210,255,120)), LightEmission = 1,
		Transparency = NS({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 1)}),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(180, 180)}},
	bubbles = {"🫧 Пузыри", false, 16, {Lifetime = NR(5, 7), Speed = NR(2, 4), Size = NS({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.9)}),
		Transparency = NS(0.55), Color = ColorSequence.new(C(180,225,255)), LightEmission = 0.3, EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(20, 20)}},
	stars = {"🌠 Звездопад", true, 7, {Lifetime = NR(1.2, 1.6), Speed = NR(45, 60), Size = NS(0.6), Color = ColorSequence.new(C(255,245,190)), LightEmission = 1,
		EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(25, 0, 0)}},
}
local W_ORDER = {"rain", "snow", "sakura", "leaves", "confetti", "fireflies", "bubbles", "stars"}
local emit = {}
for k, d in pairs(WEATHER) do
	local e = new("ParticleEmitter", d[4], d[2] and fxTop or fxLow)
	e.Rate = d[3]; e.Enabled = false
	emit[k] = e
end
local function applyWeather()
	for k, e in pairs(emit) do
		e.Enabled = (k == S.weather)
		e.Rate = WEATHER[k][3] * S.wamt / 2
	end
end
task.spawn(function()
	while alive do
		task.wait(math.random(4, 10))
		if S.weather == "rain" and S.thunder then
			for _ = 1, math.random(1, 2) do
				flash.Brightness = 0.55
				TS:Create(flash, TweenInfo.new(0.35), {Brightness = 0}):Play()
				task.wait(0.25)
			end
		end
	end
end)

---------------------------------------------------------------- эффекты персонажа
local function applyChar()
	local hrp = root()
	if not hrp then return end
	for _, o in ipairs(hrp:GetChildren()) do
		if string.sub(o.Name, 1, 10) == "LauncherFx" then o:Destroy() end
	end
	local acc = ACCENTS[S.acc]
	if S.trail then
		local a0 = new("Attachment", {Name = "LauncherFxA0", Position = Vector3.new(0, 1, 0)}, hrp)
		local a1 = new("Attachment", {Name = "LauncherFxA1", Position = Vector3.new(0, -1, 0)}, hrp)
		new("Trail", {Name = "LauncherFxTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 0.8, LightEmission = 1, Color = RAINBOW,
			Transparency = NS({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if S.aura == "fire" then new("Fire", {Name = "LauncherFxAura", Size = 7, Heat = 9, Color = acc, SecondaryColor = Color3.new(1, 1, 1)}, hrp)
	elseif S.aura == "smoke" then new("Smoke", {Name = "LauncherFxAura", Size = 6, Opacity = 0.35, Color = acc, RiseVelocity = 3}, hrp)
	elseif S.aura == "sparkles" then new("Sparkles", {Name = "LauncherFxAura", SparkleColor = acc}, hrp)
	elseif S.aura == "orbs" then
		new("ParticleEmitter", {Name = "LauncherFxAura", Rate = 22, Lifetime = NR(1.5, 2.5), Speed = NR(1, 3), SpreadAngle = Vector2.new(180, 180), Size = NS(0.4),
			LightEmission = 1, Color = ColorSequence.new(acc), Transparency = NS({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})}, hrp)
	end
	if S.glow > 0 then new("PointLight", {Name = "LauncherFxLight", Color = acc, Brightness = ({0, 2, 5})[S.glow + 1], Range = 18}, hrp) end
end
conn(lp.CharacterAdded, function(ch)
	ch:WaitForChild("HumanoidRootPart"); task.wait(0.3)
    local h = ch:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end -- Сбрасываем зависание
	flyBV, flyBG = nil, nil; spectating = false
	applyChar()
end)

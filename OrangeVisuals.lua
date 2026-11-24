--[[
  ORANGE VISUALS  |  LocalScript
  Куда класть: StarterPlayer > StarterPlayerScripts (в своём плейсе в Roblox Studio)
  Меню: LeftCtrl  |  ПКМ по виджету: размер / убрать  |  ЛКМ: перетаскивать
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pgui = lp:WaitForChild("PlayerGui")

-- ===================== ТЕМА =====================
local ACCENT = Color3.fromRGB(255, 128, 0)
local ACCENT2 = Color3.fromRGB(255, 190, 70)
local BG = Color3.fromRGB(12, 12, 14)
local BG2 = Color3.fromRGB(22, 22, 26)
local BG3 = Color3.fromRGB(40, 40, 46)
local TXT = Color3.fromRGB(235, 235, 235)
local DIM = Color3.fromRGB(145, 145, 155)
local OPEN_KEY = Enum.KeyCode.LeftControl
local FONT = Enum.Font.GothamMedium
local BOLD = Enum.Font.GothamBold

-- ===================== ХЕЛПЕРЫ =====================
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, c, t, tr)
	return new("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function tw(o, t, p, style, dir)
	TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p):Play()
end
local function label(parent, text, size, color, font, xa)
	return new("TextLabel", {
		Text = text, TextSize = size or 12, TextColor3 = color or TXT, Font = font or FONT,
		BackgroundTransparency = 1, TextXAlignment = xa or Enum.TextXAlignment.Left,
	}, parent)
end

local conns = {}
local function on(sig, fn)
	local c = sig:Connect(fn)
	table.insert(conns, c)
	return c
end

local function getChar()
	local c = lp.Character
	return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

-- старые экземпляры
do
	local old = pgui:FindFirstChild("OrangeVisuals")
	if old then old:Destroy() end
	local oldfx = cam:FindFirstChild("OV_FX")
	if oldfx then oldfx:Destroy() end
end

local gui = new("ScreenGui", { Name = "OrangeVisuals", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pgui)
local fx = new("Folder", { Name = "OV_FX" }, cam)
local blur = new("BlurEffect", { Size = 0 }, Lighting)

-- ===================== SVG-ПОДОБНЫЕ ИКОНКИ (векторные, из UI-примитивов) =====================
-- Roblox не поддерживает SVG напрямую, поэтому иконки рисуются фигурами.
-- Если хотите свои картинки: замените icon() на ImageLabel с rbxassetid.
local function icon(parent, kind, col)
	col = col or ACCENT
	local f = new("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 }, parent)
	local function part(w, h, x, y, rot, round, fill)
		local p = new("Frame", {
			Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), AnchorPoint = Vector2.new(.5, .5),
			Rotation = rot or 0, BackgroundColor3 = col, BackgroundTransparency = fill and 0 or 1, BorderSizePixel = 0,
		}, f)
		if round then corner(p, round) end
		if not fill then stroke(p, col, 1.5) end
	end
	if kind == "eye" then part(16, 9, 8, 8, 0, 5, false); part(5, 5, 8, 8, 0, 3, true)
	elseif kind == "speed" then part(6, 2, 8, 3, 0, 1, true); part(10, 2, 8, 8, 0, 1, true); part(14, 2, 8, 13, 0, 1, true)
	elseif kind == "wing" then part(12, 5, 6, 6, -30, 3, true); part(10, 4, 7, 11, -12, 3, true)
	elseif kind == "star" then part(10, 10, 8, 8, 45, 2, false); part(4, 4, 8, 8, 0, 2, true)
	elseif kind == "gear" then part(12, 12, 8, 8, 0, 6, false); part(4, 4, 8, 8, 0, 2, true)
	elseif kind == "sun" then part(14, 14, 8, 8, 0, 7, false); part(6, 6, 8, 8, 0, 3, true)
	elseif kind == "cross" then part(2, 14, 8, 8, 0, 1, true); part(14, 2, 8, 8, 0, 1, true)
	elseif kind == "user" then part(6, 6, 8, 5, 0, 3, true); part(12, 6, 8, 12, 0, 3, true)
	elseif kind == "orb" then part(12, 12, 8, 8, 0, 6, false); part(4, 4, 8, 8, 0, 2, true)
	else part(6, 6, 4, 4, 0, 2, true); part(6, 6, 12, 4, 0, 2, true); part(6, 6, 4, 12, 0, 2, true); part(6, 6, 12, 12, 0, 2, true) end
	return f
end

-- ===================== iOS ПЕРЕКЛЮЧАТЕЛЬ =====================
local function makeToggle(parent, init, cb)
	local b = new("TextButton", {
		Text = "", Size = UDim2.fromOffset(40, 22), AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -10, .5, 0), BackgroundColor3 = init and ACCENT or BG3, AutoButtonColor = false,
	}, parent)
	corner(b, 11)
	local k = new("Frame", {
		Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.new(1, 1, 1),
		Position = init and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
	}, b)
	corner(k, 9)
	local state = init
	local function set(v, silent)
		state = v
		tw(b, .2, { BackgroundColor3 = v and ACCENT or BG3 })
		tw(k, .3, { Position = v and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2) }, Enum.EasingStyle.Back)
		if not silent and cb then cb(v) end
	end
	on(b.Activated, function() set(not state) end)
	return b, set
end

-- ===================== МОДУЛИ =====================
local featureList, F = {}, {}
local function feature(def)
	def.on = false
	def.v = {}
	for _, s in ipairs(def.settings or {}) do def.v[s.key] = s.default end
	table.insert(featureList, def)
	F[def.key] = def
	return def
end
local function setFeature(f, v)
	if f.on == v then return end
	f.on = v
	if f.onChange then
		local ok, err = pcall(f.onChange, v)
		if not ok then warn("[OrangeVisuals] " .. f.name .. ": " .. tostring(err)) end
	end
	if f.setToggle then f.setToggle(v, true) end
end

local function fxPart(props)
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true,
		Material = Enum.Material.Neon, CastShadow = false, Color = ACCENT, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
	}, nil)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = fx
	return p
end
local function pickColor(i, t, rainbow)
	if rainbow then return Color3.fromHSV((t * .25 + i * .06) % 1, .85, 1) end
	return ACCENT:Lerp(ACCENT2, (i % 7) / 7)
end

-- ---------- FOV (плавный) ----------
local fovBase, fovReturn = 70, false
feature({ tab = "Visuals", name = "Smooth FOV", key = "fov", icon = "eye", bind = Enum.KeyCode.B,
	settings = { { key = "fov", name = "FOV", min = 40, max = 120, default = 100 }, { key = "smooth", name = "Плавность", min = 1, max = 20, default = 8 } },
	onChange = function(on)
		if on then if not fovReturn then fovBase = cam.FieldOfView end fovReturn = false else fovReturn = true end
	end })

-- ---------- Aspect ratio ----------
feature({ tab = "Visuals", name = "Aspect Ratio", key = "aspect", icon = "grid",
	settings = { { key = "stretch", name = "Растяжение", min = .4, max = 1, default = .7, step = .01 } } })

-- ---------- ESP ----------
local espFolder = new("Folder", { Name = "ESP" }, fx)
local esp = {}
local function espClear(p)
	local e = esp[p]
	if e then
		if e.hl then e.hl:Destroy() end
		if e.bb then e.bb:Destroy() end
		esp[p] = nil
	end
end
local function espBuild(p)
	espClear(p)
	if p == lp or not F.esp.on then return end
	local char = p.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local hl = new("Highlight", { Adornee = char, FillColor = ACCENT, OutlineColor = Color3.new(1, 1, 1), FillTransparency = .65, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, espFolder)
	local bb = new("BillboardGui", { Adornee = root, AlwaysOnTop = true, Size = UDim2.fromOffset(140, 40), StudsOffset = Vector3.new(0, 3.6, 0), LightInfluence = 0 }, espFolder)
	local name = label(bb, "", 13, TXT, BOLD, Enum.TextXAlignment.Center)
	name.Size = UDim2.new(1, 0, 0, 16)
	local info = label(bb, "", 11, ACCENT2, FONT, Enum.TextXAlignment.Center)
	info.Size = UDim2.new(1, 0, 0, 14); info.Position = UDim2.fromOffset(0, 16)
	local hpBg = new("Frame", { Size = UDim2.new(.6, 0, 0, 4), Position = UDim2.new(.2, 0, 0, 33), BackgroundColor3 = BG, BorderSizePixel = 0 }, bb)
	corner(hpBg, 2)
	local hp = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, hpBg)
	corner(hp, 2)
	esp[p] = { hl = hl, bb = bb, name = name, info = info, hp = hp, hpBg = hpBg, hum = hum, root = root }
end
local function espHook(p)
	if p == lp then return end
	on(p.CharacterAdded, function(c)
		task.spawn(function()
			c:WaitForChild("HumanoidRootPart", 5)
			c:WaitForChild("Humanoid", 5)
			espBuild(p)
		end)
	end)
	on(p.CharacterRemoving, function() espClear(p) end)
end
feature({ tab = "Visuals", name = "ESP", key = "esp", icon = "eye", bind = Enum.KeyCode.Z,
	settings = {
		{ key = "dist", name = "Макс. дистанция", min = 50, max = 2000, default = 800 },
		{ key = "glow", name = "Подсветка (Highlight)", type = "bool", default = true },
		{ key = "names", name = "Имена", type = "bool", default = true },
		{ key = "info", name = "Дистанция / HP", type = "bool", default = true },
	},
	onChange = function(on)
		if on then for _, p in ipairs(Players:GetPlayers()) do espBuild(p) end
		else for p in pairs(esp) do espClear(p) end end
	end })
for _, p in ipairs(Players:GetPlayers()) do espHook(p) end
on(Players.PlayerAdded, espHook)
on(Players.PlayerRemoving, espClear)

-- ---------- КРЫЛЬЯ (анимированные) ----------
local wingFolder, feathers
local function getTorso(c) return c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")) end
local function wingsDestroy() if wingFolder then wingFolder:Destroy() wingFolder, feathers = nil, nil end end
local function wingsBuild()
	wingsDestroy()
	wingFolder = new("Folder", { Name = "Wings" }, fx)
	feathers = {}
	local sc = F.wings.v.size
	for side = -1, 1, 2 do
		for i = 1, 7 do
			local len = (3.8 - (i - 1) * .38) * sc
			local p = fxPart({ Size = Vector3.new(len, .08, (.6 - (i - 1) * .03) * sc), Transparency = .08 })
			p.Parent = wingFolder
			table.insert(feathers, { p = p, side = side, i = i, len = len })
		end
	end
end
feature({ tab = "Visuals", name = "Animated Wings", key = "wings", icon = "wing", bind = Enum.KeyCode.X,
	settings = {
		{ key = "speed", name = "Скорость взмаха", min = 1, max = 10, default = 3, step = .1 },
		{ key = "amp", name = "Амплитуда", min = .1, max = 1, default = .45, step = .05 },
		{ key = "size", name = "Размер", min = .5, max = 2, default = 1, step = .1 },
		{ key = "rainbow", name = "Радужные", type = "bool", default = false },
	},
	onChange = function(on) if on then wingsBuild() else wingsDestroy() end end,
	changed = function(k) if k == "size" and F.wings.on then wingsBuild() end end })

-- ---------- 3D МОДЕЛИ: нимб, орбы, питомец ----------
local haloParts, orbParts, petOuter, petCore = nil, nil, nil, nil
local function clearList(l) if l then for _, p in ipairs(l) do p:Destroy() end end end
feature({ tab = "Visuals", name = "Halo", key = "halo", icon = "star",
	settings = { { key = "speed", name = "Скорость", min = .5, max = 6, default = 2, step = .1 }, { key = "radius", name = "Радиус", min = .8, max = 2.5, default = 1.4, step = .1 }, { key = "rainbow", name = "Радужный", type = "bool", default = false } },
	onChange = function(on)
		clearList(haloParts); haloParts = nil
		if on then haloParts = {} for i = 1, 20 do haloParts[i] = fxPart({ Size = Vector3.new(.28, .1, .28), Shape = Enum.PartType.Block }) end end
	end })
local function orbsBuild()
	clearList(orbParts); orbParts = {}
	for i = 1, F.orbs.v.count do orbParts[i] = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.new(.6, .6, .6) }) end
end
feature({ tab = "Visuals", name = "Orbit Orbs", key = "orbs", icon = "orb",
	settings = { { key = "count", name = "Количество", min = 1, max = 8, default = 4 }, { key = "radius", name = "Радиус", min = 2, max = 6, default = 3.5, step = .1 }, { key = "speed", name = "Скорость", min = .5, max = 6, default = 2, step = .1 }, { key = "rainbow", name = "Радужные", type = "bool", default = false } },
	onChange = function(on) if on then orbsBuild() else clearList(orbParts); orbParts = nil end end,
	changed = function(k) if k == "count" and F.orbs.on then orbsBuild() end end })
feature({ tab = "Visuals", name = "3D Pet", key = "pet", icon = "gear",
	settings = { { key = "follow", name = "Плавность следования", min = 2, max = 15, default = 6 } },
	onChange = function(on)
		if petOuter then petOuter:Destroy() petCore:Destroy() petOuter, petCore = nil, nil end
		if on then
			petOuter = fxPart({ Size = Vector3.new(1.2, 1.2, 1.2), Transparency = .55 })
			petCore = fxPart({ Size = Vector3.new(.55, .55, .55), Color = ACCENT2 })
			local _, _, root = getChar()
			if root then petOuter.Position = root.Position + Vector3.new(2, 2, 0) end
		end
	end })

-- ---------- Trail / Aura ----------
local trailObjs, auraObj = {}, nil
feature({ tab = "Visuals", name = "Trail", key = "trail", icon = "speed", charBound = true,
	settings = { { key = "life", name = "Длина", min = .2, max = 2, default = .8, step = .05 } },
	onChange = function(on)
		for _, o in ipairs(trailObjs) do o:Destroy() end
		trailObjs = {}
		if not on then return end
		local _, _, root = getChar()
		if not root then return end
		local a0 = new("Attachment", { Position = Vector3.new(0, .9, 0) }, root)
		local a1 = new("Attachment", { Position = Vector3.new(0, -.9, 0) }, root)
		local tr = new("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = F.trail.v.life, LightEmission = 1,
			Color = ColorSequence.new(ACCENT2, ACCENT), Transparency = NumberSequence.new(.1, 1) }, root)
		trailObjs = { a0, a1, tr }
	end,
	changed = function() if trailObjs[3] then trailObjs[3].Lifetime = F.trail.v.life end end })
feature({ tab = "Visuals", name = "Particle Aura", key = "aura", icon = "sun", charBound = true,
	settings = { { key = "rate", name = "Количество", min = 5, max = 100, default = 30 } },
	onChange = function(on)
		if auraObj then auraObj:Destroy() auraObj = nil end
		if not on then return end
		local _, _, root = getChar()
		if not root then return end
		auraObj = new("ParticleEmitter", { Rate = F.aura.v.rate, Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Color = ColorSequence.new(ACCENT2, ACCENT),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .35), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Texture = "rbxasset://textures/particles/sparkles_main.dds" }, root)
	end,
	changed = function() if auraObj then auraObj.Rate = F.aura.v.rate end end })

-- ---------- Jump Circles ----------
local lastState
feature({ tab = "Visuals", name = "Jump Circles", key = "jump", icon = "orb",
	settings = { { key = "size", name = "Размер", min = 4, max = 20, default = 10 } } })

-- ---------- Crosshair ----------
local ch = new("Frame", { Size = UDim2.fromOffset(140, 140), AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), BackgroundTransparency = 1, Visible = false }, gui)
local bars = {}
for i = 1, 4 do bars[i] = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, ch); stroke(bars[i], Color3.new(0, 0, 0), 1, .3) end
local function chLayout()
	local s, g, t, c = F.cross.v.size, F.cross.v.gap, F.cross.v.thick, 70
	bars[1].Size = UDim2.fromOffset(t, s); bars[1].Position = UDim2.fromOffset(c, c - g - s / 2)
	bars[2].Size = UDim2.fromOffset(t, s); bars[2].Position = UDim2.fromOffset(c, c + g + s / 2)
	bars[3].Size = UDim2.fromOffset(s, t); bars[3].Position = UDim2.fromOffset(c - g - s / 2, c)
	bars[4].Size = UDim2.fromOffset(s, t); bars[4].Position = UDim2.fromOffset(c + g + s / 2, c)
end
feature({ tab = "Visuals", name = "Crosshair", key = "cross", icon = "cross",
	settings = { { key = "size", name = "Длина", min = 4, max = 30, default = 10 }, { key = "gap", name = "Зазор", min = 0, max = 20, default = 5 },
		{ key = "thick", name = "Толщина", min = 1, max = 4, default = 2 }, { key = "spin", name = "Вращение", min = 0, max = 360, default = 0 } },
	onChange = function(on) ch.Visible = on; chLayout() end,
	changed = function() chLayout() end })

-- ---------- Освещение ----------
local lightBackup
feature({ tab = "Visuals", name = "Full Bright", key = "fullbright", icon = "sun", bind = Enum.KeyCode.V,
	onChange = function(on)
		if on then
			lightBackup = { Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows }
			Lighting.Brightness = 2; Lighting.Ambient = Color3.fromRGB(190, 190, 190); Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190); Lighting.GlobalShadows = false
		elseif lightBackup then
			Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = unpack(lightBackup)
		end
	end })
local fogBackup
feature({ tab = "Visuals", name = "No Fog", key = "nofog", icon = "sun",
	onChange = function(on)
		if on then
			fogBackup = { Lighting.FogStart, Lighting.FogEnd }
			Lighting.FogStart = 1e6; Lighting.FogEnd = 1e6
			local a = Lighting:FindFirstChildOfClass("Atmosphere")
			if a then fogBackup[3] = a.Density; a.Density = 0 end
		elseif fogBackup then
			Lighting.FogStart, Lighting.FogEnd = fogBackup[1], fogBackup[2]
			local a = Lighting:FindFirstChildOfClass("Atmosphere")
			if a and fogBackup[3] then a.Density = fogBackup[3] end
		end
	end })
local clockBackup
feature({ tab = "Visuals", name = "Time Changer", key = "time", icon = "sun",
	settings = { { key = "time", name = "Время суток", min = 0, max = 24, default = 14, step = .1 } },
	onChange = function(on) if on then clockBackup = Lighting.ClockTime elseif clockBackup then Lighting.ClockTime = clockBackup end end })
local cc, bloom
feature({ tab = "Visuals", name = "Color Grade", key = "grade", icon = "grid",
	settings = { { key = "sat", name = "Насыщенность", min = -1, max = 2, default = .3, step = .01 }, { key = "con", name = "Контраст", min = -.5, max = 1, default = .1, step = .01 },
		{ key = "bri", name = "Яркость", min = -.3, max = .3, default = 0, step = .01 }, { key = "tint", name = "Оранжевый оттенок", min = 0, max = 1, default = .15, step = .01 } },
	onChange = function(on)
		if cc then cc:Destroy() cc = nil end
		if on then cc = new("ColorCorrectionEffect", {}, Lighting) end
	end })
feature({ tab = "Visuals", name = "Bloom", key = "bloom", icon = "star",
	settings = { { key = "int", name = "Интенсивность", min = 0, max = 3, default = 1, step = .05 }, { key = "size", name = "Размер", min = 0, max = 56, default = 24 }, { key = "thr", name = "Порог", min = 0, max = 3, default = 1, step = .05 } },
	onChange = function(on)
		if bloom then bloom:Destroy() bloom = nil end
		if on then bloom = new("BloomEffect", {}, Lighting) end
	end })

-- ---------- Utilities: WalkSpeed (плавный) ----------
local wsBase, wsReturn = 16, false
feature({ tab = "Utilities", name = "Smooth WalkSpeed", key = "walk", icon = "speed", bind = Enum.KeyCode.C,
	settings = { { key = "speed", name = "Скорость", min = 16, max = 120, default = 32 }, { key = "smooth", name = "Плавность", min = 1, max = 20, default = 6 } },
	onChange = function(on)
		local _, hum = getChar()
		if on then if not wsReturn and hum then wsBase = hum.WalkSpeed end wsReturn = false else wsReturn = true end
	end })

-- ===================== ВИДЖЕТЫ =====================
local fps = 60
local widgets = {}
local ctx, ctxTarget

local function showCtx(w)
	ctxTarget = w
	local m = UIS:GetMouseLocation()
	ctx.Position = UDim2.fromOffset(m.X - 10, m.Y - 10)
	ctx.Visible = true
end

local function makeWidget(def)
	local w = { rows = {} }
	local fr = new("Frame", { Name = def.name, Size = UDim2.fromOffset(170, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(def.pos.X, def.pos.Y), BackgroundColor3 = BG, BackgroundTransparency = .12, Active = true }, gui)
	corner(fr, 10); stroke(fr, ACCENT, 1, .55)
	local sc = new("UIScale", { Scale = 1 }, fr)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, fr)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, fr)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0 }, fr)
	icon(head, def.icon)
	local t = label(head, def.name, 12, ACCENT, BOLD); t.Position = UDim2.fromOffset(22, 0); t.Size = UDim2.new(1, -22, 1, 0)
	for i, r in ipairs(def.rows) do
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = i }, fr)
		local l = label(row, r[1], 12, DIM); l.Size = UDim2.fromScale(.5, 1)
		local v = label(row, "", 12, TXT, FONT, Enum.TextXAlignment.Right); v.Size = UDim2.fromScale(1, 1)
		w.rows[i] = { v = v, fn = r[2] }
	end
	w.fr, w.scale = fr, sc
	local dragging, off = false, Vector2.zero
	on(fr.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; off = UIS:GetMouseLocation() - fr.AbsolutePosition
		elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
			showCtx(w)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local m = UIS:GetMouseLocation()
			fr.Position = UDim2.fromOffset(m.X - off.X, m.Y - off.Y)
		end
	end)
	on(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	w.name, w.def = def.name, def
	table.insert(widgets, w)
	return w
end

local nearest = { name = "-", dist = "-", hp = "-" }
local hotRows = { { "Меню", function() return "LCtrl" end } }
for _, f in ipairs(featureList) do
	if f.bind then table.insert(hotRows, { f.name, function() return f.bind.Name .. (f.on and "  ON" or "  OFF") end }) end
end

local widgetDefs = {
	{ name = "Info", icon = "grid", pos = Vector2.new(16, 16), rows = {
		{ "FPS", function() return tostring(math.floor(fps + .5)) end },
		{ "Ping", function() local ok, p = pcall(function() return lp:GetNetworkPing() * 1000 end) return ok and (math.floor(p) .. " ms") or "-" end },
		{ "Время", function() return os.date("%H:%M:%S") end } } },
	{ name = "Hotkeys", icon = "gear", pos = Vector2.new(16, 120), rows = hotRows },
	{ name = "Status", icon = "speed", pos = Vector2.new(16, 330), rows = {
		{ "WalkSpeed", function() local _, h = getChar() return h and string.format("%.1f", h.WalkSpeed) or "-" end },
		{ "FOV", function() return string.format("%.1f", cam.FieldOfView) end },
		{ "Модулей", function() local n = 0 for _, f in ipairs(featureList) do if f.on then n += 1 end end return tostring(n) end } } },
	{ name = "Position", icon = "cross", pos = Vector2.new(210, 16), rows = {
		{ "X", function() local _, _, r = getChar() return r and string.format("%.1f", r.Position.X) or "-" end },
		{ "Y", function() local _, _, r = getChar() return r and string.format("%.1f", r.Position.Y) or "-" end },
		{ "Z", function() local _, _, r = getChar() return r and string.format("%.1f", r.Position.Z) or "-" end } } },
	{ name = "Nearest", icon = "user", pos = Vector2.new(210, 120), rows = {
		{ "Игрок", function() return nearest.name end }, { "Дистанция", function() return nearest.dist end }, { "HP", function() return nearest.hp end } } },
}
for _, d in ipairs(widgetDefs) do makeWidget(d) end

-- контекстное меню (ПКМ)
ctx = new("Frame", { Size = UDim2.fromOffset(150, 98), BackgroundColor3 = BG2, Visible = false, Active = true }, gui)
corner(ctx, 8); stroke(ctx, ACCENT, 1, .3)
new("UIListLayout", { Padding = UDim.new(0, 2) }, ctx)
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, ctx)
local function ctxBtn(text, fn)
	local b = new("TextButton", { Text = text, Font = FONT, TextSize = 12, TextColor3 = TXT, BackgroundColor3 = BG3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false }, ctx)
	corner(b, 6)
	on(b.MouseEnter, function() tw(b, .12, { BackgroundTransparency = 0 }) end)
	on(b.MouseLeave, function() tw(b, .12, { BackgroundTransparency = 1 }) end)
	on(b.Activated, function() if ctxTarget then fn(ctxTarget) end ctx.Visible = false end)
end
ctxBtn("Размер  +", function(w) w.scale.Scale = math.clamp(w.scale.Scale + .15, .6, 2.2) end)
ctxBtn("Размер  −", function(w) w.scale.Scale = math.clamp(w.scale.Scale - .15, .6, 2.2) end)
ctxBtn("Убрать виджет", function(w) w.fr.Visible = false if w.setToggle then w.setToggle(false, true) end end)
on(ctx.MouseLeave, function() ctx.Visible = false end)

-- ===================== МЕНЮ =====================
local main = new("CanvasGroup", { Size = UDim2.fromOffset(560, 400), AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	BackgroundColor3 = BG, GroupTransparency = 1, Visible = false }, gui)
corner(main, 14); stroke(main, ACCENT, 1.5, .35)
local mscale = new("UIScale", { Scale = .9 }, main)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1 }, main)
local logo = icon(header, "orb"); logo.Position = UDim2.fromOffset(16, 16)
local title = label(header, "ORANGE VISUALS", 13, ACCENT, BOLD); title.Position = UDim2.fromOffset(40, 0); title.Size = UDim2.new(0, 130, 1, 0)
new("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, 0), BackgroundColor3 = BG3, BorderSizePixel = 0 }, header)

local tabNames = { "Visuals", "HUD", "Utilities" }
local pages, tabBtns, tabLines = {}, {}, {}
local function selectTab(n)
	for _, name in ipairs(tabNames) do
		pages[name].Visible = (name == n)
		tw(tabBtns[name], .2, { TextColor3 = name == n and ACCENT or DIM })
		tw(tabLines[name], .25, { Size = UDim2.new(name == n and 1 or 0, name == n and -16 or 0, 0, 2) })
	end
end
for idx, name in ipairs(tabNames) do
	local b = new("TextButton", { Text = name, Font = BOLD, TextSize = 13, TextColor3 = DIM, BackgroundTransparency = 1, AutoButtonColor = false,
		Size = UDim2.fromOffset(84, 48), Position = UDim2.fromOffset(170 + (idx - 1) * 88, 0) }, header)
	local line = new("Frame", { AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, 0), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, b)
	corner(line, 1)
	tabBtns[name], tabLines[name] = b, line
	on(b.Activated, function() selectTab(name) end)
	local pg = new("ScrollingFrame", { Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 1, -70), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, main)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
	new("UIPadding", { PaddingRight = UDim.new(0, 8) }, pg)
	pages[name] = pg
end

local function buildSlider(parent, f, s)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, parent)
	local nl = label(row, s.name, 12, DIM); nl.Size = UDim2.new(.6, 0, 0, 16)
	local val = label(row, "", 12, TXT, FONT, Enum.TextXAlignment.Right); val.Size = UDim2.new(1, 0, 0, 16)
	local bar = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 22), BackgroundColor3 = BG3 }, row)
	corner(bar, 3)
	local fill = new("Frame", { BackgroundColor3 = ACCENT, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bar); corner(fill, 3)
	local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = Color3.new(1, 1, 1) }, bar); corner(knob, 6)
	local function render(v)
		local a = (v - s.min) / (s.max - s.min)
		fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, .5)
		val.Text = (s.step and s.step < 1) and string.format("%.2f", v) or tostring(math.floor(v + .5))
	end
	render(f.v[s.key])
	local dragging = false
	local function upd(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local st = s.step or 1
		local v = math.clamp(math.floor((s.min + a * (s.max - s.min)) / st + .5) * st, s.min, s.max)
		f.v[s.key] = v; render(v)
		if f.changed then f.changed(s.key) end
	end
	on(bar.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; upd(i.Position.X) end
	end)
	on(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end
	end)
	on(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

local function buildBool(parent, f, s)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
	local nl = label(row, s.name, 12, DIM); nl.Size = UDim2.new(.7, 0, 1, 0)
	local _, set = makeToggle(row, f.v[s.key], function(v) f.v[s.key] = v end)
	local tg = row:FindFirstChildOfClass("TextButton")
	tg.Position = UDim2.new(1, 0, .5, 0); tg.Size = UDim2.fromOffset(34, 18)
	tg:FindFirstChildOfClass("Frame").Size = UDim2.fromOffset(14, 14)
	tg:FindFirstChildOfClass("Frame").Position = f.v[s.key] and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
end

local function buildCard(parent, f)
	local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG2 }, parent)
	corner(card, 8)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1 }, card)
	local ic = icon(head, f.icon); ic.Position = UDim2.fromOffset(12, 11)
	local nl = label(head, f.name, 13, TXT); nl.Position = UDim2.fromOffset(36, 0); nl.Size = UDim2.new(1, -120, 1, 0)
	local _, set = makeToggle(head, f.on, function(v) setFeature(f, v) end)
	f.setToggle = set
	if f.settings and #f.settings > 0 then
		local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2 }, card)
		new("UIListLayout", { Padding = UDim.new(0, 2) }, body)
		new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 10) }, body)
		for _, s in ipairs(f.settings) do
			if s.type == "bool" then buildBool(body, f, s) else buildSlider(body, f, s) end
		end
		local dots = new("TextButton", { Text = "···", Font = BOLD, TextSize = 18, TextColor3 = DIM, BackgroundTransparency = 1, AutoButtonColor = false,
			Size = UDim2.fromOffset(30, 24), AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -56, .5, 0) }, head)
		on(dots.Activated, function() body.Visible = not body.Visible; tw(dots, .2, { TextColor3 = body.Visible and ACCENT or DIM }) end)
	end
end

local function textButton(parent, text, fn)
	local b = new("TextButton", { Text = text, Font = BOLD, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = ACCENT, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36) }, parent)
	corner(b, 8)
	on(b.MouseEnter, function() tw(b, .15, { BackgroundColor3 = ACCENT2 }) end)
	on(b.MouseLeave, function() tw(b, .15, { BackgroundColor3 = ACCENT }) end)
	on(b.Activated, fn)
	return b
end

for _, f in ipairs(featureList) do buildCard(pages[f.tab], f) end

-- HUD: виджеты
for _, w in ipairs(widgets) do
	local card = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = BG2 }, pages.HUD); corner(card, 8)
	local ic = icon(card, w.def.icon); ic.Position = UDim2.fromOffset(12, 11)
	local nl = label(card, "Виджет: " .. w.name, 13, TXT); nl.Position = UDim2.fromOffset(36, 0); nl.Size = UDim2.new(1, -100, 1, 0)
	local _, set = makeToggle(card, true, function(v) w.fr.Visible = v end)
	w.setToggle = set
end
local hint = label(pages.HUD, "ЛКМ — перетащить виджет  •  ПКМ — размер / убрать", 11, DIM); hint.Size = UDim2.new(1, 0, 0, 22)
textButton(pages.HUD, "Сбросить виджеты", function()
	for i, w in ipairs(widgets) do w.fr.Visible = true; w.scale.Scale = 1; w.fr.Position = UDim2.fromOffset(w.def.pos.X, w.def.pos.Y); if w.setToggle then w.setToggle(true, true) end end
end)

-- Utilities: Unload
local unload
textButton(pages.Utilities, "Выгрузить скрипт (Unload)", function() unload() end)

selectTab("Visuals")

-- открытие меню
local open = false
local function setOpen(v)
	open = v
	if v then
		main.Visible = true
		mscale.Scale = .88
		tw(main, .3, { GroupTransparency = 0 })
		tw(mscale, .45, { Scale = 1 }, Enum.EasingStyle.Back)
		tw(blur, .35, { Size = 14 })
	else
		tw(main, .2, { GroupTransparency = 1 })
		tw(mscale, .2, { Scale = .92 })
		tw(blur, .25, { Size = 0 })
		task.delay(.22, function() if not open then main.Visible = false end end)
	end
end

-- ===================== ВВОД =====================
on(UIS.InputBegan, function(i, gpe)
	if gpe then return end
	if i.KeyCode == OPEN_KEY then setOpen(not open) return end
	for _, f in ipairs(featureList) do
		if f.bind and i.KeyCode == f.bind then setFeature(f, not f.on) end
	end
end)

on(lp.CharacterAdded, function(c)
	task.spawn(function()
		c:WaitForChild("HumanoidRootPart", 5); task.wait(.2)
		for _, f in ipairs(featureList) do
			if f.on and f.charBound then pcall(f.onChange, true) end
		end
	end)
end)

-- ===================== ГЛАВНЫЙ ЦИКЛ =====================
local acc = 0
on(RunService.RenderStepped, function(dt)
	local t = os.clock()
	fps = fps * .92 + (1 / math.max(dt, 1e-4)) * .08
	local char, hum, root = getChar()

	-- плавный FOV
	if F.fov.on then
		cam.FieldOfView += (F.fov.v.fov - cam.FieldOfView) * (1 - math.exp(-dt * F.fov.v.smooth))
	elseif fovReturn then
		cam.FieldOfView += (fovBase - cam.FieldOfView) * (1 - math.exp(-dt * F.fov.v.smooth))
		if math.abs(cam.FieldOfView - fovBase) < .05 then cam.FieldOfView = fovBase; fovReturn = false end
	end

	-- плавный WalkSpeed
	if hum then
		if F.walk.on then
			hum.WalkSpeed += (F.walk.v.speed - hum.WalkSpeed) * (1 - math.exp(-dt * F.walk.v.smooth))
		elseif wsReturn then
			hum.WalkSpeed += (wsBase - hum.WalkSpeed) * (1 - math.exp(-dt * F.walk.v.smooth))
			if math.abs(hum.WalkSpeed - wsBase) < .05 then hum.WalkSpeed = wsBase; wsReturn = false end
		end
	end

	-- ESP
	if F.esp.on then
		local cp = cam.CFrame.Position
		local v = F.esp.v
		for p, e in pairs(esp) do
			if not (e.hum.Parent and e.root.Parent) then
				espClear(p)
			else
				local d = (e.root.Position - cp).Magnitude
				local vis = d <= v.dist and e.hum.Health > 0
				e.hl.Enabled = vis and v.glow
				e.bb.Enabled = vis
				if vis then
					local ratio = math.clamp(e.hum.Health / math.max(e.hum.MaxHealth, 1), 0, 1)
					e.name.Visible = v.names; e.name.Text = p.DisplayName
					e.info.Visible = v.info; e.hpBg.Visible = v.info
					e.info.Text = string.format("%dm  |  %d HP", d, e.hum.Health)
					e.hp.Size = UDim2.fromScale(ratio, 1)
					e.hp.BackgroundColor3 = Color3.fromRGB(255, 60, 40):Lerp(ACCENT2, ratio)
				end
			end
		end
	end

	-- крылья
	if F.wings.on and feathers then
		local torso = getTorso(char)
		if torso then
			local v = F.wings.v
			local flap = math.sin(t * v.speed) * v.amp
			for _, f in ipairs(feathers) do
				local yaw = -f.side * (math.rad(35) + flap * .6)
				local pivot = torso.CFrame * CFrame.new(f.side * .35, .5, .55) * CFrame.Angles(0, yaw, 0)
				local rz = f.side * (math.rad(40 - (f.i - 1) * 14) + flap + (f.i - 1) * flap * .12)
				f.p.CFrame = pivot * CFrame.Angles(0, 0, rz) * CFrame.new(f.side * f.len / 2, 0, 0)
				f.p.Color = pickColor(f.i, t, v.rainbow)
			end
		end
	end

	-- нимб
	if F.halo.on and haloParts and char then
		local head = char:FindFirstChild("Head")
		if head then
			local v, n = F.halo.v, #haloParts
			local center = head.Position + Vector3.new(0, 1.3, 0)
			for i, p in ipairs(haloParts) do
				local a = t * v.speed + i * (math.pi * 2 / n)
				p.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * v.radius, 0, math.sin(a) * v.radius)) * CFrame.Angles(0, -a, 0)
				p.Color = pickColor(i, t, v.rainbow)
			end
		end
	end

	-- орбы
	if F.orbs.on and orbParts and root then
		local v, n = F.orbs.v, #orbParts
		for i, p in ipairs(orbParts) do
			local a = t * v.speed + i * (math.pi * 2 / n)
			p.Position = root.Position + Vector3.new(math.cos(a) * v.radius, math.sin(t * 2 + i) * .8, math.sin(a) * v.radius)
			p.Color = pickColor(i, t, v.rainbow)
		end
	end

	-- питомец
	if F.pet.on and petOuter and root then
		local target = (root.CFrame * CFrame.new(2.8, 2.2 + math.sin(t * 2) * .35, 1)).Position
		local pos = petOuter.Position:Lerp(target, 1 - math.exp(-dt * F.pet.v.follow))
		petOuter.CFrame = CFrame.new(pos) * CFrame.Angles(t, t * .7, 0)
		petCore.CFrame = CFrame.new(pos) * CFrame.Angles(-t * 1.5, t, t * .5)
	end

	-- jump circles
	if hum then
		local st = hum:GetState()
		if F.jump.on and root and st == Enum.HumanoidStateType.Jumping and lastState ~= st then
			local s = F.jump.v.size
			local ring = fxPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(.12, 1, 1), Transparency = .15 })
			ring.CFrame = CFrame.new(root.Position - Vector3.new(0, hum.HipHeight + root.Size.Y / 2 - .05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			tw(ring, .7, { Size = Vector3.new(.12, s, s), Transparency = 1 })
			Debris:AddItem(ring, .8)
		end
		lastState = st
	end

	-- прицел
	if F.cross.on then ch.Rotation = (ch.Rotation + F.cross.v.spin * dt) % 360 end

	-- время суток / эффекты
	if F.time.on then Lighting.ClockTime = F.time.v.time end
	if cc then
		local v = F.grade.v
		cc.Saturation, cc.Contrast, cc.Brightness = v.sat, v.con, v.bri
		cc.TintColor = Color3.new(1, 1, 1):Lerp(ACCENT, v.tint)
	end
	if bloom then bloom.Intensity, bloom.Size, bloom.Threshold = F.bloom.v.int, F.bloom.v.size, F.bloom.v.thr end

	-- виджеты (5 раз в секунду)
	acc += dt
	if acc > .2 then
		acc = 0
		-- ближайший игрок
		nearest = { name = "-", dist = "-", hp = "-" }
		if root then
			local best = math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p ~= lp and p.Character
				local r = c and c:FindFirstChild("HumanoidRootPart")
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if r and h then
					local d = (r.Position - root.Position).Magnitude
					if d < best then best = d; nearest = { name = p.DisplayName, dist = string.format("%dm", d), hp = tostring(math.floor(h.Health)) } end
				end
			end
		end
		for _, w in ipairs(widgets) do
			if w.fr.Visible then
				for _, r in ipairs(w.rows) do r.v.Text = tostring(r.fn()) end
			end
		end
	end
end)

-- растяжение экрана (Aspect Ratio)
RunService:BindToRenderStep("OV_Stretch", Enum.RenderPriority.Camera.Value + 1, function()
	if F.aspect.on then
		cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, F.aspect.v.stretch, 0, 0, 0, 1)
	end
end)

unload = function()
	for _, f in ipairs(featureList) do if f.on then setFeature(f, false) end end
	pcall(function() RunService:UnbindFromRenderStep("OV_Stretch") end)
	for _, c in ipairs(conns) do c:Disconnect() end
	blur:Destroy(); fx:Destroy(); gui:Destroy()
end

task.delay(.4, function() setOpen(true) end)

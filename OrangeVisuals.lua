--[[
  ORANGE VISUALS V2  |  LocalScript
  Куда класть: StarterPlayer > StarterPlayerScripts (в своём плейсе в Roblox Studio)
  Активация: требуется OrangeVisualsLicense.server.lua в ServerScriptService
  Меню: LeftCtrl  |  ПКМ по виджету: размер / убрать  |  ЛКМ: перетаскивать
]]

local function awaitLicense(playerGui, reason)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local previous = playerGui:FindFirstChild("OrangeVisualsActivation")
	if previous then previous:Destroy() end

	local function make(class, properties, parent)
		local instance = Instance.new(class)
		for key, value in pairs(properties) do instance[key] = value end
		instance.Parent = parent
		return instance
	end
	local orange = Color3.fromRGB(255, 139, 44)
	local background = Color3.fromRGB(19, 18, 20)
	local foreground = Color3.fromRGB(245, 238, 233)
	local gui = make("ScreenGui", {
		Name = "OrangeVisualsActivation", ResetOnSpawn = false, DisplayOrder = 30,
	}, playerGui)
	local backdrop = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(9, 8, 10),
		BackgroundTransparency = .24, BorderSizePixel = 0,
	}, gui)
	local card = make("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.new(.92, 0, 0, 236), BackgroundColor3 = background, BorderSizePixel = 0,
	}, backdrop)
	make("UISizeConstraint", { MaxSize = Vector2.new(440, 236) }, card)
	make("UICorner", { CornerRadius = UDim.new(0, 15) }, card)
	make("UIStroke", { Color = orange, Transparency = .57 }, card)

	local function text(value, size, color, y, height)
		return make("TextLabel", {
			Text = value, TextSize = size, TextColor3 = color, Font = Enum.Font.GothamMedium,
			Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, height),
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1,
		}, card)
	end
	local title = text("OrangeVisuals", 23, orange, 14, 32)
	title.Font = Enum.Font.GothamBold
	text("Вставьте ключ активации", 15, foreground, 52, 27)
	local input = make("TextBox", {
		Name = "LicenseKey", Text = "", PlaceholderText = "Ключ OV1…", ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, Font = Enum.Font.Code,
		TextColor3 = foreground, PlaceholderColor3 = Color3.fromRGB(167, 158, 155),
		BackgroundColor3 = Color3.fromRGB(41, 37, 39), BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 87), Size = UDim2.new(1, -40, 0, 42),
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, input)
	local button = make("TextButton", {
		Text = "Активировать", Font = Enum.Font.GothamBold, TextSize = 15, AutoButtonColor = true,
		TextColor3 = Color3.fromRGB(32, 17, 9), BackgroundColor3 = orange, BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 140), Size = UDim2.new(1, -40, 0, 40),
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
	local status = text(reason or "Скопируйте ключ целиком из панели выдачи.", 13, foreground, 184, 35)
	local messages = {
		invalid = "Ключ неверный. Проверьте, что он скопирован целиком.",
		expired = "Срок действия ключа истёк.",
		rate = "Слишком много попыток. Повторите через несколько секунд.",
		unavailable = "Сервер проверки недоступен. Повторите попытку.",
	}
	local finished = Instance.new("BindableEvent")
	local busy, closed = false, false

	local function submit()
		if busy or closed then return end
		local key = input.Text:match("^%s*(.-)%s*$")
		if #key == 0 or #key > 450 then status.Text = messages.invalid return end
		busy = true
		button.Text, status.Text = "Проверяем…", ""
		local remote = ReplicatedStorage:WaitForChild("OV_CheckLicense", 5)
		local ok, response = false, nil
		if remote and remote:IsA("RemoteFunction") then ok, response = pcall(remote.InvokeServer, remote, key) end
		if closed then return end
		if ok and type(response) == "table" and response.ok == true and type(response.expiresAt) == "number" then
			closed = true
			input.Text = ""
			finished:Fire(response.expiresAt)
		else
			local code = ok and type(response) == "table" and response.code or "unavailable"
			status.Text, button.Text, busy = messages[code] or messages.unavailable, "Активировать", false
		end
	end
	button.Activated:Connect(submit)
	input.FocusLost:Connect(function(enterPressed) if enterPressed then submit() end end)
	gui.Destroying:Connect(function()
		if not closed then closed = true finished:Fire() end
	end)
	local expiry = finished.Event:Wait()
	finished:Destroy()
	if gui.Parent then gui:Destroy() end
	return expiry
end

local function runVisuals(expiresAt)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local Debris = game:GetService("Debris")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	local HttpService = game:GetService("HttpService")
	local SoundService = game:GetService("SoundService")

	local lp = Players.LocalPlayer
	local pgui = lp:WaitForChild("PlayerGui")
	while not workspace.CurrentCamera do workspace:GetPropertyChangedSignal("CurrentCamera"):Wait() end
	local cam = workspace.CurrentCamera
	local V2 = { alive = true, searchItems = {} }

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
		if old then
			local cleanup = old:FindFirstChild("OV_Cleanup")
			if cleanup and cleanup:IsA("BindableFunction") then pcall(cleanup.Invoke, cleanup) end
			if old.Parent then old:Destroy() end
		end
		local oldfx = cam:FindFirstChild("OV_FX")
		if oldfx then oldfx:Destroy() end
	end

	local gui = new("ScreenGui", { Name = "OrangeVisuals", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pgui)
	local fx = new("Folder", { Name = "OV_ClientFX" }, workspace)
	local blur = new("BlurEffect", { Name = "OV_MenuBlur", Size = 0 }, Lighting)
	local cleanup = new("BindableFunction", { Name = "OV_Cleanup" }, gui)

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
	local function makeToggle(parent, init, cb, compact)
		local width, height = compact and 34 or 40, compact and 18 or 22
		local travel = width - height + 2
		local b = new("TextButton", {
			Text = "", Size = UDim2.fromOffset(width, height), AnchorPoint = Vector2.new(1, .5),
			Position = UDim2.new(1, -10, .5, 0), BackgroundColor3 = init and ACCENT or BG3, AutoButtonColor = false,
		}, parent)
		corner(b, height / 2)
		local k = new("Frame", {
			Size = UDim2.fromOffset(height - 4, height - 4), BackgroundColor3 = Color3.new(1, 1, 1),
			Position = init and UDim2.fromOffset(travel, 2) or UDim2.fromOffset(2, 2),
		}, b)
		corner(k, (height - 4) / 2)
		local state = init
		local function set(v, silent)
			if state == v then return end
			state = v
			tw(b, .2, { BackgroundColor3 = v and ACCENT or BG3 })
			tw(k, .3, { Position = v and UDim2.fromOffset(travel, 2) or UDim2.fromOffset(2, 2) }, Enum.EasingStyle.Back)
			if not silent and cb then cb(v) end
		end
		on(b.Activated, function() set(not state) end)
		return b, set
	end

	-- ===================== МОДУЛИ =====================
	local featureList, F = {}, {}
	local originalHeavy = { wings = true, halo = true, orbs = true, pet = true, trail = true, aura = true, jump = true, bloom = true }
	local function feature(def)
		def.on, def.active = false, false
		def.heavy = def.heavy or originalHeavy[def.key]
		def.v = {}
		for _, s in ipairs(def.settings or {}) do def.v[s.key] = s.default end
		table.insert(featureList, def)
		F[def.key] = def
		return def
	end
	local function applyFeature(f)
		local paused = f.heavy and F.fpsMode and F.fpsMode.on
		local replaced = f.key == "wings" and F.customWings and F.customWings.active
		local active = f.on and not paused and not replaced
		if f.active == active then return end
		f.active = active
		if f.onChange then
			local ok, err = pcall(f.onChange, active)
			if not ok then warn("[OrangeVisuals] " .. f.name .. ": " .. tostring(err)) end
		end
	end
	local function setFeature(f, v)
		if f.on == v then return end
		f.on = v
		applyFeature(f)
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
		if not V2.alive or p == lp or p.Parent ~= Players or not F.esp.active then return end
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
				if p.Character == c then espBuild(p) end
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
		changed = function(k) if k == "size" and F.wings.active then wingsBuild() end end })

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
		changed = function(k) if k == "count" and F.orbs.active then orbsBuild() end end })
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
				Lighting.FogStart, Lighting.FogEnd = 1e6, 1e6
			elseif fogBackup then
				Lighting.FogStart, Lighting.FogEnd = fogBackup[1], fogBackup[2]
				fogBackup = nil
			end
			V2.syncAtmosphere()
		end })
	local clockBackup
	function V2.updateClock()
		local target = F.time.active and (F.time.v.time % 24) or V2.skyClock
		if target ~= nil then
			if clockBackup == nil then clockBackup = Lighting.ClockTime end
			if Lighting.ClockTime ~= target then Lighting.ClockTime = target end
		elseif clockBackup ~= nil then
			Lighting.ClockTime, clockBackup = clockBackup, nil
		end
	end
	feature({ tab = "Visuals", name = "Time Changer", key = "time", icon = "sun",
		settings = { { key = "time", name = "Время суток", min = 0, max = 24, default = 14, step = .1 } },
		onChange = V2.updateClock })
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
	local wsHum, wsBase, wsReturn = nil, 16, false
	local function restoreWalk()
		if wsHum and wsHum.Parent then wsHum.WalkSpeed = wsBase end
		wsHum, wsReturn = nil, false
	end
	local function takeWalk(humanoid)
		if wsHum ~= humanoid then
			restoreWalk()
			if humanoid then wsHum, wsBase = humanoid, humanoid.WalkSpeed end
		end
	end
	feature({ tab = "Utilities", name = "Smooth WalkSpeed", key = "walk", icon = "speed", bind = Enum.KeyCode.C,
		settings = { { key = "speed", name = "Скорость", min = 16, max = 120, default = 32 }, { key = "smooth", name = "Плавность", min = 1, max = 20, default = 6 } },
		onChange = function(on)
			local _, hum = getChar()
			if on then takeWalk(hum) end
			wsReturn = not on and wsHum ~= nil
		end })

	-- ===================== МИР, ПОГОДА И КАМЕРА =====================
	do
		local terrain = workspace.Terrain
		local spark = "rbxasset://textures/particles/sparkles_main.dds"
		local smoke = "rbxasset://textures/particles/smoke_main.dds"
		local skyNames = { "Золотой час", "Полярное утро", "Ясная ночь" }
		local skyStyles = {
			{ 17.6, 400, Color3.fromRGB(255, 187, 146), Color3.fromRGB(192, 110, 105), 1.6 },
			{ 7.2, 850, Color3.fromRGB(180, 226, 255), Color3.fromRGB(109, 144, 180), 1.1 },
			{ 0.4, 4000, Color3.fromRGB(127, 155, 219), Color3.fromRGB(74, 83, 139), .3 },
		}
		local atmosphere, atmosphereBase, ownsAtmosphere

		function V2.syncAtmosphere()
			local style = F.sky and F.sky.active and skyStyles[F.sky.v.preset]
			local fog = F.weather and F.weather.active and F.weather.v.kind == 3
			local clear = F.nofog.active
			local wanted = style or fog or (clear and not ownsAtmosphere and Lighting:FindFirstChildOfClass("Atmosphere"))
			if atmosphere and (not wanted or atmosphere.Parent ~= Lighting) then
				if ownsAtmosphere then
					atmosphere:Destroy()
				elseif atmosphere.Parent == Lighting then
					for key, value in pairs(atmosphereBase) do atmosphere[key] = value end
				end
				atmosphere, atmosphereBase, ownsAtmosphere = nil, nil, false
			end
			if not wanted then return end
			if not atmosphere then
				atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
				ownsAtmosphere = atmosphere == nil
				if ownsAtmosphere then
					if not style and not fog then return end
					atmosphere = new("Atmosphere", { Name = "OV_Atmosphere" }, Lighting)
				end
				atmosphereBase = {
					Color = atmosphere.Color, Decay = atmosphere.Decay, Density = atmosphere.Density,
					Haze = atmosphere.Haze, Glare = atmosphere.Glare,
				}
			end
			local base = atmosphereBase
			atmosphere.Color = fog and Color3.fromRGB(196, 208, 216) or (style and style[3] or base.Color)
			atmosphere.Decay = style and style[4] or base.Decay
			atmosphere.Density = (clear and 0) or (fog and .55) or (style and .25) or base.Density
			atmosphere.Haze = (clear and 0) or (fog and 3.5) or (style and style[5]) or base.Haze
			atmosphere.Glare = (clear and 0) or (style and .15) or base.Glare
		end

		local sky, parkedSkies
		local function updateSky(active)
			if sky then sky:Destroy() sky = nil end
			if not active then
				if parkedSkies then
					for _, original in ipairs(parkedSkies:GetChildren()) do original.Parent = Lighting end
					parkedSkies:Destroy()
					parkedSkies = nil
				end
				V2.skyClock = nil
			else
				if not parkedSkies then
					parkedSkies = new("Folder", { Name = "OV_OriginalSkies" }, fx)
					for _, child in ipairs(Lighting:GetChildren()) do
						if child:IsA("Sky") then child.Parent = parkedSkies end
					end
				end
				local index = F.sky.v.preset
				local style = skyStyles[index]
				local library = ReplicatedStorage:FindFirstChild("OrangeVisualsSkies")
				local custom = library and library:FindFirstChild(skyNames[index])
				sky = custom and custom:IsA("Sky") and custom:Clone() or Instance.new("Sky")
				sky.Name, sky.StarCount, sky.Parent = "OV_Sky", style[2], Lighting
				V2.skyClock = style[1]
			end
			V2.updateClock()
			V2.syncAtmosphere()
		end

		feature({ tab = "Visuals", name = "Sky Changer", key = "sky", icon = "sun",
			settings = { { key = "preset", name = "Небо", options = skyNames, default = 1 } },
			onChange = updateSky,
			changed = function() if F.sky.active then updateSky(true) end end })

		local skyAnchor, skyEmitters
		local function buildSkyParticles(active)
			if skyAnchor then skyAnchor:Destroy() end
			skyAnchor, skyEmitters = nil, nil
			if not active then return end
			skyAnchor = fxPart({
				Name = "OV_SkyParticles", Size = Vector3.new(240, 85, 240), Transparency = 1,
				Position = cam.CFrame.Position + Vector3.new(0, 116, 0),
			})
			local settings = F.skyParticles.v
			local function emit(key, rate, texture, size, lifetime, color, fade)
				local enabled = settings[key]
				local emitter = new("ParticleEmitter", {
					Enabled = enabled, Texture = texture, Rate = rate * settings.density,
					Lifetime = lifetime, Speed = NumberRange.new(.15, .75),
					SpreadAngle = Vector2.new(180, 180), LightEmission = .9, LightInfluence = 0,
					LockedToPart = true, Size = size, Color = color, Transparency = fade,
					Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-8, 8),
				}, skyAnchor)
				if enabled then emitter:Emit(math.floor(rate * settings.density * 2)) end
				return { emitter = emitter, rate = rate }
			end
			local fade = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.25, .08),
				NumberSequenceKeypoint.new(.65, .4), NumberSequenceKeypoint.new(1, 1),
			})
			skyEmitters = {
				stars = emit("stars", 8, spark, NumberSequence.new(1.05, .45), NumberRange.new(4, 7),
					ColorSequence.new(Color3.fromRGB(254, 244, 222), Color3.fromRGB(191, 222, 255)), fade),
				shimmer = emit("shimmer", 5, spark, NumberSequence.new(1.7, .2), NumberRange.new(3, 6),
					ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(114, 232, 255)),
						ColorSequenceKeypoint.new(.5, Color3.fromRGB(224, 140, 255)),
						ColorSequenceKeypoint.new(1, ACCENT2),
					}), fade),
				clouds = emit("clouds", 1.5, smoke, NumberSequence.new(19, 38), NumberRange.new(7, 10),
					ColorSequence.new(Color3.fromRGB(220, 180, 245), Color3.fromRGB(139, 178, 235)),
					NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.4, .82),
						NumberSequenceKeypoint.new(1, 1),
					})),
			}
		end

		feature({ tab = "Visuals", name = "Sky Particles", key = "skyParticles", icon = "star", heavy = true,
			settings = {
				{ key = "stars", name = "Звёзды", type = "bool", default = true },
				{ key = "shimmer", name = "Переливающиеся частицы", type = "bool", default = true },
				{ key = "clouds", name = "Светящиеся облака", type = "bool", default = true },
				{ key = "density", name = "Плотность", min = .25, max = 1.5, step = .05, default = 1 },
			},
			onChange = buildSkyParticles,
			changed = function(key)
				if not skyEmitters then return end
				local settings = F.skyParticles.v
				if key == "density" then
					for _, entry in pairs(skyEmitters) do entry.emitter.Rate = entry.rate * settings.density end
				else
					local entry = skyEmitters[key]
					entry.emitter.Enabled = settings[key]
					if not settings[key] then entry.emitter:Clear() end
				end
			end })

		local weatherAnchor, weatherEmitter
		local weatherModes = { "Дождь", "Снег", "Туман", "Пыльца" }
		local function updateWeather(active)
			if weatherAnchor then weatherAnchor:Destroy() end
			weatherAnchor, weatherEmitter = nil, nil
			V2.syncAtmosphere()
			local mode = F.weather.v.kind
			if not active or mode == 3 then return end
			weatherAnchor = fxPart({
				Name = "OV_Weather", Size = Vector3.new(50, .1, 50), Transparency = 1,
				Position = cam.CFrame.Position + Vector3.new(0, 17, 0),
			})
			local rain, snow = mode == 1, mode == 2
			weatherEmitter = new("ParticleEmitter", {
				Texture = rain and "rbxasset://textures/particles/sparkles_main.dds" or (snow and smoke or spark),
				Rate = F.weather.v.rate, Lifetime = rain and NumberRange.new(.48, .7) or NumberRange.new(2.4, 3.3),
				Speed = rain and NumberRange.new(42, 52) or (snow and NumberRange.new(6, 9) or NumberRange.new(3, 6)),
				EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(7, 7),
				Orientation = rain and Enum.ParticleOrientation.VelocityParallel or Enum.ParticleOrientation.FacingCamera,
				Squash = NumberSequence.new(rain and -0.83 or 0),
				Size = NumberSequence.new(rain and .65 or (snow and .48 or .27)),
				Color = ColorSequence.new(rain and Color3.fromRGB(169, 213, 255) or (snow and TXT or ACCENT2)),
				Transparency = NumberSequence.new(.15, .85), LightEmission = .55,
			}, weatherAnchor)
		end

		feature({ tab = "Visuals", name = "Weather Effects", key = "weather", icon = "sun", heavy = true,
			settings = {
				{ key = "kind", name = "Погода", options = weatherModes, default = 1 },
				{ key = "rate", name = "Частиц в секунду", min = 8, max = 85, default = 50 },
			},
			onChange = updateWeather,
			changed = function(key)
				if not F.weather.active then return end
				if key == "kind" then
					updateWeather(true)
				elseif weatherEmitter then
					weatherEmitter.Rate = F.weather.v.rate
				end
			end })

		local glowItems = {}
		local glowTag = "OrangeVisualsGlow"
		local glowClock = 0
		local function clearGlow()
			for object, highlight in pairs(glowItems) do
				highlight:Destroy()
				glowItems[object] = nil
			end
		end
		feature({ tab = "Visuals", name = "World Glow", key = "worldGlow", icon = "star", heavy = true,
			hint = "Поверхности с тегом OrangeVisualsGlow",
			settings = { { key = "distance", name = "Дистанция", min = 30, max = 300, default = 95 } },
			onChange = function(active) if active then glowClock = 1 else clearGlow() end end })

		local motionBlur
		local lastLook
		local cameraRoll = 0
		local edgeFlash
		local edgeImages = {}
		local edgeAmount = 0
		feature({ tab = "Visuals", name = "Motion Blur", key = "motionBlur", icon = "speed", heavy = true,
			settings = { { key = "strength", name = "Сила", min = 2, max = 24, default = 12 } },
			onChange = function(active)
				if motionBlur then motionBlur:Destroy() motionBlur = nil end
				if active then motionBlur = new("BlurEffect", { Name = "OV_MotionBlur", Size = 0 }, Lighting) end
				lastLook = nil
			end })
		feature({ tab = "Visuals", name = "Camera Tilt", key = "tilt", icon = "eye",
			settings = { { key = "angle", name = "Максимальный наклон", min = 1, max = 12, default = 6 } } })
		feature({ tab = "Visuals", name = "Speed Effects", key = "speedFx", icon = "speed",
			settings = { { key = "threshold", name = "Порог скорости", min = 8, max = 60, default = 18 } },
			onChange = function(active)
				if edgeFlash then edgeFlash:Destroy() edgeFlash = nil end
				table.clear(edgeImages)
				edgeAmount = 0
				if not active then return end
				edgeFlash = new("Frame", {
					Name = "OV_SpeedEdges", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0,
				}, gui)
				for _, side in ipairs({ 0, 1 }) do
					local edge = new("Frame", {
						AnchorPoint = Vector2.new(side, 0), Position = UDim2.fromScale(side, 0),
						Size = UDim2.fromScale(.16, 1), BackgroundColor3 = ACCENT,
						BackgroundTransparency = 1, BorderSizePixel = 0,
					}, edgeFlash)
					new("UIGradient", { Rotation = side * 180, Transparency = NumberSequence.new(.12, 1) }, edge)
					table.insert(edgeImages, edge)
				end
			end })

		function V2.worldStep(dt, t, root)
			local position = cam.CFrame.Position
			if skyAnchor then skyAnchor.Position = position + Vector3.new(0, 116, 0) end
			if weatherAnchor then weatherAnchor.Position = position + Vector3.new(0, 17, 0) end

			if F.worldGlow.active then
				glowClock += dt
				if glowClock >= .35 then
					glowClock = 0
					local nearby = {}
					for _, object in ipairs(CollectionService:GetTagged(glowTag)) do
						if object:IsA("BasePart") and object:IsDescendantOf(workspace) then
							local distance = (object:GetClosestPointOnSurface(position) - position).Magnitude
							if distance <= F.worldGlow.v.distance then
								table.insert(nearby, { object = object, distance = distance })
							end
						end
					end
					table.sort(nearby, function(a, b) return a.distance < b.distance end)
					local visible = {}
					local budget = F.esp.active and 7 or 16
					for i = 1, math.min(budget, #nearby) do visible[nearby[i].object] = true end
					for object, highlight in pairs(glowItems) do
						if not visible[object] then highlight:Destroy() glowItems[object] = nil end
					end
					for object in pairs(visible) do
						if not glowItems[object] then
							glowItems[object] = new("Highlight", {
								Name = "OV_WorldGlow", Adornee = object, FillTransparency = 1,
								OutlineTransparency = .25, DepthMode = Enum.HighlightDepthMode.Occluded,
							}, fx)
						end
					end
				end
				local color = ACCENT:Lerp(ACCENT2, .5 + .5 * math.sin(t * 2))
				for _, highlight in pairs(glowItems) do highlight.OutlineColor = color end
			end

			if edgeFlash then
				local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
				local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
				local amount = math.clamp((speed - F.speedFx.v.threshold) / 26, 0, 1) * .65
				edgeAmount += (amount - edgeAmount) * (1 - math.exp(-dt * 9))
				for _, edge in ipairs(edgeImages) do edge.BackgroundTransparency = 1 - edgeAmount end
			end
		end

		function V2.cameraStep(dt, base)
			local look = base.LookVector
			if motionBlur then
				local turn = lastLook and math.acos(math.clamp(lastLook:Dot(look), -1, 1)) / math.max(dt, .001) or 0
				local size = V2.menuOpen and 0 or math.min(turn / 5, 1) * F.motionBlur.v.strength
				motionBlur.Size += (size - motionBlur.Size) * (1 - math.exp(-dt * 14))
				lastLook = look
			end
			local wantedRoll = 0
			if F.tilt.active then
				local _, humanoid = getChar()
				if humanoid then
					wantedRoll = -humanoid.MoveDirection:Dot(base.RightVector) * math.rad(F.tilt.v.angle)
				end
			end
			cameraRoll += (wantedRoll - cameraRoll) * (1 - math.exp(-dt * 9))
			if math.abs(cameraRoll) < .0001 and wantedRoll == 0 then cameraRoll = 0 end
			return cameraRoll
		end
	end

	-- ===================== HUD, ОФОРМЛЕНИЕ И РЕАКЦИЯ =====================
	do
		local glassLayer
		function V2.refreshGlass()
			if not V2.main then return end
			local active = F.glass.active
			V2.main.BackgroundTransparency = active and .15 or 0
			if glassLayer then glassLayer:Destroy() glassLayer = nil end
			if active then
				glassLayer = new("UIGradient", {
					Rotation = 28,
					Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(194, 182, 175)),
				}, V2.main)
			end
		end
		feature({ tab = "Utilities", name = "Liquid Glass UI", key = "glass", icon = "grid", defaultOn = true,
			onChange = function()
				V2.refreshGlass()
				if V2.menuOpen then tw(blur, .25, { Size = V2.menuBlur() }) end
			end })
		feature({ tab = "Utilities", name = "FPS Mode", key = "fpsMode", icon = "speed",
			hint = "Приостанавливает тяжёлые эффекты, пока режим включён",
			onChange = function(active)
				for _, f in ipairs(featureList) do
					if f.heavy then applyFeature(f) end
				end
				if V2.menuOpen then tw(blur, .25, { Size = V2.menuBlur() }) end
				V2.notify(active and "Режим FPS включён" or "Режим FPS выключен")
			end })
		function V2.menuBlur()
			return F.glass.active and not F.fpsMode.active and 14 or 0
		end

		local defaultPalette = { ACCENT, ACCENT2, BG, BG2, BG3, TXT, DIM }
		local function applyTheme()
			local previous = { ACCENT, ACCENT2, BG, BG2, BG3, TXT, DIM }
			local nextPalette = table.clone(defaultPalette)
			local v = F.theme.v
			if F.theme.active then
				nextPalette[1] = Color3.fromHSV(v.hue / 360, .94, 1)
				nextPalette[2] = Color3.fromHSV(((v.hue + 9) % 360) / 360, .67, 1)
				nextPalette[3] = Color3.fromRGB(v.shade, v.shade, v.shade + 2)
				nextPalette[4] = Color3.fromRGB(v.shade + 10, v.shade + 10, v.shade + 14)
				nextPalette[5] = Color3.fromRGB(v.shade + 28, v.shade + 28, v.shade + 34)
				nextPalette[6] = Color3.fromRGB(v.text, v.text, v.text)
				nextPalette[7] = Color3.fromRGB(v.text - 90, v.text - 90, v.text - 80)
			end
			ACCENT, ACCENT2, BG, BG2, BG3, TXT, DIM = table.unpack(nextPalette)
			local function recolor(instance, property)
				local current = instance[property]
				for i, oldColor in ipairs(previous) do
					if current == oldColor then instance[property] = nextPalette[i] return end
				end
			end
			for _, item in ipairs(gui:GetDescendants()) do
				if item:IsA("GuiObject") then recolor(item, "BackgroundColor3") end
				if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then recolor(item, "TextColor3") end
				if item:IsA("TextBox") then recolor(item, "PlaceholderColor3") end
				if item:IsA("UIStroke") then recolor(item, "Color") end
				if item:IsA("ScrollingFrame") then recolor(item, "ScrollBarImageColor3") end
			end
		end
		feature({ tab = "Utilities", name = "Theme Editor", key = "theme", icon = "gear",
			settings = {
				{ key = "hue", name = "Оттенок акцента", min = 0, max = 359, default = 30 },
				{ key = "shade", name = "Яркость фона", min = 6, max = 44, default = 12 },
				{ key = "text", name = "Яркость текста", min = 195, max = 255, default = 235 },
			},
			onChange = applyTheme,
			changed = function() if F.theme.active then applyTheme() end end })

		local note, noteText, noteTween, noteSerial = nil, nil, nil, 0
		local function cancelNotice()
			noteSerial += 1
			if noteTween then noteTween:Cancel() noteTween = nil end
			if note then note:Destroy() note, noteText = nil, nil end
		end
		feature({ tab = "HUD", name = "Notifications", key = "notifications", icon = "orb", defaultOn = true,
			onChange = function(active) if not active then cancelNotice() end end })

		function V2.notify(message)
			if not V2.alive or not F.notifications.active then return end
			if not note then
				note = new("CanvasGroup", {
					Name = "OV_Notification", Size = UDim2.new(.88, 0, 0, 46), AnchorPoint = Vector2.new(.5, 1),
					Position = UDim2.new(.5, 0, 1, 8), BackgroundColor3 = BG2, BackgroundTransparency = .06,
					GroupTransparency = 1, ZIndex = 8,
				}, gui)
				new("UISizeConstraint", { MaxSize = Vector2.new(315, 46) }, note)
				corner(note, 12)
				stroke(note, ACCENT, 1, .4)
				noteText = label(note, "", 12, TXT, BOLD, Enum.TextXAlignment.Center)
				noteText.Size = UDim2.new(1, -20, 1, 0)
				noteText.Position = UDim2.fromOffset(10, 0)
				noteText.TextWrapped = true
			end
			noteSerial += 1
			local ticket = noteSerial
			noteText.Text = message
			if noteTween then noteTween:Cancel() end
			noteTween = TweenService:Create(note, TweenInfo.new(.24, Enum.EasingStyle.Quint), {
				GroupTransparency = 0, Position = UDim2.new(.5, 0, 1, -28),
			})
			noteTween:Play()
			task.delay(2.7, function()
				if ticket ~= noteSerial or not note then return end
				noteTween = TweenService:Create(note, TweenInfo.new(.2), {
					GroupTransparency = 1, Position = UDim2.new(.5, 0, 1, 8),
				})
				noteTween:Play()
				task.delay(.22, function() if ticket == noteSerial then cancelNotice() end end)
			end)
		end

		local watermark, watermarkText
		feature({ tab = "HUD", name = "Watermark", key = "watermark", icon = "star",
			onChange = function(active)
				if watermark then watermark:Destroy() watermark, watermarkText = nil, nil end
				if not active then return end
				watermark = new("Frame", {
					Name = "OV_Watermark", Size = UDim2.fromOffset(264, 28), AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 12, 1, -14), BackgroundColor3 = BG, BackgroundTransparency = .13,
				}, gui)
				corner(watermark, 9)
				stroke(watermark, ACCENT, 1, .5)
				watermarkText = label(watermark, "", 11, TXT, BOLD, Enum.TextXAlignment.Center)
				watermarkText.Size = UDim2.fromScale(1, 1)
			end })

		local keyPanel, keyTiles = nil, {}
		local keyNames = {
			{ Enum.KeyCode.W, "W", 38, 0, 34 }, { Enum.KeyCode.A, "A", 0, 38, 34 },
			{ Enum.KeyCode.S, "S", 38, 38, 34 }, { Enum.KeyCode.D, "D", 76, 38, 34 },
			{ Enum.KeyCode.Space, "SPACE", 0, 76, 110 },
		}
		feature({ tab = "HUD", name = "Keystrokes", key = "keystrokes", icon = "grid",
			onChange = function(active)
				if keyPanel then keyPanel:Destroy() keyPanel = nil end
				table.clear(keyTiles)
				if not active then return end
				keyPanel = new("Frame", {
					Name = "OV_Keystrokes", Size = UDim2.fromOffset(110, 110), AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -16, 1, -68), BackgroundTransparency = 1,
				}, gui)
				for _, key in ipairs(keyNames) do
					local tile = label(keyPanel, key[2], 12, TXT, BOLD, Enum.TextXAlignment.Center)
					tile.Size, tile.Position = UDim2.fromOffset(key[5], 34), UDim2.fromOffset(key[3], key[4])
					tile.BackgroundColor3, tile.BackgroundTransparency = BG2, .11
					corner(tile, 8)
					stroke(tile, ACCENT, 1, .5)
					keyTiles[key[1]] = { tile = tile, down = false }
				end
			end })

		local reactionPanel, reactionButton, reactionSerial, reactionState, reactionStart = nil, nil, 0, "ready", 0
		feature({ tab = "Utilities", name = "Reaction Test", key = "reaction", icon = "speed",
			onChange = function(active)
				reactionSerial += 1
				reactionState = "ready"
				if reactionPanel then reactionPanel:Destroy() reactionPanel = nil end
				if not active then return end
				if V2.setOpen then V2.setOpen(false) end
				reactionPanel = new("Frame", {
					Name = "OV_Reaction", Size = UDim2.new(.86, 0, 0, 167), AnchorPoint = Vector2.new(.5, .5),
					Position = UDim2.fromScale(.5, .5), BackgroundColor3 = BG, ZIndex = 5,
				}, gui)
				new("UISizeConstraint", { MaxSize = Vector2.new(370, 167) }, reactionPanel)
				corner(reactionPanel, 14)
				stroke(reactionPanel, ACCENT, 1, .4)
				local heading = label(reactionPanel, "Тест реакции", 15, TXT, BOLD)
				heading.Position, heading.Size = UDim2.fromOffset(14, 0), UDim2.new(1, -50, 0, 40)
				local close = new("TextButton", {
					Text = "×", TextSize = 22, TextColor3 = DIM, BackgroundTransparency = 1,
					Position = UDim2.new(1, -39, 0, 0), Size = UDim2.fromOffset(37, 37),
				}, reactionPanel)
				on(close.Activated, function() setFeature(F.reaction, false) end)
				reactionButton = new("TextButton", {
					Text = "Начать", TextSize = 15, TextColor3 = TXT, Font = BOLD,
					BackgroundColor3 = BG2, AutoButtonColor = false, Size = UDim2.new(1, -24, 1, -53),
					Position = UDim2.fromOffset(12, 41),
				}, reactionPanel)
				corner(reactionButton, 10)
				on(reactionButton.MouseButton1Down, function()
					if reactionState == "ready" then
						reactionState = "wait"
						reactionButton.Text = "Дождитесь зелёного"
						reactionButton.BackgroundColor3 = Color3.fromRGB(134, 54, 39)
						reactionSerial += 1
						local ticket = reactionSerial
						task.delay(Random.new():NextNumber(1.5, 4.2), function()
							if ticket ~= reactionSerial or reactionState ~= "wait" then return end
							reactionState, reactionStart = "go", os.clock()
							reactionButton.Text = "Нажмите!"
							reactionButton.BackgroundColor3 = Color3.fromRGB(28, 123, 78)
						end)
					elseif reactionState == "wait" then
						reactionState = "ready"
						reactionSerial += 1
						reactionButton.BackgroundColor3 = BG2
						reactionButton.Text = "Слишком рано · повторить"
					else
						local milliseconds = math.floor((os.clock() - reactionStart) * 1000 + .5)
						reactionState = "ready"
						reactionButton.BackgroundColor3 = BG2
						reactionButton.Text = string.format("%d мс · повторить", milliseconds)
						V2.notify(string.format("Реакция: %d мс", milliseconds))
					end
				end)
			end })

		local hudClock = 0
		function V2.hudStep(dt, fps)
			for key, item in pairs(keyTiles) do
				local down = not UIS:GetFocusedTextBox() and UIS:IsKeyDown(key)
				if item.down ~= down then
					item.down = down
					tw(item.tile, .12, { BackgroundColor3 = down and ACCENT or BG2 })
				end
			end
			if not watermarkText then return end
			hudClock += dt
			if hudClock < .33 then return end
			hudClock = 0
			local ok, ping = pcall(lp.GetNetworkPing, lp)
			watermarkText.Text = string.format("ORANGE  ·  %d FPS  ·  %s  ·  %s",
				math.floor(fps + .5), ok and string.format("%d ms", ping * 1000) or "—", os.date("%H:%M"))
		end
	end

	-- ===================== МУЗЫКАЛЬНЫЙ HUD =====================
	do
		local playbackEvent = "OV_NowPlaying"
		local maxAge = 15
		local bridgeState

		local function finite(value)
			return type(value) == "number" and value == value and math.abs(value) < math.huge
		end
		local function trackText(value, fallback)
			if type(value) == "string" and #value > 0 and #value <= 512 and utf8.len(value) then
				local cleaned = string.match(value:gsub("[%c]", " "), "^%s*(.-)%s*$")
				if cleaned ~= "" then return cleaned end
			end
			return fallback
		end
		local function coverId(value)
			if type(value) == "string" and #value <= 34 and value:match("^rbxassetid://[1-9]%d*$") then return value end
			return ""
		end
		local function decodePlayback(state)
			if type(state) ~= "table" or state.playing ~= true then return nil end
			if not finite(state.updatedAt) or not finite(state.durationMs) or not finite(state.progressMs) then return nil end
			if state.durationMs <= 0 or state.durationMs > 86400000 or state.progressMs < 0 or state.progressMs >= state.durationMs then
				return nil
			end
			local title = trackText(state.title)
			if not title then return nil end
			return {
				title = title, artist = trackText(state.artist, "Внешний источник"), cover = coverId(state.coverAsset),
				updatedAt = state.updatedAt, duration = state.durationMs / 1000, position = state.progressMs / 1000,
			}
		end
		local function bridgeProgress(state, now)
			if not state then return nil end
			local age = now - state.updatedAt
			if age > maxAge or age < -2 then return nil end
			local position = state.position + math.max(age, 0)
			if position >= state.duration then return nil end
			return position
		end
		local bridgeRemote, bridgeConnection
		local function connectBridge()
			if bridgeConnection then bridgeConnection:Disconnect() bridgeConnection = nil end
			bridgeState = nil
			bridgeRemote = ReplicatedStorage:FindFirstChild(playbackEvent)
			if bridgeRemote and bridgeRemote:IsA("RemoteEvent") then
				bridgeConnection = bridgeRemote.OnClientEvent:Connect(function(data)
					bridgeState = decodePlayback(data)
				end)
			end
		end
		connectBridge()
		on(ReplicatedStorage.ChildAdded, function(child)
			if child.Name == playbackEvent then connectBridge() end
		end)
		on(ReplicatedStorage.ChildRemoved, function(child)
			if child == bridgeRemote then connectBridge() end
		end)
		function V2.disconnectMusic()
			if bridgeConnection then bridgeConnection:Disconnect() end
		end

		local function readPlayback()
			if bridgeState then
				local position = bridgeProgress(bridgeState, workspace:GetServerTimeNow())
				if position then return bridgeState.title, bridgeState.artist, bridgeState.cover, position, bridgeState.duration, nil end
			end
			local sound = SoundService:FindFirstChild("OrangeVisualsMusic")
			if not sound or not sound:IsA("Sound") or not sound.IsLoaded or not sound.IsPlaying or sound.TimeLength <= 0 then return nil end
			return trackText(sound:GetAttribute("TrackTitle"), "Музыка плейса"),
				trackText(sound:GetAttribute("TrackArtist"), "Roblox"), coverId(sound:GetAttribute("CoverAsset")),
				sound.TimePosition, sound.TimeLength, sound.PlaybackLoudness
		end

		local panel, title, artist, cover, fallback, progress, durationLabel
		local equalizer = {}
		local showing, currentTween, visibilityTicket = false, nil, 0
		local oldTitle, oldArtist, oldCover
		local clock = 0
		local shownPosition = UDim2.new(.5, 0, 0, 43)
		local hiddenPosition = UDim2.new(.5, 0, 0, 27)

		local function setShowing(wanted, force)
			if showing == wanted and not force then return end
			showing = wanted
			visibilityTicket += 1
			local ticket = visibilityTicket
			if currentTween then currentTween:Cancel() currentTween = nil end
			if not panel then return end
			local transparency = wanted and 0 or 1
			local position = wanted and shownPosition or hiddenPosition
			if not F.island.active or F.fpsMode.active then
				panel.GroupTransparency, panel.Position, panel.Visible = transparency, position, wanted
				return
			end
			if wanted then panel.Visible = true end
			currentTween = TweenService:Create(panel, TweenInfo.new(.24, Enum.EasingStyle.Quint), {
				Position = position, GroupTransparency = transparency,
			})
			currentTween:Play()
			if not wanted then
				task.delay(.26, function()
					if panel and visibilityTicket == ticket then panel.Visible = false end
				end)
			end
		end

		local function buildPanel(active)
			setShowing(false, true)
			if currentTween then currentTween:Cancel() currentTween = nil end
			if panel then panel:Destroy() panel = nil end
			table.clear(equalizer)
			oldTitle, oldArtist, oldCover = nil, nil, nil
			clock = 1
			if not active then return end
			panel = new("CanvasGroup", {
				Name = "OV_Music", Size = UDim2.new(.92, 0, 0, 76), AnchorPoint = Vector2.new(.5, 0),
				Position = hiddenPosition, Visible = false, GroupTransparency = 1, BackgroundColor3 = BG,
				BackgroundTransparency = .12, ZIndex = 4,
			}, gui)
			new("UISizeConstraint", { MaxSize = Vector2.new(342, 76) }, panel)
			corner(panel, 20)
			stroke(panel, ACCENT, 1, .47)
			local album = new("Frame", {
				Position = UDim2.fromOffset(11, 11), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = BG3,
				ClipsDescendants = true,
			}, panel)
			corner(album, 10)
			fallback = label(album, "♪", 26, ACCENT2, BOLD, Enum.TextXAlignment.Center)
			fallback.Size = UDim2.fromScale(1, 1)
			cover = new("ImageLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false,
			}, album)
			title = label(panel, "", 14, TXT, BOLD)
			title.Position, title.Size = UDim2.fromOffset(75, 9), UDim2.new(1, -126, 0, 21)
			title.TextTruncate = Enum.TextTruncate.AtEnd
			artist = label(panel, "", 12, DIM)
			artist.Position, artist.Size = UDim2.fromOffset(75, 29), UDim2.new(1, -126, 0, 17)
			artist.TextTruncate = Enum.TextTruncate.AtEnd
			local track = new("Frame", {
				Position = UDim2.fromOffset(75, 56), Size = UDim2.new(1, -147, 0, 4),
				BackgroundColor3 = BG3, BorderSizePixel = 0, ClipsDescendants = true,
			}, panel)
			corner(track, 2)
			progress = new("Frame", {
				Size = UDim2.fromScale(0, 1), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
			}, track)
			corner(progress, 2)
			durationLabel = label(panel, "", 10, DIM, FONT, Enum.TextXAlignment.Right)
			durationLabel.Position, durationLabel.Size = UDim2.new(1, -69, 0, 50), UDim2.fromOffset(57, 15)
			for i = 1, 4 do
				local bar = new("Frame", {
					Position = UDim2.new(1, -37 + (i - 1) * 7, 0, 41), AnchorPoint = Vector2.new(0, 1),
					Size = UDim2.fromOffset(4, 3), BorderSizePixel = 0, BackgroundColor3 = ACCENT2,
				}, panel)
				corner(bar, 2)
				equalizer[i] = bar
			end
		end

		feature({ tab = "HUD", name = "Music HUD", key = "music", icon = "orb", defaultOn = true,
			hint = "Появляется при получении данных о воспроизведении",
			settings = {
				{ key = "art", name = "Обложка", type = "bool", default = true },
				{ key = "bars", name = "Анимация полос", type = "bool", default = true },
			},
			onChange = buildPanel })
		feature({ tab = "HUD", name = "Dynamic Island", key = "island", icon = "orb", defaultOn = true,
			hint = "Плавное появление и скрытие музыкального HUD",
			onChange = function() setShowing(showing, true) end })

		local function timestamp(seconds)
			return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds) % 60)
		end
		function V2.musicStep(dt, t)
			if not panel then return end
			clock += dt
			if clock < (F.fpsMode.active and .33 or .085) then return end
			clock = 0
			local trackTitle, trackArtist, asset, position, duration, loudness = readPlayback()
			setShowing(trackTitle ~= nil)
			if not trackTitle then return end
			if trackTitle ~= oldTitle then title.Text, oldTitle = trackTitle, trackTitle end
			if trackArtist ~= oldArtist then artist.Text, oldArtist = trackArtist, trackArtist end
			if asset ~= oldCover then cover.Image, oldCover = asset, asset end
			cover.Visible = F.music.v.art and asset ~= ""
			fallback.Visible = not cover.Visible or not cover.IsLoaded
			progress.Size = UDim2.fromScale(math.clamp(position / duration, 0, 1), 1)
			durationLabel.Text = timestamp(position) .. " / " .. timestamp(duration)
			for i, bar in ipairs(equalizer) do
				bar.Visible = F.music.v.bars
				local strength = loudness and math.clamp(loudness / 500, 0, 1) or .56
				local wave = F.fpsMode.active and 0 or (.55 + .45 * math.sin(t * (6 + i * 1.3) + i))
				bar.Size = UDim2.fromOffset(4, 3 + 15 * strength * wave)
			end
		end
	end

	-- ===================== ЭФФЕКТЫ ПЕРСОНАЖА =====================
	do
		local wingStyles = {
			{ "Перья", 8, 36, 12, 3.65, .48, Color3.fromRGB(255, 197, 97), "feather" },
			{ "Феникс", 7, 60, 16, 4.2, .47, Color3.fromRGB(255, 85, 34), "feather" },
			{ "Мотылёк", 5, 44, 22, 2.6, .82, Color3.fromRGB(241, 166, 244), "round" },
			{ "Бабочка", 4, 63, 34, 3.1, 1.08, Color3.fromRGB(123, 185, 255), "round" },
			{ "Гарпия", 9, 29, 9, 4.05, .32, Color3.fromRGB(229, 218, 188), "feather" },
			{ "Серафим", 7, 66, 20, 3.75, .40, Color3.fromRGB(255, 239, 201), "double" },
			{ "Ворон", 9, 22, 10, 4.25, .37, Color3.fromRGB(111, 102, 179), "feather" },
			{ "Дракон", 5, 49, 21, 4.1, .68, Color3.fromRGB(118, 239, 166), "blade" },
			{ "Летучая мышь", 5, 22, 17, 3.55, .76, Color3.fromRGB(192, 89, 201), "blade" },
			{ "Кристалл", 6, 36, 14, 3.6, .45, Color3.fromRGB(119, 239, 255), "shard" },
			{ "Голограмма", 8, 42, 13, 3.15, .25, Color3.fromRGB(112, 252, 214), "shard" },
			{ "Кибер", 5, 27, 9, 3.85, .31, Color3.fromRGB(255, 191, 31), "strut" },
			{ "Реактивные", 4, 12, 9, 3.6, .36, Color3.fromRGB(255, 113, 69), "strut" },
			{ "Ледяные", 6, 55, 18, 4.0, .55, Color3.fromRGB(183, 229, 255), "shard" },
			{ "Спектр", 7, 48, 15, 3.8, .46, Color3.fromRGB(255, 160, 80), "spectrum" },
		}
		local wingNames = {}
		for i, style in ipairs(wingStyles) do wingNames[i] = style[1] end
		local customFolder, customParts
		local function buildCustomWings(active)
			if customFolder then customFolder:Destroy() end
			customFolder, customParts = nil, nil
			if not active then return end
			customFolder = new("Folder", { Name = "OV_CustomWings" }, fx)
			customParts = {}
			local v = F.customWings.v
			local style = wingStyles[v.style]
			local shape = style[8]
			for side = -1, 1, 2 do
				for i = 1, style[2] do
					local fraction = (i - 1) / math.max(style[2] - 1, 1)
					local length = style[5] * (1 - .63 * fraction) * v.size
					if shape == "round" then length *= .68 + .32 * math.sin(math.pi * (fraction * .82 + .12)) end
					local width = style[6] * (1 - .44 * fraction) * v.size
					local p = fxPart({
						Size = Vector3.new(length, shape == "shard" and .17 or .1, width),
						Transparency = 1, Color = style[7]:Lerp(ACCENT2, fraction * .38),
						Shape = shape == "round" and Enum.PartType.Ball or Enum.PartType.Block,
					})
					p.Parent = customFolder
					if shape == "blade" or shape == "shard" then
						new("SpecialMesh", { MeshType = Enum.MeshType.Wedge, Scale = Vector3.new(1, .9, 1) }, p)
					end
					local layer = shape == "double" and ((i - 1) % 2) or 0
					table.insert(customParts, {
						part = p, side = side, offset = length / 2, layer = layer, index = i,
						angle = math.rad(style[3] - (i - 1) * style[4] + layer * 8),
						progress = fraction,
					})
				end
			end
		end
		feature({ tab = "Visuals", name = "Custom Wings", key = "customWings", icon = "wing", heavy = true,
			settings = {
				{ key = "style", name = "Модель", options = wingNames, default = 1 },
				{ key = "size", name = "Размер", min = .5, max = 2, step = .1, default = 1 },
				{ key = "speed", name = "Скорость взмаха", min = .5, max = 8, step = .1, default = 3 },
			},
			onChange = function(active)
				applyFeature(F.wings)
				buildCustomWings(active)
			end,
			changed = function(key) if F.customWings.active and key ~= "speed" then buildCustomWings(true) end end })

		local hat, hatParts
		feature({ tab = "Visuals", name = "China Hat", key = "hat", icon = "star", heavy = true,
			settings = { { key = "radius", name = "Радиус", min = .8, max = 2.2, step = .1, default = 1.4 } },
			onChange = function(active)
				if hat then hat:Destroy() end
				hat, hatParts = nil, nil
				if not active then return end
				hat = new("Folder", { Name = "OV_Hat" }, fx)
				hatParts = {}
				for i = 1, 14 do
					local rib = fxPart({ Transparency = 1 })
					local brim = fxPart({ Transparency = 1, Color = ACCENT2 })
					rib.Parent, brim.Parent = hat, hat
					table.insert(hatParts, { rib, brim })
				end
			end })

		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Exclude
		ray.RespectCanCollide = true
		local function groundBelow(root, offset)
			ray.FilterDescendantsInstances = { lp.Character, fx }
			return workspace:Raycast(root.Position + offset, Vector3.new(0, -12, 0), ray)
		end
		local function floorFrame(hit, forward)
			local normal = hit.Normal
			local tangent = forward - normal * forward:Dot(normal)
			if tangent.Magnitude < .01 then tangent = Vector3.yAxis:Cross(normal) end
			local origin = hit.Position + normal * .035
			return CFrame.lookAt(origin, origin + tangent, normal)
		end

		local characterFx = {}
		local function setCharacterFx(key, active)
			local folder = characterFx[key]
			if folder then folder:Destroy() end
			characterFx[key] = active and new("Folder", { Name = "OV_" .. key }, fx) or nil
		end
		feature({ tab = "Visuals", name = "Jump Effects", key = "jumpWave", icon = "orb", heavy = true,
			settings = { { key = "size", name = "Радиус волны", min = 2, max = 10, default = 5 } },
			onChange = function(active) setCharacterFx("jumpWave", active) end })
		feature({ tab = "Visuals", name = "Footstep Effects", key = "footsteps", icon = "speed", heavy = true,
			settings = { { key = "lifetime", name = "Длительность", min = .3, max = 1.5, step = .05, default = .7 } },
			onChange = function(active) setCharacterFx("footsteps", active) end })

		local function jumpWave(root)
			local hit = groundBelow(root, Vector3.zero)
			if not hit then return end
			local plate = fxPart({ CFrame = floorFrame(hit, root.CFrame.LookVector), Size = Vector3.new(1, .02, 1), Transparency = 1 })
			plate.Parent = characterFx.jumpWave
			local surface = new("SurfaceGui", { Face = Enum.NormalId.Top, LightInfluence = 0, CanvasSize = Vector2.new(128, 128) }, plate)
			local image = new("ImageLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				Image = "rbxassetid://1266170131", ImageColor3 = ACCENT2, ImageTransparency = .12,
			}, surface)
			local diameter = F.jumpWave.v.size * 2
			tw(plate, .55, { Size = Vector3.new(diameter, .02, diameter) })
			tw(image, .55, { ImageTransparency = 1 })
			Debris:AddItem(plate, .6)
		end

		local stepTime, stepSide = 0, 1
		local function footsteps(dt, root, humanoid)
			if humanoid.FloorMaterial == Enum.Material.Air or humanoid.MoveDirection.Magnitude < .1 then
				stepTime = 0
				return
			end
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			if speed < 3 then stepTime = 0 return end
			stepTime += dt
			if stepTime < math.clamp(3.6 / speed, .17, .42) then return end
			stepTime = 0
			stepSide *= -1
			local hit = groundBelow(root, root.CFrame.RightVector * (.44 * stepSide))
			if not hit then return end
			local part = fxPart({
				Size = Vector3.new(.36, .045, .66), Transparency = .25,
				CFrame = floorFrame(hit, root.CFrame.LookVector), Color = stepSide == 1 and ACCENT or ACCENT2,
			})
			part.Parent = characterFx.footsteps
			local lifetime = F.footsteps.v.lifetime
			tw(part, lifetime, { Transparency = 1, Size = Vector3.new(.23, .045, .44) })
			Debris:AddItem(part, lifetime + .06)
		end

		local animationNames, animations = { "Нет анимаций" }, {}
		local animationLibrary = ReplicatedStorage:FindFirstChild("OrangeVisualsAnimations")
		if animationLibrary then
			local children = animationLibrary:GetChildren()
			table.sort(children, function(a, b) return a.Name < b.Name end)
			for _, asset in ipairs(children) do
				if asset:IsA("Animation") then table.insert(animations, asset) end
			end
			if #animations > 0 then
				table.clear(animationNames)
				for i, asset in ipairs(animations) do animationNames[i] = asset.Name end
			end
		end
		local activeTrack, lastAnimator, animationChecked
		local function clearAnimation()
			if activeTrack then activeTrack:Stop(.15) activeTrack:Destroy() end
			activeTrack, lastAnimator, animationChecked = nil, nil, false
		end
		local function stepAnimation(humanoid)
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if animator ~= lastAnimator then clearAnimation() lastAnimator = animator end
			if animationChecked or not animator then return end
			animationChecked = true
			local asset = animations[F.customAnimations.v.animation]
			if not asset then return end
			local rig = asset:GetAttribute("RigType")
			if rig and rig ~= humanoid.RigType.Name then
				V2.notify("Анимация не подходит для " .. humanoid.RigType.Name)
				return
			end
			local ok, track = pcall(animator.LoadAnimation, animator, asset)
			if not ok then V2.notify("Не удалось загрузить анимацию") return end
			activeTrack = track
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = F.customAnimations.v.loop
			track:Play(.15)
		end
		feature({ tab = "Visuals", name = "Custom Animations", key = "customAnimations", icon = "user",
			hint = "Анимации из ReplicatedStorage / OrangeVisualsAnimations",
			settings = {
				{ key = "animation", name = "Анимация", options = animationNames, default = 1 },
				{ key = "loop", name = "Повторять", type = "bool", default = true },
			},
			onChange = function(active)
				clearAnimation()
				if active and #animations == 0 then V2.notify("В плейсе нет настроенных анимаций") end
			end,
			changed = function() if F.customAnimations.active then clearAnimation() end end })

		function V2.characterStep(dt, t, char, humanoid, root, jumped)
			if characterFx.jumpWave and jumped then jumpWave(root) end
			if characterFx.footsteps and root and humanoid then footsteps(dt, root, humanoid) end
			if F.customAnimations.active then stepAnimation(humanoid) end
			if customParts then
				local torso = getTorso(char)
				local v = F.customWings.v
				local shape = wingStyles[v.style][8]
				local flap = math.sin(t * v.speed)
				for _, entry in ipairs(customParts) do
					local p, side = entry.part, entry.side
					p.Transparency = torso and (shape == "round" and .27 or .1) or 1
					if torso then
						local pivot = torso.CFrame * CFrame.new(side * .4, .4 - entry.layer * .48, .65 + entry.layer * .2)
						p.CFrame = pivot * CFrame.Angles(0, -side * (.61 + flap * .39), 0)
							* CFrame.Angles(0, 0, side * (entry.angle + flap * .3))
							* CFrame.new(side * entry.offset, 0, entry.progress * .14)
						if shape == "spectrum" then p.Color = pickColor(entry.index, t, true) end
					end
				end
			end
			if hatParts then
				local head = char and char:FindFirstChild("Head")
				local radius = F.hat.v.radius
				for i, parts in ipairs(hatParts) do
					parts[1].Transparency, parts[2].Transparency = head and .18 or 1, head and .16 or 1
					if head then
						local a = i * math.pi * 2 / #hatParts + t * .18
						local b = a + math.pi * 2 / #hatParts
						local base = head.Position + Vector3.new(0, head.Size.Y / 2 + .18, 0)
						local tip = base + Vector3.new(0, .55, 0)
						local from = base + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
						local to = base + Vector3.new(math.cos(b) * radius, 0, math.sin(b) * radius)
						parts[1].Size = Vector3.new(.1, .09, (tip - from).Magnitude)
						parts[1].CFrame = CFrame.lookAt((tip + from) / 2, tip)
						parts[2].Size = Vector3.new(.09, .09, (to - from).Magnitude)
						parts[2].CFrame = CFrame.lookAt((to + from) / 2, to)
					end
				end
			end
		end
	end

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
				local point = i.UserInputType == Enum.UserInputType.Touch and Vector2.new(i.Position.X, i.Position.Y) or UIS:GetMouseLocation()
				dragging = true; off = point - fr.AbsolutePosition
			elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
				showCtx(w)
			end
		end)
		on(UIS.InputChanged, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local m = i.UserInputType == Enum.UserInputType.Touch and Vector2.new(i.Position.X, i.Position.Y) or UIS:GetMouseLocation()
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
	local hotRows = { { "Меню", function() return OPEN_KEY == Enum.KeyCode.LeftControl and "LCtrl" or OPEN_KEY.Name end } }
	for _, f in ipairs(featureList) do
		if f.bind then table.insert(hotRows, { f.name, function() return (f.bind and f.bind.Name or "—") .. (f.active and "  ON" or "  OFF") end }) end
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
	V2.main = main
	local mscale = new("UIScale", { Scale = .9 }, main)
	local function menuScale()
		local view = cam.ViewportSize
		return math.clamp(math.min((view.X - 16) / 560, (view.Y - 24) / 400), .25, 1)
	end

	local header = new("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1 }, main)
	local logo = icon(header, "orb"); logo.Position = UDim2.fromOffset(16, 16)
	local title = label(header, "ORANGE VISUALS", 13, ACCENT, BOLD); title.Position = UDim2.fromOffset(40, 0); title.Size = UDim2.new(0, 130, 1, 0)
	new("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, 0), BackgroundColor3 = BG3, BorderSizePixel = 0 }, header)

	local tabNames = { "Visuals", "HUD", "Utilities" }
	local pages, tabBtns, tabLines = {}, {}, {}
	local function selectTab(n)
		V2.tab = n
		if V2.clearSearch then V2.clearSearch() end
		for _, name in ipairs(tabNames) do
			pages[name].Visible = (name == n)
			tw(tabBtns[name], .2, { TextColor3 = name == n and ACCENT or DIM })
			tw(tabLines[name], .25, { Size = UDim2.new(name == n and 1 or 0, name == n and -16 or 0, 0, 2) })
		end
		if V2.refreshSearch then V2.refreshSearch() end
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
		s.render = render
		render(f.v[s.key])
		local dragging = false
		local function upd(x)
			local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local st = s.step or 1
			local v = math.clamp(math.floor((s.min + a * (s.max - s.min)) / st + .5) * st, s.min, s.max)
			if f.v[s.key] == v then return end
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
		local toggle, set = makeToggle(row, f.v[s.key], function(v)
			f.v[s.key] = v
			if f.changed then f.changed(s.key) end
		end, true)
		toggle.Position = UDim2.new(1, 0, .5, 0)
		s.render = function(v) set(v, true) end
	end

	local function buildChoice(parent, f, s)
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, parent)
		local title = label(row, s.name, 12, DIM)
		title.Size = UDim2.new(.4, 0, 1, 0)
		local value = label(row, "", 12, TXT, BOLD, Enum.TextXAlignment.Center)
		value.Position, value.Size = UDim2.new(.4, 30, 0, 0), UDim2.new(.6, -60, 1, 0)
		value.TextTruncate = Enum.TextTruncate.AtEnd
		s.render = function(i) value.Text = s.options[i] end
		s.render(f.v[s.key])
		for _, direction in ipairs({ -1, 1 }) do
			local i = direction == -1 and .4 or 1
			local button = new("TextButton", {
				Text = direction == -1 and "‹" or "›", Size = UDim2.fromOffset(27, 26),
				Position = UDim2.new(i, direction == -1 and 0 or -27, 0, 3),
				Font = BOLD, TextColor3 = TXT, TextSize = 18, BackgroundColor3 = BG3, AutoButtonColor = false,
			}, row)
			corner(button, 6)
			on(button.Activated, function()
				local selection = (f.v[s.key] + direction - 1) % #s.options + 1
				if selection == f.v[s.key] then return end
				f.v[s.key] = selection
				s.render(selection)
				if f.changed then f.changed(s.key) end
			end)
		end
	end

	local function buildCard(parent, f)
		local card = new("Frame", { Name = "OV_" .. f.key, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG2, LayoutOrder = f.order }, parent)
		corner(card, 8)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
		local head = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1 }, card)
		local ic = icon(head, f.icon); ic.Position = UDim2.fromOffset(12, 11)
		local nl = label(head, f.name, 13, TXT); nl.Position = UDim2.fromOffset(36, 0); nl.Size = UDim2.new(1, -120, 1, 0)
		local body
		local _, set = makeToggle(head, f.on, function(v)
			setFeature(f, v)
			if v and body and f.build then body.Visible = true end
		end)
		f.setToggle = set
		if f.settings or f.hint or f.build then
			body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2 }, card)
			new("UIListLayout", { Padding = UDim.new(0, 2) }, body)
			new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 10) }, body)
			if f.hint then
				local hint = label(body, f.hint, 11, DIM)
				hint.Size, hint.TextWrapped = UDim2.new(1, 0, 0, 26), true
			end
			for _, s in ipairs(f.settings or {}) do
				if s.type == "bool" then
					buildBool(body, f, s)
				elseif s.options then
					buildChoice(body, f, s)
				else
					buildSlider(body, f, s)
				end
			end
			if f.build then f.build(body) end
			local dots = new("TextButton", { Text = "···", Font = BOLD, TextSize = 18, TextColor3 = DIM, BackgroundTransparency = 1, AutoButtonColor = false,
				Size = UDim2.fromOffset(30, 24), AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -56, .5, 0) }, head)
			on(dots.Activated, function() body.Visible = not body.Visible; tw(dots, .2, { TextColor3 = body.Visible and ACCENT or DIM }) end)
		end
		local searchText = f.name .. " " .. (f.hint or "")
		for _, setting in ipairs(f.settings or {}) do searchText ..= " " .. setting.name end
		V2.addSearchItem(card, parent, searchText)
	end

	local function textButton(parent, text, fn)
		local b = new("TextButton", { Text = text, Font = BOLD, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = ACCENT, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36) }, parent)
		corner(b, 8)
		on(b.MouseEnter, function() tw(b, .15, { BackgroundColor3 = ACCENT2 }) end)
		on(b.MouseLeave, function() tw(b, .15, { BackgroundColor3 = ACCENT }) end)
		on(b.Activated, fn)
		return b
	end

	-- ===================== ПОИСК, БИНДЫ И ПРОФИЛИ =====================
	do
		local searchBox = new("TextBox", {
			Name = "OV_Search", PlaceholderText = "Поиск по всем вкладкам", ClearTextOnFocus = false,
			Text = "", Font = FONT, TextSize = 13, TextColor3 = TXT, PlaceholderColor3 = DIM,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = BG2,
			Position = UDim2.fromOffset(12, 55), Size = UDim2.new(1, -24, 0, 30),
		}, main)
		corner(searchBox, 8)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, searchBox)
		local results = new("ScrollingFrame", {
			Name = "OV_SearchResults", Position = UDim2.fromOffset(12, 93), Size = UDim2.new(1, -24, 1, -105),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, BackgroundTransparency = 1, Visible = false,
		}, main)
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, results)
		new("UIPadding", { PaddingRight = UDim.new(0, 8) }, results)
		local noResults = label(results, "Совпадений нет", 13, DIM)
		noResults.Size, noResults.Visible = UDim2.new(1, 0, 0, 36), false

		local function lower(text)
			local chunks = {}
			for _, point in utf8.codes(string.lower(text)) do
				if point >= 0x410 and point <= 0x42F then point += 32 end
				if point == 0x401 then point = 0x451 end
				table.insert(chunks, utf8.char(point))
			end
			return table.concat(chunks)
		end

		function V2.refreshSearch()
			if not V2.alive then return end
			local enabled = F.search.active
			searchBox.Visible = enabled
			local query = enabled and lower(searchBox.Text:match("^%s*(.-)%s*$")) or ""
			local searching = query ~= ""
			local count = 0
			for _, entry in ipairs(V2.searchItems) do
				local matches = searching and string.find(entry.search, query, 1, true) ~= nil
				entry.card.Parent = matches and results or entry.page
				if matches then count += 1 end
			end
			results.Visible = searching
			noResults.Visible = searching and count == 0
			for name, page in pairs(pages) do
				local top = enabled and 93 or 58
				page.Position = UDim2.fromOffset(12, top)
				page.Size = UDim2.new(1, -24, 1, -top - 12)
				page.Visible = not searching and name == V2.tab
			end
		end
		function V2.addSearchItem(card, page, name)
			table.insert(V2.searchItems, { card = card, page = page, search = lower(name) })
		end
		function V2.clearSearch()
			if searchBox.Text ~= "" then searchBox.Text = "" end
		end
		on(searchBox:GetPropertyChangedSignal("Text"), function()
			results.CanvasPosition = Vector2.zero
			V2.refreshSearch()
		end)
		feature({ tab = "Utilities", name = "Search", key = "search", icon = "eye", defaultOn = true,
			onChange = V2.refreshSearch })
	end

	do
		local bindTargets = { { name = "Меню", key = "menu" } }
		for _, f in ipairs(featureList) do table.insert(bindTargets, f) end
		local bindNames, keyCodes = {}, {}
		for i, f in ipairs(bindTargets) do bindNames[i] = f.name end
		for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do keyCodes[key.Name] = key end
		local selected, captureButton = nil, nil

		local function readBind(f)
			if f.key == "menu" then return OPEN_KEY end
			return f.bind
		end
		local function selectedTarget()
			return bindTargets[F.hotkeys.v.target]
		end
		local function updateCapture()
			if not captureButton then return end
			local key = readBind(selectedTarget())
			captureButton.Text = selected and "Нажмите клавишу · Esc отменяет"
				or ("Изменить: " .. (key and key.Name or "без бинда"))
		end
		local function writeBind(f, key)
			if f.key == "menu" then OPEN_KEY = key else f.bind = key end
		end
		local function available(target, key)
			if not key then return target.key ~= "menu" end
			for _, other in ipairs(bindTargets) do
				if other ~= target and readBind(other) == key then return false end
			end
			return true
		end
		function V2.captureInput(input)
			if not selected or input.UserInputType ~= Enum.UserInputType.Keyboard then return false end
			local key = input.KeyCode
			local target = selected
			if key.Value == 0 then return true end
			if key == Enum.KeyCode.Backspace then key = nil end
			if key ~= Enum.KeyCode.Escape then
				if not available(target, key) then
					if captureButton then captureButton.Text = "Клавиша занята · попробуйте другую" end
					V2.notify("Выберите свободную клавишу")
					return true
				end
				writeBind(target, key)
			end
			selected = nil
			updateCapture()
			return true
		end
		function V2.cancelCapture()
			selected = nil
			updateCapture()
		end

		feature({ tab = "Utilities", name = "Custom Hotkeys", key = "hotkeys", icon = "gear",
			hint = "Выберите функцию. Backspace убирает бинд функции",
			settings = { { key = "target", name = "Функция", options = bindNames, default = 1 } },
			changed = V2.cancelCapture,
			onChange = function(active)
				if captureButton then captureButton.Visible = active end
				if not active then V2.cancelCapture() end
			end,
			build = function(body)
				captureButton = textButton(body, "", function()
					selected = selectedTarget()
					updateCapture()
				end)
				captureButton.Visible = F.hotkeys.active
				updateCapture()
			end })

		local function captureProfile()
			local data = { version = 1, menu = OPEN_KEY.Name, features = {}, widgets = {} }
			for _, f in ipairs(featureList) do
				local values = {}
				for _, s in ipairs(f.settings or {}) do
					local value = f.v[s.key]
					values[s.key] = s.options and s.options[value] or value
				end
				local transient = f.key == "reaction" or f.key == "config"
				data.features[f.key] = { enabled = not transient and f.on, bind = f.bind and f.bind.Name or false, values = values }
			end
			for _, w in ipairs(widgets) do
				data.widgets[w.name] = { x = w.fr.Position.X.Offset, y = w.fr.Position.Y.Offset, scale = w.scale.Scale, visible = w.fr.Visible }
			end
			return data
		end

		local function bounded(value, min, max)
			if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return nil end
			return math.clamp(value, min, max)
		end
		local function applyProfile(data)
			if type(data) ~= "table" or data.version ~= 1 or type(data.features) ~= "table" then return false end
			local menu = type(data.menu) == "string" and keyCodes[data.menu]
			if menu and menu.Value ~= 0 then OPEN_KEY = menu end
			local taken = { [OPEN_KEY] = true }
			for _, f in ipairs(featureList) do
				local saved = data.features[f.key]
				local bind = f.bind
				if type(saved) == "table" then
					if saved.bind == false then bind = nil end
					if type(saved.bind) == "string" and keyCodes[saved.bind] then bind = keyCodes[saved.bind] end
					local changed = {}
					if type(saved.values) == "table" then
						for _, s in ipairs(f.settings or {}) do
							local value = saved.values[s.key]
							if s.options then
								value = table.find(s.options, value)
							elseif s.type == "bool" then
								if type(value) ~= "boolean" then value = nil end
							else
								value = bounded(value, s.min, s.max)
							end
							if value ~= nil and value ~= f.v[s.key] then
								f.v[s.key] = value
								if s.render then s.render(value) end
								table.insert(changed, s.key)
							end
						end
					end
					local wasActive = f.active
					if f.key ~= "reaction" and f.key ~= "config" and type(saved.enabled) == "boolean" then
						setFeature(f, saved.enabled)
					end
					if wasActive == f.active and f.changed then
						for _, key in ipairs(changed) do f.changed(key) end
					end
				end
				if bind and bind.Value ~= 0 and not taken[bind] then
					f.bind, taken[bind] = bind, true
				else
					f.bind = nil
				end
			end
			if type(data.widgets) == "table" then
				for _, w in ipairs(widgets) do
					local saved = data.widgets[w.name]
					if type(saved) == "table" then
						local viewport = cam.ViewportSize
						local x = bounded(saved.x, 0, math.max(0, viewport.X - 45))
						local y = bounded(saved.y, 0, math.max(0, viewport.Y - 25))
						if x and y then w.fr.Position = UDim2.fromOffset(x, y) end
						w.scale.Scale = bounded(saved.scale, .6, 2.2) or w.scale.Scale
						if type(saved.visible) == "boolean" then
							w.fr.Visible = saved.visible
							w.setToggle(saved.visible, true)
						end
					end
				end
			end
			V2.cancelCapture()
			return true
		end

		local profiles, sessionProfiles = {}, {}
		local profileInput, profileStatus, profileList
		local profilePanel
		local waiting = false
		local function status(message)
			if profileStatus then profileStatus.Text = message end
		end
		local function refreshList()
			local names = {}
			for name in pairs(profiles) do table.insert(names, name) end
			table.sort(names)
			profileList.Text = #names > 0 and table.concat(names, "  ·  ") or "Сохранённых профилей пока нет"
		end
		local function remote()
			local endpoint = ReplicatedStorage:FindFirstChild("OV_ProfileStore")
			return endpoint and endpoint:IsA("RemoteFunction") and endpoint
		end
		local function syncProfiles(operation, name, data)
			local endpoint = remote()
			if not endpoint then return false end
			local ok, response = pcall(endpoint.InvokeServer, endpoint, operation, name, data)
			if not ok or type(response) ~= "table" or response.ok ~= true or type(response.profiles) ~= "table" then
				return false
			end
			if not V2.alive then return false end
			profiles = response.profiles
			for key, value in pairs(sessionProfiles) do profiles[key] = value end
			return true
		end
		local function profileName()
			local name = profileInput.Text:match("^%s*(.-)%s*$")
			if #name == 0 or #name > 40 or not utf8.len(name) or name:find("[%c]") then return nil end
			return name
		end
		local function saveProfile()
			if waiting then return end
			local name = profileName()
			if not name then status("Введите имя профиля (до 40 байт)") return end
			local total = 0
			for _ in pairs(profiles) do total += 1 end
			if not profiles[name] and total >= 5 then status("Достигнут лимит в 5 профилей") return end
			waiting = true
			local data = captureProfile()
			sessionProfiles[name] = nil
			local persisted = syncProfiles("save", name, data)
			if not V2.alive then return end
			if not persisted then sessionProfiles[name], profiles[name] = data, data end
			refreshList()
			local message = persisted and "Профиль сохранён" or "Профиль сохранён до конца сеанса"
			status(message)
			V2.notify(message)
			waiting = false
		end
		local function loadProfile()
			if waiting then return end
			local name = profileName()
			if not name or not profiles[name] or not applyProfile(profiles[name]) then status("Профиль не найден") return end
			status("Профиль загружен")
			V2.notify("Профиль загружен")
		end
		local function refreshProfiles()
			if waiting then return end
			waiting = true
			local persisted = syncProfiles("list")
			if not V2.alive then return end
			refreshList()
			status(persisted and "Профили доступны между сеансами" or "Хранилище недоступно. Профили действуют до конца сеанса")
			waiting = false
		end
		local function deleteProfile()
			if waiting then return end
			local name = profileName()
			if not name or not profiles[name] then status("Профиль не найден") return end
			if sessionProfiles[name] then
				sessionProfiles[name], profiles[name] = nil, nil
				refreshList()
				status("Локальная копия удалена. Обновите список для проверки хранилища")
				return
			end
			waiting = true
			local persisted = syncProfiles("delete", name)
			if not V2.alive then return end
			refreshList()
			status(persisted and "Профиль удалён" or "Хранилище недоступно. Профиль сохранён")
			waiting = false
		end

		feature({ tab = "Utilities", name = "Config Manager", key = "config", icon = "gear",
			hint = "До пяти именованных профилей",
			onChange = function(active)
				if profilePanel then profilePanel.Visible = active end
				if active then task.spawn(refreshProfiles) end
			end,
			build = function(body)
				profilePanel = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					Visible = false,
				}, body)
				new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, profilePanel)
				profileInput = new("TextBox", {
					Size = UDim2.new(1, 0, 0, 32), Text = "", PlaceholderText = "Имя профиля",
					PlaceholderColor3 = DIM, Font = FONT, TextColor3 = TXT, TextSize = 13,
					ClearTextOnFocus = false, BackgroundColor3 = BG3,
				}, profilePanel)
				corner(profileInput, 7)
				profileList = label(profilePanel, "", 11, DIM)
				profileList.Size, profileList.TextWrapped = UDim2.new(1, 0, 0, 35), true
				textButton(profilePanel, "Сохранить текущие настройки", saveProfile)
				textButton(profilePanel, "Загрузить профиль", loadProfile)
				textButton(profilePanel, "Удалить профиль", deleteProfile)
				textButton(profilePanel, "Обновить список", refreshProfiles)
				profileStatus = label(profilePanel, "", 11, TXT)
				profileStatus.Size, profileStatus.TextWrapped = UDim2.new(1, 0, 0, 32), true
				refreshList()
			end })
		for _, f in ipairs({ F.hotkeys, F.config }) do
			table.insert(bindTargets, f)
			table.insert(bindNames, f.name)
		end
	end

	for i, f in ipairs(featureList) do f.order = i buildCard(pages[f.tab], f) end

	-- HUD: виджеты
	for i, w in ipairs(widgets) do
		local card = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = BG2, LayoutOrder = #featureList + i }, pages.HUD); corner(card, 8)
		local ic = icon(card, w.def.icon); ic.Position = UDim2.fromOffset(12, 11)
		local nl = label(card, "Виджет: " .. w.name, 13, TXT); nl.Position = UDim2.fromOffset(36, 0); nl.Size = UDim2.new(1, -100, 1, 0)
		local _, set = makeToggle(card, true, function(v) w.fr.Visible = v end)
		w.setToggle = set
		V2.addSearchItem(card, pages.HUD, "Виджет " .. w.name)
	end
	local hint = label(pages.HUD, "ЛКМ — перетащить виджет  •  ПКМ — размер / убрать", 11, DIM); hint.Size = UDim2.new(1, 0, 0, 22); hint.LayoutOrder = 100
	local resetWidgets = textButton(pages.HUD, "Сбросить виджеты", function()
		for i, w in ipairs(widgets) do w.fr.Visible = true; w.scale.Scale = 1; w.fr.Position = UDim2.fromOffset(w.def.pos.X, w.def.pos.Y); if w.setToggle then w.setToggle(true, true) end end
	end)
	resetWidgets.LayoutOrder = 101

	-- Utilities: Unload
	local unload
	local unloadButton = textButton(pages.Utilities, "Выгрузить скрипт (Unload)", function() unload() end)
	unloadButton.LayoutOrder = 101

	selectTab("Visuals")

	-- открытие меню
	local function setOpen(v)
		if not V2.alive or V2.menuOpen == v then return end
		V2.menuOpen = v
		if not v then V2.cancelCapture() end
		local scale = menuScale()
		if v then
			main.Visible = true
			mscale.Scale = scale * .88
			tw(main, .3, { GroupTransparency = 0 })
			tw(mscale, .45, { Scale = scale }, Enum.EasingStyle.Back)
			tw(blur, .35, { Size = V2.menuBlur() })
		else
			tw(main, .2, { GroupTransparency = 1 })
			tw(mscale, .2, { Scale = scale * .92 })
			tw(blur, .25, { Size = 0 })
			task.delay(.22, function() if V2.alive and not V2.menuOpen then main.Visible = false end end)
		end
	end

	V2.setOpen = setOpen
	if UIS.TouchEnabled then
		local menuButton = new("TextButton", {
			Name = "OV_MenuButton", Text = "OV", TextSize = 13, TextColor3 = ACCENT, Font = BOLD,
			Position = UDim2.new(1, -54, 0, 52), Size = UDim2.fromOffset(42, 34), BackgroundColor3 = BG,
			ZIndex = 6,
		}, gui)
		corner(menuButton, 8)
		stroke(menuButton, ACCENT, 1, .45)
		on(menuButton.Activated, function() setOpen(not V2.menuOpen) end)
	end

	-- ===================== ВВОД =====================
	on(UIS.InputBegan, function(i, gpe)
		if UIS:GetFocusedTextBox() then return end
		if V2.captureInput(i) or gpe then return end
		if i.KeyCode == OPEN_KEY then setOpen(not V2.menuOpen) return end
		for _, f in ipairs(featureList) do
			if f.bind and i.KeyCode == f.bind then setFeature(f, not f.on) end
		end
	end)

	on(lp.CharacterAdded, function(c)
		task.spawn(function()
			c:WaitForChild("HumanoidRootPart", 5); task.wait(.2)
			if not V2.alive or lp.Character ~= c then return end
			for _, f in ipairs(featureList) do
				if f.active and f.charBound then pcall(f.onChange, true) end
			end
		end)
	end)

	-- ===================== ГЛАВНЫЙ ЦИКЛ =====================
	local acc, espAcc = 0, 0
	local jumpHumanoid, lastViewport
	on(RunService.RenderStepped, function(dt)
		local t = os.clock()
		fps = fps * .92 + (1 / math.max(dt, 1e-4)) * .08
		local char, hum, root = getChar()
		if V2.menuOpen and lastViewport ~= cam.ViewportSize then
			if lastViewport then tw(mscale, .12, { Scale = menuScale() }) end
			lastViewport = cam.ViewportSize
		end
		if jumpHumanoid ~= hum then jumpHumanoid, lastState = hum, nil end
		local jumped = false

		-- плавный FOV
		if F.fov.active then
			cam.FieldOfView += (F.fov.v.fov - cam.FieldOfView) * (1 - math.exp(-dt * F.fov.v.smooth))
		elseif fovReturn then
			cam.FieldOfView += (fovBase - cam.FieldOfView) * (1 - math.exp(-dt * F.fov.v.smooth))
			if math.abs(cam.FieldOfView - fovBase) < .05 then cam.FieldOfView = fovBase; fovReturn = false end
		end

		-- плавный WalkSpeed
		if F.walk.active then
			takeWalk(hum)
			if hum then hum.WalkSpeed += (F.walk.v.speed - hum.WalkSpeed) * (1 - math.exp(-dt * F.walk.v.smooth)) end
		elseif wsReturn then
			if hum and hum == wsHum then
				hum.WalkSpeed += (wsBase - hum.WalkSpeed) * (1 - math.exp(-dt * F.walk.v.smooth))
				if math.abs(hum.WalkSpeed - wsBase) < .05 then restoreWalk() end
			else
				restoreWalk()
			end
		end

		-- ESP
		espAcc += dt
		if F.esp.active and espAcc >= (F.fpsMode.active and .2 or .075) then
			espAcc = 0
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
		if F.wings.active and feathers then
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
		if F.halo.active and haloParts and char then
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
		if F.orbs.active and orbParts and root then
			local v, n = F.orbs.v, #orbParts
			for i, p in ipairs(orbParts) do
				local a = t * v.speed + i * (math.pi * 2 / n)
				p.Position = root.Position + Vector3.new(math.cos(a) * v.radius, math.sin(t * 2 + i) * .8, math.sin(a) * v.radius)
				p.Color = pickColor(i, t, v.rainbow)
			end
		end

		-- питомец
		if F.pet.active and petOuter and root then
			local target = (root.CFrame * CFrame.new(2.8, 2.2 + math.sin(t * 2) * .35, 1)).Position
			local pos = petOuter.Position:Lerp(target, 1 - math.exp(-dt * F.pet.v.follow))
			petOuter.CFrame = CFrame.new(pos) * CFrame.Angles(t, t * .7, 0)
			petCore.CFrame = CFrame.new(pos) * CFrame.Angles(-t * 1.5, t, t * .5)
		end

		-- jump circles
		if hum then
			local st = hum:GetState()
			jumped = root ~= nil and st == Enum.HumanoidStateType.Jumping and lastState ~= st
			if F.jump.active and jumped then
				local s = F.jump.v.size
				local ring = fxPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(.12, 1, 1), Transparency = .15 })
				ring.CFrame = CFrame.new(root.Position - Vector3.new(0, hum.HipHeight + root.Size.Y / 2 - .05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				tw(ring, .7, { Size = Vector3.new(.12, s, s), Transparency = 1 })
				Debris:AddItem(ring, .8)
			end
			lastState = st
		end

		-- прицел
		if F.cross.active then ch.Rotation = (ch.Rotation + F.cross.v.spin * dt) % 360 end

		-- время суток / эффекты
		if F.time.active or V2.skyClock then V2.updateClock() end
		if cc then
			local v = F.grade.v
			cc.Saturation, cc.Contrast, cc.Brightness = v.sat, v.con, v.bri
			cc.TintColor = Color3.new(1, 1, 1):Lerp(ACCENT, v.tint)
		end
		if bloom then bloom.Intensity, bloom.Size, bloom.Threshold = F.bloom.v.int, F.bloom.v.size, F.bloom.v.thr end

		V2.worldStep(dt, t, root)
		V2.characterStep(dt, t, char, hum, root, jumped)
		V2.hudStep(dt, fps)
		V2.musicStep(dt, t)

		-- виджеты обновляются реже, чем камера
		acc += dt
		if acc > (F.fpsMode.active and .33 or .2) then
			acc = 0
			-- ближайший игрок
			nearest = { name = "-", dist = "-", hp = "-" }
			if root and widgets[5].fr.Visible then
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

	-- Камера обновляется после стандартного контроллера Roblox.
	local cameraBinding = "OV_" .. HttpService:GenerateGUID(false)
	local baseline, applied
	local function restoreCameraFrame()
		if applied and cam.CFrame == applied then cam.CFrame = baseline end
		baseline, applied = nil, nil
	end
	RunService:BindToRenderStep(cameraBinding .. "_Reset", Enum.RenderPriority.Camera.Value - 1, restoreCameraFrame)
	RunService:BindToRenderStep(cameraBinding, Enum.RenderPriority.Camera.Value + 1, function(dt)
		local base = cam.CFrame
		local roll = V2.cameraStep(dt, base)
		if roll ~= 0 or F.aspect.active then
			local frame = roll ~= 0 and base * CFrame.Angles(0, 0, roll) or base
			if F.aspect.active then
				frame *= CFrame.new(0, 0, 0, 1, 0, 0, 0, F.aspect.v.stretch, 0, 0, 0, 1)
			end
			baseline = base
			cam.CFrame = frame
			applied = cam.CFrame
		end
	end)

	on(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		local current = workspace.CurrentCamera
		if not current or current == cam then return end
		restoreCameraFrame()
		if F.fov.active or fovReturn then cam.FieldOfView = fovBase end
		cam, fovReturn = current, false
		if F.fov.active then fovBase = cam.FieldOfView end
	end)

	unload = function()
		if not V2.alive then return end
		V2.alive = false
		for _, f in ipairs(featureList) do f.on = false end
		for _, f in ipairs(featureList) do applyFeature(f) end
		RunService:UnbindFromRenderStep(cameraBinding)
		RunService:UnbindFromRenderStep(cameraBinding .. "_Reset")
		restoreCameraFrame()
		if fovReturn then cam.FieldOfView = fovBase end
		restoreWalk()
		V2.disconnectMusic()
		for _, c in ipairs(conns) do c:Disconnect() end
		blur:Destroy()
		fx:Destroy()
		gui:Destroy()
	end
	cleanup.OnInvoke = function() unload() end
	on(gui.Destroying, unload)

	for _, f in ipairs(featureList) do
		if f.defaultOn then setFeature(f, true) end
	end
	task.delay(.4, function() if V2.alive and V2.menuOpen == nil then setOpen(true) end end)

	if expiresAt > 0 then
		task.spawn(function()
			while V2.alive do
				local remaining = expiresAt - workspace:GetServerTimeNow()
				if remaining <= 0 then
					unload()
					local renewed = awaitLicense(pgui, "Срок действия ключа истёк. Вставьте новый ключ.")
					if renewed ~= nil then runVisuals(renewed) end
					return
				end
				task.wait(math.min(remaining, 15))
			end
		end)
	end
end

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local expiresAt = awaitLicense(playerGui)
if expiresAt ~= nil then runVisuals(expiresAt) end

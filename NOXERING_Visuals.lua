--[[
    NOXERING Visuals
    Меню: LeftCtrl / RightCtrl
    Вкладки: Visuals (ESP) · World · Player (FOV, WalkSpeed) · HUD · Misc
]]

local genv = (getgenv and getgenv()) or _G
if genv.NoxVis_Unload then pcall(genv.NoxVis_Unload) end

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local Stats        = game:GetService("Stats")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local function getParent()
    if gethui then
        local ok, r = pcall(gethui)
        if ok and r then return r end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end
local guiParent = getParent()

---------------------------------------------------------------------
-- Utils
---------------------------------------------------------------------
local conns = {}
local function Connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local T = {
    bg     = Color3.fromRGB(16, 16, 22),
    panel  = Color3.fromRGB(22, 22, 31),
    row    = Color3.fromRGB(30, 30, 41),
    rowHov = Color3.fromRGB(38, 38, 52),
    text   = Color3.fromRGB(235, 235, 245),
    dim    = Color3.fromRGB(140, 140, 165),
    accent = Color3.fromRGB(112, 72, 255),
    off    = Color3.fromRGB(55, 55, 72),
}

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(i, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, i) end
local function tw(o, t, p, style, dir)
    local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p)
    x:Play()
    return x
end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

---------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------
local S = {
    -- ESP
    esp = false, espChams = true, espBox = false, espName = false, espInfo = false,
    espTracer = false, espTeam = false, espRainbow = false,
    espColor = Color3.fromRGB(112, 72, 255), espFill = 0.6, espOutline = 0, espMax = 1500,
    -- World
    fullbright = false, nofog = false, noshadow = false,
    timeOn = false, time = 14,
    ambientOn = false, ambient = Color3.fromRGB(120, 90, 255),
    ccOn = false, sat = 0.2, contrast = 0.1, bright = 0, tint = Color3.new(1, 1, 1),
    bloomOn = false, bloom = 1.2,
    raysOn = false, rays = 0.25,
    blurOn = false, blur = 6,
    -- Player
    fovOn = false, fov = 100, fovSpeed = 8,
    zoomKey = false, zoomFov = 25,
    maxZoomOn = false, maxZoom = 400,
    wsOn = false, ws = 32,
    jpOn = false, jp = 70,
    -- HUD
    hud = true,
    cross = false, crossSize = 10, crossGap = 5, crossThick = 2, crossSpin = false,
    crossColor = Color3.fromRGB(255, 255, 255),
}

---------------------------------------------------------------------
-- GUI root
---------------------------------------------------------------------
local gui = new("ScreenGui", {
    Name = "NoxVis", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, guiParent)

local Main = new("CanvasGroup", {
    Size = UDim2.fromOffset(700, 440), Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.bg,
    GroupTransparency = 1, Visible = false, BorderSizePixel = 0,
}, gui)
corner(Main, 12)
new("UIStroke", {Color = Color3.fromRGB(45, 45, 62), Thickness = 1}, Main)
local Scale = new("UIScale", {Scale = 0.92}, Main)
new("TextButton", {Modal = true, Text = "", BackgroundTransparency = 1, Size = UDim2.new()}, Main) -- освобождает мышь

local Top = new("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.panel, BorderSizePixel = 0}, Main)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0.5, 0, 1, 0),
    Text = "NOXERING  ·  Visuals", Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
}, Top)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -16, 1, 0),
    Text = "CTRL — открыть / закрыть", Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right,
}, Top)

local Side = new("Frame", {
    Position = UDim2.fromOffset(10, 54), Size = UDim2.new(0, 140, 1, -64), BackgroundTransparency = 1,
}, Main)
new("UIListLayout", {Padding = UDim.new(0, 4)}, Side)

local Content = new("Frame", {
    Position = UDim2.fromOffset(160, 54), Size = UDim2.new(1, -170, 1, -64), BackgroundTransparency = 1,
}, Main)

-- перетаскивание за верхнюю панель
do
    local dragging, dragStart, startPos
    Connect(Top.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, Main.Position
        end
    end)
    Connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            tw(Main, 0.08, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)}, Enum.EasingStyle.Linear)
        end
    end)
    Connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

---------------------------------------------------------------------
-- UI library
---------------------------------------------------------------------
local tabs, currentTab = {}, nil

local function selectTab(t)
    if currentTab == t then return end
    for _, o in ipairs(tabs) do
        local on = (o == t)
        o.page.Visible = on
        tw(o.btn, 0.25, {BackgroundTransparency = on and 0 or 1})
        tw(o.ind, 0.25, {BackgroundTransparency = on and 0 or 1})
        tw(o.label, 0.25, {TextColor3 = on and T.text or T.dim})
        if on then
            o.page.Position = UDim2.fromOffset(0, 10)
            tw(o.page, 0.35, {Position = UDim2.fromOffset(0, 0)})
        end
    end
    currentTab = t
end

local function AddTab(name)
    local tab = {}
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.row, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
    }, Side)
    corner(btn, 8)
    local ind = new("Frame", {
        Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 4, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, btn)
    corner(ind, 2)
    local label = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0),
        Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)

    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, Content)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, page)

    tab.btn, tab.ind, tab.label, tab.page = btn, ind, label, page
    tabs[#tabs + 1] = tab
    Connect(btn.MouseButton1Click, function() selectTab(tab) end)

    local function row(h)
        local r = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.row, BorderSizePixel = 0}, page)
        corner(r, 8)
        return r
    end
    local function hover(r, hit)
        Connect(hit.MouseEnter, function() tw(r, 0.15, {BackgroundColor3 = T.rowHov}) end)
        Connect(hit.MouseLeave, function() tw(r, 0.15, {BackgroundColor3 = T.row}) end)
    end
    local function title(r, text)
        return new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -80, 0, 36),
            Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, r)
    end

    function tab:Section(text)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = string.upper(text),
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.accent,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, page)
    end

    function tab:Toggle(name, default, cb)
        local r = row(36)
        title(r, name)
        local sw = new("Frame", {
            Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = default and T.accent or T.off, BorderSizePixel = 0,
        }, r)
        corner(sw, 10)
        local kn = new("Frame", {
            Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0,
            Position = default and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
        }, sw)
        corner(kn, 7)
        local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ""}, r)
        hover(r, hit)
        local state = default
        local function set(v)
            state = v
            tw(sw, 0.25, {BackgroundColor3 = v and T.accent or T.off})
            tw(kn, 0.3, {Position = v and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, Enum.EasingStyle.Back)
            task.spawn(cb, v)
        end
        Connect(hit.MouseButton1Click, function() set(not state) end)
        task.spawn(cb, default)
    end

    function tab:Slider(name, min, max, default, step, cb, suffix)
        local r = row(52)
        new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -90, 0, 22),
            Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, r)
        local val = new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(1, -82, 0, 4), Size = UDim2.fromOffset(70, 22),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right,
        }, r)
        local bar = new("Frame", {
            Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 36), BackgroundColor3 = T.off, BorderSizePixel = 0,
        }, r)
        corner(bar, 3)
        local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.accent, BorderSizePixel = 0}, bar)
        corner(fill, 3)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        }, fill)
        corner(knob, 6)
        local hit = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, -28), BackgroundTransparency = 1, Text = "",
        }, r)
        hover(r, hit)

        local function fmt(v)
            if step < 1 then return string.format("%.2f", v) .. (suffix or "") end
            return tostring(math.floor(v + 0.5)) .. (suffix or "")
        end
        local function set(v)
            v = clamp(math.floor(v / step + 0.5) * step, min, max)
            local a = (v - min) / (max - min)
            tw(fill, 0.12, {Size = UDim2.fromScale(a, 1)})
            val.Text = fmt(v)
            task.spawn(cb, v)
        end
        local sliding = false
        local function fromInput(x)
            set(min + clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * (max - min))
        end
        Connect(hit.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                fromInput(i.Position.X)
            end
        end)
        Connect(UIS.InputChanged, function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                fromInput(i.Position.X)
            end
        end)
        Connect(UIS.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
        end)
        set(default)
    end

    function tab:Colors(name, list, defaultIndex, cb)
        local r = row(36)
        title(r, name)
        local holder = new("Frame", {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(#list * 24, 36), Position = UDim2.new(1, -10, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
        }, r)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }, holder)
        local strokes = {}
        for idx, col in ipairs(list) do
            local b = new("TextButton", {Size = UDim2.fromOffset(18, 18), BackgroundColor3 = col, Text = "", AutoButtonColor = false}, holder)
            corner(b, 9)
            local st = new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = idx == defaultIndex and 0 or 1}, b)
            strokes[idx] = st
            Connect(b.MouseButton1Click, function()
                for k, s in ipairs(strokes) do tw(s, 0.2, {Transparency = k == idx and 0 or 1}) end
                cb(col)
            end)
        end
        cb(list[defaultIndex])
    end

    function tab:Button(name, cb)
        local r = row(36)
        local hit = new("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = name,
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text,
        }, r)
        hover(r, hit)
        Connect(hit.MouseButton1Click, function()
            tw(r, 0.1, {BackgroundColor3 = T.accent})
            task.delay(0.15, function() tw(r, 0.3, {BackgroundColor3 = T.row}) end)
            cb()
        end)
    end

    return tab
end

---------------------------------------------------------------------
-- Open / close (CTRL)
---------------------------------------------------------------------
local open, token = false, 0
local function setOpen(v)
    open = v
    token += 1
    local my = token
    if v then
        Main.Visible = true
        tw(Main, 0.35, {GroupTransparency = 0})
        tw(Scale, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
    else
        tw(Main, 0.25, {GroupTransparency = 1})
        tw(Scale, 0.25, {Scale = 0.92})
        task.delay(0.27, function() if token == my then Main.Visible = false end end)
    end
end
Connect(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then
        setOpen(not open)
    end
end)

---------------------------------------------------------------------
-- Notify
---------------------------------------------------------------------
local function notify(text)
    local f = new("Frame", {
        Size = UDim2.fromOffset(280, 36), Position = UDim2.new(0.5, 0, 1, 20), AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = T.bg, BorderSizePixel = 0,
    }, gui)
    corner(f, 10)
    new("UIStroke", {Color = T.accent, Thickness = 1}, f)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.text,
    }, f)
    tw(f, 0.5, {Position = UDim2.new(0.5, 0, 1, -24)}, Enum.EasingStyle.Back)
    task.delay(2.8, function()
        tw(f, 0.4, {Position = UDim2.new(0.5, 0, 1, 20)})
        task.delay(0.45, function() f:Destroy() end)
    end)
end

---------------------------------------------------------------------
-- Lighting originals + effects
---------------------------------------------------------------------
local orig = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
}
local atmos = {}
for _, a in ipairs(Lighting:GetChildren()) do
    if a:IsA("Atmosphere") then atmos[a] = a.Density end
end

local CC    = new("ColorCorrectionEffect", {Name = "NoxCC", Enabled = false}, Lighting)
local Bloom = new("BloomEffect", {Name = "NoxBloom", Enabled = false, Size = 30, Threshold = 0.9}, Lighting)
local Rays  = new("SunRaysEffect", {Name = "NoxRays", Enabled = false}, Lighting)
local Blur  = new("BlurEffect", {Name = "NoxBlur", Enabled = false, Size = 0}, Lighting)

local palette = {
    Color3.fromRGB(112, 72, 255), Color3.fromRGB(255, 70, 90), Color3.fromRGB(70, 200, 255),
    Color3.fromRGB(80, 255, 140), Color3.fromRGB(255, 220, 70), Color3.fromRGB(255, 255, 255),
}
local tints = {
    Color3.new(1, 1, 1), Color3.fromRGB(255, 200, 170), Color3.fromRGB(170, 200, 255),
    Color3.fromRGB(200, 170, 255), Color3.fromRGB(170, 255, 200),
}

---------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------
local espFolder = new("Folder", {Name = "NoxESP"}, gui)
local espObjs = {}

local function mkDraw(t, props)
    if not Drawing then return nil end
    local ok, d = pcall(Drawing.new, t)
    if not ok or not d then return nil end
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function removeESP(p)
    local o = espObjs[p]
    if not o then return end
    for _, v in pairs(o) do
        pcall(function()
            if typeof(v) == "Instance" then v:Destroy() else v:Remove() end
        end)
    end
    espObjs[p] = nil
end

local function newESP(p)
    if espObjs[p] then return espObjs[p] end
    local o = {}
    o.hl = new("Highlight", {Name = p.Name, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false}, espFolder)
    o.bb = new("BillboardGui", {
        Name = p.Name, Size = UDim2.fromOffset(220, 40), StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0),
        AlwaysOnTop = true, Enabled = false, LightInfluence = 0,
    }, espFolder)
    o.nameL = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.55, 0), Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.4,
    }, o.bb)
    o.infoL = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.55), Size = UDim2.new(1, 0, 0.45, 0),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(210, 210, 225), TextStrokeTransparency = 0.5,
    }, o.bb)
    o.box    = mkDraw("Square", {Thickness = 1.5, Filled = false, Visible = false})
    o.health = mkDraw("Line", {Thickness = 2, Visible = false})
    o.tracer = mkDraw("Line", {Thickness = 1, Visible = false})
    espObjs[p] = o
    return o
end

local function updateESP()
    local camPos = Cam.CFrame.Position
    local vp = Cam.ViewportSize
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local o = newESP(p)
            local ch = p.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local show = S.esp and hrp and hum and hum.Health > 0
            if show and S.espTeam and p.Team ~= nil and p.Team == LP.Team then show = false end
            local dist = 0
            if show then
                dist = (hrp.Position - camPos).Magnitude
                if dist > S.espMax then show = false end
            end

            if show then
                local col = S.espRainbow and Color3.fromHSV(tick() % 4 / 4, 0.8, 1) or S.espColor

                o.hl.Enabled = S.espChams
                o.hl.Adornee = ch
                o.hl.FillColor, o.hl.OutlineColor = col, col
                o.hl.FillTransparency, o.hl.OutlineTransparency = S.espFill, S.espOutline

                o.bb.Enabled = S.espName or S.espInfo
                o.bb.Adornee = hrp
                o.nameL.Visible = S.espName
                o.nameL.Text = p.DisplayName
                o.nameL.TextColor3 = col
                o.infoL.Visible = S.espInfo
                o.infoL.Text = string.format("%d HP  ·  %d studs", hum.Health, dist)

                local top = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.2, 0))
                local vis = top.Z > 0
                local h = math.abs(bot.Y - top.Y)
                local w = h * 0.55

                if o.box then
                    o.box.Visible = S.espBox and vis
                    o.box.Color = col
                    o.box.Size = Vector2.new(w, h)
                    o.box.Position = Vector2.new(top.X - w / 2, top.Y)
                end
                if o.health then
                    local hp = clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    o.health.Visible = S.espBox and vis
                    o.health.Color = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(70, 255, 110), hp)
                    o.health.From = Vector2.new(top.X - w / 2 - 5, bot.Y)
                    o.health.To = Vector2.new(top.X - w / 2 - 5, bot.Y - h * hp)
                end
                if o.tracer then
                    o.tracer.Visible = S.espTracer and vis
                    o.tracer.Color = col
                    o.tracer.From = Vector2.new(vp.X / 2, vp.Y)
                    o.tracer.To = Vector2.new(bot.X, bot.Y)
                end
            else
                o.hl.Enabled = false
                o.bb.Enabled = false
                if o.box then o.box.Visible = false end
                if o.health then o.health.Visible = false end
                if o.tracer then o.tracer.Visible = false end
            end
        end
    end
end
Connect(Players.PlayerRemoving, removeESP)

---------------------------------------------------------------------
-- HUD: info pill + crosshair
---------------------------------------------------------------------
local Pill = new("Frame", {
    Size = UDim2.fromOffset(280, 30), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = S.hud,
}, gui)
corner(Pill, 15)
new("UIStroke", {Color = Color3.fromRGB(45, 45, 62)}, Pill)
local PillText = new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamMedium,
    TextSize = 13, TextColor3 = T.text, Text = "",
}, Pill)

local CH = new("Frame", {
    Size = UDim2.fromOffset(200, 200), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Visible = false,
}, gui)
local chLines = {}
for i = 1, 4 do
    chLines[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, CH)
end
local function updateCrosshair(dt)
    CH.Visible = S.cross
    if not S.cross then return end
    local len, gap, th = S.crossSize, S.crossGap, S.crossThick
    local off = gap + len / 2
    chLines[1].Size, chLines[1].Position = UDim2.fromOffset(th, len), UDim2.new(0.5, 0, 0.5, -off)
    chLines[2].Size, chLines[2].Position = UDim2.fromOffset(th, len), UDim2.new(0.5, 0, 0.5, off)
    chLines[3].Size, chLines[3].Position = UDim2.fromOffset(len, th), UDim2.new(0.5, -off, 0.5, 0)
    chLines[4].Size, chLines[4].Position = UDim2.fromOffset(len, th), UDim2.new(0.5, off, 0.5, 0)
    for _, l in ipairs(chLines) do l.BackgroundColor3 = S.crossColor end
    if S.crossSpin then CH.Rotation = (CH.Rotation + dt * 120) % 360
    else CH.Rotation = CH.Rotation * (1 - math.min(dt * 10, 1)) end
end

---------------------------------------------------------------------
-- Player features (FOV / WalkSpeed / JumpPower)
---------------------------------------------------------------------
local baseFOV = Cam.FieldOfView
local fovReleasing = false
local origWS, origJP = 16, 50
local zoomHeld = false

Connect(UIS.InputBegan, function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.C then zoomHeld = true end
end)
Connect(UIS.InputEnded, function(i)
    if i.KeyCode == Enum.KeyCode.C then zoomHeld = false end
end)

local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- FOV идёт после камеры игры, плавная интерполяция
RunService:BindToRenderStep("NoxVis_Cam", Enum.RenderPriority.Camera.Value + 1, function(dt)
    Cam = workspace.CurrentCamera
    if not Cam then return end
    local target
    if S.zoomKey and zoomHeld then
        target = S.zoomFov
        fovReleasing = true
    elseif S.fovOn then
        target = S.fov
        fovReleasing = true
    elseif fovReleasing then
        target = baseFOV
        if math.abs(Cam.FieldOfView - baseFOV) < 0.05 then fovReleasing = false end
    end
    if target then
        local speed = (S.zoomKey and zoomHeld) and 14 or S.fovSpeed
        Cam.FieldOfView = Cam.FieldOfView + (target - Cam.FieldOfView) * (1 - math.exp(-dt * speed))
    end
end)

---------------------------------------------------------------------
-- Main loops
---------------------------------------------------------------------
local fps, hudTimer = 60, 0
Connect(RunService.RenderStepped, function(dt)
    Cam = workspace.CurrentCamera or Cam
    fps = fps + ((1 / math.max(dt, 1e-4)) - fps) * 0.08

    updateESP()
    updateCrosshair(dt)

    -- HUD
    Pill.Visible = S.hud
    hudTimer += dt
    if hudTimer > 0.25 and S.hud then
        hudTimer = 0
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        PillText.Text = string.format("%s   ·   %d ms   ·   %d FPS", LP.Name, ping, math.floor(fps))
    end

    -- Lighting
    if S.fullbright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    end
    if S.ambientOn then
        Lighting.Ambient = S.ambient
        Lighting.OutdoorAmbient = S.ambient
    end
    if S.nofog then
        Lighting.FogEnd, Lighting.FogStart = 1e6, 1e6
        for a in pairs(atmos) do if a.Parent then a.Density = 0 end end
    end
    if S.noshadow then Lighting.GlobalShadows = false end
    if S.timeOn then
        Lighting.ClockTime = Lighting.ClockTime + (S.time - Lighting.ClockTime) * (1 - math.exp(-dt * 4))
    end
    -- плавные эффекты
    local k = 1 - math.exp(-dt * 6)
    CC.Saturation = CC.Saturation + (S.sat - CC.Saturation) * k
    CC.Contrast   = CC.Contrast + (S.contrast - CC.Contrast) * k
    CC.Brightness = CC.Brightness + (S.bright - CC.Brightness) * k
    CC.TintColor  = CC.TintColor:Lerp(S.tint, k)
    Bloom.Intensity = Bloom.Intensity + (S.bloom - Bloom.Intensity) * k
    Rays.Intensity  = Rays.Intensity + (S.rays - Rays.Intensity) * k
    Blur.Size       = Blur.Size + ((S.blurOn and S.blur or 0) - Blur.Size) * k
    CC.Enabled, Bloom.Enabled, Rays.Enabled = S.ccOn, S.bloomOn, S.raysOn
    Blur.Enabled = S.blurOn or Blur.Size > 0.2
end)

Connect(RunService.Heartbeat, function(dt)
    local hum = getHum()
    if hum then
        if S.wsOn then
            hum.WalkSpeed = hum.WalkSpeed + (S.ws - hum.WalkSpeed) * (1 - math.exp(-dt * 10))
        end
        if S.jpOn then
            hum.UseJumpPower = true
            hum.JumpPower = S.jp
        end
    end
    if S.maxZoomOn then LP.CameraMaxZoomDistance = S.maxZoom end
end)

---------------------------------------------------------------------
-- Menu
---------------------------------------------------------------------
local tVis    = AddTab("Visuals")
local tWorld  = AddTab("World")
local tPlayer = AddTab("Player")
local tHud    = AddTab("HUD")
local tMisc   = AddTab("Misc")

-- Visuals
tVis:Section("ESP")
tVis:Toggle("ESP (главный выключатель)", S.esp, function(v) S.esp = v end)
tVis:Toggle("Chams (подсветка игроков)", S.espChams, function(v) S.espChams = v end)
tVis:Toggle("Box + полоса HP", S.espBox, function(v) S.espBox = v end)
tVis:Toggle("Имена", S.espName, function(v) S.espName = v end)
tVis:Toggle("HP и дистанция", S.espInfo, function(v) S.espInfo = v end)
tVis:Toggle("Tracers", S.espTracer, function(v) S.espTracer = v end)
tVis:Toggle("Не показывать тиммейтов", S.espTeam, function(v) S.espTeam = v end)
tVis:Toggle("Rainbow цвет", S.espRainbow, function(v) S.espRainbow = v end)
tVis:Colors("Цвет ESP", palette, 1, function(c) S.espColor = c end)
tVis:Slider("Прозрачность заливки", 0, 1, S.espFill, 0.05, function(v) S.espFill = v end)
tVis:Slider("Прозрачность контура", 0, 1, S.espOutline, 0.05, function(v) S.espOutline = v end)
tVis:Slider("Макс. дистанция", 100, 5000, S.espMax, 50, function(v) S.espMax = v end, " st")

-- World
tWorld:Section("Освещение")
tWorld:Toggle("Fullbright", S.fullbright, function(v)
    S.fullbright = v
    if not v then
        Lighting.Brightness = orig.Brightness
        Lighting.Ambient, Lighting.OutdoorAmbient = orig.Ambient, orig.OutdoorAmbient
    end
end)
tWorld:Toggle("No Fog", S.nofog, function(v)
    S.nofog = v
    if not v then
        Lighting.FogEnd, Lighting.FogStart = orig.FogEnd, orig.FogStart
        for a, d in pairs(atmos) do if a.Parent then a.Density = d end end
    end
end)
tWorld:Toggle("No Shadows", S.noshadow, function(v)
    S.noshadow = v
    if not v then Lighting.GlobalShadows = orig.GlobalShadows end
end)
tWorld:Toggle("Своё время суток", S.timeOn, function(v)
    S.timeOn = v
    if not v then Lighting.ClockTime = orig.ClockTime end
end)
tWorld:Slider("Время суток", 0, 24, S.time, 0.25, function(v) S.time = v end, " ч")
tWorld:Toggle("Свой цвет Ambient", S.ambientOn, function(v)
    S.ambientOn = v
    if not v then Lighting.Ambient, Lighting.OutdoorAmbient = orig.Ambient, orig.OutdoorAmbient end
end)
tWorld:Colors("Цвет Ambient", palette, 1, function(c) S.ambient = c end)

tWorld:Section("Постобработка")
tWorld:Toggle("Color Correction", S.ccOn, function(v) S.ccOn = v end)
tWorld:Slider("Насыщенность", -1, 2, S.sat, 0.05, function(v) S.sat = v end)
tWorld:Slider("Контраст", -1, 1, S.contrast, 0.05, function(v) S.contrast = v end)
tWorld:Slider("Яркость", -0.5, 0.5, S.bright, 0.05, function(v) S.bright = v end)
tWorld:Colors("Оттенок", tints, 1, function(c) S.tint = c end)
tWorld:Toggle("Bloom", S.bloomOn, function(v) S.bloomOn = v end)
tWorld:Slider("Сила Bloom", 0, 5, S.bloom, 0.1, function(v) S.bloom = v end)
tWorld:Toggle("Sun Rays", S.raysOn, function(v) S.raysOn = v end)
tWorld:Slider("Сила лучей", 0, 1, S.rays, 0.05, function(v) S.rays = v end)
tWorld:Toggle("Blur", S.blurOn, function(v) S.blurOn = v end)
tWorld:Slider("Сила Blur", 0, 40, S.blur, 1, function(v) S.blur = v end)

-- Player
tPlayer:Section("Камера")
tPlayer:Toggle("FOV Changer", S.fovOn, function(v) S.fovOn = v end)
tPlayer:Slider("FOV", 30, 120, S.fov, 1, function(v) S.fov = v end)
tPlayer:Slider("Плавность FOV", 1, 20, S.fovSpeed, 1, function(v) S.fovSpeed = v end)
tPlayer:Toggle("Zoom (зажми C)", S.zoomKey, function(v) S.zoomKey = v end)
tPlayer:Slider("FOV при зуме", 5, 60, S.zoomFov, 1, function(v) S.zoomFov = v end)
tPlayer:Toggle("Макс. отдаление камеры", S.maxZoomOn, function(v)
    S.maxZoomOn = v
    if not v then LP.CameraMaxZoomDistance = 128 end
end)
tPlayer:Slider("Дистанция камеры", 20, 1000, S.maxZoom, 10, function(v) S.maxZoom = v end)

tPlayer:Section("Движение")
tPlayer:Toggle("WalkSpeed", S.wsOn, function(v)
    if v and not S.wsOn then
        local h = getHum()
        if h and h.WalkSpeed < 100 then origWS = h.WalkSpeed end
    end
    S.wsOn = v
    if not v then
        local h = getHum()
        if h then h.WalkSpeed = origWS end
    end
end)
tPlayer:Slider("Скорость", 0, 200, S.ws, 1, function(v) S.ws = v end)
tPlayer:Toggle("JumpPower", S.jpOn, function(v)
    if v and not S.jpOn then
        local h = getHum()
        if h then origJP = h.JumpPower end
    end
    S.jpOn = v
    if not v then
        local h = getHum()
        if h then h.JumpPower = origJP end
    end
end)
tPlayer:Slider("Сила прыжка", 0, 300, S.jp, 1, function(v) S.jp = v end)

-- HUD
tHud:Section("Информация")
tHud:Toggle("Плашка (ник · пинг · FPS)", S.hud, function(v) S.hud = v end)
tHud:Section("Прицел")
tHud:Toggle("Crosshair", S.cross, function(v) S.cross = v end)
tHud:Toggle("Вращение", S.crossSpin, function(v) S.crossSpin = v end)
tHud:Slider("Длина", 2, 40, S.crossSize, 1, function(v) S.crossSize = v end)
tHud:Slider("Разрыв", 0, 30, S.crossGap, 1, function(v) S.crossGap = v end)
tHud:Slider("Толщина", 1, 8, S.crossThick, 1, function(v) S.crossThick = v end)
tHud:Colors("Цвет прицела", palette, 6, function(c) S.crossColor = c end)

-- Misc
local function unload()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("NoxVis_Cam") end)
    for p in pairs(espObjs) do removeESP(p) end
    pcall(function()
        Lighting.Brightness, Lighting.ClockTime = orig.Brightness, orig.ClockTime
        Lighting.FogEnd, Lighting.FogStart = orig.FogEnd, orig.FogStart
        Lighting.Ambient, Lighting.OutdoorAmbient = orig.Ambient, orig.OutdoorAmbient
        Lighting.GlobalShadows = orig.GlobalShadows
        for a, d in pairs(atmos) do if a.Parent then a.Density = d end end
        if Cam then Cam.FieldOfView = baseFOV end
        local h = getHum()
        if h and S.wsOn then h.WalkSpeed = origWS end
        if h and S.jpOn then h.JumpPower = origJP end
        LP.CameraMaxZoomDistance = 128
    end)
    for _, e in ipairs({CC, Bloom, Rays, Blur}) do pcall(function() e:Destroy() end) end
    pcall(function() gui:Destroy() end)
    genv.NoxVis_Unload = nil
end
genv.NoxVis_Unload = unload

tMisc:Section("Скрипт")
tMisc:Button("Выгрузить скрипт (вернуть всё как было)", unload)

selectTab(tVis)
task.delay(0.3, function()
    setOpen(true)
    notify("NOXERING Visuals загружен · CTRL — меню")
end)

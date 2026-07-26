--[[
================================================================================
  NEXUS ADMIN SUITE  Â·  v1.0.2  (correÃ§Ã£o de inicializaÃ§Ã£o)
  Painel de administraÃ§Ã£o / debug para Roblox  Â·  LocalScript, 100% client-side
================================================================================

  O QUE MUDOU NESTA VERSÃƒO
    Â· corrigido erro fatal no dropdown multi-seleÃ§Ã£o (cor recebendo booleano)
    Â· corrigido string.format com decimais (%d / %X quebram no Luau)
    Â· toda a construÃ§Ã£o da interface agora roda dentro de um guarda de erro:
      se algo falhar, vocÃª VÃŠ o motivo na tela e no console (F9), em vez de
      simplesmente nÃ£o acontecer nada
    Â· aviso claro se o script for colocado como Script de servidor
    Â· notificaÃ§Ã£o "carregando / pronto" pra confirmar que executou

  COMO INSTALAR
    Studio:   StarterPlayer > StarterPlayerScripts > LocalScript > cole tudo
    Executor: execute o arquivo direto

  ATALHOS
    RightShift ....... abrir / fechar painel
    RightControl ..... ESP master
    F / G / T / K .... voar / noclip / teleporte no clique / crosshair
    End .............. PANIC: encerra tudo e restaura o jogo
================================================================================
]]

--==============================================================================
-- 00 Â· SANIDADE + DIAGNÃ“STICO
--==============================================================================

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function coreNotify(title, text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 4 })
	end)
end

if not RunService:IsClient() then
	warn("[NEXUS] Este script precisa rodar no cliente. Use um LocalScript em StarterPlayer > StarterPlayerScripts.")
	return
end

if not Players.LocalPlayer then
	local t = 0
	repeat task.wait(0.1) t += 0.1 until Players.LocalPlayer or t > 10
end
if not Players.LocalPlayer then
	warn("[NEXUS] LocalPlayer nÃ£o encontrado. O script nÃ£o Ã© um LocalScript ou o cliente nÃ£o carregou.")
	return
end

print("[NEXUS] iniciando v1.0.2 ...")
coreNotify("Nexus Admin", "Carregando painel...", 3)

--==============================================================================
-- 01 Â· SERVIÃ‡OS E HELPERS
--==============================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
local Mouse       = LocalPlayer:GetMouse()

local VERSION = "1.0.2"

local Conns = {}
local function bind(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Conns, c)
	return c
end

local function new(class, props, kids)
	local o = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

local function corner(r, p)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p })
end

local function stroke(c, t, p, transp)
	return new("UIStroke", {
		Color = c, Thickness = t or 1, Transparency = transp or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p,
	})
end

local function padding(t, r, b, l, p)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), Parent = p,
	})
end

local function vlist(gap, p)
	return new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = p,
	})
end

local function hlist(gap, p)
	return new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = p,
	})
end

local EASE = Enum.EasingStyle.Quart
local function tween(o, time, props, style)
	local tw = TweenService:Create(o, TweenInfo.new(time or 0.18, style or EASE, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function round(n, d)
	local m = 10 ^ (d or 0)
	return math.floor(n * m + 0.5) / m
end

-- int seguro: %d e %X no Luau explodem com decimais
local function i(n) return math.floor(tonumber(n) or 0) end

local function chr()  return LocalPlayer.Character end
local function hum()  local c = chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = chr(); return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end

local function clip(text)
	if typeof(setclipboard) == "function" then
		if pcall(setclipboard, text) then return true end
	end
	if typeof(toclipboard) == "function" then
		if pcall(toclipboard, text) then return true end
	end
	return false
end

local FONTS = {
	Gotham = Enum.Font.Gotham, GothamMedium = Enum.Font.GothamMedium,
	GothamBold = Enum.Font.GothamBold, GothamBlack = Enum.Font.GothamBlack,
	Code = Enum.Font.Code, SourceSans = Enum.Font.SourceSans,
	SourceSansBold = Enum.Font.SourceSansBold, Fantasy = Enum.Font.Fantasy, Arcade = Enum.Font.Arcade,
}

--==============================================================================
-- 02 Â· TEMA
--==============================================================================

local T = {
	Bg      = Color3.fromRGB(22, 20, 24),
	Bg2     = Color3.fromRGB(28, 25, 30),
	Card    = Color3.fromRGB(34, 31, 37),
	Card2   = Color3.fromRGB(43, 39, 47),
	Stroke  = Color3.fromRGB(58, 53, 63),
	Stroke2 = Color3.fromRGB(48, 44, 53),
	Text    = Color3.fromRGB(238, 234, 240),
	Sub     = Color3.fromRGB(152, 145, 160),
	Dim     = Color3.fromRGB(108, 102, 116),
	Accent  = Color3.fromRGB(255, 149, 92),
	Good    = Color3.fromRGB(118, 224, 178),
	Bad     = Color3.fromRGB(255, 98, 112),
	Warn    = Color3.fromRGB(255, 205, 108),
	Font    = Enum.Font.Gotham,
	FontB   = Enum.Font.GothamBold,
	FontM   = Enum.Font.GothamMedium,
}

--==============================================================================
-- 03 Â· ESTADO
--==============================================================================

local S = {
	ESP_Master = false,
	ESP_Players = true, ESP_NPCs = false, ESP_Objects = false,
	ESP_MaxDistance = 1500, ESP_Refresh = 1,
	ESP_ShowSelf = false, ESP_AliveOnly = true,
	ESP_TeamCheck = false, ESP_TeamColor = false,
	ESP_TextSize = 13, ESP_Thickness = 1, ESP_Font = "GothamBold",
	ESP_Rainbow = false, ESP_VisibilityCheck = false,

	ESP_Box = true, ESP_BoxType = "Cantos", ESP_BoxFill = false, ESP_FillOpacity = 0.85,
	ESP_Name = true, ESP_Distance = true,
	ESP_HealthBar = true, ESP_HealthText = false,
	ESP_Skeleton = false, ESP_HeadDot = false, ESP_LookVector = false,
	ESP_Tracer = false, ESP_TracerFrom = "Base da tela",
	ESP_Chams = false, ESP_ChamsThrough = true, ESP_ChamsOpacity = 0.55,
	ESP_Outline = false, ESP_Arrows = false,

	C_Visible = Color3.fromRGB(118, 224, 178),
	C_Hidden  = Color3.fromRGB(255, 98, 112),
	C_NPC     = Color3.fromRGB(255, 205, 108),
	C_Object  = Color3.fromRGB(170, 160, 255),
	C_Text    = Color3.fromRGB(238, 234, 240),

	ST_Health = true, ST_MaxHealth = false, ST_WalkSpeed = false, ST_JumpPower = false,
	ST_State = false, ST_Tool = false, ST_Team = false, ST_Leaderstats = false,
	ST_Attributes = false, ST_Velocity = false, ST_Position = false,
	ST_UserId = false, ST_Display = false, ST_AccountAge = false, ST_Sitting = false,

	OBJ_Classes = { "Tool" }, OBJ_Keywords = "", OBJ_Dot = true, OBJ_Limit = 250,

	Fly = false, FlySpeed = 60,
	SpeedOn = false, SpeedValue = 32,
	JumpOn = false, JumpValue = 80,
	InfJump = false, Noclip = false, ClickTP = false,
	AntiVoid = false, VoidY = -120,
	Spin = false, SpinSpeed = 6, HipHeight = 0, Freeze = false,

	Fullbright = false, Brightness = 3, NoFog = false, NoShadows = false,
	ClockTimeOn = false, ClockTime = 14,
	AmbientColor = Color3.fromRGB(190, 190, 200),
	FOVOn = false, FOV = 70, ZoomOn = false, ZoomMax = 400,
	Crosshair = false, CrosshairSize = 10, CrosshairColor = Color3.fromRGB(255, 149, 92),
	Saturation = 0, Contrast = 0, TintOn = false, Tint = Color3.fromRGB(255, 255, 255),
	LowGFX = false, NoParticles = false, HideChar = false, HideNames = false,
	Freecam = false, FreecamSpeed = 60,

	GravityOn = false, Gravity = 196.2,
	AntiAFK = false, AutoClick = false, CPS = 8,

	UIScale = 1, UITransparency = 0, HUD = false,
	KB_Panel = "RightShift", KB_ESP = "RightControl", KB_Fly = "F",
	KB_Noclip = "G", KB_ClickTP = "T", KB_Crosshair = "K", KB_Panic = "End",

	Waypoints = {},
}

local DEFAULTS = {}
for k, v in pairs(S) do DEFAULTS[k] = v end

--==============================================================================
-- 04 Â· GUIs
--==============================================================================

local parentGui = LocalPlayer:WaitForChild("PlayerGui")
if typeof(gethui) == "function" then
	local ok, hui = pcall(gethui)
	if ok and hui then parentGui = hui end
end

local PanelGui = new("ScreenGui", {
	Name = "NX_Panel", IgnoreGuiInset = true, ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = parentGui,
})
local EspGui = new("ScreenGui", {
	Name = "NX_ESP", IgnoreGuiInset = true, ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 500, Parent = parentGui,
})
local EspHolder = new("Frame", { Name = "Holder", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = EspGui })
local OverlayGui = new("ScreenGui", {
	Name = "NX_Overlay", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 700, Parent = parentGui,
})

local Lib = { Flags = {}, Refreshers = {} }

local function label(parent, text, props)
	local p = {
		Text = tostring(text or ""), Font = T.Font, TextSize = 13, TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = parent,
	}
	for k, v in pairs(props or {}) do p[k] = v end
	return new("TextLabel", p)
end

local function dragHook(target, fn)
	target.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		fn(inp.Position)
		local mc, ec
		mc = UserInputService.InputChanged:Connect(function(i2)
			if i2.UserInputType == Enum.UserInputType.MouseMovement or i2.UserInputType == Enum.UserInputType.Touch then
				fn(i2.Position)
			end
		end)
		ec = UserInputService.InputEnded:Connect(function(i3)
			if i3.UserInputType == inp.UserInputType then
				if mc then mc:Disconnect() end
				if ec then ec:Disconnect() end
			end
		end)
	end)
end

------------------------------------------------------------------- janela ------
local Win = new("Frame", {
	Name = "Window", Size = UDim2.fromOffset(790, 500), Position = UDim2.new(0.5, -395, 0.5, -250),
	BackgroundColor3 = T.Bg, BorderSizePixel = 0, Visible = false, Parent = PanelGui,
})
corner(14, Win); stroke(T.Stroke, 1, Win)
local WinScale = new("UIScale", { Scale = 1, Parent = Win })

local Side = new("Frame", { Size = UDim2.new(0, 186, 1, 0), BackgroundColor3 = T.Bg2, BorderSizePixel = 0, Parent = Win })
corner(14, Side)
new("Frame", { Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
	BackgroundColor3 = T.Bg2, BorderSizePixel = 0, Parent = Side })
new("Frame", { Size = UDim2.new(0, 1, 1, -28), Position = UDim2.new(1, -1, 0, 14),
	BackgroundColor3 = T.Stroke2, BorderSizePixel = 0, Parent = Side })

local brand = new("Frame", { Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1, Parent = Side })
new("Frame", { Size = UDim2.fromOffset(6, 26), Position = UDim2.fromOffset(20, 26),
	BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = brand },
	{ new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
label(brand, "NEXUS", { Position = UDim2.fromOffset(36, 24), Size = UDim2.fromOffset(120, 18),
	Font = Enum.Font.GothamBlack, TextSize = 17 })
label(brand, "ADMIN SUITE  v" .. VERSION, { Position = UDim2.fromOffset(36, 42), Size = UDim2.fromOffset(140, 12),
	Font = T.FontM, TextSize = 9, TextColor3 = T.Dim })

local TabBar = new("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -140), Position = UDim2.fromOffset(12, 78),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Side,
})
vlist(3, TabBar)

local SideFoot = new("Frame", {
	Size = UDim2.new(1, -24, 0, 50), Position = UDim2.new(0, 12, 1, -56),
	BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = Side,
})
corner(9, SideFoot)
local footFps  = label(SideFoot, "-- fps", { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.Code, TextSize = 12, TextColor3 = T.Good })
local footPing = label(SideFoot, "-- ms", { Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -20, 0, 12),
	Font = Enum.Font.Code, TextSize = 10, TextColor3 = T.Dim })

local Head = new("Frame", { Size = UDim2.new(1, -186, 0, 76), Position = UDim2.fromOffset(186, 0),
	BackgroundTransparency = 1, Parent = Win })
local HeadTitle = label(Head, "ESP", { Position = UDim2.fromOffset(22, 24), Size = UDim2.new(1, -140, 0, 22),
	Font = Enum.Font.GothamBold, TextSize = 19 })
local HeadDesc = label(Head, "", { Position = UDim2.fromOffset(22, 46), Size = UDim2.new(1, -140, 0, 14),
	Font = T.Font, TextSize = 11, TextColor3 = T.Sub })

local function headBtn(txt, x, color)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, x, 0, 26),
		BackgroundColor3 = T.Card, Text = txt, Font = T.FontB, TextSize = 14,
		TextColor3 = color or T.Sub, AutoButtonColor = false, BorderSizePixel = 0, Parent = Head,
	})
	corner(8, b)
	b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = T.Card2 }) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = T.Card }) end)
	return b
end
local BtnClose = headBtn("Ã—", -40, T.Bad)
local BtnMin   = headBtn("â€“", -72)

new("Frame", { Size = UDim2.new(1, -230, 0, 1), Position = UDim2.fromOffset(208, 76),
	BackgroundColor3 = T.Stroke2, BorderSizePixel = 0, Parent = Win })

local Pages = new("Frame", { Size = UDim2.new(1, -210, 1, -92), Position = UDim2.fromOffset(198, 86),
	BackgroundTransparency = 1, Parent = Win })

do -- arrastar
	local dragging, startPos, startAbs = false, nil, nil
	Head.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startAbs = true, Win.Position, inp.Position
		end
	end)
	bind(UserInputService.InputChanged, function(inp)
		if not dragging then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			local d = inp.Position - startAbs
			Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	bind(UserInputService.InputEnded, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

do -- redimensionar
	local grip = new("TextButton", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -18, 1, -18),
		Text = "", BackgroundTransparency = 1, Parent = Win })
	for n = 1, 3 do
		new("Frame", { Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(12 - (n - 1) * 5, 12),
			BackgroundColor3 = T.Dim, BorderSizePixel = 0, Parent = grip })
	end
	local base, from
	dragHook(grip, function(p)
		if not from then base, from = Win.AbsoluteSize, p end
		local d = p - from
		Win.Size = UDim2.fromOffset(math.clamp(base.X + d.X, 620, 1600), math.clamp(base.Y + d.Y, 380, 1000))
	end)
	grip.InputEnded:Connect(function() from = nil end)
end

--==============================================================================
-- 05 Â· NOTIFICAÃ‡Ã•ES
--==============================================================================

local NotifHolder = new("Frame", { Size = UDim2.fromOffset(300, 400), Position = UDim2.new(1, -316, 1, -416),
	BackgroundTransparency = 1, Parent = OverlayGui })
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifHolder,
})

local notifId = 0
local function notify(title, body, dur, kind)
	notifId += 1
	local accent = kind == "bad" and T.Bad or kind == "warn" and T.Warn or kind == "good" and T.Good or T.Accent
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, body and 54 or 38), BackgroundColor3 = T.Card, BackgroundTransparency = 1,
		BorderSizePixel = 0, LayoutOrder = notifId, Parent = NotifHolder,
	})
	corner(10, card)
	local st = stroke(T.Stroke, 1, card, 1)
	new("Frame", { Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(14, 17),
		BackgroundColor3 = accent, BorderSizePixel = 0, Parent = card },
		{ new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local t1 = label(card, title, { Position = UDim2.fromOffset(28, body and 10 or 11), Size = UDim2.new(1, -40, 0, 16),
		Font = T.FontB, TextSize = 12.5, TextTransparency = 1 })
	local t2
	if body then
		t2 = label(card, body, { Position = UDim2.fromOffset(28, 28), Size = UDim2.new(1, -40, 0, 16),
			TextSize = 11, TextColor3 = T.Sub, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd })
	end
	tween(card, 0.28, { BackgroundTransparency = 0 })
	tween(st, 0.28, { Transparency = 0 })
	tween(t1, 0.28, { TextTransparency = 0 })
	if t2 then tween(t2, 0.28, { TextTransparency = 0 }) end
	task.delay(dur or 3, function()
		if not card.Parent then return end
		tween(card, 0.2, { BackgroundTransparency = 1 })
		tween(st, 0.2, { Transparency = 1 })
		tween(t1, 0.2, { TextTransparency = 1 })
		if t2 then tween(t2, 0.2, { TextTransparency = 1 }) end
		task.delay(0.24, function() if card then card:Destroy() end end)
	end)
end

--==============================================================================
-- 06 Â· CONTROLES
--==============================================================================

local Section = {}
Section.__index = Section

function Section:_row(h)
	self._n += 1
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = self._n, Parent = self.frame })
	vlist(6, row)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, h or 24), BackgroundTransparency = 1,
		LayoutOrder = 1, Parent = row })
	return row, head
end

local function initial(o)
	if o.flag ~= nil and S[o.flag] ~= nil then return S[o.flag] end
	return o.default
end

function Section:Toggle(o)
	local row, head = self:_row(24)
	label(head, o.text, { Size = UDim2.new(1, -50, 1, 0), TextSize = 12.5 })
	local track = new("Frame", { Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9),
		BackgroundColor3 = T.Bg, BorderSizePixel = 0, Parent = head })
	corner(9, track)
	local ts = stroke(T.Stroke, 1, track)
	local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = T.Dim, BorderSizePixel = 0, Parent = track })
	corner(6, knob)
	local btn = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = head })

	local state = initial(o) == true
	local function apply(v, fire)
		state = v == true
		tween(knob, 0.16, { Position = UDim2.fromOffset(state and 19 or 3, 3), BackgroundColor3 = state and T.Bg or T.Dim })
		tween(track, 0.16, { BackgroundColor3 = state and T.Accent or T.Bg })
		tween(ts, 0.16, { Color = state and T.Accent or T.Stroke })
		if o.flag then S[o.flag] = state end
		if fire ~= false and o.callback then
			local ok, err = pcall(o.callback, state)
			if not ok then notify("Erro: " .. tostring(o.text), tostring(err), 6, "bad") end
		end
	end
	btn.MouseButton1Click:Connect(function() apply(not state) end)
	apply(state, false)
	if o.flag then Lib.Flags[o.flag] = function(v) apply(v == true, true) end end
	return { Set = apply, Get = function() return state end }
end

function Section:Slider(o)
	local row, head = self:_row(38)
	label(head, o.text, { Size = UDim2.new(1, -70, 0, 16), TextSize = 12.5 })
	local val = label(head, "", { Size = UDim2.fromOffset(64, 16), Position = UDim2.new(1, -64, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 12, TextColor3 = T.Accent })
	local track = new("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = T.Bg, BorderSizePixel = 0, Parent = head })
	corner(3, track)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = track })
	corner(3, fill)
	local knob = new("Frame", { Size = UDim2.fromOffset(11, 11), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = T.Text, BorderSizePixel = 0, Parent = track })
	corner(6, knob)
	local hit = new("TextButton", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 18),
		BackgroundTransparency = 1, Text = "", Parent = head })

	local mn, mx, dec = o.min or 0, o.max or 100, o.decimals or 0
	local cur = tonumber(initial(o)) or mn
	local function apply(v, fire)
		v = math.clamp(round(tonumber(v) or mn, dec), mn, mx)
		cur = v
		local a = (v - mn) / math.max(mx - mn, 0.0001)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		val.Text = tostring(v) .. (o.suffix or "")
		if o.flag then S[o.flag] = v end
		if fire ~= false and o.callback then pcall(o.callback, v) end
	end
	dragHook(hit, function(p)
		local a = math.clamp((p.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		apply(mn + (mx - mn) * a)
	end)
	apply(cur, false)
	if o.flag then Lib.Flags[o.flag] = function(v) apply(v, true) end end
	return { Set = apply, Get = function() return cur end }
end

function Section:Button(o)
	local row, head = self:_row(28)
	local idle = o.danger and Color3.fromRGB(58, 32, 38) or T.Card2
	local b = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = idle, Text = o.text, Font = T.FontM, TextSize = 12.5,
		TextColor3 = o.danger and T.Bad or T.Text, AutoButtonColor = false, BorderSizePixel = 0, Parent = head,
	})
	corner(8, b)
	stroke(o.danger and Color3.fromRGB(88, 44, 52) or T.Stroke2, 1, b)
	b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = o.danger and Color3.fromRGB(74, 38, 46) or T.Stroke }) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = idle }) end)
	b.MouseButton1Click:Connect(function()
		tween(b, 0.08, { BackgroundColor3 = T.Accent })
		task.delay(0.1, function() tween(b, 0.14, { BackgroundColor3 = idle }) end)
		if o.callback then
			local ok, err = pcall(o.callback)
			if not ok then notify("Erro: " .. tostring(o.text), tostring(err), 6, "bad") end
		end
	end)
	return { Button = b }
end

function Section:Dropdown(o)
	local hasLabel = o.text ~= nil and o.text ~= ""
	local row, head = self:_row(hasLabel and 44 or 26)
	if hasLabel then label(head, o.text, { Size = UDim2.new(1, 0, 0, 16), TextSize = 12.5 }) end
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, hasLabel and 18 or 0),
		BackgroundColor3 = T.Bg, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = head,
	})
	corner(8, btn); stroke(T.Stroke2, 1, btn)
	local sel = label(btn, "", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0),
		TextSize = 12, TextColor3 = T.Sub, TextTruncate = Enum.TextTruncate.AtEnd })
	local arrow = label(btn, "â–¾", { Position = UDim2.new(1, -20, 0, 0), Size = UDim2.fromOffset(14, 26),
		TextColor3 = T.Dim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center })

	local listF = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 100), BackgroundColor3 = T.Bg, BorderSizePixel = 0, Visible = false,
		LayoutOrder = 2, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = T.Stroke, Parent = row,
	})
	corner(8, listF); stroke(T.Stroke2, 1, listF); padding(4, 4, 4, 4, listF)
	vlist(2, listF)

	local multi = o.multi == true
	local options = o.options or {}
	local chosen = initial(o)
	if multi and type(chosen) ~= "table" then chosen = {} end

	local function summary()
		if multi then
			if #chosen == 0 then return "nenhum" end
			if #chosen <= 2 then return table.concat(chosen, ", ") end
			return #chosen .. " selecionados"
		end
		if chosen == nil then return "-" end
		return tostring(chosen)
	end

	-- BUG CORRIGIDO: aqui antes um booleano ia pra TextColor3 e matava o script
	local function filled()
		if multi then return #chosen > 0 end
		return chosen ~= nil
	end

	local rebuild
	local function fire()
		sel.Text = summary()
		sel.TextColor3 = filled() and T.Text or T.Sub
		if o.flag then S[o.flag] = multi and table.clone(chosen) or chosen end
		if o.callback then pcall(o.callback, chosen) end
	end

	rebuild = function()
		for _, c in ipairs(listF:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for idx, opt in ipairs(options) do
			local on
			if multi then on = table.find(chosen, opt) ~= nil else on = (chosen == opt) end
			local ob = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Card2, BackgroundTransparency = on and 0 or 1,
				Text = "", AutoButtonColor = false, LayoutOrder = idx, BorderSizePixel = 0, Parent = listF,
			})
			corner(6, ob)
			label(ob, tostring(opt), { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0),
				TextSize = 12, TextColor3 = on and T.Accent or T.Sub, TextTruncate = Enum.TextTruncate.AtEnd })
			if on then
				label(ob, "â€¢", { Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(12, 24),
					TextColor3 = T.Accent, Font = T.FontB, TextXAlignment = Enum.TextXAlignment.Center })
			end
			ob.MouseButton1Click:Connect(function()
				if multi then
					local at = table.find(chosen, opt)
					if at then table.remove(chosen, at) else table.insert(chosen, opt) end
				else
					chosen = opt
					listF.Visible = false
					arrow.Text = "â–¾"
				end
				fire(); rebuild()
			end)
		end
		listF.Size = UDim2.new(1, 0, 0, math.min(#options * 26 + 8, 132))
	end

	btn.MouseButton1Click:Connect(function()
		listF.Visible = not listF.Visible
		arrow.Text = listF.Visible and "â–´" or "â–¾"
	end)

	rebuild(); fire()

	local api = {}
	function api.SetOptions(list, keep)
		options = list or {}
		if not keep then
			if multi then chosen = {} else chosen = nil end
		end
		rebuild(); fire()
	end
	function api.Get() return chosen end
	function api.Set(v)
		if multi then chosen = type(v) == "table" and v or {} else chosen = v end
		rebuild(); fire()
	end
	if o.flag then Lib.Flags[o.flag] = api.Set end
	if o.id then Lib.Refreshers[o.id] = api end
	return api
end

function Section:TextBox(o)
	local hasLabel = o.text ~= nil and o.text ~= ""
	local row, head = self:_row(hasLabel and 44 or 26)
	if hasLabel then label(head, o.text, { Size = UDim2.new(1, 0, 0, 16), TextSize = 12.5 }) end
	local box = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, hasLabel and 18 or 0),
		BackgroundColor3 = T.Bg, BorderSizePixel = 0, Parent = head })
	corner(8, box)
	local bs = stroke(T.Stroke2, 1, box)
	local tb = new("TextBox", {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1,
		Text = tostring(initial(o) or ""), PlaceholderText = o.placeholder or "", PlaceholderColor3 = T.Dim,
		Font = T.Font, TextSize = 12, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, Parent = box,
	})
	tb.Focused:Connect(function() tween(bs, 0.14, { Color = T.Accent }) end)
	tb.FocusLost:Connect(function(enter)
		tween(bs, 0.14, { Color = T.Stroke2 })
		if o.flag then S[o.flag] = tb.Text end
		if o.callback then pcall(o.callback, tb.Text, enter) end
	end)
	if o.flag then Lib.Flags[o.flag] = function(v) tb.Text = tostring(v) end end
	return { Get = function() return tb.Text end, Set = function(v) tb.Text = tostring(v) end }
end

local capturing = nil
function Section:Keybind(o)
	local row, head = self:_row(24)
	label(head, o.text, { Size = UDim2.new(1, -90, 1, 0), TextSize = 12.5 })
	local b = new("TextButton", {
		Size = UDim2.fromOffset(86, 22), Position = UDim2.new(1, -86, 0.5, -11), BackgroundColor3 = T.Bg,
		Text = tostring(initial(o) or "-"), Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.Sub,
		AutoButtonColor = false, BorderSizePixel = 0, Parent = head,
	})
	corner(6, b); stroke(T.Stroke2, 1, b)
	b.MouseButton1Click:Connect(function()
		b.Text = "..."; b.TextColor3 = T.Accent
		capturing = function(keyName)
			b.Text = keyName; b.TextColor3 = T.Sub
			if o.flag then S[o.flag] = keyName end
		end
	end)
	if o.flag then Lib.Flags[o.flag] = function(v) b.Text = tostring(v) end end
	return { Button = b }
end

function Section:ColorPicker(o)
	local row, head = self:_row(24)
	label(head, o.text, { Size = UDim2.new(1, -52, 1, 0), TextSize = 12.5 })
	local sw = new("TextButton", { Size = UDim2.fromOffset(40, 18), Position = UDim2.new(1, -40, 0.5, -9),
		BackgroundColor3 = initial(o) or Color3.new(1, 1, 1), Text = "", AutoButtonColor = false,
		BorderSizePixel = 0, Parent = head })
	corner(6, sw); stroke(T.Stroke, 1, sw)

	local panel = new("Frame", { Size = UDim2.new(1, 0, 0, 118), BackgroundColor3 = T.Bg, BorderSizePixel = 0,
		Visible = false, LayoutOrder = 2, Parent = row })
	corner(8, panel); stroke(T.Stroke2, 1, panel); padding(8, 8, 8, 8, panel)

	local sv = new("Frame", { Size = UDim2.new(1, -34, 1, -22), BackgroundColor3 = Color3.new(1, 0, 0),
		BorderSizePixel = 0, Parent = panel })
	corner(6, sv)
	local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, Parent = sv })
	corner(6, white)
	new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Parent = white })
	local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0, Parent = sv })
	corner(6, black)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Parent = black })
	local cursor = new("Frame", { Size = UDim2.fromOffset(9, 9), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1, ZIndex = 5, Parent = sv })
	corner(5, cursor); stroke(Color3.new(1, 1, 1), 2, cursor)

	local hue = new("Frame", { Size = UDim2.fromOffset(20, 96), Position = UDim2.new(1, -20, 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = panel })
	corner(6, hue)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	}), Parent = hue })
	local hcur = new("Frame", { Size = UDim2.new(1, 4, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		ZIndex = 5, Parent = hue })
	local hexBox = new("TextBox", { Size = UDim2.new(1, -34, 0, 16), Position = UDim2.new(0, 0, 1, -16),
		BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.Dim, Text = "",
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })

	local c0 = initial(o) or Color3.new(1, 1, 1)
	local h, s, v = Color3.toHSV(c0)
	local function apply(fire)
		local col = Color3.fromHSV(h, s, v)
		sw.BackgroundColor3 = col
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		cursor.Position = UDim2.fromScale(s, 1 - v)
		hcur.Position = UDim2.new(0.5, 0, h, 0)
		-- BUG CORRIGIDO: %X exige inteiro no Luau
		hexBox.Text = string.format("#%02X%02X%02X", i(col.R * 255 + 0.5), i(col.G * 255 + 0.5), i(col.B * 255 + 0.5))
		if o.flag then S[o.flag] = col end
		if fire ~= false and o.callback then pcall(o.callback, col) end
	end
	dragHook(sv, function(p)
		s = math.clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
		apply()
	end)
	dragHook(hue, function(p)
		h = math.clamp((p.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
		apply()
	end)
	hexBox.FocusLost:Connect(function()
		local hx = string.gsub(hexBox.Text, "#", "")
		if #hx == 6 and tonumber(hx, 16) then
			local n = tonumber(hx, 16)
			h, s, v = Color3.toHSV(Color3.fromRGB(bit32.rshift(n, 16) % 256, bit32.rshift(n, 8) % 256, n % 256))
		end
		apply()
	end)
	sw.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
	apply(false)
	if o.flag then
		Lib.Flags[o.flag] = function(col)
			if typeof(col) == "Color3" then h, s, v = Color3.toHSV(col); apply() end
		end
	end
	return { Set = function(col) h, s, v = Color3.toHSV(col); apply() end }
end

function Section:Label(text, color)
	local row, head = self:_row(0)
	head.Size = UDim2.new(1, 0, 0, 0)
	head.AutomaticSize = Enum.AutomaticSize.Y
	local l = label(head, text, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 11.5, TextColor3 = color or T.Sub, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top })
	return { Set = function(v) l.Text = tostring(v) end }
end

function Section:Divider()
	local _, head = self:_row(1)
	head.BackgroundColor3 = T.Stroke2
	head.BackgroundTransparency = 0
	head.BorderSizePixel = 0
end

function Section:Console(height)
	local _, head = self:_row(height or 150)
	local sf = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bg, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.Stroke, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = head })
	corner(8, sf); stroke(T.Stroke2, 1, sf); padding(6, 6, 6, 6, sf)
	vlist(2, sf)
	local n = 0
	local api = {}
	function api.Add(text, color, cb)
		n += 1
		if n > 220 then
			for _, k in ipairs(sf:GetChildren()) do
				if k:IsA("GuiObject") then k:Destroy() break end
			end
		end
		local host
		if cb then
			host = new("TextButton", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, Text = "", LayoutOrder = n, Parent = sf })
			host.MouseButton1Click:Connect(function() pcall(cb) end)
		else
			host = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, LayoutOrder = n, Parent = sf })
		end
		label(host, text, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Code, TextSize = 11.5, TextColor3 = color or T.Sub, TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top })
		task.defer(function()
			if sf.Parent then sf.CanvasPosition = Vector2.new(0, math.max(sf.AbsoluteCanvasSize.Y, 0)) end
		end)
		return host
	end
	function api.Clear()
		n = 0
		for _, k in ipairs(sf:GetChildren()) do
			if k:IsA("GuiObject") then k:Destroy() end
		end
	end
	return api
end

--------------------------------------------------------------------- tabs -----
local tabButtons = {}
function Lib:Tab(name, desc)
	local order = #tabButtons + 1
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Card,
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order,
		BorderSizePixel = 0, Parent = TabBar })
	corner(8, btn)
	local bar = new("Frame", { Size = UDim2.fromOffset(2, 0), Position = UDim2.fromOffset(0, 16),
		AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = btn })
	local tl = label(btn, name, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -20, 1, 0),
		TextSize = 12.5, TextColor3 = T.Sub, Font = T.FontM })

	local page = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, Visible = false, ScrollBarThickness = 4, ScrollBarImageColor3 = T.Stroke,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Pages })
	padding(0, 10, 20, 0, page)
	hlist(12, page)
	local cols = {}
	for n = 1, 2 do
		cols[n] = new("Frame", { Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, LayoutOrder = n, Parent = page })
		vlist(12, cols[n])
	end

	local tab = { name = name, page = page, _sec = 0 }
	function tab:Section(title, side)
		local col = cols[side == 2 and 2 or 1]
		self._sec += 1
		local f = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = self._sec, Parent = col })
		corner(11, f); stroke(T.Stroke2, 1, f); padding(12, 13, 14, 13, f)
		vlist(9, f)
		new("TextLabel", { Text = string.upper(title), Font = T.FontB, TextSize = 10.5, TextColor3 = T.Dim,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 13), LayoutOrder = 0, Parent = f })
		return setmetatable({ frame = f, _n = 0 }, Section)
	end

	local function select()
		for _, t in ipairs(tabButtons) do
			t.page.Visible = false
			tween(t.btn, 0.14, { BackgroundTransparency = 1 })
			tween(t.label, 0.14, { TextColor3 = T.Sub })
			tween(t.bar, 0.14, { Size = UDim2.fromOffset(2, 0) })
		end
		page.Visible = true
		tween(btn, 0.16, { BackgroundTransparency = 0 })
		tween(tl, 0.16, { TextColor3 = T.Text })
		tween(bar, 0.2, { Size = UDim2.fromOffset(2, 18) })
		HeadTitle.Text = name
		HeadDesc.Text = desc or ""
	end
	btn.MouseButton1Click:Connect(select)
	btn.MouseEnter:Connect(function()
		if not page.Visible then tween(btn, 0.12, { BackgroundTransparency = 0.6 }) end
	end)
	btn.MouseLeave:Connect(function()
		if not page.Visible then tween(btn, 0.12, { BackgroundTransparency = 1 }) end
	end)

	table.insert(tabButtons, { page = page, btn = btn, label = tl, bar = bar, select = select })
	if order == 1 then select() end
	return tab
end

--==============================================================================
-- 07 Â· ENGINE DE ESP
--==============================================================================

local ESP = { Targets = {}, Active = {}, Highlights = {}, Focus = nil }
local HLFolder = new("Folder", { Name = "NX_Highlights", Parent = Workspace })

local CORNERS = {
	Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
	Vector3.new(1, -1, -1), Vector3.new(1, -1, 1), Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}
local EDGES = { {1,2},{1,3},{1,5},{2,4},{2,6},{3,4},{3,7},{4,8},{5,6},{5,7},{6,8},{7,8} }
local BONES_R15 = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local BONES_R6 = { {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"} }

local function mkLine(parent, z)
	return new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1, 1), Visible = false,
		ZIndex = z or 2, Parent = parent })
end

local function setLine(f, a, b, thick, color)
	local d = b - a
	local mag = d.Magnitude
	if mag ~= mag or mag > 12000 then f.Visible = false return end
	f.Size = UDim2.fromOffset(math.max(mag, 1), thick)
	f.Position = UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.BackgroundColor3 = color
	f.Visible = true
end

local function mkText(parent, size, align)
	return new("TextLabel", { BackgroundTransparency = 1, Font = T.FontB, TextSize = size or 13,
		TextColor3 = T.Text, TextStrokeTransparency = 0.35, TextStrokeColor3 = Color3.new(0, 0, 0),
		TextXAlignment = align or Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.fromOffset(200, 14), Visible = false, ZIndex = 3, Parent = parent })
end

local function createDrawing()
	local d = {}
	d.holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = EspHolder })
	d.fill = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85,
		BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = d.holder })
	d.box = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2, Parent = d.holder })
	d.boxStroke = stroke(Color3.new(1, 1, 1), 1, d.box)
	d.cor = {}; for n = 1, 8 do d.cor[n] = mkLine(d.holder) end
	d.b3 = {};  for n = 1, 12 do d.b3[n] = mkLine(d.holder) end
	d.bone = {};for n = 1, 16 do d.bone[n] = mkLine(d.holder) end
	d.tracer = mkLine(d.holder, 1)
	d.look = mkLine(d.holder, 2)
	d.hpBg = new("Frame", { BackgroundColor3 = Color3.fromRGB(12, 12, 14), BorderSizePixel = 0,
		Visible = false, ZIndex = 2, Parent = d.holder })
	d.hpFill = new("Frame", { BackgroundColor3 = T.Good, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = d.hpBg })
	d.dot = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 3, Parent = d.holder })
	corner(20, d.dot)
	d.name = mkText(d.holder, 13)
	d.dist = mkText(d.holder, 12)
	d.info = mkText(d.holder, 12, Enum.TextXAlignment.Left)
	d.arrow = mkText(d.holder, 18)
	d.arrow.Text = "âž¤"
	d.arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	return d
end

local function hideDrawing(d) d.holder.Visible = false end
local function espFont() return FONTS[S.ESP_Font] or Enum.Font.GothamBold end
local function isAlive(t)
	if not t.humanoid then return true end
	return t.humanoid.Health > 0
end

function ESP:Refresh()
	local list = {}

	if S.ESP_Players then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer or S.ESP_ShowSelf then
				local c = p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				local r = c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
				if c and r then
					local skip = false
					if S.ESP_TeamCheck and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then skip = true end
					if ESP.Focus and p.Name ~= ESP.Focus then skip = true end
					if not skip then
						table.insert(list, { model = c, humanoid = h, player = p, type = "Player", name = p.Name })
					end
				end
			end
		end
	end

	if S.ESP_NPCs then
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("Humanoid") then
				local m = o.Parent
				if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
					local r = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
					if r then table.insert(list, { model = m, humanoid = o, type = "NPC", name = m.Name }) end
				end
			end
		end
	end

	if S.ESP_Objects then
		local classes = S.OBJ_Classes or {}
		local words = {}
		for w in string.gmatch(string.lower(S.OBJ_Keywords or ""), "[^,]+") do
			w = string.match(w, "^%s*(.-)%s*$")
			if w and w ~= "" then table.insert(words, w) end
		end
		if #classes > 0 or #words > 0 then
			local count = 0
			local myChar = chr()
			for _, o in ipairs(Workspace:GetDescendants()) do
				if count >= (S.OBJ_Limit or 250) then break end
				local hitClass = false
				for _, cl in ipairs(classes) do
					if o.ClassName == cl then hitClass = true break end
				end
				local hitWord = false
				if #words > 0 then
					local ln = string.lower(o.Name)
					for _, w in ipairs(words) do
						if string.find(ln, w, 1, true) then hitWord = true break end
					end
				end
				if (hitClass or hitWord) and not o:IsDescendantOf(HLFolder) then
					local part = o:IsA("BasePart") and o or nil
					local model = o:IsA("Model") and o or nil
					if not part and not model then part = o:FindFirstChildWhichIsA("BasePart", true) end
					if (part or model) and not (myChar and o:IsDescendantOf(myChar)) then
						count += 1
						table.insert(list, { model = model or part, part = part, type = "Object", name = o.Name })
					end
				end
			end
		end
	end

	local keep = {}
	for _, t in ipairs(list) do keep[t.model] = true end
	for m, d in pairs(self.Active) do
		if not keep[m] then d.holder:Destroy(); self.Active[m] = nil end
	end
	for m, hl in pairs(self.Highlights) do
		if not keep[m] then hl:Destroy(); self.Highlights[m] = nil end
	end
	self.Targets = list
end

local function targetColor(t, visible)
	if S.ESP_Rainbow then return Color3.fromHSV((tick() * 0.25) % 1, 0.72, 1) end
	if t.type == "Object" then return S.C_Object end
	if t.type == "NPC" then return S.C_NPC end
	if S.ESP_TeamColor and t.player and t.player.Team then return t.player.TeamColor.Color end
	if S.ESP_VisibilityCheck then return visible and S.C_Visible or S.C_Hidden end
	return S.C_Visible
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function checkVisible(t, pos, camPos)
	local ignore = { HLFolder }
	local c = chr()
	if c then table.insert(ignore, c) end
	if t.model then table.insert(ignore, t.model) end
	rayParams.FilterDescendantsInstances = ignore
	local dir = pos - camPos
	if dir.Magnitude < 1 then return true end
	return Workspace:Raycast(camPos, dir, rayParams) == nil
end

local function updateHighlight(t, col)
	local m = t.model
	if not S.ESP_Chams and not S.ESP_Outline then
		if ESP.Highlights[m] then ESP.Highlights[m]:Destroy(); ESP.Highlights[m] = nil end
		return
	end
	local hl = ESP.Highlights[m]
	if not hl or not hl.Parent then
		hl = new("Highlight", { Name = "NX_HL", Parent = HLFolder })
		ESP.Highlights[m] = hl
	end
	hl.Adornee = m
	hl.DepthMode = S.ESP_ChamsThrough and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.FillColor = col
	hl.OutlineColor = col
	hl.FillTransparency = S.ESP_Chams and S.ESP_ChamsOpacity or 1
	hl.OutlineTransparency = S.ESP_Outline and 0 or 1
end

local function statusLines(t)
	local lines = {}
	local h, p = t.humanoid, t.player
	if S.ST_Health and h then
		if S.ST_MaxHealth then table.insert(lines, string.format("HP %d/%d", i(h.Health), i(h.MaxHealth)))
		else table.insert(lines, "HP " .. i(h.Health)) end
	elseif S.ST_MaxHealth and h then
		table.insert(lines, "MAX " .. i(h.MaxHealth))
	end
	if S.ST_WalkSpeed and h then table.insert(lines, "SPD " .. round(h.WalkSpeed, 1)) end
	if S.ST_JumpPower and h then
		table.insert(lines, h.UseJumpPower and ("JMP " .. round(h.JumpPower, 1)) or ("JH " .. round(h.JumpHeight, 1)))
	end
	if S.ST_State and h then table.insert(lines, tostring(h:GetState().Name)) end
	if S.ST_Sitting and h and h.Sit then table.insert(lines, "sentado") end
	if S.ST_Tool then
		local tool = t.model and t.model:FindFirstChildOfClass("Tool")
		table.insert(lines, "[" .. (tool and tool.Name or "vazio") .. "]")
	end
	if S.ST_Team and p then table.insert(lines, "team: " .. (p.Team and p.Team.Name or "none")) end
	if S.ST_Display and p and p.DisplayName ~= p.Name then table.insert(lines, "(" .. p.DisplayName .. ")") end
	if S.ST_UserId and p then table.insert(lines, "id " .. p.UserId) end
	if S.ST_AccountAge and p then table.insert(lines, p.AccountAge .. " dias") end
	if S.ST_Leaderstats and p then
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			for _, val in ipairs(ls:GetChildren()) do
				if val:IsA("ValueBase") then table.insert(lines, val.Name .. ": " .. tostring(val.Value)) end
			end
		end
	end
	if S.ST_Attributes and t.model then
		for k, val in pairs(t.model:GetAttributes()) do table.insert(lines, k .. " = " .. tostring(val)) end
	end
	local r = t.part
	if not r and t.model then
		r = t.model:IsA("BasePart") and t.model or t.model:FindFirstChild("HumanoidRootPart")
			or (t.model:IsA("Model") and t.model.PrimaryPart) or nil
	end
	if S.ST_Velocity and r and r:IsA("BasePart") then
		table.insert(lines, "vel " .. round(r.AssemblyLinearVelocity.Magnitude, 1))
	end
	if S.ST_Position and r and r:IsA("BasePart") then
		local pp = r.Position
		table.insert(lines, string.format("%d, %d, %d", i(pp.X), i(pp.Y), i(pp.Z)))
	end
	return lines
end

local function renderTarget(t, d, camPos, vp)
	local model = t.model
	local prim = t.part
	if not prim then
		if model:IsA("BasePart") then prim = model
		else prim = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart") end
	end
	if not prim then hideDrawing(d) return end
	if S.ESP_AliveOnly and t.type ~= "Object" and not isAlive(t) then hideDrawing(d) return end

	local pos = prim.Position
	local dist = (camPos - pos).Magnitude
	if dist > S.ESP_MaxDistance then hideDrawing(d) return end

	local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	local sp, onScreen = Camera:WorldToViewportPoint(pos)

	if S.ESP_Arrows and not onScreen then
		local dir = Vector2.new(sp.X, sp.Y) - center
		if sp.Z <= 0 then dir = -dir end
		if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
		local u = dir.Unit
		local rad = math.min(vp.X, vp.Y) * 0.33
		d.holder.Visible = true
		d.arrow.Visible = true
		d.arrow.Size = UDim2.fromOffset(24, 24)
		d.arrow.Position = UDim2.fromOffset(center.X + u.X * rad, center.Y + u.Y * rad)
		d.arrow.Rotation = math.deg(math.atan2(u.Y, u.X))
		d.arrow.TextColor3 = targetColor(t, false)
	else
		d.arrow.Visible = false
	end

	if sp.Z <= 0 then
		for _, e in ipairs({ d.box, d.fill, d.hpBg, d.dot, d.name, d.dist, d.info, d.tracer, d.look }) do e.Visible = false end
		for n = 1, 8 do d.cor[n].Visible = false end
		for n = 1, 12 do d.b3[n].Visible = false end
		for n = 1, 16 do d.bone[n].Visible = false end
		if not d.arrow.Visible then hideDrawing(d) end
		return
	end

	d.holder.Visible = true

	local cf, size
	if t.part or model:IsA("BasePart") then
		cf, size = prim.CFrame, prim.Size
	else
		local ok, a, b = pcall(function() return model:GetBoundingBox() end)
		if ok and a then cf, size = a, b else cf, size = prim.CFrame, prim.Size end
	end

	local pts, minX, minY, maxX, maxY = {}, math.huge, math.huge, -math.huge, -math.huge
	local bad = false
	local hs = size * 0.5
	for n = 1, 8 do
		local c = CORNERS[n]
		local wp = cf:PointToWorldSpace(Vector3.new(c.X * hs.X, c.Y * hs.Y, c.Z * hs.Z))
		local s2 = Camera:WorldToViewportPoint(wp)
		if s2.Z <= 0 then bad = true break end
		pts[n] = Vector2.new(s2.X, s2.Y)
		if s2.X < minX then minX = s2.X end
		if s2.Y < minY then minY = s2.Y end
		if s2.X > maxX then maxX = s2.X end
		if s2.Y > maxY then maxY = s2.Y end
	end
	if bad then minX, minY, maxX, maxY = sp.X - 20, sp.Y - 30, sp.X + 20, sp.Y + 30 end
	local w, hgt = math.max(maxX - minX, 4), math.max(maxY - minY, 4)

	local visible = true
	if S.ESP_VisibilityCheck then visible = checkVisible(t, pos, camPos) end
	local col = targetColor(t, visible)
	local thick = S.ESP_Thickness
	local fnt = espFont()

	local wantBox = S.ESP_Box and t.type ~= "Object"
	d.box.Visible = wantBox and S.ESP_BoxType == "Completa"
	if d.box.Visible then
		d.box.Position = UDim2.fromOffset(minX, minY)
		d.box.Size = UDim2.fromOffset(w, hgt)
		d.boxStroke.Color = col
		d.boxStroke.Thickness = thick
	end
	for n = 1, 8 do d.cor[n].Visible = false end
	if wantBox and S.ESP_BoxType == "Cantos" then
		local cw, ch = w * 0.3, hgt * 0.22
		local L = {
			{ Vector2.new(minX, minY), Vector2.new(minX + cw, minY) },
			{ Vector2.new(minX, minY), Vector2.new(minX, minY + ch) },
			{ Vector2.new(maxX, minY), Vector2.new(maxX - cw, minY) },
			{ Vector2.new(maxX, minY), Vector2.new(maxX, minY + ch) },
			{ Vector2.new(minX, maxY), Vector2.new(minX + cw, maxY) },
			{ Vector2.new(minX, maxY), Vector2.new(minX, maxY - ch) },
			{ Vector2.new(maxX, maxY), Vector2.new(maxX - cw, maxY) },
			{ Vector2.new(maxX, maxY), Vector2.new(maxX, maxY - ch) },
		}
		for n = 1, 8 do setLine(d.cor[n], L[n][1], L[n][2], thick, col) end
	end
	for n = 1, 12 do d.b3[n].Visible = false end
	if wantBox and S.ESP_BoxType == "3D" and not bad then
		for n, e in ipairs(EDGES) do setLine(d.b3[n], pts[e[1]], pts[e[2]], thick, col) end
	end
	d.fill.Visible = wantBox and S.ESP_BoxFill
	if d.fill.Visible then
		d.fill.Position = UDim2.fromOffset(minX, minY)
		d.fill.Size = UDim2.fromOffset(w, hgt)
		d.fill.BackgroundColor3 = col
		d.fill.BackgroundTransparency = S.ESP_FillOpacity
	end

	d.name.Visible = S.ESP_Name
	if d.name.Visible then
		d.name.Text = t.name
		d.name.Font = fnt
		d.name.TextSize = S.ESP_TextSize
		d.name.TextColor3 = S.C_Text
		d.name.Size = UDim2.fromOffset(240, S.ESP_TextSize + 2)
		d.name.Position = UDim2.fromOffset(minX + w * 0.5 - 120, minY - S.ESP_TextSize - 3)
	end

	local bottom = {}
	if S.ESP_Distance then table.insert(bottom, i(dist) .. "m") end
	if S.ESP_HealthText and t.humanoid then
		table.insert(bottom, i(t.humanoid.Health) .. "/" .. i(t.humanoid.MaxHealth) .. " hp")
	end
	d.dist.Visible = #bottom > 0
	if d.dist.Visible then
		d.dist.Text = table.concat(bottom, "  ")
		d.dist.Font = fnt
		d.dist.TextSize = S.ESP_TextSize - 1
		d.dist.TextColor3 = S.C_Text
		d.dist.Size = UDim2.fromOffset(240, S.ESP_TextSize + 2)
		d.dist.Position = UDim2.fromOffset(minX + w * 0.5 - 120, maxY + 2)
	end

	local lines = t.type == "Object" and {} or statusLines(t)
	d.info.Visible = #lines > 0
	if d.info.Visible then
		d.info.Text = table.concat(lines, "\n")
		d.info.Font = fnt
		d.info.TextSize = S.ESP_TextSize - 1
		d.info.TextColor3 = S.C_Text
		d.info.Size = UDim2.fromOffset(180, (S.ESP_TextSize + 1) * #lines + 4)
		d.info.Position = UDim2.fromOffset(maxX + 5, minY)
	end

	if S.ESP_HealthBar and t.humanoid then
		local a = math.clamp(t.humanoid.Health / math.max(t.humanoid.MaxHealth, 1), 0, 1)
		d.hpBg.Visible = true
		d.hpBg.Position = UDim2.fromOffset(minX - 6, minY)
		d.hpBg.Size = UDim2.fromOffset(3, hgt)
		d.hpFill.Size = UDim2.fromScale(1, a)
		d.hpFill.BackgroundColor3 = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(110, 230, 150), a)
	else
		d.hpBg.Visible = false
	end

	d.tracer.Visible = false
	if S.ESP_Tracer then
		local from
		if S.ESP_TracerFrom == "Centro" then from = center
		elseif S.ESP_TracerFrom == "Topo" then from = Vector2.new(vp.X * 0.5, 0)
		elseif S.ESP_TracerFrom == "Mouse" then from = UserInputService:GetMouseLocation()
		else from = Vector2.new(vp.X * 0.5, vp.Y) end
		setLine(d.tracer, from, Vector2.new(minX + w * 0.5, maxY), thick, col)
	end

	for n = 1, 16 do d.bone[n].Visible = false end
	if S.ESP_Skeleton and t.humanoid and model:IsA("Model") then
		local set = model:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
		local n = 0
		for _, pair in ipairs(set) do
			local a, b = model:FindFirstChild(pair[1]), model:FindFirstChild(pair[2])
			if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				local sa = Camera:WorldToViewportPoint(a.Position)
				local sb = Camera:WorldToViewportPoint(b.Position)
				if sa.Z > 0 and sb.Z > 0 then
					n += 1
					if n <= 16 then setLine(d.bone[n], Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), math.max(thick, 1), col) end
				end
			end
		end
	end

	local wantDot = (S.ESP_HeadDot and t.type ~= "Object") or (t.type == "Object" and S.OBJ_Dot)
	d.dot.Visible = wantDot == true
	if wantDot then
		local hp = pos
		local head = model:IsA("Model") and model:FindFirstChild("Head")
		if head and head:IsA("BasePart") and t.type ~= "Object" then hp = head.Position end
		local ds = Camera:WorldToViewportPoint(hp)
		local sz = math.clamp(700 / math.max(dist, 1), 3, 12)
		d.dot.Size = UDim2.fromOffset(sz, sz)
		d.dot.Position = UDim2.fromOffset(ds.X, ds.Y)
		d.dot.BackgroundColor3 = col
	end

	d.look.Visible = false
	if S.ESP_LookVector and t.type ~= "Object" then
		local origin = model:IsA("Model") and (model:FindFirstChild("Head") or prim) or prim
		if origin and origin:IsA("BasePart") then
			local a = Camera:WorldToViewportPoint(origin.Position)
			local b = Camera:WorldToViewportPoint(origin.Position + origin.CFrame.LookVector * 8)
			if a.Z > 0 and b.Z > 0 then setLine(d.look, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), thick, col) end
		end
	end

	updateHighlight(t, col)
end

local espErrors = 0
local function espStep()
	if not S.ESP_Master then
		for _, d in pairs(ESP.Active) do hideDrawing(d) end
		for m, hl in pairs(ESP.Highlights) do hl:Destroy(); ESP.Highlights[m] = nil end
		return
	end
	local vp = Camera.ViewportSize
	local camPos = Camera.CFrame.Position
	for _, t in ipairs(ESP.Targets) do
		local m = t.model
		if m and m.Parent then
			local d = ESP.Active[m]
			if not d then d = createDrawing(); ESP.Active[m] = d end
			local ok, err = pcall(renderTarget, t, d, camPos, vp)
			if not ok then
				espErrors += 1
				if espErrors == 1 then
					warn("[NEXUS] ESP: " .. tostring(err))
					notify("ESP: erro isolado", tostring(err), 6, "warn")
				end
			end
		end
	end
end

--==============================================================================
-- 08 Â· FEATURES
--==============================================================================

local ORIG = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
	FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
	Gravity = Workspace.Gravity, FOV = Camera.FieldOfView,
	ZoomMax = LocalPlayer.CameraMaxZoomDistance,
}

local CC = new("ColorCorrectionEffect", { Name = "NX_CC", Enabled = false, Parent = Lighting })

local flyBV, flyBG
local function setFly(on)
	S.Fly = on
	local h, r = hum(), root()
	if on then
		if not r then notify("Fly", "personagem nÃ£o encontrado", 3, "warn") S.Fly = false return end
		flyBV = new("BodyVelocity", { Name = "NX_Fly", Velocity = Vector3.zero,
			MaxForce = Vector3.one * 9e9, P = 1250, Parent = r })
		flyBG = new("BodyGyro", { Name = "NX_Gyro", P = 9e4, D = 100,
			MaxTorque = Vector3.one * 9e9, CFrame = Camera.CFrame, Parent = r })
		if h then h.PlatformStand = true end
		notify("Voando", "WASD move, EspaÃ§o sobe, Ctrl desce", 3, "good")
	else
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
		if h then h.PlatformStand = false end
	end
end

local function flyStep()
	if not S.Fly or not flyBV or not flyBG then return end
	local dir = Vector3.zero
	local cf = Camera.CFrame
	if UserInputService:GetFocusedTextBox() == nil then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
	end
	flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * S.FlySpeed
	flyBG.CFrame = cf
end

local function noclipStep()
	if not S.Noclip then return end
	local c = chr()
	if not c then return end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end

local function charStep()
	local h = hum()
	if not h then return end
	if S.SpeedOn and h.WalkSpeed ~= S.SpeedValue then h.WalkSpeed = S.SpeedValue end
	if S.JumpOn then
		if h.UseJumpPower then
			if h.JumpPower ~= S.JumpValue then h.JumpPower = S.JumpValue end
		elseif h.JumpHeight ~= S.JumpValue then
			h.JumpHeight = S.JumpValue
		end
	end
	if S.HipHeight > 0 and h.HipHeight ~= S.HipHeight then h.HipHeight = S.HipHeight end
	local r = root()
	if r then
		if S.Freeze and not r.Anchored then r.Anchored = true
		elseif not S.Freeze and r.Anchored then r.Anchored = false end
		if S.Spin then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(S.SpinSpeed), 0) end
		if S.AntiVoid and r.Position.Y < S.VoidY then
			local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			r.CFrame = CFrame.new((sp and sp.Position or Vector3.new(0, 20, 0)) + Vector3.new(0, 6, 0))
			notify("Anti-void", "vocÃª foi trazido de volta", 2, "warn")
		end
	end
end

local function teleport(pos)
	local r = root()
	if not r then notify("Teleporte", "sem personagem", 2, "warn") return end
	r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

local function tpToPlayer(name)
	local p = Players:FindFirstChild(name or "")
	if not p or not p.Character then notify("Teleporte", "jogador sem personagem", 3, "warn") return end
	local r = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
	if r then teleport(r.Position + Vector3.new(2, 0, 2)) notify("Teleporte", "-> " .. name, 2, "good") end
end

local function applyLighting()
	if S.Fullbright then
		Lighting.Brightness = S.Brightness
		Lighting.Ambient = S.AmbientColor
		Lighting.OutdoorAmbient = S.AmbientColor
	else
		Lighting.Brightness = ORIG.Brightness
		Lighting.Ambient = ORIG.Ambient
		Lighting.OutdoorAmbient = ORIG.OutdoorAmbient
	end
	if S.NoFog then
		Lighting.FogEnd = 1e6
		Lighting.FogStart = 1e6
	else
		Lighting.FogEnd = ORIG.FogEnd
		Lighting.FogStart = ORIG.FogStart
	end
	Lighting.GlobalShadows = (not S.NoShadows) and ORIG.GlobalShadows or false
	Lighting.ClockTime = S.ClockTimeOn and S.ClockTime or ORIG.ClockTime
	CC.Enabled = S.Saturation ~= 0 or S.Contrast ~= 0 or S.TintOn
	CC.Saturation = S.Saturation
	CC.Contrast = S.Contrast
	CC.TintColor = S.TintOn and S.Tint or Color3.new(1, 1, 1)
end

local removed = {}
local function lowGFX(on)
	if on then
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("Decal") or o:IsA("Texture") then
				table.insert(removed, { obj = o, parent = o.Parent })
				o.Parent = nil
			elseif o:IsA("BasePart") then
				o.Material = Enum.Material.SmoothPlastic
				o.Reflectance = 0
			end
		end
		notify("Low GFX", #removed .. " texturas removidas", 3, "good")
	else
		for _, r in ipairs(removed) do
			if r.obj then pcall(function() r.obj.Parent = r.parent end) end
		end
		removed = {}
	end
end

local function noParticles(on)
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire")
			or o:IsA("Sparkles") or o:IsA("Beam") then
			o.Enabled = not on
		end
	end
end

local function hideChar(on)
	local c = chr()
	if not c then return end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.LocalTransparencyModifier = on and 1 or 0
		elseif p:IsA("Decal") then p.Transparency = on and 1 or 0 end
	end
end

local function hideNames(on)
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h then
			h.DisplayDistanceType = on and Enum.HumanoidDisplayDistanceType.None
				or Enum.HumanoidDisplayDistanceType.Viewer
		end
	end
end

local CrossHolder = new("Frame", { Size = UDim2.fromOffset(60, 60), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = OverlayGui })
local crossParts = {}
for n = 1, 4 do
	crossParts[n] = new("Frame", { BackgroundColor3 = T.Accent, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Parent = CrossHolder })
end
crossParts[5] = new("Frame", { Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = CrossHolder })
local function applyCrosshair()
	CrossHolder.Visible = S.Crosshair
	local L, gap = S.CrosshairSize, 4
	local dirs = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
	for n = 1, 4 do
		local d = dirs[n]
		local vert = d[1] == 0
		crossParts[n].Size = vert and UDim2.fromOffset(2, L) or UDim2.fromOffset(L, 2)
		crossParts[n].Position = UDim2.new(0.5, d[1] * (gap + L * 0.5), 0.5, d[2] * (gap + L * 0.5))
		crossParts[n].BackgroundColor3 = S.CrosshairColor
	end
	crossParts[5].BackgroundColor3 = S.CrosshairColor
end

local fcCF
local function setFreecam(on)
	S.Freecam = on
	if on then
		fcCF = Camera.CFrame
		Camera.CameraType = Enum.CameraType.Scriptable
		notify("Freecam", "WASD + EspaÃ§o/Ctrl Â· Q/E gira", 4, "good")
	else
		Camera.CameraType = Enum.CameraType.Custom
		if chr() then Camera.CameraSubject = hum() or chr() end
	end
end

local function freecamStep(dt)
	if not S.Freecam or not fcCF then return end
	local move, rot = Vector3.zero, 0
	if UserInputService:GetFocusedTextBox() == nil then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move += Vector3.new(0, -1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then rot += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then rot -= 1 end
	end
	fcCF = fcCF * CFrame.Angles(0, math.rad(rot * 90 * dt), 0)
	fcCF = fcCF + fcCF:VectorToWorldSpace(move * S.FreecamSpeed * dt)
	Camera.CFrame = fcCF
end

local spectating = nil
local function spectate(name)
	if not name or name == "" or spectating == name then
		spectating = nil
		if chr() then Camera.CameraSubject = hum() or chr() end
		notify("Espectar", "voltou pra vocÃª", 2)
		return
	end
	local p = Players:FindFirstChild(name)
	if p and p.Character then
		spectating = name
		Camera.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid") or p.Character
		notify("Espectando", name, 3, "good")
	else
		notify("Espectar", "jogador sem personagem", 3, "warn")
	end
end

local vim, vu
pcall(function() vim = game:GetService("VirtualInputManager") end)
pcall(function() vu = game:GetService("VirtualUser") end)

task.spawn(function()
	while task.wait(1 / math.max(S.CPS, 1)) do
		if S.AutoClick then
			local done = false
			if typeof(mouse1click) == "function" then done = pcall(mouse1click) end
			if not done and vim then
				pcall(function()
					local m = UserInputService:GetMouseLocation()
					vim:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 1)
					vim:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 1)
				end)
			end
		end
	end
end)

--==============================================================================
-- 09 Â· INTERFACE (construÃ­da dentro de guarda de erro)
--==============================================================================

local UI = {}

local function build()
	local playerNames = {}
	local function refreshPlayers()
		playerNames = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
		end
		for _, id in ipairs({ "tpTarget", "spectateTarget", "focusTarget" }) do
			local api = Lib.Refreshers[id]
			if api then api.SetOptions(playerNames, true) end
		end
	end
	UI.refreshPlayers = refreshPlayers

	----------------------------------------------------------------- ESP -------
	local TabESP = Lib:Tab("ESP", "Players, NPCs e objetos atravÃ©s de paredes")

	local sMain = TabESP:Section("Principal", 1)
	sMain:Toggle({ text = "ESP ativado (master)", flag = "ESP_Master", callback = function(v)
		if v then ESP:Refresh() end
		notify("ESP", v and "ligado" or "desligado", 2, v and "good" or nil)
	end })
	sMain:Toggle({ text = "Players", flag = "ESP_Players", callback = function() ESP:Refresh() end })
	sMain:Toggle({ text = "NPCs (humanoides sem player)", flag = "ESP_NPCs", callback = function() ESP:Refresh() end })
	sMain:Toggle({ text = "Objetos / itens", flag = "ESP_Objects", callback = function() ESP:Refresh() end })
	sMain:Toggle({ text = "Mostrar vocÃª mesmo", flag = "ESP_ShowSelf", callback = function() ESP:Refresh() end })
	sMain:Toggle({ text = "SÃ³ alvos vivos", flag = "ESP_AliveOnly" })
	sMain:Toggle({ text = "Ignorar meu time", flag = "ESP_TeamCheck", callback = function() ESP:Refresh() end })
	sMain:Toggle({ text = "Usar cor do time", flag = "ESP_TeamColor" })
	sMain:Slider({ text = "DistÃ¢ncia mÃ¡xima", flag = "ESP_MaxDistance", min = 50, max = 5000, suffix = "m" })
	sMain:Slider({ text = "Atualizar alvos a cada", flag = "ESP_Refresh", min = 0.2, max = 5, decimals = 1, suffix = "s" })

	local sVis = TabESP:Section("Elementos visuais", 1)
	sVis:Toggle({ text = "Caixa", flag = "ESP_Box" })
	sVis:Dropdown({ text = "Tipo de caixa", flag = "ESP_BoxType", options = { "Cantos", "Completa", "3D" } })
	sVis:Toggle({ text = "Preencher caixa", flag = "ESP_BoxFill" })
	sVis:Slider({ text = "Opacidade do preenchimento", flag = "ESP_FillOpacity", min = 0, max = 1, decimals = 2 })
	sVis:Toggle({ text = "Nome", flag = "ESP_Name" })
	sVis:Toggle({ text = "DistÃ¢ncia", flag = "ESP_Distance" })
	sVis:Toggle({ text = "Barra de vida", flag = "ESP_HealthBar" })
	sVis:Toggle({ text = "Vida em texto", flag = "ESP_HealthText" })
	sVis:Toggle({ text = "Esqueleto", flag = "ESP_Skeleton" })
	sVis:Toggle({ text = "Ponto na cabeÃ§a", flag = "ESP_HeadDot" })
	sVis:Toggle({ text = "Linha de visÃ£o do alvo", flag = "ESP_LookVector" })
	sVis:Toggle({ text = "Tracers", flag = "ESP_Tracer" })
	sVis:Dropdown({ text = "Origem do tracer", flag = "ESP_TracerFrom",
		options = { "Base da tela", "Centro", "Topo", "Mouse" } })
	sVis:Toggle({ text = "Chams (corpo preenchido)", flag = "ESP_Chams" })
	sVis:Slider({ text = "Opacidade do chams", flag = "ESP_ChamsOpacity", min = 0, max = 1, decimals = 2 })
	sVis:Toggle({ text = "Chams atravessa parede", flag = "ESP_ChamsThrough" })
	sVis:Toggle({ text = "Contorno do corpo", flag = "ESP_Outline" })
	sVis:Toggle({ text = "Setas fora da tela", flag = "ESP_Arrows" })
	sVis:Toggle({ text = "Checar linha de visÃ£o (cor)", flag = "ESP_VisibilityCheck" })
	sVis:Toggle({ text = "Modo arco-Ã­ris", flag = "ESP_Rainbow" })

	local sStat = TabESP:Section("Status dos players", 2)
	sStat:Label("Cada item liga uma linha de info ao lado do alvo.")
	sStat:Toggle({ text = "Vida atual", flag = "ST_Health" })
	sStat:Toggle({ text = "Vida mÃ¡xima", flag = "ST_MaxHealth" })
	sStat:Toggle({ text = "WalkSpeed", flag = "ST_WalkSpeed" })
	sStat:Toggle({ text = "JumpPower / JumpHeight", flag = "ST_JumpPower" })
	sStat:Toggle({ text = "Estado do humanoide", flag = "ST_State" })
	sStat:Toggle({ text = "Sentado", flag = "ST_Sitting" })
	sStat:Toggle({ text = "Ferramenta equipada", flag = "ST_Tool" })
	sStat:Toggle({ text = "Time", flag = "ST_Team" })
	sStat:Toggle({ text = "Display name", flag = "ST_Display" })
	sStat:Toggle({ text = "UserId", flag = "ST_UserId" })
	sStat:Toggle({ text = "Idade da conta", flag = "ST_AccountAge" })
	sStat:Toggle({ text = "Leaderstats (todos)", flag = "ST_Leaderstats" })
	sStat:Toggle({ text = "Attributes do modelo", flag = "ST_Attributes" })
	sStat:Toggle({ text = "Velocidade", flag = "ST_Velocity" })
	sStat:Toggle({ text = "PosiÃ§Ã£o XYZ", flag = "ST_Position" })

	local sObj = TabESP:Section("ESP de objetos", 2)
	sObj:Dropdown({ text = "Classes", flag = "OBJ_Classes", multi = true,
		callback = function() ESP:Refresh() end,
		options = { "Tool", "Part", "MeshPart", "Model", "SpawnLocation", "ProximityPrompt",
			"ClickDetector", "VehicleSeat", "Seat", "Sound", "Attachment" } })
	sObj:TextBox({ text = "Palavras-chave (vÃ­rgula)", flag = "OBJ_Keywords",
		placeholder = "chest, ore, key, door", callback = function() ESP:Refresh() end })
	sObj:Toggle({ text = "Mostrar ponto no objeto", flag = "OBJ_Dot" })
	sObj:Slider({ text = "Limite de objetos", flag = "OBJ_Limit", min = 20, max = 1000 })
	sObj:Button({ text = "Recarregar alvos agora", callback = function()
		ESP:Refresh()
		notify("ESP", #ESP.Targets .. " alvos encontrados", 2, "good")
	end })

	local sCol = TabESP:Section("Cores e tipografia", 2)
	sCol:ColorPicker({ text = "VisÃ­vel", flag = "C_Visible" })
	sCol:ColorPicker({ text = "AtrÃ¡s de parede", flag = "C_Hidden" })
	sCol:ColorPicker({ text = "NPCs", flag = "C_NPC" })
	sCol:ColorPicker({ text = "Objetos", flag = "C_Object" })
	sCol:ColorPicker({ text = "Textos", flag = "C_Text" })
	sCol:Slider({ text = "Tamanho do texto", flag = "ESP_TextSize", min = 8, max = 24 })
	sCol:Slider({ text = "Espessura das linhas", flag = "ESP_Thickness", min = 1, max = 5 })
	sCol:Dropdown({ text = "Fonte", flag = "ESP_Font",
		options = { "Gotham", "GothamMedium", "GothamBold", "GothamBlack", "Code",
			"SourceSans", "SourceSansBold", "Fantasy", "Arcade" } })

	------------------------------------------------------------ MOVIMENTO ------
	local TabMove = Lib:Tab("Movimento", "Voo, velocidade, noclip e teleportes")

	local sMv = TabMove:Section("LocomoÃ§Ã£o", 1)
	sMv:Toggle({ text = "Voar", flag = "Fly", callback = setFly })
	sMv:Slider({ text = "Velocidade do voo", flag = "FlySpeed", min = 10, max = 500 })
	sMv:Toggle({ text = "Velocidade customizada", flag = "SpeedOn", callback = function(v)
		if not v then local h = hum() if h then h.WalkSpeed = 16 end end
	end })
	sMv:Slider({ text = "WalkSpeed", flag = "SpeedValue", min = 8, max = 500 })
	sMv:Toggle({ text = "Pulo customizado", flag = "JumpOn", callback = function(v)
		if not v then
			local h = hum()
			if h then
				if h.UseJumpPower then h.JumpPower = 50 else h.JumpHeight = 7.2 end
			end
		end
	end })
	sMv:Slider({ text = "ForÃ§a do pulo", flag = "JumpValue", min = 10, max = 500 })
	sMv:Toggle({ text = "Pulo infinito", flag = "InfJump" })
	sMv:Toggle({ text = "Noclip (atravessar paredes)", flag = "Noclip", callback = function(v)
		if not v then
			local c = chr()
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
				end
			end
		end
	end })
	sMv:Toggle({ text = "Congelar personagem", flag = "Freeze" })
	sMv:Toggle({ text = "Girar (spin)", flag = "Spin" })
	sMv:Slider({ text = "Velocidade do spin", flag = "SpinSpeed", min = 1, max = 40 })
	sMv:Slider({ text = "Altura do corpo (HipHeight)", flag = "HipHeight", min = 0, max = 20, decimals = 1 })

	local sTp = TabMove:Section("Teleporte", 2)
	sTp:Toggle({ text = "Teleporte no clique", flag = "ClickTP", callback = function(v)
		if v then notify("Click TP", "aponte e aperte " .. S.KB_ClickTP, 3, "good") end
	end })
	local ddTp = sTp:Dropdown({ text = "Ir atÃ© o player", id = "tpTarget", options = playerNames })
	sTp:Button({ text = "Teleportar", callback = function()
		local n = ddTp.Get()
		if n then tpToPlayer(n) else notify("Teleporte", "escolha um player", 2, "warn") end
	end })
	sTp:Toggle({ text = "Anti-void (volta se cair)", flag = "AntiVoid" })
	sTp:Slider({ text = "Altura limite do void", flag = "VoidY", min = -600, max = 0 })

	local sWp = TabMove:Section("Waypoints", 2)
	local wpName = sWp:TextBox({ text = "Nome do waypoint", placeholder = "base, loja, spawn..." })
	local ddWp
	local function wpNames()
		local t = {}
		for _, w in ipairs(S.Waypoints) do table.insert(t, w.name) end
		return t
	end
	sWp:Button({ text = "Salvar posiÃ§Ã£o atual", callback = function()
		local r = root()
		if not r then notify("Waypoint", "sem personagem", 2, "warn") return end
		local n = wpName.Get()
		if n == "" then n = "wp" .. (#S.Waypoints + 1) end
		table.insert(S.Waypoints, { name = n, x = r.Position.X, y = r.Position.Y, z = r.Position.Z })
		ddWp.SetOptions(wpNames(), true)
		notify("Waypoint salvo", n, 2, "good")
	end })
	ddWp = sWp:Dropdown({ text = "Waypoints salvos", options = wpNames() })
	sWp:Button({ text = "Ir para o waypoint", callback = function()
		local n = ddWp.Get()
		for _, w in ipairs(S.Waypoints) do
			if w.name == n then teleport(Vector3.new(w.x, w.y, w.z)) notify("Teleporte", n, 2, "good") return end
		end
		notify("Waypoint", "escolha um waypoint", 2, "warn")
	end })
	sWp:Button({ text = "Apagar waypoint selecionado", danger = true, callback = function()
		local n = ddWp.Get()
		for idx, w in ipairs(S.Waypoints) do
			if w.name == n then table.remove(S.Waypoints, idx) break end
		end
		ddWp.SetOptions(wpNames())
		notify("Waypoint", "removido", 2)
	end })

	--------------------------------------------------------------- VISUAL ------
	local TabVis = Lib:Tab("Visual", "IluminaÃ§Ã£o, cÃ¢mera e limpeza grÃ¡fica")

	local sLight = TabVis:Section("IluminaÃ§Ã£o", 1)
	sLight:Toggle({ text = "Fullbright", flag = "Fullbright", callback = applyLighting })
	sLight:Slider({ text = "Brilho", flag = "Brightness", min = 0, max = 10, decimals = 1, callback = applyLighting })
	sLight:ColorPicker({ text = "Cor ambiente", flag = "AmbientColor", callback = applyLighting })
	sLight:Toggle({ text = "Sem neblina", flag = "NoFog", callback = applyLighting })
	sLight:Toggle({ text = "Sem sombras", flag = "NoShadows", callback = applyLighting })
	sLight:Toggle({ text = "Travar horÃ¡rio", flag = "ClockTimeOn", callback = applyLighting })
	sLight:Slider({ text = "HorÃ¡rio", flag = "ClockTime", min = 0, max = 24, decimals = 1, callback = applyLighting })
	sLight:Slider({ text = "SaturaÃ§Ã£o", flag = "Saturation", min = -1, max = 3, decimals = 2, callback = applyLighting })
	sLight:Slider({ text = "Contraste", flag = "Contrast", min = -1, max = 2, decimals = 2, callback = applyLighting })
	sLight:Toggle({ text = "Tint colorido", flag = "TintOn", callback = applyLighting })
	sLight:ColorPicker({ text = "Cor do tint", flag = "Tint", callback = applyLighting })

	local sCam = TabVis:Section("CÃ¢mera", 2)
	sCam:Toggle({ text = "FOV customizado", flag = "FOVOn", callback = function(v)
		Camera.FieldOfView = v and S.FOV or ORIG.FOV
	end })
	sCam:Slider({ text = "FOV", flag = "FOV", min = 20, max = 120, callback = function(v)
		if S.FOVOn then Camera.FieldOfView = v end
	end })
	sCam:Toggle({ text = "Liberar zoom (3Âª pessoa)", flag = "ZoomOn", callback = function(v)
		LocalPlayer.CameraMaxZoomDistance = v and S.ZoomMax or ORIG.ZoomMax
	end })
	sCam:Slider({ text = "Zoom mÃ¡ximo", flag = "ZoomMax", min = 20, max = 2000, callback = function(v)
		if S.ZoomOn then LocalPlayer.CameraMaxZoomDistance = v end
	end })
	sCam:Toggle({ text = "Freecam", flag = "Freecam", callback = setFreecam })
	sCam:Slider({ text = "Velocidade do freecam", flag = "FreecamSpeed", min = 10, max = 400 })
	sCam:Toggle({ text = "Crosshair", flag = "Crosshair", callback = applyCrosshair })
	sCam:Slider({ text = "Tamanho do crosshair", flag = "CrosshairSize", min = 2, max = 40, callback = applyCrosshair })
	sCam:ColorPicker({ text = "Cor do crosshair", flag = "CrosshairColor", callback = applyCrosshair })

	local sClean = TabVis:Section("Performance e limpeza", 2)
	sClean:Toggle({ text = "Low GFX (remove texturas)", flag = "LowGFX", callback = lowGFX })
	sClean:Toggle({ text = "Sem partÃ­culas / efeitos", flag = "NoParticles", callback = noParticles })
	sClean:Toggle({ text = "Esconder meu personagem", flag = "HideChar", callback = hideChar })
	sClean:Toggle({ text = "Esconder nomes acima da cabeÃ§a", flag = "HideNames", callback = hideNames })

	---------------------------------------------------------------- MUNDO ------
	local TabWorld = Lib:Tab("Mundo", "FÃ­sica, explorador de instÃ¢ncias e remotes")

	local sPhys = TabWorld:Section("FÃ­sica", 1)
	sPhys:Toggle({ text = "Gravidade customizada", flag = "GravityOn", callback = function(v)
		Workspace.Gravity = v and S.Gravity or ORIG.Gravity
	end })
	sPhys:Slider({ text = "Gravidade", flag = "Gravity", min = 0, max = 400, decimals = 1, callback = function(v)
		if S.GravityOn then Workspace.Gravity = v end
	end })
	sPhys:Button({ text = "Restaurar gravidade original", callback = function()
		Workspace.Gravity = ORIG.Gravity
		notify("Gravidade", "restaurada", 2, "good")
	end })

	local sSrv = TabWorld:Section("Servidor", 1)
	sSrv:Label(string.format("PlaceId: %d\nJobId: %s", i(game.PlaceId), tostring(game.JobId)))
	UI.upLbl = sSrv:Label("Uptime: 0s")
	sSrv:Button({ text = "Copiar JobId", callback = function()
		notify("JobId", clip(tostring(game.JobId)) and "copiado" or "clipboard indisponÃ­vel", 2)
	end })
	sSrv:Button({ text = "Reentrar no servidor", danger = true, callback = function()
		notify("Rejoin", "reentrando...", 3, "warn")
		pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
	end })
	sSrv:Toggle({ text = "Anti-AFK", flag = "AntiAFK", callback = function(v)
		notify("Anti-AFK", v and "ativo" or "desativado", 2, v and "good" or nil)
	end })
	sSrv:Toggle({ text = "Auto-click", flag = "AutoClick" })
	sSrv:Slider({ text = "Cliques por segundo", flag = "CPS", min = 1, max = 25 })

	local sExp = TabWorld:Section("Explorador de instÃ¢ncias", 2)
	local expPath = sExp:Label("Workspace", T.Accent)
	local expConsole = sExp:Console(190)
	local expCurrent = Workspace
	local function drawExplorer()
		expConsole.Clear()
		expPath.Set(expCurrent:GetFullName())
		if expCurrent ~= game then
			expConsole.Add("[..] voltar", T.Accent, function()
				expCurrent = expCurrent.Parent or game
				drawExplorer()
			end)
		end
		local kids = expCurrent:GetChildren()
		if #kids == 0 then expConsole.Add("(vazio)", T.Dim) end
		for idx, c in ipairs(kids) do
			if idx > 120 then expConsole.Add("... +" .. (#kids - 120) .. " itens", T.Dim) break end
			local col = c:IsA("BasePart") and T.Good or c:IsA("Model") and T.Warn or T.Sub
			expConsole.Add(c.Name .. "  Â·  " .. c.ClassName, col, function()
				expCurrent = c
				drawExplorer()
			end)
		end
	end
	UI.drawExplorer = drawExplorer
	sExp:Button({ text = "Voltar pro Workspace", callback = function()
		expCurrent = Workspace
		drawExplorer()
	end })
	sExp:Button({ text = "Copiar caminho atual", callback = function()
		notify("Explorer", clip(expCurrent:GetFullName()) and "caminho copiado" or "clipboard indisponÃ­vel", 2)
	end })
	sExp:Button({ text = "Teleportar atÃ© (se for parte)", callback = function()
		local p = expCurrent:IsA("BasePart") and expCurrent or expCurrent:FindFirstChildWhichIsA("BasePart")
		if p then teleport(p.Position) notify("Teleporte", "-> " .. expCurrent.Name, 2, "good")
		else notify("Explorer", "nada com posiÃ§Ã£o aqui", 2, "warn") end
	end })

	local sRem = TabWorld:Section("Remotes", 2)
	local remConsole = sRem:Console(150)
	local remSelected = nil
	sRem:Button({ text = "Listar remotes do jogo", callback = function()
		remConsole.Clear()
		local n = 0
		for _, o in ipairs(game:GetDescendants()) do
			if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
				n += 1
				if n > 150 then break end
				local ref = o
				remConsole.Add((o:IsA("RemoteEvent") and "EVT" or "FUN") .. " Â· " .. o:GetFullName(),
					o:IsA("RemoteEvent") and T.Good or T.Warn, function()
						remSelected = ref
						notify("Remote selecionado", ref.Name, 2, "good")
					end)
			end
		end
		if n == 0 then remConsole.Add("nenhum remote encontrado", T.Dim) end
		notify("Remotes", n .. " encontrados", 2)
	end })
	local remArgs = sRem:TextBox({ text = "Argumentos (vÃ­rgula)", placeholder = "1, true, texto" })
	sRem:Button({ text = "Disparar remote selecionado", danger = true, callback = function()
		if not remSelected then notify("Remotes", "selecione um remote na lista", 3, "warn") return end
		local args = {}
		for a in string.gmatch(remArgs.Get(), "[^,]+") do
			a = string.match(a, "^%s*(.-)%s*$")
			if a == "true" then table.insert(args, true)
			elseif a == "false" then table.insert(args, false)
			elseif tonumber(a) then table.insert(args, tonumber(a))
			elseif a and a ~= "" then table.insert(args, a) end
		end
		local ok, err = pcall(function()
			if remSelected:IsA("RemoteEvent") then
				remSelected:FireServer(table.unpack(args))
			else
				notify("Retorno", tostring(remSelected:InvokeServer(table.unpack(args))), 4, "good")
			end
		end)
		notify(ok and "Remote disparado" or "Falhou", ok and remSelected.Name or tostring(err), 4, ok and "good" or "bad")
	end })

	-------------------------------------------------------------- PLAYERS ------
	local TabPl = Lib:Tab("Players", "Lista, inspeÃ§Ã£o, espectar e logs")

	local sList = TabPl:Section("Lista de players", 1)
	local plConsole = sList:Console(200)
	local function drawPlayers()
		plConsole.Clear()
		local r = root()
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local pr = c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
			local dist = (r and pr) and (i((r.Position - pr.Position).Magnitude) .. "m") or "-"
			local line = string.format("%s%s  Â·  %s hp  Â·  %s", p.Name,
				p == LocalPlayer and " (vocÃª)" or "", h and tostring(i(h.Health)) or "?", dist)
			local col = p == LocalPlayer and T.Accent or ((h and h.Health > 0) and T.Sub or T.Dim)
			plConsole.Add(line, col, function()
				notify(p.Name, string.format("id %d Â· %d dias Â· time %s", i(p.UserId), i(p.AccountAge),
					p.Team and p.Team.Name or "none"), 5, "good")
				clip(tostring(p.UserId))
			end)
		end
	end
	UI.drawPlayers = drawPlayers
	sList:Button({ text = "Atualizar lista", callback = drawPlayers })
	sList:Label("Clique num player pra ver detalhes e copiar o UserId.")

	local sAct = TabPl:Section("AÃ§Ãµes", 2)
	local ddSpec = sAct:Dropdown({ text = "Espectar", id = "spectateTarget", options = playerNames })
	sAct:Button({ text = "Espectar / parar", callback = function() spectate(ddSpec.Get()) end })
	local ddFocus = sAct:Dropdown({ text = "Focar ESP em 1 player", id = "focusTarget", options = playerNames })
	sAct:Button({ text = "Aplicar foco", callback = function()
		ESP.Focus = ddFocus.Get()
		ESP:Refresh()
		notify("ESP", "focando " .. tostring(ESP.Focus), 3, "good")
	end })
	sAct:Button({ text = "Limpar foco", callback = function()
		ESP.Focus = nil
		ESP:Refresh()
		notify("ESP", "foco limpo", 2)
	end })
	sAct:Button({ text = "Copiar link do perfil", callback = function()
		local n = ddFocus.Get() or ddSpec.Get()
		local p = n and Players:FindFirstChild(n)
		if p then
			clip("https://www.roblox.com/users/" .. p.UserId .. "/profile")
			notify("Perfil", "link copiado", 2, "good")
		else
			notify("Perfil", "escolha um player", 2, "warn")
		end
	end })

	local sLog = TabPl:Section("Logs", 2)
	local logConsole = sLog:Console(180)
	UI.logConsole = logConsole
	sLog:Button({ text = "Limpar log", callback = function() logConsole.Clear() end })

	---------------------------------------------------------- UTILITÃRIOS ------
	local TabUtil = Lib:Tab("UtilitÃ¡rios", "Atalhos, aparÃªncia e configuraÃ§Ãµes")

	local sKeys = TabUtil:Section("Atalhos", 1)
	sKeys:Keybind({ text = "Abrir / fechar painel", flag = "KB_Panel" })
	sKeys:Keybind({ text = "ESP master", flag = "KB_ESP" })
	sKeys:Keybind({ text = "Voar", flag = "KB_Fly" })
	sKeys:Keybind({ text = "Noclip", flag = "KB_Noclip" })
	sKeys:Keybind({ text = "Teleporte no clique", flag = "KB_ClickTP" })
	sKeys:Keybind({ text = "Crosshair", flag = "KB_Crosshair" })
	sKeys:Keybind({ text = "PANIC (encerrar tudo)", flag = "KB_Panic" })

	local sUI = TabUtil:Section("AparÃªncia do painel", 1)
	sUI:Slider({ text = "Escala da interface", flag = "UIScale", min = 0.6, max = 1.6, decimals = 2,
		callback = function(v) WinScale.Scale = v end })
	sUI:Slider({ text = "TransparÃªncia", flag = "UITransparency", min = 0, max = 0.6, decimals = 2,
		callback = function(v) Win.BackgroundTransparency = v Side.BackgroundTransparency = v end })
	sUI:Toggle({ text = "HUD de performance", flag = "HUD", callback = function(v)
		if UI.HUD then UI.HUD.Visible = v end
	end })

	local sCfg = TabUtil:Section("ConfiguraÃ§Ã£o", 2)
	local function serialize()
		local out = {}
		for k, v in pairs(S) do
			if typeof(v) == "Color3" then out[k] = { __c3 = true, r = v.R, g = v.G, b = v.B }
			else out[k] = v end
		end
		return HttpService:JSONEncode(out)
	end
	local function deserialize(json)
		local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
		if not ok or type(data) ~= "table" then return false end
		for k, v in pairs(data) do
			if S[k] ~= nil then
				if type(v) == "table" and v.__c3 then v = Color3.new(v.r, v.g, v.b) end
				S[k] = v
				if Lib.Flags[k] then pcall(Lib.Flags[k], v) end
			end
		end
		applyLighting(); applyCrosshair(); ESP:Refresh()
		return true
	end

	sCfg:Button({ text = "Salvar configuraÃ§Ã£o", callback = function()
		local json = serialize()
		local saved = false
		if typeof(writefile) == "function" then saved = pcall(writefile, "nexus_admin_config.json", json) end
		if saved then notify("Config", "salvo em nexus_admin_config.json", 3, "good")
		elseif clip(json) then notify("Config", "JSON copiado pro clipboard", 3, "good")
		else notify("Config", "sem arquivo/clipboard, use o campo abaixo", 4, "warn") end
	end })
	sCfg:Button({ text = "Carregar configuraÃ§Ã£o salva", callback = function()
		if typeof(readfile) == "function" then
			local ok, json = pcall(readfile, "nexus_admin_config.json")
			if ok and json and deserialize(json) then notify("Config", "carregada", 3, "good") return end
		end
		notify("Config", "nada em arquivo, cole o JSON abaixo", 4, "warn")
	end })
	local cfgBox = sCfg:TextBox({ text = "Colar / ver JSON", placeholder = "{...}" })
	sCfg:Button({ text = "Aplicar JSON do campo", callback = function()
		if deserialize(cfgBox.Get()) then notify("Config", "aplicada", 3, "good")
		else notify("Config", "JSON invÃ¡lido", 3, "bad") end
	end })
	sCfg:Button({ text = "Exportar para o campo", callback = function() cfgBox.Set(serialize()) end })
	sCfg:Button({ text = "Resetar tudo", danger = true, callback = function()
		for k, v in pairs(DEFAULTS) do
			S[k] = v
			if Lib.Flags[k] then pcall(Lib.Flags[k], v) end
		end
		applyLighting(); applyCrosshair(); ESP:Refresh()
		notify("Config", "tudo resetado", 3, "warn")
	end })

	local sHelp = TabUtil:Section("Sobre", 2)
	sHelp:Label("Nexus Admin Suite v" .. VERSION ..
		"\n\nTudo roda no cliente. Nada vai pro servidor, exceto se vocÃª usar o disparador de remotes." ..
		"\n\nESP: 28 opÃ§Ãµes + 15 linhas de status.\nExtras: 40+ funcionalidades.")
	sHelp:Divider()
	sHelp:Label("ESP de objetos usa classe OU palavra-chave. Ex: 'chest' acha qualquer coisa com chest no nome.", T.Dim)
	sHelp:Button({ text = "NotificaÃ§Ã£o de teste", callback = function()
		notify("Funcionando", "se vocÃª viu isso, tÃ¡ tudo certo", 3, "good")
	end })
	sHelp:Button({ text = "PANIC Â· encerrar e restaurar", danger = true, callback = function()
		Lib.Destroy()
	end })

	refreshPlayers()
	drawPlayers()
	drawExplorer()
end

local okBuild, errBuild = pcall(build)
if not okBuild then
	warn("[NEXUS] falha ao montar a interface: " .. tostring(errBuild))
	coreNotify("Nexus Admin Â· ERRO", tostring(errBuild), 12)
	local err = new("Frame", { Size = UDim2.fromOffset(520, 130), Position = UDim2.new(0.5, -260, 0, 60),
		BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = OverlayGui })
	corner(12, err); stroke(T.Bad, 1, err); padding(14, 16, 14, 16, err)
	label(err, "Nexus: erro ao montar a interface", { Size = UDim2.new(1, 0, 0, 18), Font = T.FontB,
		TextSize = 14, TextColor3 = T.Bad })
	label(err, tostring(errBuild), { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 1, -26),
		TextSize = 11.5, TextColor3 = T.Sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
end

--==============================================================================
-- 10 Â· HUD, INPUT, LOOPS, INIT
--==============================================================================

local HUD = new("Frame", { Size = UDim2.fromOffset(168, 92), Position = UDim2.fromOffset(18, 60),
	BackgroundColor3 = T.Bg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
	Visible = false, Parent = OverlayGui })
UI.HUD = HUD
corner(10, HUD); stroke(T.Stroke, 1, HUD); padding(8, 10, 8, 10, HUD)
vlist(2, HUD)
local hudLines = {}
for n = 1, 5 do
	hudLines[n] = new("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1,
		Font = Enum.Font.Code, TextSize = 11.5, TextColor3 = n == 1 and T.Accent or T.Sub,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "", LayoutOrder = n, Parent = HUD })
end
do
	local dragging, startPos, startAbs
	HUD.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, startPos, startAbs = true, HUD.Position, inp.Position
		end
	end)
	bind(UserInputService.InputChanged, function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - startAbs
			HUD.Position = UDim2.new(0, startPos.X.Offset + d.X, 0, startPos.Y.Offset + d.Y)
		end
	end)
	bind(UserInputService.InputEnded, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

local uiOpen = false
local function setOpen(v)
	uiOpen = v
	if v then
		Win.Visible = true
		Win.BackgroundTransparency = 1
		WinScale.Scale = S.UIScale * 0.95
		tween(Win, 0.22, { BackgroundTransparency = S.UITransparency })
		tween(WinScale, 0.26, { Scale = S.UIScale })
	else
		tween(WinScale, 0.16, { Scale = S.UIScale * 0.96 })
		tween(Win, 0.16, { BackgroundTransparency = 1 })
		task.delay(0.18, function() if not uiOpen then Win.Visible = false end end)
	end
end
BtnClose.MouseButton1Click:Connect(function() setOpen(false) end)
BtnMin.MouseButton1Click:Connect(function() setOpen(false) end)

function Lib.Destroy()
	for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
	S.ESP_Master = false
	pcall(setFly, false)
	S.Noclip = false
	S.Freecam = false
	pcall(function()
		Camera.CameraType = Enum.CameraType.Custom
		Camera.FieldOfView = ORIG.FOV
		LocalPlayer.CameraMaxZoomDistance = ORIG.ZoomMax
		Workspace.Gravity = ORIG.Gravity
	end)
	S.Fullbright, S.NoFog, S.NoShadows, S.ClockTimeOn = false, false, false, false
	S.Saturation, S.Contrast, S.TintOn = 0, 0, false
	pcall(applyLighting)
	pcall(lowGFX, false)
	pcall(noParticles, false)
	pcall(hideChar, false)
	local h = hum()
	if h then h.WalkSpeed = 16 h.PlatformStand = false end
	local r = root()
	if r then r.Anchored = false end
	pcall(function() HLFolder:Destroy() end)
	pcall(function() CC:Destroy() end)
	task.delay(0.1, function()
		pcall(function() PanelGui:Destroy() end)
		pcall(function() EspGui:Destroy() end)
		pcall(function() OverlayGui:Destroy() end)
	end)
	coreNotify("Nexus Admin", "Encerrado e jogo restaurado.", 4)
end

bind(UserInputService.InputBegan, function(input, processed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local name = input.KeyCode.Name
	if capturing then
		local fn = capturing
		capturing = nil
		if name ~= "Unknown" then fn(name) end
		return
	end
	if processed or UserInputService:GetFocusedTextBox() then return end
	if name == S.KB_Panel then setOpen(not uiOpen)
	elseif name == S.KB_ESP then
		if Lib.Flags.ESP_Master then Lib.Flags.ESP_Master(not S.ESP_Master) else S.ESP_Master = not S.ESP_Master end
	elseif name == S.KB_Fly then
		if Lib.Flags.Fly then Lib.Flags.Fly(not S.Fly) else setFly(not S.Fly) end
	elseif name == S.KB_Noclip then
		if Lib.Flags.Noclip then Lib.Flags.Noclip(not S.Noclip) else S.Noclip = not S.Noclip end
	elseif name == S.KB_Crosshair then
		if Lib.Flags.Crosshair then Lib.Flags.Crosshair(not S.Crosshair) end
	elseif name == S.KB_ClickTP then
		if S.ClickTP and Mouse.Hit then teleport(Mouse.Hit.Position) end
	elseif name == S.KB_Panic then
		Lib.Destroy()
	end
end)

bind(UserInputService.JumpRequest, function()
	if S.InfJump then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

bind(LocalPlayer.Idled, function()
	if S.AntiAFK and vu then
		pcall(function()
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end
end)

bind(LocalPlayer.CharacterAdded, function()
	task.wait(0.6)
	if S.Fly then setFly(true) end
	if S.HideChar then hideChar(true) end
	if S.HideNames then hideNames(true) end
	ESP:Refresh()
end)

local function hookChat(p)
	bind(p.Chatted, function(msg)
		if UI.logConsole then UI.logConsole.Add("[" .. os.date("%H:%M") .. "] " .. p.Name .. ": " .. msg, T.Sub) end
	end)
end
for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
bind(Players.PlayerAdded, function(p)
	hookChat(p)
	if UI.logConsole then UI.logConsole.Add("[+] " .. p.Name .. " entrou", T.Good) end
	if UI.refreshPlayers then UI.refreshPlayers() end
	if UI.drawPlayers then UI.drawPlayers() end
end)
bind(Players.PlayerRemoving, function(p)
	if UI.logConsole then UI.logConsole.Add("[-] " .. p.Name .. " saiu", T.Bad) end
	task.defer(function()
		if UI.refreshPlayers then UI.refreshPlayers() end
		if UI.drawPlayers then UI.drawPlayers() end
	end)
end)

local loopErrors = 0
bind(RunService.RenderStepped, function(dt)
	local ok, err = pcall(function()
		flyStep()
		freecamStep(dt)
		espStep()
	end)
	if not ok then
		loopErrors += 1
		if loopErrors % 180 == 1 then warn("[NEXUS] loop: " .. tostring(err)) end
	end
end)

bind(RunService.Stepped, function()
	pcall(noclipStep)
	pcall(charStep)
end)

task.spawn(function()
	while PanelGui.Parent do
		task.wait(math.clamp(S.ESP_Refresh, 0.2, 5))
		if S.ESP_Master then pcall(function() ESP:Refresh() end) end
	end
end)

task.spawn(function()
	local start = tick()
	local frames, last = 0, tick()
	bind(RunService.RenderStepped, function() frames += 1 end)
	while PanelGui.Parent do
		task.wait(0.5)
		local now = tick()
		local fps = i(frames / math.max(now - last, 0.001))
		frames, last = 0, now
		local ping, mem = 0, 0
		pcall(function() ping = i(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		pcall(function() mem = i(Stats:GetTotalMemoryUsageMb()) end)
		footFps.Text = fps .. " fps"
		footFps.TextColor3 = fps >= 50 and T.Good or fps >= 25 and T.Warn or T.Bad
		footPing.Text = ping .. " ms  Â·  " .. #Players:GetPlayers() .. " players"
		if UI.upLbl then UI.upLbl.Set("Uptime: " .. i(now - start) .. "s") end
		if HUD.Visible then
			local r = root()
			local h = hum()
			hudLines[1].Text = fps .. " fps  " .. ping .. " ms"
			hudLines[2].Text = mem .. " mb"
			hudLines[3].Text = #Players:GetPlayers() .. " players  " .. #ESP.Targets .. " alvos"
			hudLines[4].Text = r and (i(r.Position.X) .. " " .. i(r.Position.Y) .. " " .. i(r.Position.Z)) or "sem char"
			hudLines[5].Text = h and ("hp " .. i(h.Health) .. "  spd " .. i(h.WalkSpeed)) or ""
		end
	end
end)

bind(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	if Workspace.CurrentCamera then Camera = Workspace.CurrentCamera end
end)

pcall(applyLighting)
pcall(applyCrosshair)
setOpen(true)

print("[NEXUS] pronto. Painel aberto. Atalho: " .. S.KB_Panel)
coreNotify("Nexus Admin", "Pronto! " .. S.KB_Panel .. " abre/fecha o painel.", 6)
notify("Nexus Admin Suite v" .. VERSION, "Aperte " .. S.KB_Panel .. " pra abrir/fechar", 6, "good")
notify("Pronto", "ESP na primeira aba. " .. S.KB_Panic .. " encerra tudo.", 6)
--[[
NEXUS ADMIN SUITE Â· PATCH v1.0.3

Cole este bloco NO FINAL do seu LocalScript atual, depois de todo o cÃ³digo original.
Ele adiciona:
  1) botÃ£o flutuante arrastÃ¡vel para abrir/fechar a GUI;
  2) correÃ§Ã£o dos textos com mojibake, como "ÃƒÂ§", "Ã‚Â·" e "ÃƒÆ’";
  3) ajuste de TextWrapped/TextScaled para os textos nÃ£o cortarem.

IMPORTANTE: salve o arquivo como UTF-8 no Roblox Studio.
]]

local function NX_fixText(s)
	if type(s) ~= "string" then return s end
	local map = {
		["ÃƒÆ’Ã‚Â§"] = "Ã§", ["ÃƒÆ’Ã‚Â£"] = "Ã£", ["ÃƒÆ’Ã‚Â¡"] = "Ã¡", ["ÃƒÆ’Ã‚Â©"] = "Ã©",
		["ÃƒÆ’Ã‚Âª"] = "Ãª", ["ÃƒÆ’Ã‚Â­"] = "Ã­", ["ÃƒÆ’Ã‚Â³"] = "Ã³", ["ÃƒÆ’Ã‚Â´"] = "Ã´",
		["ÃƒÆ’Ã‚Âµ"] = "Ãµ", ["ÃƒÆ’Ã‚Âº"] = "Ãº", ["ÃƒÆ’Ã‚Â§"] = "Ã§", ["ÃƒÆ’Ã¢â‚¬Ëœ"] = "Ã‘",
		["ÃƒÂ§"] = "Ã§", ["ÃƒÂ£"] = "Ã£", ["ÃƒÂ¡"] = "Ã¡", ["ÃƒÂ©"] = "Ã©", ["ÃƒÂª"] = "Ãª",
		["ÃƒÂ­"] = "Ã­", ["ÃƒÂ³"] = "Ã³", ["ÃƒÂ´"] = "Ã´", ["ÃƒÂµ"] = "Ãµ", ["ÃƒÂº"] = "Ãº",
		["Ãƒâ€°"] = "Ã‰", ["Ãƒâ‚¬"] = "Ã€", ["Ãƒâ€¡"] = "Ã‡", ["Ãƒâ€œ"] = "Ã“", ["ÃƒÅ¡"] = "Ãš",
		["Ã‚Â·"] = "Â·", ["Ã‚Â©"] = "Â©", ["Ã‚Âº"] = "Âº", ["Ã¢â‚¬â€œ"] = "â€“", ["Ã¢â‚¬â€"] = "â€”",
		["Ã¢â€“Â¾"] = "â–¾", ["Ã¢â€“Â´"] = "â–´", ["Ã¢â‚¬Â¢"] = "â€¢", ["Ã¢Å¾Â¤"] = "âž¤",
		["Ãƒâ€”"] = "Ã—",
	}
	for bad, good in pairs(map) do s = string.gsub(s, bad, good) end
	return s
end

-- Corrige textos que jÃ¡ foram criados pela interface.
local function NX_repairGuiText(root)
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			obj.Text = NX_fixText(obj.Text)
			obj.PlaceholderText = NX_fixText(obj.PlaceholderText)
			obj.TextWrapped = true
			obj.TextTruncate = Enum.TextTruncate.AtEnd
		end
	end
end

pcall(function()
	NX_repairGuiText(PanelGui)
	NX_repairGuiText(OverlayGui)
end)

-- BotÃ£o flutuante, sempre visÃ­vel mesmo com a janela fechada.
local NX_Float = new("TextButton", {
	Name = "NexusFloatingButton",
	Size = UDim2.fromOffset(58, 58),
	Position = UDim2.new(1, -78, 0.5, -29),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = T.Accent,
	Text = "N",
	TextColor3 = T.Bg,
	TextSize = 24,
	Font = T.FontB,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 100,
	Parent = OverlayGui,
})
corner(29, NX_Float)
local NX_FloatStroke = stroke(T.Text, 1, NX_Float, 0.55)

local NX_FloatSub = label(NX_Float, "NEXUS", {
	Position = UDim2.new(0, -12, 1, 4),
	Size = UDim2.fromOffset(82, 14),
	TextColor3 = T.Text,
	TextSize = 9,
	Font = T.FontB,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextWrapped = false,
	ZIndex = 101,
})

local NX_dragging = false
local NX_dragStart
local NX_buttonStart
local NX_moved = false

NX_Float.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		NX_dragging = true
		NX_moved = false
		NX_dragStart = input.Position
		NX_buttonStart = NX_Float.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not NX_dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local delta = input.Position - NX_dragStart
	if delta.Magnitude > 6 then NX_moved = true end
	NX_Float.Position = UDim2.new(
		NX_buttonStart.X.Scale,
		NX_buttonStart.X.Offset + delta.X,
		NX_buttonStart.Y.Scale,
		NX_buttonStart.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		NX_dragging = false
	end
end)

NX_Float.MouseEnter:Connect(function()
	tween(NX_Float, 0.12, { BackgroundColor3 = T.Text, TextColor3 = T.Accent })
	tween(NX_FloatStroke, 0.12, { Color = T.Accent, Transparency = 0 })
end)

NX_Float.MouseLeave:Connect(function()
	tween(NX_Float, 0.12, { BackgroundColor3 = T.Accent, TextColor3 = T.Bg })
	tween(NX_FloatStroke, 0.12, { Color = T.Text, Transparency = 0.55 })
end)

NX_Float.MouseButton1Click:Connect(function()
	if NX_moved then return end
	setOpen(not uiOpen)
end)

-- Se outro script destruir a interface, este botÃ£o nÃ£o fica sobrando.
PanelGui.Destroying:Connect(function()
	if NX_Float and NX_Float.Parent then NX_Float:Destroy() end
end)

-- Reaplica a correÃ§Ã£o quando novas notificaÃ§Ãµes/labels forem criadas.
task.spawn(function()
	while PanelGui.Parent and OverlayGui.Parent do
		task.wait(1)
		pcall(function()
			NX_repairGuiText(PanelGui)
			NX_repairGuiText(OverlayGui)
		end)
	end
end)

print("[NEXUS] patch v1.0.3 aplicado: botÃ£o flutuante ativo")

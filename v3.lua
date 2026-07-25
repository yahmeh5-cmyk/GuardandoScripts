--[[
    ================================================================
    ADVANCED ROBLOX ADMIN & DEBUG SUITE (MOBILE ADAPTED)
    ================================================================
    Description: Comprehensive LocalScript Admin Panel & ESP System
    Architecture: Adaptive Mobile/PC UI Engine + Touch Floating Toggle Button
    Target Platform: Mobile (iOS/Android) & PC Support
    ================================================================
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------
-- SYSTEM CONFIGURATION & STATE MANAGEMENT
--------------------------------------------------------------------
local Config = {
    -- ESP Settings
    ESP_Enabled = false,
    ESP_Players = true,
    ESP_NPCs = true,
    ESP_Objects = true,
    ESP_Boxes = true,
    ESP_Tracers = true,
    ESP_Names = true,
    ESP_HealthBar = true,
    ESP_Distance = true,
    ESP_Tool = true,
    ESP_Chams = true,
    ESP_TeamColor = true,
    ESP_MaxDistance = 1000,
    ESP_TextSize = 12,
    ESP_BoxColor = Color3.fromRGB(255, 0, 85),
    ESP_TracerColor = Color3.fromRGB(255, 255, 255),
    ESP_NPCColor = Color3.fromRGB(255, 170, 0),
    
    -- Movement & Physics
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    Flying = false,
    Noclip = false,
    InfJump = false,
    Gravity = 196.2,
    HipHeight = 0,
    
    -- World & Render
    Fullbright = false,
    NoFog = false,
    FieldOfView = 70,
    HitboxSize = 2,
    HitboxExpanded = false,
    
    -- Utility
    AntiAFK = true,
    ClickTP = false,
    
    -- UI
    UI_Open = false,
    ToggleKey = Enum.KeyCode.RightControl
}

--------------------------------------------------------------------
-- UI BUILDING ENGINE (MOBILE OPTIMIZED)
--------------------------------------------------------------------
local AdminUI = Instance.new("ScreenGui")
AdminUI.Name = "AdminSuite_Mobile_" .. math.random(10000, 99999)
AdminUI.ResetOnSpawn = false

local success, err = pcall(function()
    if gethui then
        AdminUI.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(AdminUI)
        AdminUI.Parent = game:GetService("CoreGui")
    else
        AdminUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)
if not success then
    AdminUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--------------------------------------------------------------------
-- FLOATING TOGGLE BUTTON FOR MOBILE (SAFE PLACEMENT)
--------------------------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "MobileToggleButton"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0) -- Placed on left mid-side to avoid mobile joysticks/jump buttons
ToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
ToggleBtn.Text = "⚡"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- Allows user to drag button anywhere on screen
ToggleBtn.Parent = AdminUI

local ToggleBtnCorner = Instance.new("UICorner")
ToggleBtnCorner.CornerRadius = UDim.new(0.5, 0) -- Circular Icon
ToggleBtnCorner.Parent = ToggleBtn

local ToggleBtnStroke = Instance.new("UIStroke")
ToggleBtnStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleBtnStroke.Thickness = 2
ToggleBtnStroke.Parent = ToggleBtn

--------------------------------------------------------------------
-- MAIN WINDOW FRAME (RESPONSIVE SIZE)
--------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.85, 0, 0.7, 0) -- Responsive percentage-based sizing for phones/tablets
MainFrame.Position = UDim2.new(0.075, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.Parent = AdminUI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 52, 68)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Top Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ ADMIN SUITE (MOBILE)"
TitleLabel.TextColor3 = Color3.fromRGB(240, 243, 248)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

local function ToggleMenu()
    Config.UI_Open = not Config.UI_Open
    MainFrame.Visible = Config.UI_Open
end

CloseBtn.MouseButton1Click:Connect(ToggleMenu)
ToggleBtn.MouseButton1Click:Connect(ToggleMenu)

-- Sidebar Navigation (Horizontal for Mobile to Save Touch Space)
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(1, -16, 0, 40)
Sidebar.Position = UDim2.new(0, 8, 0, 44)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
Sidebar.BorderSizePixel = 0
Sidebar.CanvasSize = UDim2.new(1.8, 0, 0, 0) -- Horizontal Scroll
Sidebar.ScrollBarThickness = 2
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.FillDirection = Enum.FillDirection.Horizontal
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingLeft = UDim.new(0, 4)
SidebarPadding.PaddingTop = UDim.new(0, 4)
SidebarPadding.Parent = Sidebar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -16, 1, -92)
ContentContainer.Position = UDim2.new(0, 8, 0, 88)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Pages = {}

local function CreateTab(name, icon)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(0, 100, 0, 30)
    TabButton.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
    TabButton.Text = icon .. " " .. name
    TabButton.TextColor3 = Color3.fromRGB(160, 170, 190)
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.TextSize = 11
    TabButton.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    Page.Visible = false
    Page.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 6)
    PagePadding.PaddingLeft = UDim.new(0, 4)
    PagePadding.PaddingRight = UDim.new(0, 4)
    PagePadding.PaddingBottom = UDim.new(0, 6)
    PagePadding.Parent = Page

    Pages[name] = {Button = TabButton, Page = Page}

    TabButton.MouseButton1Click:Connect(function()
        for k, v in pairs(Pages) do
            v.Page.Visible = false
            v.Button.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
            v.Button.TextColor3 = Color3.fromRGB(160, 170, 190)
        end
        Page.Visible = true
        TabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return Page
end

-- UI Control Generators
local function AddToggle(page, labelText, defaultState, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 38) -- Larger Touch Area
    Row.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
    Row.Parent = page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 6)
    RowCorner.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.68, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(220, 225, 235)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 56, 0, 26) -- Touch-Friendly Button
    ToggleBtn.Position = UDim2.new(1, -64, 0.5, -13)
    ToggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(70, 75, 90)
    ToggleBtn.Text = defaultState and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 11
    ToggleBtn.Parent = Row

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleBtn

    local state = defaultState
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.Text = state and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(70, 75, 90)
        callback(state)
    end)
end

local function AddSlider(page, labelText, min, max, default, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 48)
    Row.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
    Row.Parent = page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 6)
    RowCorner.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 18)
    Label.Position = UDim2.new(0, 10, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = labelText .. ": " .. tostring(default)
    Label.TextColor3 = Color3.fromRGB(220, 225, 235)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -20, 0, 12) -- Thicker for touch sliders
    SliderBg.Position = UDim2.new(0, 10, 0, 26)
    SliderBg.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    SliderBg.Parent = Row

    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(0, 6)
    SliderBgCorner.Parent = SliderBg

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    SliderFill.Parent = SliderBg

    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 6)
    SliderFillCorner.Parent = SliderFill

    local isDragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        Label.Text = labelText .. ": " .. tostring(val)
        callback(val)
    end

    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            Update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
end

local function AddButton(page, buttonText, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    Btn.Text = buttonText
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = page

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn

    Btn.MouseButton1Click:Connect(callback)
end

--------------------------------------------------------------------
-- CREATE TAB PAGES
--------------------------------------------------------------------
local ESPPage = CreateTab("ESP System", "👁️")
local MovementPage = CreateTab("Movement", "🏃")
local WorldPage = CreateTab("World", "🌐")
local PlayerPage = CreateTab("Player", "👤")
local AdminToolsPage = CreateTab("Tools", "🛠️")

--------------------------------------------------------------------
-- POPULATE TABS
--------------------------------------------------------------------
AddToggle(ESPPage, "[1] Master ESP Switch", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v end)
AddToggle(ESPPage, "[2] Player ESP", Config.ESP_Players, function(v) Config.ESP_Players = v end)
AddToggle(ESPPage, "[3] NPC / Mob ESP", Config.ESP_NPCs, function(v) Config.ESP_NPCs = v end)
AddToggle(ESPPage, "[4] 2D Boxes", Config.ESP_Boxes, function(v) Config.ESP_Boxes = v end)
AddToggle(ESPPage, "[5] Snapline Tracers", Config.ESP_Tracers, function(v) Config.ESP_Tracers = v end)
AddToggle(ESPPage, "[6] Name Tags", Config.ESP_Names, function(v) Config.ESP_Names = v end)
AddToggle(ESPPage, "[7] Health Bar", Config.ESP_HealthBar, function(v) Config.ESP_HealthBar = v end)
AddToggle(ESPPage, "[8] Distance Meter", Config.ESP_Distance, function(v) Config.ESP_Distance = v end)
AddToggle(ESPPage, "[9] Wall Chams Highlight", Config.ESP_Chams, function(v) Config.ESP_Chams = v end)
AddSlider(ESPPage, "[10] Max Distance", 100, 3000, Config.ESP_MaxDistance, function(v) Config.ESP_MaxDistance = v end)

AddSlider(MovementPage, "[1] WalkSpeed", 16, 250, Config.WalkSpeed, function(v)
    Config.WalkSpeed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

AddSlider(MovementPage, "[2] Jump Power", 50, 300, Config.JumpPower, function(v)
    Config.JumpPower = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)

AddToggle(MovementPage, "[3] Noclip (Wall Pass)", Config.Noclip, function(v) Config.Noclip = v end)
AddToggle(MovementPage, "[4] Infinite Jump", Config.InfJump, function(v) Config.InfJump = v end)

AddToggle(WorldPage, "[1] Fullbright Mode", Config.Fullbright, function(v)
    Config.Fullbright = v
    if v then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

AddSlider(WorldPage, "[2] Field of View (FOV)", 30, 120, Config.FieldOfView, function(v)
    Config.FieldOfView = v
    Camera.FieldOfView = v
end)

AddToggle(PlayerPage, "[1] Hitbox Expander", Config.HitboxExpanded, function(v) Config.HitboxExpanded = v end)
AddSlider(PlayerPage, "[2] Hitbox Size", 2, 20, Config.HitboxSize, function(v) Config.HitboxSize = v end)
AddButton(PlayerPage, "[3] Reset Character", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end)

AddToggle(AdminToolsPage, "[1] Anti-AFK", Config.AntiAFK, function(v) Config.AntiAFK = v end)
AddButton(AdminToolsPage, "[2] Rejoin Server", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Default Active Tab
Pages["ESP System"].Page.Visible = true
Pages["ESP System"].Button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
Pages["ESP System"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

--------------------------------------------------------------------
-- TOUCH INF JUMP & NOCLIP LOOP
--------------------------------------------------------------------
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

--------------------------------------------------------------------
-- ESP ENGINE & RENDER LOOP
--------------------------------------------------------------------
local ESP_Cache = {}

local function ClearESPCache(model)
    if ESP_Cache[model] then
        for _, obj in pairs(ESP_Cache[model]) do
            if type(obj) == "table" and obj.Remove then
                obj:Remove()
            elseif typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        ESP_Cache[model] = nil
    end
end

local function DrawESPForCharacter(model, isPlayer)
    if not Config.ESP_Enabled then return end
    if model == LocalPlayer.Character then return end
    
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("PrimaryPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    
    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    
    if not onScreen or dist > Config.ESP_MaxDistance then
        ClearESPCache(model)
        return
    end

    if not ESP_Cache[model] then
        ESP_Cache[model] = {}
        local highlight = Instance.new("Highlight")
        highlight.Name = "AdminESP_Cham"
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = model
        ESP_Cache[model].Highlight = highlight
    end

    local cache = ESP_Cache[model]
    local color = isPlayer and Config.ESP_BoxColor or Config.ESP_NPCColor

    if cache.Highlight then
        cache.Highlight.Enabled = Config.ESP_Chams
        cache.Highlight.FillColor = color
        cache.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= Config.WalkSpeed then
            LocalPlayer.Character.Humanoid.WalkSpeed = Config.WalkSpeed
        end
    end

    if Config.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if Config.ESP_Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then DrawESPForCharacter(player.Character, true) end
        end
        if Config.ESP_NPCs then
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                    DrawESPForCharacter(obj, false)
                end
            end
        end
    end
end)

print("[MOBILE SUITE] Loaded successfully.")

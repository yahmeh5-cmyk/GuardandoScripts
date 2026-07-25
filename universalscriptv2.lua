--[[
    Admin GUI - Roblox
    16 ESPs + 10+ powers | Mobile optimized
    Coloque em StarterPlayerScripts como LocalScript
]]

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local Lighting = game:GetService("Lighting")

-- // Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local uis = UserInputService

-- // Configurações
local config = {
    -- ESP
    espEnabled = true,
    espPlayers = true,
    espNames = true,
    espHealth = true,
    espDistance = true,
    espBoxes = true,
    espTracers = true,
    espSkeleton = true,
    espChams = true,
    espNPC = true,
    espItems = true,
    espCorpse = true,
    espVehicle = true,
    espExplosives = true,
    espLoot = true,
    espQuestNPCs = true,
    espCustom = true,
    espQuestNPCTags = {"QuestGiver", "NPC", "Merchant"},
    espCustomTags = {"CustomTag"},
    -- Movement
    speedEnabled = false,
    speedValue = 50,
    flyEnabled = false,
    flySpeed = 50,
    noclipEnabled = false,
    jumpBoostEnabled = false,
    jumpBoostValue = 100,
    infiniteJumpEnabled = false,
    -- Visual
    fullbrightEnabled = false,
    removeFogEnabled = false,
    timeSkipEnabled = false,
    timeValue = 12,
    gravityControlEnabled = false,
    gravityValue = 196,
    -- Combat
    aimbotEnabled = false,
    aimbotFOV = 100,
    aimbotSmoothness = 0.1,
    hitboxExtendEnabled = false,
    hitboxSize = 10,
    noRecoilEnabled = false,
    -- Utility
    antiAfkEnabled = false,
    chatSpyEnabled = false,
    autoClickEnabled = false,
    teleportToolEnabled = false,
}

-- // GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- // Background overlay
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 1
background.Visible = false
background.Parent = screenGui

-- // Floating Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = UDim2.new(1, -70, 1, -80)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
toggleBtn.Text = "⚙"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 24
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.AutoButtonColor = true
toggleBtn.Draggable = true
local toggleUICorner = Instance.new("UICorner")
toggleUICorner.CornerRadius = UDim.new(0, 12)
toggleUICorner.Parent = toggleBtn
local toggleUIStroke = Instance.new("UIStroke")
toggleUIStroke.Color = Color3.fromRGB(255, 255, 255)
toggleUIStroke.Thickness = 2
toggleUIStroke.Parent = toggleBtn
toggleBtn.Parent = screenGui

-- // Main Panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 350, 0, 500)
mainPanel.Position = UDim2.new(0, 20, 0.5, -250)
mainPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainPanel.BackgroundTransparency = 0.1
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Draggable = true
local mainUICorner = Instance.new("UICorner")
mainUICorner.CornerRadius = UDim.new(0, 10)
mainUICorner.Parent = mainPanel
local mainUIStroke = Instance.new("UIStroke")
mainUIStroke.Color = Color3.fromRGB(30, 144, 255)
mainUIStroke.Thickness = 1
mainUIStroke.Transparency = 0.5
mainUIStroke.Parent = mainPanel
mainPanel.Parent = screenGui

-- // Panel Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
header.BorderSizePixel = 0
header.Parent = mainPanel

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(1, -50, 1, 0)
headerTitle.Position = UDim2.new(0, 10, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "Admin GUI"
headerTitle.Font = Enum.Font.SourceSansBold
headerTitle.TextSize = 18
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -10, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = true
closeBtn.Parent = header
local closeUICorner = Instance.new("UICorner")
closeUICorner.CornerRadius = UDim.new(0, 6)
closeUICorner.Parent = closeBtn

-- // Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainPanel

local espTabBtn = Instance.new("TextButton")
espTabBtn.Name = "EspTabBtn"
espTabBtn.Size = UDim2.new(0.2, 0, 1, 0)
espTabBtn.Position = UDim2.new(0, 0, 0, 0)
espTabBtn.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
espTabBtn.Text = "ESP"
espTabBtn.Font = Enum.Font.SourceSansBold
espTabBtn.TextSize = 14
espTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espTabBtn.AutoButtonColor = true
espTabBtn.Parent = tabContainer

local movementTabBtn = Instance.new("TextButton")
movementTabBtn.Name = "MovementTabBtn"
movementTabBtn.Size = UDim2.new(0.2, 0, 1, 0)
movementTabBtn.Position = UDim2.new(0.2, 0, 0, 0)
movementTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
movementTabBtn.Text = "Movement"
movementTabBtn.Font = Enum.Font.SourceSansBold
movementTabBtn.TextSize = 12
movementTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
movementTabBtn.AutoButtonColor = true
movementTabBtn.Parent = tabContainer

local visualTabBtn = Instance.new("TextButton")
visualTabBtn.Name = "VisualTabBtn"
visualTabBtn.Size = UDim2.new(0.2, 0, 1, 0)
visualTabBtn.Position = UDim2.new(0.4, 0, 0, 0)
visualTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
visualTabBtn.Text = "Visual"
visualTabBtn.Font = Enum.Font.SourceSansBold
visualTabBtn.TextSize = 12
visualTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
visualTabBtn.AutoButtonColor = true
visualTabBtn.Parent = tabContainer

local combatTabBtn = Instance.new("TextButton")
combatTabBtn.Name = "CombatTabBtn"
combatTabBtn.Size = UDim2.new(0.2, 0, 1, 0)
combatTabBtn.Position = UDim2.new(0.6, 0, 0, 0)
combatTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
combatTabBtn.Text = "Combat"
combatTabBtn.Font = Enum.Font.SourceSansBold
combatTabBtn.TextSize = 12
combatTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
combatTabBtn.AutoButtonColor = true
combatTabBtn.Parent = tabContainer

local utilityTabBtn = Instance.new("TextButton")
utilityTabBtn.Name = "UtilityTabBtn"
utilityTabBtn.Size = UDim2.new(0.2, 0, 1, 0)
utilityTabBtn.Position = UDim2.new(0.8, 0, 0, 0)
utilityTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
utilityTabBtn.Text = "Utility"
utilityTabBtn.Font = Enum.Font.SourceSansBold
utilityTabBtn.TextSize = 12
utilityTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
utilityTabBtn.AutoButtonColor = true
utilityTabBtn.Parent = tabContainer

-- // Content Area (ScrollView)
local contentArea = Instance.new("ScrollingFrame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -10, 1, -85)
contentArea.Position = UDim2.new(0, 5, 0, 40)
contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
contentArea.ScrollBarThickness = 6
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = mainPanel

local contentUICorner = Instance.new("UICorner")
contentUICorner.CornerRadius = UDim.new(0, 6)
contentUICorner.Parent = contentArea

-- // Tab Content Frames
local tabs = {}
for _, tabName in ipairs({"ESP", "Movement", "Visual", "Combat", "Utility"}) do
    local tab = Instance.new("Frame")
    tab.Name = tabName .. "Tab"
    tab.Size = UDim2.new(1, 0, 0, 0)
    tab.BackgroundTransparency = 1
    tab.BorderSizePixel = 0
    tab.Visible = false
    tab.Parent = contentArea
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = 8
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = tab
    
    tabs[tabName] = tab
end

-- // Helper: Create Toggle Button
local function createToggle(parent, name, label, key)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Frame"
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local toggle = Instance.new("TextButton")
    toggle.Name = name .. "Toggle"
    toggle.Size = UDim2.new(0, 40, 0, 40)
    toggle.BackgroundColor3 = config[key] and Color3.fromRGB(30, 200, 30) or Color3.fromRGB(80, 80, 80)
    toggle.Text = config[key] and "✓" or ""
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 18
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.AutoButtonColor = true
    toggle.Parent = frame
    local toggleUICorner = Instance.new("UICorner")
    toggleUICorner.CornerRadius = UDim.new(0, 6)
    toggleUICorner.Parent = toggle
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = name .. "Label"
    labelText.Size = UDim2.new(1, -50, 1, 0)
    labelText.Position = UDim2.new(0, 50, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.SourceSans
    labelText.TextSize = 14
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = frame
    
    toggle.MouseButton1Click:Connect(function()
        config[key] = not config[key]
        toggle.BackgroundColor3 = config[key] and Color3.fromRGB(30, 200, 30) or Color3.fromRGB(80, 80, 80)
        toggle.Text = config[key] and "✓" or ""
        
        -- Update powers when toggled
        if key == "speedEnabled" then toggleSpeed() end
        if key == "flyEnabled" then toggleFly() end
        if key == "noclipEnabled" then toggleNoclip() end
        if key == "jumpBoostEnabled" then toggleJumpBoost() end
        if key == "infiniteJumpEnabled" then toggleInfiniteJump() end
        if key == "fullbrightEnabled" then toggleFullbright() end
        if key == "removeFogEnabled" then toggleRemoveFog() end
        if key == "timeSkipEnabled" then toggleTimeSkip() end
        if key == "gravityControlEnabled" then toggleGravity() end
        if key == "aimbotEnabled" then toggleAimbot() end
        if key == "hitboxExtendEnabled" then toggleHitboxExtend() end
        if key == "noRecoilEnabled" then toggleNoRecoil() end
        if key == "antiAfkEnabled" then toggleAntiAfk() end
        if key == "chatSpyEnabled" then toggleChatSpy() end
        if key == "autoClickEnabled" then toggleAutoClick() end
        if key == "teleportToolEnabled" then toggleTeleportTool() end
    end)
    
    return toggle
end

-- // Helper: Create Slider
local function createSlider(parent, name, label, key, min, max, default)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Frame"
    frame.Size = UDim2.new(1, -10, 0, 55)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = name .. "Label"
    labelText.Size = UDim2.new(1, 0, 0, 20)
    labelText.BackgroundTransparency = 1
    labelText.Text = label .. ": " .. tostring(default)
    labelText.Font = Enum.Font.SourceSans
    labelText.TextSize = 13
    labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Name = name .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slider.BorderSizePixel = 0
    slider.Parent = frame
    local sliderUICorner = Instance.new("UICorner")
    sliderUICorner.CornerRadius = UDim.new(0, 4)
    sliderUICorner.Parent = slider
    
    local fill = Instance.new("Frame")
    fill.Name = name .. "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    local fillUICorner = Instance.new("UICorner")
    fillUICorner.CornerRadius = UDim.new(0, 4)
    fillUICorner.Parent = fill
    
    local dragging = false
    slider.Active = true
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * percent)
            config[key] = value
            fill.Size = UDim2.new(percent, 0, 1, 0)
            labelText.Text = label .. ": " .. tostring(value)
            
            -- Update powers when slider changed
            if key == "speedValue" and config.speedEnabled then toggleSpeed() end
            if key == "flySpeed" and config.flyEnabled then toggleFly() end
            if key == "jumpBoostValue" and config.jumpBoostEnabled then toggleJumpBoost() end
            if key == "timeValue" and config.timeSkipEnabled then toggleTimeSkip() end
            if key == "gravityValue" and config.gravityControlEnabled then toggleGravity() end
            if key == "aimbotFOV" then end -- Updated in loop
            if key == "aimbotSmoothness" then end -- Updated in loop
            if key == "hitboxSize" and config.hitboxExtendEnabled then toggleHitboxExtend() end
        end
    end)
    
    return slider
end

-- // Populate Tabs
-- ESP Tab
createToggle(tabs.ESP, "ESPEnabled", "ESP Enabled", "espEnabled")
createToggle(tabs.ESP, "ESPPlayers", "ESP Players", "espPlayers")
createToggle(tabs.ESP, "ESPNames", "ESP Names", "espNames")
createToggle(tabs.ESP, "ESPHealth", "ESP Health", "espHealth")
createToggle(tabs.ESP, "ESPDistance", "ESP Distance", "espDistance")
createToggle(tabs.ESP, "ESPBoxes", "ESP Boxes", "espBoxes")
createToggle(tabs.ESP, "ESPTracers", "ESP Tracers", "espTracers")
createToggle(tabs.ESP, "ESPSkeleton", "ESP Skeleton", "espSkeleton")
createToggle(tabs.ESP, "ESPChams", "ESP Chams", "espChams")
createToggle(tabs.ESP, "ESPNPC", "ESP NPC", "espNPC")
createToggle(tabs.ESP, "ESPItems", "ESP Items", "espItems")
createToggle(tabs.ESP, "ESPCorpse", "ESP Corpse", "espCorpse")
createToggle(tabs.ESP, "ESPVehicle", "ESP Vehicle", "espVehicle")
createToggle(tabs.ESP, "ESPExplosives", "ESP Explosives", "espExplosives")
createToggle(tabs.ESP, "ESPLoot", "ESP Loot", "espLoot")
createToggle(tabs.ESP, "ESPQuestNPCs", "ESP Quest NPCs", "espQuestNPCs")
createToggle(tabs.ESP, "ESPCustom", "ESP Custom Tags", "espCustom")

-- Movement Tab
createToggle(tabs.Movement, "Speed", "Speed Hack", "speedEnabled")
createSlider(tabs.Movement, "SpeedValue", "Speed Value", "speedValue", 16, 200, 50)
createToggle(tabs.Movement, "Fly", "Fly", "flyEnabled")
createSlider(tabs.Movement, "FlySpeed", "Fly Speed", "flySpeed", 10, 200, 50)
createToggle(tabs.Movement, "Noclip", "Noclip", "noclipEnabled")
createToggle(tabs.Movement, "JumpBoost", "Jump Boost", "jumpBoostEnabled")
createSlider(tabs.Movement, "JumpBoostValue", "Jump Power", "jumpBoostValue", 50, 300, 100)
createToggle(tabs.Movement, "InfiniteJump", "Infinite Jump", "infiniteJumpEnabled")

-- Visual Tab
createToggle(tabs.Visual, "Fullbright", "Fullbright", "fullbrightEnabled")
createToggle(tabs.Visual, "RemoveFog", "Remove Fog", "removeFogEnabled")
createToggle(tabs.Visual, "TimeSkip", "Time Skip", "timeSkipEnabled")
createSlider(tabs.Visual, "TimeValue", "Time Value", "timeValue", 0, 24, 12)
createToggle(tabs.Visual, "GravityControl", "Gravity Control", "gravityControlEnabled")
createSlider(tabs.Visual, "GravityValue", "Gravity Value", "gravityValue", 0, 300, 196)

-- Combat Tab
createToggle(tabs.Combat, "Aimbot", "Aimbot", "aimbotEnabled")
createSlider(tabs.Combat, "AimbotFOV", "Aimbot FOV", "aimbotFOV", 10, 360, 100)
createSlider(tabs.Combat, "AimbotSmoothness", "Aimbot Smoothness", "aimbotSmoothness", 1, 20, 1)
createToggle(tabs.Combat, "HitboxExtend", "Hitbox Extend", "hitboxExtendEnabled")
createSlider(tabs.Combat, "HitboxSize", "Hitbox Size", "hitboxSize", 2, 20, 10)
createToggle(tabs.Combat, "NoRecoil", "No Recoil", "noRecoilEnabled")

-- Utility Tab
createToggle(tabs.Utility, "AntiAfk", "Anti-AFK", "antiAfkEnabled")
createToggle(tabs.Utility, "ChatSpy", "Chat Spy", "chatSpyEnabled")
createToggle(tabs.Utility, "AutoClick", "Auto Click", "autoClickEnabled")
createToggle(tabs.Utility, "TeleportTool", "Teleport Tool", "teleportToolEnabled")

-- // ESP System
local espObjects = {}
local drawingObjects = {}

local function isNPC(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local isPlayer = Players:GetPlayerFromCharacter(model)
    return not isPlayer
end

local function isItem(obj)
    return obj:IsA("Tool") or (obj:IsA("Part") and (obj.Name:lower():find("item") or obj.Name:lower():find("weapon")))
end

local function isCorpse(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return true end
    return false
end

local function isVehicle(obj)
    if obj:IsA("VehicleSeat") then return true end
    if obj:IsA("Model") then
        return obj:FindFirstChildOfClass("VehicleSeat") or obj:FindFirstChild("VehicleControl")
    end
    return false
end

local function isExplosive(obj)
    local explosiveNames = {"grenade", "bomb", "explosive", "rocket", "mine"}
    for _, name in ipairs(explosiveNames) do
        if obj.Name:lower():find(name) then return true end
    end
    if obj:IsA("ParticleEmitter") and obj.Name:lower():find("explosion") then return true end
    return false
end

local function isLoot(obj)
    local lootNames = {"chest", "loot", "crate", "drop", "treasure"}
    for _, name in ipairs(lootNames) do
        if obj.Name:lower():find(name) then return true end
    end
    return false
end

local function isQuestNPC(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local isPlayer = Players:GetPlayerFromCharacter(model)
    if isPlayer then return false end
    for _, tag in ipairs(config.espQuestNPCTags) do
        if model.Name:find(tag) then return true end
    end
    return false
end

local function isCustomTag(obj)
    for _, tag in ipairs(config.espCustomTags) do
        if obj.Name:find(tag) then return true end
    end
    return false
end

local function createESP(playerObj)
    local character = playerObj.Character or playerObj.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP"
    espFolder.Parent = character
    
    -- Highlight (Chams)
    if config.espChams then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.3
        highlight.Enabled = config.espChams
        highlight.Parent = character
        espFolder.ESPHighlight = highlight
    end
    
    -- BillboardGui (Names, Health, Distance)
    if config.espNames or config.espHealth or config.espDistance then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.Adornee = rootPart
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = character
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerObj.Name or "Unknown"
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Visible = config.espNames
        nameLabel.Parent = billboard
        
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.4, 0)
        healthLabel.BackgroundTransparency = 1
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        healthLabel.Text = humanoid and ("Health: " .. math.floor(humanoid.Health)) or "Health: N/A"
        healthLabel.Font = Enum.Font.SourceSans
        healthLabel.TextSize = 12
        healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        healthLabel.TextStrokeTransparency = 0.5
        healthLabel.Visible = config.espHealth
        healthLabel.Parent = billboard
        
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Text = "Distance: " .. math.floor((rootPart.Position - camera.CFrame.Position).Magnitude) .. "m"
        distanceLabel.Font = Enum.Font.SourceSans
        distanceLabel.TextSize = 12
        distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        distanceLabel.TextStrokeTransparency = 0.5
        distanceLabel.Visible = config.espDistance
        distanceLabel.Parent = billboard
        
        espFolder.ESPBillboard = billboard
    end
    
    -- Drawing objects (Boxes, Tracers, Skeleton)
    if config.espBoxes or config.espTracers or config.espSkeleton then
        local drawTable = {}
        espFolder.Drawings = drawTable
        
        if config.espBoxes then
            local box = Drawing.new("Rectangle")
            box.Visible = false
            box.Color = Color3.fromRGB(255, 255, 255)
            box.Thickness = 1
            box.Filled = false
            drawTable.Box = box
        end
        
        if config.espTracers then
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Color = Color3.fromRGB(255, 255, 255)
            tracer.Thickness = 1
            drawTable.Tracer = tracer
        end
        
        if config.espSkeleton then
            local joints = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}
            for _, joint in ipairs(joints) do
                local line = Drawing.new("Line")
                line.Visible = false
                line.Color = Color3.fromRGB(255, 255, 255)
                line.Thickness = 1
                drawTable[joint] = line
            end
        end
    end
end

local function removeESP(character)
    if character then
        local espFolder = character:FindFirstChild("ESP")
        if espFolder then
            espFolder:Destroy()
        end
    end
end

local function updateESP()
    if not config.espEnabled then return end
    
    -- Update player ESPs
    for _, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj ~= player then
            if config.espPlayers then
                if playerObj.Character then
                    if not playerObj.Character:FindFirstChild("ESP") then
                        createESP(playerObj)
                    end
                end
            else
                if playerObj.Character then
                    removeESP(playerObj.Character)
                end
            end
        end
    end
    
    -- Update NPC ESPs
    if config.espNPC then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isNPC(obj) then
                if not obj:FindFirstChild("ESP") then
                    createESP(obj)
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isNPC(obj) and obj:FindFirstChild("ESP") then
                obj.ESP:Destroy()
            end
        end
    end
    
    -- Update Item ESPs
    if config.espItems then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isItem(obj) then
                if not obj:FindFirstChild("ESP") then
                    local espFolder = Instance.new("Folder")
                    espFolder.Name = "ESP"
                    espFolder.Parent = obj
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.Adornee = obj:IsA("Tool") and (obj:FindFirstChild("Handle") or obj) or obj
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0, 1, 0)
                    billboard.Parent = obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[ITEM] " .. obj.Name
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextColor3 = Color3.fromRGB(0, 255, 255)
                    label.Parent = billboard
                    
                    espFolder.Billboard = billboard
                end
            end
        end
    end
    
    -- Update Corpse ESPs
    if config.espCorpse then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isCorpse(obj) then
                if not obj:FindFirstChild("ESP") then
                    local espFolder = Instance.new("Folder")
                    espFolder.Name = "ESP"
                    espFolder.Parent = obj
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.Adornee = obj:FindFirstChild("Head") or obj:FindFirstChildOfClass("BasePart")
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0, 1, 0)
                    billboard.Parent = obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[CORPSE] " .. obj.Name
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextColor3 = Color3.fromRGB(150, 150, 150)
                    label.Parent = billboard
                    
                    espFolder.Billboard = billboard
                end
            end
        end
    end
    
    -- Update Vehicle ESPs
    if config.espVehicle then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isVehicle(obj) then
                if not obj:FindFirstChild("ESP") then
                    local espFolder = Instance.new("Folder")
                    espFolder.Name = "ESP"
                    espFolder.Parent = obj
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.Adornee = obj:IsA("VehicleSeat") and obj or (obj:FindFirstChild("Seat") or obj:FindFirstChildOfClass("BasePart"))
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.Parent = obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[VEHICLE] " .. obj.Name
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextColor3 = Color3.fromRGB(255, 165, 0)
                    label.Parent = billboard
                    
                    espFolder.Billboard = billboard
                end
            end
        end
    end
    
    -- Update Explosive ESPs
    if config.espExplosives then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isExplosive(obj) then
                if not obj:FindFirstChild("ESP") then
                    local espFolder = Instance.new("Folder")
                    espFolder.Name = "ESP"
                    espFolder.Parent = obj
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.Adornee = obj:IsA("ParticleEmitter") and obj.Parent or obj
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0, 1, 0)
                    billboard.Parent = obj:IsA("ParticleEmitter") and obj.Parent or obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[EXPLOSIVE] " .. obj.Name
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextColor3 = Color3.fromRGB(255, 0, 0)
                    label.Parent = billboard
                    
                    espFolder.Billboard = billboard
                end
            end
        end
    end
    
    -- Update Loot ESPs
    if config.espLoot then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isLoot(obj) then
                if not obj:FindFirstChild("ESP") then
                    local espFolder = Instance.new("Folder")
                    espFolder.Name = "ESP"
                    espFolder.Parent = obj
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.Adornee = obj:FindFirstChildOfClass("BasePart") or obj
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.Parent = obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[LOOT] " .. obj.Name
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextColor3 = Color3.fromRGB(255, 215, 0)
                    label.Parent = billboard
                    
                    espFolder.Billboard = billboard
                end
            end
        end
    end
    
    -- Update Quest NPC ESPs
    if config.espQuestNPCs then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isQuestNPC(obj) then
                if not obj:FindFirstChild("ESP") then
                    createESP(obj)
                end
            end
        end
    end
    
    -- Update Drawing objects (Boxes, Tracers, Skeleton)
    for _, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj ~= player and playerObj.Character then
            local espFolder = playerObj.Character:FindFirstChild("ESP")
            if espFolder and espFolder:FindFirstChild("Drawings") then
                local drawings = espFolder.Drawings
                local rootPart = playerObj.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local screenPos = camera:WorldToScreenPoint(rootPart.Position)
                    if screenPos.Z > 0 then
                        if drawings.Box then
                            drawings.Box.Visible = config.espBoxes
                            if config.espBoxes then
                                local size = Vector2.new(50, 80)
                                drawings.Box.Size = size
                                drawings.Box.Position = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)
                            end
                        end
                        
                        if drawings.Tracer then
                            drawings.Tracer.Visible = config.espTracers
                            if config.espTracers then
                                drawings.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                                drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            end
                        end
                        
                        if drawings.Head then
                            local head = playerObj.Character:FindFirstChild("Head")
                            local root = playerObj.Character:FindFirstChild("HumanoidRootPart")
                            if head and root then
                                local headPos = camera:WorldToScreenPoint(head.Position)
                                local rootPos = camera:WorldToScreenPoint(root.Position)
                                
                                for _, joint in ipairs({"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}) do
                                    local part = playerObj.Character:FindFirstChild(joint)
                                    if part and drawings[joint] then
                                        local pos = camera:WorldToScreenPoint(part.Position)
                                        drawings[joint].From = Vector2.new(headPos.X, headPos.Y)
                                        drawings[joint].To = Vector2.new(pos.X, pos.Y)
                                        drawings[joint].Visible = true
                                    end
                                end
                            end
                        end
                    else
                        if drawings.Box then drawings.Box.Visible = false end
                        if drawings.Tracer then drawings.Tracer.Visible = false end
                        for _, joint in ipairs({"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}) do
                            if drawings[joint] then
                                drawings[joint].Visible = false
                            end
                        end
                    end
                end
            end
        end
    end
end

-- // Movement Powers
local speedConn
local flyConn
local noclipConn
local jumpConn
local infiniteJumpConn

local function toggleSpeed()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = config.speedEnabled and config.speedValue or 16
    end
end

local function toggleFly()
    if config.flyEnabled then
        local char = player.Character or player.CharacterAdded:Wait()
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "FlyVelocity"
            bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.Parent = rootPart
            
            flyConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not config.flyEnabled or not rootPart then 
                    if flyConn then flyConn:Disconnect() end
                    return 
                end
                local moveDir = Vector3.new(0, 0, 0)
                if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                moveDir = moveDir.Unit * config.flySpeed
                bodyVelocity.Velocity = moveDir
            end)
        end
    else
        local char = player.Character
        if char then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local flyVel = rootPart:FindFirstChild("FlyVelocity")
                if flyVel then flyVel:Destroy() end
            end
        end
    end
end

local function toggleNoclip()
    if config.noclipEnabled then
        noclipConn = game:GetService("RunService").Stepped:Connect(function()
            if not config.noclipEnabled then 
                if noclipConn then noclipConn:Disconnect() end
                return 
            end
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function toggleJumpBoost()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = config.jumpBoostEnabled and config.jumpBoostValue or 50
    end
end

local function toggleInfiniteJump()
    if config.infiniteJumpEnabled then
        infiniteJumpConn = uis.JumpRequest:Connect(function()
            if config.infiniteJumpEnabled then
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
    else
        if infiniteJumpConn then
            infiniteJumpConn:Disconnect()
        end
    end
end

-- // Visual Powers
local originalFog, originalTime, originalGravity

local function toggleFullbright()
    if config.fullbrightEnabled then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 100000
    else
        if originalFog then
            Lighting.FogEnd = originalFog
        end
    end
end

local function toggleRemoveFog()
    if config.removeFogEnabled then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ambient = Color3.fromRGB(255, 255, 255)
    else
        if originalFog then
            Lighting.FogEnd = originalFog
        end
    end
end

local function toggleTimeSkip()
    if config.timeSkipEnabled then
        originalTime = Lighting.TimeOfDay
        Lighting.TimeOfDay = tostring(config.timeValue) .. ":00:00"
    else
        if originalTime then
            Lighting.TimeOfDay = originalTime
        end
    end
end

local function toggleGravity()
    if config.gravityControlEnabled then
        originalGravity = workspace.Gravity
        workspace.Gravity = config.gravityValue
    else
        if originalGravity then
            workspace.Gravity = originalGravity
        end
    end
end

-- // Combat Powers
local aimbotConn
local hitboxConn

local function toggleAimbot()
    if config.aimbotEnabled then
        aimbotConn = game:GetService("RunService").RenderStepped:Connect(function()
            if not config.aimbotEnabled then 
                if aimbotConn then aimbotConn:Disconnect() end
                return 
            end
            
            local closestPlayer
            local closestDistance = math.huge
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local screenPos = camera:WorldToScreenPoint(rootPart.Position)
                        if screenPos.Z > 0 then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if distance < config.aimbotFOV and distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = targetPlayer
                            end
                        end
                    end
                end
            end
            
            if closestPlayer and closestPlayer.Character then
                local rootPart = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local targetPos = rootPart.Position
                    local currentCFrame = camera.CFrame
                    local newCFrame = CFrame.fromMatrix(currentCFrame.Position, CFrame.new(currentCFrame.Position, targetPos))
                    camera.CFrame = currentCFrame:Lerp(newCFrame, config.aimbotSmoothness)
                end
            end
        end)
    else
        if aimbotConn then
            aimbotConn:Disconnect()
        end
    end
end

local function toggleHitboxExtend()
    if config.hitboxExtendEnabled then
        hitboxConn = game:GetService("RunService").Stepped:Connect(function()
            if not config.hitboxExtendEnabled then 
                if hitboxConn then hitboxConn:Disconnect() end
                return 
            end
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
                        rootPart.Transparency = 0.7
                        rootPart.CanCollide = false
                    end
                end
            end
        end)
    else
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer.Character then
                local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Size = Vector3.new(2, 2, 1)
                    rootPart.Transparency = 0
                    rootPart.CanCollide = true
                end
            end
        end
    end
end

local function toggleNoRecoil()
    -- No recoil implementation would require hooking into weapon scripts
    -- This is a placeholder - actual implementation depends on game
end

-- // Utility Powers
local antiAfkConn
local chatSpyConn
local autoClickConn

local function toggleAntiAfk()
    if config.antiAfkEnabled then
        antiAfkConn = game:GetService("RunService").Stepped:Connect(function()
            if config.antiAfkEnabled then
                local virtualUser = game:GetService("VirtualUser")
                virtualUser:CaptureController()
                virtualUser:MoveMouse(0, 0)
            end
        end)
    else
        if antiAfkConn then
            antiAfkConn:Disconnect()
        end
    end
end

local function toggleChatSpy()
    if config.chatSpyEnabled then
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local chatEvents = replicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local onMessage = chatEvents:FindFirstChild("OnMessageDoneFiltering")
            if onMessage then
                chatSpyConn = onMessage.OnClientEvent:Connect(function(messageData)
                    if messageData.Message then
                        print("[CHAT SPY] " .. (messageData.FromSpeaker or "Unknown") .. ": " .. messageData.Message)
                    end
                end)
            end
        end
    else
        if chatSpyConn then
            chatSpyConn:Disconnect()
        end
    end
end

local function toggleAutoClick()
    if config.autoClickEnabled then
        autoClickConn = game:GetService("RunService").RenderStepped:Connect(function()
            if config.autoClickEnabled then
                mouse:Click()
            end
        end)
    else
        if autoClickConn then
            autoClickConn:Disconnect()
        end
    end
end

local function toggleTeleportTool()
    if config.teleportToolEnabled then
        local tool = Instance.new("Tool")
        tool.Name = "TeleportTool"
        tool.RequiresHandle = false
        
        local function onActivated()
            local target = mouse.Target
            if target and target:IsA("BasePart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
        
        tool.Activated:Connect(onActivated)
        tool.Parent = player.Backpack
    else
        local tool = player.Backpack:FindFirstChild("TeleportTool")
        if tool then tool:Destroy() end
    end
end

-- // Button Connections
toggleBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = not mainPanel.Visible
    background.Visible = not background.Visible
    toggleBtn.Text = mainPanel.Visible and "✕" or "⚙"
end)

closeBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = false
    background.Visible = false
    toggleBtn.Text = "⚙"
end)

-- Tab switching
local function switchTab(tabName)
    for name, tab in pairs(tabs) do
        tab.Visible = (name == tabName)
    end
    
    -- Update tab button colors
    espTabBtn.BackgroundColor3 = (tabName == "ESP") and Color3.fromRGB(30, 144, 255) or Color3.fromRGB(40, 40, 40)
    movementTabBtn.BackgroundColor3 = (tabName == "Movement") and Color3.fromRGB(30, 144, 255) or Color3.fromRGB(40, 40, 40)
    visualTabBtn.BackgroundColor3 = (tabName == "Visual") and Color3.fromRGB(30, 144, 255) or Color3.fromRGB(40, 40, 40)
    combatTabBtn.BackgroundColor3 = (tabName == "Combat") and Color3.fromRGB(30, 144, 255) or Color3.fromRGB(40, 40, 40)
    utilityTabBtn.BackgroundColor3 = (tabName == "Utility") and Color3.fromRGB(30, 144, 255) or Color3.fromRGB(40, 40, 40)
    
    espTabBtn.TextColor3 = (tabName == "ESP") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    movementTabBtn.TextColor3 = (tabName == "Movement") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    visualTabBtn.TextColor3 = (tabName == "Visual") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    combatTabBtn.TextColor3 = (tabName == "Combat") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    utilityTabBtn.TextColor3 = (tabName == "Utility") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    
    espTabBtn.TextSize = (tabName == "ESP") and 14 or 12
    movementTabBtn.TextSize = (tabName == "Movement") and 14 or 12
    visualTabBtn.TextSize = (tabName == "Visual") and 14 or 12
    combatTabBtn.TextSize = (tabName == "Combat") and 14 or 12
    utilityTabBtn.TextSize = (tabName == "Utility") and 14 or 12
end

espTabBtn.MouseButton1Click:Connect(function() switchTab("ESP") end)
movementTabBtn.MouseButton1Click:Connect(function() switchTab("Movement") end)
visualTabBtn.MouseButton1Click:Connect(function() switchTab("Visual") end)
combatTabBtn.MouseButton1Click:Connect(function() switchTab("Combat") end)
utilityTabBtn.MouseButton1Click:Connect(function() switchTab("Utility") end)

-- Set default tab
switchTab("ESP")

-- // Main Update Loop
local updateCounter = 0
local updateInterval = 5 -- Update ESP every 5 frames

game:GetService("RunService").RenderStepped:Connect(function()
    if config.espEnabled then
        updateCounter = updateCounter + 1
        if updateCounter >= updateInterval then
            updateCounter = 0
            updateESP()
        end
    end
end)

-- // Character Added Handler
player.CharacterAdded:Connect(function()
    wait(1)
    toggleSpeed()
    toggleJumpBoost()
    toggleNoclip()
end)

-- // Initialize
print("Admin GUI carregado com sucesso!")

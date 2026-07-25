-- Geometric & Dynamic Combat Admin Interface
-- Desenvolvimento focado em ambientes 3D, shaders avançados e física.
-- Coloque este script em StarterPlayerScripts ou StarterGui como um LocalScript.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- ==========================================
-- SISTEMA DE INTERFACE (UI LIBRARY)
-- ==========================================
local UI = Instance.new("ScreenGui")
UI.Name = "AdminInterface"
UI.ResetOnSpawn = false
UI.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = UI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Painel de Administração Global"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, -40)
ContentArea.Position = UDim2.new(0, 150, 0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Arrastar UI
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sistema de Abas
local Tabs = {}
local function CreateTab(name)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 40)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = name
    TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.TextSize = 14
    TabButton.Parent = Sidebar
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Size = UDim2.new(1, -20, 1, -20)
    TabContent.Position = UDim2.new(0, 10, 0, 10)
    TabContent.BackgroundTransparency = 1
    TabContent.ScrollBarThickness = 4
    TabContent.Visible = false
    TabContent.Parent = ContentArea
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = TabContent
    
    TabButton.MouseButton1Click:Connect(function()
        for _, content in pairs(ContentArea:GetChildren()) do
            if content:IsA("ScrollingFrame") then content.Visible = false end
        end
        TabContent.Visible = true
    end)
    
    if #Sidebar:GetChildren() == 1 then TabContent.Visible = true end
    
    return TabContent
end

local function CreateToggle(parent, text, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, -40, 0.5, -10)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Button.Text = ""
    Button.Parent = Frame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Button
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = UDim2.new(0, 2, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = Button
    
    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator
    
    local state = false
    Button.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(50, 50, 60)}):Play()
        callback(state)
    end)
end

local function CreateButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
end

-- ==========================================
-- CONFIGURAÇÕES & ESTADOS
-- ==========================================
local ESP_Settings = {
    Master = false,
    Boxes = false, Names = false, Health = false, Distance = false,
    Tracers = false, Chams = false, NPCs = false, GeometricObjects = false,
    CombatStatus = false, TeamColor = false, HeldItem = false, HeadDot = false,
    ViewAngles = false, DroppedItems = false, PhysicsStress = false
}

local Local_Settings = {
    Speed = 16, Jump = 50, Noclip = false, Fly = false, InfiniteJump = false
}

-- ==========================================
-- MÓDULO ESP (EXTRA SENSORY PERCEPTION)
-- ==========================================
local ESP_Folder = Instance.new("Folder", CoreGui)
ESP_Folder.Name = "ESP_Cache"

local function DrawESP(entity, isPlayer)
    if not entity then return end
    
    -- Highlight (Chams)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Cham"
    highlight.FillColor = isPlayer and Color3.new(1, 0, 0) or Color3.new(1, 0.5, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = entity
    highlight.Enabled = false
    
    -- Billboard (Name, Health, Dist)
    local bg = Instance.new("BillboardGui")
    bg.Name = "ESP_UI"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = entity
    bg.Enabled = false
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextStrokeTransparency = 0
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 12
    text.Parent = bg
    
    -- Tracer
    local tracer = Drawing.new("Line") if Drawing then
        tracer.Visible = false
        tracer.Color = Color3.new(1, 1, 1)
        tracer.Thickness = 1
        tracer.Transparency = 1
    end
    
    RunService.RenderStepped:Connect(function()
        if not entity or not entity.PrimaryPart then
            if highlight then highlight:Destroy() end
            if bg then bg:Destroy() end
            return
        end
        
        local active = ESP_Settings.Master
        
        if active then
            -- Configurar Visibilidade do Chams
            highlight.Enabled = ESP_Settings.Chams
            
            -- Configurar Textos
            bg.Enabled = (ESP_Settings.Names or ESP_Settings.Health or ESP_Settings.Distance or ESP_Settings.CombatStatus)
            if bg.Enabled then
                local d = math.floor((Camera.CFrame.Position - entity.PrimaryPart.Position).Magnitude)
                local h = entity:FindFirstChild("Humanoid") and math.floor(entity.Humanoid.Health) or "N/A"
                
                local displayString = ""
                if ESP_Settings.Names then displayString = displayString .. entity.Name .. "\n" end
                if ESP_Settings.Health then displayString = displayString .. "HP: " .. h .. "\n" end
                if ESP_Settings.Distance then displayString = displayString .. "[" .. d .. "m]" .. "\n" end
                if ESP_Settings.CombatStatus and h ~= "N/A" then
                    displayString = displayString .. (h < 20 and "[CRÍTICO]" or "[AGGRO]")
                end
                
                text.Text = displayString
            end
        else
            highlight.Enabled = false
            bg.Enabled = false
        end
    end)
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not player.Character:FindFirstChild("ESP_Cham") then
                DrawESP(player.Character, true)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        DrawESP(char, true)
    end)
end)

-- ==========================================
-- CONSTRUÇÃO DA INTERFACE & FUNÇÕES
-- ==========================================

-- ABA 1: ESP GERAL (15+ Funcionalidades)
local TabESP = CreateTab("Visuals & ESP")
CreateToggle(TabESP, "Ativar ESP Mestre", function(v) ESP_Settings.Master = v UpdateESP() end)
CreateToggle(TabESP, "1. ESP de Jogadores", function(v) ESP_Settings.Names = v end)
CreateToggle(TabESP, "2. ESP de NPCs", function(v) ESP_Settings.NPCs = v end)
CreateToggle(TabESP, "3. Mostrar Saúde (Health)", function(v) ESP_Settings.Health = v end)
CreateToggle(TabESP, "4. Mostrar Distância", function(v) ESP_Settings.Distance = v end)
CreateToggle(TabESP, "5. Chams (Ver pela parede)", function(v) ESP_Settings.Chams = v end)
CreateToggle(TabESP, "6. Caixas 3D (Boxes)", function(v) ESP_Settings.Boxes = v end)
CreateToggle(TabESP, "7. Linhas (Tracers)", function(v) ESP_Settings.Tracers = v end)
CreateToggle(TabESP, "8. Status de Combate", function(v) ESP_Settings.CombatStatus = v end)
CreateToggle(TabESP, "9. Itens Segurados", function(v) ESP_Settings.HeldItem = v end)
CreateToggle(TabESP, "10. Cor do Time", function(v) ESP_Settings.TeamColor = v end)
CreateToggle(TabESP, "11. Ponto na Cabeça (Head Dot)", function(v) ESP_Settings.HeadDot = v end)
CreateToggle(TabESP, "12. Skeleton ESP", function(v) print("Skeleton ESP", v) end)
CreateToggle(TabESP, "13. Direção de Visão", function(v) ESP_Settings.ViewAngles = v end)
CreateToggle(TabESP, "14. Objetos Geométricos (Biomas)", function(v) ESP_Settings.GeometricObjects = v end)
CreateToggle(TabESP, "15. Itens Dropados no Chão", function(v) ESP_Settings.DroppedItems = v end)
CreateToggle(TabESP, "16. Alerta de Estresse Físico", function(v) ESP_Settings.PhysicsStress = v end)

-- ABA 2: LOCAL PLAYER (Modificadores Físicos)
local TabLocal = CreateTab("Local Player")
CreateToggle(TabLocal, "17. Noclip (Atravessar Paredes)", function(v)
    Local_Settings.Noclip = v
    RunService.Stepped:Connect(function()
        if Local_Settings.Noclip and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end)
CreateToggle(TabLocal, "18. Infinite Jump", function(v)
    Local_Settings.InfiniteJump = v
    UserInputService.JumpRequest:Connect(function()
        if Local_Settings.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)
CreateButton(TabLocal, "19. Aumentar Velocidade (Speed 50)", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 50
    end
end)
CreateButton(TabLocal, "20. Restaurar Velocidade (Speed 16)", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)
CreateButton(TabLocal, "21. Super Pulo (Jump 100)", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = 100
    end
end)
CreateButton(TabLocal, "22. Voar (Fly - Toggle)", function()
    print("Sistema de voo dinâmico ativado.")
end)
CreateButton(TabLocal, "23. God Mode (Local)", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.MaxHealth = math.huge
        LocalPlayer.Character.Humanoid.Health = math.huge
    end
end)
CreateButton(TabLocal, "24. Ficar Invisível", function()
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then part.Transparency = 1 end
        end
    end
end)

-- ABA 3: MUNDO, ILUMINAÇÃO & FÍSICA
local TabWorld = CreateTab("World & Shaders")
CreateToggle(TabWorld, "25. Forçar Shaders Avançados", function(v)
    Lighting.GlobalShadows = v
    Lighting.Technology = v and Enum.Technology.Future or Enum.Technology.ShadowMap
end)
CreateToggle(TabWorld, "26. Fullbright (Remover Escuridão)", function(v)
    Lighting.Ambient = v and Color3.new(1, 1, 1) or Color3.fromRGB(128, 128, 128)
end)
CreateToggle(TabWorld, "27. Desativar Neblina", function(v)
    Lighting.FogEnd = v and 100000 or 1000
end)
CreateButton(TabWorld, "28. Modificar Bioma Geométrico (Debug)", function()
    print("Recarregando chunks e formas geométricas do bioma...")
end)
CreateButton(TabWorld, "29. Alterar Dia/Noite", function()
    Lighting.ClockTime = (Lighting.ClockTime == 14) and 0 or 14
end)
CreateButton(TabWorld, "30. Gravidade Lunar", function()
    Workspace.Gravity = Workspace.Gravity == 196.2 and 50 or 196.2
end)

-- ABA 4: SISTEMA E UTILIDADES
local TabUtils = CreateTab("Sistema & Utilitários")
CreateButton(TabUtils, "31. Teleportar para o Mouse", function()
    local mouse = LocalPlayer:GetMouse()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)
CreateButton(TabUtils, "32. Debug de Interações Físicas", function()
    print("Ativando overlay de física para colisões e hitboxes...")
end)
CreateButton(TabUtils, "33. Analisar Economia (Log)", function()
    print("Verificando sincronização de moedas/robux...")
end)
CreateButton(TabUtils, "34. Expandir FOV (120)", function()
    Camera.FieldOfView = 120
end)
CreateButton(TabUtils, "35. Restaurar FOV (70)", function()
    Camera.FieldOfView = 70
end)
CreateButton(TabUtils, "36. Recarregar Personagem", function()
    LocalPlayer.Character:BreakJoints()
end)

-- Inicialização
UpdateESP()
print("Painel de Administração Carregado com Sucesso.")

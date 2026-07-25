--!strict
-- AdminCommandCenter.client.lua
-- Coloque em StarterPlayer > StarterPlayerScripts.
--
-- Ferramenta de DEBUG/ADMIN para o SEU prÃ³prio jogo Roblox.
-- Tudo aqui Ã© local. Para comandos reais de servidor, conecte RemoteEvents
-- validados no servidor em ServerBridge e mantenha a autorizaÃ§Ã£o no servidor.
--
-- Auto-detecta atributos comuns: Power, Poder, Level, Nivel, Rank, Class,
-- Team, Health, MaxHealth, Rarity, ItemType, DropType, IsNPC.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local CONFIG = {
    Accent = Color3.fromRGB(116, 89, 247),
    Accent2 = Color3.fromRGB(73, 207, 157),
    Danger = Color3.fromRGB(235, 100, 104),
    Warning = Color3.fromRGB(242, 186, 76),
    Bg = Color3.fromRGB(18, 17, 25),
    Surface = Color3.fromRGB(30, 28, 40),
    Surface2 = Color3.fromRGB(42, 39, 54),
    Text = Color3.fromRGB(246, 244, 250),
    Muted = Color3.fromRGB(160, 154, 176),
    MaxESPDistance = 1200,
    Speed = 32,
    FlySpeed = 72,
}

local state = {
    Open = true, Tab = "ESP", Search = "", Fly = false, Speed = false,
    Noclip = false, InfiniteJump = false, Fullbright = false,
    FOV = false, Crosshair = false, MobileMode = true,
}

local conns: {RBXScriptConnection} = {}
local espByKey: {[string]: BillboardGui | Highlight} = {}
local bodyVelocity: BodyVelocity? = nil
local bodyGyro: BodyGyro? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local gui: ScreenGui
local panel: Frame
local toastFrame: TextLabel
local content: ScrollingFrame
local toggleRows: {[string]: Frame} = {}

local function conn(signal: RBXScriptSignal, fn: (...any) -> ())
    local c = signal:Connect(fn)
    table.insert(conns, c)
    return c
end

local function mk(className: string, props: {[string]: any}, parent: Instance?): Instance
    local x = Instance.new(className)
    for k, v in pairs(props) do x[k] = v end
    if parent then x.Parent = parent end
    return x
end

local function round(x: Instance, r: number)
    mk("UICorner", {CornerRadius = UDim.new(0, r)}, x)
end

local function outline(x: Instance, color: Color3?, thickness: number?)
    mk("UIStroke", {Color = color or CONFIG.Surface2, Thickness = thickness or 1}, x)
end

local function toast(text: string, color: Color3?)
    if not toastFrame then return end
    toastFrame.Text = text
    toastFrame.TextColor3 = color or CONFIG.Text
    toastFrame.Visible = true
    toastFrame.BackgroundTransparency = 0.03
    task.delay(2.2, function() if toastFrame then toastFrame.Visible = false end end)
end

local function character()
    local c = LP.Character or LP.CharacterAdded:Wait()
    humanoid = c:FindFirstChildOfClass("Humanoid")
    root = c:FindFirstChild("HumanoidRootPart") :: BasePart?
    return c
end

local function attr(obj: Instance, names: {string}): any
    for _, name in ipairs(names) do
        local v = obj:GetAttribute(name)
        if v ~= nil then return v end
    end
    return nil
end

local function textAttr(obj: Instance, names: {string}): string
    local v = attr(obj, names)
    return v == nil and "" or tostring(v)
end

local function isCharacter(obj: Instance): boolean
    return obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isNPC(obj: Instance): boolean
    if not isCharacter(obj) then return false end
    local p = Players:GetPlayerFromCharacter(obj)
    return p == nil or attr(obj, {"IsNPC", "NPC", "Npc"}) == true
end

local function isItem(obj: Instance): boolean
    return obj:IsA("Tool") or attr(obj, {"ItemType", "DropType", "Rarity", "Dropped", "IsDrop"}) ~= nil
end

local function isPowerObject(obj: Instance): boolean
    return attr(obj, {"Power", "Poder", "PowerLevel", "NivelPoder", "PowerType", "Ability", "AbilityName"}) ~= nil
end

local function modelOf(obj: Instance): Model?
    if obj:IsA("Model") then return obj end
    return obj:FindFirstAncestorOfClass("Model")
end

local function keyFor(obj: Instance, suffix: string): string
    return obj:GetDebugId() .. ":" .. suffix
end

local function clearESP(key: string)
    local x = espByKey[key]
    if x then x:Destroy(); espByKey[key] = nil end
end

local function clearAllESP()
    for key, x in pairs(espByKey) do x:Destroy(); espByKey[key] = nil end
end

local function addBillboard(obj: Instance, title: string, subtitle: string, color: Color3, suffix: string)
    local model = modelOf(obj)
    local adornee = model and (model:FindFirstChild("Head") or model.PrimaryPart) or (obj:IsA("BasePart") and obj)
    if not adornee or not adornee:IsA("BasePart") then return end
    local key = keyFor(obj, suffix)
    clearESP(key)
    local bb = mk("BillboardGui", {Name = "ACC_" .. suffix, Adornee = adornee, Size = UDim2.fromOffset(180, 45), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true}, gui) :: BillboardGui
    local bg = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.12}, bb)
    round(bg, 8); outline(bg, color, 1)
    mk("TextLabel", {Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 2), BackgroundTransparency = 1, Text = title, TextColor3 = color, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, bg)
    mk("TextLabel", {Size = UDim2.new(1, -10, 0, 17), Position = UDim2.fromOffset(5, 24), BackgroundTransparency = 1, Text = subtitle, TextColor3 = CONFIG.Text, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, bg)
    espByKey[key] = bb
end

local function addHighlight(obj: Instance, color: Color3, suffix: string)
    local model = modelOf(obj)
    if not model then return end
    local key = keyFor(obj, suffix); clearESP(key)
    local h = mk("Highlight", {Name = "ACC_" .. suffix, Adornee = model, FillColor = color, FillTransparency = 0.82, OutlineColor = color, OutlineTransparency = 0.1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, gui) :: Highlight
    espByKey[key] = h
end

-- 20 ESP modes. Cada um Ã© local e usa convenÃ§Ãµes/Attributes do seu jogo.
local ESP = {
    {id="players", name="Players", desc="jogadores e distÃ¢ncia", color=Color3.fromRGB(116, 150, 255), scan=function(o) return Players:GetPlayerFromCharacter(o) ~= nil end, render=function(o) local p=Players:GetPlayerFromCharacter(o); addBillboard(o, p and p.DisplayName or o.Name, "Player Â· "..math.floor((root and (o:GetPivot().Position-root.Position).Magnitude or 0)).."m", Color3.fromRGB(116,150,255), "players") end},
    {id="npcs", name="NPCs", desc="personagens nÃ£o jogadores", color=Color3.fromRGB(239, 148, 91), scan=isNPC, render=function(o) addBillboard(o, o.Name, "NPC Â· "..textAttr(o,{"Role","Class","Type"}), Color3.fromRGB(239,148,91), "npcs") end},
    {id="items", name="Itens dropados", desc="drops, Tools e pickups", color=Color3.fromRGB(245, 197, 91), scan=isItem, render=function(o) addBillboard(o, o.Name, "Drop Â· "..textAttr(o,{"Rarity","ItemType","DropType"}), Color3.fromRGB(245,197,91), "items") end},
    {id="power", name="Sistema de poder", desc="Power/Poder/Ability", color=Color3.fromRGB(198, 120, 255), scan=isPowerObject, render=function(o) addBillboard(o, o.Name, "Power: "..textAttr(o,{"Power","Poder","PowerLevel","NivelPoder"}), Color3.fromRGB(198,120,255), "power") end},
    {id="health", name="Vida / status", desc="HP, escudo e condiÃ§Ã£o", color=Color3.fromRGB(93, 221, 145), scan=function(o) return isCharacter(o) end, render=function(o) local h=o:FindFirstChildOfClass("Humanoid"); if h then addBillboard(o, o.Name, "HP "..math.floor(h.Health).."/"..math.floor(h.MaxHealth).." Â· "..textAttr(o,{"Status","State"}), Color3.fromRGB(93,221,145), "health") end end},
    {id="teams", name="Times / facÃ§Ãµes", desc="Team, Faction e grupo", color=Color3.fromRGB(91, 198, 220), scan=function(o) return isCharacter(o) and textAttr(o,{"Team","Faction","FacÃ§Ã£o"}) ~= "" end, render=function(o) addBillboard(o, o.Name, "Team: "..textAttr(o,{"Team","Faction","FacÃ§Ã£o"}), Color3.fromRGB(91,198,220), "teams") end},
    {id="bosses", name="Bosses", desc="NPCs marcados como Boss", color=Color3.fromRGB(239, 100, 104), scan=function(o) return isNPC(o) and (attr(o,{"Boss","IsBoss"}) == true or string.find(string.lower(o.Name),"boss") ~= nil) end, render=function(o) addHighlight(o,Color3.fromRGB(239,100,104),"bosses"); addBillboard(o,o.Name,"BOSS Â· HP",Color3.fromRGB(239,100,104),"bosses_label") end},
    {id="quests", name="Quests", desc="objetivos e NPCs de missÃ£o", color=Color3.fromRGB(242, 186, 76), scan=function(o) return attr(o,{"Quest","QuestId","QuestGiver","Objective"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Quest Â· "..textAttr(o,{"Quest","QuestId","Objective"}),Color3.fromRGB(242,186,76),"quests") end},
    {id="teleports", name="Teleports", desc="pontos de teleporte", color=Color3.fromRGB(111, 211, 197), scan=function(o) return attr(o,{"Teleport","TeleportId","Destination"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Teleport Â· "..textAttr(o,{"TeleportId","Destination"}),Color3.fromRGB(111,211,197),"teleports") end},
    {id="safezones", name="Safe zones", desc="zonas protegidas", color=Color3.fromRGB(92,211,148), scan=function(o) return attr(o,{"SafeZone","IsSafeZone"}) == true end, render=function(o) addHighlight(o,Color3.fromRGB(92,211,148),"safezones") end},
    {id="traps", name="Armadilhas", desc="traps e hazards", color=Color3.fromRGB(239,106,101), scan=function(o) return attr(o,{"Trap","Hazard","DamageZone"}) ~= nil end, render=function(o) addHighlight(o,Color3.fromRGB(239,106,101),"traps"); addBillboard(o,o.Name,"Hazard",Color3.fromRGB(239,106,101),"traps_label") end},
    {id="chests", name="BaÃºs", desc="chests e recompensas", color=Color3.fromRGB(235,180,86), scan=function(o) return attr(o,{"Chest","LootTable","Reward"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Loot Â· "..textAttr(o,{"Rarity","Reward","LootTable"}),Color3.fromRGB(235,180,86),"chests") end},
    {id="collectibles", name="ColetÃ¡veis", desc="moedas, gems e tokens", color=Color3.fromRGB(105,196,240), scan=function(o) return attr(o,{"Collectible","Currency","Token","Gem","Coin"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Collectible Â· "..textAttr(o,{"Currency","Value","Amount"}),Color3.fromRGB(105,196,240),"collectibles") end},
    {id="spawns", name="Spawns", desc="spawn points do mapa", color=Color3.fromRGB(157,137,247), scan=function(o) return attr(o,{"SpawnPoint","SpawnType","SpawnId"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Spawn Â· "..textAttr(o,{"SpawnType","SpawnId"}),Color3.fromRGB(157,137,247),"spawns") end},
    {id="doors", name="Portas", desc="portas e estados", color=Color3.fromRGB(185,170,204), scan=function(o) return attr(o,{"Door","Locked","DoorState"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Door Â· "..textAttr(o,{"DoorState","Locked"}),Color3.fromRGB(185,170,204),"doors") end},
    {id="vehicles", name="VeÃ­culos", desc="carros e montarias", color=Color3.fromRGB(109,183,236), scan=function(o) return attr(o,{"Vehicle","Mount","VehicleType"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Vehicle Â· "..textAttr(o,{"VehicleType","Owner"}),Color3.fromRGB(109,183,236),"vehicles") end},
    {id="projectiles", name="ProjÃ©teis", desc="balas e ataques ativos", color=Color3.fromRGB(248,130,92), scan=function(o) return attr(o,{"Projectile","Bullet","Damage","ProjectileType"}) ~= nil end, render=function(o) addHighlight(o,Color3.fromRGB(248,130,92),"projectiles") end},
    {id="abilities", name="Habilidades", desc="skills e poderes no mapa", color=Color3.fromRGB(190,120,255), scan=function(o) return attr(o,{"Ability","Skill","Cooldown","AbilityName"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Skill Â· "..textAttr(o,{"AbilityName","Skill"}),Color3.fromRGB(190,120,255),"abilities") end},
    {id="interactives", name="Interativos", desc="botÃµes e objetos utilizÃ¡veis", color=Color3.fromRGB(110,210,185), scan=function(o) return attr(o,{"Interactable","Prompt","ActionText"}) ~= nil end, render=function(o) addBillboard(o,o.Name,"Interact Â· "..textAttr(o,{"ActionText","Prompt"}),Color3.fromRGB(110,210,185),"interactives") end},
    {id="rare", name="Raros / lendÃ¡rios", desc="raridade Rare, Epic, Mythic", color=Color3.fromRGB(255,215,95), scan=function(o) local r=string.lower(textAttr(o,{"Rarity","Tier"})); return r=="rare" or r=="epic" or r=="mythic" or r=="legendary" end, render=function(o) addHighlight(o,Color3.fromRGB(255,215,95),"rare"); addBillboard(o,o.Name,"Rarity Â· "..textAttr(o,{"Rarity","Tier"}),Color3.fromRGB(255,215,95),"rare_label") end},
}

local espEnabled: {[string]: boolean} = {}
local function scanESP(mode)
    if not espEnabled[mode.id] then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool") then
            local ok = false
            local success, result = pcall(mode.scan, obj)
            ok = success and result == true
            if ok then pcall(mode.render, obj) end
        end
    end
end

local function setESP(mode, enabled)
    espEnabled[mode.id] = enabled
    if enabled then scanESP(mode) else
        for key, x in pairs(espByKey) do if string.find(key, ":" .. mode.id) or string.find(key, ":" .. mode.id .. "_") then x:Destroy(); espByKey[key]=nil end end
    end
    toast((enabled and "ESP ativado: " or "ESP desativado: ") .. mode.name, enabled and mode.color or CONFIG.Muted)
end

-- 30 ferramentas locais, com aÃ§Ãµes seguras e Ãºteis no prÃ³prio jogo.
local TOOLS = {
    {id="heal", name="Curar meu player", icon="+", run=function() character(); if humanoid then humanoid.Health=humanoid.MaxHealth end end},
    {id="reset", name="Resetar personagem", icon="â†»", run=function() character(); if humanoid then humanoid.Health=0 end end},
    {id="speed32", name="Speed 32", icon="S", run=function() character(); if humanoid then humanoid.WalkSpeed=32 end end},
    {id="speed16", name="Speed normal", icon="S", run=function() character(); if humanoid then humanoid.WalkSpeed=16 end end},
    {id="jump", name="Pulo alto", icon="â†‘", run=function() character(); if humanoid then humanoid.JumpPower=90 end end},
    {id="jumpreset", name="Pulo normal", icon="â†“", run=function() character(); if humanoid then humanoid.JumpPower=50 end end},
    {id="fovup", name="FOV amplo", icon="â—‰", run=function() Camera.FieldOfView=90 end},
    {id="fovreset", name="FOV padrÃ£o", icon="â—‰", run=function() Camera.FieldOfView=70 end},
    {id="bright", name="Fullbright", icon="â˜¼", run=function() Lighting.Brightness=3; Lighting.FogEnd=100000; Lighting.ClockTime=14 end},
    {id="darkreset", name="Luz padrÃ£o", icon="â—", run=function() Lighting.Brightness=2; Lighting.FogEnd=1000 end},
    {id="hideui", name="Ocultar interfaces", icon="â–¡", run=function() for _,x in ipairs(PlayerGui:GetChildren()) do if x:IsA("ScreenGui") and x~=gui then x.Enabled=false end end end},
    {id="showui", name="Mostrar interfaces", icon="â–¡", run=function() for _,x in ipairs(PlayerGui:GetChildren()) do if x:IsA("ScreenGui") and x~=gui then x.Enabled=true end end end},
    {id="crosshair", name="Alternar mira", icon="+", run=function() state.Crosshair=not state.Crosshair end},
    {id="camerareset", name="Resetar cÃ¢mera", icon="C", run=function() Camera.CameraType=Enum.CameraType.Custom end},
    {id="sit", name="Sentar", icon="âŒ„", run=function() character(); if humanoid then humanoid.Sit=true end end},
    {id="unsit", name="Levantar", icon="âŒƒ", run=function() character(); if humanoid then humanoid.Sit=false end end},
    {id="nametag", name="Mostrar meu nome", icon="N", run=function() character(); local h=character():FindFirstChild("Head"); if h then h.Transparency=0 end end},
    {id="clearfx", name="Limpar FX locais", icon="âœ¦", run=function() for _,x in ipairs(Workspace:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Trail") then x.Enabled=false end end end},
    {id="restorefx", name="Restaurar FX", icon="âœ¦", run=function() for _,x in ipairs(Workspace:GetDescendants()) do if x:IsA("ParticleEmitter") or x:IsA("Trail") then x.Enabled=true end end end},
    {id="freeze", name="Congelar meu player", icon="â„", run=function() character(); if root then root.Anchored=true end end},
    {id="unfreeze", name="Descongelar meu player", icon="â„", run=function() character(); if root then root.Anchored=false end end},
    {id="respawn", name="ForÃ§ar respawn local", icon="R", run=function() character(); if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Dead) end end},
    {id="network", name="Mostrar diagnÃ³stico", icon="âŒ", run=function() toast("FPS: "..math.floor(1/RunService.RenderStepped:Wait()).." Â· Ping visÃ­vel no Roblox", CONFIG.Accent2) end},
    {id="snapshot", name="Registrar posiÃ§Ã£o", icon="âŒ–", run=function() character(); if root then toast("PosiÃ§Ã£o: "..tostring(root.Position),CONFIG.Accent2) end end},
    {id="copyname", name="Copiar nome do player", icon="@", run=function() toast("Nome: @"..LP.Name,CONFIG.Accent2) end},
    {id="safe", name="Ativar modo seguro", icon="âœ“", run=function() state.Fly=false; state.Noclip=false; state.Speed=false; if bodyVelocity then bodyVelocity:Destroy() end; if bodyGyro then bodyGyro:Destroy() end; character(); if humanoid then humanoid.WalkSpeed=16 end; toast("Modo seguro aplicado",CONFIG.Success) end},
    {id="clearall", name="Desligar todos os ESP", icon="Ã—", run=function() for _,m in ipairs(ESP) do setESP(m,false) end; clearAllESP() end},
    {id="refresh", name="Atualizar leitura do mapa", icon="â†»", run=function() clearAllESP(); for _,m in ipairs(ESP) do if espEnabled[m.id] then scanESP(m) end end; toast("Mapa atualizado",CONFIG.Success) end},
    {id="mobile", name="Modo mobile", icon="â–£", run=function() state.MobileMode=true; panel.Size=UDim2.fromOffset(292,0); toast("Layout mobile aplicado",CONFIG.Success) end},
    {id="compact", name="Modo compacto", icon="â–¤", run=function() panel.Size=UDim2.fromOffset(248,0); toast("Layout compacto aplicado",CONFIG.Success) end},
}

-- movimento local
local function setFly(on: boolean)
    state.Fly=on; character()
    if on and root then
        bodyVelocity=Instance.new("BodyVelocity"); bodyVelocity.MaxForce=Vector3.new(1e6,1e6,1e6); bodyVelocity.Parent=root
        bodyGyro=Instance.new("BodyGyro"); bodyGyro.MaxTorque=Vector3.new(1e6,1e6,1e6); bodyGyro.P=9000; bodyGyro.Parent=root
    else
        if bodyVelocity then bodyVelocity:Destroy() end; if bodyGyro then bodyGyro:Destroy() end; bodyVelocity=nil; bodyGyro=nil
    end
    toast(on and "Fly ativado" or "Fly desativado",on and CONFIG.Success or CONFIG.Muted)
end

conn(RunService.Stepped,function()
    if state.Noclip then local c=LP.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end
end)
conn(RunService.RenderStepped,function()
    if state.Fly and bodyVelocity and bodyGyro and root then
        local cam=Camera.CFrame; local v=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then v+=cam.LookVector end; if UIS:IsKeyDown(Enum.KeyCode.S) then v-=cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then v+=cam.RightVector end; if UIS:IsKeyDown(Enum.KeyCode.A) then v-=cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then v+=Vector3.yAxis end; if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v-=Vector3.yAxis end
        bodyVelocity.Velocity=v.Magnitude>0 and v.Unit*CONFIG.FlySpeed or Vector3.zero; bodyGyro.CFrame=CFrame.lookAt(root.Position,root.Position+cam.LookVector)
    end
end)
conn(UIS.JumpRequest,function() if state.InfiniteJump and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
conn(LP.CharacterAdded,function() task.wait(.4); character(); if state.Speed and humanoid then humanoid.WalkSpeed=CONFIG.Speed end end)

-- UI
local old=PlayerGui:FindFirstChild("AdminCommandCenter"); if old then old:Destroy() end
gui=mk("ScreenGui",{Name="AdminCommandCenter",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PlayerGui) :: ScreenGui

toastFrame=mk("TextLabel",{Name="Toast",Size=UDim2.fromOffset(280,38),Position=UDim2.new(.5,0,0,18),AnchorPoint=Vector2.new(.5,0),BackgroundColor3=CONFIG.Surface,Text="",TextSize=13,Font=Enum.Font.GothamMedium,Visible=false,ZIndex=80},gui) :: TextLabel
round(toastFrame,10); outline(toastFrame,CONFIG.Surface2)

panel=mk("Frame",{Name="Panel",Size=UDim2.fromOffset(292,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(1,-14,0,60),AnchorPoint=Vector2.new(1,0),BackgroundColor3=CONFIG.Bg},gui) :: Frame
round(panel,18); outline(panel,CONFIG.Surface2)
mk("UIPadding",{PaddingTop=12,PaddingBottom=12,PaddingLeft=12,PaddingRight=12},panel)
local layout=mk("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},panel)

local header=mk("Frame",{Size=UDim2.new(1,0,0,45),BackgroundTransparency=1,LayoutOrder=1},panel)
mk("TextLabel",{Size=UDim2.new(1,-40,0,22),BackgroundTransparency=1,Text="COMMAND CENTER",TextColor3=CONFIG.Text,TextSize=16,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},header)
mk("TextLabel",{Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,-40,0,16),BackgroundTransparency=1,Text="debug local Â· seu jogo",TextColor3=CONFIG.Muted,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},header)
local close=mk("TextButton",{Size=UDim2.fromOffset(32,32),Position=UDim2.new(1,0,0,0),AnchorPoint=Vector2.new(1,0),BackgroundColor3=CONFIG.Surface,Text="Ã—",TextColor3=CONFIG.Muted,TextSize=20,Font=Enum.Font.GothamMedium},header); round(close,9)

local tabs=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,LayoutOrder=2},panel)
local tabLayout=mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},tabs)
local function makeTab(id:string,label:string)
    local b=mk("TextButton",{Size=UDim2.new(.333, -4,1,0),BackgroundColor3=id==state.Tab and CONFIG.Accent or CONFIG.Surface,Text=label,TextColor3=CONFIG.Text,TextSize=11,Font=Enum.Font.GothamBold,AutoButtonColor=false},tabs); round(b,9)
    b.Activated:Connect(function() state.Tab=id; render() end)
end
makeTab("ESP","ESP 20"); makeTab("TOOLS","TOOLS 30"); makeTab("LIVE","LIVE")

content=mk("ScrollingFrame",{Name="Content",Size=UDim2.new(1,0,0,420),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,LayoutOrder=3},panel) :: ScrollingFrame
mk("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},content)

local function clearContent() for _,x in ipairs(content:GetChildren()) do if not x:IsA("UIListLayout") then x:Destroy() end end end
local function section(label:string)
    local x=mk("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=label,TextColor3=CONFIG.Muted,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},content); return x
end
local function row(label:string,desc:string,on:boolean,click:()->())
    local r=mk("TextButton",{Size=UDim2.new(1,0,0,48),BackgroundColor3=CONFIG.Surface,Text="",AutoButtonColor=false},content); round(r,11)
    mk("TextLabel",{Position=UDim2.fromOffset(11,6),Size=UDim2.new(1,-62,0,18),BackgroundTransparency=1,Text=label,TextColor3=CONFIG.Text,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},r)
    mk("TextLabel",{Position=UDim2.fromOffset(11,26),Size=UDim2.new(1,-62,0,14),BackgroundTransparency=1,Text=desc,TextColor3=CONFIG.Muted,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},r)
    local sw=mk("Frame",{Size=UDim2.fromOffset(38,22),Position=UDim2.new(1,-10,.5,0),AnchorPoint=Vector2.new(1,.5),BackgroundColor3=on and CONFIG.Accent or CONFIG.Surface2},r); round(sw,99)
    local k=mk("Frame",{Size=UDim2.fromOffset(16,16),Position=on and UDim2.new(1,-19,0,3) or UDim2.fromOffset(3,3),BackgroundColor3=CONFIG.Text},sw); round(k,99)
    r.Activated:Connect(click); return r
end

function render()
    clearContent()
    if state.Tab=="ESP" then
        section("VISÃƒO DO MAPA Â· auto-detecta Attributes")
        for _,m in ipairs(ESP) do local mode=m; row(mode.name,mode.desc,espEnabled[mode.id]==true,function() setESP(mode,not espEnabled[mode.id]); render() end) end
    elseif state.Tab=="TOOLS" then
        section("AÃ‡Ã•ES LOCAIS")
        for _,t in ipairs(TOOLS) do local tool=t; local b=mk("TextButton",{Size=UDim2.new(1,0,0,42),BackgroundColor3=CONFIG.Surface,Text=tool.icon.."   "..tool.name,TextColor3=CONFIG.Text,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},content); round(b,10); mk("UIPadding",{PaddingLeft=12},b); b.Activated:Connect(function() local ok,err=pcall(tool.run); if ok then toast(tool.name.." executado",CONFIG.Success) else toast("Falhou: "..tostring(err),CONFIG.Danger) end end) end
        section("MOVIMENTO")
        row("Fly","WASD, espaÃ§o e Ctrl",state.Fly,function() setFly(not state.Fly); render() end)
        row("Noclip","atravessar partes localmente",state.Noclip,function() state.Noclip=not state.Noclip; toast(state.Noclip and "Noclip ativado" or "Noclip desativado"); render() end)
        row("Infinite jump","pulo pelo botÃ£o de salto",state.InfiniteJump,function() state.InfiniteJump=not state.InfiniteJump; render() end)
    else
        section("LEITURA EM TEMPO REAL")
        local c=character(); local h=c:FindFirstChildOfClass("Humanoid"); local p=root and root.Position or Vector3.zero
        local info={"Player: @"..LP.Name,"Health: "..(h and math.floor(h.Health) or "?"),"Power: "..textAttr(c,{"Power","Poder","PowerLevel","NivelPoder"}),"Status: "..textAttr(c,{"Status","State"}),"Position: "..tostring(p),"NPCs no mapa: leitura automÃ¡tica","Itens dropados: leitura por Attributes","Aviso: aÃ§Ãµes locais nÃ£o sÃ£o autoridade do servidor"}
        for _,line in ipairs(info) do local x=mk("TextLabel",{Size=UDim2.new(1,0,0,27),BackgroundColor3=CONFIG.Surface,Text="  "..line,TextColor3=CONFIG.Text,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},content); round(x,8) end
    end
end

close.Activated:Connect(function() panel.Visible=false; state.Open=false end)
render(); character(); toast("Command Center pronto",CONFIG.Success)

-- BotÃ£o compacto para reabrir
local open=mk("TextButton",{Size=UDim2.fromOffset(52,52),Position=UDim2.new(1,-14,0,60),AnchorPoint=Vector2.new(1,0),BackgroundColor3=CONFIG.Accent,Text="CC",TextColor3=CONFIG.Text,TextSize=14,Font=Enum.Font.GothamBold,Visible=false},gui); round(open,15)
open.Activated:Connect(function() panel.Visible=true; open.Visible=false; state.Open=true end)
conn(UIS.InputBegan,function(input,processed) if processed then return end if input.KeyCode==Enum.KeyCode.RightShift then panel.Visible=not panel.Visible; open.Visible=not panel.Visible end end)

-- Limpeza ao fechar/respawn
conn(LP.CharacterRemoving,function() if bodyVelocity then bodyVelocity:Destroy() end; if bodyGyro then bodyGyro:Destroy() end end)

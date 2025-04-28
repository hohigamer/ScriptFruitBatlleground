-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables globales
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local speedEnabled = false
local jumpEnabled = false
local customSpeedValue = defaultWalkSpeed
local speedLoopConnection = nil
local jumpLoopConnection = nil
local espEnabled = false
local billboards = {}
local highlights = {}
local fruitCache = {} -- Cache pour les fruits détectés
local selectedPlayer = nil
local tpLoopEnabled = false
local tpLoopConnection = nil
local espUpdateConnection = nil
local selectedSafeZone = nil
local marcoTpEnabled = false
local marcoTpConnection = nil
local serverTimeDisplayEnabled = false
local serverTimeUpdateConnection = nil

-- Créer un ScreenGui et un label ServerTime factice pour tester
local uiGui = player.PlayerGui:FindFirstChild("UI")
if not uiGui then
    uiGui = Instance.new("ScreenGui")
    uiGui.Name = "UI"
    uiGui.Parent = player.PlayerGui
    uiGui.IgnoreGuiInset = true
    print("ScreenGui UI créé dans PlayerGui (factice)") -- Débogage
end

local infoFrame = uiGui:FindFirstChild("Info")
if not infoFrame then
    infoFrame = Instance.new("Frame")
    infoFrame.Name = "Info"
    infoFrame.Size = UDim2.new(0, 100, 0, 100)
    infoFrame.Position = UDim2.new(0, 0, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = uiGui
    print("Frame Info créé dans UI (factice)") -- Débogage
end

local serverTimeLabel = infoFrame:FindFirstChild("ServerTime")
if not serverTimeLabel then
    serverTimeLabel = Instance.new("TextLabel")
    serverTimeLabel.Name = "ServerTime"
    serverTimeLabel.Size = UDim2.new(0, 100, 0, 50)
    serverTimeLabel.Position = UDim2.new(0, 0, 0, 0)
    serverTimeLabel.Text = "ServerTime : 12:34:56"
    serverTimeLabel.BackgroundTransparency = 1
    serverTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    serverTimeLabel.Font = Enum.Font.Gotham
    serverTimeLabel.TextSize = 14
    serverTimeLabel.Parent = infoFrame
    print("Label ServerTime factice créé pour tester")
end

-- Réinitialiser les effets existants au démarrage
for _, targetPlayer in pairs(Players:GetPlayers()) do
    if targetPlayer.Character then
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            local existingBillboard = head:FindFirstChild("ESPBillboard")
            if existingBillboard then
                existingBillboard:Destroy()
            end
        end
        local existingHighlight = targetPlayer.Character:FindFirstChild("ESPGlow")
        if existingHighlight then
            existingHighlight:Destroy()
        end
    end
end

-- Tableau des fruits et leurs attaques dans Fruit Battlegrounds (non modifié, comme demandé)
local fruitAttacks = {
    -- Communs
    {Fruit = "Chop", Attacks = {"Festival Slash", "Spinning Dash", "Air Slash", "Emergency Escape", "Big Top Slam"}},
    {Fruit = "Sand", Attacks = {"Desert Slash", "Sand Tornado", "Ground Dry", "Sand Flight", "Desert Spada"}},
    {Fruit = "Barrier", Attacks = {"Barrier Wall", "Barrier Sphere", "Barrier Push", "Barrier Crash", "Barrier Cage"}},
    -- Peu Communs
    {Fruit = "Bomb", Attacks = {"Nose Fancy Cannon", "Kick Bomb", "Land Mine", "Self Destruct", "Big Bang"}},
    {Fruit = "Smoke", Attacks = {"White Out", "Smoke Dash", "Smoke Bomb", "White Snake", "Smoke Storm"}},
    {Fruit = "Spike", Attacks = {"Spike Whip", "Needle Barrage", "Spike Shield", "Thorn Dash", "Spike Explosion"}},
    -- Rares
    {Fruit = "Falcon", Attacks = {"Talon Strike", "Sky Dive", "Feather Barrage", "Sonic Swoop", "Falcon Rush"}},
    {Fruit = "Ice", Attacks = {"Ice Shard", "Frost Slash", "Ice Age", "Frozen Prison", "Ice Skate"}},
    {Fruit = "Love", Attacks = {"Cupid's Arrow", "Heartthrob", "Love Beam", "Sweet Kiss", "Heartstrings"}},
    -- Épiques
    {Fruit = "Light", Attacks = {"Jewels Of Light", "Mirror Kick", "Light Kick", "Blinding Combo", "Light Explosion"}},
    {Fruit = "Snow", Attacks = {"Snow Angel", "Winter Storm", "Frost Dome", "Snowball Catastrophe", "Frost Dash"}},
    {Fruit = "Magma", Attacks = {"Magma Fist", "Magma Rain", "Volcanic Eruption", "Magma Wave", "Meteor Shower"}},
    {Fruit = "String", Attacks = {"String Pull", "Overheat Whip", "Parasite", "Fullbright", "String Cage"}},
    -- Légendaires
    {Fruit = "Flame V2", Attacks = {"Scorching Fist", "Twisting Claw", "Blazing Meteor", "Crimson Body", "Supernova"}},
    {Fruit = "Light V2", Attacks = {"Light Spear", "Radiant Burst", "Light Speed Dash", "Holy Light", "Light Nova"}},
    {Fruit = "Magma V2", Attacks = {"Magma Storm", "Crimson Howl", "Lava Burst", "Magma Shower", "Volcanic Smash"}},
    {Fruit = "Venom", Attacks = {"Venom Hydra", "Poison Cloud", "Toxic Slam", "Venom Spread", "Deadly Mist"}},
    {Fruit = "Magnet", Attacks = {"Cyclone", "Punk Prison", "Repel", "Punk Cannon", "Metal Arms"}},
    {Fruit = "Phoenix", Attacks = {"Flame Talon", "Phoenix Dive", "Healing Flames", "Blue Flames", "Phoenix Burst"}},
    -- Mythiques
    {Fruit = "Gravity", Attacks = {"Gravity Push", "Meteor Strike", "Black Hole", "Gravity Crush", "Planetary Devastation"}},
    {Fruit = "Quake", Attacks = {"Quake Punch", "Shockwave", "SeaQuake", "Eruption", "Slam"}},
    {Fruit = "Dark", Attacks = {"Black Hole", "Dark Vortex", "Liberation", "Dark Matter", "Black World"}},
    {Fruit = "Lightning", Attacks = {"Thunder Strike", "Lightning Dash", "Projected Burst", "Crashing Thunder", "Raigo"}},
    {Fruit = "Dough", Attacks = {"Dough Muddle", "Grilled Dough", "Chestnut", "Piercing Mochi", "Dough Explosion"}},
    {Fruit = "Leopard", Attacks = {"Claw Slash", "Leopard Rush", "Feral Roar", "Pounce Strike", "Savage Combo"}},
    {Fruit = "Ope", Attacks = {"Room", "Takt", "Shambles", "Gamma Knife", "Counter Shock"}},
    {Fruit = "Dragon", Attacks = {"Screech", "Dragon Breath", "Dragon Claw", "Thunder Roar", "Dragon Meteor", "Meteor Blaze"}},
    {Fruit = "Nika", Attacks = {"Gear Fifth Punch", "Rubber Dawn", "Laughing Storm", "Freedom Strike", "Nika Barrage"}},
    {Fruit = "Soul", Attacks = {"Soul Steal", "Spirit Barrage", "Soul Chain", "Ethereal Wave", "Soul Reaper"}},
    {Fruit = "DarkXQuake", Attacks = {"Dark Quake", "Black Eruption", "Shadow Slam", "Vortex Shock", "Abyssal Tsunami"}},
    {Fruit = "TSRubber", Attacks = {"Jet Pistol", "Time Stop", "Kong Gun", "Gear Second", "Red Hawk", "Gatling"}},
    {Fruit = "Nika", Attacks = {"Gear Fifth Punch", "Rubber Dawn", "Laughing Storm", "Freedom Strike", "Nika Barrage"}},
    {Fruit = "DarkXQuake", Attacks = {"Anti Body", "Anti Quake", "Black Hole Path", "Black Turret", "Abyssal Tsunami"}},
    {Fruit = "DoughV2", Attacks = {"Scorching Buzzcut", "Elastic Lasso", "Rolling Dough", "Piercing Mochi", "Dough Explosion"}},
    {Fruit = "Leopard", Attacks = {"Infinity Drive", "Sonic Kick", "Feral Roar", "Pounce Strike", "Savage Combo"}},
    {Fruit = "Okuchi", Attacks = {"Divine Serpent", "Arctic Breath", "Devastating Drop", "Glacial Coat", "Frost Fang"}},
    {Fruit = "Light V2", Attacks = {"X-Flash", "Solar Grenade", "Light Speed Dash", "Holy Light", "Light Nova"}},
}

-- Fonction pour mesurer la similarité entre deux chaînes
local function areStringsSimilar(str1, str2)
    str1 = str1:lower():gsub("%s+", "")
    str2 = str2:lower():gsub("%s+", "")
    
    if str1:find(str2) or str2:find(str1) then
        return true
    end
    
    local len1, len2 = #str1, #str2
    if math.abs(len1 - len2) > 3 then
        return false
    end
    
    local distance = 0
    for i = 1, math.min(len1, len2) do
        if str1:sub(i, i) ~= str2:sub(i, i) then
            distance = distance + 1
        end
    end
    distance = distance + math.abs(len1 - len2)
    
    return distance <= 3
end

-- Fonction pour détecter le fruit d'un joueur
local function detectFruit(targetPlayer)
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if not backpack then
        return "Inconnu", {"Erreur : Backpack non trouvé"}
    end

    local tools = {}
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item.Name)
        end
    end

    if #tools == 0 then
        return "Inconnu", {"Erreur : Aucun outil trouvé"}
    end

    local bestFruit = nil
    local bestMatches = 0
    local bestMatchedAttacks = {}
    
    for _, fruitData in pairs(fruitAttacks) do
        local matches = 0
        local matchedAttacks = {}
        for _, toolName in pairs(tools) do
            for _, attack in pairs(fruitData.Attacks) do
                if areStringsSimilar(toolName, attack) then
                    matches = matches + 1
                    table.insert(matchedAttacks, toolName .. " -> " .. attack)
                    break
                end
            end
        end
        if matches > bestMatches then
            bestMatches = matches
            bestFruit = fruitData.Fruit
            bestMatchedAttacks = matchedAttacks
        end
    end

    if bestFruit and bestMatches >= 2 then
        return bestFruit, bestMatchedAttacks
    else
        return "Inconnu", tools
    end
end

-- Fonction pour surveiller les changements dans le Backpack d'un joueur
local function monitorBackpack(targetPlayer)
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then
        local fruit, matchedAttacks = detectFruit(targetPlayer)
        fruitCache[targetPlayer] = {fruit = fruit, attacks = matchedAttacks}

        backpack.ChildAdded:Connect(function()
            local newFruit, newMatchedAttacks = detectFruit(targetPlayer)
            fruitCache[targetPlayer] = {fruit = newFruit, attacks = newMatchedAttacks}
        end)
        backpack.ChildRemoved:Connect(function()
            local newFruit, newMatchedAttacks = detectFruit(targetPlayer)
            fruitCache[targetPlayer] = {fruit = newFruit, attacks = newMatchedAttacks}
        end)
    end
end

-- Initialiser le cache pour les joueurs existants
for _, targetPlayer in pairs(Players:GetPlayers()) do
    if targetPlayer ~= player then
        monitorBackpack(targetPlayer)
    end
end

-- Surveiller les nouveaux joueurs
Players.PlayerAdded:Connect(function(targetPlayer)
    if targetPlayer ~= player then
        monitorBackpack(targetPlayer)
    end
end)

-- Gestion de la mort du joueur
humanoid.Died:Connect(function()
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
        tpLoopEnabled = false
    end
end)

-- Gestion du respawn du joueur
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    if speedEnabled then
        humanoid.WalkSpeed = customSpeedValue
        print("Vitesse restaurée à : " .. customSpeedValue)
        if speedLoopConnection then
            speedLoopConnection:Disconnect()
        end
        speedLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if speedEnabled and humanoid then
                humanoid.WalkSpeed = customSpeedValue
            end
        end)
    else
        humanoid.WalkSpeed = defaultWalkSpeed
        print("Vitesse réinitialisée à : " .. defaultWalkSpeed)
    end
    if jumpEnabled then
        local jumpValue = tonumber(jumpTextBox.Text) or defaultJumpPower
        humanoid.JumpPower = jumpValue
        humanoid.UseJumpPower = true
        print("Puissance de saut restaurée à : " .. jumpValue)
        if jumpLoopConnection then
            jumpLoopConnection:Disconnect()
        end
        jumpLoopConnection = game:GetService("RunService").Stepped:Connect(function()
            if jumpEnabled and humanoid then
                humanoid.JumpPower = jumpValue
                humanoid.UseJumpPower = true
            end
        end)
    end
    if tpLoopEnabled and selectedPlayer then
        if tpLoopConnection then
            tpLoopConnection:Disconnect()
        end
        tpLoopConnection = RunService.Heartbeat:Connect(function()
            if tpLoopEnabled and character and character:FindFirstChild("HumanoidRootPart") and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
            end
        end)
    end
end)

-- Création du ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGui"
ScreenGui.ResetOnSpawn = false

local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("CustomGui")
if existingGui then
    espEnabled = false
    for _, billboard in pairs(billboards) do
        billboard:Destroy()
    end
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    billboards = {}
    highlights = {}
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    infJumpEnabled = false
    tpLoopEnabled = false
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
    end
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        humanoid.WalkSpeed = defaultWalkSpeed
        humanoid.JumpPower = defaultJumpPower
        humanoid.UseJumpPower = true
    end
    existingGui:Destroy()
end

ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 370, 0, 500)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Name = "MainFrame"
local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 10)
MainFrameCorner.Parent = MainFrame
MainFrameCorner.Name = "MainFrameCorner"

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 350, 0, 50)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.Text = "Custom GUI"
TitleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TitleLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame
TitleLabel.Name = "TitleLabel"
local TitleLabelCorner = Instance.new("UICorner")
TitleLabelCorner.CornerRadius = UDim.new(0, 10)
TitleLabelCorner.Parent = TitleLabel
TitleLabelCorner.Name = "TitleLabelCorner"

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(0, 10, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.BorderSizePixel = 0
closeButton.Parent = MainFrame
closeButton.Name = "CloseButton"
local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 5)
closeButtonCorner.Parent = closeButton
closeButtonCorner.Name = "CloseButtonCorner"

closeButton.MouseButton1Click:Connect(function()
    espEnabled = false
    for _, billboard in pairs(billboards) do
        billboard:Destroy()
    end
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    billboards = {}
    highlights = {}
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    infJumpEnabled = false
    tpLoopEnabled = false
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
    end
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
    if serverTimeDisplayLabel then
        serverTimeDisplayLabel:Destroy()
        serverTimeDisplayLabel = nil
        print("serverTimeDisplayLabel supprimé lors de la fermeture du GUI")
    end
    if serverTimeUpdateConnection then
        serverTimeUpdateConnection:Disconnect()
        serverTimeUpdateConnection = nil
    end
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        humanoid.WalkSpeed = defaultWalkSpeed
        humanoid.JumpPower = defaultJumpPower
        humanoid.UseJumpPower = true
    end
    ScreenGui:Destroy()
end)

local reloadButton = Instance.new("TextButton")
reloadButton.Size = UDim2.new(0, 30, 0, 30)
reloadButton.Position = UDim2.new(1, -40, 0, 10)
reloadButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
reloadButton.Text = "↻"
reloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
reloadButton.Font = Enum.Font.GothamBold
reloadButton.TextSize = 16
reloadButton.BorderSizePixel = 0
reloadButton.Parent = MainFrame
reloadButton.Name = "ReloadButton"
local reloadButtonCorner = Instance.new("UICorner")
reloadButtonCorner.CornerRadius = UDim.new(0, 5)
reloadButtonCorner.Parent = reloadButton
reloadButtonCorner.Name = "ReloadButtonCorner"

reloadButton.MouseButton1Click:Connect(function()
    espEnabled = false
    for _, billboard in pairs(billboards) do
        billboard:Destroy()
    end
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    billboards = {}
    highlights = {}
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    infJumpEnabled = false
    tpLoopEnabled = false
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
    end
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        humanoid.WalkSpeed = defaultWalkSpeed
        humanoid.JumpPower = defaultJumpPower
        humanoid.UseJumpPower = true
    end
    ScreenGui:Destroy()
    local success, errorMsg = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hohigamer/Scirpt-dex/refs/heads/main/MyScript.lua"))()
    end)
    if success then
        print("Script rechargé avec succès !")
    else
        print("Erreur lors du rechargement du script : " .. tostring(errorMsg))
    end
end)

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

TitleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local baseSelectButton = Instance.new("TextButton")
baseSelectButton.Size = UDim2.new(0, 80, 0, 30)
baseSelectButton.Position = UDim2.new(0, 15, 0, 60)
baseSelectButton.Text = "Base"
baseSelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
baseSelectButton.TextColor3 = Color3.fromRGB(255, 165, 0)
baseSelectButton.Font = Enum.Font.Gotham
baseSelectButton.TextSize = 14
baseSelectButton.BorderSizePixel = 1
baseSelectButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
baseSelectButton.Parent = MainFrame
baseSelectButton.Name = "BaseSelectButton"
local baseSelectButtonCorner = Instance.new("UICorner")
baseSelectButtonCorner.CornerRadius = UDim.new(0, 5)
baseSelectButtonCorner.Parent = baseSelectButton
baseSelectButtonCorner.Name = "BaseSelectButtonCorner"

local playerSelectButton = Instance.new("TextButton")
playerSelectButton.Size = UDim2.new(0, 80, 0, 30)
playerSelectButton.Position = UDim2.new(0, 100, 0, 60)
playerSelectButton.Text = "Player"
playerSelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerSelectButton.TextColor3 = Color3.fromRGB(255, 165, 0)
playerSelectButton.Font = Enum.Font.Gotham
playerSelectButton.TextSize = 14
playerSelectButton.BorderSizePixel = 1
playerSelectButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
playerSelectButton.Parent = MainFrame
playerSelectButton.Name = "PlayerSelectButton"
local playerSelectButtonCorner = Instance.new("UICorner")
playerSelectButtonCorner.CornerRadius = UDim.new(0, 5)
playerSelectButtonCorner.Parent = playerSelectButton
playerSelectButtonCorner.Name = "PlayerSelectButtonCorner"

local settingsSelectButton = Instance.new("TextButton")
settingsSelectButton.Size = UDim2.new(0, 80, 0, 30)
settingsSelectButton.Position = UDim2.new(0, 185, 0, 60)
settingsSelectButton.Text = "Settings"
settingsSelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
settingsSelectButton.TextColor3 = Color3.fromRGB(255, 165, 0)
settingsSelectButton.Font = Enum.Font.Gotham
settingsSelectButton.TextSize = 14
settingsSelectButton.BorderSizePixel = 1
settingsSelectButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
settingsSelectButton.Parent = MainFrame
settingsSelectButton.Name = "SettingsSelectButton"
local settingsSelectButtonCorner = Instance.new("UICorner")
settingsSelectButtonCorner.CornerRadius = UDim.new(0, 5)
settingsSelectButtonCorner.Parent = settingsSelectButton
settingsSelectButtonCorner.Name = "SettingsSelectButtonCorner"

local tpSelectButton = Instance.new("TextButton")
tpSelectButton.Size = UDim2.new(0, 80, 0, 30)
tpSelectButton.Position = UDim2.new(0, 270, 0, 60)
tpSelectButton.Text = "TP"
tpSelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpSelectButton.TextColor3 = Color3.fromRGB(255, 165, 0)
tpSelectButton.Font = Enum.Font.Gotham
tpSelectButton.TextSize = 14
tpSelectButton.BorderSizePixel = 1
tpSelectButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
tpSelectButton.Parent = MainFrame
tpSelectButton.Name = "TpSelectButton"
local tpSelectButtonCorner = Instance.new("UICorner")
tpSelectButtonCorner.CornerRadius = UDim.new(0, 5)
tpSelectButtonCorner.Parent = tpSelectButton
tpSelectButtonCorner.Name = "TpSelectButtonCorner"

-- Définition de BaseGuiFrame (suppression des TextBox pour les coordonnées)
local BaseGuiFrame = Instance.new("Frame")
BaseGuiFrame.Size = UDim2.new(0, 320, 0, 300)
BaseGuiFrame.Position = UDim2.new(0, 15, 0, 100)
BaseGuiFrame.BackgroundTransparency = 1
BaseGuiFrame.Parent = MainFrame
BaseGuiFrame.Name = "BaseGuiFrame"
BaseGuiFrame.Visible = true

-- Bouton "Saut Infini" (inchangé)
local infJumpButton = Instance.new("TextButton")
infJumpButton.Size = UDim2.new(0, 250, 0, 40)
infJumpButton.Position = UDim2.new(0, 25, 0, 20)
infJumpButton.Text = "Saut Infini : OFF"
infJumpButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
infJumpButton.TextColor3 = Color3.fromRGB(255, 165, 0)
infJumpButton.Font = Enum.Font.Gotham
infJumpButton.TextSize = 16
infJumpButton.BorderSizePixel = 1
infJumpButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
infJumpButton.Parent = BaseGuiFrame
infJumpButton.Name = "InfJumpButton"
local infJumpButtonCorner = Instance.new("UICorner")
infJumpButtonCorner.CornerRadius = UDim.new(0, 5)
infJumpButtonCorner.Parent = infJumpButton
infJumpButtonCorner.Name = "InfJumpButtonCorner"

-- Bouton "Téléporter" (position ajustée, plus de TextBox)
local teleportButton = Instance.new("TextButton")
teleportButton.Size = UDim2.new(0, 250, 0, 40)
teleportButton.Position = UDim2.new(0, 25, 0, 70) -- Remis à sa position initiale
teleportButton.Text = "Téléporter"
teleportButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
teleportButton.TextColor3 = Color3.fromRGB(255, 165, 0)
teleportButton.Font = Enum.Font.Gotham
teleportButton.TextSize = 16
teleportButton.BorderSizePixel = 1
teleportButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
teleportButton.Parent = BaseGuiFrame
teleportButton.Name = "TeleportButton"
local teleportButtonCorner = Instance.new("UICorner")
teleportButtonCorner.CornerRadius = UDim.new(0, 5)
teleportButtonCorner.Parent = teleportButton
teleportButtonCorner.Name = "TeleportButtonCorner"

-- Bouton "NoClip" (position ajustée)
local noClipButton = Instance.new("TextButton")
noClipButton.Size = UDim2.new(0, 250, 0, 40)
noClipButton.Position = UDim2.new(0, 25, 0, 120) -- Remis à sa position initiale
noClipButton.Text = "NoClip : OFF"
noClipButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
noClipButton.TextColor3 = Color3.fromRGB(255, 165, 0)
noClipButton.Font = Enum.Font.Gotham
noClipButton.TextSize = 16
noClipButton.BorderSizePixel = 1
noClipButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
noClipButton.Parent = BaseGuiFrame
noClipButton.Name = "NoClipButton"
local noClipButtonCorner = Instance.new("UICorner")
noClipButtonCorner.CornerRadius = UDim.new(0, 5)
noClipButtonCorner.Parent = noClipButton
noClipButtonCorner.Name = "NoClipButtonCorner"

-- Bouton "ESP" (position ajustée)
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 250, 0, 40)
espButton.Position = UDim2.new(0, 25, 0, 170) -- Remis à sa position initiale
espButton.Text = "ESP : OFF"
espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espButton.TextColor3 = Color3.fromRGB(255, 165, 0)
espButton.Font = Enum.Font.Gotham
espButton.TextSize = 16
espButton.BorderSizePixel = 1
espButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
espButton.Parent = BaseGuiFrame
espButton.Name = "EspButton"
local espButtonCorner = Instance.new("UICorner")
espButtonCorner.CornerRadius = UDim.new(0, 5)
espButtonCorner.Parent = espButton
espButtonCorner.Name = "EspButtonCorner"

-- Bouton "Respawn" (position ajustée)
local respawnButton = Instance.new("TextButton")
respawnButton.Size = UDim2.new(0, 250, 0, 40)
respawnButton.Position = UDim2.new(0, 25, 0, 220) -- Remis à sa position initiale
respawnButton.Text = "Respawn"
respawnButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
respawnButton.TextColor3 = Color3.fromRGB(255, 165, 0)
respawnButton.Font = Enum.Font.Gotham
respawnButton.TextSize = 16
respawnButton.BorderSizePixel = 1
respawnButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
respawnButton.Parent = BaseGuiFrame
respawnButton.Name = "RespawnButton"
local respawnButtonCorner = Instance.new("UICorner")
respawnButtonCorner.CornerRadius = UDim.new(0, 5)
respawnButtonCorner.Parent = respawnButton
respawnButtonCorner.Name = "RespawnButtonCorner"

-- Bouton "Charger Script" (position ajustée)
local loadScriptButton = Instance.new("TextButton")
loadScriptButton.Size = UDim2.new(0, 250, 0, 40)
loadScriptButton.Position = UDim2.new(0, 25, 0, 270) -- Remis à sa position initiale
loadScriptButton.Text = "Charger Script"
loadScriptButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
loadScriptButton.TextColor3 = Color3.fromRGB(255, 165, 0)
loadScriptButton.Font = Enum.Font.Gotham
loadScriptButton.TextSize = 16
loadScriptButton.BorderSizePixel = 1
loadScriptButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
loadScriptButton.Parent = BaseGuiFrame
loadScriptButton.Name = "LoadScriptButton"
local loadScriptButtonCorner = Instance.new("UICorner")
loadScriptButtonCorner.CornerRadius = UDim.new(0, 5)
loadScriptButtonCorner.Parent = loadScriptButton
loadScriptButtonCorner.Name = "LoadScriptButtonCorner"

local PlayerGuiFrame = Instance.new("Frame")
PlayerGuiFrame.Size = UDim2.new(0, 320, 0, 250)
PlayerGuiFrame.Position = UDim2.new(0, 15, 0, 100)
PlayerGuiFrame.BackgroundTransparency = 1
PlayerGuiFrame.Parent = MainFrame
PlayerGuiFrame.Name = "PlayerGuiFrame"
PlayerGuiFrame.Visible = false

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0, 250, 0, 100)
playerListFrame.Position = UDim2.new(0, 25, 0, 20)
playerListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerListFrame.BorderSizePixel = 1
playerListFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
playerListFrame.ScrollBarThickness = 5
playerListFrame.Parent = PlayerGuiFrame
playerListFrame.Name = "PlayerListFrame"
local playerListFrameCorner = Instance.new("UICorner")
playerListFrameCorner.CornerRadius = UDim.new(0, 5)
playerListFrameCorner.Parent = playerListFrame
playerListFrameCorner.Name = "PlayerListFrameCorner"

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Parent = playerListFrame
playerListLayout.Name = "PlayerListLayout"

local selectedPlayerLabel = Instance.new("TextLabel")
selectedPlayerLabel.Size = UDim2.new(0, 250, 0, 30)
selectedPlayerLabel.Position = UDim2.new(0, 25, 0, 130)
selectedPlayerLabel.Text = "Joueur sélectionné : Aucun"
selectedPlayerLabel.BackgroundTransparency = 1
selectedPlayerLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
selectedPlayerLabel.Font = Enum.Font.Gotham
selectedPlayerLabel.TextSize = 14
selectedPlayerLabel.Parent = PlayerGuiFrame
selectedPlayerLabel.Name = "SelectedPlayerLabel"

local tpOnceButton = Instance.new("TextButton")
tpOnceButton.Size = UDim2.new(0, 250, 0, 40)
tpOnceButton.Position = UDim2.new(0, 25, 0, 170)
tpOnceButton.Text = "Téléporter (Une fois)"
tpOnceButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpOnceButton.TextColor3 = Color3.fromRGB(255, 165, 0)
tpOnceButton.Font = Enum.Font.Gotham
tpOnceButton.TextSize = 16
tpOnceButton.BorderSizePixel = 1
tpOnceButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
tpOnceButton.Parent = PlayerGuiFrame
tpOnceButton.Name = "TpOnceButton"
local tpOnceButtonCorner = Instance.new("UICorner")
tpOnceButtonCorner.CornerRadius = UDim.new(0, 5)
tpOnceButtonCorner.Parent = tpOnceButton
tpOnceButtonCorner.Name = "TpOnceButtonCorner"

local tpLoopButton = Instance.new("TextButton")
tpLoopButton.Size = UDim2.new(0, 250, 0, 40)
tpLoopButton.Position = UDim2.new(0, 25, 0, 220)
tpLoopButton.Text = "Téléportation en boucle : OFF"
tpLoopButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpLoopButton.TextColor3 = Color3.fromRGB(255, 165, 0)
tpLoopButton.Font = Enum.Font.Gotham
tpLoopButton.TextSize = 16
tpLoopButton.BorderSizePixel = 1
tpLoopButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
tpLoopButton.Parent = PlayerGuiFrame
tpLoopButton.Name = "TpLoopButton"
local tpLoopButtonCorner = Instance.new("UICorner")
tpLoopButtonCorner.CornerRadius = UDim.new(0, 5)
tpLoopButtonCorner.Parent = tpLoopButton
tpLoopButtonCorner.Name = "TpLoopButtonCorner"

local SettingsGuiFrame = Instance.new("Frame")
SettingsGuiFrame.Size = UDim2.new(0, 320, 0, 250)
SettingsGuiFrame.Position = UDim2.new(0, 15, 0, 100)
SettingsGuiFrame.BackgroundTransparency = 1
SettingsGuiFrame.Parent = MainFrame
SettingsGuiFrame.Name = "SettingsGuiFrame"
SettingsGuiFrame.Visible = false

local serverTimeToggleButton = Instance.new("TextButton")
serverTimeToggleButton.Size = UDim2.new(0, 250, 0, 40)
serverTimeToggleButton.Position = UDim2.new(0, 25, 0, 185)
serverTimeToggleButton.Text = "Afficher ServerTime : OFF"
serverTimeToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
serverTimeToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
serverTimeToggleButton.Font = Enum.Font.Gotham
serverTimeToggleButton.TextSize = 16
serverTimeToggleButton.BorderSizePixel = 1
serverTimeToggleButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
serverTimeToggleButton.Parent = SettingsGuiFrame
serverTimeToggleButton.Name = "ServerTimeToggleButton"
local serverTimeToggleButtonCorner = Instance.new("UICorner")
serverTimeToggleButtonCorner.CornerRadius = UDim.new(0, 5)
serverTimeToggleButtonCorner.Parent = serverTimeToggleButton
serverTimeToggleButtonCorner.Name = "ServerTimeToggleButtonCorner"

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 100, 0, 30)
speedLabel.Position = UDim2.new(0, 25, 0, 20)
speedLabel.Text = "Vitesse :"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 16
speedLabel.Parent = SettingsGuiFrame
speedLabel.Name = "SpeedLabel"

local speedTextBox = Instance.new("TextBox")
speedTextBox.Size = UDim2.new(0, 150, 0, 30)
speedTextBox.Position = UDim2.new(0, 125, 0, 20)
speedTextBox.Text = tostring(defaultWalkSpeed)
speedTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTextBox.Font = Enum.Font.Gotham
speedTextBox.TextSize = 16
speedTextBox.BorderSizePixel = 1
speedTextBox.BorderColor3 = Color3.fromRGB(255, 165, 0)
speedTextBox.Parent = SettingsGuiFrame
speedTextBox.Name = "SpeedTextBox"
local speedTextBoxCorner = Instance.new("UICorner")
speedTextBoxCorner.CornerRadius = UDim.new(0, 5)
speedTextBoxCorner.Parent = speedTextBox
speedTextBoxCorner.Name = "SpeedTextBoxCorner"

local speedToggleButton = Instance.new("TextButton")
speedToggleButton.Size = UDim2.new(0, 250, 0, 40)
speedToggleButton.Position = UDim2.new(0, 25, 0, 60)
speedToggleButton.Text = "Activer Vitesse"
speedToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
speedToggleButton.Font = Enum.Font.Gotham
speedToggleButton.TextSize = 16
speedToggleButton.BorderSizePixel = 1
speedToggleButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
speedToggleButton.Parent = SettingsGuiFrame
speedToggleButton.Name = "SpeedToggleButton"
local speedToggleButtonCorner = Instance.new("UICorner")
speedToggleButtonCorner.CornerRadius = UDim.new(0, 5)
speedToggleButtonCorner.Parent = speedToggleButton
speedToggleButtonCorner.Name = "SpeedToggleButtonCorner"

local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(0, 100, 0, 30)
jumpLabel.Position = UDim2.new(0, 25, 0, 110)
jumpLabel.Text = "Saut :"
jumpLabel.BackgroundTransparency = 1
jumpLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
jumpLabel.Font = Enum.Font.Gotham
jumpLabel.TextSize = 16
jumpLabel.Parent = SettingsGuiFrame
jumpLabel.Name = "JumpLabel"

local jumpTextBox = Instance.new("TextBox")
jumpTextBox.Size = UDim2.new(0, 150, 0, 30)
jumpTextBox.Position = UDim2.new(0, 125, 0, 110)
jumpTextBox.Text = tostring(defaultJumpPower)
jumpTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
jumpTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpTextBox.Font = Enum.Font.Gotham
jumpTextBox.TextSize = 16
jumpTextBox.BorderSizePixel = 1
jumpTextBox.BorderColor3 = Color3.fromRGB(255, 165, 0)
jumpTextBox.Parent = SettingsGuiFrame
jumpTextBox.Name = "JumpTextBox"
local jumpTextBoxCorner = Instance.new("UICorner")
jumpTextBoxCorner.CornerRadius = UDim.new(0, 5)
jumpTextBoxCorner.Parent = jumpTextBox
jumpTextBoxCorner.Name = "JumpTextBoxCorner"

local jumpToggleButton = Instance.new("TextButton")
jumpToggleButton.Size = UDim2.new(0, 250, 0, 40)
jumpToggleButton.Position = UDim2.new(0, 25, 0, 150)
jumpToggleButton.Text = "Activer Saut"
jumpToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
jumpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
jumpToggleButton.Font = Enum.Font.Gotham
jumpToggleButton.TextSize = 16
jumpToggleButton.BorderSizePixel = 1
jumpToggleButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
jumpToggleButton.Parent = SettingsGuiFrame
jumpToggleButton.Name = "JumpToggleButton"
local jumpToggleButtonCorner = Instance.new("UICorner")
jumpToggleButtonCorner.CornerRadius = UDim.new(0, 5)
jumpToggleButtonCorner.Parent = jumpToggleButton
jumpToggleButtonCorner.Name = "JumpToggleButtonCorner"

local TpGuiFrame = Instance.new("Frame")
TpGuiFrame.Size = UDim2.new(0, 320, 0, 300)
TpGuiFrame.Position = UDim2.new(0, 15, 0, 100)
TpGuiFrame.BackgroundTransparency = 1
TpGuiFrame.Parent = MainFrame
TpGuiFrame.Name = "TpGuiFrame"
TpGuiFrame.Visible = false

local showCoordsButton = Instance.new("TextButton")
showCoordsButton.Size = UDim2.new(0, 250, 0, 40)
showCoordsButton.Position = UDim2.new(0, 25, 0, 20)
showCoordsButton.Text = "Afficher mes coordonnées"
showCoordsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
showCoordsButton.TextColor3 = Color3.fromRGB(255, 165, 0)
showCoordsButton.Font = Enum.Font.Gotham
showCoordsButton.TextSize = 16
showCoordsButton.BorderSizePixel = 1
showCoordsButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
showCoordsButton.Parent = TpGuiFrame
showCoordsButton.Name = "ShowCoordsButton"
local showCoordsButtonCorner = Instance.new("UICorner")
showCoordsButtonCorner.CornerRadius = UDim.new(0, 5)
showCoordsButtonCorner.Parent = showCoordsButton
showCoordsButtonCorner.Name = "ShowCoordsButtonCorner"

local coordsLabel = Instance.new("TextLabel")
coordsLabel.Size = UDim2.new(0, 250, 0, 30)
coordsLabel.Position = UDim2.new(0, 25, 0, 70)
coordsLabel.Text = "Coordonnées : Non définies"
coordsLabel.BackgroundTransparency = 1
coordsLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
coordsLabel.Font = Enum.Font.Gotham
coordsLabel.TextSize = 14
coordsLabel.Parent = TpGuiFrame
coordsLabel.Name = "CoordsLabel"

local safeZonesFrame = Instance.new("ScrollingFrame")
safeZonesFrame.Size = UDim2.new(0, 250, 0, 100)
safeZonesFrame.Position = UDim2.new(0, 25, 0, 120)
safeZonesFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
safeZonesFrame.BorderSizePixel = 1
safeZonesFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
safeZonesFrame.ScrollBarThickness = 5
safeZonesFrame.Parent = TpGuiFrame
safeZonesFrame.Name = "SafeZonesFrame"
local safeZonesFrameCorner = Instance.new("UICorner")
safeZonesFrameCorner.CornerRadius = UDim.new(0, 5)
safeZonesFrameCorner.Parent = safeZonesFrame
safeZonesFrameCorner.Name = "SafeZonesFrameCorner"

local safeZonesLayout = Instance.new("UIListLayout")
safeZonesLayout.SortOrder = Enum.SortOrder.LayoutOrder
safeZonesLayout.Padding = UDim.new(0, 5)
safeZonesLayout.Parent = safeZonesFrame
safeZonesLayout.Name = "SafeZonesLayout"

local selectedSafeZoneLabel = Instance.new("TextLabel")
selectedSafeZoneLabel.Size = UDim2.new(0, 250, 0, 30)
selectedSafeZoneLabel.Position = UDim2.new(0, 25, 0, 220)
selectedSafeZoneLabel.Text = "Modèle sélectionné : Aucun"
selectedSafeZoneLabel.BackgroundTransparency = 1
selectedSafeZoneLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
selectedSafeZoneLabel.Font = Enum.Font.Gotham
selectedSafeZoneLabel.TextSize = 14
selectedSafeZoneLabel.Parent = TpGuiFrame
selectedSafeZoneLabel.Name = "SelectedSafeZoneLabel"

-- Définition du bouton "Téléporter Safezone" (déjà renommé dans le script précédent)
local tpToSafeZoneButton = Instance.new("TextButton")
tpToSafeZoneButton.Size = UDim2.new(0, 250, 0, 40)
tpToSafeZoneButton.Position = UDim2.new(0, 25, 0, 260)
tpToSafeZoneButton.Text = "Téléporter Safezone"
tpToSafeZoneButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpToSafeZoneButton.TextColor3 = Color3.fromRGB(255, 165, 0)
tpToSafeZoneButton.Font = Enum.Font.Gotham
tpToSafeZoneButton.TextSize = 16
tpToSafeZoneButton.BorderSizePixel = 1
tpToSafeZoneButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
tpToSafeZoneButton.Parent = TpGuiFrame
tpToSafeZoneButton.Name = "TpToSafeZoneButton"
local tpToSafeZoneButtonCorner = Instance.new("UICorner")
tpToSafeZoneButtonCorner.CornerRadius = UDim.new(0, 5)
tpToSafeZoneButtonCorner.Parent = tpToSafeZoneButton
tpToSafeZoneButtonCorner.Name = "TpToSafeZoneButtonCorner"

-- Bouton "Détection Marco" (inchangé, mais la logique sera modifiée)
local marcoTpToggleButton = Instance.new("TextButton")
marcoTpToggleButton.Size = UDim2.new(0, 250, 0, 40)
marcoTpToggleButton.Position = UDim2.new(0, 25, 0, 310)
marcoTpToggleButton.Text = "Détection Marco : OFF"
marcoTpToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
marcoTpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
marcoTpToggleButton.Font = Enum.Font.Gotham
marcoTpToggleButton.TextSize = 16
marcoTpToggleButton.BorderSizePixel = 1
marcoTpToggleButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
marcoTpToggleButton.Parent = TpGuiFrame
marcoTpToggleButton.Name = "MarcoTpToggleButton"
local marcoTpToggleButtonCorner = Instance.new("UICorner")
marcoTpToggleButtonCorner.CornerRadius = UDim.new(0, 5)
marcoTpToggleButtonCorner.Parent = marcoTpToggleButton
marcoTpToggleButtonCorner.Name = "MarcoTpToggleButtonCorner"

-- Label pour afficher l'état de la détection de Marco (inchangé)
local marcoStateLabel = Instance.new("TextLabel")
marcoStateLabel.Size = UDim2.new(0, 250, 0, 30)
marcoStateLabel.Position = UDim2.new(0, 25, 0, 355)
marcoStateLabel.Text = "Marco détecté : Non"
marcoStateLabel.BackgroundTransparency = 1
marcoStateLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
marcoStateLabel.Font = Enum.Font.Gotham
marcoStateLabel.TextSize = 14
marcoStateLabel.Parent = TpGuiFrame
marcoStateLabel.Name = "MarcoStateLabel"

local uiGui = player.PlayerGui:FindFirstChild("UI")
if not uiGui then
    uiGui = Instance.new("ScreenGui")
    uiGui.Name = "UI"
    uiGui.Parent = player.PlayerGui
    uiGui.IgnoreGuiInset = true
    print("ScreenGui UI créé dans PlayerGui")
else
    print("ScreenGui UI déjà existant dans PlayerGui")
end

local existingServerTimeLabel = uiGui:FindFirstChild("ServerTimeDisplayLabel")
if existingServerTimeLabel then
    existingServerTimeLabel:Destroy()
    print("Doublon de serverTimeDisplayLabel détecté et supprimé")
end

local serverTimeDisplayLabel = Instance.new("TextLabel")
serverTimeDisplayLabel.Size = UDim2.new(0, 400, 0, 70)
serverTimeDisplayLabel.Position = UDim2.new(0.5, -200, 0, 10)
serverTimeDisplayLabel.Text = "ServerTime : Non chargé"
serverTimeDisplayLabel.BackgroundTransparency = 1
serverTimeDisplayLabel.BorderSizePixel = 0
serverTimeDisplayLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
serverTimeDisplayLabel.Font = Enum.Font.GothamBold
serverTimeDisplayLabel.TextSize = 28
serverTimeDisplayLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
serverTimeDisplayLabel.TextStrokeTransparency = 0
serverTimeDisplayLabel.Visible = false
serverTimeDisplayLabel.Parent = uiGui
serverTimeDisplayLabel.Name = "ServerTimeDisplayLabel"
print("serverTimeDisplayLabel créé et ajouté à player.PlayerGui.UI")

local function updateESP()
    if not espEnabled then
        for _, billboard in pairs(billboards) do
            billboard:Destroy()
        end
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        billboards = {}
        highlights = {}
        return
    end

    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer == player then continue end

        local targetCharacter = targetPlayer.Character
        if targetCharacter and targetCharacter:FindFirstChild("Head") and targetCharacter:FindFirstChild("Humanoid") then
            local targetHumanoid = targetCharacter.Humanoid

            local billboard = billboards[targetPlayer]
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "ESPBillboard"
                billboard.Size = UDim2.new(0, 100, 0, 75)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = targetCharacter.Head
                billboards[targetPlayer] = billboard

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
                nameLabel.Position = UDim2.new(0, 0, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 12
                nameLabel.Parent = billboard

                local hpLabel = Instance.new("TextLabel")
                hpLabel.Name = "HPLabel"
                hpLabel.Size = UDim2.new(1, 0, 0.33, 0)
                hpLabel.Position = UDim2.new(0, 0, 0.33, 0)
                hpLabel.BackgroundTransparency = 1
                hpLabel.TextColor3 = Color3.fromRGB(0, 100, 0)
                hpLabel.Font = Enum.Font.GothamBold
                hpLabel.TextSize = 12
                hpLabel.Parent = billboard

                local fruitLabel = Instance.new("TextLabel")
                fruitLabel.Name = "FruitLabel"
                fruitLabel.Size = UDim2.new(1, 0, 0.33, 0)
                fruitLabel.Position = UDim2.new(0, 0, 0.66, 0)
                fruitLabel.BackgroundTransparency = 1
                fruitLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                fruitLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                fruitLabel.TextStrokeTransparency = 0.5
                fruitLabel.Font = Enum.Font.GothamBold
                fruitLabel.TextSize = 12
                fruitLabel.Parent = billboard
            end

            local highlight = highlights[targetPlayer]
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESPGlow"
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0.3
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = targetCharacter
                highlights[targetPlayer] = highlight
            end

            local nameLabel = billboard:FindFirstChild("NameLabel")
            local hpLabel = billboard:FindFirstChild("HPLabel")
            local fruitLabel = billboard:FindFirstChild("FruitLabel")
            if nameLabel and hpLabel and fruitLabel then
                nameLabel.Text = targetPlayer.Name
                hpLabel.Text = "HP: " .. math.floor(targetHumanoid.Health) .. "/" .. math.floor(targetHumanoid.MaxHealth)

                local cachedFruit = fruitCache[targetPlayer] or {fruit = "Inconnu", attacks = {"Erreur : Non détecté"}}
                if cachedFruit.fruit ~= "Inconnu" then
                    fruitLabel.Text = "Fruit: " .. cachedFruit.fruit
                else
                    fruitLabel.Text = "Attaques: " .. table.concat(cachedFruit.attacks, ", ")
                end
            end
        else
            if billboards[targetPlayer] then
                billboards[targetPlayer]:Destroy()
                billboards[targetPlayer] = nil
            end
            if highlights[targetPlayer] then
                highlights[targetPlayer]:Destroy()
                highlights[targetPlayer] = nil
            end
        end
    end
end

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "ESP : " .. (espEnabled and "ON" or "OFF")
    espButton.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if not espEnabled then
        for _, billboard in pairs(billboards) do
            billboard:Destroy()
        end
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        billboards = {}
        highlights = {}
        if espUpdateConnection then
            espUpdateConnection:Disconnect()
            espUpdateConnection = nil
        end
    else
        espUpdateConnection = RunService.Heartbeat:Connect(function()
            if tick() % 0.5 < 0.016 then
                updateESP()
            end
        end)
    end
end)

local function updatePlayerList()
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local index = 0
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(0, 230, 0, 30)
            playerButton.Position = UDim2.new(0, 5, 0, index * 35)
            playerButton.Text = targetPlayer.Name
            playerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            playerButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            playerButton.Font = Enum.Font.Gotham
            playerButton.TextSize = 14
            playerButton.BorderSizePixel = 1
            playerButton.BorderColor3 = Color3.fromRGB(255, 165, 0)
            playerButton.Parent = playerListFrame
            local playerButtonCorner = Instance.new("UICorner")
            playerButtonCorner.CornerRadius = UDim.new(0, 5)
            playerButtonCorner.Parent = playerButton

            playerButton.MouseButton1Click:Connect(function()
                selectedPlayer = targetPlayer
                selectedPlayerLabel.Text = "Joueur sélectionné : " .. targetPlayer.Name
            end)

            index = index + 1
        end
    end

    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, index * 35)
end

-- Logique pour ajouter une SafeZone à la liste (corrigée pour s'assurer que selectedSafeZone est bien défini)
local function addSafeZoneToList(zone)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Text = zone.Name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = safeZonesFrame
    button.Name = zone.Name

    button.MouseButton1Click:Connect(function()
        selectedSafeZone = zone
        selectedSafeZoneLabel.Text = "Modèle sélectionné : " .. zone.Name
        print("Modèle sélectionné : " .. zone.Name .. " (CFrame : " .. tostring(zone.CFrame)) -- Débogage
    end)

    print("Modèle ajouté à la liste : " .. zone.Name)
end

local function removeSafeZoneFromList(zone)
    local button = safeZonesFrame:FindFirstChild(zone.Name)
    if button then
        button:Destroy()
        if selectedSafeZone == zone then
            selectedSafeZone = nil
            selectedSafeZoneLabel.Text = "Modèle sélectionné : Aucun"
        end
        print("Modèle supprimé de la liste : " .. zone.Name)
    end
end

local safeZonesFolder = game.Workspace:FindFirstChild("SafeZones")
if not safeZonesFolder then
    safeZonesFolder = Instance.new("Folder")
    safeZonesFolder.Name = "SafeZones"
    safeZonesFolder.Parent = game.Workspace
    print("Dossier SafeZones créé dans Workspace")
end

for _, zone in ipairs(safeZonesFolder:GetChildren()) do
    addSafeZoneToList(zone)
end

safeZonesFolder.ChildAdded:Connect(addSafeZoneToList)
safeZonesFolder.ChildRemoved:Connect(removeSafeZoneFromList)

updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(targetPlayer)
    updatePlayerList()
    fruitCache[targetPlayer] = nil
    if billboards[targetPlayer] then
        billboards[targetPlayer]:Destroy()
        billboards[targetPlayer] = nil
    end
    if highlights[targetPlayer] then
        highlights[targetPlayer]:Destroy()
        highlights[targetPlayer] = nil
    end
    if selectedPlayer == targetPlayer then
        selectedPlayer = nil
        selectedPlayerLabel.Text = "Joueur sélectionné : Aucun"
        if tpLoopEnabled then
            tpLoopEnabled = false
            tpLoopButton.Text = "Téléportation en boucle : OFF"
            tpLoopButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            if tpLoopConnection then
                tpLoopConnection:Disconnect()
                tpLoopConnection = nil
            end
        end
    end
end)

baseSelectButton.MouseButton1Click:Connect(function()
    BaseGuiFrame.Visible = true
    PlayerGuiFrame.Visible = false
    SettingsGuiFrame.Visible = false
    TpGuiFrame.Visible = false
end)

playerSelectButton.MouseButton1Click:Connect(function()
    BaseGuiFrame.Visible = false
    PlayerGuiFrame.Visible = true
    SettingsGuiFrame.Visible = false
    TpGuiFrame.Visible = false
end)

settingsSelectButton.MouseButton1Click:Connect(function()
    BaseGuiFrame.Visible = false
    PlayerGuiFrame.Visible = false
    SettingsGuiFrame.Visible = true
    TpGuiFrame.Visible = false
end)

tpSelectButton.MouseButton1Click:Connect(function()
    BaseGuiFrame.Visible = false
    PlayerGuiFrame.Visible = false
    SettingsGuiFrame.Visible = false
    TpGuiFrame.Visible = true
end)

local function toggleSpeed()
    speedEnabled = not speedEnabled
    if humanoid then
        if speedEnabled then
            speedToggleButton.Text = "Désactiver Vitesse"
            speedToggleButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            customSpeedValue = tonumber(speedTextBox.Text) or defaultWalkSpeed
            humanoid.WalkSpeed = customSpeedValue
            print("Vitesse définie à : " .. customSpeedValue)
            if speedLoopConnection then
                speedLoopConnection:Disconnect()
            end
            speedLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if speedEnabled and humanoid then
                    humanoid.WalkSpeed = customSpeedValue
                end
            end)
        else
            speedToggleButton.Text = "Activer Vitesse"
            speedToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            if speedLoopConnection then
                speedLoopConnection:Disconnect()
                speedLoopConnection = nil
            end
            humanoid.WalkSpeed = defaultWalkSpeed
            customSpeedValue = defaultWalkSpeed
            print("Vitesse réinitialisée à : " .. defaultWalkSpeed)
        end
    else
        print("Erreur : Humanoid non disponible")
        speedEnabled = false
        speedToggleButton.Text = "Activer Vitesse"
        speedToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
end

local function toggleJump()
    jumpEnabled = not jumpEnabled
    if humanoid then
        if jumpEnabled then
            jumpToggleButton.Text = "Désactiver Saut"
            jumpToggleButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            local jumpValue = tonumber(jumpTextBox.Text) or defaultJumpPower
            humanoid.JumpPower = jumpValue
            humanoid.UseJumpPower = true
            print("Puissance de saut définie à : " .. jumpValue)
            if jumpLoopConnection then
                jumpLoopConnection:Disconnect()
            end
            jumpLoopConnection = game:GetService("RunService").Stepped:Connect(function()
                if jumpEnabled and humanoid then
                    humanoid.JumpPower = jumpValue
                    humanoid.UseJumpPower = true
                end
            end)
        else
            jumpToggleButton.Text = "Activer Saut"
            jumpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            if jumpLoopConnection then
                jumpLoopConnection:Disconnect()
                jumpLoopConnection = nil
            end
            humanoid.JumpPower = defaultJumpPower
            humanoid.UseJumpPower = true
            print("Puissance de saut réinitialisée à : " .. defaultJumpPower)
        end
    else
        print("Erreur : Humanoid non disponible")
        jumpEnabled = false
        jumpToggleButton.Text = "Activer Saut"
        jumpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
end

speedToggleButton.MouseButton1Click:Connect(toggleSpeed)
jumpToggleButton.MouseButton1Click:Connect(toggleJump)

-- Suite du script à partir de la gestion du bouton "Saut Infini"

local infJumpEnabled = false
infJumpButton.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    infJumpButton.Text = "Saut Infini : " .. (infJumpEnabled and "ON" or "OFF")
    infJumpButton.TextColor3 = infJumpEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if infJumpEnabled then
        local userInputService = game:GetService("UserInputService")
        userInputService.JumpRequest:Connect(function()
            if infJumpEnabled and character and humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- Logique pour le bouton "Téléporter" (modifiée pour téléporter directement aux coordonnées fixes)
teleportButton.MouseButton1Click:Connect(function()
    if not character then
        print("Erreur : Personnage non disponible")
        return
    end
    if not character:FindFirstChild("HumanoidRootPart") then
        print("Erreur : HumanoidRootPart non trouvé pour le joueur")
        return
    end

    -- Coordonnées fixes demandées
    local x = -304.0
    local y = 698.4
    local z = -1241.2

    -- Téléporter le joueur aux coordonnées fixes
    local targetCFrame = CFrame.new(x, y, z)
    character.HumanoidRootPart.CFrame = targetCFrame
    print("Téléportation effectuée aux coordonnées fixes : " .. x .. ", " .. y .. ", " .. z)
end)

local noClipEnabled = false
noClipButton.MouseButton1Click:Connect(function()
    noClipEnabled = not noClipEnabled
    noClipButton.Text = "NoClip : " .. (noClipEnabled and "ON" or "OFF")
    noClipButton.TextColor3 = noClipEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if noClipEnabled then
        local noClipConnection
        noClipConnection = RunService.Stepped:Connect(function()
            if not noClipEnabled then
                noClipConnection:Disconnect()
                return
            end
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

respawnButton.MouseButton1Click:Connect(function()
    if character and humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        print("Respawn déclenché")
    end
end)

loadScriptButton.MouseButton1Click:Connect(function()
    local success, errorMsg = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hohigamer/Scirpt-dex/refs/heads/main/MyScript.lua"))()
    end)
    if success then
        print("Script chargé avec succès !")
    else
        print("Erreur lors du chargement du script : " .. tostring(errorMsg))
    end
end)

tpOnceButton.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") and character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
        print("Téléportation effectuée vers : " .. selectedPlayer.Name)
    else
        print("Erreur : Aucun joueur sélectionné ou personnage non disponible")
    end
end)

tpLoopButton.MouseButton1Click:Connect(function()
    tpLoopEnabled = not tpLoopEnabled
    tpLoopButton.Text = "Téléportation en boucle : " .. (tpLoopEnabled and "ON" or "OFF")
    tpLoopButton.TextColor3 = tpLoopEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if tpLoopEnabled then
        if tpLoopConnection then
            tpLoopConnection:Disconnect()
        end
        tpLoopConnection = RunService.Heartbeat:Connect(function()
            if tpLoopEnabled and character and character:FindFirstChild("HumanoidRootPart") and selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
            end
        end)
    else
        if tpLoopConnection then
            tpLoopConnection:Disconnect()
            tpLoopConnection = nil
        end
    end
end)

serverTimeToggleButton.MouseButton1Click:Connect(function()
    serverTimeDisplayEnabled = not serverTimeDisplayEnabled
    serverTimeToggleButton.Text = "Afficher ServerTime : " .. (serverTimeDisplayEnabled and "ON" or "OFF")
    serverTimeToggleButton.TextColor3 = serverTimeDisplayEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if serverTimeDisplayEnabled then
        serverTimeDisplayLabel.Visible = true
        if serverTimeUpdateConnection then
            serverTimeUpdateConnection:Disconnect()
        end
        serverTimeUpdateConnection = RunService.Heartbeat:Connect(function()
            local serverTimeLabel = player.PlayerGui:FindFirstChild("UI") and player.PlayerGui.UI:FindFirstChild("Info") and player.PlayerGui.UI.Info:FindFirstChild("ServerTime")
            if serverTimeLabel then
                serverTimeDisplayLabel.Text = serverTimeLabel.Text
            else
                serverTimeDisplayLabel.Text = "ServerTime : Non disponible"
            end
        end)
    else
        serverTimeDisplayLabel.Visible = false
        if serverTimeUpdateConnection then
            serverTimeUpdateConnection:Disconnect()
            serverTimeUpdateConnection = nil
        end
    end
end)

showCoordsButton.MouseButton1Click:Connect(function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        local position = character.HumanoidRootPart.Position
        coordsLabel.Text = string.format("Coordonnées : %.2f, %.2f, %.2f", position.X, position.Y, position.Z)
    else
        coordsLabel.Text = "Coordonnées : Non disponibles"
    end
end)

-- Logique pour le bouton "Téléporter Safezone" (corrigée avec plus de vérifications)
tpToSafeZoneButton.MouseButton1Click:Connect(function()
    if not character then
        print("Erreur : Personnage non disponible")
        return
    end
    if not character:FindFirstChild("HumanoidRootPart") then
        print("Erreur : HumanoidRootPart non trouvé pour le joueur")
        return
    end
    if not selectedSafeZone then
        print("Erreur : Aucun modèle sélectionné (selectedSafeZone est nil)")
        return
    end
    if not selectedSafeZone:IsA("BasePart") and not selectedSafeZone:IsA("Model") then
        print("Erreur : selectedSafeZone n'est pas un BasePart ou un Model")
        return
    end

    -- Vérifier si selectedSafeZone est un Model ou un BasePart et obtenir le CFrame approprié
    local targetCFrame
    if selectedSafeZone:IsA("Model") then
        local primaryPart = selectedSafeZone.PrimaryPart or selectedSafeZone:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            targetCFrame = primaryPart.CFrame
        else
            print("Erreur : Le modèle sélectionné n'a pas de PrimaryPart ou de BasePart")
            return
        end
    else
        targetCFrame = selectedSafeZone.CFrame
    end

    -- Téléporter le joueur
    character.HumanoidRootPart.CFrame = targetCFrame
    print("Téléportation effectuée vers : " .. selectedSafeZone.Name .. " (CFrame : " .. tostring(targetCFrame))
end)

marcoTpToggleButton.MouseButton1Click:Connect(function()
    marcoTpEnabled = not marcoTpEnabled
    marcoTpToggleButton.Text = "Détection Marco : " .. (marcoTpEnabled and "ON" or "OFF")
    marcoTpToggleButton.TextColor3 = marcoTpEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if marcoTpEnabled then
        if marcoTpConnection then
            marcoTpConnection:Disconnect()
        end
        marcoTpConnection = RunService.Heartbeat:Connect(function()
            if not marcoTpEnabled then return end

            -- Vérifier si le dossier "Marcos" existe dans Workspace
            local marcosFolder = game.Workspace:FindFirstChild("Marcos")
            if marcosFolder then
                local marcoFound = false
                for _, marco in pairs(marcosFolder:GetChildren()) do
                    if marco:IsA("BasePart") then
                        marcoFound = true
                        marcoStateLabel.Text = "Marco détecté : Oui"
                        marcoStateLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        -- Téléporter le joueur vers le Marco
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.CFrame = marco.CFrame
                            print("Téléportation vers Marco : " .. marco.Name)
                        end
                        break
                    end
                end
                if not marcoFound then
                    marcoStateLabel.Text = "Marco détecté : Non"
                    marcoStateLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                end
            else
                marcoStateLabel.Text = "Marco détecté : Non (Dossier Marcos non trouvé)"
                marcoStateLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
            end
        end)
    else
        if marcoTpConnection then
            marcoTpConnection:Disconnect()
            marcoTpConnection = nil
        end
        marcoStateLabel.Text = "Marco détecté : Non"
        marcoStateLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
end)

-- Fin du script

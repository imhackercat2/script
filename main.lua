-- [[ 掛貓豪華整合版 v1.3.1 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心控制變數 ----------
local flyEnabled, hoverEnabled, espEnabled, lockHeadEnabled = false, false, false, false
local speed, interval = 6, 0.05
local bodyVel = nil
local espObjects, espConnections = {}, {}
local lockConnection = nil

-- ---------- 基礎邏輯函式 ----------
local function getCharacterInfo()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    return char, root, hum
end
local character, rootPart, humanoid = getCharacterInfo()

-- ---------- 核心功能區域 ----------

-- 1. 飛行邏輯
local function flyLoop()
    while flyEnabled do
        if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 and not hoverEnabled then
            rootPart.CFrame = rootPart.CFrame + (camera.CFrame.LookVector * speed)
            rootPart.Velocity = Vector3.new(0,0,0)
        end
        task.wait(interval)
    end
end

-- 2. 懸停邏輯
local function toggleHover(state)
    hoverEnabled = state
    if hoverEnabled then
        if not bodyVel and rootPart then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.new(0,0,0)
            bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVel.Parent = rootPart
        end
    else
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
    end
end

-- 3. ESP 邏輯 (修正：不顯示隊友)
local function addESP(char)
    if not char or char == player.Character then return end
    
    -- 隊友檢查：如果是同隊則不顯示 ESP
    local targetPlayer = Players:GetPlayerFromCharacter(char)
    if targetPlayer and player.Team and targetPlayer.Team == player.Team then return end

    if not char:FindFirstChild("ESP_Highlight") then
        local h = Instance.new("Highlight", char)
        h.Name = "ESP_Highlight"
        h.FillColor = Color3.fromRGB(255, 50, 50) -- 敵人顯示紅色
        h.FillTransparency = 0.5
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        espObjects[char] = h
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do if p.Character then addESP(p.Character) end end
        espConnections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(c) if espEnabled then task.wait(1) addESP(c) end end)
        end)
    else
        for char, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
        espObjects = {}
        if espConnections.PlayerAdded then espConnections.PlayerAdded:Disconnect() end
    end
end

-- 4. 鎖頭邏輯 (修正：加入隊伍與存活檢查)
local function getNearestHead()
    local nearest, dist = nil, math.huge
    local myTeam = player.Team

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            -- 1. 隊伍檢查
            if myTeam and p.Team == myTeam then continue end
            
            -- 2. 存活檢查
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < dist then 
                    dist = d 
                    nearest = p.Character.Head 
                end
            end
        end
    end
    return nearest
end

local function toggleLock(state)
    lockHeadEnabled = state
    if state then
        lockConnection = RunService.RenderStepped:Connect(function()
            local target = getNearestHead()
            if target then
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            end
        end)
    else
        if lockConnection then lockConnection:Disconnect() end
    end
end

-- ---------- UI 構建 (同 v1.3.0 現代化風格) ----------
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "NekoModernGui"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 300)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(50, 50, 60)
stroke.Thickness = 1.5

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.Text = "NEKO HUB v1.3.1"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -50)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 0
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0)
    lab.Position = UDim2.new(0, 12, 0, 0)
    lab.Text = name
    lab.TextColor3 = Color3.fromRGB(200, 200, 200)
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 13
    lab.BackgroundTransparency = 1
    lab.TextXAlignment = Enum.TextXAlignment.Left

    local toggleFrame = Instance.new("Frame", btn)
    toggleFrame.Size = UDim2.new(0, 30, 0, 16)
    toggleFrame.Position = UDim2.new(1, -42, 0.5, -8)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", toggleFrame)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        callback(active)
    end)
end

-- ---------- 功能綁定 ----------
createToggle("視角瞬移 (Fly)", function(s) flyEnabled = s if s then task.spawn(flyLoop) end end)
createToggle("空中懸停 (Hover)", function(s) toggleHover(s) end)
createToggle("玩家透視 (ESP)", function(s) toggleESP(s) end)
createToggle("鎖定最近敵方 (Aim)", function(s) toggleLock(s) end)

-- ---------- 拖拽邏輯 ----------
local dragStart, startPos, dragging
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = i.Position startPos = mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

-- 重生處理
player.CharacterAdded:Connect(function()
    task.wait(1)
    character, rootPart, humanoid = getCharacterInfo()
    if espEnabled then toggleESP(false) toggleESP(true) end -- 重生後刷新 ESP
end)

print("掛貓 v1.3.1 已載入 (含隊友過濾)")

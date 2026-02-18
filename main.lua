-- [[ 掛貓豪華整合版 v1.3.2 ]]
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
    return char, char:WaitForChild("HumanoidRootPart", 5), char:WaitForChild("Humanoid", 5)
end
local character, rootPart, humanoid = getCharacterInfo()

-- ---------- 核心功能區域 ----------

-- 1. 飛行與懸停
local function flyLoop()
    while flyEnabled do
        if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 and not hoverEnabled then
            rootPart.CFrame = rootPart.CFrame + (camera.CFrame.LookVector * speed)
            rootPart.Velocity = Vector3.new(0,0,0)
        end
        task.wait(interval)
    end
end

local function toggleHover(state)
    hoverEnabled = state
    if hoverEnabled then
        if not bodyVel and rootPart then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.zero
            bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVel.Parent = rootPart
        end
    else
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
    end
end

-- 2. ESP 邏輯 (敵人紅、隊友綠)
local function addESP(char)
    if not char or char == player.Character then return end
    local targetPlayer = Players:GetPlayerFromCharacter(char)
    if not targetPlayer then return end

    local isTeammate = player.Team and targetPlayer.Team == player.Team
    local highlightColor = isTeammate and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)

    if not char:FindFirstChild("ESP_Highlight") then
        local h = Instance.new("Highlight", char)
        h.Name = "ESP_Highlight"
        h.FillColor = highlightColor
        h.FillTransparency = 0.6
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.OutlineTransparency = 0.2
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

-- 3. 鎖頭
local function getNearestEnemyHead()
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if player.Team and p.Team == player.Team then continue end -- 跳過隊友
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < dist then dist = d nearest = p.Character.Head end
            end
        end
    end
    return nearest
end

local function toggleLock(state)
    lockHeadEnabled = state
    if state then
        lockConnection = RunService.RenderStepped:Connect(function()
            local target = getNearestEnemyHead()
            if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position) end
        end)
    else
        if lockConnection then lockConnection:Disconnect() end
    end
end

-- ---------- UI 介面構築 ----------
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "NekoHub_v1.3.2"
screenGui.ResetOnSpawn = false

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 280, 0, 320)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

-- 最小化後的小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 50, 0, 50)
miniButton.Position = mainFrame.Position
miniButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
miniButton.Text = "貓"
miniButton.Font = Enum.Font.GothamBold
miniButton.TextSize = 24
miniButton.TextColor3 = Color3.fromRGB(255,255,255)
miniButton.Visible = false
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)

-- 頂部欄
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "掛貓 NEKO v1.3.2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

-- 最小化按鈕
local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -70, 0, 5)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.BackgroundTransparency = 1

-- 關閉按鈕
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1

-- 功能清單
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -55)
container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 0
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0)
    lab.Position = UDim2.new(0, 15, 0, 0)
    lab.Text = name
    lab.TextColor3 = Color3.fromRGB(220, 220, 220)
    lab.Font = Enum.Font.Gotham
    lab.BackgroundTransparency = 1
    lab.TextXAlignment = Enum.TextXAlignment.Left

    local toggleFrame = Instance.new("Frame", btn)
    toggleFrame.Size = UDim2.new(0, 34, 0, 18)
    toggleFrame.Position = UDim2.new(1, -45, 0.5, -9)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", toggleFrame)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 2, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 220, 120) or Color3.fromRGB(70, 70, 80)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        callback(active)
    end)
end

-- ---------- UI 交互邏輯 ----------

-- 最小化與還原
minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniButton.Position = mainFrame.Position
    miniButton.Visible = true
end)

miniButton.MouseButton1Click:Connect(function()
    miniButton.Visible = false
    mainFrame.Visible = true
end)

-- 關閉腳本
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    toggleESP(false)
    toggleLock(false)
    toggleHover(false)
    flyEnabled = false
end)

-- 拖拽功能 (修正：小球與主面板同步位置)
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = i.Position startPos = obj.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
makeDraggable(topBar.Parent)
makeDraggable(miniButton)

-- ---------- 綁定功能 ----------
createToggle("視角瞬移 (Fly)", function(s) flyEnabled = s if s then task.spawn(flyLoop) end end)
createToggle("空中懸停 (Hover)", toggleHover)
createToggle("全體透視 (敵人紅/隊友綠)", toggleESP)
createToggle("自動鎖頭 (僅敵人)", toggleLock)

player.CharacterAdded:Connect(function()
    task.wait(1)
    character, rootPart, humanoid = getCharacterInfo()
end)

print("掛貓 v1.3.2 載入成功！")

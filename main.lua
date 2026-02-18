-- [[ 掛貓豪華整合版 v1.3.6 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心變數 ----------
local flyEnabled, hoverEnabled, espEnabled, lockHeadEnabled = false, false, false, false
local speed, interval = 6, 0.05
local bodyVel = nil
local espObjects = {}

-- ---------- 強化隊伍判定 ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    local myTeam = player.Team
    local targetTeam = targetPlayer.Team
    
    -- 檢查 Team 物件
    if myTeam and targetTeam then
        return myTeam ~= targetTeam
    end
    -- 檢查 TeamColor (備用方案)
    if player.TeamColor ~= targetPlayer.TeamColor then
        return true
    end
    -- 沒分隊則視為對手
    return true
end

-- ---------- 核心功能區域 ----------

-- 1. 飛行與懸停
local function updateMovement()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if flyEnabled and root and hum then
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (camera.CFrame.LookVector * speed)
            root.Velocity = Vector3.zero
        elseif hoverEnabled then
            root.Velocity = Vector3.zero -- 懸停時強制動能為零
        end
    end
end

RunService.Heartbeat:Connect(updateMovement)

local function toggleHover(state)
    hoverEnabled = state
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if hoverEnabled and root then
        if not bodyVel then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.zero
            bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bodyVel.Parent = root
        end
    else
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
    end
end

-- 2. ESP 持續偵測 (解決新玩家/重生問題)
task.spawn(function()
    while true do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local char = p.Character
                    if not char:FindFirstChild("ESP_Highlight") then
                        local enemy = isEnemy(p)
                        local h = Instance.new("Highlight")
                        h.Name = "ESP_Highlight"
                        h.FillColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
                        h.FillTransparency = 0.5
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.Parent = char
                        espObjects[char] = h
                    else
                        -- 定期校正顏色 (防止中途換隊)
                        local h = char.ESP_Highlight
                        local enemy = isEnemy(p)
                        h.FillColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
                    end
                end
            end
        end
        task.wait(2) -- 每 2 秒全地圖掃描一次
    end
end)

-- 3. 穩定鎖頭
task.spawn(function()
    while true do
        if lockHeadEnabled then
            local nearest, dist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local screenPoint = camera:WorldToViewportPoint(p.Character.Head.Position)
                        local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = p.Character.Head
                        end
                    end
                end
            end
            if nearest then
                camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position)
            end
        end
        RunService.RenderStepped:Wait() -- 跟隨螢幕刷新率同步
    end
end)

-- ---------- UI 拖拽功能 ----------
local function makeDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ---------- UI 介面 ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.3.6"
screenGui.ResetOnSpawn = false

-- 小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 60, 0, 60)
miniButton.Position = UDim2.new(0, 20, 0.5, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniButton.Text = "Neko"; miniButton.Font = Enum.Font.SourceSansBold
miniButton.TextScaled = true; miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.Visible = false; miniButton.ZIndex = 10
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)
makeDraggable(miniButton)

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.ZIndex = 5; Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
makeDraggable(mainFrame)

-- 標題欄
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 40); topBar.BackgroundTransparency = 1; topBar.ZIndex = 6

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0); titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "NEKO HUB v1.3.6"; titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 14
titleLabel.BackgroundTransparency = 1; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 7

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 5)
minBtn.Text = "─"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255); minBtn.BackgroundTransparency = 1; minBtn.ZIndex = 7

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeBtn.BackgroundTransparency = 1; closeBtn.ZIndex = 7

-- 功能容器
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -55); container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1; container.ScrollBarThickness = 0; container.ZIndex = 6
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 45); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 7
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0); lab.Position = UDim2.new(0, 12, 0, 0)
    lab.Text = name; lab.TextColor3 = Color3.fromRGB(220, 220, 220); lab.Font = Enum.Font.Gotham; lab.BackgroundTransparency = 1; lab.TextXAlignment = Enum.TextXAlignment.Left; lab.ZIndex = 8

    local tFrame = Instance.new("Frame", btn)
    tFrame.Size = UDim2.new(0, 30, 0, 16); tFrame.Position = UDim2.new(1, -40, 0.5, -8)
    tFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 80); tFrame.ZIndex = 8; Instance.new("UICorner", tFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tFrame)
    dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.ZIndex = 9; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(tFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(70, 70, 80)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        callback(active)
    end)
end

-- ---------- 綁定與交互 ----------
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); espEnabled = false; lockHeadEnabled = false; toggleHover(false) end)

createToggle("視角飛行 (Fly)", function(s) flyEnabled = s end)
createToggle("空中懸停 (Hover)", toggleHover)
createToggle("持續掃描透視 (ESP)", function(s) 
    espEnabled = s 
    if not s then 
        for _, h in pairs(espObjects) do pcall(function() h:Destroy() end) end 
        espObjects = {}
    end 
end)
createToggle("穩定鎖頭 (Aim)", function(s) lockHeadEnabled = s end)

print("掛貓 v1.3.6 已載入 - 解決所有失效問題")

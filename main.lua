-- [[ 掛貓 NEKO HUB v1.4.2 - 圖片修復版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心變數 ----------
local walkSpeedEnabled = false
local flyEnabled = false
local espEnabled = false
local lockHeadEnabled = false

local speedPower = 120 -- 你喜歡的移速加成
local flyPower = 60

-- ---------- 1. 隊伍判定 (針對競爭者深度修復) ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    
    -- 如果遊戲有隊伍系統，判斷顏色
    if targetPlayer.TeamColor ~= player.TeamColor then
        return true
    end
    
    -- 某些模式下即便顏色一樣也可能是敵人 (如個人賽)，但通常顏色不同最準確
    return false
end

-- ---------- 2. 核心邏輯迴圈 ----------
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [移速加成]
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- [真正飛行/懸停]
    local bv = root:FindFirstChild("NekoFlyForce")
    if flyEnabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "NekoFlyForce"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Parent = root
        end
        bv.Velocity = (hum.MoveDirection.Magnitude > 0) and (camera.CFrame.LookVector * flyPower) or Vector3.zero
    else
        if bv then bv:Destroy() end
    end

    -- [鎖頭]
    if lockHeadEnabled then
        local nearest = nil
        local minDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local dist = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = p.Character.Head
                end
            end
        end
        if nearest then
            camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position)
        end
    end
end)

-- ---------- 3. UI 構建 (排除黑板問題) ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.2"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.Active = true -- 讓面板能接收點擊
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- 拖拉邏輯 (直接綁在面板上，不加蓋板)
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- 小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 50, 0, 50)
miniButton.Position = UDim2.new(0, 10, 0.5, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
miniButton.Text = "🐱"; miniButton.TextSize = 25; miniButton.TextColor3 = Color3.new(1,1,1)
miniButton.Visible = false; miniButton.ZIndex = 50
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1,0)

-- 標題區域
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40); title.Text = "  NEKO HUB v1.4.2"; title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1
title.ZIndex = 6

-- 縮小按鈕
local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -35, 0, 5)
minBtn.Text = "─"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1; minBtn.ZIndex = 10

-- 功能按鈕容器
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -60); container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1; container.ScrollBarThickness = 0; container.ZIndex = 6
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = "  " .. name; btn.TextColor3 = Color3.new(0.8, 0.8, 0.8); btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.ZIndex = 7
    Instance.new("UICorner", btn)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 50)
        callback(active)
    end)
end

-- 交互
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)

-- 功能
createToggle("移速加成 (Speed)", function(s) walkSpeedEnabled = s end)
createToggle("真正飛行 (Fly/Hover)", function(s) flyEnabled = s end)
createToggle("透視 (ESP)", function(s) 
    espEnabled = s 
    if not s then 
        for _, p in pairs(Players:GetPlayers()) do 
            if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP:Destroy() end 
        end 
    end
end)
createToggle("自動鎖頭 (Aimbot)", function(s) lockHeadEnabled = s end)

-- ESP 循環 (優化顏色判斷)
task.spawn(function()
    while true do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local char = p.Character
                    local enemy = isEnemy(p)
                    local targetColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
                    local h = char:FindFirstChild("Neko_ESP") or Instance.new("Highlight", char)
                    h.Name = "Neko_ESP"; h.FillColor = targetColor; h.OutlineColor = Color3.new(1,1,1)
                end
            end
        end
        task.wait(1)
    end
end)

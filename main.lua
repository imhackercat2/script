-- [[ 掛貓 NEKO HUB v1.3.11 - 穩定開發版 ]]
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

local speedPower = 100 -- 移速強度
local flyPower = 50   -- 飛行強度

-- ---------- 1. 隊伍判定 (針對競爭者優化) ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    -- 競爭者專用：如果隊伍顏色不同，或是一方沒有隊伍，皆視為敵人
    if player.TeamColor ~= targetPlayer.TeamColor then
        return true
    end
    if player.Team ~= targetPlayer.Team then
        return true
    end
    return false
end

-- ---------- 2. 核心功能迴圈 ----------
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [移速加成邏輯] - 你的新點子
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- [真正飛行/懸停邏輯]
    local bv = root:FindFirstChild("NekoFlyForce")
    if flyEnabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "NekoFlyForce"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Parent = root
        end
        
        if hum.MoveDirection.Magnitude > 0 then
            bv.Velocity = camera.CFrame.LookVector * flyPower
        else
            bv.Velocity = Vector3.new(0, 0, 0) -- 這裡達成真正的懸停
        end
    else
        if bv then bv:Destroy() end
    end

    -- [自動鎖頭]
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

-- ---------- 3. ESP 邏輯 (瞬間啟動) ----------
local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local enemy = isEnemy(p)
            local targetColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
            
            local h = char:FindFirstChild("Neko_ESP")
            if espEnabled then
                if not h then
                    h = Instance.new("Highlight", char)
                    h.Name = "Neko_ESP"
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
                h.FillColor = targetColor
                h.Enabled = true
            else
                if h then h.Enabled = false end
            end
        end
    end
end

-- ---------- 4. UI 與拖動 (暴力修復) ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.1"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320); mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- 這裡是重點：拖動把手放在 mainFrame 之外或最頂層
local dragHandle = Instance.new("TextButton", screenGui)
dragHandle.Size = UDim2.size(mainFrame.Size.X.Offset, 40)
dragHandle.Position = mainFrame.Position
dragHandle.BackgroundTransparency = 1; dragHandle.Text = ""
dragHandle.ZIndex = 999 -- 最高層級

local function syncUI()
    dragHandle.Position = mainFrame.Position
end

-- 拖動邏輯
local dragging, dragStart, startPos
dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        syncUI()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- UI 內容
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40); title.Text = "  NEKO HUB v1.4.1"; title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1

local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -60); container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1; container.ScrollBarThickness = 0
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = "  " .. name; btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    btn.Font = Enum.Font.Gotham; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 50)
        callback(active)
    end)
end

-- 綁定功能
createToggle("移速加成 (Speed)", function(s) walkSpeedEnabled = s end)
createToggle("真正飛行 (Fly/Hover)", function(s) flyEnabled = s end)
createToggle("透視 (ESP)", function(s) espEnabled = s; updateESP() end)
createToggle("自動鎖頭 (Aimbot)", function(s) lockHeadEnabled = s end)

-- ESP 循環
task.spawn(function()
    while true do
        if espEnabled then updateESP() end
        task.wait(1)
    end
end)

print("NEKO v1.4.1 載入成功，已修復所有邏輯與拖動問題。")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態 ]
_G.FlyEnabled = false
_G.WalkSpeedEnabled = false
_G.AimEnabled = false
_G.ESPEnabled = false

local flySpeed = 90
local walkSpeedMultiplier = 125

-- [ UI 構建 ]
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v190"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 320)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", mainFrame)

-- 標題列 (負責拖動)
local title = Instance.new("TextLabel", mainFrame)
title.Text = "  NEKO HUB v1.9.0"
title.Size = UDim2.new(1, 0, 0, 40)
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold

-- 拖動功能
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function() dragging = false end)

-- 關閉按鈕
local close = Instance.new("TextButton", mainFrame)
close.Text = "✕"; close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundTransparency = 1; close.TextColor3 = Color3.new(1, 0.3, 0.3)
close.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- 滾動清單
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)

local function addT(txt, color, varName)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 40); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    b.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        b.BackgroundColor3 = _G[varName] and color or Color3.fromRGB(45, 45, 50)
    end)
end

addT("感應飛行 (Fly)", Color3.fromRGB(0, 150, 255), "FlyEnabled")
addT("透視 (ESP)", Color3.fromRGB(0, 200, 100), "ESPEnabled")
addT("暴力鎖頭 (Aim)", Color3.fromRGB(0, 200, 100), "AimEnabled")
addT("加移速 (Speed)", Color3.fromRGB(0, 200, 100), "WalkSpeedEnabled")

-- [ 判定與物理 ]
local function isEnemy(p)
    if not p or p == player or not p.Character then return false end
    if player.Team and p.Team then return player.Team ~= p.Team end
    return tostring(player.TeamColor) ~= tostring(p.TeamColor)
end

RunService.Heartbeat:Connect(function()
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- 飛行與穩定懸停
    local bPos = root:FindFirstChild("NekoPos")
    local bVel = root:FindFirstChild("NekoVel")
    
    if _G.FlyEnabled then
        if not bPos then bPos = Instance.new("BodyPosition", root); bPos.Name = "NekoPos"; bPos.MaxForce = Vector3.new(1e6, 1e6, 1e6); bPos.D = 500; bPos.P = 10000 end
        if not bVel then bVel = Instance.new("BodyVelocity", root); bVel.Name = "NekoVel"; bVel.MaxForce = Vector3.new(1e6, 1e6, 1e6) end
        
        -- 核心判定：只有按鍵 MoveDirection > 0.1 才是真正的移動
        if hum.MoveDirection.Magnitude > 0.1 then
            bPos.MaxForce = Vector3.new(0, 0, 0) -- 移動時關閉位置鎖定
            bVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bVel.Velocity = camera.CFrame.LookVector * flySpeed
            _G.LastFlyPos = root.Position
        else
            -- 沒按鍵：鎖死位置 (懸停)
            if not _G.LastFlyPos then _G.LastFlyPos = root.Position end
            bVel.MaxForce = Vector3.new(0, 0, 0)
            bPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bPos.Position = _G.LastFlyPos
        end
        root.RotVelocity = Vector3.zero
    else
        if bPos then bPos:Destroy() end
        if bVel then bVel:Destroy() end
        _G.LastFlyPos = nil
    end

    -- 移速
    if _G.WalkSpeedEnabled and hum.MoveDirection.Magnitude > 0.1 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * walkSpeedMultiplier, root.Velocity.Y, hum.MoveDirection.Z * walkSpeedMultiplier)
    end

    -- 鎖頭
    if _G.AimEnabled then
        local target, minD = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; target = p.Character.Head end
            end
        end
        if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position) end
    end
end)

-- [ ESP ]
task.spawn(function()
    while task.wait(0.5) do
        if not screenGui.Parent then break end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local h = p.Character:FindFirstChild("NekoESP")
                if _G.ESPEnabled then
                    if not h then h = Instance.new("Highlight", p.Character); h.Name = "NekoESP" end
                    h.Enabled = true; h.FillColor = isEnemy(p) and Color3.new(1,0,0) or Color3.new(0,1,0)
                elseif h then h.Enabled = false end
            end
        end
    end
end)

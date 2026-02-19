-- [[ 掛貓 NEKO HUB v1.5.0 - 終極穩定版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態區 ]
local walkSpeedEnabled, flyEnabled, espEnabled, lockHeadEnabled, forceFFA = false, false, false, false, false
local speedPower, flyPower, hoverPos = 125, 70, nil

-- [ 智慧判定邏輯 ]
local function checkIsEnemy(target)
    if not target or target == player then return false end
    if forceFFA then return true end -- 強制 FFA 模式：全場皆敵
    if player.Team and target.Team then return player.Team ~= target.Team end
    if tostring(player.TeamColor) ~= tostring(target.TeamColor) then return true end
    return (player.Neutral and target.Neutral)
end

-- [ UI 核心 ]
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_Final"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 360); mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- [ 拖動與標題 ]
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 45); topBar.BackgroundTransparency = 1
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0); title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "NEKO HUB v1.5.0"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1

local dragStart, startPos, dragging
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function() dragging = false end)

-- [ 縮小與貓球邏輯 ]
local mini = Instance.new("TextButton", screenGui)
mini.Size = UDim2.new(0, 50, 0, 50); mini.Position = UDim2.new(0, 10, 0.5, 0); mini.BackgroundColor3 = Color3.fromRGB(255, 150, 0); mini.Text = "🐱"; mini.Visible = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(1,0)

local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 7); minBtn.Text = "─"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; mini.Visible = true end)
mini.MouseButton1Click:Connect(function() mini.Visible = false; mainFrame.Visible = true end)

-- [ 徹底關閉按鈕 ]
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 7); closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1, 0.4, 0.4); closeBtn.BackgroundTransparency = 1
closeBtn.MouseButton1Click:Connect(function() 
    walkSpeedEnabled = false; flyEnabled = false; espEnabled = false; lockHeadEnabled = false
    for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP:Destroy() end end
    screenGui:Destroy() 
end)

-- [ 按鈕工廠 ]
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -70); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

local function addT(name, color, cb)
    local b = Instance.new("TextButton", scroll); b.Size = UDim2.new(1, 0, 0, 42); b.BackgroundColor3 = Color3.fromRGB(40,40,50); b.Text = "  "..name; b.TextColor3 = Color3.new(0.9,0.9,0.9); b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b)
    local on = false; b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and color or Color3.fromRGB(40,40,50); cb(on) end)
end

addT("移速加成 (Speed)", Color3.fromRGB(0, 180, 100), function(v) walkSpeedEnabled = v end)
addT("硬性飛行/懸停 (Fly)", Color3.fromRGB(0, 180, 100), function(v) flyEnabled = v end)
addT("強制 FFA 模式", Color3.fromRGB(200, 120, 0), function(v) forceFFA = v end)
addT("智能透視 (ESP)", Color3.fromRGB(0, 180, 100), function(v) espEnabled = v end)
addT("暴力鎖頭 (Aim)", Color3.fromRGB(0, 180, 100), function(v) lockHeadEnabled = v end)

-- [ 核心循環 ]
local hb; hb = RunService.Heartbeat:Connect(function()
    if not screenGui or not screenGui.Parent then hb:Disconnect(); return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end
    local f = root:FindFirstChild("NekoF")
    if flyEnabled then
        if not f then f = Instance.new("BodyVelocity", root); f.Name = "NekoF"; f.MaxForce = Vector3.new(1e6, 1e6, 1e6) end
        if hum.MoveDirection.Magnitude > 0 then f.Velocity = camera.CFrame.LookVector * flyPower; hoverPos = nil
        else if not hoverPos then hoverPos = root.CFrame end f.Velocity = Vector3.zero; root.CFrame = hoverPos end
    elseif f then f:Destroy(); hoverPos = nil end
    if lockHeadEnabled then
        local t, minD = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if checkIsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; t = p.Character.Head end
            end
        end
        if t then camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position) end
    end
end)

-- [ ESP 循環 ]
task.spawn(function()
    while screenGui and screenGui.Parent do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local isE = checkIsEnemy(p); local h = p.Character:FindFirstChild("Neko_ESP") or Instance.new("Highlight", p.Character)
                    h.Name = "Neko_ESP"; h.FillColor = isE and Color3.new(1,0,0) or Color3.new(0,1,0); h.Enabled = true
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP.Enabled = false end end
        end
        task.wait(1)
    end
end)

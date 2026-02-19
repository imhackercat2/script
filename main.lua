-- [[ 掛貓 NEKO HUB v1.4.8 - UI 與功能同步修復版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ---------- 狀態變數 ----------
local walkSpeedEnabled = false
local flyEnabled = false
local espEnabled = false
local lockHeadEnabled = false
local forceFFA = false 

local speedPower = 125 
local flyPower = 70
local hoverPos = nil 

-- ---------- 1. 判定邏輯 ----------
local function checkIsEnemy(target)
    if not target or target == player then return false end
    if forceFFA then return true end
    if player.Team and target.Team then return player.Team ~= target.Team end
    if player.TeamColor ~= target.TeamColor then return true end
    return (player.Neutral and target.Neutral)
end

-- ---------- 2. 核心功能迴圈 (修復關閉邏輯) ----------
local hbConnection
hbConnection = RunService.Heartbeat:Connect(function()
    if not screenGui or not screenGui.Parent then 
        hbConnection:Disconnect() -- UI 被銷毀時徹底停止
        return 
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [移速] 
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- [飛行與硬性懸停]
    local force = root:FindFirstChild("NekoForce")
    if flyEnabled then
        if not force then
            force = Instance.new("BodyVelocity", root)
            force.Name = "NekoForce"
            force.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        end
        if hum.MoveDirection.Magnitude > 0 then
            force.Velocity = camera.CFrame.LookVector * flyPower
            hoverPos = nil
        else
            if not hoverPos then hoverPos = root.CFrame end
            force.Velocity = Vector3.zero
            root.CFrame = hoverPos -- 硬性釘住
        end
    else
        if force then force:Destroy() end
        hoverPos = nil
    end

    -- [鎖頭]
    if lockHeadEnabled then
        local targetHead = nil
        local maxDist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if checkIsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                local h = p.Character:FindFirstChild("Humanoid")
                if h and h.Health > 0 then
                    local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                    if d < maxDist then maxDist = d; targetHead = p.Character.Head end
                end
            end
        end
        if targetHead then camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position) end
    end
end)

-- ---------- 3. UI 完整構築 (不准再刪除邏輯) ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.8"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 360)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- 標題與拖動
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 45); topBar.BackgroundTransparency = 1
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0); title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "NEKO HUB v1.4.8"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1

local dragStart, startPos, dragging
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function() dragging = false end)

-- [修復] 縮小按鈕
local mini = Instance.new("TextButton", screenGui)
mini.Size = UDim2.new(0, 50, 0, 50); mini.Position = UDim2.new(0, 10, 0.5, 0); mini.BackgroundColor3 = Color3.fromRGB(255, 120, 0); mini.Text = "🐱"; mini.Visible = false; mini.ZIndex = 100
Instance.new("UICorner", mini).CornerRadius = UDim.new(1, 0)

local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 7); minBtn.Text = "─"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; mini.Visible = true end)
mini.MouseButton1Click:Connect(function() mini.Visible = false; mainFrame.Visible = true end)

-- [修復] 關閉按鈕 (關閉後強制重置所有功能)
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 7); closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1, 0.3, 0.3); closeBtn.BackgroundTransparency = 1
closeBtn.MouseButton1Click:Connect(function() 
    walkSpeedEnabled = false; flyEnabled = false; espEnabled = false; lockHeadEnabled = false; forceFFA = false
    screenGui:Destroy() 
end)

-- 按鈕容器
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -65); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 7)

local function makeToggle(name, color, cb)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 40); b.BackgroundColor3 = Color3.fromRGB(40,40,50); b.Text = "  " .. name; b.TextColor3 = Color3.new(0.9,0.9,0.9); b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b)
    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        b.BackgroundColor3 = on and color or Color3.fromRGB(40,40,50)
        cb(on)
    end)
end

makeToggle("移速加成 (Speed)", Color3.fromRGB(0, 180, 100), function(v) walkSpeedEnabled = v end)
makeToggle("硬性飛行/懸停 (Fly)", Color3.fromRGB(0, 180, 100), function(v) flyEnabled = v end)
makeToggle("強制 FFA 模式", Color3.fromRGB(200, 100, 0), function(v) forceFFA = v end)
makeToggle("智能透視 (ESP)", Color3.fromRGB(0, 180, 100), function(v) espEnabled = v end)
makeToggle("暴力鎖頭 (Aim)", Color3.fromRGB(0, 180, 100), function(v) lockHeadEnabled = v end)

-- ESP 更新 (增加 Enabled 檢查)
task.spawn(function()
    while true do
        if not screenGui or not screenGui.Parent then break end
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local isE = checkIsEnemy(p)
                    local h = p.Character:FindFirstChild("Neko_ESP") or Instance.new("Highlight", p.Character)
                    h.Name = "Neko_ESP"; h.FillColor = isE and Color3.new(1, 0, 0) or Color3.new(0, 1, 0); h.Enabled = true
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP.Enabled = false end end
        end
        task.wait(1)
    end
end)

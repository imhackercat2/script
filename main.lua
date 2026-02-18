-- [[ 掛貓 NEKO HUB v1.4.6 - 多重判定優化版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ---------- 狀態變數 ----------
local walkSpeedEnabled, flyEnabled, espEnabled, lockHeadEnabled = false, false, false, false
local speedPower, flyPower = 120, 65

-- ---------- 核心：多重情況判定函式 ----------
local function checkIsEnemy(target)
    if not target or target == player then return false end
    
    -- 情況 A: 標準隊伍物件不同 (最常見)
    if player.Team and target.Team then
        return player.Team ~= target.Team
    end
    
    -- 情況 B: 隊伍顏色不同 (Arsenal 常用)
    if player.TeamColor ~= target.TeamColor then
        return true
    end
    
    -- 情況 C: 檢查是否為「中立」或是「FFA大亂鬥」
    -- 如果遊戲設定所有人都在同一個隊伍但可以互相傷害，這裡會回傳 true
    if player.Neutral or (player.Team == target.Team and target.Neutral) then
        return true
    end

    -- 情況 D: 字符串比對 (最後兜底，防止物件引用失效)
    if tostring(player.TeamColor) ~= tostring(target.TeamColor) then
        return true
    end

    return false
end

-- ---------- 核心循環 (物理與鎖頭) ----------
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [移速]
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- [飛行/懸停]
    local force = root:FindFirstChild("NekoVelo")
    if flyEnabled then
        if not force then
            force = Instance.new("BodyVelocity", root)
            force.Name = "NekoVelo"
            force.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        end
        force.Velocity = (hum.MoveDirection.Magnitude > 0) and (camera.CFrame.LookVector * flyPower) or Vector3.zero
    else
        if force then force:Destroy() end
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

-- ---------- UI 介面 (穩定版) ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.6"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320); mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- 拖動區域 (頂部藍色小條)
local dragBar = Instance.new("Frame", mainFrame)
dragBar.Size = UDim2.new(1, 0, 0, 40); dragBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", dragBar)
title.Size = UDim2.new(1, 0, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
title.Text = "NEKO HUB v1.4.6"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1

-- 拖動實作
local dragging, dragStart, startPos
dragBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = i.Position; startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function() dragging = false end)

-- 控制按鈕
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,0.3,0.3); closeBtn.BackgroundTransparency = 1

local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 5)
minBtn.Text = "─"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1

-- 功能按鈕清單
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 7)

local function makeToggle(name, cb)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 40); b.BackgroundColor3 = Color3.fromRGB(40,40,50); b.Text = "  " .. name; b.TextColor3 = Color3.new(0.9,0.9,0.9); b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b)
    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        b.BackgroundColor3 = on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(40,40,50)
        cb(on)
    end)
end

local mini = Instance.new("TextButton", screenGui)
mini.Size = UDim2.new(0, 50, 0, 50); mini.Position = UDim2.new(0, 10, 0.5, 0); mini.BackgroundColor3 = Color3.fromRGB(255,140,0); mini.Text = "🐱"; mini.Visible = false; Instance.new("UICorner", mini).CornerRadius = UDim.new(1,0)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; mini.Visible = true end)
mini.MouseButton1Click:Connect(function() mini.Visible = false; mainFrame.Visible = true end)

-- 功能綁定
makeToggle("加移速 (Speed)", function(v) walkSpeedEnabled = v end)
makeToggle("飛行/懸停 (Fly)", function(v) flyEnabled = v end)
makeToggle("智能透視 (ESP)", function(v) espEnabled = v end)
makeToggle("暴力鎖頭 (Aim)", function(v) lockHeadEnabled = v end)

-- ESP 持續掃描 (多重邏輯應用)
task.spawn(function()
    while true do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local color = checkIsEnemy(p) and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
                    local h = p.Character:FindFirstChild("Neko_ESP") or Instance.new("Highlight", p.Character)
                    h.Name = "Neko_ESP"; h.FillColor = color; h.Enabled = true
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP.Enabled = false end
            end
        end
        task.wait(1)
    end
end)

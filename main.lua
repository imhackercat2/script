-- [[ 掛貓 NEKO HUB v1.4.7 - 最終適配強化版 ]]
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
local forceFFA = false -- 新增：手動 FFA 強制敵對開關

local speedPower = 125 
local flyPower = 70
local hoverPos = nil -- 用於鎖定高度的座標

-- ---------- 1. 核心：超級判定大腦 (增加 FFA 強制模式) ----------
local function checkIsEnemy(target)
    if not target or target == player then return false end
    
    -- 如果開啟了強制 FFA 模式，除了自己全是敵人
    if forceFFA then return true end
    
    -- 正常判定邏輯
    if player.Team and target.Team then
        return player.Team ~= target.Team
    end
    if player.TeamColor ~= target.TeamColor then
        return true
    end
    -- 針對某些 FFA 模式但隊伍顏色相同的特殊檢查
    if player.Neutral and target.Neutral then
        return true
    end
    return false
end

-- ---------- 2. 核心循環 (解決下墜飛行問題) ----------
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [移速]
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- [硬性飛行與懸停]
    if flyEnabled then
        if hum.MoveDirection.Magnitude > 0 then
            -- 移動時使用速度
            root.Velocity = camera.CFrame.LookVector * flyPower
            hoverPos = nil -- 移動時解鎖高度
        else
            -- 停止移動時：硬性鎖定坐標 (解決你說的往下掉的問題)
            if not hoverPos then
                hoverPos = root.CFrame -- 記錄停下來那一刻的位置
            end
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = hoverPos -- 強制將你「釘」在原地
        end
    else
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

-- ---------- 3. UI 介面 (加入 FFA 開關) ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.7"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 360) -- 稍微加高一點放新按鈕
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- 拖拉與標題 (略，保持 v1.4.6 的穩定結構)
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 45); topBar.BackgroundTransparency = 1
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0); title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "NEKO HUB v1.4.7"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1

local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function() dragging = false end)

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 7); closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,0.3,0.3); closeBtn.BackgroundTransparency = 1; closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
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

-- 功能綁定
makeToggle("移速加成 (Speed)", Color3.fromRGB(0, 180, 100), function(v) walkSpeedEnabled = v end)
makeToggle("硬性飛行/懸停 (Fly)", Color3.fromRGB(0, 180, 100), function(v) flyEnabled = v end)
makeToggle("強制 FFA 模式", Color3.fromRGB(200, 100, 0), function(v) forceFFA = v end) -- 解決兵工廠 FFA 問題
makeToggle("智能透視 (ESP)", Color3.fromRGB(0, 180, 100), function(v) espEnabled = v end)
makeToggle("暴力鎖頭 (Aim)", Color3.fromRGB(0, 180, 100), function(v) lockHeadEnabled = v end)

-- ESP 更新
task.spawn(function()
    while true do
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

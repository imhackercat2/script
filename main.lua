local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態控制 ]
_G.NekoFly = false
_G.NekoSpeed = false
_G.NekoAim = false
_G.NekoESP = false

local flySpeed = 90
local walkSpeed = 125

-- [ UI 構建 ]
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoFinal_v191"
screenGui.ResetOnSpawn = false

-- 1. 小貓按鈕 (縮小時顯示)
local miniBtn = Instance.new("TextButton", screenGui)
miniBtn.Size = UDim2.new(0, 50, 0, 50)
miniBtn.Position = UDim2.new(0, 20, 0.5, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniBtn.Text = "🐱"
miniBtn.Visible = false
miniBtn.ZIndex = 10
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0)

-- 2. 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 320)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- 拖動功能 (通用)
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = obj.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function() dragging = false end)
end
makeDraggable(mainFrame)
makeDraggable(miniBtn)

-- 面板內容
local title = Instance.new("TextLabel", mainFrame)
title.Text = "  NEKO HUB v1.9.1"; title.Size = UDim2.new(1, 0, 0, 40); title.TextColor3 = Color3.new(1, 1, 1); title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.Font = Enum.Font.GothamBold

-- 縮小按鈕
local min = Instance.new("TextButton", mainFrame)
min.Text = "─"; min.Size = UDim2.new(0, 30, 0, 30); min.Position = UDim2.new(1, -65, 0, 5); min.BackgroundTransparency = 1; min.TextColor3 = Color3.new(1,1,1)
min.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniBtn.Visible = true end)
miniBtn.MouseButton1Click:Connect(function() miniBtn.Visible = false; mainFrame.Visible = true end)

-- 關閉按鈕 (徹底清理)
local close = Instance.new("TextButton", mainFrame)
close.Text = "✕"; close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -35, 0, 5); close.BackgroundTransparency = 1; close.TextColor3 = Color3.new(1, 0.3, 0.3)
close.MouseButton1Click:Connect(function()
    _G.NekoFly = false; _G.NekoSpeed = false; _G.NekoAim = false; _G.NekoESP = false
    screenGui:Destroy()
end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)

local function addT(txt, color, varName)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 40); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(45, 45, 50); b.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        b.BackgroundColor3 = _G[varName] and color or Color3.fromRGB(45, 45, 50)
    end)
end

addT("感應飛行 (Fly)", Color3.fromRGB(0, 150, 255), "NekoFly")
addT("透視 (ESP)", Color3.fromRGB(0, 200, 100), "NekoESP")
addT("暴力鎖頭 (Aim)", Color3.fromRGB(0, 200, 100), "NekoAim")
addT("加移速 (Speed)", Color3.fromRGB(0, 200, 100), "NekoSpeed")

-- [ 判定與循環 ]
local function isEnemy(p)
    if not p or p == player or not p.Character then return false end
    if player.Team and p.Team then return player.Team ~= p.Team end
    return tostring(player.TeamColor) ~= tostring(p.TeamColor)
end

RunService.Heartbeat:Connect(function()
    -- 如果 UI 已被刪除，停止所有邏輯並清理物理物件
    if not screenGui.Parent then 
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and root:FindFirstChild("NekoForce") then root.NekoForce:Destroy() end
        return 
    end

    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- 飛行優化：使用單一 BodyVelocity 並強制鎖定 Y 軸
    local f = root:FindFirstChild("NekoForce")
    if _G.NekoFly then
        if not f then
            f = Instance.new("BodyVelocity", root); f.Name = "NekoForce"
            f.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        end
        if hum.MoveDirection.Magnitude > 0.1 then
            f.Velocity = camera.CFrame.LookVector * flySpeed
        else
            f.Velocity = Vector3.new(0, 0, 0) -- 靜止時不抖動的秘密：速度歸零，MaxForce 撐住
        end
        root.RotVelocity = Vector3.zero
    elseif f then
        f:Destroy()
    end

    -- 移速
    if _G.NekoSpeed and hum.MoveDirection.Magnitude > 0.1 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * walkSpeed, root.Velocity.Y, hum.MoveDirection.Z * walkSpeed)
    end

    -- 鎖頭
    if _G.NekoAim then
        local t, minD = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; t = p.Character.Head end
            end
        end
        if t then camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position) end
    end
end)

-- ESP 循環 (增加安全退出)
task.spawn(function()
    while true do
        if not screenGui.Parent then break end
        if _G.NekoESP then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local h = p.Character:FindFirstChild("NekoESP") or Instance.new("Highlight", p.Character)
                    h.Name = "NekoESP"; h.Enabled = true; h.FillColor = isEnemy(p) and Color3.new(1,0,0) or Color3.new(0,1,0)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("NekoESP") then p.Character.NekoESP.Enabled = false end end
        end
        task.wait(0.5)
    end
end)

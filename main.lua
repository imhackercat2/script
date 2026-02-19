-- [[ 掛貓 NEKO HUB v1.5.5 - 按鍵感應飛行修正版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態變數 ]
local walkSpeedEnabled, flyEnabled, espEnabled, lockHeadEnabled, forceFFA = false, false, false, false, false
local speedPower, flyPower = 125, 85

-- [ UI 拖動函數 ]
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = obj.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function() dragging = false end)
end

-- [ UI 構建 ]
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v155"; screenGui.ResetOnSpawn = false

local miniBall = Instance.new("TextButton", screenGui)
miniBall.Size = UDim2.new(0, 55, 0, 55); miniBall.Position = UDim2.new(0, 20, 0.5, 0); miniBall.BackgroundColor3 = Color3.fromRGB(255, 140, 0); miniBall.Text = "🐱"; miniBall.Visible = false; miniBall.ZIndex = 10; Instance.new("UICorner", miniBall).CornerRadius = UDim.new(1, 0)
makeDraggable(miniBall)

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 360); mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180); mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); mainFrame.BorderSizePixel = 0; Instance.new("UICorner", mainFrame)
makeDraggable(mainFrame)

-- [ 功能清單 ]
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -75); scroll.Position = UDim2.new(0, 10, 0, 55); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0; Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

local function addToggle(name, color, cb)
    local b = Instance.new("TextButton", scroll); b.Size = UDim2.new(1, 0, 0, 42); b.BackgroundColor3 = Color3.fromRGB(35, 35, 45); b.Text = "  " .. name; b.TextColor3 = Color3.new(0.9, 0.9, 0.9); b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b)
    local on = false; b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and color or Color3.fromRGB(35, 35, 45); cb(on) end)
end

addToggle("移速加成 (Speed)", Color3.fromRGB(0, 180, 100), function(v) walkSpeedEnabled = v end)
addToggle("按鍵感應飛行 (Fly)", Color3.fromRGB(0, 180, 100), function(v) flyEnabled = v end)
addToggle("強制 FFA 模式", Color3.fromRGB(255, 120, 0), function(v) forceFFA = v end)
addToggle("智能透視 (ESP)", Color3.fromRGB(0, 180, 100), function(v) espEnabled = v end)
addToggle("暴力鎖頭 (Aim)", Color3.fromRGB(0, 180, 100), function(v) lockHeadEnabled = v end)

-- UI 控制按鈕
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Text = "✕"; closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 7); closeBtn.TextColor3 = Color3.new(1, 0.4, 0.4); closeBtn.BackgroundTransparency = 1; closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Text = "─"; minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 7); minBtn.TextColor3 = Color3.new(1, 1, 1); minBtn.BackgroundTransparency = 1; minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniBall.Visible = true end)
miniBall.MouseButton1Click:Connect(function() miniBall.Visible = false; mainFrame.Visible = true end)

-- [ 判定與核心循環 ]
local function checkIsEnemy(t)
    if not t or t == player then return false end
    if forceFFA then return true end
    if player.Team and t.Team then return player.Team ~= t.Team end
    return tostring(player.TeamColor) ~= tostring(t.TeamColor)
end

RunService.Heartbeat:Connect(function()
    if not screenGui or not screenGui.Parent then return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- 1. 移速
    if walkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end
    
    -- 2. 感應式飛行 (核心優化)
    local f = root:FindFirstChild("NekoFly")
    if flyEnabled and hum.MoveDirection.Magnitude > 0 then
        -- 只有在按住移動鍵時才創建/更新推力
        if not f then
            f = Instance.new("BodyVelocity", root)
            f.Name = "NekoFly"
            f.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        end
        f.Velocity = camera.CFrame.LookVector * flyPower
    else
        -- 沒操作或沒開功能，立刻刪除推力，讓重力接管
        if f then f:Destroy() end
    end

    -- 3. 鎖頭
    if lockHeadEnabled then
        local target, minD = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if checkIsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; target = p.Character.Head end
            end
        end
        if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position) end
    end
end)

-- [ 4. ESP 循環 ]
task.spawn(function()
    while screenGui and screenGui.Parent do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local h = p.Character:FindFirstChild("Neko_ESP") or Instance.new("Highlight", p.Character)
                    h.Name = "Neko_ESP"; h.FillColor = checkIsEnemy(p) and Color3.new(1,0,0) or Color3.new(0,1,0); h.Enabled = true
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Neko_ESP") then p.Character.Neko_ESP.Enabled = false end end
        end
        task.wait(1)
    end
end)

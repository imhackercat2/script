-- [[ 掛貓 NEKO HUB v1.8.0 - 座標鎖定與 FFA 終極修正 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態控制 ]
_G.FlyEnabled = false
_G.WalkSpeedEnabled = false
_G.AimEnabled = false
_G.ESPEnabled = false
_G.ForceFFA = false

local flyPower, speedPower = 90, 125
local hoverPos = nil -- 用於存儲鬆開按鍵瞬間的座標

-- [ UI 與拖動 ]
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "Neko_v1.8"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 340); mainFrame.Position = UDim2.new(0.5, -120, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Instance.new("UICorner", mainFrame)

local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = obj.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (i.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (i.Position - dragStart).Y) end end)
    UserInputService.InputEnded:Connect(function() dragging = false end)
end
makeDraggable(mainFrame)

-- [ 功能切換 ]
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -80); scroll.Position = UDim2.new(0, 10, 0, 60); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
local layout = Instance.new("UIListLayout", scroll); layout.Padding = UDim.new(0, 5)

local function addT(txt, color, varName)
    local b = Instance.new("TextButton", scroll); b.Size = UDim2.new(1, 0, 0, 40); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(40, 40, 45); b.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        b.BackgroundColor3 = _G[varName] and color or Color3.fromRGB(40, 40, 45)
    end)
end

addT("感應飛行 (Fly)", Color3.fromRGB(0, 150, 255), "FlyEnabled")
addT("強制 FFA 模式", Color3.fromRGB(255, 100, 0), "ForceFFA")
addT("透視 (ESP)", Color3.fromRGB(0, 200, 100), "ESPEnabled")
addT("暴力鎖頭 (Aim)", Color3.fromRGB(0, 200, 100), "AimEnabled")
addT("加移速 (Speed)", Color3.fromRGB(0, 200, 100), "WalkSpeedEnabled")

-- [ 判定與物理核心 ]
local function isEnemy(p)
    if not p or p == player then return false end
    if _G.ForceFFA then return true end -- 這裡直接讀取全域變數
    if player.Team and p.Team then return player.Team ~= p.Team end
    return tostring(player.TeamColor) ~= tostring(p.TeamColor)
end

RunService.Heartbeat:Connect(function()
    if not screenGui.Parent then return end
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- 飛行鎖定核心 (CFrame 錨定法)
    if _G.FlyEnabled then
        local bv = root:FindFirstChild("NekoFly") or Instance.new("BodyVelocity", root)
        bv.Name = "NekoFly"; bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)

        if hum.MoveDirection.Magnitude > 0 then
            -- 移動中：物理推進
            bv.Velocity = camera.CFrame.LookVector * flyPower
            hoverPos = nil -- 清除懸停座標
        else
            -- 停止移動：強制座標鎖定 (核心修正)
            if not hoverPos then hoverPos = root.CFrame end
            bv.Velocity = Vector3.zero
            root.CFrame = hoverPos -- 這裡會把你強行釘在鬆手的那一刻
        end
        root.RotVelocity = Vector3.zero
    else
        if root:FindFirstChild("NekoFly") then root.NekoFly:Destroy() end
        hoverPos = nil
    end

    -- 移速
    if _G.WalkSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedPower, root.Velocity.Y, hum.MoveDirection.Z * speedPower)
    end

    -- 鎖頭
    if _G.AimEnabled then
        local t, minD = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; t = p.Character.Head end
            end
        end
        if t then camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position) end
    end
end)

-- [ ESP 穩定版 ]
task.spawn(function()
    while task.wait(0.3) do
        if not screenGui.Parent then break end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local h = p.Character:FindFirstChild("NekoHighlight")
                if _G.ESPEnabled then
                    if not h then h = Instance.new("Highlight", p.Character); h.Name = "NekoHighlight" end
                    h.FillColor = isEnemy(p) and Color3.new(1,0,0) or Color3.new(0,1,0)
                    h.Enabled = true
                elseif h then
                    h.Enabled = false
                end
            end
        end
    end
end)

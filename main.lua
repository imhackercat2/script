-- [[ NEKO HUB v2.1.0 - MOBILE OPTIMIZED ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 全域狀態控制 ]
_G.NekoFly = false
_G.NekoSpeed = false
_G.NekoAim = false
_G.NekoESP = false

-- [ 手機端參數調優 ]
local flySpeed = 75
local speedMultiplier = 50 -- 手機端建議不要太高，否則搖桿很難控制方向
local hoverPos = nil

-- ---------- [ 1. 手機專用觸控拖動系統 ] ----------
local function makeMobileDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    -- 針對觸控 Began
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    -- 全域觸控移動監測
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- 觸控結束
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ---------- [ 2. UI 構建 (加大手機點擊區域) ] ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_Mobile_v21"
screenGui.ResetOnSpawn = false

-- 小貓按鈕 (手機端加大至 60x60 方便點擊)
local miniBtn = Instance.new("TextButton", screenGui)
miniBtn.Size = UDim2.new(0, 60, 0, 60)
miniBtn.Position = UDim2.new(0, 30, 0.4, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniBtn.Text = "🐱"
miniBtn.Visible = false
miniBtn.ZIndex = 10
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0)
makeMobileDraggable(miniBtn)

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 340) -- 稍微加寬
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", mainFrame)
makeMobileDraggable(mainFrame)

-- 標題
local title = Instance.new("TextLabel", mainFrame)
title.Text = "  NEKO MOBILE v2.1.0"; title.Size = UDim2.new(1, 0, 0, 50)
title.TextColor3 = Color3.new(1, 1, 1); title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left

-- 頂部控制
local function createTopBtn(txt, pos, color, cb)
    local b = Instance.new("TextButton", mainFrame)
    b.Text = txt; b.Size = UDim2.new(0, 40, 0, 40); b.Position = pos
    b.BackgroundTransparency = 1; b.TextColor3 = color; b.TextSize = 20
    b.MouseButton1Click:Connect(cb)
end
createTopBtn("─", UDim2.new(1, -85, 0, 5), Color3.new(1,1,1), function() mainFrame.Visible = false; miniBtn.Visible = true end)
createTopBtn("✕", UDim2.new(1, -45, 0, 5), Color3.new(1,0.3,0.3), function() _G.NekoFly = false; screenGui:Destroy() end)
miniBtn.MouseButton1Click:Connect(function() miniBtn.Visible = false; mainFrame.Visible = true end)

-- 功能按鈕列表
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -80); scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

local function addToggle(txt, varName)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 48); b.Text = "  "..txt; b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    b.TextColor3 = Color3.new(0.9, 0.9, 0.9); b.TextXAlignment = Enum.TextXAlignment.Left
    b.Font = Enum.Font.Gotham; b.TextSize = 16
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        b.BackgroundColor3 = _G[varName] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(40, 40, 45)
    end)
end

addToggle("手機感應飛行", "NekoFly")
addToggle("詳細透視 (距離/名字)", "NekoESP")
addToggle("自動鎖頭 (Aim)", "NekoAim")
addToggle("穩定移速加成", "NekoSpeed")

-- ---------- [ 3. 核心物理邏輯 ] ----------
local function getIsEnemy(p)
    if not p or p == player or not p.Character then return false end
    if player.Team and p.Team then return player.Team ~= p.Team end
    return true
end

RunService.Heartbeat:Connect(function()
    if not screenGui.Parent then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- [ 手機飛行：解決重力下墜誤判 ]
    local force = root:FindFirstChild("NekoFlyForce")
    if _G.NekoFly then
        if not force then
            force = Instance.new("BodyVelocity", root)
            force.Name = "NekoFlyForce"; force.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        end
        -- 手機端搖桿判定 Magnitude 需略大於 0.1 避免靈敏度誤觸
        if hum.MoveDirection.Magnitude > 0.15 then
            force.Velocity = camera.CFrame.LookVector * flySpeed
        else
            force.Velocity = Vector3.new(0, 0, 0) -- 靜止懸停
        end
        root.RotVelocity = Vector3.zero
    elseif force then
        force:Destroy()
    end

    -- [ 移速：針對搖桿優化 ]
    if _G.NekoSpeed and hum.MoveDirection.Magnitude > 0.15 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * speedMultiplier, root.Velocity.Y, hum.MoveDirection.Z * speedMultiplier)
    end

    -- [ 鎖頭 ]
    if _G.NekoAim then
        local target = nil; local minD = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if getIsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; target = p.Character.Head end
            end
        end
        if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position) end
    end
end)

-- ---------- [ 4. ESP 系統 (手機端輕量化) ] ----------
task.spawn(function()
    while task.wait(0.5) do -- 降低手機 CPU 負擔
        if not screenGui.Parent then break end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local bgui = head:FindFirstChild("NekoESP_Gui")
                    if _G.NekoESP then
                        if not bgui then
                            bgui = Instance.new("BillboardGui", head); bgui.Name = "NekoESP_Gui"
                            bgui.Size = UDim2.new(0, 80, 0, 40); bgui.AlwaysOnTop = true; bgui.StudsOffset = Vector3.new(0, 3, 0)
                            local tl = Instance.new("TextLabel", bgui)
                            tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0
                            tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
                        end
                        local dist = math.floor((head.Position - camera.CFrame.Position).Magnitude)
                        local isE = getIsEnemy(p)
                        bgui.TextLabel.Text = p.Name .. "\n[" .. dist .. "m]"
                        bgui.TextLabel.TextColor3 = isE and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
                    elseif bgui then
                        bgui:Destroy()
                    end
                end
            end
        end
    end
end)

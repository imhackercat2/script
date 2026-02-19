-- [[ NEKO HUB v2.7.0 - STABLE MOBILE ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態管理 ]
_G.NekoFly = false
_G.NekoSpeed = false
_G.NekoAim = false
_G.NekoESP = false

local flySpeed = 85
local walkSpeedAdd = 90 
local runningConnections = {} -- 用於徹底關閉

-- ---------- [ 1. 拖動功能 ] ----------
local function makeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function() dragging = false end)
end

-- ---------- [ 2. UI 構建 ] ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v27"; screenGui.ResetOnSpawn = false

local miniBtn = Instance.new("TextButton", screenGui)
miniBtn.Size = UDim2.new(0, 60, 0, 60); miniBtn.Position = UDim2.new(0, 20, 0.5, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0); miniBtn.Text = "🐱"; miniBtn.Visible = false; miniBtn.ZIndex = 20
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0); makeDraggable(miniBtn)

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 250, 0, 320); mainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Instance.new("UICorner", mainFrame)
makeDraggable(mainFrame)

local title = Instance.new("TextLabel", mainFrame)
title.Text = "  NEKO HUB v2.7.0"; title.Size = UDim2.new(1, 0, 0, 45); title.TextColor3 = Color3.new(1, 1, 1); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 10

local function createTopBtn(txt, pos, color, cb)
    local b = Instance.new("TextButton", mainFrame)
    b.Text = txt; b.Size = UDim2.new(0, 35, 0, 35); b.Position = pos; b.BackgroundTransparency = 1; b.TextColor3 = color; b.ZIndex = 15; b.TextSize = 20; b.MouseButton1Click:Connect(cb)
end
createTopBtn("─", UDim2.new(1, -80, 0, 5), Color3.new(1,1,1), function() mainFrame.Visible = false; miniBtn.Visible = true end)
createTopBtn("✕", UDim2.new(1, -40, 0, 5), Color3.new(1,0.3,0.3), function() 
    _G.NekoFly = false; _G.NekoSpeed = false; _G.NekoAim = false; _G.NekoESP = false
    for _, conn in pairs(runningConnections) do conn:Disconnect() end
    screenGui:Destroy() 
end)
miniBtn.MouseButton1Click:Connect(function() miniBtn.Visible = false; mainFrame.Visible = true end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -70); scroll.Position = UDim2.new(0, 10, 0, 55); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

local function addToggle(txt, varName)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 45); b.Text = "  "..txt; b.BackgroundColor3 = Color3.fromRGB(40, 40, 45); b.TextColor3 = Color3.new(1, 1, 1); b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 10; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() _G[varName] = not _G[varName]; b.BackgroundColor3 = _G[varName] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(40, 40, 45) end)
end
addToggle("手機飛行", "NekoFly")
addToggle("透視 (人物+距離)", "NekoESP")
addToggle("自動鎖頭", "NekoAim")
addToggle("移速 (90)", "NekoSpeed")

-- ---------- [ 3. 核心邏輯處理 ] ----------
local hbConn = RunService.Heartbeat:Connect(function()
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    -- 飛行邏輯
    if _G.NekoFly then
        local v = root:FindFirstChild("NekoV") or Instance.new("BodyVelocity", root)
        v.Name = "NekoV"
        hum.PlatformStand = true
        if hum.MoveDirection.Magnitude > 0.1 then
            v.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            v.Velocity = camera.CFrame.LookVector * flySpeed
        else
            v.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            v.Velocity = Vector3.zero -- 鎖死速度，不抖動
        end
        root.RotVelocity = Vector3.zero
    else
        if root:FindFirstChild("NekoV") then root.NekoV:Destroy() end
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    -- 移速
    if _G.NekoSpeed and hum.MoveDirection.Magnitude > 0.1 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * walkSpeedAdd, root.Velocity.Y, hum.MoveDirection.Z * walkSpeedAdd)
    end

    -- 鎖頭
    if _G.NekoAim then
        local t = nil; local minD = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Team ~= player.Team and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                if d < minD then minD = d; t = p.Character.Head end
            end
        end
        if t then camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position) end
    end
end)
table.insert(runningConnections, hbConn)

-- ---------- [ 4. ESP 系統 (0.5s 刷新) ] ----------
task.spawn(function()
    while task.wait(0.5) do
        if not screenGui.Parent then break end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local bgui = head:FindFirstChild("NekoESP")
                    local high = p.Character:FindFirstChild("NekoHigh")
                    if _G.NekoESP then
                        if not bgui then
                            bgui = Instance.new("BillboardGui", head); bgui.Name = "NekoESP"
                            bgui.Size = UDim2.new(0, 80, 0, 30); bgui.AlwaysOnTop = true; bgui.StudsOffset = Vector3.new(0, 2, 0)
                            local tl = Instance.new("TextLabel", bgui); tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.new(1,1,1); tl.Font = Enum.Font.GothamBold; tl.TextSize = 10; tl.TextStrokeTransparency = 0; tl.Parent = bgui
                        end
                        bgui.TextLabel.Text = p.Name .. " [" .. math.floor((head.Position - camera.CFrame.Position).Magnitude) .. "m]"
                        if not high then high = Instance.new("Highlight", p.Character); high.Name = "NekoHigh" end
                        high.Enabled = true; high.FillColor = (p.Team ~= player.Team) and Color3.new(1,0,0) or Color3.new(0,1,0)
                    else
                        if bgui then bgui:Destroy() end
                        if high then high.Enabled = false end
                    end
                end
            end
        end
    end
end)

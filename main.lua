-- [[ NEKO HUB v2.3.0 - ZERO JITTER MOBILE ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- [ 狀態變數 ]
_G.NekoFly = false
_G.NekoSpeed = false
_G.NekoAim = false
_G.NekoESP = false

local flySpeed = 80
local walkSpeedAdd = 100

-- ---------- [ 1. 手機 UI 拖動 (穩定版) ] ----------
local function makeMobileDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ---------- [ 2. UI 構建 ] ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v230"
screenGui.ResetOnSpawn = false

local miniBtn = Instance.new("TextButton", screenGui)
miniBtn.Size = UDim2.new(0, 60, 0, 60); miniBtn.Position = UDim2.new(0, 30, 0.4, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0); miniBtn.Text = "🐱"
miniBtn.Visible = false; miniBtn.ZIndex = 10; Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0)
makeMobileDraggable(miniBtn)

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 340); mainFrame.Position = UDim2.new(0.5, -130, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Instance.new("UICorner", mainFrame)
makeMobileDraggable(mainFrame)

local function createTopBtn(txt, pos, color, cb)
    local b = Instance.new("TextButton", mainFrame)
    b.Text = txt; b.Size = UDim2.new(0, 40, 0, 40); b.Position = pos
    b.BackgroundTransparency = 1; b.TextColor3 = color; b.MouseButton1Click:Connect(cb)
end
createTopBtn("─", UDim2.new(1, -85, 0, 5), Color3.new(1,1,1), function() mainFrame.Visible = false; miniBtn.Visible = true end)
createTopBtn("✕", UDim2.new(1, -45, 0, 5), Color3.new(1,0.3,0.3), function() _G.NekoFly = false; screenGui:Destroy() end)
miniBtn.MouseButton1Click:Connect(function() miniBtn.Visible = false; mainFrame.Visible = true end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -80); scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 0
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

local function addToggle(txt, varName)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 48); b.Text = "  "..txt; b.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    b.TextColor3 = Color3.new(0.9, 0.9, 0.9); b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        b.BackgroundColor3 = _G[varName] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(35, 35, 40)
    end)
end

addToggle("感應飛行 (零抖動)", "NekoFly")
addToggle("詳細透視 (人物高亮)", "NekoESP")
addToggle("自動鎖頭 (Aimbot)", "NekoAim")
addToggle("移速加成 (100)", "NekoSpeed")

-- ---------- [ 3. 核心物理核心 ] ----------
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

    -- [ 飛行優化版 ]
    local force = root:FindFirstChild("NekoFlyForce")
    if _G.NekoFly then
        if not force then
            force = Instance.new("BodyVelocity", root)
            force.Name = "NekoFlyForce"; force.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        end
        
        if hum.MoveDirection.Magnitude > 0.15 then
            -- 移動中：啟動物理推動力，關閉錨定
            root.Anchored = false
            force.Velocity = camera.CFrame.LookVector * flySpeed
        else
            -- 停下時：直接物理錨定 (這絕對不會抖動)
            force.Velocity = Vector3.new(0, 0, 0)
            root.Anchored = true 
        end
        root.RotVelocity = Vector3.new(0,0,0)
    else
        -- 關閉功能時務必解除錨定，否則會卡在空中
        if root.Anchored and not _G.NekoFly then root.Anchored = false end
        if force then force:Destroy() end
    end

    -- [ 移速 ]
    if _G.NekoSpeed and hum.MoveDirection.Magnitude > 0.15 then
        root.Velocity = Vector3.new(hum.MoveDirection.X * walkSpeedAdd, root.Velocity.Y, hum.MoveDirection.Z * walkSpeedAdd)
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

-- ---------- [ 4. ESP 系統 ] ----------
task.spawn(function()
    while task.wait(0.4) do
        if not screenGui.Parent then break end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local bgui = head:FindFirstChild("NekoESP_Gui")
                    local high = p.Character:FindFirstChild("NekoHigh")
                    
                    if _G.NekoESP then
                        if not bgui then
                            bgui = Instance.new("BillboardGui", head); bgui.Name = "NekoESP_Gui"
                            bgui.Size = UDim2.new(0, 100, 0, 40); bgui.AlwaysOnTop = true; bgui.StudsOffset = Vector3.new(0, 3, 0)
                            local tl = Instance.new("TextLabel", bgui)
                            tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0
                            tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
                        end
                        local dist = math.floor((head.Position - camera.CFrame.Position).Magnitude)
                        local isE = getIsEnemy(p)
                        bgui.TextLabel.Text = p.Name .. " [" .. dist .. "m]"
                        bgui.TextLabel.TextColor3 = isE and Color3.new(1, 0.1, 0.1) or Color3.new(0.1, 1, 0.1)
                        
                        if not high then
                            high = Instance.new("Highlight", p.Character); high.Name = "NekoHigh"
                            high.OutlineTransparency = 0.3; high.FillTransparency = 0.5
                        end
                        high.Enabled = true; high.FillColor = bgui.TextLabel.TextColor3
                    else
                        if bgui then bgui:Destroy() end
                        if high then high.Enabled = false end
                    end
                end
            end
        end
    end
end)

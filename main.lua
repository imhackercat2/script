-- [[ 掛貓 NEKO HUB v1.5.1 - 完整邏輯與 UI 守護版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ---------- [ 核心狀態變數 ] ----------
local walkSpeedEnabled = false
local flyEnabled = false
local espEnabled = false
local lockHeadEnabled = false
local forceFFA = false 

local speedPower = 125 
local flyPower = 70
local hoverPos = nil -- 用於硬性鎖定高度

-- ---------- [ 智慧判定大腦 ] ----------
local function checkIsEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then 
        return false 
    end
    
    -- 優先級 1: 強制 FFA 模式 (兵工廠大亂鬥必開)
    if forceFFA then 
        return true 
    end
    
    -- 優先級 2: 標準隊伍對象檢查
    if player.Team and targetPlayer.Team then
        return player.Team ~= targetPlayer.Team
    end
    
    -- 優先級 3: 隊伍顏色名稱檢查 (針對競爭者優化)
    local myColor = tostring(player.TeamColor)
    local targetColor = tostring(targetPlayer.TeamColor)
    if myColor ~= targetColor then
        return true
    end
    
    -- 優先級 4: 中立狀態判定
    if player.Neutral and targetPlayer.Neutral then
        return true
    end

    return false
end

-- ---------- [ UI 組件構建 ] ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NekoHub_v151"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 360)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- 頂部拖動條
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundTransparency = 1
topBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Text = "  NEKO HUB v1.5.1"
title.Size = UDim2.new(1, 0, 1, 0)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.Parent = topBar

-- 拖動功能實作
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    dragging = false
end)

-- ---------- [ 縮小與關閉按鈕 ] ----------
local miniBall = Instance.new("TextButton")
miniBall.Name = "MiniBall"
miniBall.Size = UDim2.new(0, 50, 0, 50)
miniBall.Position = UDim2.new(0, 10, 0.5, 0)
miniBall.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
miniBall.Text = "🐱"
miniBall.TextSize = 25
miniBall.Visible = false
miniBall.Parent = screenGui
Instance.new("UICorner", miniBall).CornerRadius = UDim.new(1, 0)

local minBtn = Instance.new("TextButton")
minBtn.Text = "─"
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -65, 0, 7)
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.BackgroundTransparency = 1
minBtn.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 7)
closeBtn.TextColor3 = Color3.new(1, 0.3, 0.3)
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = mainFrame

-- 按鈕點擊事件
minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniBall.Visible = true
end)

miniBall.MouseButton1Click:Connect(function()
    miniBall.Visible = false
    mainFrame.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    -- 徹底清理所有功能狀態
    walkSpeedEnabled = false
    flyEnabled = false
    espEnabled = false
    lockHeadEnabled = false
    forceFFA = false
    -- 清理 ESP 高亮
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Neko_ESP") then
            p.Character.Neko_ESP:Destroy()
        end
    end
    screenGui:Destroy()
end)

-- ---------- [ 功能列表容器 ] ----------
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 0
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

local function createToggle(name, activeColor, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 42)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    button.Text = "  " .. name
    button.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    button.Font = Enum.Font.Gotham
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = scrollFrame
    Instance.new("UICorner", button)

    local isToggled = false
    button.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        if isToggled then
            button.BackgroundColor3 = activeColor
        else
            button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
        callback(isToggled)
    end)
end

-- 綁定功能按鈕
createToggle("加移速 (Speed Boost)", Color3.fromRGB(0, 180, 100), function(v) walkSpeedEnabled = v end)
createToggle("硬性飛行/懸停 (Fly/Hover)", Color3.fromRGB(0, 180, 100), function(v) flyEnabled = v end)
createToggle("強制 FFA 模式 (敵對全開)", Color3.fromRGB(255, 100, 0), function(v) forceFFA = v end)
createToggle("智能透視 (ESP)", Color3.fromRGB(0, 180, 100), function(v) espEnabled = v end)
createToggle("暴力鎖頭 (Aimbot)", Color3.fromRGB(0, 180, 100), function(v) lockHeadEnabled = v end)

-- ---------- [ 物理與功能核心循環 ] ----------
local heartConnection
heartConnection = RunService.Heartbeat:Connect(function()
    if not screenGui or not screenGui.Parent then
        heartConnection:Disconnect()
        return
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid then return end

    -- [1] 移速邏輯
    if walkSpeedEnabled and humanoid.MoveDirection.Magnitude > 0 then
        rootPart.Velocity = Vector3.new(
            humanoid.MoveDirection.X * speedPower, 
            rootPart.Velocity.Y, 
            humanoid.MoveDirection.Z * speedPower
        )
    end

    -- [2] 飛行與硬性懸停
    local flyForce = rootPart:FindFirstChild("NekoForce")
    if flyEnabled then
        if not flyForce then
            flyForce = Instance.new("BodyVelocity")
            flyForce.Name = "NekoForce"
            flyForce.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            flyForce.Parent = rootPart
        end

        if humanoid.MoveDirection.Magnitude > 0 then
            flyForce.Velocity = camera.CFrame.LookVector * flyPower
            hoverPos = nil -- 移動時清空懸停點
        else
            -- 硬性鎖定高度與位置
            if not hoverPos then
                hoverPos = rootPart.CFrame
            end
            flyForce.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = hoverPos
        end
    else
        if flyForce then
            flyForce:Destroy()
        end
        hoverPos = nil
    end

    -- [3] 自動鎖頭
    if lockHeadEnabled then
        local nearestHead = nil
        local shortestDistance = math.huge
        
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if checkIsEnemy(otherPlayer) and otherPlayer.Character then
                local head = otherPlayer.Character:FindFirstChild("Head")
                local hum = otherPlayer.Character:FindFirstChild("Humanoid")
                
                if head and hum and hum.Health > 0 then
                    local dist = (head.Position - camera.CFrame.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        nearestHead = head
                    end
                end
            end
        end
        
        if nearestHead then
            camera.CFrame = CFrame.new(camera.CFrame.Position, nearestHead.Position)
        end
    end
end)

-- ---------- [ ESP 持續更新掃描 ] ----------
task.spawn(function()
    while screenGui and screenGui.Parent do
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local isEnemyPlayer = checkIsEnemy(p)
                    local esp = p.Character:FindFirstChild("Neko_ESP") or Instance.new("Highlight", p.Character)
                    esp.Name = "Neko_ESP"
                    esp.FillColor = isEnemyPlayer and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
                    esp.Enabled = true
                end
            end
        else
            -- 關閉 ESP
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Neko_ESP") then
                    p.Character.Neko_ESP.Enabled = false
                end
            end
        end
        task.wait(1)
    end
end)

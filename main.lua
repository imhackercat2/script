-- [[ 掛貓 NEKO HUB v1.4.0 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 變數初始化 ----------
local flyEnabled = false
local hoverEnabled = false
local espEnabled = false
local lockHeadEnabled = false
local flySpeed = 50 -- 調整為更適合射擊遊戲的速度

-- ---------- 核心：隊伍判定邏輯 ----------
-- 在《競爭者》中，隊伍顏色是最精準的判別方式
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    
    -- 判斷：只要顏色不同，就是敵人
    if player.TeamColor ~= targetPlayer.TeamColor then
        return true
    end
    
    -- 備用判斷：如果 Team 對象存在且不同
    if player.Team and targetPlayer.Team and player.Team ~= targetPlayer.Team then
        return true
    end

    return false
end

-- ---------- 核心：ESP 功能 ----------
local function clearESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local old = p.Character:FindFirstChild("Neko_ESP")
            if old then old:Destroy() end
        end
    end
end

local function applyESP()
    if not espEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local char = p.Character
            local enemy = isEnemy(p)
            
            -- 顏色定義：敵人紅，隊友綠
            local targetColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
            
            local h = char:FindFirstChild("Neko_ESP")
            if not h then
                h = Instance.new("Highlight")
                h.Name = "Neko_ESP"
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.Parent = char
            end
            h.FillColor = targetColor
        end
    end
end

-- ---------- 核心：飛行與懸停 ----------
-- 使用 Heartbeat 確保每幀同步
RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end
    
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if root and hum then
        -- 核心：飛行位移
        if hum.MoveDirection.Magnitude > 0 then
            local moveDir = hum.MoveDirection
            root.Velocity = moveDir * flySpeed
            -- 保持高度，不掉下去
            if hoverEnabled then
                root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            end
        else
            -- 核心：懸停 (當沒按下移動鍵時)
            if hoverEnabled then
                root.Velocity = Vector3.new(0, 0, 0)
                -- 抵消重力
                root.CFrame = root.CFrame 
            end
        end
    end
end)

-- ---------- 核心：鎖頭 AimLock ----------
task.spawn(function()
    while true do
        if lockHeadEnabled then
            local nearest = nil
            local minDistance = math.huge
            
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local head = p.Character.Head
                        -- 計算螢幕距離與空間距離
                        local dist = (head.Position - camera.CFrame.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            nearest = head
                        end
                    end
                end
            end
            
            if nearest then
                camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position)
            end
        end
        RunService.RenderStepped:Wait()
    end
end)

-- ---------- UI 拖拽功能 (穩定版) ----------
local function makeDraggable(gui, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ---------- UI 介面構築 ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.4.0"
screenGui.ResetOnSpawn = false

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

-- 頂部標題與拖動區域 (分開處理以防按鈕攔截)
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 10

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "NEKO HUB v1.4.0"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11

-- 專用拖拉把手 (不覆蓋按鈕)
local dragHandle = Instance.new("TextButton", topBar)
dragHandle.Size = UDim2.new(1, -70, 1, 0)
dragHandle.BackgroundTransparency = 1
dragHandle.Text = ""
dragHandle.ZIndex = 12
makeDraggable(mainFrame, dragHandle)

-- 小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 60, 0, 60)
miniButton.Position = UDim2.new(0, 20, 0.5, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniButton.Text = "🐱"
miniButton.TextSize = 30
miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.Visible = false
miniButton.ZIndex = 100
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)
makeDraggable(miniButton, miniButton)

-- 縮小/關閉按鈕
local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 35, 0, 35)
minBtn.Position = UDim2.new(1, -75, 0, 7)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundTransparency = 1
minBtn.ZIndex = 20

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 7)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.ZIndex = 20

-- 功能按鈕容器
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -70)
container.Position = UDim2.new(0, 10, 0, 60)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 0
container.ZIndex = 6
Instance.new("UIListLayout", container).Padding = UDim.new(0, 10)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 7
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0)
    lab.Position = UDim2.new(0, 15, 0, 0)
    lab.Text = name
    lab.TextColor3 = Color3.fromRGB(200, 200, 200)
    lab.Font = Enum.Font.Gotham
    lab.BackgroundTransparency = 1
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.ZIndex = 8

    local tFrame = Instance.new("Frame", btn)
    tFrame.Size = UDim2.new(0, 34, 0, 18)
    tFrame.Position = UDim2.new(1, -45, 0.5, -9)
    tFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    tFrame.ZIndex = 8
    Instance.new("UICorner", tFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tFrame)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 2, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.ZIndex = 9
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(tFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        callback(active)
    end)
end

-- ---------- 交互綁定 ----------
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); espEnabled = false; lockHeadEnabled = false end)

createToggle("視角飛行 (Fly)", function(s) flyEnabled = s end)
createToggle("空中懸停 (Hover)", function(s) hoverEnabled = s end)
createToggle("敵紅隊綠 (ESP)", function(s) 
    espEnabled = s 
    if s then applyESP() else clearESP() end 
end)
createToggle("穩定鎖頭 (Aim)", function(s) lockHeadEnabled = s end)

-- ESP 持續監控
task.spawn(function()
    while true do
        if espEnabled then applyESP() end
        task.wait(1.5)
    end
end)

print("掛貓 v1.4.0 穩定版已啟動")

-- [[ 掛貓豪華整合版 v1.3.9 - The Rivals Edition ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心控制變數 ----------
local flyEnabled, hoverEnabled, espEnabled, lockHeadEnabled = false, false, false, false
local speed = 6
local espObjects = {}

-- ---------- 《競爭者》專用隊伍判定 ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    
    -- 優先判斷：如果是競爭者這類遊戲，通常 TeamColor 是最準確的
    if player.TeamColor ~= targetPlayer.TeamColor then
        return true -- 顏色不同即為敵人
    end
    
    -- 次要判斷：標準 Team 物件
    if player.Team and targetPlayer.Team then
        return player.Team ~= targetPlayer.Team
    end
    
    -- 如果都沒設定隊伍，則視為敵人
    return false 
end

-- ---------- ESP 邏輯 (瞬間上色 + 定時掃描) ----------
local function applyESP()
    if not espEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local enemy = isEnemy(p)
            local targetColor = enemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
            
            local h = char:FindFirstChild("Neko_ESP")
            if not h then
                h = Instance.new("Highlight")
                h.Name = "Neko_ESP"
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.Parent = char
                espObjects[char] = h
            end
            h.FillColor = targetColor
        end
    end
end

-- ---------- 核心循環 (飛行/懸停/鎖頭) ----------
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if flyEnabled and root and hum then
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (camera.CFrame.LookVector * speed)
            root.Velocity = Vector3.zero
        elseif hoverEnabled then
            root.Velocity = Vector3.zero
        end
    end

    if lockHeadEnabled then
        local nearest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                local h = p.Character:FindFirstChild("Humanoid")
                if h and h.Health > 0 then
                    -- 檢查距離
                    local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                    if d < dist then 
                        dist = d 
                        nearest = p.Character.Head 
                    end
                end
            end
        end
        if nearest then
            camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position)
        end
    end
end)

-- ---------- UI 拖拽邏輯 (修正判定問題) ----------
local function makeDraggable(gui, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ---------- UI 介面構築 ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.3.9"
screenGui.ResetOnSpawn = false

-- 小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 60, 0, 60)
miniButton.Position = UDim2.new(0, 20, 0.4, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniButton.Text = "🐱"; miniButton.Font = Enum.Font.SourceSansBold
miniButton.TextSize = 35; miniButton.TextColor3 = Color3.fromRGB(255,255,255)
miniButton.Visible = false; miniButton.ZIndex = 100
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", miniButton).Thickness = 2
makeDraggable(miniButton, miniButton)

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.ZIndex = 10; Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- 標題拖動欄 (覆蓋在最上層確保可拖動)
local dragHandle = Instance.new("TextButton", mainFrame)
dragHandle.Size = UDim2.new(1, 0, 0, 45)
dragHandle.BackgroundTransparency = 1; dragHandle.Text = ""
dragHandle.ZIndex = 50
makeDraggable(mainFrame, dragHandle)

local titleLabel = Instance.new("TextLabel", dragHandle)
titleLabel.Size = UDim2.new(1, -70, 1, 0); titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "NEKO HUB v1.3.9"; titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 14; titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 51

local minBtn = Instance.new("TextButton", dragHandle)
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -65, 0, 7)
minBtn.Text = "─"; minBtn.TextColor3 = Color3.fromRGB(255,255,255); minBtn.BackgroundTransparency = 1; minBtn.ZIndex = 52

local closeBtn = Instance.new("TextButton", dragHandle)
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -35, 0, 7)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255,100,100); closeBtn.BackgroundTransparency = 1; closeBtn.ZIndex = 52

-- 功能容器
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -60); container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1; container.ScrollBarThickness = 0; container.ZIndex = 11
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 45); btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1,-50,1,0); lab.Position = UDim2.new(0,12,0,0)
    lab.Text = name; lab.TextColor3 = Color3.fromRGB(200,200,200); lab.Font = Enum.Font.Gotham; lab.BackgroundTransparency = 1; lab.TextXAlignment = Enum.TextXAlignment.Left; lab.ZIndex = 13

    local tFrame = Instance.new("Frame", btn)
    tFrame.Size = UDim2.new(0,30,0,16); tFrame.Position = UDim2.new(1,-40,0.5,-8)
    tFrame.BackgroundColor3 = Color3.fromRGB(70,70,80); tFrame.ZIndex = 13; Instance.new("UICorner", tFrame).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame", tFrame)
    dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.ZIndex = 14; Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(tFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(70, 70, 80)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        callback(active)
    end)
end

-- ---------- 綁定與循環 ----------
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); espEnabled = false; lockHeadEnabled = false end)

createToggle("視角飛行 (Fly)", function(s) flyEnabled = s end)
createToggle("空中懸停 (Hover)", function(s) hoverEnabled = s end)
createToggle("瞬間/持續透視 (ESP)", function(s) 
    espEnabled = s 
    if s then applyESP() else 
        for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end 
        espObjects = {}
    end 
end)
createToggle("穩定鎖頭 (Aim)", function(s) lockHeadEnabled = s end)

task.spawn(function()
    while true do
        if espEnabled then applyESP() end
        task.wait(2)
    end
end)

print("掛貓 v1.3.9 《競爭者》專用版已加載")

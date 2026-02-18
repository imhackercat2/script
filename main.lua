-- [[ 掛貓豪華整合版 v1.3.4 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心變數 ----------
local flyEnabled, hoverEnabled, espEnabled, lockHeadEnabled = false, false, false, false
local speed, interval = 6, 0.05
local bodyVel = nil
local espObjects, espConnections = {}, {}
local lockConnection = nil

-- ---------- 隊伍判定工具 (核心修復) ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    
    -- 如果遊戲沒有隊伍系統，全部視為敵人
    if #game:GetService("Teams"):GetTeams() == 0 then return true end
    
    -- 檢查隊伍屬性
    if player.Team ~= targetPlayer.Team then
        return true
    end
    
    -- 雙重檢查：檢查隊伍顏色 (針對某些特殊遊戲)
    if player.TeamColor ~= targetPlayer.TeamColor then
        return true
    end
    
    return false
end

-- ---------- 功能邏輯 ----------
local function addESP(char)
    if not char or char == player.Character then return end
    local targetPlayer = Players:GetPlayerFromCharacter(char)
    if not targetPlayer then return end

    -- 清除舊的
    if char:FindFirstChild("ESP_Highlight") then char.ESP_Highlight:Destroy() end

    local enemyStatus = isEnemy(targetPlayer)
    local highlightColor = enemyStatus and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)

    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.FillColor = highlightColor
    h.FillTransparency = 0.5
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.Parent = char
    espObjects[char] = h
end

local function toggleESP(state)
    espEnabled = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do if p.Character then addESP(p.Character) end end
        espConnections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(c) if espEnabled then task.wait(1) addESP(c) end end)
        end)
    else
        for char, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
        espObjects = {}
        if espConnections.PlayerAdded then espConnections.PlayerAdded:Disconnect() end
    end
end

local function toggleLock(state)
    lockHeadEnabled = state
    if state then
        lockConnection = RunService.RenderStepped:Connect(function()
            local nearest, dist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
                        if d < dist then dist = d nearest = p.Character.Head end
                    end
                end
            end
            if nearest then camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position) end
        end)
    else
        if lockConnection then lockConnection:Disconnect() end
    end
end

-- ---------- 拖拽邏輯 ----------
local function makeDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ---------- UI 介面 ----------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "NekoHub_v1.3.4"
screenGui.ResetOnSpawn = false

-- 小球 (修正外觀)
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Size = UDim2.new(0, 60, 0, 60)
miniButton.Position = UDim2.new(0.1, 0, 0.4, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
miniButton.Text = "Neko"
miniButton.Font = Enum.Font.GothamBlack
miniButton.TextScaled = true -- 修正字體大小問題
miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.Visible = false
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", miniButton)
stroke.Thickness = 3; stroke.Color = Color3.fromRGB(255,255,255)
makeDraggable(miniButton)

-- 主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
makeDraggable(mainFrame)

-- 標題列按鈕
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundTransparency = 1

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "×"; closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 25; closeBtn.BackgroundTransparency = 1

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -65, 0, 5)
minBtn.Text = "─"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 20; minBtn.BackgroundTransparency = 1

-- 功能清單
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -50)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1; container.ScrollBarThickness = 0
Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 45); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = ""; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0); lab.Position = UDim2.new(0, 12, 0, 0)
    lab.Text = name; lab.TextColor3 = Color3.fromRGB(200, 200, 200)
    lab.Font = Enum.Font.Gotham; lab.BackgroundTransparency = 1; lab.TextXAlignment = Enum.TextXAlignment.Left

    local tFrame = Instance.new("Frame", btn)
    tFrame.Size = UDim2.new(0, 30, 0, 16); tFrame.Position = UDim2.new(1, -40, 0.5, -8)
    tFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70); Instance.new("UICorner", tFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tFrame)
    dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(tFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(60, 60, 70)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        callback(active)
    end)
end

-- ---------- 綁定與交互 ----------
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); toggleESP(false); toggleLock(false) end)

createToggle("視角飛行 (Fly)", function(s) flyEnabled = s; if s then task.spawn(function()
    while flyEnabled do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and player.Character.Humanoid.MoveDirection.Magnitude > 0 then
            root.CFrame += camera.CFrame.LookVector * speed; root.Velocity = Vector3.zero
        end
        task.wait(interval)
    end
end) end end)

createToggle("敵紅隊綠 (ESP)", toggleESP)
createToggle("自動鎖頭 (Aim)", toggleLock)

print("掛貓 v1.3.4 修復完成")

-- [[ 掛貓豪華整合版 v1.3.5 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ---------- 核心變數 ----------
local flyEnabled, espEnabled, lockHeadEnabled = false, false, false
local speed, interval = 6, 0.05
local espObjects, espConnections = {}, {}
local lockConnection = nil

-- ---------- 強化隊伍判定 ----------
local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    -- 判斷是否有隊伍系統
    local teams = game:GetService("Teams"):GetTeams()
    if #teams <= 1 then return true end -- 沒分隊則視為對手
    
    -- 檢查 Team 物件或 TeamColor
    if player.Team ~= targetPlayer.Team or player.TeamColor ~= targetPlayer.TeamColor then
        return true
    end
    return false
end

-- ---------- 功能邏輯 ----------
local function addESP(char)
    if not char or char == player.Character then return end
    local targetPlayer = Players:GetPlayerFromCharacter(char)
    if not targetPlayer then return end

    if char:FindFirstChild("ESP_Highlight") then char.ESP_Highlight:Destroy() end

    local enemyStatus = isEnemy(targetPlayer)
    -- 強制定義：敵人紅，隊友綠
    local highlightColor = enemyStatus and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)

    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.FillColor = highlightColor
    h.FillTransparency = 0.5
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
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

-- ---------- 拖動邏輯 ----------
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

-- ---------- UI 介面構築 ----------
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "NekoHub_v1.3.5"
screenGui.ResetOnSpawn = false

-- 1. 修復版小球
local miniButton = Instance.new("TextButton", screenGui)
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.new(0, 60, 0, 60)
miniButton.Position = UDim2.new(0, 50, 0.5, 0)
miniButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
miniButton.Text = "Neko"
miniButton.Font = Enum.Font.SourceSansBold
miniButton.TextScaled = true -- 讓文字自動縮放填充
miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.Visible = false
miniButton.ZIndex = 10
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", miniButton).Thickness = 2
makeDraggable(miniButton)

-- 2. 修復版主面板
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 260, 0, 300)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
makeDraggable(mainFrame)

-- 3. 標題與按鈕區 (確保可見)
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 6

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "NEKO HUB v1.3.5"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -65, 0, 5)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundTransparency = 1
minBtn.TextSize = 18
minBtn.ZIndex = 7

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 18
closeBtn.ZIndex = 7

-- 4. 功能滾動區
local container = Instance.new("ScrollingFrame", mainFrame)
container.Size = UDim2.new(1, -20, 1, -55)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 0
container.ZIndex = 6
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)

local function createToggle(name, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 7
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local lab = Instance.new("TextLabel", btn)
    lab.Size = UDim2.new(1, -50, 1, 0)
    lab.Position = UDim2.new(0, 10, 0, 0)
    lab.Text = name
    lab.TextColor3 = Color3.fromRGB(220, 220, 220)
    lab.Font = Enum.Font.Gotham
    lab.BackgroundTransparency = 1
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.ZIndex = 8

    local tFrame = Instance.new("Frame", btn)
    tFrame.Size = UDim2.new(0, 30, 0, 16)
    tFrame.Position = UDim2.new(1, -40, 0.5, -8)
    tFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    tFrame.ZIndex = 8
    Instance.new("UICorner", tFrame).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tFrame)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.ZIndex = 9
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(tFrame, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(70, 70, 80)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        callback(active)
    end)
end

-- ---------- 按鈕交互 ----------
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; miniButton.Visible = true end)
miniButton.MouseButton1Click:Connect(function() miniButton.Visible = false; mainFrame.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); toggleESP(false); lockHeadEnabled = false end)

-- ---------- 功能綁定 ----------
createToggle("視角飛行 (Fly)", function(s) 
    flyEnabled = s 
    if s then task.spawn(function()
        while flyEnabled do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if char.Humanoid.MoveDirection.Magnitude > 0 then
                    char.HumanoidRootPart.CFrame += camera.CFrame.LookVector * speed
                    char.HumanoidRootPart.Velocity = Vector3.zero
                end
            end
            task.wait(interval)
        end
    end) end 
end)

createToggle("敵紅隊綠 (ESP)", toggleESP)

createToggle("自動鎖頭 (Aim)", function(s)
    lockHeadEnabled = s
    if s then
        RunService:BindToRenderStep("NekoLock", 1, function()
            if not lockHeadEnabled then RunService:UnbindFromRenderStep("NekoLock") return end
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
        RunService:UnbindFromRenderStep("NekoLock")
    end
end)

print("掛貓 v1.3.5 修復完成 - 標題與小球已校正")

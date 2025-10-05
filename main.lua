-- 掛貓簡易腳本 v1.2.0
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- 初始化角色
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    return char, root, humanoid
end

local character, rootPart, humanoid = getCharacter()

-- 控制變數
local flyEnabled = false
local hoverEnabled = false
local lockEnabled = false
local speed = 6
local interval = 0.05
local bodyVel = nil

-- ESP功能
local espEnabled = false
local espObjects = {}

-- 加 ESP
local function addESPToCharacter(char)
    if not char or char == player.Character then return end
    if char:FindFirstChild("ESP_Highlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    espObjects[char] = highlight
end

-- 移除 ESP
local function removeESPFromCharacter(char)
    if espObjects[char] then
        espObjects[char]:Destroy()
        espObjects[char] = nil
    end
end

-- 開啟 ESP
local function enableESP()
    espEnabled = true
    spawn(function()
        while espEnabled do
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    addESPToCharacter(plr.Character)
                end
            end
            task.wait(1)
        end
    end)
end

-- 關閉 ESP
local function disableESP()
    espEnabled = false
    for char, highlight in pairs(espObjects) do
        if highlight then highlight:Destroy() end
    end
    espObjects = {}
end

-- 找最近玩家
local function getNearestPlayer()
    local nearest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("HumanoidRootPart") then
            local mag = (plr.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if mag < dist then
                dist = mag
                nearest = plr
            end
        end
    end
    return nearest
end

-- 鎖頭功能
local function lockOnNearestPlayer()
    spawn(function()
        while lockEnabled do
            local target = getNearestPlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local headPos = target.Character.Head.Position
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, headPos)
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "掛貓Gui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 主介面
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 310)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- 標題列
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Draggable = true

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "簡易腳本 v1.2.0"
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

-- 最小化按鈕
local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "─"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- 關閉按鈕
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)

-- 功能容器
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

-- 建立功能開關
local function createToggle(parent, name, callback, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 40)
    row.Position = UDim2.new(0, 10, 0, 10 + (order-1)*50)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 25)
    toggle.Position = UDim2.new(0.75, 0, 0.2, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggle.Text = ""
    toggle.Parent = row
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        callback(state)
    end)
end

-- 功能 1：朝視角瞬移
local function flyLoop()
    while flyEnabled do
        if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 and not hoverEnabled then
            local dir = camera.CFrame.LookVector
            rootPart.CFrame = rootPart.CFrame + dir.Unit * speed
            rootPart.Velocity = Vector3.new(0,0,0)
        end
        task.wait(interval)
    end
end

createToggle(content, "朝視角瞬移", function(state)
    flyEnabled = state
    if flyEnabled then flyLoop() end
end, 1)

-- 功能 2：空中懸停
createToggle(content, "空中懸停", function(state)
    hoverEnabled = state
    if hoverEnabled then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVel.Parent = rootPart
    else
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
    end
end, 2)

-- 功能 3：玩家透視
createToggle(content, "玩家透視", function(state)
    if state then enableESP() else disableESP() end
end, 3)

-- 功能 4：鎖定最近玩家頭部
createToggle(content, "鎖定最近玩家頭部", function(state)
    lockEnabled = state
    if lockEnabled then lockOnNearestPlayer() end
end, 4)

-- 最小化介面
local miniFrame = Instance.new("TextButton")
miniFrame.Size = UDim2.new(0, 40, 0, 40)
miniFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniFrame.Text = "掛貓"
miniFrame.TextColor3 = Color3.fromRGB(255, 150, 0)
miniFrame.TextSize = 30
miniFrame.Font = Enum.Font.GothamBold
miniFrame.Visible = false
miniFrame.Active = true
miniFrame.Draggable = true
miniFrame.Parent = screenGui
Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 12)

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniFrame.Visible = true
end)

miniFrame.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniFrame.Visible = false
end)

-- 關閉確認框
local confirmFrame = Instance.new("Frame", screenGui)
confirmFrame.Size = UDim2.new(0, 200, 0, 120)
confirmFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
confirmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
confirmFrame.Visible = false
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 10)

local confirmLabel = Instance.new("TextLabel", confirmFrame)
confirmLabel.Size = UDim2.new(1, 0, 0.6, 0)
confirmLabel.Text = "你確定要關閉腳本嗎？"
confirmLabel.TextSize = 16
confirmLabel.Font = Enum.Font.GothamBold
confirmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmLabel.BackgroundTransparency = 1

local yesBtn = Instance.new("TextButton", confirmFrame)
yesBtn.Size = UDim2.new(0.5, -5, 0.3, 0)
yesBtn.Position = UDim2.new(0, 0, 0.7, 0)
yesBtn.Text = "是"
yesBtn.Font = Enum.Font.GothamBold
yesBtn.TextSize = 20
yesBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
yesBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local noBtn = Instance.new("TextButton", confirmFrame)
noBtn.Size = UDim2.new(0.5, -5, 0.3, 0)
noBtn.Position = UDim2.new(0.5, 5, 0.7, 0)
noBtn.Text = "否"
noBtn.Font = Enum.Font.GothamBold
noBtn.TextSize = 18
noBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
noBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

closeBtn.MouseButton1Click:Connect(function()
    confirmFrame.Visible = true
end)

yesBtn.MouseButton1Click:Connect(function()
    flyEnabled = false
    hoverEnabled = false
    lockEnabled = false
    espEnabled = false
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    disableESP()
    screenGui:Destroy()
end)

noBtn.MouseButton1Click:Connect(function()
    confirmFrame.Visible = false
end)

-- 重生處理
player.CharacterAdded:Connect(function()
    task.wait(1)
    character, rootPart, humanoid = getCharacter()
end)

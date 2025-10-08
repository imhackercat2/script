-- 簡易腳本 v1.2.2
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- 初始化角色函式
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
local espEnabled = false
local lockHeadEnabled = false
local speed = 6
local interval = 0.05
local bodyVel = nil

-- ESP 管理表與連線儲存
local espObjects = {}
local espLoopTask = nil
local espConnections = {}

--GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "掛貓Gui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 260)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "簡易腳本v1.2.2"
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "─"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

local miniFrame = Instance.new("TextButton")
miniFrame.Size = UDim2.new(0, 40, 0, 40)
miniFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniFrame.Text = "掛貓"
miniFrame.TextColor3 = Color3.fromRGB(255, 150, 0)
miniFrame.TextSize = 30
miniFrame.Font = Enum.Font.GothamBold
miniFrame.Visible = false
miniFrame.Parent = screenGui
Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 12)

--拖動gui
local function makeDraggable(guiA, guiB)
    local dragging = false
    local dragInput, startPos, startGuiPos
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            startPos = input.Position
            startGuiPos = {guiA.Position, guiB.Position}
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
    local function onInputChanged(input)
        if input == dragInput and dragging then
            local delta = input.Position - startPos
            guiA.Position = UDim2.new(0, startGuiPos[1].X.Offset + delta.X, 0, startGuiPos[1].Y.Offset + delta.Y)
            guiB.Position = UDim2.new(0, startGuiPos[2].X.Offset + delta.X, 0, startGuiPos[2].Y.Offset + delta.Y)
        end
    end
    guiA.InputBegan:Connect(onInputBegan)
    guiB.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
end

makeDraggable(frame, miniFrame)
makeDraggable(titleBar, miniFrame)

--功能按鈕
local function createToggle(parent, name, callback, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 40)
    row.Position = UDim2.new(0, 10, 0, 10 + (order-1)*50)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", row)
    toggle.Size = UDim2.new(0, 40, 0, 25)
    toggle.Position = UDim2.new(0.75, 0, 0.2, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
    toggle.Text = ""
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
        callback(state)
    end)
end

-- ---------- 飛行 / 懸停 ----------
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

local function hoverLoop()
    while hoverEnabled do
        if not bodyVel and rootPart then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.new(0,0,0)
            bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVel.Parent = rootPart
        end
        task.wait(interval)
    end
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
end

-- ---------- ESP ----------
local function addESPToCharacter(char)
    if not char or char == player.Character then return end
    if espObjects[char] and espObjects[char].Parent then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.FillTransparency = 0.35
    highlight.OutlineTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    espObjects[char] = highlight
end

local function removeESPFromCharacter(char)
    if espObjects[char] then
        pcall(function() espObjects[char]:Destroy() end)
        espObjects[char] = nil
    end
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            addESPToCharacter(plr.Character)
        end
    end
    espConnections.playerAdded = Players.PlayerAdded:Connect(function(plr)
        espConnections[plr] = plr.CharacterAdded:Connect(function(char)
            if espEnabled then
                task.wait(1)
                addESPToCharacter(char)
            end
        end)
    end)
    espConnections.playerRemoving = Players.PlayerRemoving:Connect(function(plr)
        if plr.Character then removeESPFromCharacter(plr.Character) end
    end)
    espLoopTask = spawn(function()
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

local function disableESP()
    espEnabled = false
    for char, h in pairs(espObjects) do
        pcall(function() h:Destroy() end)
    end
    espObjects = {}
    for k, conn in pairs(espConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    espConnections = {}
end

-- ---------- 鎖定最近玩家頭部 ----------
local function getNearestPlayerHead()
    local bestDist = math.huge
    local bestHead = nil
    local bestPlayer = nil
    local camPos = camera.CFrame.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local part = head or hrp
            if part then
                local d = (part.Position - camPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestHead = part
                    bestPlayer = plr
                end
            end
        end
    end
    return bestPlayer, bestHead
end

local lockConnection = nil
local previousCameraType = nil

local function startLockHead()
    if lockHeadEnabled then return end
    lockHeadEnabled = true
    previousCameraType = camera.CameraType
    local p, head = getNearestPlayerHead()
    if head then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
    end
    lockConnection = RunService.RenderStepped:Connect(function()
        if not lockHeadEnabled then return end
        local _, head2 = getNearestPlayerHead()
        if head2 then
            camera.CFrame = CFrame.new(camera.CFrame.Position, head2.Position)
        end
    end)
end

local function stopLockHead()
    lockHeadEnabled = false
    if lockConnection and lockConnection.Connected then
        lockConnection:Disconnect()
        lockConnection = nil
    end
    camera.CameraType = previousCameraType or Enum.CameraType.Custom
end

-- ---------- 功能按鈕 ----------
createToggle(content, "視角瞬移", function(state)
    flyEnabled = state
    if flyEnabled then task.spawn(flyLoop) end
end, 1)

createToggle(content, "空中懸停", function(state)
    hoverEnabled = state
    if hoverEnabled then task.spawn(hoverLoop) end
end, 2)

createToggle(content, "玩家透視", function(state)
    if state then enableESP() else disableESP() end
end, 3)

createToggle(content, "鎖定玩家", function(state)
    if state then startLockHead() else stopLockHead() end
end, 4)

-- ---------- 最小化 / 還原 ----------
minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniFrame.Visible = true
end)

miniFrame.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniFrame.Visible = false
end)

-- ---------- 關閉腳本 ----------
closeBtn.MouseButton1Click:Connect(function()
    -- 清理所有功能
    flyEnabled = false
    hoverEnabled = false
    espEnabled = false
    lockHeadEnabled = false
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    disableESP()
    stopLockHead()
    screenGui:Destroy()
end)

-- ---------- 角色重生處理 ----------
player.CharacterAdded:Connect(function()
    task.wait(1

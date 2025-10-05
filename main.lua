-- 掛貓簡易腳本 v1.2.1
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- 初始化角色
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    return char, root, humanoid
end

local character, rootPart, humanoid = getCharacter()

-- 控制變數（保留你原本的）
local flyEnabled = false
local hoverEnabled = false
local speed = 6
local interval = 0.05
local bodyVel = nil

-- ESP 功能（v1.1.14 的實作）
local espEnabled = false
local espObjects = {}

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

local function removeESPFromCharacter(char)
    if espObjects[char] then
        espObjects[char]:Destroy()
        espObjects[char] = nil
    end
end

local function enableESP()
    espEnabled = true
    spawn(function()
        while espEnabled do
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    addESPToCharacter(plr.Character)
                end
            end
            task.wait(1) -- 每1秒檢查（可改）
        end
    end)
end

local function disableESP()
    espEnabled = false
    for char, highlight in pairs(espObjects) do
        if highlight then highlight:Destroy() end
    end
    espObjects = {}
end

-- GUI 建立（與 v1.1.14 保持一致）
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

-- 標題列（放在 frame 裡面）
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Active = true

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "簡易腳本 v1.2.1" -- 改版本
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

-- 最小化與關閉（維持原樣）
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

-- 建立功能行 helper（跟之前一樣）
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

-- 瞬移飛行（維持原樣）
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

-- 建立功能 toggle：朝視角瞬移 / 空中懸停 / 玩家透視（維持 v1.1.14 行為）
createToggle(content, "朝視角瞬移", function(state)
    flyEnabled = state
    if flyEnabled then flyLoop() end
end, 1)

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

createToggle(content, "玩家透視", function(state)
    if state then enableESP() else disableESP() end
end, 3)

-- 🔹 最小化方塊（維持外觀與圓角）
local miniFrame = Instance.new("TextButton")
miniFrame.Size = UDim2.new(0, 40, 0, 40) -- 你之前要 40x40
miniFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniFrame.Text = "掛貓"
miniFrame.TextColor3 = Color3.fromRGB(255, 150, 0)
miniFrame.TextSize = 30
miniFrame.Font = Enum.Font.GothamBold
miniFrame.Visible = false
miniFrame.Active = true
miniFrame.Parent = screenGui
Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 12)
-- miniFrame 可拖（下方同步拖動修正）

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniFrame.Visible = true
end)
miniFrame.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniFrame.Visible = false
end)

-- 關閉確認框（維持）
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
    -- 停掉所有功能並清理
    flyEnabled = false
    hoverEnabled = false
    espEnabled = false
    lockEnabled = false
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    disableESP()
    -- 若鎖頭使用了 RenderStepped 的連接，確保關閉
    if lockConn then lockConn:Disconnect() lockConn = nil end
    screenGui:Destroy()
end)

noBtn.MouseButton1Click:Connect(function()
    confirmFrame.Visible = false
end)

-- =========================
-- 新增功能：鎖定最近玩家的頭（v1.2.1）
-- =========================
local lockEnabled = false
local lockConn = nil -- RunService.RenderStepped connection

-- 找到最近玩家的 head（不限制距離）
local function findNearestPlayerHead()
    local nearestHead = nil
    local nearestDist = math.huge
    if not rootPart then return nil end
    local myPos = rootPart.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if head and head.Position then
                local d = (head.Position - myPos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearestHead = head
                end
            end
        end
    end
    return nearestHead
end

-- 啟動鎖頭（使用 RenderStepped 每幀更新 camera，延遲最低）
local function enableLock()
    if lockConn then lockConn:Disconnect() lockConn = nil end
    lockEnabled = true
    lockConn = RunService.RenderStepped:Connect(function()
        if not lockEnabled then return end
        local head = findNearestPlayerHead()
        if head and head.Position then
            -- 只改 camera 的朝向（不改角色位置）
            camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
        end
    end)
end

local function disableLock()
    lockEnabled = false
    if lockConn then
        lockConn:Disconnect()
        lockConn = nil
    end
end

-- 把鎖頭加入 GUI（作為第4個 toggle）
createToggle(content, "鎖定玩家", function(state)
    if state then
        enableLock()
    else
        disableLock()
    end
end, 4)

-- =========================
-- 拖動行為修正（拖動 titleBar 或 frame 任一者都同步移動）
-- =========================
-- 這裡採用 Input 事件手動處理，避免 Roblox 的內建 Draggable 行為只移動自己
local UserInputService = game:GetService("UserInputService")

local function makeSyncDraggable(handle, target) -- handle: 被拖動的 UI；target: 要移動的 frame (主框體)
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            -- store the input for global processing
            -- nothing needed here because we use UserInputService.InputChanged below
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 讓 titleBar 拖動時移動整個 frame；同時讓 frame 本身也能整個被拖動
makeSyncDraggable(titleBar, frame)
makeSyncDraggable(frame, frame)
-- 讓縮小的小方塊也可拖動（獨立）
makeSyncDraggable(miniFrame, miniFrame)

-- 重生處理（維持）
player.CharacterAdded:Connect(function()
    task.wait(1)
    character, rootPart, humanoid = getCharacter()
end)

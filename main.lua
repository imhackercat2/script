-- 掛貓簡易腳本 v1.2.1
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
local lockHeadEnabled = false -- 新增：鎖頭開關
local speed = 6
local interval = 0.05
local bodyVel = nil

-- ESP 管理表與連線儲存（便於清理）
local espObjects = {}      -- [character] = Highlight
local espLoopTask = nil    -- coroutine/task for periodic scan
local espConnections = {}  -- 存 PlayerAdded/PlayerRemoving 相關 connections

-- ---------- GUI 建立（以 v1.1.14 排版為基礎） ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "掛貓Gui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 主介面（圓角長方形）
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

-- 標題列（拖曳手把）
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "簡易腳本v1.2.1"
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

-- 內容容器（保留）
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

-- 縮小方塊（圓角）
local miniFrame = Instance.new("TextButton")
miniFrame.Size = UDim2.new(0, 40, 0, 40) -- 你先前說要 40x40
miniFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniFrame.Text = "掛貓"
miniFrame.TextColor3 = Color3.fromRGB(255, 150, 0)
miniFrame.TextSize = 30
miniFrame.Font = Enum.Font.GothamBold
miniFrame.Visible = false
miniFrame.Parent = screenGui
Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 12)

-- 關閉確認框（簡單版）
local overlay = Instance.new("Frame", screenGui)
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.ZIndex = 10
overlay.Active = true

local confirmFrame = Instance.new("Frame", screenGui)
confirmFrame.Size = UDim2.new(0, 200, 0, 120)
confirmFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
confirmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
confirmFrame.Visible = false
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 10)
confirmFrame.ZIndex = 11

local confirmLabel = Instance.new("TextLabel", confirmFrame)
confirmLabel.Size = UDim2.new(1, 0, 0.6, 0)
confirmLabel.Text = "你確定要關閉腳本嗎？"
confirmLabel.TextSize = 16
confirmLabel.Font = Enum.Font.GothamBold
confirmLabel.TextColor3 = Color3.fromRGB(255,255,255)
confirmLabel.BackgroundTransparency = 1
confirmLabel.ZIndex = 12

local yesBtn = Instance.new("TextButton", confirmFrame)
yesBtn.Size = UDim2.new(0.5, -5, 0.3, 0)
yesBtn.Position = UDim2.new(0, 0, 0.7, 0)
yesBtn.Text = "是"
yesBtn.Font = Enum.Font.GothamBold
yesBtn.TextSize = 20
yesBtn.TextColor3 = Color3.fromRGB(0,0,0)
yesBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
yesBtn.ZIndex = 12

local noBtn = Instance.new("TextButton", confirmFrame)
noBtn.Size = UDim2.new(0.5, -5, 0.3, 0)
noBtn.Position = UDim2.new(0.5, 5, 0.7, 0)
noBtn.Text = "否"
noBtn.Font = Enum.Font.GothamBold
noBtn.TextSize = 18
noBtn.TextColor3 = Color3.fromRGB(0,0,0)
noBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
noBtn.ZIndex = 12

-- ---------- 拖動（雙向同步） ----------
-- 使 guiA 與 guiB 任一拖動時，另一個跟著移動（雙向）
local function makeDraggableSync(guiA, guiB)
    local dragging = {}
    -- helper: start drag on a specified gui
    local function attach(g)
        local drag = false
        local dragInput, startPos, startGuiPos
        g.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = true
                dragInput = input
                startPos = input.Position
                startGuiPos = {guiA.Position, guiB.Position}
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        drag = false
                    end
                end)
            end
        end)
        g.InputChanged:Connect(function(input)
            if input == dragInput then
                -- no-op; we use UserInputService.InputChanged for consistent updates
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and drag then
                local delta = input.Position - startPos
                -- update guiA and guiB positions by same delta (keep offsets)
                guiA.Position = UDim2.new(0, startGuiPos[1].X.Offset + delta.X, 0, startGuiPos[1].Y.Offset + delta.Y)
                guiB.Position = UDim2.new(0, startGuiPos[2].X.Offset + delta.X, 0, startGuiPos[2].Y.Offset + delta.Y)
            end
        end)
    end
    attach(guiA)
    attach(guiB)
end

-- 我們希望 frame <-> miniFrame 同步，titleBar 也能拖動影響兩者
-- titleBar 在 frame 裡，drag titleBar 改變 frame; 但為確保「拖 titleBar 也會移動 miniFrame」，
-- 我們把 frame 與 miniFrame 做雙向同步，並且把 titleBar 與 miniFrame 也做同步（titleBar 的拖動驅動 frame）
makeDraggableSync(frame, miniFrame)
makeDraggableSync(titleBar, miniFrame)
-- 這樣拖 frame/miniframe/titlebar 任一個都會讓其他兩個位置同步。

-- ---------- 功能按鈕建立（保持原 createToggle 行為） ----------
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

-- ---------- 飛行 / 懸停 功能（原樣保留） ----------
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

-- 懸停
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

-- ---------- ESP（每 5 秒掃描 + PlayerAdded/CharacterAdded 立即處理） ----------
local function addESPToCharacter(char)
    if not char or char == player.Character then return end
    if espObjects[char] and espObjects[char].Parent then return end
    -- 使用 Highlight（整體填充），放到角色根目錄
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
    -- 先一次掃描所有已存在角色
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            addESPToCharacter(plr.Character)
        end
    end
    -- 監聽新玩家加入與玩家移除（儲存 connections 便於 disable 時斷開）
    espConnections.playerAdded = Players.PlayerAdded:Connect(function(plr)
        espConnections[char] = nil
        espConnections[plr] = plr.CharacterAdded:Connect(function(char)
            if espEnabled then
                task.wait(1) -- 等角色完全建立
                addESPToCharacter(char)
            end
        end)
    end)
    espConnections.playerRemoving = Players.PlayerRemoving:Connect(function(plr)
        if plr.Character then removeESPFromCharacter(plr.Character) end
    end)
    -- 啟動週期性掃描（每 5 秒確保所有人都被標記）
    espLoopTask = spawn(function()
        while espEnabled do
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    addESPToCharacter(plr.Character)
                end
            end
            task.wait(5)
        end
    end)
end

local function disableESP()
    espEnabled = false
    -- 清除 highlights
    for char, h in pairs(espObjects) do
        pcall(function() h:Destroy() end)
    end
    espObjects = {}
    -- 斷開 connections（若有）
    for k, conn in pairs(espConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    espConnections = {}
    -- espLoopTask 會自然結束 (espEnabled == false)
end

-- ---------- 鎖定最近玩家頭部（camera lock） ----------
-- 找到最近玩家的 Head（或 HumanoidRootPart）回傳 (player, headCFrame)
local function getNearestPlayerHead()
    local bestDist = math.huge
    local bestHead = nil
    local bestPlayer = nil
    local camPos = camera.CFrame.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local humanoid = plr.Character:FindFirstChild("Humanoid")
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

-- camera lock loop (使用 RenderStepped 以獲得最低延遲)
local lockConnection = nil
local previousCameraType = nil

local function startLockHead()
    if lockHeadEnabled then return end
    lockHeadEnabled = true
    previousCameraType = camera.CameraType
    -- 若要「瞬間鎖定」：先找到一次最近的 head 並把 camera 瞬間對準
    local p, head = getNearestPlayerHead()
    if head then
        camera.CameraType = Enum.CameraType.Scriptable
        -- 保持 camera 原位置，把朝向設為頭部
        local camPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(camPos, head.Position)
    end
    -- 持續追蹤（RenderStepped）
    lockConnection = RunService.RenderStepped:Connect(function()
        if not lockHeadEnabled then return end
        local p2, head2 = getNearestPlayerHead()
        if head2 then
            local camPos2 = camera.CFrame.Position
            camera.CFrame = CFrame.new(camPos2, head2.Position)
        else
            -- 若沒有其他玩家，維持原 camera（不改變）
        end
    end)
end

local function stopLockHead()
    lockHeadEnabled = false
    if lockConnection and lockConnection.Connected then
        lockConnection:Disconnect()
        lockConnection = nil
    end
    -- 還原 camera
    if previousCameraType then
        camera.CameraType = previousCameraType or Enum.CameraType.Custom
    else
        camera.CameraType = Enum.CameraType.Custom
    end
end

-- ---------- 加入功能按鈕（三個原始 + 鎖頭） ----------
createToggle(content, "朝視角瞬移", function(state)
    flyEnabled = state
    if flyEnabled then
        task.spawn(flyLoop)
    end
end, 1)

createToggle(content, "空中懸停", function(state)
    hoverEnabled = state
    if hoverEnabled then
        task.spawn(hoverLoop)
    end
end, 2)

createToggle(content, "玩家透視", function(state)
    if state then enableESP() else disableESP() end
end, 3)

-- 新增：鎖定最近玩家頭部（第四個）
createToggle(content, "鎖定玩家", function(state)
    if state then
        startLockHead()
    else
        stopLockHead()
    end
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

-- ---------- 關閉確認 ----------
closeBtn.MouseButton1Click:Connect(function()
    overlay.Visible = true
    confirmFrame.Visible = true
end)

yesBtn.MouseButton1Click:Connect(function()
    -- 關閉時清理：停止所有功能、清理 ESP、清除 BodyVelocity、還原 camera
    flyEnabled = false
    hoverEnabled = false
    espEnabled = false
    lockHeadEnabled = false
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    disableESP()
    stopLockHead()
    -- 殺掉整個 GUI
    screenGui:Destroy()
end)

noBtn.MouseButton1Click:Connect(function()
    overlay.Visible = false
    confirmFrame.Visible = false
end)

-- ---------- 角色重生處理（保持原本 getCharacter 行為） ----------
player.CharacterAdded:Connect(function()
    task.wait(1)
    character, rootPart, humanoid = getCharacter()
end)

-- End of script v1.2.1

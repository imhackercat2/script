--📜 掛貓 v1.2.1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local flyEnabled, hoverEnabled, espEnabled, aimlockEnabled = false, false, false, false
local bodyVel, aimlockConnection

-- 🪶 GUI 生成
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "掛貓v1.2.1"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 150)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.2
mainFrame.Name = "MainFrame"

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "簡易腳本v1.2.1"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true

-- 🧭 功能按鈕生成
local function createButton(text, order)
	local btn = Instance.new("TextButton", mainFrame)
	btn.Size = UDim2.new(1, -20, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, 40 + (order - 1) * 35)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextScaled = true
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 0.1
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end)
	return btn
end

local flyBtn = createButton("✈️ 飛行", 1)
local espBtn = createButton("👁 玩家透視", 2)
local aimBtn = createButton("🎯 鎖頭", 3)
local yesBtn = createButton("❌ 關閉", 4)

--------------------------------------------------------
-- ✈️ 飛行功能
--------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if flyEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local root = player.Character.HumanoidRootPart
		if not bodyVel then
			bodyVel = Instance.new("BodyVelocity", root)
			bodyVel.Velocity = Vector3.zero
			bodyVel.MaxForce = Vector3.new(9e4, 9e4, 9e4)
		end
		local moveDir = Vector3.zero
		if userinputservice:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
		if userinputservice:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
		if userinputservice:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
		if userinputservice:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
		bodyVel.Velocity = moveDir.Unit * 80
	elseif bodyVel then
		bodyVel:Destroy()
		bodyVel = nil
	end
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	flyBtn.Text = flyEnabled and "🛑 停止飛行" or "✈️ 飛行"
end)

--------------------------------------------------------
-- 👁 玩家 ESP
--------------------------------------------------------
local function addESP(char)
	if not char:FindFirstChild("ESP_Highlight") then
		local hl = Instance.new("Highlight", char)
		hl.Name = "ESP_Highlight"
		hl.FillColor = Color3.fromRGB(255, 0, 0)
		hl.FillTransparency = 0.5
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.OutlineTransparency = 0
	end
end

local function enableESP()
	espEnabled = true
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			addESP(plr.Character)
		end
		plr.CharacterAdded:Connect(function(char)
			task.wait(1)
			if espEnabled then addESP(char) end
		end)
	end
end

local function disableESP()
	espEnabled = false
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character then
			for _, obj in pairs(plr.Character:GetChildren()) do
				if obj:IsA("Highlight") then obj:Destroy() end
			end
		end
	end
end

espBtn.MouseButton1Click:Connect(function()
	if espEnabled then
		disableESP()
		espBtn.Text = "👁 玩家透視"
	else
		enableESP()
		espBtn.Text = "🛑 關閉透視"
	end
end)

--------------------------------------------------------
-- 🎯 鎖定最近玩家頭部
--------------------------------------------------------
local function getClosestPlayer()
	local closest, dist = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
			local head = plr.Character.Head
			local diff = (head.Position - camera.CFrame.Position).Magnitude
			if diff < dist then
				closest = head
				dist = diff
			end
		end
	end
	return closest
end

local function startAimlock()
	aimlockEnabled = true
	aimBtn.Text = "🛑 停止鎖頭"
	aimlockConnection = RunService.RenderStepped:Connect(function()
		if aimlockEnabled then
			local target = getClosestPlayer()
			if target then
				camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
			end
		end
	end)
end

local function stopAimlock()
	aimlockEnabled = false
	aimBtn.Text = "🎯 鎖頭"
	if aimlockConnection then
		aimlockConnection:Disconnect()
		aimlockConnection = nil
	end
end

aimBtn.MouseButton1Click:Connect(function()
	if aimlockEnabled then stopAimlock() else startAimlock() end
end)

--------------------------------------------------------
-- ❌ 關閉腳本（全面清理）
--------------------------------------------------------
yesBtn.MouseButton1Click:Connect(function()
	flyEnabled = false
	hoverEnabled = false
	stopAimlock()
	disableESP()
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	screenGui:Destroy()
end)

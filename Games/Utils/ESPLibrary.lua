print("feather esp v1.2223")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}
local inputService = game:GetService("UserInputService")

local R15_BONES = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "LowerTorso"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
	{"Head", "Torso"},
	{"Torso", "Right Arm"},
	{"Right Arm", "Right Arm"},
	{"Torso", "Left Arm"},
	{"Left Arm", "Left Arm"},
	{"Torso", "Left Leg"},
	{"Left Leg", "Left Leg"},
	{"Torso", "Right Leg"},
	{"Right Leg", "Right Leg"}
}

--// Settings
local ESP_SETTINGS = {
	BoxOutlineColor = Color3.new(0, 0, 0),
	BoxColor = Color3.new(1, 1, 1),
	NameColor = Color3.new(1, 1, 1),
	HealthOutlineColor = Color3.new(0, 0, 0),
	HealthHighColor = Color3.new(0, 1, 0),
	HealthLowColor = Color3.new(1, 0, 0),
	CharSize = Vector2.new(4, 6),
	Teamcheck = false,
	WallCheck = false,
	Enabled = false,
	ShowBox = false,
	BoxType = "2D",
	ShowName = false,
	ShowHealth = false,
	ShowDistance = false,
	ShowSkeletons = false,
	ShowTracer = false,
	TracerColor = Color3.new(1, 1, 1), 
	TracerThickness = 2,
	SkeletonsColor = Color3.new(1, 1, 1),
	TracerPosition = "Bottom",
}

local function create(class, properties)
	local drawing = Drawing.new(class)
	for property, value in pairs(properties) do
		drawing[property] = value
	end
	return drawing
end

local function createEsp(player)
	local esp = {
		tracer = create("Line", {
			Thickness = ESP_SETTINGS.TracerThickness,
			Color = ESP_SETTINGS.TracerColor,
			Transparency = 0.5
		}),
		boxOutline = create("Square", {
			Color = ESP_SETTINGS.BoxOutlineColor,
			Thickness = 3,
			Filled = false
		}),
		box = create("Square", {
			Color = ESP_SETTINGS.BoxColor,
			Thickness = 1,
			Filled = false
		}),
		name = create("Text", {
			Color = ESP_SETTINGS.NameColor,
			Outline = true,
			Center = true,
			Size = 13
		}),
		healthOutline = create("Line", {
			Thickness = 3,
			Color = ESP_SETTINGS.HealthOutlineColor
		}),
		health = create("Line", {
			Thickness = 1
		}),
		distance = create("Text", {
			Color = Color3.new(1, 1, 1),
			Size = 12,
			Outline = true,
			Center = true
		}),
		boxLines = {},
		skeletonlines = {}
	}

	cache[player] = esp

	local function setupSkeletonLines(bones)
		for _, bonePair in ipairs(bones) do
			local parentBone, childBone = bonePair[1], bonePair[2]

			if player.Character and player.Character:FindFirstChild(parentBone) and player.Character:FindFirstChild(childBone) then
				local skeletonLine = create("Line", {
					Thickness = 1,
					Color = ESP_SETTINGS.SkeletonsColor,
					Transparency = 1
				})
				table.insert(esp.skeletonlines, {skeletonLine, parentBone, childBone})
			end
		end
	end

	-- Check if the character is R15 or R6
	if player.Character and player.Character:FindFirstChild("UpperTorso") then
		setupSkeletonLines(R15_BONES)
	elseif player.Character and player.Character:FindFirstChild("Torso") then
		setupSkeletonLines(R6_BONES)
	end
end

local function isPlayerBehindWall(player)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})

	return hit and hit:IsA("Part")
end

local function removeEsp(player)
	local esp = cache[player]
	if not esp then return end

	for _, drawing in pairs(esp) do
		drawing:Remove()
	end

	cache[player] = nil
end

local function updateEsp()
	for player, esp in pairs(cache) do
		local character, team = player.Character, player.Team
		if character and (not ESP_SETTINGS.Teamcheck or (team and team ~= localPlayer.Team)) then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local head = character:FindFirstChild("Head")
			local humanoid = character:FindFirstChild("Humanoid")
			local isBehindWall = ESP_SETTINGS.WallCheck and isPlayerBehindWall(player)
			local shouldShow = not isBehindWall and ESP_SETTINGS.Enabled

			if rootPart and head and humanoid and shouldShow then
				local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
				if onScreen then
					local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
					local charSize = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
					local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
					local boxPosition = Vector2.new(math.floor(hrp2D.X - charSize * 1.8 / 2), math.floor(hrp2D.Y - charSize * 1.6 / 2))

					if ESP_SETTINGS.ShowName and ESP_SETTINGS.Enabled then
						esp.name.Visible = true
						esp.name.Text = string.lower(player.Name)
						esp.name.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y - 16)
						esp.name.Color = ESP_SETTINGS.NameColor
					else
						esp.name.Visible = false
					end

					if ESP_SETTINGS.ShowBox and ESP_SETTINGS.Enabled then
						if ESP_SETTINGS.BoxType == "2D" then
							esp.boxOutline.Size = boxSize
							esp.boxOutline.Position = boxPosition
							esp.box.Size = boxSize
							esp.box.Position = boxPosition
							esp.box.Color = ESP_SETTINGS.BoxColor
							esp.box.Visible = true
							esp.boxOutline.Visible = true
							for _, line in ipairs(esp.boxLines) do
								line:Remove()
							end
						elseif ESP_SETTINGS.BoxType == "Corner Box Esp" then
							local lineW = (boxSize.X / 5)
							local lineH = (boxSize.Y / 6)
							local lineT = 1

							if #esp.boxLines == 0 then
								for i = 1, 16 do
									local boxLine = create("Line", {
										Thickness = 1,
										Color = ESP_SETTINGS.BoxColor,
										Transparency = 1
									})
									esp.boxLines[#esp.boxLines + 1] = boxLine
								end
							end

							local boxLines = esp.boxLines

							-- top left
							boxLines[1].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y - lineT)
							boxLines[1].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y - lineT)

							boxLines[2].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y - lineT)
							boxLines[2].To = Vector2.new(boxPosition.X - lineT, boxPosition.Y + lineH)

							-- top right
							boxLines[3].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)
							boxLines[3].To = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y - lineT)

							boxLines[4].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)
							boxLines[4].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + lineH)

							-- bottom left
							boxLines[5].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)
							boxLines[5].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y + boxSize.Y + lineT)

							boxLines[6].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)
							boxLines[6].To = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y - lineH)

							-- bottom right
							boxLines[7].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)
							boxLines[7].To = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y + lineT)

							boxLines[8].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)
							boxLines[8].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y - lineH)

							-- center right
							boxLines[9].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + (boxSize.Y / 2))
							boxLines[9].To = Vector2.new(boxPosition.X + boxSize.X - (lineW / 2), boxPosition.Y + (boxSize.Y / 2))

							-- center left
							boxLines[10].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + (boxSize.Y / 2))
							boxLines[10].To = Vector2.new(boxPosition.X + (lineW / 2), boxPosition.Y + (boxSize.Y / 2))

							-- center bottom
							boxLines[11].From = Vector2.new(boxPosition.X + (boxSize.X / 2), boxPosition.Y + boxSize.Y + lineT)
							boxLines[11].To = Vector2.new(boxPosition.X + (boxSize.X / 2), boxPosition.Y + boxSize.Y - (lineH / 2))

							-- center top
							boxLines[12].From = Vector2.new(boxPosition.X + (boxSize.X / 2), boxPosition.Y - lineT)
							boxLines[12].To = Vector2.new(boxPosition.X + (boxSize.X / 2), boxPosition.Y + (lineH / 2))

							for i = 1, 12 do
								boxLines[i].Visible = true
							end
							esp.box.Visible = false
							esp.boxOutline.Visible = false
						end
					else
						esp.box.Visible = false
						esp.boxOutline.Visible = false
						for _, line in ipairs(esp.boxLines) do
							line.Visible = false
						end
					end

					if ESP_SETTINGS.ShowDistance and ESP_SETTINGS.Enabled then
						esp.distance.Visible = true
						esp.distance.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y + boxSize.Y + 1)
						esp.distance.Text = string.format("%d studs", math.floor((localPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude))
					else
						esp.distance.Visible = false
					end

					if ESP_SETTINGS.ShowHealth and ESP_SETTINGS.Enabled then
						local health = humanoid.Health
						local maxHealth = humanoid.MaxHealth
						local size = boxSize.Y * (health / maxHealth)
						local pos = boxPosition.Y + boxSize.Y - size

						esp.health.From = Vector2.new(boxPosition.X - 5, pos)
						esp.health.To = Vector2.new(boxPosition.X - 5, pos + size)

						local red = (maxHealth - health) / maxHealth
						local green = health / maxHealth
						esp.health.Color = Color3.new(red, green, 0)
						esp.health.Visible = true

						esp.healthOutline.From = Vector2.new(boxPosition.X - 5, boxPosition.Y)
						esp.healthOutline.To = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
						esp.healthOutline.Visible = true
					else
						esp.health.Visible = false
						esp.healthOutline.Visible = false
					end

					if ESP_SETTINGS.ShowTracer and ESP_SETTINGS.Enabled then
						local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
						esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 1)
						esp.tracer.To = Vector2.new(hrp2D.X, hrp2D.Y)
						esp.tracer.Color = ESP_SETTINGS.TracerColor
						esp.tracer.Thickness = ESP_SETTINGS.TracerThickness
						esp.tracer.Visible = true
					else
						esp.tracer.Visible = false
					end

					if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
						local bones = character:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
						for _, boneLine in ipairs(esp.skeletonlines) do
							local skeletonLine, parentBone, childBone = boneLine[1], boneLine[2], boneLine[3]

							local parentPart = character:FindFirstChild(parentBone)
							local childPart = character:FindFirstChild(childBone)

							if parentPart and childPart then
								local parentPosition, parentOnScreen = camera:WorldToViewportPoint(parentPart.Position)
								local childPosition, childOnScreen = camera:WorldToViewportPoint(childPart.Position)

								if parentOnScreen and childOnScreen then
									skeletonLine.From = Vector2.new(parentPosition.X, parentPosition.Y)
									skeletonLine.To = Vector2.new(childPosition.X, childPosition.Y)
									skeletonLine.Visible = true
								else
									skeletonLine.Visible = false
								end
							else
								skeletonLine.Visible = false
							end
						end
					else
						for _, boneLine in ipairs(esp.skeletonlines) do
							boneLine[1].Visible = false
						end
					end
				else
					for _, drawing in pairs(esp) do
						drawing.Visible = false
					end
				end
			else
				for _, drawing in pairs(esp) do
					drawing.Visible = false
				end
			end
		else
			removeEsp(player)
		end
	end
end

local function playerAdded(player)
	createEsp(player)
	player.CharacterAdded:Connect(function()
		createEsp(player)
	end)
	player.CharacterRemoving:Connect(function()
		removeEsp(player)
	end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(removeEsp)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		playerAdded(player)
	end
end

RunService.RenderStepped:Connect(updateEsp)

print("esp loaded")

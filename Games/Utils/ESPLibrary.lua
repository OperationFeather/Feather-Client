print("feather esp v1.101")
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
							boxLines[3].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y - lineT)
							boxLines[3].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)

							boxLines[4].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)
							boxLines[4].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + lineH)

							-- bottom left
							boxLines[5].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y - lineH)
							boxLines[5].To = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)

							boxLines[6].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)
							boxLines[6].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y + boxSize.Y + lineT)

							-- bottom right
							boxLines[7].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y + lineT)
							boxLines[7].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)

							boxLines[8].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y - lineH)
							boxLines[8].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)

							-- inline
							for i = 9, 16 do
								boxLines[i].Thickness = 2
								boxLines[i].Color = ESP_SETTINGS.BoxOutlineColor
								boxLines[i].Transparency = 1
							end

							boxLines[9].From = Vector2.new(boxPosition.X, boxPosition.Y)
							boxLines[9].To = Vector2.new(boxPosition.X, boxPosition.Y + lineH)

							boxLines[10].From = Vector2.new(boxPosition.X, boxPosition.Y)
							boxLines[10].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y)

							boxLines[11].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y)
							boxLines[11].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + lineH)

							boxLines[12].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y)
							boxLines[12].To = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y)

							boxLines[13].From = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y)
							boxLines[13].To = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y - lineH)

							boxLines[14].From = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y)
							boxLines[14].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y + boxSize.Y)

							boxLines[15].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y)
							boxLines[15].To = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y)

							boxLines[16].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y)
							boxLines[16].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y - lineH)
						end
					else
						esp.box.Visible = false
						esp.boxOutline.Visible = false
					end

					if ESP_SETTINGS.ShowDistance and ESP_SETTINGS.Enabled then
						esp.distance.Visible = true
						esp.distance.Text = string.format("%.0fm", (localPlayer:DistanceFromCharacter(rootPart.Position) / 3.571))
						esp.distance.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y + boxSize.Y + 1)
					else
						esp.distance.Visible = false
					end

					if ESP_SETTINGS.ShowTracers and ESP_SETTINGS.Enabled then
						esp.tracer.Visible = true
						esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, ESP_SETTINGS.TracersFrom == "Bottom" and camera.ViewportSize.Y or (ESP_SETTINGS.TracersFrom == "Mouse" and inputService:GetMouseLocation().Y or camera.ViewportSize.Y / 2))
						esp.tracer.To = Vector2.new(position.X, position.Y)
					else
						esp.tracer.Visible = false
					end

					if ESP_SETTINGS.ShowHealthBar and ESP_SETTINGS.Enabled then
						esp.health.Visible = true
						esp.healthOutline.Visible = true
						esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
						esp.health.To = Vector2.new((boxPosition.X - 5), (boxPosition.Y + boxSize.Y) - (boxSize.Y * (humanoid.Health / humanoid.MaxHealth)))
						esp.health.Color = Color3.fromRGB(255 - 255 / (humanoid.MaxHealth / humanoid.Health), 255 / (humanoid.MaxHealth / humanoid.Health), 0)
						esp.healthOutline.From = Vector2.new((boxPosition.X - 5), (boxPosition.Y + boxSize.Y) + 1)
						esp.healthOutline.To = Vector2.new((boxPosition.X - 5), (boxPosition.Y - 1))
					else
						esp.health.Visible = false
						esp.healthOutline.Visible = false
					end

					-- Update skeletons for R15 and R6
					if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
						for i, lineInfo in ipairs(esp.skeletonlines) do
							local line, parentBone, childBone = lineInfo[1], lineInfo[2], lineInfo[3]

							if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
								local boneA = camera:WorldToViewportPoint(character[parentBone].Position)
								local boneB = camera:WorldToViewportPoint(character[childBone].Position)
								line.From = Vector2.new(boneA.X, boneA.Y)
								line.To = Vector2.new(boneB.X, boneB.Y)
								line.Color = ESP_SETTINGS.SkeletonsColor
								line.Thickness = ESP_SETTINGS.SkeletonsThickness
								line.Transparency = ESP_SETTINGS.SkeletonsTransparency
								line.Visible = true
							else
								line.Visible = false
							end
						end
					else
						for _, lineInfo in ipairs(esp.skeletonlines) do
							lineInfo[1].Visible = false
						end
					end

					continue
				end
			end
		end

		for _, v in pairs(esp) do
			if type(v) == "table" then
				for _, line in ipairs(v) do
					line.Visible = false
				end
			else
				v.Visible = false
			end
		end
	end
end


for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		createEsp(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= localPlayer then
		createEsp(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeEsp(player)
end)

RunService.RenderStepped:Connect(updateEsp)
return ESP_SETTINGS

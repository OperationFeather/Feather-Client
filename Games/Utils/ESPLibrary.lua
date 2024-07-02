-- esp.lua111
--// Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

local bones = {
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

local r6Bones = {
	{"Head", "Torso"},
	{"Torso", "Left Arm"},
	{"Torso", "Right Arm"},
	{"Torso", "Left Leg"},
	{"Torso", "Right Leg"}
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
		tracer = create("Line", {
			Thickness = ESP_SETTINGS.TracerThickness,
			Color = ESP_SETTINGS.TracerColor,
			Transparency = 1
		}),
		boxLines = {},
	}

	cache[player] = esp
	cache[player]["skeletonlines"] = {}
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

							-- set color
							for _, boxLine in ipairs(boxLines) do
								boxLine.Color = ESP_SETTINGS.BoxColor
								boxLine.Visible = true
							end
						end
					else
						esp.box.Visible = false
						esp.boxOutline.Visible = false
					end

					if ESP_SETTINGS.ShowDistance and ESP_SETTINGS.Enabled then
						esp.distance.Visible = true
						esp.distance.Text = string.format("[%d]", math.floor((camera.CFrame.Position - rootPart.Position).Magnitude))
						esp.distance.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y + boxSize.Y + 1)
						esp.distance.Color = Color3.new(1, 1, 1)
					else
						esp.distance.Visible = false
					end

					if ESP_SETTINGS.ShowHealth and ESP_SETTINGS.Enabled then
						esp.healthOutline.Visible = true
						esp.health.Visible = true
						esp.healthOutline.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
						esp.healthOutline.To = Vector2.new((boxPosition.X - 5), boxPosition.Y)
						esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + (boxSize.Y * (humanoid.Health / humanoid.MaxHealth)))
						esp.health.To = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
						esp.health.Color = ESP_SETTINGS.HealthLowColor:lerp(ESP_SETTINGS.HealthHighColor, humanoid.Health / humanoid.MaxHealth)
					else
						esp.health.Visible = false
						esp.healthOutline.Visible = false
					end

					if ESP_SETTINGS.ShowTracer and ESP_SETTINGS.Enabled then
						esp.tracer.Visible = true
						esp.tracer.Color = ESP_SETTINGS.TracerColor
						if ESP_SETTINGS.TracerPosition == "Top" then
							esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, 0)
						elseif ESP_SETTINGS.TracerPosition == "Bottom" then
							esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
						elseif ESP_SETTINGS.TracerPosition == "Middle" then
							esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
						end
						esp.tracer.To = Vector2.new(position.X, position.Y)
					else
						esp.tracer.Visible = false
					end

					if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
						for i, bone in pairs(bones) do
							local part0 = character:FindFirstChild(bone[1]) or character:FindFirstChild("Torso")
							local part1 = character:FindFirstChild(bone[2]) or character:FindFirstChild("Torso")
							if part0 and part1 then
								local pos1 = camera:WorldToViewportPoint(part0.Position)
								local pos2 = camera:WorldToViewportPoint(part1.Position)
								if not cache[player]["skeletonlines"][i] then
									cache[player]["skeletonlines"][i] = create("Line", {Transparency = 1})
								end
								local line = cache[player]["skeletonlines"][i]
								line.From = Vector2.new(pos1.X, pos1.Y)
								line.To = Vector2.new(pos2.X, pos2.Y)
								line.Visible = ESP_SETTINGS.Enabled
								line.Color = ESP_SETTINGS.SkeletonsColor
							else
								if cache[player]["skeletonlines"][i] then
									cache[player]["skeletonlines"][i].Visible = false
								end
							end
						end
					else
						for i, line in pairs(cache[player]["skeletonlines"]) do
							line.Visible = false
						end
					end
				else
					esp.box.Visible = false
					esp.boxOutline.Visible = false
					esp.name.Visible = false
					esp.healthOutline.Visible = false
					esp.health.Visible = false
					esp.tracer.Visible = false
					esp.distance.Visible = false
					for i, line in pairs(cache[player]["skeletonlines"]) do
						line.Visible = false
					end
				end
			else
				esp.box.Visible = false
				esp.boxOutline.Visible = false
				esp.name.Visible = false
				esp.healthOutline.Visible = false
				esp.health.Visible = false
				esp.tracer.Visible = false
				esp.distance.Visible = false
				for i, line in pairs(cache[player]["skeletonlines"]) do
					line.Visible = false
				end
			end
		else
			esp.box.Visible = false
			esp.boxOutline.Visible = false
			esp.name.Visible = false
			esp.healthOutline.Visible = false
			esp.health.Visible = false
			esp.tracer.Visible = false
			esp.distance.Visible = false
			for i, line in pairs(cache[player]["skeletonlines"]) do
				line.Visible = false
			end
		end
	end
end

RunService.RenderStepped:Connect(updateEsp)
Players.PlayerRemoving:Connect(removeEsp)

Players.PlayerAdded:Connect(function(player)
	createEsp(player)
end)

for _, player in pairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		createEsp(player)
	end
end

return ESP_SETTINGS

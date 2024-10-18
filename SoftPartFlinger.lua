--[[
	- - SOFT PART FLING - -
	This script detects whenever a player touches a body,
	modifies the part properties and attempts to fling them

	Made by:  @fastest.me (Discord)
    Made by:  @agreeed (GitHub)
]]

-- Config
local SIMULATION_BODY_LIMIT = 100 -- Simulation bodies can have too much parts, this limits how many are taken into count
local BODY_FREEING_DELAY = 1 -- After how many seconds the simulation body will be freed from fling
local COLLISION_FREEING_DELAY = 1 -- (after fling freeing) After how many seconds the simulation body will have collision restored
local DEBOUNCE_DELAY = 3 -- (after all fling phases) After how many seconds the fling function will be able to fire again
local SEARCH_MECHANISMS = false -- Searches for all connected parts (mechanisms) and applies fling function to all of them

-- Functions
local inf = math.huge
local density = 30
local weight = 30
local height = 100
local tqp = 25000
local app = 25000
local low = 0.0001

local Player = game:GetService("Players").LocalPlayer

local function getChar()
	return Player.Character
end
local function lightPart(part)
	if not part:IsA("BasePart") then return end
	part.CustomPhysicalProperties = PhysicalProperties.new(low, low, low, low, low)
end
local function heavyPart(part)
	if not part:IsA("BasePart") then return end
	part.CollisionGroup = "INT1"
	part.CustomPhysicalProperties = PhysicalProperties.new(density, 0, 0, weight, weight)
end
local function getMechanism(part, limited)
	-- We do not need anchored parts to have mechanisms / simulation bodies accounted!
	if part.Anchored then return {part} end
	if not SEARCH_MECHANISMS then return {part} end

	local mechanism = {part}

	local function add(target)
		for i, v in mechanism do
			if v == target then return end
		end
		table.insert(mechanism, target)
	end
	
	for i, v in part:GetJoints() do
		if v:IsA("JointInstance") then
			if v.Part0 then add(v.Part0.Parent) end
			if v.Part1 then add(v.Part1.Parent) end
		elseif v:IsA("Constraint") then
			if v.Attachment0 then add(v.Attachment0.Parent) end
			if v.Attachment0 then add(v.Attachment1.Parent) end
		end

		if type(limit) == "number" then
			if #mechanism >= limit then
				return mechanism
			end
		end
	end
	for i, v in part:GetConnectedParts(true) do
		add(v)

		if type(limit) == "number" then
			if #mechanism >= limit then
				return mechanism
			end
		end
	end

	return mechanism
end
local NetworkAccess = coroutine.create(function() -- Taken/Modified from BlackHole FE script
    settings().Physics.AllowSleep = false
    while game:GetService("RunService").RenderStepped:Wait() do
        Player.MaximumSimulationRadius = math.pow(math.huge, math.huge)
        if setsimulationradius then
			setsimulationradius(math.huge)
		end
    end
end)
local function touchy(part)
	if part.Anchored or part:HasTag("Debounce") then return end
	part:AddTag("Debounce")
	
	local mechanism = getMechanism(part, SIMULATION_BODY_LIMIT)

	for i, v in mechanism do
		task.spawn(function()
			local Attachment1 = getChar().HumanoidRootPart.RootAttachment

			local cc = part.CanCollide
			part.CollisionGroup = "INT2"
			part.CanCollide = false

			local Torque = Instance.new("Torque", part)
			Torque.Torque = Vector3.new(tqp, tqp, tqp)

			local AlignPosition = Instance.new("AlignPosition", v)
			local Attachment2 = Instance.new("Attachment", v)
			Torque.Attachment0 = Attachment2
			AlignPosition.MaxForce = app
			AlignPosition.MaxVelocity = math.huge
			AlignPosition.Responsiveness = 200
			AlignPosition.Attachment0 = Attachment2
			AlignPosition.Attachment1 = Attachment1

			task.wait(BODY_FREEING_DELAY)
			Torque:Destroy()
			AlignPosition:Destroy()

			task.wait(COLLISION_FREEING_DELAY)
			part.CanCollide = cc

			task.wait(DEBOUNCE_DELAY)
			part:RemoveTag("Debounce")
		end)
	end
end

-- Setup
for i, v in game:GetDescendants() do
	if not v:IsDescendantOf(getChar()) then
		lightPart(v)
	end
end
game.DescendantAdded:Connect(function(v)
	if not v:IsDescendantOf(getChar()) then
		lightPart(v)
	end
end)

for i, v in getChar():GetDescendants() do
	heavyPart(v)
	if v:IsA("BasePart") then
		v.Touched:Connect(touchy)
	end
end
Player.CharacterAdded:Connect(function(char)
	for i, v in char:GetDescendants() do
		heavyPart(v)
		if v:IsA("BasePart") then
			v.Touched:Connect(touchy)
		end
	end
end)
coroutine.resume(NetworkAccess)
if not setsimulationradius then
	print("Soft part fling may not work correctly! (Missing setsimulationradius)")
end
print("SOFT PART FLING Loaded!")

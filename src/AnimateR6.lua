--!strict

local CONFIGURATION: {[string]: number} = {
	HUMANOID_HIP_HEIGHT = 2,

	JUMP_ANIM_DURATION = 0.31,

	TOOL_TRANSITION_TIME = 0.1,
	FALL_TRANSITION_TIME = 0.2,
	EMOTE_TRANSITION_TIME = 0.1,
}

type SerializedAnimation = {
	id: string,
	weight: number,
}

type AnimationSet = {
	count: number,
	totalWeight: number,
	connections: {RBXScriptConnection},
	entries: {{
		animation: Animation,
		weight: number,
	}}
}

type AnimationState = {
	pose: string,

	rightShoulder: Motor6D,
	leftShoulder: Motor6D,
	rightHip: Motor6D,
	leftHip: Motor6D,
	neck: Motor6D,

	currentAnim: string,
	currentAnimInstance: Animation?,
	currentAnimTrack: AnimationTrack?,
	currentAnimKeyframeHandler: RBXScriptConnection?,
	currentAnimSpeed: number,

	toolAnim: string,
	toolAnimInstance: Animation?,
	toolAnimTrack: AnimationTrack?,
	currentToolAnimKeyframeHandler: RBXScriptConnection?,

	legacyToolAnim: string,
	legacyToolAnimTime: number,

	jumpAnimTime: number,
	currentlyPlayingEmote: boolean,
}

type AnimationEntity = {
	sets: {[string]: AnimationSet},
	state: AnimationState,

	meta: {
		director: Humanoid,
		performer: Humanoid,
		animator: Animator,

		preloaded: {[string]: boolean},
		parent: Instance,
	}
}

local SERIALIZED_DEFAULT_ANIMATIONS: {[string]: {SerializedAnimation}} = {
	idle = 	{	
		{ id = "rbxassetid://180435571", weight = 9 },
		{ id = "rbxassetid://180435792", weight = 1 },
	},
	walk = 	{ 	
		{ id = "rbxassetid://180426354", weight = 10 },
	}, 
	run = 	{
		{ id = "rbxassetid://180426354", weight = 10 },
	}, 
	jump = 	{
		{ id = "rbxassetid://125750702", weight = 10 },
	}, 
	fall = 	{
		{ id = "rbxassetid://180436148", weight = 10 },
	}, 
	climb = {
		{ id = "rbxassetid://180436334", weight = 10 },
	}, 
	sit = 	{
		{ id = "rbxassetid://178130996", weight = 10 },
	},	
	toolnone = {
		{ id = "rbxassetid://182393478", weight = 10 },
	},
	toolslash = {
		{ id = "rbxassetid://129967390", weight = 10 },
	},
	toollunge = {
		{ id = "rbxassetid://129967478", weight = 10 },
	},
	wave = {
		{ id = "rbxassetid://128777973", weight = 10 },
	},
	point = {
		{ id = "rbxassetid://128853357", weight = 10 },
	},
	dance1 = {
		{ id = "rbxassetid://182435998", weight = 10 },
		{ id = "rbxassetid://182491037", weight = 10 },
		{ id = "rbxassetid://182491065", weight = 10 },
	},
	dance2 = {
		{ id = "rbxassetid://182436842", weight = 10 },
		{ id = "rbxassetid://182491248", weight = 10 },
		{ id = "rbxassetid://182491277", weight = 10 },
	},
	dance3 = {
		{ id = "rbxassetid://182436935", weight = 10 },
		{ id = "rbxassetid://182491368", weight = 10 },
		{ id = "rbxassetid://182491423", weight = 10 },
	},
	laugh = {
		{ id = "rbxassetid://129423131", weight = 10 },
	},
	cheer = {
		{ id = "rbxassetid://129423030", weight = 10 },
	},
}

local EMOTE_NAMES: {[string]: boolean} = {
	wave = false, 
	point = false, 
	dance = true, 
	dance2 = true, 
	dance3 = true, 
	laugh = false, 
	cheer = false,
}

local module = {}
local random = Random.new()

-- Private

local function stopAllPlayingAnimationsOnHumanoid(humanoid: Humanoid)
	local animator = humanoid:FindFirstChild("Animator")
	if animator and animator:IsA("Animator") then
		local playingTracks = animator:GetPlayingAnimationTracks()
		for _, track in playingTracks do
			track:Stop(0)
			track:Destroy()
		end
	end
end

local function addDefaultAnimations(parent: Instance)
	for name, serializedAnimations in SERIALIZED_DEFAULT_ANIMATIONS do
		local found = parent:FindFirstChild(name)

		if not found then
			local container = Instance.new("StringValue")
			container.Name = name

			for _, serialized in serializedAnimations do
				local animation = Instance.new("Animation")
				animation.Name = name
				animation.AnimationId = serialized.id
				animation.Parent = container

				local weight = Instance.new("NumberValue")
				weight.Name = "Weight"
				weight.Value = serialized.weight
				weight.Parent = animation
			end

			container.Parent = parent
		end
	end
end

local function getLegacyToolAnim(tool: Tool): StringValue?
	for _, child in tool:GetChildren() do
		if child.Name == "toolanim" and child:IsA("StringValue") then
			return child
		end
	end
	return nil
end

local actions = {} do
	function actions.refreshAnimationSet(entity: AnimationEntity, name: string)
		local defaults = SERIALIZED_DEFAULT_ANIMATIONS[name]
		if not defaults then
			return
		end

		if entity.sets[name] then
			for _, connection in entity.sets[name].connections do
				connection:Disconnect()
			end
		end

		local set: AnimationSet = {
			count = 0,
			totalWeight = 0,
			connections = {},
			entries = {},
		}

		local allowCustomAnimations = true
		local success = pcall(function() 
			allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations
		end)

		if not success then
			allowCustomAnimations = true
		end

		local config = entity.meta.parent:FindFirstChild(name)
		if allowCustomAnimations and config then
			table.insert(set.connections, config.ChildAdded:Connect(function()
				actions.refreshAnimationSet(entity, name)
			end))

			table.insert(set.connections, config.ChildRemoved:Connect(function()
				actions.refreshAnimationSet(entity, name)
			end))

			for _, child in config:GetChildren() do
				if child:IsA("Animation") then
					local weight = 1
					local weightObject = child:FindFirstChild("Weight")
					if weightObject and weightObject:IsA("NumberValue") then
						weight = weightObject.Value
					end

					set.count = set.count + 1
					set.totalWeight = set.totalWeight + weight

					set.entries[set.count] = {
						animation = child,
						weight = weight,
					}

					table.insert(set.connections, child.ChildAdded:Connect(function()
						actions.refreshAnimationSet(entity, name)
					end))

					table.insert(set.connections, child.ChildRemoved:Connect(function()
						actions.refreshAnimationSet(entity, name)
					end))

					table.insert(set.connections, child.Changed:Connect(function()
						actions.refreshAnimationSet(entity, name)
					end))
				end
			end
		end

		if set.count <= 0 then
			for i, serialized in defaults do
				local animation = Instance.new("Animation")
				animation.Name = name
				animation.AnimationId = serialized.id

				set.count = set.count + 1
				set.totalWeight = set.totalWeight + serialized.weight

				set.entries[i] = {
					animation = animation,
					weight = serialized.weight,
				}
			end
		end

		for _, entry in set.entries do
			if not entity.meta.preloaded[entry.animation.AnimationId] then
				entity.meta.animator:LoadAnimation(entry.animation)
				entity.meta.preloaded[entry.animation.AnimationId] = true
			end
		end

		entity.sets[name] = set
	end

	function actions.stopAllAnimations(entity: AnimationEntity): string
		local oldAnim = entity.state.currentAnim

		if EMOTE_NAMES[oldAnim] ~= nil and EMOTE_NAMES[oldAnim] == false then
			oldAnim = "idle"
		end

		entity.state.currentAnim = ""
		entity.state.currentAnimInstance = nil

		if entity.state.currentAnimKeyframeHandler then
			entity.state.currentAnimKeyframeHandler:Disconnect()
		end

		if entity.state.currentAnimTrack then
			entity.state.currentAnimTrack:Stop()
			entity.state.currentAnimTrack:Destroy()
			entity.state.currentAnimTrack = nil
		end

		return oldAnim
	end

	function actions.setAnimationSpeed(entity: AnimationEntity, speed: number)
		if speed ~= entity.state.currentAnimSpeed then
			entity.state.currentAnimSpeed = speed
			if entity.state.currentAnimTrack then
				entity.state.currentAnimTrack:AdjustSpeed(entity.state.currentAnimSpeed)
			end
		end
	end

	function actions.onKeyFrameReached(entity: AnimationEntity, frameName: string)
		if frameName == "End" then
			local repeatAnim = entity.state.currentAnim

			-- return to idle if finishing an emote
			if EMOTE_NAMES[repeatAnim] ~= nil and EMOTE_NAMES[repeatAnim] == false then
				repeatAnim = "idle"
			end

			local animSpeed = entity.state.currentAnimSpeed
			actions.playAnimation(entity, repeatAnim, 0)
			actions.setAnimationSpeed(entity, animSpeed)
		end
	end

	function actions.rollAnimation(entity: AnimationEntity, name: string): Animation
		local set = entity.sets[name]
		assert(set, ("Unable to roll animation for name %s"):format(name))

		local index = 1
		local roll = random:NextNumber(1, set.totalWeight)
		while roll > set.entries[index].weight do
			roll = roll - set.entries[index].weight
			index = index + 1
		end

		return set.entries[index].animation
	end

	function actions.switchAnimation(entity: AnimationEntity, anim: Animation, name: string, transitionTime: number)
		if anim ~= entity.state.currentAnimInstance then
			if entity.state.currentAnimTrack then
				entity.state.currentAnimTrack:Stop(transitionTime)
				entity.state.currentAnimTrack:Destroy()
			end

			entity.state.currentAnimSpeed = 1

			local currentAnimTrack = entity.meta.animator:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core
			currentAnimTrack:Play(transitionTime)
			
			entity.state.currentAnimTrack = currentAnimTrack
			entity.state.currentAnim = name
			entity.state.currentAnimInstance = anim

			if entity.state.currentAnimKeyframeHandler then
				entity.state.currentAnimKeyframeHandler:Disconnect()
			end

			entity.state.currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(function(frameName: string)
				actions.onKeyFrameReached(entity, frameName)
			end)
		end
	end

	function actions.playAnimation(entity: AnimationEntity, name: string, transitionTime: number)
		local anim = actions.rollAnimation(entity, name)
		actions.switchAnimation(entity, anim, name, transitionTime)
	end

	function actions.playEmote(entity: AnimationEntity, emoteAnim: Animation, transitionTime: number)
		actions.switchAnimation(entity, emoteAnim, emoteAnim.Name, transitionTime)
	end

	function actions.playToolAnimation(entity: AnimationEntity, name: string, transitionTime: number, priority: Enum.AnimationPriority?)
		local anim = actions.rollAnimation(entity, name)

		if entity.state.toolAnimInstance ~= anim then
			if entity.state.toolAnimTrack then
				entity.state.toolAnimTrack:Stop()
				entity.state.toolAnimTrack:Destroy()
				transitionTime = 0
			end

			local toolAnimTrack = entity.meta.animator:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end

			toolAnimTrack:Play(transitionTime)
			
			entity.state.toolAnimTrack = toolAnimTrack
			entity.state.toolAnim = name
			entity.state.toolAnimInstance = anim

			entity.state.currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:Connect(function(frameName: string)
				actions.onToolKeyFrameReached(entity, frameName)
			end)
		end
	end

	function actions.onToolKeyFrameReached(entity: AnimationEntity, frameName: string)
		if frameName == "End" then
			actions.playToolAnimation(entity, entity.state.toolAnim, 0)
		end
	end

	function actions.stopToolAnimations(entity: AnimationEntity): string
		local oldAnim = entity.state.toolAnim

		if entity.state.currentToolAnimKeyframeHandler then
			entity.state.currentToolAnimKeyframeHandler:Disconnect()
		end

		entity.state.toolAnim = ""
		entity.state.toolAnimInstance = nil

		if entity.state.toolAnimTrack then
			entity.state.toolAnimTrack:Stop()
			entity.state.toolAnimTrack:Destroy()
			entity.state.toolAnimTrack = nil
		end

		return oldAnim
	end

	function actions.animateToolLegacy(entity: AnimationEntity)
		local legacyToolAnim = entity.state.legacyToolAnim
		if legacyToolAnim == "None" then
			actions.playToolAnimation(entity, "toolnone", CONFIGURATION.TOOL_TRANSITION_TIME, Enum.AnimationPriority.Idle)
		elseif legacyToolAnim == "Slash" then
			actions.playToolAnimation(entity, "toolslash", 0, Enum.AnimationPriority.Action)
		elseif legacyToolAnim == "Lunge" then
			actions.playToolAnimation(entity, "toollunge", 0, Enum.AnimationPriority.Action)
		end
	end
end

local humanoidStateHandlers: {[string]: (AnimationEntity, ...any) -> ()} = {} do
	function humanoidStateHandlers.Died(entity: AnimationEntity)
		entity.state.pose = "Dead"
	end

	function humanoidStateHandlers.Running(entity: AnimationEntity, speed: number)
		if speed > 0.01 then
			actions.playAnimation(entity, "walk", 0.1)
			if entity.state.currentAnimInstance and entity.state.currentAnimInstance.AnimationId == "rbxassetid://180426354" then
				actions.setAnimationSpeed(entity, speed / 14.5)
			end
			entity.state.pose = "Running"
		else
			if EMOTE_NAMES[entity.state.currentAnim] == nil then
				actions.playAnimation(entity, "idle", 0.1)
				entity.state.pose = "Standing"
			end
		end
	end

	function humanoidStateHandlers.Jumping(entity: AnimationEntity)
		actions.playAnimation(entity, "jump", 0.1)
		entity.state.jumpAnimTime = CONFIGURATION.JUMP_ANIM_DURATION
		entity.state.pose = "Jumping"
	end

	function humanoidStateHandlers.Climbing(entity: AnimationEntity, speed: number)
		actions.playAnimation(entity, "climb", 0.1)
		actions.setAnimationSpeed(entity, speed / 12)
		entity.state.pose = "Climbing"
	end

	function humanoidStateHandlers.GettingUp(entity: AnimationEntity)
		entity.state.pose = "GettingUp"
	end

	function humanoidStateHandlers.FreeFalling(entity: AnimationEntity)
		if entity.state.jumpAnimTime <= 0 then
			actions.playAnimation(entity, "fall", CONFIGURATION.FALL_TRANSITION_TIME)
		end
		entity.state.pose = "FreeFall"
	end

	function humanoidStateHandlers.FallingDown(entity: AnimationEntity)
		entity.state.pose = "FallingDown"
	end

	function humanoidStateHandlers.Seated(entity: AnimationEntity)
		entity.state.pose = "Seated"
	end

	function humanoidStateHandlers.PlatformStanding(entity: AnimationEntity)
		entity.state.pose = "PlatformStanding"
	end

	function humanoidStateHandlers.Swimming(entity: AnimationEntity, speed: number)
		if speed > 0 then
			entity.state.pose = "Swimming"
		else
			entity.state.pose = "Standing"
		end
	end
end

local function stepAnimate(entity: AnimationEntity, t: number, dt: number)
	local amplitude = 1
	local frequency = 1
	local climbFudge = 0
	local setAngles = false

	if entity.state.jumpAnimTime > 0 then
		entity.state.jumpAnimTime = entity.state.jumpAnimTime - dt
	end

	local pose = entity.state.pose
	if pose == "FreeFall" and entity.state.jumpAnimTime <= 0 then
		actions.playAnimation(entity, "fall", CONFIGURATION.FALL_TRANSITION_TIME)
	elseif pose == "Seated" then
		actions.playAnimation(entity, "sit", 0.5)
		return
	elseif pose == "Running" then
		actions.playAnimation(entity, "walk", 0.2)
	elseif pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "PlatformStanding" then
		actions.stopAllAnimations(entity)
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	if setAngles then
		local desiredAngle = amplitude * math.sin(t * frequency)

		entity.state.rightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
		entity.state.leftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
		entity.state.rightHip:SetDesiredAngle(-desiredAngle)
		entity.state.leftHip:SetDesiredAngle(-desiredAngle)
	end

	local character = entity.meta.director.Parent
	local tool = character and character:FindFirstChildWhichIsA("Tool")
	if tool and tool:FindFirstChild("Handle") then
		local legacyToolAnimStringValueObject = getLegacyToolAnim(tool)

		if legacyToolAnimStringValueObject then
			entity.state.legacyToolAnim = legacyToolAnimStringValueObject.Value
			entity.state.legacyToolAnimTime = t + 0.3

			-- message recieved, delete StringValue
			legacyToolAnimStringValueObject.Parent = nil
		end

		if t > entity.state.legacyToolAnimTime then
			entity.state.legacyToolAnimTime = 0
			entity.state.legacyToolAnim = "None"
		end

		actions.animateToolLegacy(entity)
	else
		actions.stopToolAnimations(entity)

		entity.state.legacyToolAnimTime = 0
		entity.state.legacyToolAnim = "None"
		entity.state.toolAnimInstance = nil
	end
end

-- Public

function module.animate(parent: Instance, director: Humanoid, performer: Humanoid)
	local connections: {RBXScriptConnection} = {}

	local animator = nil
	local character = performer.Parent :: Instance
	local torso = character:WaitForChild("Torso")

	local found = performer:FindFirstChildWhichIsA("Animator")
	if found then
		animator = found
	else
		animator = Instance.new("Animator")
		animator.Parent = performer
	end

	local entity: AnimationEntity = {
		sets = {},

		state = {
			pose = "Standing",

			rightShoulder = torso:WaitForChild("Right Shoulder") :: Motor6D,
			leftShoulder = torso:WaitForChild("Left Shoulder") :: Motor6D,
			rightHip = torso:WaitForChild("Right Hip") :: Motor6D,
			leftHip = torso:WaitForChild("Left Hip") :: Motor6D,
			neck = torso:WaitForChild("Neck") :: Motor6D,

			currentAnim = "",
			currentAnimInstance = nil,
			currentAnimTrack = nil,
			currentAnimKeyframeHandler = nil,
			currentAnimSpeed = 1,

			toolAnim = "",
			toolAnimInstance = nil,
			toolAnimTrack = nil,
			currentToolAnimKeyframeHandler = nil,

			legacyToolAnim = "None",
			legacyToolAnimTime = 0,

			jumpAnimTime = 0,
			currentlyPlayingEmote = false,
		},

		meta = {
			director = director,
			performer = performer,
			animator = animator,

			preloaded = {},
			parent = parent,
		},
	}
	
	-- addDefaultAnimations(parent) -- TODO: handle race conditions w/ custom animations loading after
	stopAllPlayingAnimationsOnHumanoid(performer)

	for name, _ in SERIALIZED_DEFAULT_ANIMATIONS do
		actions.refreshAnimationSet(entity, name)
	end

	table.insert(connections, parent.ChildAdded:Connect(function(child)
		actions.refreshAnimationSet(entity, child.Name)
	end))

	table.insert(connections, parent.ChildRemoved:Connect(function(child)
		actions.refreshAnimationSet(entity, child.Name)
	end))

	for name, callback in humanoidStateHandlers do
		table.insert(connections, (director :: any)[name]:Connect(function(...)
			callback(entity, ...)
		end))
	end

	if character.Parent then
		actions.playAnimation(entity, "idle", 0.1)
		entity.state.pose = "Standing"
	end

	local stepping = coroutine.create(function()
		while true do
			local dt = task.wait(0.1)
			stepAnimate(entity, os.clock(), dt)
		end
	end)

	coroutine.resume(stepping)

	local function playEmote(emote: string | Animation): (boolean, AnimationTrack?)
		if entity.state.pose == "Standing" then
			if typeof(emote) == "string" and EMOTE_NAMES[emote] ~= nil then
				actions.playAnimation(entity, emote, CONFIGURATION.EMOTE_TRANSITION_TIME)
				return true, entity.state.currentAnimTrack
			elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
				actions.playEmote(entity, emote, CONFIGURATION.EMOTE_TRANSITION_TIME)
				return true, entity.state.currentAnimTrack
			end
		end

		return false
	end

	local function cleanup()
		coroutine.close(stepping)
		actions.stopAllAnimations(entity)

		for _, connection in connections do
			connection:Disconnect()
		end

		for _, set in entity.sets do
			for _, connection in set.connections do
				connection:Disconnect()
			end
		end

		stopAllPlayingAnimationsOnHumanoid(performer)
	end

	return cleanup, playEmote
end

return module
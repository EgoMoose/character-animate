--!strict

local ExportedTypes = require(script.Parent:WaitForChild("ExportedTypes"))

local CONFIGURATION: { [string]: number } = {
	HUMANOID_HIP_HEIGHT = 2,

	JUMP_ANIM_DURATION = 0.31,

	TOOL_TRANSITION_TIME = 0.1,
	FALL_TRANSITION_TIME = 0.2,
	EMOTE_TRANSITION_TIME = 0.1,
}

type AnimateController = ExportedTypes.AnimateController
type SerializedAnimation = ExportedTypes.SerializedAnimation
type AnimationSet = ExportedTypes.AnimationSet
type AnimationEntity = ExportedTypes.AnimationEntityR15

local EPSILON = 1E-4

local SERIALIZED_DEFAULT_ANIMATIONS: { [string]: { SerializedAnimation } } = {
	idle = {
		{ id = "rbxassetid://507766666", weight = 1 },
		{ id = "rbxassetid://507766951", weight = 1 },
		{ id = "rbxassetid://507766388", weight = 9 },
	},
	walk = {
		{ id = "rbxassetid://507777826", weight = 10 },
	},
	run = {
		{ id = "rbxassetid://507767714", weight = 10 },
	},
	swim = {
		{ id = "rbxassetid://507784897", weight = 10 },
	},
	swimidle = {
		{ id = "rbxassetid://507785072", weight = 10 },
	},
	jump = {
		{ id = "rbxassetid://507765000", weight = 10 },
	},
	fall = {
		{ id = "rbxassetid://507767968", weight = 10 },
	},
	climb = {
		{ id = "rbxassetid://507765644", weight = 10 },
	},
	sit = {
		{ id = "rbxassetid://2506281703", weight = 10 },
	},
	toolnone = {
		{ id = "rbxassetid://507768375", weight = 10 },
	},
	toolslash = {
		{ id = "rbxassetid://522635514", weight = 10 },
	},
	toollunge = {
		{ id = "rbxassetid://522638767", weight = 10 },
	},
	wave = {
		{ id = "rbxassetid://507770239", weight = 10 },
	},
	point = {
		{ id = "rbxassetid://507770453", weight = 10 },
	},
	dance = {
		{ id = "rbxassetid://507771019", weight = 10 },
		{ id = "rbxassetid://507771955", weight = 10 },
		{ id = "rbxassetid://507772104", weight = 10 },
	},
	dance2 = {
		{ id = "rbxassetid://507776043", weight = 10 },
		{ id = "rbxassetid://507776720", weight = 10 },
		{ id = "rbxassetid://507776879", weight = 10 },
	},
	dance3 = {
		{ id = "rbxassetid://507777268", weight = 10 },
		{ id = "rbxassetid://507777451", weight = 10 },
		{ id = "rbxassetid://507777623", weight = 10 },
	},
	laugh = {
		{ id = "rbxassetid://507770818", weight = 10 },
	},
	cheer = {
		{ id = "rbxassetid://507770677", weight = 10 },
	},
}

local EMOTE_NAMES: { [string]: boolean } = {
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

-- selene: allow(multiple_statements)
local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop")
end)
local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue

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

local actions = {}
do
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
			table.insert(
				set.connections,
				config.ChildAdded:Connect(function()
					actions.refreshAnimationSet(entity, name)
				end)
			)

			table.insert(
				set.connections,
				config.ChildRemoved:Connect(function()
					actions.refreshAnimationSet(entity, name)
				end)
			)

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

					table.insert(
						set.connections,
						child.ChildAdded:Connect(function()
							actions.refreshAnimationSet(entity, name)
						end)
					)

					table.insert(
						set.connections,
						child.ChildRemoved:Connect(function()
							actions.refreshAnimationSet(entity, name)
						end)
					)

					table.insert(
						set.connections,
						child.Changed:Connect(function()
							actions.refreshAnimationSet(entity, name)
						end)
					)
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

		if entity.state.currentlyPlayingEmote then
			oldAnim = "idle"
			entity.state.currentlyPlayingEmote = false
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

		if entity.state.runAnimKeyframeHandler then
			entity.state.runAnimKeyframeHandler:Disconnect()
		end

		if entity.state.runAnimTrack then
			entity.state.runAnimTrack:Stop()
			entity.state.runAnimTrack:Destroy()
			entity.state.runAnimTrack = nil
		end

		return oldAnim
	end

	function actions.getHeightScale(entity: AnimationEntity): number
		local humanoid = entity.meta.performer
		local baseHipHeight = 2
		local scale = 1

		if humanoid.AutomaticScalingEnabled then
			scale = humanoid.HipHeight / baseHipHeight

			local animationSpeedDampingObject = entity.meta.parent:FindFirstChild("ScaleDampeningPercent")
			if animationSpeedDampingObject and animationSpeedDampingObject:IsA("NumberValue") then
				scale = 1 + (humanoid.HipHeight - baseHipHeight) * animationSpeedDampingObject.Value / baseHipHeight
			end
		end

		return scale
	end

	function actions.getRootMotionCompensation(entity: AnimationEntity, speed: number): number
		local speedScaled = speed * 1.25
		local heightScale = actions.getHeightScale(entity)
		local runSpeed = speedScaled / heightScale
		return runSpeed
	end

	function actions.setRunSpeed(entity: AnimationEntity, speed: number)
		local normalizedWalkSpeed = 0.5 -- established empirically using current `913402848` walk animation
		local normalizedRunSpeed = 1
		local runSpeed = actions.getRootMotionCompensation(entity, speed)

		local walkAnimationWeight = EPSILON
		local runAnimationWeight = EPSILON
		local walkAnimationTimewarp = runSpeed / normalizedWalkSpeed
		local runAnimationTimewarp = runSpeed / normalizedRunSpeed

		if runSpeed <= normalizedWalkSpeed then
			walkAnimationWeight = 1
		elseif runSpeed < normalizedRunSpeed then
			local fadeInRun = (runSpeed - normalizedWalkSpeed) / (normalizedRunSpeed - normalizedWalkSpeed)
			walkAnimationWeight = 1 - fadeInRun
			runAnimationWeight = fadeInRun
			walkAnimationTimewarp = 1
			runAnimationTimewarp = 1
		else
			runAnimationWeight = 1
		end

		if entity.state.currentAnimTrack then
			entity.state.currentAnimTrack:AdjustWeight(walkAnimationWeight)
			entity.state.currentAnimTrack:AdjustSpeed(walkAnimationTimewarp)
		end

		if entity.state.runAnimTrack then
			entity.state.runAnimTrack:AdjustWeight(runAnimationWeight)
			entity.state.runAnimTrack:AdjustSpeed(runAnimationTimewarp)
		end
	end

	function actions.setAnimationSpeed(entity: AnimationEntity, speed: number)
		if entity.state.currentAnim == "walk" then
			actions.setRunSpeed(entity, speed)
		else
			if speed ~= entity.state.currentAnimSpeed then
				entity.state.currentAnimSpeed = speed
				if entity.state.currentAnimTrack then
					entity.state.currentAnimTrack:AdjustSpeed(entity.state.currentAnimSpeed)
				end
			end
		end
	end

	function actions.onKeyFrameReached(entity: AnimationEntity, frameName: string)
		if frameName == "End" then
			if entity.state.currentAnim == "walk" then
				if userNoUpdateOnLoop then
					if entity.state.runAnimTrack and not entity.state.runAnimTrack.Looped then
						entity.state.runAnimTrack.TimePosition = 0
					end
					if entity.state.currentAnimTrack and not entity.state.currentAnimTrack.Looped then
						entity.state.currentAnimTrack.TimePosition = 0
					end
				else
					if entity.state.runAnimTrack then
						entity.state.runAnimTrack.TimePosition = 0
					end
					if entity.state.currentAnimTrack then
						entity.state.currentAnimTrack.TimePosition = 0
					end
				end
			else
				local repeatAnim = entity.state.currentAnim

				-- return to idle if finishing an emote
				if EMOTE_NAMES[repeatAnim] ~= nil and EMOTE_NAMES[repeatAnim] == false then
					repeatAnim = "idle"
				end

				if entity.state.currentlyPlayingEmote then
					if entity.state.currentAnimTrack and entity.state.currentAnimTrack.Looped then
						-- allow the emote to loop
						return
					end

					repeatAnim = "idle"
					entity.state.currentlyPlayingEmote = false
				end

				local animSpeed = entity.state.currentAnimSpeed
				actions.playAnimation(entity, repeatAnim, 0.15)
				actions.setAnimationSpeed(entity, animSpeed)
			end
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

			if entity.state.runAnimTrack then
				entity.state.runAnimTrack:Stop(transitionTime)
				entity.state.runAnimTrack:Destroy()

				if userNoUpdateOnLoop then
					entity.state.runAnimTrack = nil
				end
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

			-- check to see if we need to blend a walk/run animation
			if name == "walk" then
				local runAnimName = "run"
				local animation = actions.rollAnimation(entity, runAnimName)

				local runAnimTrack = entity.meta.animator:LoadAnimation(animation)
				runAnimTrack.Priority = Enum.AnimationPriority.Core
				runAnimTrack:Play(transitionTime)

				entity.state.runAnimTrack = runAnimTrack

				if entity.state.runAnimKeyframeHandler then
					entity.state.runAnimKeyframeHandler:Disconnect()
				end

				entity.state.runAnimKeyframeHandler = runAnimTrack.KeyframeReached:Connect(function(frameName: string)
					actions.onKeyFrameReached(entity, frameName)
				end)
			end
		end
	end

	function actions.playAnimation(entity: AnimationEntity, name: string, transitionTime: number)
		local animation = actions.rollAnimation(entity, name)
		actions.switchAnimation(entity, animation, name, transitionTime)
		entity.state.currentlyPlayingEmote = false
	end

	function actions.playEmote(entity: AnimationEntity, emoteAnim: Animation, transitionTime: number)
		actions.switchAnimation(entity, emoteAnim, emoteAnim.Name, transitionTime)
		entity.state.currentlyPlayingEmote = true
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

local humanoidStateHandlers: { [string]: (AnimationEntity, ...any) -> () } = {}
do
	function humanoidStateHandlers.Died(entity: AnimationEntity)
		entity.state.pose = "Dead"
	end

	function humanoidStateHandlers.Running(entity: AnimationEntity, speed: number)
		local movedDuringEmote = entity.state.currentlyPlayingEmote and entity.meta.director.MoveDirection == Vector3.new(0, 0, 0)
		local speedThreshold = movedDuringEmote and entity.meta.director.WalkSpeed or 0.75
		if speed > speedThreshold then
			local scale = 16
			actions.playAnimation(entity, "walk", 0.2)
			actions.setAnimationSpeed(entity, speed / scale)
			entity.state.pose = "Running"
		else
			if EMOTE_NAMES[entity.state.currentAnim] == nil and not entity.state.currentlyPlayingEmote then
				actions.playAnimation(entity, "idle", 0.2)
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
		local scale = 5
		actions.playAnimation(entity, "climb", 0.1)
		actions.setAnimationSpeed(entity, speed / scale)
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
		if speed > 1 then
			local scale = 10
			actions.playAnimation(entity, "swim", 0.4)
			actions.setAnimationSpeed(entity, speed / scale)
			entity.state.pose = "Swimming"
		else
			actions.playAnimation(entity, "swimidle", 0.4)
			entity.state.pose = "Standing"
		end
	end
end

local function stepAnimate(entity: AnimationEntity, t: number, dt: number)
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

function module.animate(parent: Instance, director: Humanoid, performer: Humanoid): AnimateController
	local connections: { RBXScriptConnection } = {}

	local animator = nil
	local character = performer.Parent :: Instance

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

			currentAnim = "",
			currentAnimInstance = nil,
			currentAnimTrack = nil,
			currentAnimKeyframeHandler = nil,
			currentAnimSpeed = 1,

			runAnimTrack = nil,
			runAnimKeyframeHandler = nil,

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

	table.insert(
		connections,
		parent.ChildAdded:Connect(function(child)
			actions.refreshAnimationSet(entity, child.Name)
		end)
	)

	table.insert(
		connections,
		parent.ChildRemoved:Connect(function(child)
			actions.refreshAnimationSet(entity, child.Name)
		end)
	)

	for name, callback in humanoidStateHandlers do
		table.insert(
			connections,
			(director :: any)[name]:Connect(function(...)
				callback(entity, ...)
			end)
		)
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

	return {
		playEmote = playEmote,
		cleanup = cleanup,
	}
end

return module

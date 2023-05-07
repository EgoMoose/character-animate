--!strict

local AnimateR6 = require(script:WaitForChild("AnimateR6"))
local AnimateR15 = require(script:WaitForChild("AnimateR15"))
local ManualDirector = require(script:WaitForChild("ManualDirector"))

type AnimateController = {
	cleanup: () -> (),
	playEmote: (string | Animation) -> (boolean, AnimationTrack?)
}

type ManualHumanoid = ManualDirector.ManualHumanoid

type AnimateControllerManually = AnimateController & {
	fireState: ManualDirector.FireState,
	setMovement: ManualDirector.SetMovement,
}

local module = {}

local function animateInternal(parent: Instance, director: Humanoid | ManualHumanoid, performer: Humanoid?): AnimateController
	local castedDirector = director :: Humanoid
	local actor = performer or castedDirector

	local cleanup, playEmote
	if actor.RigType == Enum.HumanoidRigType.R6 then
		cleanup, playEmote = AnimateR6.animate(parent, castedDirector, actor)
	else
		cleanup, playEmote = AnimateR15.animate(parent, castedDirector, actor)
	end

	return {
		cleanup = cleanup,
		playEmote = playEmote,
	}
end

function module.animate(parent: Instance, director: Humanoid, performer: Humanoid?): AnimateController
	return animateInternal(parent, director, performer)
end

function module.animateManually(parent: Instance, performer: Humanoid): AnimateControllerManually
	local director = ManualDirector.create()
	local animated = animateInternal(parent, director.humanoid, performer)

	return {
		cleanup = animated.cleanup,
		playEmote = animated.playEmote,
		fireState = director.fireState,
		setMovement = director.setMovement,
	}
end

return module
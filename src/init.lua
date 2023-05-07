--!strict

local AnimateR6 = require(script:WaitForChild("AnimateR6"))
local AnimateR15 = require(script:WaitForChild("AnimateR15"))
local ManualDirector = require(script:WaitForChild("ManualDirector"))
local SharedTypes = require(script:WaitForChild("SharedTypes"))

local module = {}

local function animateInternal(parent: Instance, director: Humanoid | ManualDirector.ManualHumanoid, performer: Humanoid?): SharedTypes.AnimateController
	local castedDirector = director :: Humanoid
	local actor = performer or castedDirector

	local controller
	if actor.RigType == Enum.HumanoidRigType.R6 then
		controller = AnimateR6.animate(parent, castedDirector, actor)
	else
		controller = AnimateR15.animate(parent, castedDirector, actor)
	end

	return controller
end

function module.animate(parent: Instance, director: Humanoid, performer: Humanoid?): SharedTypes.AnimateController
	return animateInternal(parent, director, performer)
end

function module.animateManually(parent: Instance, performer: Humanoid): ManualDirector.AnimateControllerManually
	local director = ManualDirector.create()
	local controller: any = animateInternal(parent, director.humanoid, performer)

	controller.fireState = director.fireState
	controller.setMovement = director.setMovement

	return controller :: ManualDirector.AnimateControllerManually
end

return module
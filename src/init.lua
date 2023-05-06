--!strict

local AnimateR6 = require(script:WaitForChild("AnimateR6"))
local AnimateR15 = require(script:WaitForChild("AnimateR15"))
local ManualDirector = require(script:WaitForChild("ManualDirector"))

type ManualHumanoid = ManualDirector.ManualHumanoid

type AnimateManually = {
	cleanup: () -> (),
	fireState: ManualDirector.FireState,
	setMovement: ManualDirector.SetMovement,
}

local module = {}

function module.animate(parent: Instance, director: Humanoid | ManualHumanoid, performer: Humanoid?): () -> ()
	local castedDirector = director :: Humanoid
	local actor = performer or castedDirector

	if actor.RigType == Enum.HumanoidRigType.R6 then
		return AnimateR6.animate(parent, castedDirector, actor)
	else
		return AnimateR15.animate(parent, castedDirector, actor)
	end
end

function module.animateManually(parent: Instance, performer: Humanoid): AnimateManually
	local director = ManualDirector.create()
	local cleanup = module.animate(parent, director.humanoid, performer)

	return {
		cleanup = cleanup,
		fireState = director.fireState,
		setMovement = director.setMovement,
	}
end

return module
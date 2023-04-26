--!strict

local AnimateR6 = require(script:WaitForChild("AnimateR6"))
local AnimateR15 = require(script:WaitForChild("AnimateR15"))

local module = {}

function module.animate(parent: Instance, director: Humanoid, performer: Humanoid?)
	local actor = performer or director

	if actor.RigType == Enum.HumanoidRigType.R6 then
		return AnimateR6.animate(parent, director, actor)
	else
		return AnimateR15.animate(parent, director, actor)
	end
end

return module
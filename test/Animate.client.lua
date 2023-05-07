local Packages = game.ReplicatedStorage.Packages
local CharacterAnimate = require(Packages.CharacterAnimate)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local dummy = workspace.Dummy
local dummyHumanoid = dummy:WaitForChild("Humanoid")

CharacterAnimate.animate(script, humanoid)

local controller = CharacterAnimate.animateManually(script, dummyHumanoid)
while true do
	controller.fireState(Enum.HumanoidStateType.Climbing, 5)
	task.wait(4)
	controller.fireState(Enum.HumanoidStateType.Running, 16)
	task.wait(2)
	controller.fireState(Enum.HumanoidStateType.Freefall)
	task.wait(1)
	controller.fireState(Enum.HumanoidStateType.Seated)
	task.wait(2)
end
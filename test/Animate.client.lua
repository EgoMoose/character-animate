local Packages = game.ReplicatedStorage.Packages
local CharacterAnimate = require(Packages.CharacterAnimate)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local dummy = workspace.Dummy
local dummyHumanoid = dummy:WaitForChild("Humanoid")

CharacterAnimate.animate(script, humanoid)

local controller = CharacterAnimate.animateManually(script, dummyHumanoid)
controller.fireState(Enum.HumanoidStateType.Climbing, 5)
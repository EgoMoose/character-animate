local Packages = game.ReplicatedStorage.Packages
local CharacterAnimate = require(Packages.CharacterAnimate)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local dummy = workspace.Dummy
local dummyHumanoid = dummy:WaitForChild("Humanoid")

CharacterAnimate.animate(script, humanoid)
CharacterAnimate.animate(script, humanoid, dummyHumanoid)
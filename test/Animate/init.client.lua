local Players = game:GetService("Players")

local Packages = game.ReplicatedStorage.Packages
local CharacterAnimate = require(Packages.CharacterAnimate)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local dummy = workspace.Dummy
local dummyHumanoid = dummy:WaitForChild("Humanoid")

-- For my character

local myController = CharacterAnimate.animate(script, humanoid)

Players.LocalPlayer.Chatted:Connect(function(msg)
	-- This is only needed for the legacy chat system
	local emote = ""
	if msg:sub(1, 3) == "/e " then
		emote = msg:sub(4)
	elseif msg:sub(1, 7) == "/emote " then
		emote = msg:sub(8)
	end

	myController.playEmote(emote)
end)

script:WaitForChild("PlayEmote").OnInvoke = function(emote)
	return myController.playEmote(emote)
end

-- For the dummy character

local dummyController = CharacterAnimate.animateManually(script, dummyHumanoid)
while true do
	dummyController.fireState(Enum.HumanoidStateType.Climbing, 5)
	task.wait(4)
	dummyController.fireState(Enum.HumanoidStateType.Running, 16)
	task.wait(2)
	dummyController.fireState(Enum.HumanoidStateType.Freefall)
	task.wait(1)
	dummyController.fireState(Enum.HumanoidStateType.Seated)
	task.wait(2)
end
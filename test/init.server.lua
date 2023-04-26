local StarterPlayer = game:GetService("StarterPlayer")
local StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts")

local Animate = script:WaitForChild("Animate")

local found = StarterCharacterScripts:FindFirstChild(Animate.Name)
if not found then
	Animate:Clone().Parent = StarterCharacterScripts
end


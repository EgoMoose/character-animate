local StarterPlayer = game:GetService("StarterPlayer")
local StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts")

local Animate = script:WaitForChild("Animate")

local found = StarterCharacterScripts:FindFirstChild(Animate.Name)
if not found or not found.Enabled then
	if found then
		found:Destroy()
	end

	Animate:Clone().Parent = StarterCharacterScripts
end


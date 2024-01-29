--!strict

local Packages = script.Parent.Parent
local Signal = require(Packages:WaitForChild("Signal"))
local ExportedTypes = require(script.Parent:WaitForChild("ExportedTypes"))

type AnimateControllerManually = ExportedTypes.AnimateControllerManually
type ManualHumanoid = ExportedTypes.ManualHumanoid
type ManualDirector = ExportedTypes.ManualDirector

local MAP_STATE_TO_SIGNAL = {
	[Enum.HumanoidStateType.Dead] = "Died",
	[Enum.HumanoidStateType.Running] = "Running",
	[Enum.HumanoidStateType.RunningNoPhysics] = "Running",
	[Enum.HumanoidStateType.Jumping] = "Jumping",
	[Enum.HumanoidStateType.Climbing] = "Climbing",
	[Enum.HumanoidStateType.GettingUp] = "GettingUp",
	[Enum.HumanoidStateType.Freefall] = "FreeFalling",
	[Enum.HumanoidStateType.Seated] = "Seated",
	[Enum.HumanoidStateType.PlatformStanding] = "PlatformStanding",
	[Enum.HumanoidStateType.Swimming] = "Swimming",
}

local module = {}

function module.create(): ManualDirector
	local humanoid: ManualHumanoid = {
		Died = Signal.new(),
		Running = Signal.new(),
		Jumping = Signal.new(),
		Climbing = Signal.new(),
		GettingUp = Signal.new(),
		FreeFalling = Signal.new(),
		FallingDown = Signal.new(),
		Seated = Signal.new(),
		PlatformStanding = Signal.new(),
		Swimming = Signal.new(),

		MoveDirection = Vector3.zero,
		WalkSpeed = 16,
	}

	local function fireState(state: Enum.HumanoidStateType, ...)
		local mapped = MAP_STATE_TO_SIGNAL[state]
		if mapped then
			humanoid[mapped]:Fire(...)
		end
	end

	local function setMovement(moveDirection: Vector3, walkSpeed: number)
		humanoid.MoveDirection = moveDirection
		humanoid.WalkSpeed = walkSpeed
	end

	return {
		humanoid = humanoid,
		fireState = fireState,
		setMovement = setMovement,
	}
end

return module

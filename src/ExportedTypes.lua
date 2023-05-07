--!strict

-- AnimateR15 and AnimateR6

export type SerializedAnimation = {
	id: string,
	weight: number,
}

export type AnimationSet = {
	count: number,
	totalWeight: number,
	connections: {RBXScriptConnection},
	entries: {{
		animation: Animation,
		weight: number,
	}}
}

type AnimationStateR15 = {
	pose: string,

	currentAnim: string,
	currentAnimInstance: Animation?,
	currentAnimTrack: AnimationTrack?,
	currentAnimKeyframeHandler: RBXScriptConnection?,
	currentAnimSpeed: number,

	runAnimTrack: AnimationTrack?,
	runAnimKeyframeHandler: RBXScriptConnection?,

	toolAnim: string,
	toolAnimInstance: Animation?,
	toolAnimTrack: AnimationTrack?,
	currentToolAnimKeyframeHandler: RBXScriptConnection?,

	legacyToolAnim: string,
	legacyToolAnimTime: number,

	jumpAnimTime: number,
	currentlyPlayingEmote: boolean,
}

type AnimationStateR6 = {
	pose: string,

	rightShoulder: Motor6D,
	leftShoulder: Motor6D,
	rightHip: Motor6D,
	leftHip: Motor6D,
	neck: Motor6D,

	currentAnim: string,
	currentAnimInstance: Animation?,
	currentAnimTrack: AnimationTrack?,
	currentAnimKeyframeHandler: RBXScriptConnection?,
	currentAnimSpeed: number,

	toolAnim: string,
	toolAnimInstance: Animation?,
	toolAnimTrack: AnimationTrack?,
	currentToolAnimKeyframeHandler: RBXScriptConnection?,

	legacyToolAnim: string,
	legacyToolAnimTime: number,

	jumpAnimTime: number,
	currentlyPlayingEmote: boolean,
}

type AnimationEntity = {
	sets: {[string]: AnimationSet},

	meta: {
		director: Humanoid,
		performer: Humanoid,
		animator: Animator,

		preloaded: {[string]: boolean},
		parent: Instance,
	}
}

export type AnimationEntityR15 = AnimationEntity & {
	state: AnimationStateR15,
}

export type AnimationEntityR6 = AnimationEntity & {
	state: AnimationStateR6,
}

-- Manual Director

type ScriptSignal = RBXScriptSignal & {
	Fire: (...any) -> ()
}

type SetMovement = (Vector3, number) -> ()
type FireState = (Enum.HumanoidStateType, ...any) -> ()

export type ManualDirector = {
	fireState: FireState,
	setMovement: SetMovement,
	humanoid: ManualHumanoid,
}

export type ManualHumanoid = {
	Died: ScriptSignal,
	Running: ScriptSignal,
	Jumping: ScriptSignal,
	Climbing: ScriptSignal,
	GettingUp: ScriptSignal,
	FreeFalling: ScriptSignal,
	FallingDown: ScriptSignal,
	Seated: ScriptSignal,
	PlatformStanding: ScriptSignal,
	Swimming: ScriptSignal,

	MoveDirection: Vector3,
	WalkSpeed: number,
}

-- Public interfaces

export type AnimateController = {
	cleanup: () -> (),
	playEmote: (string | Animation) -> (boolean, AnimationTrack?)
}

export type AnimateControllerManually = AnimateController & {
	fireState: FireState,
	setMovement: SetMovement,
}

return {}
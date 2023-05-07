--!strict

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

export type AnimationEntityNoState = {
	sets: {[string]: AnimationSet},

	meta: {
		director: Humanoid,
		performer: Humanoid,
		animator: Animator,

		preloaded: {[string]: boolean},
		parent: Instance,
	}
}

export type AnimateController = {
	cleanup: () -> (),
	playEmote: (string | Animation) -> (boolean, AnimationTrack?)
}

return {}
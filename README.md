# Character Animate
A replacement implementation of the `Animate` script that is typically loaded into characters by default.

Get it here:

* [Wally](https://wally.run/package/egomoose/character-animate)
* [Releases](https://github.com/EgoMoose/character-animate/releases)

## API

```Lua
--[=[
Creates a new animate controller

@param parent Instance -- The instance where custom animations will be loaded from
@param director Humanoid -- The humanoid used to track state for transitioning animations
@param performer Humanoid? -- The humanoid the animations will play on. Defaults to `director` if nil
@return AnimateController: {
	cleanup: () -> (), -- stops the animate process
	playEmote: (string | Animation) -> (boolean, AnimationTrack?), -- play an emote either by string name or animation instance
}
--]=]
function module.animate(parent: Instance, director: Humanoid, performer: Humanoid?): AnimateController

--[=[
Creates a new animate controller that can transition states manually

@param parent Instance -- The instance where custom animations will be loaded from
@param performer Humanoid -- The humanoid the animations will play on
@return AnimateControllerManually: {
	cleanup: () -> (), -- stops the animate process
	playEmote: (string | Animation) -> (boolean, AnimationTrack?) -- play an emote either by string name or animation instance
	fireState: (Enum.HumanoidStateType, ...any) -> (), -- fire a humanoid state for a reactive animation
	setMovement: (Vector3, number) -> (), -- set humanoid MoveDirection and WalkSpeed properties for animation calculation
}
--]=]
function module.animateManually(parent: Instance, performer: Humanoid): AnimateControllerManually
```

An example of using this package to replicate the standard `Animate` script:

```Lua
-- Animate.lua (placed under StarterCharacterScripts)
local CharacterAnimate = require(...)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local controller = CharacterAnimate.animate(script, humanoid)

script:WaitForChild("PlayEmote").OnInvoke = function(emote)
	return controller.playEmote(emote)
end
```
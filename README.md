# Character Animate
An implementation of the default `Animate` script that is typically loaded into characters by default.

```Lua
--[=[
Creates a new animate process

@param parent Instance -- The instance where custom animations will be loaded from
@param director Humanoid -- The humanoid used to track state for transitioning animations
@param performer Humanoid? -- The humanoid the animations will play on. Defaults to `director` if nil
@return function () -> () -- Calling this function cleans up the animate process
--]=]
function module.animate(parent: Instance, director: Humanoid, performer: Humanoid?): () -> ()
```

An example of using this package to replicate the standard `Animate` script:

```Lua
-- Animate.lua (placed under StarterCharacterScripts)
local CharacterAnimate = require(...)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

CharacterAnimate.animate(script, humanoid)
```
# Canvas

Renders images using UIGradients to reduce the number of frames needed.
Currently due to Roblox engine limitations there is a maximum of 128^2
unique colors. Works well in conjunction with
[Roblox-PNG-Library](https://github.com/CloneTrooper1019/Roblox-PNG-Library).
Please do not use this library to bypass Roblox moderation, it is purely for
fun.

This example uses Roblox PNG Library to render an image imported into Studio.

```lua
local DOWNSCALING = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StudioService = game:GetService("StudioService")

local Canvas = require(ReplicatedStorage.Canvas)
local PNG = require(ReplicatedStorage.PNG) -- Roblox PNG Library

local file = StudioService:PromptImportFile({"png"})
local image = PNG.new(file:GetBinaryContents())
local canvas = Canvas.new(
    image.Width / DOWNSCALING,
    image.Height / DOWNSCALING
)

function canvas:GetPixel(x, y)
    --[[
        Overwrite the canvas's GetPixel method to use PNG instead. This saves
        us time during the prerendering process so we don't have to loop
        through the image to set every pixel on the canvas.
    ]]
    return image:GetPixel(
        x * DOWNSCALING,
        y * DOWNSCALING
    )
end

local frame = canvas:Render()
local screengui = Instance.new("ScreenGui")
frame.Parent = screengui
screengui.Parent = StarterGui
```

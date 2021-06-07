local DOWNSCALING = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StudioService = game:GetService("StudioService")

local Canvas = require(ReplicatedStorage.Canvas)
local PNG = require(ReplicatedStorage.PNG)

local file = StudioService:PromptImportFile({"png"})
local image = PNG.new(file:GetBinaryContents())
local canvas = Canvas.new(
    image.Width / DOWNSCALING,
    image.Height / DOWNSCALING
)

function canvas:GetPixel(x, y)
    return image:GetPixel(
        x * DOWNSCALING,
        y * DOWNSCALING
    )
end

local encodeStart = os.clock()
local encoding = canvas:Encode()
local encodeEnd = os.clock()

local decodeStart = os.clock()
canvas:FromEncoding(encoding)
local decodeEnd = os.clock()

local renderStart = os.clock()
local frame = canvas:Render()
local renderEnd = os.clock()

local screengui = Instance.new("ScreenGui")
frame.Parent = screengui
screengui.Parent = StarterGui

print("Encoding took", encodeEnd - encodeStart)
print("Decoding took", decodeEnd - decodeStart)
print("Rendering took", renderEnd - renderStart)
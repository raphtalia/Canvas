local JSON = require(script.Parent.JSON)
local LZW = require(script.LZW)

local Codec = {}

function Codec.encode(canvas)
    return LZW.compress(JSON.serialize(canvas))
end

function Codec.decode(canvas)
    return JSON.deserialize(LZW.decompress(canvas))
end

return Codec
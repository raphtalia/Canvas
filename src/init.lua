-- Not sure how much this optimizes but any bit helps in this case
local WHITE_COLOR3 = Color3.new(1, 1, 1)
local BLANK_COLOR3 = Color3.new()

local Codec = require(script.Codec)

local insert = table.insert
local vec2 = Vector2.new
local colorSeq = ColorSequence.new
local colorSeqKeypoint = ColorSequenceKeypoint.new

local Canvas = {}

local function color3FuzzyEq(c30, c31, epsilon)
    epsilon = math.max(epsilon or 0, 1.01)

    if epsilon > 1 then
        epsilon /= 255
    end

    if c30.r > c31.r - epsilon and c30.r < c31.r + epsilon
    and c30.g > c31.g - epsilon and c30.g < c31.g + epsilon
    and c30.b > c31.b - epsilon and c30.b < c31.b + epsilon then
        return true
    end

    return false
end

function Canvas.new(x, y)
    local canvas = {}

    canvas._prerenderedCanvas = {}

    canvas.Width = x
    canvas.Height = y
    canvas.Pixels = {}
    canvas.Settings = {
        CompressSegments = true,
        CompressFrames = true,
        Color3Epsilon = 4,
    }

    return setmetatable(canvas, {__index = Canvas})
end

function Canvas:SetPixel(x, y, color3)
    self.Pixels[("%s,%s"):format(x, y)] = color3
    self._prerenderedCanvas = {}
    return self
end

function Canvas:GetPixel(x, y)
    return self.Pixels[("%s,%s"):format(x, y)] or BLANK_COLOR3
end

function Canvas:Encode()
    self:Prerender()
    return Codec.encode(self._prerenderedCanvas)
end

function Canvas:FromEncoding(encoding)
    self._prerenderedCanvas = Codec.decode(encoding)
    return self
end

function Canvas:Prerender()
    local canvasSize = vec2(self.Width, self.Height)
    local color3Epsilon = self.Settings.Color3Epsilon

    for y = 1, canvasSize.Y do
        local x = 1
        local prerenderSegment = {}

        repeat
            local posStart = vec2(x, y)
            local posEnd
            local colors = {}
            local width

            repeat
                local lastColor3 = colors[#colors]
                local curColor3 = self:GetPixel(x, y)

                if not lastColor3 or not color3FuzzyEq(lastColor3.Color3, curColor3, color3Epsilon) then
                    insert(
                        colors,
                        {
                            X = x - posStart.X,
                            Color3 = curColor3,
                        }
                    )
                end

                x += 1
            until #colors == 10 or x > canvasSize.X
            posEnd = vec2(x, y)
            width = posEnd.X - posStart.X

            local colorSequence = {}
            for i, color in ipairs(colors) do
                local color3 = color.Color3
                local colorStart = color.X
                local colorEnd = colors[i + 1]

                colorStart /= width
                colorEnd = colorEnd and colorEnd.X
                colorEnd = i == #colors and 1 or colorEnd / width - 0.0001

                insert(
                    colorSequence,
                    colorSeqKeypoint(
                        colorStart,
                        color3
                    )
                )
                insert(
                    colorSequence,
                    colorSeqKeypoint(
                        colorEnd,
                        color3
                    )
                )
            end

            if #colorSequence > 2 then
                insert(prerenderSegment, {width, colorSeq(colorSequence)})
            else
                local color3 = colorSequence[1].Value
                local curFrame = {width, color3}
                insert(prerenderSegment, curFrame)
            end
        until x > canvasSize.X

        local lastPrerenderSegment = self._prerenderedCanvas[#self._prerenderedCanvas]

        if lastPrerenderSegment then
            -- Combine identical segments together
            if #lastPrerenderSegment == 1 and #prerenderSegment == 1 then
                if self.Settings.CompressSegments then
                    local lastPrerenderSegmentColor = lastPrerenderSegment[1][2]
                    local curPrerenderSegmentColor = prerenderSegment[1][2]

                    local lastPrerenderSegmentColorType = typeof(lastPrerenderSegmentColor)
                    local curPrerenderSegmentColorType = typeof(curPrerenderSegmentColor)

                    if (lastPrerenderSegmentColorType == "Color3" and curPrerenderSegmentColorType == "Color3"
                    and color3FuzzyEq(lastPrerenderSegmentColor, curPrerenderSegmentColor, color3Epsilon))
                    or (lastPrerenderSegmentColorType == "ColorSequence" and curPrerenderSegmentColorType == "ColorSequence"
                    and lastPrerenderSegmentColor == curPrerenderSegmentColor) then
                        local frame = lastPrerenderSegment[1]
                        frame[3] = (frame[3] or 1) + 1
                        continue
                    end
                end
            else
                if self.Settings.CompressFrames then
                    -- Combine identical frames together
                    for i = 1, math.min(#prerenderSegment, #lastPrerenderSegment) do
                        local lastFrame = lastPrerenderSegment[i]
                        local curFrame = prerenderSegment[i]

                        if type(lastFrame) == "table" then
                            local lastFrameColor = lastFrame[2]
                            local curFrameColor = curFrame[2]

                            local lastFrameColorType = typeof(lastFrameColor)
                            local curFrameColorType = typeof(curFrameColor)

                            if (lastFrameColorType == "Color3" and curFrameColorType == "Color3"
                            and color3FuzzyEq(lastFrameColor, curFrameColor, color3Epsilon))
                            or (lastFrameColorType == "ColorSequence" and curFrameColorType == "ColorSequence"
                            and lastFrameColor == curFrameColor) then
                                lastFrame[3] = (lastFrame[3] or 1) + 1
                                prerenderSegment[i] = curFrame[1]
                            end
                        end
                    end
                end
            end
        end

        insert(self._prerenderedCanvas, prerenderSegment)
    end

    return self
end

function Canvas:Render()
    local canvasSize = vec2(self.Width, self.Height)

    local canvas = Instance.new("Frame")
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.fromOffset(canvasSize.X, canvasSize.Y)

    if #self._prerenderedCanvas == 0 then
        self:Prerender()
    end

    local y = 1
    for i = 1, #self._prerenderedCanvas do
        local x = 0
        local prerenderSegment = self._prerenderedCanvas[i]

        local minHeight
        for _,frameData in ipairs(prerenderSegment) do
            local frameDataType = type(frameData)

            if frameDataType == "table" then
                local width = frameData[1]
                local colorSequence = frameData[2]
                local height = frameData[3] or 1

                local frame = Instance.new("Frame")
                frame.BorderSizePixel = 0
                frame.Position = UDim2.fromScale(
                    (x - 1) / canvasSize.X,
                    (y - 1) / canvasSize.Y
                )
                frame.Size = UDim2.fromScale(
                    width / canvasSize.X,
                    1 / canvasSize.Y * height
                )

                if typeof(colorSequence) == "Color3" then
                    -- UIGradient would be a solid color which is redundant
                    frame.BackgroundColor3 = colorSequence
                else
                    frame.BackgroundColor3 = WHITE_COLOR3
                    local gradient = Instance.new("UIGradient")
                    gradient.Color = colorSequence
                    gradient.Parent = frame
                end

                frame.Parent = canvas

                x += width
                if minHeight then
                    minHeight = math.min(minHeight, height)
                else
                    minHeight = height
                end
            elseif frameDataType == "number" then
                x += frameData
            end
        end

        y += minHeight
    end

    return canvas
end

return Canvas
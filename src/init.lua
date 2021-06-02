-- Not sure how much this optimizes but any bit helps in this case
local WHITE_COLOR3 = Color3.new(1, 1, 1)
local BLANK_COLOR3 = Color3.new()

local insert = table.insert
local vec2 = Vector2.new
local colorSeq = ColorSequence.new
local colorSeqKeypoint = ColorSequenceKeypoint.new

local Canvas = {}

function Canvas.new(x, y)
    local canvas = {}

    canvas.Width = x
    canvas.Height = y
    canvas.Pixels = {}
    canvas._prerenderData = {}

    return setmetatable(canvas, {__index = Canvas})
end

function Canvas:SetPixel(x, y, color3)
    self.Pixels[("%s,%s"):format(x, y)] = color3
    self._prerenderData = {}
    return self
end

function Canvas:GetPixel(x, y)
    return self.Pixels[("%s,%s"):format(x, y)] or BLANK_COLOR3
end

function Canvas:Prerender()
    local canvasSize = vec2(self.Width, self.Height)

    for y = 1, canvasSize.Y do
        local x = 1
        local preRenderData = {}

        repeat
            local posStart = vec2(x, y)
            local posEnd
            local colors = {}
            local width

            repeat
                local lastColor3 = colors[#colors]
                local curColor3 = self:GetPixel(x, y)

                if (lastColor3 and lastColor3.Color3 or lastColor3) ~= curColor3 then
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
                colorEnd = i == #colors and 1 or colorEnd / width - 0.001

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

            insert(
                preRenderData,
                {
                    Width = width,
                    ColorSequence = colorSequence,
                }
            )
        until x > canvasSize.X

        insert(self._prerenderData, preRenderData)
    end

    return self
end

function Canvas:Render()
    local canvasSize = vec2(self.Width, self.Height)

    local canvas = Instance.new("Frame")
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.fromOffset(canvasSize.X, canvasSize.Y)

    if #self._prerenderData == 0 then
        self:Prerender()
    end

    for y, preRenderData in ipairs(self._prerenderData) do
        local x = 0

        for _,frameData in ipairs(preRenderData) do
            local frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
            frame.Position = UDim2.fromScale(
                (x - 1) / canvasSize.X,
                (y - 1) / canvasSize.Y
            )
            frame.Size = UDim2.fromScale(
                frameData.Width / canvasSize.X,
                1 / canvasSize.Y
            )

            local colorSequence = frameData.ColorSequence
            if #colorSequence == 2 then
                -- UIGradient would be a solid color which is redundant
                frame.BackgroundColor3 = colorSequence[1].Value
            else
                frame.BackgroundColor3 = WHITE_COLOR3
                local gradient = Instance.new("UIGradient")
                gradient.Color = colorSeq(colorSequence)
                gradient.Parent = frame
            end

            frame.Parent = canvas

            x += frameData.Width
        end
    end

    return canvas
end

return Canvas
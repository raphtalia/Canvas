local BLANK_COLOR3 = Color3.new()

local Canvas = {}

function Canvas.new(x, y)
    local canvas = {}

    canvas.Size = Vector2.new(x, y)
    canvas.Pixels = {}
    canvas._prerenderData = {}

    return setmetatable(canvas, {__index = Canvas})
end

function Canvas:SetPixel(x, y, color3)
    self.Pixels[("%s,%s"):format(x, y)] = color3
end

function Canvas:GetPixel(x, y)
    return self.Pixels[("%s,%s"):format(x, y)] or BLANK_COLOR3
end

function Canvas:Prerender()
    local canvasSize = self.Size

    for y = 1, canvasSize.Y do
        local x = 1
        local preRenderData = {}

        repeat
            local posStart = Vector2.new(x, y)
            local posEnd
            local colors = {}
            local width

            repeat
                local lastColor3 = colors[#colors]
                local curColor3 = self:GetPixel(x, y)

                if (lastColor3 and lastColor3.Color3 or lastColor3) ~= curColor3 then
                    table.insert(
                        colors,
                        {
                            X = x - posStart.X,
                            Color3 = curColor3,
                        }
                    )
                end

                x += 1
            until #colors == 10 or x > canvasSize.X
            posEnd = Vector2.new(x, y)
            width = posEnd.X - posStart.X

            local colorSequence = {}
            for i, color in ipairs(colors) do
                local color3 = color.Color3
                local colorStart = color.X
                local colorEnd = colors[i + 1]

                colorStart /= width
                colorEnd = colorEnd and colorEnd.X
                colorEnd = i == #colors and 1 or colorEnd / width - 0.001

                table.insert(
                    colorSequence,
                    ColorSequenceKeypoint.new(
                        colorStart,
                        color3
                    )
                )
                table.insert(
                    colorSequence,
                    ColorSequenceKeypoint.new(
                        colorEnd,
                        color3
                    )
                )
            end

            table.insert(
                preRenderData,
                {
                    Width = width,
                    ColorSequence = colorSequence,
                }
            )
        until x > canvasSize.X

        table.insert(self._prerenderData, preRenderData)
    end

    return self
end

function Canvas:Render()
    local canvasSize = self.Size

    local canvas = Instance.new("Frame")
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.new(0, canvasSize.X, 0, canvasSize.Y)

    if #self._prerenderData == 0 then
        self:Prerender()
    end

    for y, preRenderData in ipairs(self._prerenderData) do
        local x = 0

        for _,frameData in ipairs(preRenderData) do
            local frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
            frame.Position = UDim2.new(
                (x - 1) / canvasSize.X,
                0,
                (y - 1) / canvasSize.Y,
                0
            )
            frame.Size = UDim2.new(
                frameData.Width / canvasSize.X,
                0,
                1 / canvasSize.Y,
                0
            )

            local colorSequence = frameData.ColorSequence
            if #colorSequence == 2 then
                -- UIGradient would be a solid color which is redundant
                frame.BackgroundColor3 = colorSequence[1].Value
            else
                frame.BackgroundColor3 = Color3.new(1, 1, 1)
                local gradient = Instance.new("UIGradient")
                gradient.Color = ColorSequence.new(colorSequence)
                gradient.Parent = frame
            end

            frame.Parent = canvas

            x += frameData.Width
        end
    end

    return canvas
end

return Canvas
local BLANK_COLOR3 = Color3.new()

local Canvas = {}

function Canvas.new(x, y)
    local canvas = {}

    canvas.Size = Vector2.new(x, y)
    canvas.Pixels = {}

    return setmetatable(canvas, {__index = Canvas})
end

function Canvas:SetColor3(x, y, color3)
    self.Pixels[("%s,%s"):format(x, y)] = color3
end

function Canvas:GetColor3(x, y)
    return self.Pixels[("%s,%s"):format(x, y)] or BLANK_COLOR3
end

function Canvas:Render()
    local canvasSize = self.Size

    local canvas = Instance.new("Frame")
    canvas.BackgroundTransparency = 1
    canvas.Size = UDim2.new(0, canvasSize.X, 0, canvasSize.Y)

    for y = 1, canvasSize.Y do
        local x = 1

        repeat
            local posStart = Vector2.new(x, y)
            local posEnd
            local colors = {}
            local width

            repeat
                local lastColor3 = colors[#colors]
                local curColor3 = self:GetColor3(x, y)

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

            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.new(1, 1, 1)
            frame.BorderSizePixel = 0
            frame.Position = UDim2.new(
                (posStart.X - 1) / canvasSize.X,
                0,
                (posStart.Y - 1) / canvasSize.Y,
                0
            )
            frame.Size = UDim2.new(
                width / canvasSize.X,
                0,
                1 / canvasSize.Y,
                0
            )

            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new(colorSequence)
            gradient.Parent = frame

            frame.Parent = canvas
        until x > canvasSize.X
    end

    return canvas
end

return Canvas
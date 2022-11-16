function drawArrow(x, y, size, angle)
    x = x + size/2 * math.sin(angle)
    y = y - size/2 * math.cos(angle)
    local a1, a2 = angle + 0.35, angle - 0.35
    screen.drawTriangleF(x, y, x - size*math.sin(a1), y + size*math.cos(a1), x - size*math.sin(a2), y + size*math.cos(a2))
end

function inRect(x, y, rectX, rectY, rectW, rectH)
	return x >= rectX and y >= rectY and x <= rectX + rectW and y <= rectY + rectH
end

currentColor = {0, 0, 0}
function setToColor(newColor)
    if currentColor[1] ~= newColor[1] or currentColor[2] ~= newColor[2] or currentColor[3] ~= newColor[3] then
        screen.setColor(newColor[1], newColor[2], newColor[3])
        currentColor[1] = newColor[1]
        currentColor[2] = newColor[2]
        currentColor[3] = newColor[3]
    end
end
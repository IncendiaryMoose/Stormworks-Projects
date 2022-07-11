---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Minimum Distance', 60)
simulator:setProperty('Maximum Distance', 3000)
simulator:setProperty('Minimum Seperation', 7)
simulator:setProperty('Distance Seperation Ratio', 0.02)
simulator:setProperty('FOV', 0.25)
simulator:setProperty('Maximum Age', 210)
simulator:setProperty('Zoom', 1)
simulator:setProperty('Target Size', 3)
simulator:setProperty('Pointer Size', 15)
onLBSimulatorTick = function(simulator, ticks)

end
---@endsection
pi = math.pi
pi2 = pi*2
minDist = property.getNumber('Minimum Distance')
maxDist = property.getNumber('Maximum Distance')
minSeperation = property.getNumber('Minimum Seperation')
distanceSeperationRatio = property.getNumber('Distance Seperation Ratio')
fov = property.getNumber('FOV')*pi
maxAge = property.getNumber('Maximum Age')
zoom = property.getNumber('Zoom')
targetSize = property.getNumber('Target Size')
pointerSize = property.getNumber('Pointer Size')
radarPosition = {0, 0, 0}
radarRotation = {0, 0, 0}
targets = {}
function onTick()
    radarPosition = {input.getNumber(8), input.getNumber(12), input.getNumber(16)}
    radarRotation = {input.getNumber(20)*pi2, math.atan(math.sin(input.getNumber(24)*pi2), math.sin(input.getNumber(28)*pi2)), input.getNumber(32)*pi2}
    radarYaw = input.getNumber(29)*pi2 - radarRotation[3]
    timeSinceUpdate = input.getNumber(4)
    blip = false
    if timeSinceUpdate == 0 then
        for i = 0, 6, 1 do
            local distance, azimuth, elevation = input.getNumber(i*4+1), input.getNumber(i*4+2)*pi2, input.getNumber(i*4+3)*pi2
            if distance == 0 then
                break
            end
            if distance > minDist then
                local targetPosition = {
                    distance * math.sin(azimuth) * math.cos(elevation),
                    distance * math.cos(azimuth) * math.cos(elevation),
                    distance * math.sin(elevation)
                }
                targetPosition = rotatePoint(targetPosition, radarRotation)
                targetPosition = addVectors(targetPosition, radarPosition)
                for targetIndex, target in ipairs(targets) do
                    if distanceBetween(targetPosition, target.position) < minSeperation + distance*distanceSeperationRatio then
                        goto skipTarget
                    end
                end
                blip = true
                table.insert(targets, {position = targetPosition, age = 0})
            end
            ::skipTarget::
        end
    end
    for i = #targets, 1, -1 do
        targets[i].age = targets[i].age + 1
        if targets[i].age > maxAge then
            table.remove(targets, i)
        end
    end
    output.setBool(1, blip)
end

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()

    screen.drawMap(radarPosition[1], radarPosition[2], zoom)

    screen.setColor(0, 255, 0, 35)
    screen.drawTriangleF(w/2, h/2, w/2 + w*math.sin(radarYaw+fov), h/2 - w*math.cos(radarYaw+fov), w/2 + w*math.sin(radarYaw-fov), h/2 - w*math.cos(radarYaw-fov))

    screen.setColor(200, 200, 200)
    drawArrow(w/2, h/2, pointerSize, -radarRotation[3])

    screen.setColor(255, 165, 0)
    for targetIndex, target in ipairs(targets) do
        local pixelX, pixelY = map.mapToScreen(radarPosition[1], radarPosition[2], zoom, w, h, target.position[1], target.position[2])
        screen.drawCircleF(pixelX, pixelY, targetSize)
    end
end

function rotatePoint(positionVector, rotationVector)
    local sx, sy, sz, cx, cy, cz = math.sin(rotationVector[1]), math.sin(rotationVector[2]), math.sin(rotationVector[3]), math.cos(rotationVector[1]), math.cos(rotationVector[2]), math.cos(rotationVector[3])

    return {
        positionVector[1]*(cz*cy-sz*sx*sy) + positionVector[2]*(-sz*cx) + positionVector[3]*(cz*sy+sz*sx*cy),
        positionVector[1]*(sz*cy+cz*sx*sy) + positionVector[2]*(cz*cx) + positionVector[3]*(sz*sy-cz*sx*cy),
        positionVector[1]*(-cx*sy) + positionVector[2]*(sx) + positionVector[3]*(cx*cy)
    }
end

function addVectors(a, b)
    return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

function distanceBetween(a, b)
    return ((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2)^0.5
end

function drawArrow(x, y, size, angle)
    x = x + size/2 * math.sin(angle)
    y = y - size/2 * math.cos(angle)
    local a1, a2 = angle + 0.35, angle - 0.35
    screen.drawTriangleF(x, y, x - size*math.sin(a1), y + size*math.cos(a1), x - size*math.sin(a2), y + size*math.cos(a2))
end
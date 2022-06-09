---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty("Cross", false)
simulator:setProperty("Color Depth", 500)
simulator:setProperty("World Horizontal Resolution", 5)
simulator:setProperty("World Vertical Resolution", 5)
simulator:setProperty("Screen Horizontal Resolution", 5)
simulator:setProperty("Screen Vertical Resolution", 5)
simulator:setProperty("Angle Step", 0.006)
simulator:setProperty("FOV", 5)
simulator:setProperty("Opacity", 150)
test = 0
onLBSimulatorTick = function(simulator, ticks)
    lasYew = math.sin(ticks/100)
    simulator:setInputNumber(1,0)     --gps x
    simulator:setInputNumber(2,0)     --gps y
    simulator:setInputNumber(3,0)     --gps z
    simulator:setInputNumber(4,0)     --gps z 2
    simulator:setInputNumber(7,0.25)
    simulator:setInputNumber(8, 0)--math.sin(ticks/10)/8)
    simulator:setInputNumber(9, lasYew)
    simulator:setInputNumber(10, 30)
    simulator:setInputNumber(11, 20)
    simulator:setInputNumber(12, 10)
    simulator:setInputNumber(13, 20)
    simulator:setInputNumber(14, 30)
    simulator:setInputNumber(15, 30)
    simulator:setInputNumber(16, 20)
    simulator:setInputNumber(17, 10)
    simulator:setInputNumber(18, 20)
    simulator:setInputNumber(19, 30)
end
---@endsection
require("Extended_Vector_Math")
require("Clamp")

diag = property.getBool("Cross")
colorDepth = property.getNumber("Color Depth")
worldHorizontalRes = property.getNumber("World Horizontal Resolution")
worldVerticalRes = property.getNumber("World Vertical Resolution")
screenHorizontalRes = property.getNumber("Screen Horizontal Resolution")
screenVerticalRes = property.getNumber("Screen Vertical Resolution")
angleStep = property.getNumber("Angle Step")
fov = property.getNumber("FOV")
opacity = property.getNumber("Opacity")
renderDist = property.getNumber("Render")
vehiclePosition = newExtendedVector()
vehicleRotation = newExtendedVector()
vehiclePositionIndex = newExtendedVector()
PI = math.pi
PI2 = PI*2
screenRotation = newExtendedVector(PI/2, 0, 0)
laserYaw = 0
timer = 0
h = 160
w = 288
monitor = {meterToPixelW = w/2.25, meterToPixelH = h/1.25, pixelW = w, pixelH = h, meterW = 2.25, meterH = 1.25, offsetX = 0, offsetY = 0, centerW = w/2-1, centerH = h/2, ratio = w/h}
worldPoints = {}

function onTick()
    vehiclePosition:set(input.getNumber(1), input.getNumber(2), input.getNumber(3))
    vehiclePositionIndex.x = math.floor((vehiclePosition.x/worldHorizontalRes)+0.5)
    vehiclePositionIndex.y = math.floor((vehiclePosition.y/worldHorizontalRes)+0.5)
    vehiclePositionIndex.z = math.floor((vehiclePosition.z/worldVerticalRes)+0.5)
    vehicleRotation:set(input.getNumber(4), input.getNumber(5), input.getNumber(6), input.getNumber(7))
    vehicleRotation:setScale(PI2)

    for i = 1, 17 do
        local laserDist = input.getNumber(9 + i)
        if laserDist > 20 and laserDist < 3500 then
            local worldPoint = newExtendedVector(laserDist,  input.getNumber(9)*PI2, (input.getNumber(8)+((i-9)*(angleStep)))*PI2)
            worldPoint:toCartesian()
            worldPoint:rotate3D(vehicleRotation)
            worldPoint:setAdd(worldPoint, vehiclePosition)
            local laserXIndex = math.floor((worldPoint.x/worldHorizontalRes)+0.5)
            local laserYIndex = math.floor((worldPoint.y/worldHorizontalRes)+0.5)
            local laserError = (math.abs(worldPoint.y/worldHorizontalRes)%1) + (math.abs(worldPoint.x/worldHorizontalRes)%1)
            worldPoint.w = laserError
            if not worldPoints[laserYIndex] then
                worldPoints[laserYIndex] = {}
            end
            local pointToReplace = worldPoints[laserYIndex][laserXIndex]
            if (not pointToReplace) or (laserError < pointToReplace.w) or ((worldPoint.z-25) > pointToReplace.z) then
                worldPoints[laserYIndex][laserXIndex] = worldPoint
            end
        end
    end
    timer = (timer + 0.5)%1000
    laserPitch = math.sin(((timer/1000)-0.5)*PI2)
    laserYaw = math.sin((((timer/100)%1)-0.5)*PI2)
    output.setNumber(1, (laserYaw)/1.5)
    output.setNumber(2, (laserPitch)/8)
end
function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()

    worldToScreenPoint(worldPoints)
    local drawBuffer = {}
    for pointYIndex = -renderDist, renderDist do
        pointRow = screenPoints[pointYIndex]
        if pointRow then
            for pointXIndex = -renderDist, renderDist do
                pixel = pointRow[pointXIndex]
                if pixel then
                    if pixel.w < colorDepth then
                        pixelLeft = pointRow[pointXIndex-1]
                        pixelRight = pointRow[pointXIndex+1]
                        pixelBehind = (screenPoints[pointYIndex+1] and screenPoints[pointYIndex+1][pointXIndex])
                        pixelFront = (screenPoints[pointYIndex-1] and screenPoints[pointYIndex-1][pointXIndex])
                        if pixelBehind and pixelRight then
                            table.insert(drawBuffer, {depth = pixel.w, p1 = pixel, p2 = pixelRight, p3 = pixelBehind})
                        end
                        if pixelFront and pixelLeft then
                            table.insert(drawBuffer, {depth = pixel.w, p1 = pixel, p2 = pixelLeft, p3 = pixelFront})
                        end
                    end
                end
            end
        end
    end
    table.sort(drawBuffer, function (a, b)
        return a.depth > b.depth
    end)
    for i, tri in ipairs(drawBuffer) do
        local pz = tri.depth/colorDepth
        local r, g, b =
            (pz > 0 and pz < 1 and (math.sin((pz/4+0.25)*PI2)^2)*255) or 0,
            (pz > 0 and pz < 1 and (math.sin((pz/4-0.5)*PI2)^2)*255) or 0,
            (pz > 0 and pz < 0.05 and (math.sin((pz*5-0.25)*PI2)^2)*255) or 0
        screen.setColor(r, g, b, math.min(255-(pz*255)+50,opacity))
        drawTri(tri)
    end
end
drawTri = function (tri)
    if tri.p1 and tri.p2 and tri.p3 then
        screen.drawTriangleF(tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y, tri.p3.x, tri.p3.y)
    end
end
worldToScreenPoint = function(points)
    screenPoints = {}
    for pointYIndex = -renderDist, renderDist do
        pointRow = points[vehiclePositionIndex.y + pointYIndex]
        if pointRow then
            for pointXIndex = -renderDist, renderDist do
                point = pointRow[vehiclePositionIndex.x + pointXIndex]
                if point then
                    local relativePoint = point:clone()
                    relativePoint:setSubtract(relativePoint, vehiclePosition)
                    relativePoint:unRotate3D(vehicleRotation)
                    local sx = monitor.centerW + ((relativePoint.x*(1/(relativePoint.y+1)))*monitor.meterToPixelW)-0.5
                    local sy = monitor.centerH - ((relativePoint.z*(1/(relativePoint.y+1)))*monitor.meterToPixelH)+0.5
                    local sz = relativePoint.y
                    if sz > 0 and sz < colorDepth and sx >= -fov and sx <= w + fov and sy >= -fov and sy <= h + fov then
                        if not screenPoints[pointYIndex] then
                            screenPoints[pointYIndex] = {}
                        end
                        screenPoints[pointYIndex][pointXIndex] = {
                            x = sx,
                            y = sy,
                            z = sz,
                            w = relativePoint:magnitude()
                        }
                    end
                end
            end
        end
    end
end
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
require('Extended_Vector_Math')
require("Advanced_Target_Fast_Decay")
require("Clamp")
require("In_Out")
maxLead = property.getNumber('Max Lead')
leadFactor = property.getNumber('Lead Factor')
vehiclePosition = newVector()
vehicleRotation = newVector()
vehiclePositionIndex = newVector()
PI = math.pi
PI2 = PI*2
screenRotation = newVector(PI/2, 0, 0)
timer = 0
h = 160
w = 288
monitor = {meterToPixelW = w/2.25, meterToPixelH = h/1.25, pixelW = w, pixelH = h, meterW = 2.25, meterH = 1.25, offsetX = 0, offsetY = 0, centerW = w/2-1, centerH = h/2, ratio = w/h}
pointChains = {}
targets = {}
for i = 1, 8, 1 do
    targets[i] = newTarget(newVector(), 1, 1)
    pointChains[i] = {}
end
jerkDecay = 0.1
accelerationDecay = 0.75
fov = 1
function onTick()
    zoom = input.getNumber(8)
    fov = 0.508388*(zoom - 2.65139)^2 + 2.02506*(zoom - 0.825779)^4 - 1.36716
    vehiclePosition:set(getInputVector(1))
    vehicleRotation:set(input.getNumber(4), input.getNumber(5), input.getNumber(6), input.getNumber(7))
    vehicleRotation:setScale(PI2)
    vehicleRotation.y = math.atan(math.sin(vehicleRotation.y), math.sin(vehicleRotation.w))
    for targetIndex, target in ipairs(targets) do
        local newPos = newVector(getInputVector((targetIndex-1)*3+9))
        pointChains[targetIndex] = {}
        if newPos:exists() then
            target:refresh(newPos)
        end
    end
    for targetIndex, target in ipairs(targets) do
        target:update(vehiclePosition)
        if target.updateAge < maxPrediction then
            table.insert(pointChains[targetIndex], target.position.predicted:clone())
            target:positionInTicks(math.min(target.distance/leadFactor, maxLead))
            table.insert(pointChains[targetIndex], target.position.predicted:clone())
        end
    end
end

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()

    worldToScreenPoint()
    for pointChainIndex, pointChain in ipairs(screenPoints) do
        for pointIndex, point in ipairs(pointChain) do
            if pointIndex == 1 then
                screen.setColor(0, 255, 0, 200)
                screen.drawCircle(point.x, point.y, 1.5)
            elseif pointIndex == #pointChain then
                screen.setColor(255, 0, 0, 200)
                screen.drawCircle(point.x, point.y, 5)
            else
                screen.setColor(100, 200, 0, 200)
                screen.drawCircleF(point.x, point.y, 1)
            end
        end
    end
    --[[local drawBuffer = {}
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
    end]]
end
drawTri = function (tri)
    if tri.p1 and tri.p2 and tri.p3 then
        screen.drawTriangleF(tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y, tri.p3.x, tri.p3.y)
    end
end
worldToScreenPoint = function()
    screenPoints = {{},{},{},{},{},{},{},{}}
    for chainIndex, chain in ipairs(pointChains) do
        for pointIndex, point in ipairs(chain) do
            if point:exists() then
                local relativePoint = point:clone()
                relativePoint:setSubtract(vehiclePosition)
                relativePoint:rotate3D(vehicleRotation, true)
                local sx = monitor.centerW + ((relativePoint.x*(1/(relativePoint.y*fov)))*monitor.meterToPixelW)-0.5
                local sy = monitor.centerH - ((relativePoint.z*(1/(relativePoint.y*fov)))*monitor.meterToPixelH)+0.5
                local sz = relativePoint.y
                if sz > 0 then
                    table.insert(screenPoints[chainIndex], {
                        x = sx,
                        y = sy,
                        z = sz,
                        w = relativePoint:magnitude()
                    })
                end
            end
        end
    end
end
---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Minimum Distance', 60)
simulator:setProperty('Maximum Distance', 3000)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Autoshoot Distance', 800)
onLBSimulatorTick = function(simulator, ticks)

end
---@endsection
require("Rotation_Vector_Math")
require("In_Out")
function avgVecList(list)
    if #list > 1 then
        local total = newRotatableVector()
        for i, j in ipairs(list) do
            total:setAdd(total, j)
        end
        total:setScale(1/#list)
        return total:clone()
    end
    return list[1]
end
function getBinaryInput(startChannel, endChannel)
    local result = 0
    for i = 0, endChannel-startChannel, 1 do
        local bit = input.getBool(i+startChannel)
        if bit then
            result = result + 2^(i)
        end
    end
    return result
end
minDist = property.getNumber('Minimum Distance')
maxDist = property.getNumber('Maximum Distance')
wepRange = property.getNumber('Weapons Range')
groupDist = property.getNumber('Group Distance')
vehiclePosition = newRotatableVector()
vehicleRotation = newRotatableVector()
screenClickPos = newRotatableVector()
worldClickPos = newRotatableVector()
click = false
PI = math.pi
PI2 = PI*2
zoom = 3
zSpeed = 0.03
killZone = 800
killSpeed = 3
distSpeed = 3
h = 160
w = 288
safeZones = {}
wasAddingZone = false
wasRemovingZone = false

function onTick()
    clearOutputs()
    targetGroups = {}
    click = input.getBool(19)
    zoomIn = input.getBool(20)
    zoomOut = input.getBool(21)
    radarIn = input.getBool(22)
    radarOut = input.getBool(23)
    autoIn = input.getBool(24)
    autoOut = input.getBool(25)
    autoAim = input.getBool(26)
    autoFire = input.getBool(27)
    manualFire = input.getBool(28)
    autoTarget = input.getBool(29)
    clearZones = input.getBool(30)
    removingZone = input.getBool(31)
    addingZone = input.getBool(32)
	screenClickPos:set(getBinaryInput(1, 9), getBinaryInput(10, 18))
    vehiclePosition:set(input.getNumber(8), input.getNumber(12), input.getNumber(16))
    vehicleRotation:set(input.getNumber(20), input.getNumber(24), input.getNumber(28), input.getNumber(32))
    vehicleRotation:setScale(PI2)
    vehicleRotation.y = math.atan(math.sin(vehicleRotation.y), math.sin(vehicleRotation.w))
    if input.getNumber(4) == 0 then
        for i=0, 7, 1 do
            local targetPosition = newRotatableVector(input.getNumber(i*4+1),input.getNumber(i*4+2)*PI2, input.getNumber(i*4+3)*PI2)
            if targetPosition.x > minDist and targetPosition.x < maxDist then
                targetPosition:toCartesian()
                targetPosition:rotate3D(vehicleRotation)
                targetPosition:setAdd(targetPosition, vehiclePosition)
                for z, zone in ipairs(safeZones) do
                    if targetPosition:distanceTo(zone) < zone.w then
                        goto safe
                    end
                end
                local targetDistance = targetPosition:distanceTo(vehiclePosition)
                for k, group in ipairs(targetGroups) do
                    for j, groupPosition in ipairs(group) do
                        if groupPosition:distanceTo(targetPosition) < groupDist + targetDistance/25 then
                            table.insert(group, targetPosition:clone())
                            goto safe
                        end
                    end
                end
                table.insert(targetGroups, {targetPosition:clone()})
                ::safe::
            end
        end
    end
    targetCounter = 0
    for k, group in ipairs(targetGroups) do
        setOutputToVector(1+targetCounter*3, avgVecList(group))
        outputBools[1+targetCounter*3] = true
        targetCounter = targetCounter + 1
    end
    setOutputToVector(25, vehiclePosition)
    outputBools[2] = click and screenClickPos.x > 45 and screenClickPos.x < w-45
    outputBools[3] = autoAim
    outputBools[5] = autoFire
    outputBools[6] = manualFire
    outputBools[8] = autoTarget
    outputNumbers[29] = killZone
    outputNumbers[30] = worldClickPos.x
    outputNumbers[31] = worldClickPos.y
    outputNumbers[32] = zoom
    setOutputs()
end
function onDraw()

    screen.setMapColorGrass(75, 75, 75)
	screen.setMapColorLand(50, 50, 50)
	screen.setMapColorOcean(25, 25, 75)
	screen.setMapColorSand(100, 100, 100)
	screen.setMapColorSnow(100, 100, 100)
	screen.setMapColorShallows(50, 50, 100)

	screen.drawMap(vehiclePosition.x, vehiclePosition.y, zoom)
    if click and screenClickPos.x > 45 and screenClickPos.x < w-45 then
        worldClickPos.z = vehiclePosition.z
        worldClickPos.x, worldClickPos.y = map.screenToMap(vehiclePosition.x, vehiclePosition.y, zoom, w, h, screenClickPos.x, screenClickPos.y)
    end

	screen.setColor(255,0,0,50)
    screen.drawCircle(w/2,h/2,toScreen(wepRange))
    screen.drawCircleF(w/2,h/2,toScreen(killZone))
    screen.setColor(0, 255, 0, 50)
    screen.drawCircle(w/2,h/2,toScreen(maxDist))

    for z, zone in ipairs(safeZones) do
        local safeX, safeY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, zone.x, zone.y)
        screen.drawCircleF(safeX, safeY, toScreen(zone.w))
    end

    if addingZone then
        if wasAddingZone then
            safeZones[#safeZones].w = safeZones[#safeZones]:distanceTo(worldClickPos)
        else
            table.insert(safeZones, newRotatableVector(worldClickPos:get()))
        end
    end
    wasAddingZone = addingZone
    if removingZone then
        if not wasRemovingZone then
            local nearestZone, nearestDist = nil, math.huge
            for z, zone in ipairs(safeZones) do
                local zoneDist = zone:distanceTo(worldClickPos)
                if zoneDist < nearestDist then
                    nearestDist = zoneDist
                    nearestZone = z
                end
            end
            if nearestZone then
                table.remove(safeZones, nearestZone)
            end
        end
    end
    wasRemovingZone = removingZone
    zoom = upDown(zoomOut, zoomIn, zoom, zSpeed, 0.05, 50)
    killZone = upDown(autoOut, autoIn, killZone, killSpeed, minDist, wepRange)
    maxDist = upDown(radarOut, radarIn, maxDist, distSpeed, minDist, 3000)
    if clearZones then
        safeZones = {}
    end
end
function upDown(up, down, upDownValue, upDownSpeed, min, max)
    return math.min(math.max((down and (upDownValue - upDownSpeed)) or (up and (upDownValue + upDownSpeed)) or upDownValue, min), max)
end
function toScreen(n)
    return n*(w/(zoom*1000))
end
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
require("Clamp")
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
gpsCorrection = property.getNumber('GPS Correction')
spinTime = property.getNumber('Spin Time')
maxAge = property.getNumber('Max Age')
spinCounter = 0
spin = 0
vehiclePosition = newRotatableVector()
previousVehiclePosition = newRotatableVector()
vehiclePositionVelocity = newRotatableVector()
vehicleRotation = newRotatableVector()
screenClickPos = newRotatableVector()
worldClickPos = newRotatableVector()
click = false
PI = math.pi
PI2 = PI*2
fov = property.getNumber('FOV')*PI
zoom = 3
zSpeed = 0.03
killZone = 800
killSpeed = 2
distSpeed = 3
h = 160
w = 288
safeZones = {}
targets = {}
wasAddingZone = false
wasRemovingZone = false
facing = 0
targets = {}
function onTick()
    clearOutputs()
    spinCounter = (spinCounter + 1)%spinTime
    spin = (spinCounter/spinTime) - 0.5
    targetGroups = {}

    massNumber = input.getNumber(31)*100000000 + input.getNumber(32)

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

    vehiclePosition:set(getInputVector(1))
    vehiclePositionVelocity:setSubtract(vehiclePosition, previousVehiclePosition)
    vehiclePositionVelocity:setScale(gpsCorrection)
    previousVehiclePosition:copy(vehiclePosition)
    vehiclePosition:setAdd(vehiclePosition, vehiclePositionVelocity)

    vehicleRotation:set(getInputVector(4))
    vehicleRotation:setScale(PI2)
    radarYaw = facing - vehicleRotation.z

    for i = 0, 7, 1 do
        local targetPosition = newRotatableVector(getInputVector(i*3+7))
        local targetMass = getMass(i+1)
        targetPosition:rotate3D(vehicleRotation)
        targetPosition:setAdd(targetPosition, vehiclePosition)
        for z, zone in ipairs(safeZones) do
            if targetPosition:distanceTo(zone) < zone.w then
                goto safe
            end
        end
        local targetDistance = targetPosition:distanceTo(vehiclePosition)
        if targetDistance < maxDist and targetDistance > minDist then
            for targetIndex, target in ipairs(targets) do
                if targetMass == target.mass and target.position:distanceTo(targetPosition) < groupDist then
                    targets[targetIndex].velocity:setSubtract(targetPosition, target.position)
                    targets[targetIndex].velocity:setScale(1/target.age)
                    targets[targetIndex].position:copy(targetPosition)
                    targets[targetIndex].predictedPosition:copy(targetPosition)
                    targets[targetIndex].mass = targetMass
                    targets[targetIndex].age = 0
                    targets[targetIndex].distance = targetDistance
                    goto safe
                end
            end
            table.insert(targets, {
                mass = targetMass,
                age = 0,
                distance = targetDistance,
                position = targetPosition:clone(),
                predictedPosition = targetPosition:clone(),
                velocity = newRotatableVector()
            })
        end
        ::safe::
    end
    massNumber = 0
    for targetIndex = #targets, 1, -1 do
        targets[targetIndex].age = targets[targetIndex].age + 1
        targets[targetIndex].predictedPosition:setAdd(targets[targetIndex].predictedPosition, targets[targetIndex].velocity)
        if targets[targetIndex].age > maxAge then
            table.remove(targets, targetIndex)
        end
    end
    table.sort(targets, function (a, b)
        return a.distance - a.mass*20 < b.distance - b.mass*20
    end)
    for targetIndex, target in ipairs(targets) do
        if targetIndex < 8 then
            setOutputToVector((targetIndex-1)*3+9, target.predictedPosition)
        end
    end
    setOutputToVector(25, vehiclePosition)
    outputNumbers[30] = math.floor(massNumber/100000000)
    outputNumbers[31] = massNumber%100000000
    outputBools[2] = click and screenClickPos.x > 45 and screenClickPos.x < w-45
    outputBools[3] = autoAim
    outputBools[5] = autoFire
    outputBools[6] = manualFire
    outputBools[8] = autoTarget
    outputNumbers[29] = killZone
    --outputNumbers[30] = worldClickPos.x
    --outputNumbers[31] = worldClickPos.y
    outputNumbers[32] = zoom
    setOutputs()
    facing = spin * PI2
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
    screen.setColor(0, 255, 0, 35)
    screen.drawTriangleF(w/2, h/2, w/2 + w*math.sin(radarYaw+fov), h/2 - w*math.cos(radarYaw+fov), w/2 + w*math.sin(radarYaw-fov), h/2 - w*math.cos(radarYaw-fov))
    for targetIndex, target in ipairs(targets) do
        local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, target.predictedPosition.x, target.predictedPosition.y)
		screen.setColor(0, 255, 0)
        screen.drawText(clamp(positionScreenX, 51, w-50), clamp(positionScreenY, 5, h-4), target.mass)
    end
    screen.drawTextBox(1, h-12, w, 11, string.format('Targets:\n%.0f',#targets), -1, -1)
end
function upDown(up, down, upDownValue, upDownSpeed, min, max)
    return math.min(math.max((down and (upDownValue - upDownSpeed)) or (up and (upDownValue + upDownSpeed)) or upDownValue, min), max)
end
function toScreen(n)
    return n*(w/(zoom*1000))
end
function getMass(index)
    return math.floor(massNumber/(100^(8-index)))%100
end
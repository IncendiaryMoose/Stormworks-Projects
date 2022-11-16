---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Speed', 8)
simulator:setProperty('GPS Delay', 1)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Max Age', 100)
simulator:setProperty('Delay', 1)
simulator:setProperty('Sample', 5)
simulator:setProperty('Accel', 1)
simulator:setProperty('Jerk', 1)
simulator:setProperty('Max Prediction', 800)

testTargs = {
    50,
    150,
    250,
    350,
    450,
    550,
    650,
    750
}
onLBSimulatorTick = function(simulator, ticks)
    simulator:setInputNumber(1, 0)
    simulator:setInputNumber(2, 0)
    simulator:setInputNumber(3, 0)
    simulator:setInputNumber(4, 0)
    simulator:setInputNumber(5, 0)
    simulator:setInputNumber(6, 0.125)
    tickMod = ticks%10
    for ti = 0, 7 do
        simulator:setInputNumber(ti*3+7, 100 + ti*100 + tickMod*800 + ticks)
        simulator:setInputNumber(ti*3+8, 100 + ti*100 + tickMod*800)
        simulator:setInputNumber(ti*3+9, 100 + ti*100 + tickMod*800)
    end
    simulator:setInputNumber(31, 10101010)
    simulator:setInputNumber(32, 10101010)
end
---@endsection
require('Extended_Vector_Math')
require('In_Out')
require('Clamp')
function getBinaryInput(startChannel, endChannel)
    local result = 0
    for i = 0, endChannel-startChannel, 1 do
        result = input.getBool(i+startChannel) and result + 2^(i) or result
    end
    return result
end
gpsDelay = property.getNumber('GPS Delay')
maxAge = property.getNumber('Max Age')

vehiclePosition = newVector()
previousVehiclePosition = newVector()

vehicleRotation = newVector()
previousVehicleRotation = newVector()

screenClickPos = newVector()
worldClickPos = newVector()
PI = math.pi
PI2 = PI*2
zoom = 5
zSpeed = 0.03
range = 500
rangeSpeed = 5
h = 160
w = 288
safeZones = {}
wasAddingZone = false
wasRemovingZone = false
targets = {}
function onTick()
    clearOutputs()

	screenClickPos:set(getBinaryInput(1, 8), getBinaryInput(9, 16))
    click = input.getBool(17)

    zoomIn = input.getBool(18)
    zoomOut = input.getBool(19)
    zoom = upDown(zoomOut, zoomIn, zoom, zSpeed, 0.1, 50)

    addingZone = input.getBool(20)
    removingZone = input.getBool(21)
    clearZones = input.getBool(22)

    rangeIn = input.getBool(23)
    rangeOut = input.getBool(24)
    range = upDown(rangeIn, rangeOut, range, rangeSpeed, 5, 2000)

    autoFire = input.getBool(25)

    trackCivilian = input.getBool(26)
    trackUnknown = input.getBool(27)
    trackMilitary = input.getBool(28)

    attackCivilian = input.getBool(29)
    attackUnknown = input.getBool(30)
    attackMilitary = input.getBool(31)

    manualFire = input.getBool(32)


    massNumber = input.getNumber(31)*100000000 + input.getNumber(32)

    vehiclePosition:set(getInputVector(1))

    vehicleRotation:set(getInputVector(4))
    vehicleRotation:setScale(PI2)

    for i = 0, 7 do
        local targetPosition, targetMass = newVector(getInputVector(i*3+7)), math.floor(massNumber/(100^(7-i)))%100
        if targetPosition:exists() then
            if (trackCivilian or targetMass ~= 0) and (trackUnknown or not inRange(targetMass, 1, 8)) and (trackMilitary or not inRange(targetMass, 9, 16)) then
                targetPosition:rotate3D(previousVehicleRotation)
                targetPosition:setAdd(previousVehiclePosition)
                for z, zone in ipairs(safeZones) do
                    if targetPosition:distanceTo(zone) < zone.w then
                        goto safe
                    end
                end
                setOutputToVector(i*3 + 7, targetPosition)
            end
        end
        ::safe::
    end

    previousVehiclePosition:copy(vehiclePosition)
    previousVehicleRotation:copy(vehicleRotation)

    outputNumbers[1] = zoom
    outputNumbers[2] = range

    setOutputs()
end
function onDraw()

	if click and screenClickPos.x > 45 and screenClickPos.x < w-45 then
        worldClickPos.z = vehiclePosition.z
        worldClickPos.x, worldClickPos.y = map.screenToMap(vehiclePosition.x, vehiclePosition.y, zoom, w, h, screenClickPos.x, screenClickPos.y)
    end

    screen.setColor(0, 255, 0, 50)
    for z, zone in ipairs(safeZones) do
        local safeX, safeY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, zone.x, zone.y)
        screen.drawCircleF(safeX, safeY, zone.w*(w/(zoom*1000)))
    end

    if addingZone then
        if wasAddingZone then
            safeZones[#safeZones].w = safeZones[#safeZones]:distanceTo(worldClickPos)
        else
            table.insert(safeZones, worldClickPos:clone())
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
    if clearZones then
        safeZones = {}
    end
end
function upDown(up, down, upDownValue, upDownSpeed, min, max)
    return math.min(math.max(down and (upDownValue - upDownSpeed) or up and (upDownValue + upDownSpeed) or upDownValue, min), max)
end
function setOutputToTarget(startChannel, outputTarget)
    if outputTarget then
        setOutputToVector(startChannel, outputTarget.position.predicted)
        outputBools[startChannel] = manualFire or (autoFire and outputTarget.distance < killZone)
    end
end
function inRange(a, b, c)
	return (a >= b and a <= c)
end
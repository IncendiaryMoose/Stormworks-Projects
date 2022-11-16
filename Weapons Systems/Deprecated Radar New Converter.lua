---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Minimum Distance', 60)
simulator:setProperty('Maximum Distance', 3000)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Autoshoot Distance', 800)
onLBSimulatorTick = function(simulator, ticks)

end
---@endsection
require('Advanced_Target_Fast_Decay')
require('In_Out')
require('Clamp')
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
maxAge = property.getNumber('Max Age')
vehiclePosition = newExtendedVector()
previousVehiclePosition = newExtendedVector()
vehiclePositionVelocity = newExtendedVector()
vehicleRotation = newExtendedVector()
click = false
PI = math.pi
PI2 = PI*2
zoom = 5
zSpeed = 0.03
h = 160
w = 288
targets = {}
function onTick()
    clearOutputs()

    massNumber = input.getNumber(31)*100000000 + input.getNumber(32)

    vehiclePosition:set(getInputVector(1))
    vehiclePositionVelocity:setSubtract(vehiclePosition, previousVehiclePosition)
    vehiclePositionVelocity:setScale(gpsCorrection)
    previousVehiclePosition:copy(vehiclePosition)
    vehiclePosition:setAdd(vehiclePosition, vehiclePositionVelocity)

    vehicleRotation:set(getInputVector(4))
    vehicleRotation:setScale(PI2)

    for i = 0, 7 do
        local targetPosition = newExtendedVector(getInputVector(i*3+7))
        local targetMass = getMass(i+1)
        if targetPosition:exists() and targetMass > 0 then
            targetPosition:rotate3D(vehicleRotation)
            targetPosition:setAdd(targetPosition, vehiclePosition)
            for targetIndex, target in ipairs(targets) do
                if targetMass == target.mass and target.position.predicted:distanceTo(targetPosition) < groupDist then
                    targets[targetIndex]:refresh(targetPosition)
                    goto safe
                end
            end
            table.insert(targets, newTarget(targetPosition, targetMass, 1))
        end
        ::safe::
    end
    for targetIndex = #targets, 1, -1 do
        targets[targetIndex]:update(vehiclePosition)
        if targets[targetIndex].updateAge > maxAge then
            table.remove(targets, targetIndex)
        end
    end
    table.sort(targets, function (a, b)
        return a.distance - a.mass*1000 < b.distance - b.mass*1000
    end)
    for targetIndex, target in ipairs(targets) do
        if targetIndex < 8 then
            setOutputToVector((targetIndex-1)*3+9, target.position.predicted)
        end
    end
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

    for targetIndex, target in ipairs(targets) do
        local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, target.position.predicted.x, target.position.predicted.y)
        screen.drawText(clamp(positionScreenX, 5, w-5), clamp(positionScreenY, 5, h-5), target.mass)
    end
    screen.drawTextBox(1, h-12, w, 11, string.format('Targets:\n%.0f',#targets), -1, -1)
end
function getMass(index)
    return math.floor(massNumber/(100^(8-index)))%100
end
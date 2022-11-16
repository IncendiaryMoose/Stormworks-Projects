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
newVector = function (x, y, z, w)
return {
    x = x or 0,
    y = y or 0,
    z = z or 0,
    w = w or 0,
    set = function (self, a, b, c, d)
        self.x = a
        self.y = b
        self.z = c
    end,
    setAdd = function (self, other)
        self:set(self.x + other.x, self.y + other.y, self.z + other.z)
    end,
    setScaledAdd = function (self, other, scalar)
        self:set(self.x + other.x * scalar, self.y + other.y * scalar, self.z + other.z * scalar)
    end,
    setSubtract = function (self, other)
        self:set(self.x - other.x, self.y - other.y, self.z - other.z)
    end,
    setScale = function (self, scalar)
        self:set(self.x * scalar, self.y * scalar, self.z * scalar)
    end,
    distanceTo = function (self, other)
        return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
    end,
    rotate3D = function (self, rotation, transposed)
        local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
        self:set(
            self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
            self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
            self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
        )
    end,
    clone = function (self)
        return newVector(self.x, self.y, self.z)
    end,
    copy = function (self, other)
        self:set(other.x, other.y, other.z)
    end,
    exists = function (self)
        return self.x ~= 0 or self.y ~= 0 or self.z ~= 0
    end
}
end
require('Advanced_Target_Fast_Decay')
require('In_Out')
require('Clamp')
function getBinaryInput(startChannel, endChannel)
    local result = 0
    for i = 0, endChannel-startChannel, 1 do
        result = input.getBool(i+startChannel) and result + 2^(i) or result
    end
    return result
end
groupDist = property.getNumber('Speed')
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
killZone = 255
killSpeed = 5
h = 160
w = 288
safeZones = {}
wasAddingZone = false
wasRemovingZone = false
targets = {}
function onTick()
    clearOutputs()

    click = input.getBool(19)
    clearZones = input.getBool(30)
    removingZone = input.getBool(31)
    addingZone = input.getBool(32)
    zoom = upDown(input.getBool(21), input.getBool(20), zoom, zSpeed, 0.1, 50)
    killZone = upDown(input.getBool(25), input.getBool(24), killZone, killSpeed, 5, 2000)

    autoFire = input.getBool(26)
    manualFire = input.getBool(27)

	screenClickPos:set(getBinaryInput(1, 9), getBinaryInput(10, 18))

    massNumber = input.getNumber(31)*100000000 + input.getNumber(32)

    vehiclePosition:set(getInputVector(1))

    vehicleRotation:set(getInputVector(4))
    vehicleRotation:setScale(PI2)

    for i = 0, 7 do
        local targetPosition, targetMass = newVector(getInputVector(i*3+7)), math.floor(massNumber/(100^(7-i)))%100
        if targetPosition:exists() then
            targetPosition:rotate3D(previousVehicleRotation)
            targetPosition:setAdd(previousVehiclePosition)
            for z, zone in ipairs(safeZones) do
                if targetPosition:distanceTo(zone) < zone.w then
                    goto safe
                end
            end
            for targetIndex, target in pairs(targets) do
                if target.position.predicted:distanceTo(targetPosition) < groupDist*(target.updateAge+1) and targetMass <= target.mass then
                    if targetMass == target.mass then
                        target:refresh(targetPosition)
                    end
                    goto safe
                end
            end
            targets[targetPosition.x] = newTarget(targetPosition, targetMass)
        end
        ::safe::
    end

    previousVehiclePosition:copy(vehiclePosition)
    previousVehicleRotation:copy(vehicleRotation)

    for targetIndex, target in pairs(targets) do
        if target.updateAge > maxAge then
            targets[targetIndex] = nil
            goto targetRemoved
        end
        target:update(vehiclePosition)
        heavyTarget = (not targets[heavyTarget] or target.distance - target.mass*500 < targets[heavyTarget].distance - targets[heavyTarget].mass*500 - 500) and targetIndex or heavyTarget
        --lightTarget = (not targets[lightTarget] or target.distance + target.mass*255 < targets[lightTarget].distance + targets[lightTarget].mass*255 - 500) and targetIndex or lightTarget
        --belowTarget = (target.elevationAngle < 0.001 and (not targets[belowTarget] or target.distance - target.mass*255 < targets[belowTarget].distance - targets[belowTarget].mass*255 - 500)) and targetIndex or belowTarget
        --aboveTarget = (target.elevationAngle > -0.001 and (not targets[aboveTarget] or target.distance - target.mass*255 < targets[aboveTarget].distance - targets[aboveTarget].mass*255 - 500)) and targetIndex or aboveTarget
        userTarget = (click and (not targets[userTarget] or target.position.predicted:distanceTo(worldClickPos) < targets[userTarget].position.predicted:distanceTo(worldClickPos))) and targetIndex or userTarget
        ::targetRemoved::
    end
    setOutputToTarget(9, targets[heavyTarget])
    --setOutputToTarget(12, targets[lightTarget])
    --setOutputToTarget(15, targets[aboveTarget])
    --setOutputToTarget(18, targets[belowTarget])
    setOutputToTarget(21, targets[userTarget])
    setOutputToVector(1, vehiclePosition)
    setOutputToVector(4, vehicleRotation)
    outputNumbers[7] = zoom
    outputNumbers[8] = killZone

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

    for targetIndex, target in pairs(targets) do
        local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, target.position.predicted.x, target.position.predicted.y)
        if targetIndex == userTarget then
            screen.setColor(255, 255, 255)
        elseif target.mass == 0 then
            screen.setColor(0, 255, 0)
        elseif target.mass < 9 then
            screen.setColor(255, 255, 0)
        else
            screen.setColor(255, 0, 0)
        end
        screen.drawText(positionScreenX, positionScreenY, (target.mass - 1)%8 + 1)
    end
    --screen.drawTextBox(1, h-12, w, 11, string.format('Targets:\n%.0f', targetCount), -1, -1)
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
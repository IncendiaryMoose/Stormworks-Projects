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
simulator:setProperty('M1', '478,731,824,1184,1309,1416,1418,1452,1482,2167,2721,2827,3125,3296,3822,3834,3863,4279,7264,10080,10218,17716,21200,42512,80240')
simulator:setProperty('M2', '229,941,1252,2174,2372,200,111,59,2426,61,5071,48728,1218,211,343,74,75,2712,8430,169,3157,9582,1721,274,284,240,1315,1316,276,278,46744')
--59,61,74,75,111,163,169,200,211,229,240,274,276,278,284,343,941,1218,1252,1315,1316,1721,2174,2372,2426,2712,3157,5071,7496,8430,9582,46744,48728
--163,169,200,211,229,240,274,276,278,284,343,941,1218,1252,1315,1316,1721,2174,2372,2426,2712,3157,5071,7496,8430,9582,46744,48728

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
--480=0,728=0,824=0,1424=0,1456=0,1488=0,3136=0,3840=0,3872=0,4288=0,7296=0,10240=0,17664=0,21248=0,
--4249=0,230=2,944=2,1248=2,2176=2,2368=2,200=2,111=2,59=2,2432=2,61=2,5056=2,48640=2,1216=2
--480=0,728=0,824=0,1424=0,1456=0,1488=0,3136=0,3840=0,3872=0,4288=0,7296=0,10240=0,17664=0,21248=0,1312=0,10112=0,9600=2
--4249=0,230=2,944=2,1248=2,2176=2,2368=2,200=2,111=2,59=2,2432=2,61=2,5056=2,48640=2,1216=2,1024=2,1040=2,2720=2,3168=2

--42512
floor = math.floor
log = math.log
abs = math.abs

function max(a, b)
    return a > b and a or b
end

function joinTables(tableA, tableB, startIndex, endIndex)
    for index = startIndex, endIndex do
        tableA[#tableA+1] = tableB[index]
    end
end

function binaryToFloat(binaryTable, exponentBits, mantissaBits, bias, startBit, unsigned)
    local exponent, sign, bitCount, mantissa = 0, unsigned and 1 or binaryTable[startBit] and -1 or 1, unsigned and 0 or 1

    for bitIndex = 1, exponentBits do
        exponent = binaryTable[startBit + bitCount] and exponent + 2 ^ (exponentBits - bitIndex) or exponent
        bitCount = bitCount + 1
    end

    mantissa = exponent > 0 and 1 or 0
    for bitIndex = 1, mantissaBits - 1 do
        mantissa = binaryTable[startBit + bitCount] and mantissa + 1 / 2 ^ bitIndex or mantissa
        bitCount = bitCount + 1
    end

    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    return mantissa * 2 ^ max(exponent - bias, -bias + 1) * sign
end

function inputToBinary(float)
    local numBits = {float < 0}
    float = abs(float) -- Sign is no longer needed, and would cause problems

    local exponent, mantissa, factor = floor(log(float, 2)) -- Determine what exponent is needed, and how much to offset it (based on the bits allocated to it)

    mantissa = (float / 2 ^ max(exponent, -126))%1 -- Also known as the significand

    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    exponent = max(exponent + 127, 0)
    for bitIndex = 8, 1, -1 do
        numBits[1 + bitIndex] = exponent%2 == 1
        exponent = exponent // 2
    end

    for bitIndex = 1, 23 do
        factor = 1 / 2 ^ bitIndex
        numBits[#numBits + 1] = mantissa >= factor
        mantissa = mantissa%factor
    end
    return numBits
end

newVector = function (x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        set = function (self, a, b, c)
            self.x = a
            self.y = b
            self.z = c
        end,
        setScaledAdd = function (self, other, scalar)
            self:set(self.x + other.x * scalar, self.y + other.y * scalar, self.z + other.z * scalar)
        end,
        setScale = function (self, scalar)
            self:set(self.x * scalar, self.y * scalar, self.z * scalar)
        end,
        distanceTo = function (self, other)
            return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
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

tickCorrection = property.getNumber('Delay')
sampleAge = property.getNumber('Sample')
accelerationDecay = 1 - property.getNumber('Accel')
jerkDecay = 1 - property.getNumber('Jerk')
maxPrediction = property.getNumber('Max Ref')

function newVectorList(initial)
    return {
        memory = {
            {value = initial:clone(), timeStamp = 0}
        },
        differenceFrom = function (self, fromValue)
            local memCount, difference, toValue = #self.memory, newVector()
            fromValue = self.memory[memCount - fromValue]
            toValue = self.memory[memCount]
            if fromValue and toValue and fromValue.value:exists() then
                difference:copy(toValue.value)
                difference:setScaledAdd(fromValue.value, -1)
                difference:setScale(1/(toValue.timeStamp - fromValue.timeStamp))
            end
            return difference:clone()
        end,
        newValue = function (self, value, timeStamp)
            self.current:copy(value)
            self.predicted:copy(value)
            table.insert(self.memory, {value = value:clone(), timeStamp = timeStamp})
            if #self.memory > sampleAge + 1 then
                table.remove(self.memory, 1)
            end
        end,
        current = initial:clone(),
        predicted = initial:clone()
    }
end

function newTarget(position, mass, class)
    return {
        mass = mass,
        class = class,
        totalAge = 0,
        updateAge = 0,
        distance = 1,
        position = newVectorList(position),
        velocity = newVectorList(newVector()),
        acceleration = newVectorList(newVector()),
        jerk = newVectorList(newVector()),
        update = function (self, referencePosition)
            self:positionInTicks(math.min(self.updateAge, maxPrediction))
            self.distance = self.position.predicted:distanceTo(referencePosition)
            self.elevationAngle = math.asin((self.position.predicted.z-referencePosition.z)/self.distance)
            self.totalAge = self.totalAge + 1
            self.updateAge = self.updateAge + 1
        end,
        refresh = function (self, newPosition)
            self.position:newValue(newPosition, self.totalAge)
            self.velocity:newValue(self.position:differenceFrom(sampleAge), self.totalAge)
            self.acceleration:newValue(self.velocity:differenceFrom(sampleAge), self.totalAge)
            self.jerk:newValue(self.acceleration:differenceFrom(sampleAge), self.totalAge)
            self.updateAge = 0
        end,
        positionInTicks = function (self, ticks)
            ticks = ticks + tickCorrection

            self.jerk.predicted:copy(self.jerk.current)
            self.acceleration.predicted:copy(self.acceleration.current)
            self.velocity.predicted:copy(self.velocity.current)
            self.position.predicted:copy(self.position.current)

            --self.acceleration.predicted:setScaledAdd(self.jerk.current, 0.5)
            --self.velocity.predicted:setScaledAdd(self.acceleration.predicted, 0.5)

            self.position.predicted:setScaledAdd(self.velocity.predicted, ticks)
            self.position.predicted:setScaledAdd(self.acceleration.predicted, ticks^2/(2*(ticks*accelerationDecay + 1)))
            self.position.predicted:setScaledAdd(self.jerk.predicted, ticks^3/(6*(ticks*jerkDecay + 1)))
        end
    }
end

outputNumbers = {}
outputBools = {}
function clearOutputs()
    for i = 1, 32 do
        outputNumbers[i] = 0
        outputBools[i] = false
    end
end
function setOutputs()
    for i = 1, 32 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end
function setOutputToVector(startChannel, vector)
	outputNumbers[startChannel] = vector.x
    outputNumbers[startChannel + 1] = vector.y
    outputNumbers[startChannel + 2] = vector.z
end
function getInputVector(startChannel)
	return input.getNumber(startChannel), input.getNumber(startChannel + 1), input.getNumber(startChannel + 2)
end

function min(a, b)
    return a < b and a or b
end

groupDist = property.getNumber('Speed')
maxAge = property.getNumber('Max Age')

vehiclePosition = newVector()
previousVehiclePosition = newVector()

vehicleRotation = newVector()
previousVehicleRotation = newVector()

screenClickPos = newVector()
worldClickPos = newVector()

PI = math.pi
PI2 = PI*2
h = 160
w = 288

targets = {}
classes = {}

function applyMassSettings(settingString, classValue)
    for massValue in string.gmatch(settingString, "(%d+)") do
        classes[tonumber(massValue)] = tonumber(classValue)
    end
end

applyMassSettings(property.getText('M1'), 0)
applyMassSettings(property.getText('M2'), 2)

track = {}
attack = {}
function onTick()
    clearOutputs()
    clickData = input.getNumber(8)
    screenClickPos:set(clickData%1000, floor((clickData%1000000)/1000), 0)
    worldClick = clickData >= 1000000 and screenClickPos.x > 45 and screenClickPos.x < w-45

    vehiclePosition:set(getInputVector(1))

    vehicleRotation:set(getInputVector(4))

    controlBits = inputToBinary(input.getNumber(7))

    zoom = binaryToFloat(controlBits, 3, 5, 3, 1) + 25
    range = binaryToFloat(controlBits, 3, 5, 3, 9) * 2000 + 500
    for i = 0, 2 do
        track[i] = controlBits[i + 19]
        attack[i] = controlBits[i + 22]
    end

    for i = 0, 7 do
        local massBits, poses = {}, {}
        for j = 9, 11 do
            local numBits = inputToBinary(input.getNumber(j + i*3))
            poses[#poses+1] = binaryToFloat(numBits, 4, 24, 0, 1)
            joinTables(massBits, numBits, 29, 32)
        end

        for j = 1, 4 do
            massBits[#massBits+1] = input.getBool(j + i*4)
        end

        local targetPosition, targetMass, class = newVector(poses[1], poses[2], poses[3]), binaryToFloat(massBits, 4, 13, -4, 1, 1)
        class = classes[targetMass] or 1
        if track[class] then
            if targetPosition:exists() then
                local sx, sy, sz, cx, cy, cz = math.sin(vehicleRotation.x), math.sin(vehicleRotation.y), math.sin(vehicleRotation.z), math.cos(vehicleRotation.x), math.cos(vehicleRotation.y), math.cos(vehicleRotation.z)
                targetPosition:set(
                    targetPosition.x*(cz*cy-sz*sx*sy) + targetPosition.y*(-sz*cx) + targetPosition.z*(cz*sy+sz*sx*cy),
                    targetPosition.x*(sz*cy+cz*sx*sy) + targetPosition.y*(cz*cx) + targetPosition.z*(sz*sy-cz*sx*cy),
                    targetPosition.x*(-cx*sy) + targetPosition.y*(sx) + targetPosition.z*(cx*cy)
                )
                targetPosition:setScaledAdd(vehiclePosition, 1)
                for targetIndex, target in pairs(targets) do
                    if target.position.predicted:distanceTo(targetPosition) < groupDist*(target.updateAge + 1) and targetMass <= target.mass then
                        if targetMass == target.mass then
                            target:refresh(targetPosition)
                        end
                        goto safe
                    end
                end
                targets[targetPosition.x + targetMass] = newTarget(targetPosition, targetMass, class)
            end
        end
        ::safe::
    end

    --previousVehiclePosition:copy(vehiclePosition)
    --previousVehicleRotation:copy(vehicleRotation)

    for targetIndex, target in pairs(targets) do
        if target.updateAge > maxAge then
            targets[targetIndex] = nil
            goto targetRemoved
        end
        target:update(vehiclePosition)
        heavyTarget = (not targets[heavyTarget] or target.distance - target.mass/10 < targets[heavyTarget].distance - targets[heavyTarget].mass/10 - 500) and attack[target.class] and targetIndex or heavyTarget
        userTarget = (worldClick and (not targets[userTarget] or target.position.predicted:distanceTo(worldClickPos) - target.mass/100 < targets[userTarget].position.predicted:distanceTo(worldClickPos) - targets[userTarget].mass/100)) and attack[target.class] and targetIndex or userTarget
        ::targetRemoved::
    end
    --outputBools[1] = controlBits[17]
    setOutputToTarget(9, targets[heavyTarget])
    setOutputToTarget(21, targets[userTarget])-- or targets[heavyTarget])
    --setOutputToVector(1, vehiclePosition)
    setOutputToVector(4, vehicleRotation)

    setOutputs()
end
function onDraw()

    worldClickPos.z = vehiclePosition.z
    worldClickPos.x, worldClickPos.y = map.screenToMap(vehiclePosition.x, vehiclePosition.y, zoom, w, h, screenClickPos.x, screenClickPos.y)

    for targetIndex, target in pairs(targets) do
        local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, target.position.predicted.x, target.position.predicted.y)
        screen.setColor((target.class > 0 or targetIndex == userTarget) and 255 or 0, (target.class < 2 or targetIndex == userTarget) and 255 or 0, targetIndex == userTarget and 255 or 0)
        if controlBits[25] then
            screen.drawText(positionScreenX, positionScreenY, string.format('%.0f', target.mass))
        else
            screen.drawCircleF(positionScreenX, positionScreenY, max(min(target.mass/10000, 10), 2.5))
        end
    end
    --screen.drawTextBox(1, h-12, w, 11, string.format('Targets:\n%.0f', targetCount), -1, -1)
end

function setOutputToTarget(startChannel, outputTarget)
    if outputTarget then
        setOutputToVector(startChannel, outputTarget.position.predicted)
        outputBools[startChannel] = attack[outputTarget.class] and (controlBits[26] or (controlBits[18] and outputTarget.distance < range))
    end
end
require("PID")
require("In_Out")
altitude_pids = {}
for i = 1, 3, 1 do
    altitude_pids[i] = CreateNewVelocityPID(property.getNumber('Alt-P'),property.getNumber('Alt-I'),property.getNumber('Alt-D'),property.getNumber('Alt-I-Max'),property.getNumber('Alt-D-Max'),property.getNumber('Alt-Max'))
end
altitude_pids[1].power_offset = 0.2
altitude_pids[2].power_offset = 0.2
altitude_pids[3].power_offset = 0.2
xHoldPID = CreateNewPID(property.getNumber('X-P'),property.getNumber('X-I'),property.getNumber('X-D'),property.getNumber('P-I-Max'),property.getNumber('P-D-Max'),1)
yHoldPID = CreateNewPID(property.getNumber('Y-P'),property.getNumber('Y-I'),property.getNumber('Y-D'),property.getNumber('P-I-Max'),property.getNumber('P-D-Max'),1)
headingPID = CreateNewPID(property.getNumber('H-P'),property.getNumber('H-I'),property.getNumber('H-D'),property.getNumber('H-I-Max'),property.getNumber('H-D-Max'),1)

seat = {AD = 0, WS = 0, LR = 0, UD = 0}

gps = {x = 0, y = 0, z = 0, az = 0}

velocity = {x = 0, y = 0, z = 0, spin = 0}

rotation = {pitch = 0, roll = 0, yaw = 0, heading = 0}

target = {x = 0, y = 0, z = 0, heading = 0}

gpsError = {x = 0, y = 0, z = 0}

correctedX = 0
correctedY = 0
driveThrottle = 0
strafeThrottle = 0

xThrottle = 0
yThrottle = 0

distance = 0
prevDistance = 0
distanceDeltas = {}
avgDistanceDelta = 0
timeToTarget = 0
direction = 0
yaw = 0
steering = 0
spinRate = 0
APHeading = 0
headingError = 0
targetHeading = 0
sensetivity = 20
PI2 = math.pi * 2
auto = false
On = false
moving = false
Startup = 0
numbers = {}
bools = {}
lockSpeed = 250
Lock = true
tilt = false
tiltWarn = property.getNumber('Tilt Warning')
EngineReadyRPS = property.getNumber('Engine Ready RPS')
EngineReadyTimer = 0
function onTick()
    clearOutputs()
    for i = 1, 32, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    On = bools[1]
    MainEngineRPS = numbers[19]
    BoostEngineRPS = numbers[20]
    if MainEngineRPS >= EngineReadyRPS then
        if EngineReadyTimer < 60 then
            EngineReadyTimer = EngineReadyTimer + 1
        end
    else
        EngineReadyTimer = 0
    end
    if EngineReadyTimer == 60 then
        outputBools[2] = true

        Combat = bools[2]

        seat.AD = numbers[1]
        seat.WS = numbers[2]
        seat.LR = numbers[3]
        seat.UD = numbers[4]

        gps.x = numbers[5]
        gps.y = numbers[6]
        gps.z = numbers[7]
        gps.az = (numbers[15] + numbers[16] + numbers[17])/3

        rotation.pitch = numbers[8] * PI2
        rotation.roll = math.atan(math.sin(numbers[9] * PI2), math.sin(numbers[11] * PI2))
        rotation.heading = numbers[10]
        rotation.yaw = rotation.heading * PI2

        tilt = math.abs(rotation.pitch) > tiltWarn or math.abs(rotation.roll) > tiltWarn

        velocity.x = numbers[12]
        velocity.y = numbers[13]
        velocity.spin = numbers[14]

        if Startup < 300 then
            if Startup < 10 then
                target.z = gps.az + 0.5
                target.heading = rotation.heading
                target.x = gps.x
                target.y = gps.y
            else
                target.z = target.z + 0.01
            end
            Startup = Startup + 1
            outputBools[3] = true
        end

        if math.abs(velocity.x) < 2 and math.abs(velocity.y) < 2 then
            moving = false
            outputBools[30] = true
        end
        if not (math.abs(seat.WS) < 0.1 and math.abs(seat.LR) < 0.1) then
            moving = true
            outputBools[29] = true
        end

        if math.abs(seat.UD) > 0.01 then
            target.z = target.z + (seat.UD/90*sensetivity)
            outputBools[28] = true
        end

        gpsError.x = target.x - gps.x
        gpsError.y = target.y - gps.y
        distance = len(gpsError.x, gpsError.y)
        direction = math.atan(gpsError.x, gpsError.y)
        APHeading = direction/PI2
        headingError = direction + rotation.yaw

        if moving then
            target.x = gps.x
            target.y = gps.y
            correctedX = seat.LR * sensetivity * 10
            correctedY = seat.WS * sensetivity * 500
        else
            correctedX = math.sin(headingError) * distance
            correctedY = math.cos(headingError) * distance
        end
        if auto then
            if math.abs(seat.WS) > 0.1 or math.abs(seat.LR) > 0.1 then
                auto = false
            end
            distanceDeltas = manage_list(distanceDeltas,prevDistance-distance,25)
            prevDistance = distance
            avgDistanceDelta = avg_list(distanceDeltas)
            timeToTarget = distance/avgDistanceDelta/60
            target.heading = -APHeading
        elseif math.abs(seat.AD) > 0.01 then
            target.heading = rotation.heading-(seat.AD/250*sensetivity)
            outputBools[27] = true
        end
        rollover = ((rotation.heading-target.heading+0.5)%1)-0.5
        headingPID:Update(rollover, velocity.spin)
        xHoldPID:Update(correctedX, velocity.x)
        yHoldPID:Update(correctedY, velocity.y)
        for i, pid in ipairs(altitude_pids) do
            if numbers[i+14] ~= 0 then
                pid:Update(clamp(target.z, gps.az-10, gps.az+10), numbers[i+14])
            end
        end
        Lock = not ((not Combat) and (velocity.y < lockSpeed))
        outputRotor(1, altitude_pids[1].output, yHoldPID.output, xHoldPID.output + headingPID.output, 1, 1, 1, 1)
        outputRotor(6, altitude_pids[2].output, yHoldPID.output, xHoldPID.output - headingPID.output, 1, 1, 0.75, 0.75)
        outputRotor(11, altitude_pids[3].output, yHoldPID.output, -xHoldPID.output + headingPID.output, 1, 1, 0.75, 0.75)
        outputNumbers[21] = altitude_pids[1].output*sign(velocity.y)/2
        outputNumbers[22] = altitude_pids[2].output*sign(velocity.y)/2
        outputNumbers[23] = altitude_pids[3].output*sign(velocity.y)/2
        outputNumbers[25] = yHoldPID.output
        outputNumbers[26] = xHoldPID.output
        outputNumbers[27] = headingPID.output*sign(velocity.y)/6
        outputBools[4] = Lock
        outputBools[5] = auto
        outputBools[6] = moving
        outputBools[7] = tilt
    else
        Startup = 0
        outputBools[31] = true
    end
    outputBools[1] = On
    setOutputs()
end

function outputRotor(startChannel, collective, p, r, pMax, rMax, r2Max, p2Max)
    outputNumbers[startChannel] = clamp(collective, -1, 1)
    if Lock then
        outputNumbers[startChannel + 1] = clamp(p*sign(collective), -pMax, pMax)
        outputNumbers[startChannel + 2] = clamp(r*sign(collective), -rMax, rMax)
        outputNumbers[startChannel + 3] = clamp(r*sign(collective), -r2Max, r2Max)
        outputNumbers[startChannel + 4] = clamp(p*sign(collective), -p2Max, p2Max)
    else
        outputNumbers[startChannel + 1] = clamp(p*sign(collective), -1, 1)
        outputNumbers[startChannel + 2] = clamp(r*sign(collective), -1, 1)
    end
end

function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
function map_value(value,currentMin,currentMax,newMin,newMax)
    local currentRange = currentMax - currentMin
    local newRange = newMax - newMin
    return (((value-currentMin)/currentRange)*newRange+newMin)
end
function remap_list(list,currentMin,currentMax,newMin,newMax)
    listout = {}
    for j, item in ipairs(list) do
        table.insert(listout,map_value(item,currentMin,currentMax,newMin,newMax))
    end
    return listout
end
function manage_list(self, item, maxItems)
	table.insert(self, item)
	if #self > maxItems then
		table.remove(self, 1)
	end
	return self
end
function getRange(list)
    currentMin = math.huge
    currentMax = -math.huge
    for j, item in ipairs(list) do
        if item < currentMin then
            currentMin = item
        end
        if item > currentMax then
            currentMax = item
        end
    end
    if math.abs(currentMin) > math.abs(currentMax) then
        currentMax = currentMin+math.abs(currentMin)*2
    else
        currentMin = currentMax-math.abs(currentMax)*2
    end
    return {currentMin - 0.1, currentMax + 0.1}
end
function len(a,b)
    return (a^2+b^2)^0.5
end
function avg_list(list)
	total = 0
	for i, j in ipairs(list) do
		total = total + j
	end
	return total/#list
end
function sign(n)
    return ((n >= 0 and 1) or (-1))
end
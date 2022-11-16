---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty('Startup Time', 15)
    simulator:setProperty('Engine Threshold', -1)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)

        -- NEW! button/slider options from the UI
        for k = 1, 10 do
            simulator:setInputBool(k, simulator:getIsToggled(k))
            simulator:setInputNumber(k, simulator:getSlider(k))
        end
    end;
end
---@endsection
require("PID")
outputNumbers = {}
outputBools = {}

function clearOutputs()
    for i = 1, 32, 1 do
        outputNumbers[i] = 0
        outputBools[i] = false
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
end

function setOutputs()
    for i = 1, 32, 1 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end

function max(a, b)
    return a > b and a or b
end

function min(a, b)
    return a < b and a or b
end

PI = math.pi
PI2 = math.pi * 2

boostRpsThreshold = property.getNumber('Min Boost')
inputThreshold = property.getNumber('Min Input')
tiltThreshold = property.getNumber('Tilt Warn')
engineRpsThreshold = property.getNumber('Min Engine')
movementThreshold = property.getNumber('Min Movement')
steeringThreshold = property.getNumber('Min Steering')
ySpeed = property.getNumber('VY')
xSpeed = property.getNumber('VX')
zSpeed = property.getNumber('VZ')
yawSpeed = property.getNumber('VYaw')
--verticalTolerance = property.getNumber('Vertical Tolerance')
liftFlapRange = property.getNumber('Lift Flap')
steeringFlapRange = property.getNumber('Yaw Flap')
yawRate = property.getNumber('Yaw Rate')
pitchScale = property.getNumber('Pitch Scale')
rollScale = property.getNumber('Roll Scale')
startAlt = property.getNumber('Start Alt Offset')
startAltRaise = property.getNumber('Start Alt Speed')
xRange = property.getNumber('XR')
yRange = property.getNumber('YR')
zRange = property.getNumber('ZR')
landingAlt = property.getNumber('Landing Alt')
startupTime = property.getNumber('Start Time')
combatReduction = property.getNumber('Combat Reduction')
safeAlt = property.getNumber('Safe Alt')
altPitchRange = property.getNumber('Alt Pitch Range')
altPitchScale = property.getNumber('Alt Pitch Scale')
zSpeedGain = property.getNumber('VZ Gain')
sensetivity = 1

maxVx = sensetivity * xSpeed
maxVy = sensetivity * ySpeed
maxVz = sensetivity * zSpeed

width = 12.75
length = 27.75

altitude_pids = {}
for i = 1, 3, 1 do
    altitude_pids[i] = CreateNewVelocityPID(property.getNumber('Alt-P'), property.getNumber('Alt-I'), property.getNumber('Alt-D'), property.getNumber('Alt-I-Max'), property.getNumber('Alt-D-Max'), property.getNumber('Alt-Max'))
end
altitude_pids[1].power_offset = 0.2
altitude_pids[2].power_offset = 0.2
altitude_pids[3].power_offset = 0.2

xHoldPID = CreateNewPID(property.getNumber('X-P'), property.getNumber('X-I'), property.getNumber('X-D'), property.getNumber('P-I-Max'), property.getNumber('P-D-Max'), xRange)
yHoldPID = CreateNewPID(property.getNumber('Y-P'), property.getNumber('Y-I'), property.getNumber('Y-D'), property.getNumber('P-I-Max'), property.getNumber('P-D-Max'), yRange)
headingPID = CreateNewPID(property.getNumber('H-P'), property.getNumber('H-I'), property.getNumber('H-D'), property.getNumber('H-I-Max'), property.getNumber('H-D-Max'), 1)

distance = 0

direction = 0
yaw = 0

headingError = 0

moving = false
steering = false
numbers = {}
bools = {}

engineReadyCapacitor = 0
startup = 0

gpsAZ = 0

atWaypointCapacitor = 0
headingCapacitor = 0
dockingStage = 0
function onTick()
    clearOutputs()

    engineEnabled = bools[1] or engineEnabled

    engineReadyCapacitor = (numbers[18] > engineRpsThreshold or (gpsAZ < safeAlt and bools[1])) and min(engineReadyCapacitor + 1, 60) or 0

    engineReady = engineReadyCapacitor == 60

    startup = engineReady and min(startup + 1, startupTime) or 0

    if engineReady then
        outputBools[3] = true

        seatWS = clamp((numbers[21] > 0.1 and numbers[21] or autoThrottle and min(distance/1900, 1) or 0) + numbers[2], -1, 1)
        seatUD = numbers[4]
        --seat.isAD = math.abs(seat.AD) > inputThreshold
        seatIsWS = math.abs(seatWS) > inputThreshold
        --seat.isLR = math.abs(seat.LR) > inputThreshold
        --seat.isUD = math.abs(seatUD) > inputThreshold

        gpsX = numbers[5]
        gpsY = numbers[6]
        gpsAZ = (numbers[16] + numbers[17])/2

        ground = numbers[20]

        roll = math.atan(math.sin(numbers[9] * PI2), math.sin(numbers[11] * PI2))
        rawHeading = numbers[10]

        xVelocity = numbers[12]
        yVelocity = numbers[13]
        rotationVelocity = numbers[14]

        if startup < startupTime then
            if startup < 10 then
                targetZ = gpsAZ + startAlt
                targetHeading = rawHeading
                targetX = gpsX
                targetY = gpsY
            else
                targetZ = targetZ + startAltRaise
            end
            outputBools[4] = true
        end
        if not bools[1] then
            dockingStage = dockingStage == 0 and numbers[27] ~=0 and 1 or dockingStage
            if ground > landingAlt then
                if dockingStage == 0 or dockingStage == 3 then
                    targetZ = targetZ - clamp(ground/100, startAltRaise, zSpeed/3)
                end
            else
                engineEnabled = false
            end
        end

        if seatIsWS or math.abs(numbers[3]) > inputThreshold then
            moving = true
            outputBools[29] = true
        elseif math.abs(xVelocity) < movementThreshold and math.abs(yVelocity) < movementThreshold then
            moving = false
            outputBools[30] = true
        end

        if math.abs(numbers[1]) > inputThreshold then
            steering = true
        elseif rotationVelocity < steeringThreshold then
            steering = false
        end
        altMultiplier = math.abs(normalize(yVelocity, -maxVy, maxVy)) * zSpeedGain
        if math.abs(seatUD) > inputThreshold then
            targetZ = targetZ + seatUD * sensetivity * zSpeed + seatUD * altMultiplier
            outputBools[28] = true
        end

        gpsErrorX = targetX - gpsX
        gpsErrorY = targetY - gpsY
        distance = (gpsErrorX^2 + gpsErrorY^2)^0.5
        direction = math.atan(gpsErrorX, gpsErrorY)

        headingError = direction + rawHeading * PI2

        if moving then
            targetX = gpsX
            targetY = gpsY
            targetVX = numbers[3] * sensetivity * xSpeed
            targetVY = seatWS * sensetivity * ySpeed * (bools[2] and combatReduction or 1)
        else
            targetVX = math.sin(headingError) * distance
            targetVY = math.cos(headingError) * distance
        end
        autoThrottle = false
        if bools[3] or dockingStage > 0 then
            targetX = dockingStage > 0 and numbers[25] or numbers[22]
            targetY = dockingStage > 0 and numbers[26] or numbers[23]
            atWaypointCapacitor = (distance < 1 and yVelocity < 0.3) and min(atWaypointCapacitor + 1, 60) or 0
            if distance > 5 then
                autoThrottle = true
                targetHeading = rawHeading - clamp(wrappedDifference(rawHeading, -direction/PI2)/2, -yawSpeed, yawSpeed)
                if yVelocity > 100 and math.abs(targetVYaw) < 0.01 then
                    targetZ = targetZ + clamp(((dockingStage > 0 and (numbers[27] + 200) or numbers[24]) - targetZ)/2, -altMultiplier - zSpeed/10, altMultiplier + zSpeed/10)
                end
            elseif atWaypointCapacitor == 60 then
                dockingStage = max(dockingStage, 2)
                targetHeading = rawHeading - clamp(wrappedDifference(rawHeading, numbers[28])/5, -yawSpeed/10, yawSpeed/10) -- nearestDockYaw
                headingCapacitor = math.abs(wrappedDifference(rawHeading, numbers[28])) < 0.001 and min(headingCapacitor + 1, 60) or 0
                if headingCapacitor == 60 then
                    dockingStage = 3
                    headingCapacitor = 0
                end
            end
        end

        if steering then
            targetHeading = rawHeading
            targetVYaw = numbers[1] * sensetivity * yawSpeed
            outputBools[27] = true
        else
            targetVYaw = wrappedDifference(rawHeading, targetHeading)
        end

        targetZ = max(targetZ, safeAlt)

        headingPID:Update(targetVYaw, rotationVelocity * yawRate)
        xHoldPID:Update(targetVX, xVelocity)
        yHoldPID:Update(targetVY, yVelocity)

        pitchOffset = normalize(yHoldPID.output, -yRange, yRange) * pitchScale
        rollOffset = normalize(xHoldPID.output, -xRange, xRange) * rollScale

        altPitchOffset = normalize(yVelocity, -maxVy, maxVy) * normalize(targetZ - numbers[15], -altPitchRange, altPitchRange) * altPitchScale

        altitude_pids[1]:Update(clamp(targetZ - pitchOffset + altPitchOffset, max(gpsAZ - length, safeAlt), gpsAZ + length), numbers[15])
        altitude_pids[2]:Update(clamp(targetZ + rollOffset + pitchOffset, max(max(numbers[15] - length, numbers[17] - width), safeAlt), min(numbers[15] + length, numbers[17] + width)), numbers[16])
        altitude_pids[3]:Update(clamp(targetZ - rollOffset + pitchOffset, max(max(numbers[15] - length, numbers[16] - width), safeAlt), min(numbers[15] + length, numbers[16] + width)), numbers[17])

        outputRotor(1, altitude_pids[1].output, yHoldPID.output, xHoldPID.output + headingPID.output)
        outputRotor(8, altitude_pids[2].output, yHoldPID.output, xHoldPID.output - headingPID.output)
        outputRotor(15, altitude_pids[3].output, yHoldPID.output, -xHoldPID.output + headingPID.output)

        outputNumbers[22] = headingPID.output * sign(yVelocity) * steeringFlapRange * (1 - math.abs(roll/(tiltThreshold*2)))

        outputNumbers[23] = (math.abs(numbers[19]) > boostRpsThreshold or seatIsWS) and yHoldPID.output or 0

        outputNumbers[24] = xHoldPID.output

        outputBools[6] = moving
        outputBools[7] = math.abs(numbers[8] * PI2) > tiltThreshold or math.abs(roll) > tiltThreshold
    end

    outputBools[31] = not engineReady

    dockingStage = ((not engineReady) or bools[1]) and 0 or dockingStage

    outputBools[1] = engineEnabled
    outputBools[2] = startup < startupTime/4 or not (bools[1] or dockingStage == 1)
    outputBools[8] = startup == startupTime
    setOutputs()
end

function outputRotor(startChannel, collective, p, r)
    outputNumbers[startChannel] = collective
    outputNumbers[startChannel + 1] = -collective
    outputNumbers[startChannel + 2] = collective * sign(yVelocity) * liftFlapRange
    outputNumbers[startChannel + 3] = clamp(p * sign(collective), -1, 1)
    outputNumbers[startChannel + 4] = clamp(p * -sign(collective), -1, 1)
    outputNumbers[startChannel + 5] = clamp(r * sign(collective), -1, 1)
    outputNumbers[startChannel + 6] = clamp(r * -sign(collective), -1, 1)
end

function clamp(a, b, c)
    return min(max(a, b), c)
end

function sign(n)
    return (n >= 0 and 1) or -1
end

function wrappedDifference(a, b)
    return (a - b + 0.5)%1 - 0.5
end

function normalize(a, b, c)
    return clamp(((a - b)/(c - b))*2 - 1, -1, 1)
end
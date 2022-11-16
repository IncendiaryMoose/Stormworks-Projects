-- Author: <Authorname> (Please change this in user settings, Ctrl+Comma)
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection

require('Extended_Vector_Math')
require('Capacitor')


function outputRotor(startChannel, collective, p, r)
    outputNumbers[startChannel] = collective
    outputNumbers[startChannel + 1] = -collective
    outputNumbers[startChannel + 2] = collective * sign(velocity.y) * liftFlapRange
    outputNumbers[startChannel + 3] = clamp(p * sign(collective), -1, 1)
    outputNumbers[startChannel + 4] = clamp(p * -sign(collective), -1, 1)
    outputNumbers[startChannel + 5] = clamp(r * sign(collective), -1, 1)
    outputNumbers[startChannel + 6] = clamp(r * -sign(collective), -1, 1)
end

function min(a, b)
    return a < b and a or b
end

function max(a, b)
    return a > b and a or b
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

PI2 = math.pi*2
PI = math.pi

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

maxVelocity = newVector(sensetivity * xSpeed, sensetivity * ySpeed, sensetivity * zSpeed)

vehicleSize = newVector(12.75, 27.75, 3)

vehiclePosition = newVector()
vehicleVelocity = newVector()

targetVehicleVelocity = newVector()

waypointPosition = newVector()

vehicleRotation = newVector()
vehicleRotationalVelocity = newVector()

startupCapacitor = newDoubleEdgeCapacitor(60, 60)
engineCapacitor = newDoubleEdgeCapacitor(60, 60)
waypointCapacitor = newRisingEdgeCapacitor(120)
velocityCapacitor = newDoubleEdgeCapacitor(60, 10)
headingCapacitor = newDoubleEdgeCapacitor(120, 5)
altitudeCapacitor = newDoubleEdgeCapacitor(60, 5)

function onTick()
    vehiclePosition:set(input.getNumber(5), input.getNumber(6), (input.getNumber(16) + input.getNumber(17))/2)

    distanceAboveGround = input.getNumber(20)

    vehicleRotation:set(0, math.atan(math.sin(input.getNumber(9) * PI2), math.sin(input.getNumber(11) * PI2)), input.getNumber(10) * PI2)
    rawHeading = input.getNumber(10)

    vehicleVelocity:set(input.getNumber(12), input.getNumber(13), 0, input.getNumber(14))

    engineEnabled = input.getBool(1) or engineEnabled

    engineCapacitor:updateCapacitor(numbers[18] > engineRpsThreshold or (gpsAZ < safeAlt and bools[1]))

    engineReady = engineCapacitor.output

    startupCapacitor:updateCapacitor(engineReady)

    if engineReady then
        outputBools[3] = true

        seatWS = clamp((numbers[21] > 0.1 and numbers[21] or (autopilotStarted and distance > 10) and min(distance/2000, 1) or 0) + numbers[2], -1, 1)
        seatUD = numbers[4]
        --seat.isAD = math.abs(seat.AD) > inputThreshold
        seatIsWS = math.abs(seatWS) > inputThreshold
        --seat.isLR = math.abs(seat.LR) > inputThreshold
        --seat.isUD = math.abs(seatUD) > inputThreshold

        if startupCapacitor.currentLevel < startupTime then
            if startupCapacitor.currentLevel < 10 then
                waypointPosition:set(vehiclePosition.x, vehiclePosition.y, vehiclePosition.z + startAlt, rawHeading)
            else
                waypointPosition.z = waypointPosition.z + startAltRaise
            end
            outputBools[4] = true
        end

        autoDock = (numbers[27] ~=0 and not bools[1])
        if not bools[1] then
            if distanceAboveGround > landingAlt then
                if not autopilot then
                    waypointPosition.z = waypointPosition.z - clamp(distanceAboveGround/100, startAltRaise, zSpeed/3)
                end
            else
                engineEnabled = false
            end
        end

        if seatIsWS or math.abs(numbers[3]) > inputThreshold then
            moving = true
            outputBools[29] = true
        elseif math.abs(vehicleVelocity.x) < movementThreshold and math.abs(vehicleVelocity.y) < movementThreshold then
            moving = false
            outputBools[30] = true
        end

        if math.abs(numbers[1]) > inputThreshold then
            steering = true
        elseif vehicleVelocity.w < steeringThreshold then
            steering = false
        end
        altMultiplier = math.abs(normalize(vehicleVelocity.y, -maxVy, maxVy)) * zSpeedGain
        if math.abs(seatUD) > inputThreshold then
            waypointPosition.z = waypointPosition.z + seatUD * sensetivity * zSpeed + seatUD * altMultiplier
            outputBools[28] = true
        end

        distance = vehiclePosition:distanceTo(waypointPosition)
        direction = math.atan(waypointPosition.x - vehiclePosition.x, waypointPosition.y - vehiclePosition.y)

        headingError = direction + vehicleRotation.z

        if moving then
            waypointPosition.x = vehiclePosition.x
            waypointPosition.y = vehiclePosition.y
            targetVehicleVelocity.x = input.getNumber(3) * maxVelocity.x
            targetVehicleVelocity.y = seatWS * maxVelocity.y * (bools[2] and combatReduction or 1)
        else
            targetVehicleVelocity.x = math.sin(headingError) * distance
            targetVehicleVelocity.y = math.cos(headingError) * distance
        end

        if bools[3] or autoDock then
            autopilot = true
            waypointPosition.x = autoDock and numbers[25] or numbers[22]
            waypointPosition.y = autoDock and numbers[26] or numbers[23]
            if autopilotStarted then
                if distance > 10 then
                    if vehicleVelocity.y > 120 then
                        waypointPosition.w = -direction/PI2
                        if math.abs(targetVehicleVelocity.w) < 0.01 then
                            waypointPosition.z = waypointPosition.z + clamp(((autoDock and (numbers[27] + 50) or numbers[24]) - waypointPosition.z)/2, -altMultiplier - zSpeed, altMultiplier + zSpeed)
                        end
                    end
                elseif autoDock and distance < 2 and velocity.y < 0.1 then
                    waypointPosition.w = clamp(numbers[28], rawHeading - yawSpeed/4, rawHeading + yawSpeed/4) -- nearestDockYaw
                    if math.abs(targetVehicleVelocity.w) < 0.01 then
                        autopilot = false
                    end
                end
            end
            autopilotStarted = true
        else
            autopilotStarted = false
        end

        if steering then
            waypointPosition.w = rawHeading
            targetVehicleVelocity.w = numbers[1] * sensetivity * yawSpeed
            outputBools[27] = true
        else
            targetVehicleVelocity.w = wrappedDifference(rawHeading, target.heading)
        end

        waypointPosition.z = max(waypointPosition.z, safeAlt)

        headingPID:Update(targetVYaw, vehicleVelocity.w * yawRate)
        xHoldPID:Update(targetVehicleVelocity.x, vehicleVelocity.x)
        yHoldPID:Update(targetVehicleVelocity.y, vehicleVelocity.y)

        pitchOffset = normalize(yHoldPID.output, -yRange, yRange) * pitchScale
        rollOffset = normalize(xHoldPID.output, -xRange, xRange) * rollScale

        altPitchOffset = normalize(vehicleVelocity.y, -maxVy, maxVy) * normalize(waypointPosition.z - numbers[15], -altPitchRange, altPitchRange) * altPitchScale

        altitude_pids[1]:Update(clamp(waypointPosition.z - pitchOffset + altPitchOffset, max(vehiclePosition.z - vehicleSize.y, safeAlt), vehiclePosition.z + vehicleSize.y), numbers[15])
        altitude_pids[2]:Update(clamp(waypointPosition.z + rollOffset + pitchOffset, max(max(numbers[15] - vehicleSize.y, numbers[17] - vehicleSize.x), safeAlt), min(numbers[15] + vehicleSize.y, numbers[17] + vehicleSize.x)), numbers[16])
        altitude_pids[3]:Update(clamp(waypointPosition.z - rollOffset + pitchOffset, max(max(numbers[15] - vehicleSize.y, numbers[16] - vehicleSize.x), safeAlt), min(numbers[15] + vehicleSize.y, numbers[16] + vehicleSize.x)), numbers[17])

        outputRotor(1, altitude_pids[1].output, yHoldPID.output, xHoldPID.output + headingPID.output)
        outputRotor(8, altitude_pids[2].output, yHoldPID.output, xHoldPID.output - headingPID.output)
        outputRotor(15, altitude_pids[3].output, yHoldPID.output, -xHoldPID.output + headingPID.output)

        outputNumbers[22] = headingPID.output * sign(vehicleVelocity.y) * steeringFlapRange * (1 - math.abs(roll/(tiltThreshold*2)))

        outputNumbers[23] = (math.abs(input.getNumber(19)) > boostRpsThreshold or seatIsWS) and yHoldPID.output or 0

        outputNumbers[24] = xHoldPID.output
        outputBools[6] = moving
        outputBools[7] = math.abs(input.getNumber(8) * PI2) > tiltThreshold or math.abs(roll) > tiltThreshold
    end

    outputBools[31] = not engineReady

    outputBools[1] = engineEnabled
    outputBools[2] = startupCapacitor.currentLevel < startupTime/4 or not (bools[1] or autopilot)
    outputBools[8] = startupCapacitor.output
    setOutputs()
end
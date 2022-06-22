require("Extended_Vector_Math")
require("In_Out")
require("Clamp")
function manage_list(listToManage, itemToAdd, maxItems)
	table.insert(listToManage, itemToAdd)
	if #listToManage > maxItems then
		table.remove(listToManage, 1)
	end
end
function weightedAvgList(list)
    local total, weight = 0, 0
    for i, j in ipairs(list) do
        weight = weight + i*2
        total = total + (j*i*2)
    end
    total = total/weight
    return total
end
missilePosition = newExtendedVector()
missileRotation = newExtendedVector()
targetPosition = newExtendedVector()
targetVelocity = newExtendedVector()
targetAcceleration = newExtendedVector()
positionDifference = newExtendedVector()
leadPosition = newExtendedVector()
PI2 = math.pi * 2
targetIndex = property.getNumber("Target")
repeats = property.getNumber("Repeats")
distanceToTarget = 0
timeToImpact = 0
maxLead = property.getNumber("Max Lead")
maxAccel = property.getNumber("Max Accel")
speed = property.getNumber("Speed")
tickCorrection = property.getNumber("Correction")
floaty = 0.075
leadDist = 10000
launch = false
kaboomDist = property.getNumber("Kaboom")
tocks = 0
steeringPower = property.getNumber("Steering Power")
pitchPower = property.getNumber("Pitch Power")
function onTick()
    launch = input.getBool(1)
    if launch then
        tocks = tocks + 1
        missilePosition:set(getInputVector(1))
        missileRotation:set(getInputVector(4))
        targetPosition:set(getInputVector(targetIndex))
        targetVelocity:set(getInputVector(targetIndex + 3))
        targetAcceleration:set(getInputVector(targetIndex + 6))
        leadPosition:copy(targetPosition)
        for k = 1, repeats do
            distanceToTarget = missilePosition:distanceTo(leadPosition)
            timeToImpact = distanceToTarget/speed
            if timeToImpact > 1 then
                targetVelocity:set(getInputVector(targetIndex + 3))
                for i = 0, math.min(timeToImpact, maxLead), 1 do
                    if i > 0 and i < maxAccel then
                        targetVelocity:setAdd(targetVelocity, targetAcceleration)
                    end
                    if i == 0 then
                        leadPosition:copy(targetPosition)
                    else
                        leadPosition:setAdd(leadPosition, targetVelocity)
                    end
                end
            end
        end
        roll = missileRotation.y*1.1
        positionDifference:setSubtract(leadPosition, missilePosition)
        newDist = positionDifference:magnitude()
        pitch = ((math.asin(positionDifference.z/newDist)/PI2)-missileRotation.x)*pitchPower
        targetHeading = math.atan(-positionDifference.x, positionDifference.y)/PI2
        rollover = ((missileRotation.z-targetHeading+0.5)%1)-0.5
        yaw = rollover*steeringPower
        output.setNumber(1, clamp(pitch + roll + floaty, -1, 1))
        output.setNumber(2, clamp(pitch - roll + floaty, -1, 1))
        output.setNumber(3, clamp(yaw, -1, 1))
        output.setNumber(4, clamp(-pitch + roll + floaty, -1, 1))
        output.setNumber(5, clamp(-pitch - roll + floaty, -1, 1))
        output.setNumber(6, clamp(-yaw, -1, 1))
        output.setNumber(9, timeToImpact)
        if tocks > 30 then
            output.setBool(1, (missilePosition:distanceTo(targetPosition) < kaboomDist) or input.getBool(2))
        end
    end
end
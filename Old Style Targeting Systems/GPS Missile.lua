require('Extended_Vector_Math')
require('Advanced_Target_Fast_Decay')
require('In_Out')
require('Clamp')

missilePosition = newVector()
missileRotation = newVector()

PI2 = math.pi * 2

kaboomDist = property.getNumber('Kaboom')
gain = property.getNumber('Gain')
targetIndex = property.getNumber('Target')

target = newTarget(newVector(), 1)
targetDirection = newVector()

tocks = 0
timeToImpact = 0
distances = {}
launch = false

function onTick()
    launch = input.getBool(1)
    if launch then
        if tocks < 6000 then
            tocks = tocks + 1

            missilePosition:set(getInputVector(1))
            missileRotation:set(getInputVector(4))
            missileRotation:setScale(PI2)

            local newPos = newVector(getInputVector(targetIndex))
            if newPos:exists() then
                target:refresh(newPos)
            end
            target:update(missilePosition)
            manage_list(distances, target.distance, 10)
            distanceDelta = MAD(distances)
            avgDistance = weightedAvgList(distances)
            if distanceDelta and distanceDelta > 0 then
                timeToImpact = clamp(avgDistance/distanceDelta, 0, maxPrediction)
            end
            target:positionInTicks(timeToImpact)
            target.position.predicted:setSubtract(missilePosition)
            target.position.predicted:rotate3D(missileRotation, true)
            target.distance = target.position.predicted:magnitude()

            targetPitch = math.asin(target.position.predicted.z/target.distance)
            targetYaw = math.atan(target.position.predicted.x, target.position.predicted.y)

            if tocks > 30 then
                output.setBool(1, (missilePosition:distanceTo(target.position.current) < kaboomDist) or input.getBool(2))
                output.setNumber(1, clamp(targetYaw * gain, -1, 1))
                output.setNumber(2, clamp(targetPitch * gain, -1, 1))
                output.setNumber(3, timeToImpact)
            end
        end
    end
end

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

function MAD(list)
    if #list > 1 then
        local total = 0
        for index, value in ipairs(list) do
            local previousValue = list[index - 1]
            if previousValue then
                total = total + previousValue - value
            end
        end
        return total/(#list - 1)
    end
    return nil
end
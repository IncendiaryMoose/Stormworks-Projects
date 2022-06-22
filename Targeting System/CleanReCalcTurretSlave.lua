require("Extended_Vector_Math")
require("Clamp")
require("In_Out")
require("PID")
yawPID = CreateNewPID(25, 1, 10, 0.1, 100, 100)
PI2 = math.pi*2
maxRange = property.getNumber('Max Range')
minRange = property.getNumber('Min Range')
tickCorrection = property.getNumber('Tick Correction')
maxAccel = property.getNumber('Max Acceleration')
target = property.getNumber('Target')
backup = (target == 15 and 24) or 15
realTarget = target
turretRoll = property.getNumber('Turret Mount Roll Offset')
selfVel = property.getNumber('Self Velocity')
selfAccel = property.getNumber('Self Acceleration')
debugMode = property.getBool('Debug Mode')
limitPrediction = property.getNumber('Limit Prediction')

turretPosition = newExtendedVector()
previousTurretPosition = newExtendedVector()
turretVelocity = newExtendedVector()
previousTurretVelocity = newExtendedVector()
turretAcceleration = newExtendedVector()
turretRollVector = newExtendedVector()
turretPitch = 0
turretYaw = 0
desiredPitch = 0
desiredYaw = 0
vehicleRotation = newExtendedVector()
targetPosition = newExtendedVector()
targetRelativePosition = newExtendedVector()
targetVelocity = newExtendedVector()
targetAcceleration = newExtendedVector()
zeTarget = newExtendedVector()
travelTime = 10
wrappedYaw = 0
previousTurretYaw = 0
zones = property.getText('Deadzones')
deadZones = {}
for yawPoint, minPitch in string.gmatch(zones, "%[([%w.-]+),([%w.-]+)%]") do
	table.insert(deadZones, {tonumber(yawPoint), tonumber(minPitch)})
end

function onTick()
	clearOutputs()

	turretPosition:set(getInputVector(1))
	turretVelocity:setSubtract(turretPosition, previousTurretPosition)
	turretAcceleration:setSubtract(turretVelocity, previousTurretVelocity)
	previousTurretVelocity:copy(turretVelocity)
	previousTurretPosition:copy(turretPosition)
	turretVelocity:setScale(selfVel)
	turretAcceleration:setScale(selfAccel)
	turretPitch = input.getNumber(7)
	zePitch = input.getNumber(14)
	turretYaw = input.getNumber(8)
	turretYawVelocity = turretYaw - previousTurretYaw
	previousTurretYaw = turretYaw
	futureTurretYaw = (turretYaw + turretYawVelocity*limitPrediction)%1
	vehicleRotation:set(getInputVector(4))
	vehicleYaw = vehicleRotation.z
	vehicleRotation:setScale(PI2)
	distA = input.getNumber(10)
	distB = input.getNumber(11)

	targetPosition:set(getInputVector(target))
	targetExists = targetPosition:exists()
	if not targetExists then
		realTarget = backup
	else
		realTarget = target
	end
	targetPosition:set(getInputVector(realTarget))
	targetExists = targetPosition:exists()
	targetVelocity:set(getInputVector(realTarget + 3))
	targetAcceleration:set(getInputVector(realTarget + 6))

	enable = input.getBool(1)
	range = input.getBool(2)
	travelTime = input.getNumber(9)
	shouldFire = input.getBool(realTarget)

	for i = 1, travelTime + tickCorrection do
		targetPosition:setAdd(targetPosition, targetVelocity)
		targetPosition:setSubtract(targetPosition, turretVelocity)
		if i < maxAccel then
			turretVelocity:setAdd(turretVelocity, turretAcceleration)
			targetVelocity:setAdd(targetVelocity, targetAcceleration)
		end
	end
	targetRelativePosition:setSubtract(targetPosition, turretPosition)
    distance = targetRelativePosition:magnitude()
	elevation = math.asin(targetRelativePosition.z/distance)/PI2
	outputNumbers[1] = distance
	outputNumbers[2] = elevation
	fire = shouldFire and (distA > minRange) and (distB > minRange) and (distA > (distance - 15)) and (distB > (distance - 15))
	targetPosition:setAdd(targetRelativePosition, turretPosition)
	zeTarget:set(1, math.atan(targetRelativePosition.x, targetRelativePosition.y), (zePitch + elevation)*PI2)
	zeTarget:toCartesian()
	zeTarget:unRotate3D(vehicleRotation)
	turretRollVector:set(0, ((PI2/4)*turretRoll))
	zeTarget:rotate3D(turretRollVector)
	if debugMode and enable then
		desiredPitch = clamp(input.getNumber(31), -0.25, 0.25)
		desiredYaw = input.getNumber(32)
		local yawError, pitchError = math.abs(yawSpeed(turretYaw, desiredYaw)), math.abs(desiredPitch - turretPitch)
		outputBools[1] = fire and (yawError < 0.03) and (pitchError < 0.01)
	elseif enable and targetExists and range then
		desiredPitch = clamp(math.asin(zeTarget.z)/PI2, -0.25, 0.25)
		desiredYaw = math.atan(zeTarget.x, zeTarget.y)/PI2
		local yawError, pitchError = math.abs(yawSpeed(turretYaw, desiredYaw)), math.abs(desiredPitch - turretPitch)
		outputBools[1] = fire and (yawError < 0.03) and (pitchError < 0.01)
	else
		desiredPitch = 0
		desiredYaw = 0
	end
	if enable then
		wrappedDesiredYaw = yawSpeed(0, futureTurretYaw)
		local yawStart, yawEnd, pitchStart, pitchEnd = -1, 1, 0, 0
		for j, deadZone in ipairs(deadZones) do
			local yawPoint, minPitch = deadZone[1], deadZone[2]
			if wrappedDesiredYaw >= yawPoint then
				yawStart = yawPoint
				pitchStart = minPitch
			else
				yawEnd = yawPoint
				pitchEnd = minPitch
				break
			end
		end
		local yawRange, pitchRange = yawEnd - yawStart, pitchEnd - pitchStart
		local yawPos = (wrappedDesiredYaw-yawStart)/yawRange
		local pitchPos = pitchStart + (pitchRange*yawPos)
		desiredPitch = math.max(desiredPitch, pitchPos)
	end
	wrappedYaw = yawSpeed(turretYaw, desiredYaw)
	yawPID:Update(clamp(wrappedYaw, -0.25, 0.25), turretYawVelocity*2.5)
	outputNumbers[3] = yawPID.output
	outputNumbers[4] = clamp((desiredPitch - turretPitch)*12, -3, 3)
	outputNumbers[5] = desiredPitch
	outputNumbers[6] = desiredYaw
	setOutputs()
end
function inRange(a, b, c)
	return (a > b and a < c)
end
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end
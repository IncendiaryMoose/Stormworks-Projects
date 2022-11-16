require("Advanced_Target_Fast_Decay")
require("Clamp")
function CreateNewPID(proportional_gain,integral_gain,derivitive_gain,max_integral,max_derivitive,max_value)
    return {
    proportional_gain = proportional_gain,
    integral_gain = integral_gain,
    integral = 0,
    max_integral = max_integral,
    derivitive_gain = derivitive_gain,
    max_derivitive = max_derivitive,
    max_value = max_value,
    startup = true,
    Update = function (self,setpoint,process_variable)
        self.setpoint = setpoint
        self.process_variable = process_variable
        self.error = self.setpoint - self.process_variable
        self.proportional = self.error * self.proportional_gain
        self.integral = clamp(self.integral + self.error * self.integral_gain, -self.max_integral, self.max_integral)
        self.derivitive = (self.previous_error and ((self.error - self.previous_error ) * self.derivitive_gain)) or 0
        self.derivitive = clamp(self.derivitive,-self.max_derivitive,self.max_derivitive)
        self.previous_error = self.error
        self.output = clamp(self.proportional + self.integral + self.derivitive, -self.max_value, self.max_value)
        self.startup = false
        return self.output
    end
    }
end
outputNumbers = {}
outputBools = {}
function clearOutputs()
    for i = 1, 32, 1 do
        outputNumbers[i] = 0
        outputBools[i] = false
    end
end
function setOutputs()
    for i = 1, 32, 1 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end
function getInputVector(startChannel)
	return input.getNumber(startChannel), input.getNumber(startChannel + 1), input.getNumber(startChannel + 2)
end
yawPID = CreateNewPID(25, 1, 10, 0.1, 100, 100)
PI2 = math.pi*2
minRange = property.getNumber('Min Range')
maxRange = property.getNumber('Max Range')
targetIndex = property.getNumber('Target')
turretRollOffset = property.getNumber('Turret Mount Roll Offset')
turretPitchOffset = property.getNumber('Turret Mount Pitch Offset')
turretYawOffset = property.getNumber('Turret Mount Yaw Offset')
limitPrediction = property.getNumber('Limit Prediction')
drag = property.getNumber('Drag')
inputOffset = (targetIndex < 15 and 14) or 0
turretOffsetVector = newExtendedVector()
vehicleRotation = newExtendedVector()
disableTime = 0
turret = {
	position = {
		current = newExtendedVector()}
}
target = newTarget(newExtendedVector(), 1, 1)
ballisticTarget = newExtendedVector()
previousTurretYaw = 0
zones = property.getText('Deadzones')
deadZones = {}
for yawPoint, minPitch in string.gmatch(zones, "%[([%w.-]+),([%w.-]+)%]") do
	table.insert(deadZones, {tonumber(yawPoint), tonumber(minPitch)})
end

turretOffsetVector:set(((PI2/4)*turretPitchOffset), ((PI2/4)*turretRollOffset), ((PI2/4)*turretYawOffset))
desiredPitch = 0
desiredYaw = 0

function onTick()
	clearOutputs()

	turretPitch = input.getNumber(7+inputOffset)
	turretYaw = input.getNumber(8+inputOffset)
	ballisticElevation = input.getNumber(12+inputOffset)
	turretYawVelocity = turretYaw - previousTurretYaw
	previousTurretYaw = turretYaw
	futureTurretYaw = (turretYaw + turretYawVelocity*limitPrediction)%1
	vehicleRotation:set(getInputVector(4))
	vehicleYaw = vehicleRotation.z
	vehicleRotation:setScale(PI2)

	turret.position.current:set(getInputVector(1+inputOffset))

	newPos = newExtendedVector(getInputVector(targetIndex))
	if newPos:exists() then
		target:refresh(newPos)
	end
	target:update(turret.position.current)

	enable = input.getBool(1)
	range = input.getBool(2)
	travelTime = input.getNumber(9+inputOffset)

	target:positionInTicks(travelTime)
	target.position.predicted:setSubtract(target.position.predicted, turret.position.current)
    distance = target.position.predicted:magnitude()
	elevation = math.asin(target.position.predicted.z/distance)/PI2
	outputNumbers[1] = distance
	outputNumbers[2] = elevation
	fire = newPos:exists()
	ballisticTarget:set(1, math.atan(target.position.predicted.x, target.position.predicted.y), (ballisticElevation + elevation)*PI2)
	ballisticTarget:toCartesian()
	ballisticTarget:unRotate3D(vehicleRotation)
	ballisticTarget:rotate3D(turretOffsetVector)
	if enable and range then
		disableTime = 0
		desiredPitch = clamp(math.asin(ballisticTarget.z)/PI2, -0.25, 0.25)
		desiredYaw = math.atan(ballisticTarget.x, ballisticTarget.y)/PI2
		local yawError, pitchError = math.abs(yawSpeed(turretYaw, desiredYaw)), math.abs(desiredPitch - turretPitch)
		outputBools[1] = fire and (yawError < 0.05) and (pitchError < 0.0075)
	else
		if disableTime < 120 then
			disableTime = disableTime + 1
		else
			desiredPitch = 0
			desiredYaw = 0
		end
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
	yawPID:Update(clamp(wrappedYaw, -0.2, 0.2), turretYawVelocity*2.5)
	outputNumbers[3] = yawPID.output
	outputNumbers[4] = clamp((desiredPitch - turretPitch)*20, -3, 3)
	outputNumbers[5] = desiredPitch
	outputNumbers[6] = desiredYaw
	outputNumbers[32] = inputOffset+1
	setOutputs()
end
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end
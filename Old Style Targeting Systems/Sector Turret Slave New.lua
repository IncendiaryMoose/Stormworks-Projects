require("Clamp")
--[-0.5,-0.00025][-0.25,-0.00125][0, -0.00025][0.25,-0.00125][0.5,-0.00025]
function CreateNewPID(proportional_gain,integral_gain,derivitive_gain,max_integral,max_derivitive,max_value)
    return {
    proportional_gain = proportional_gain,
    proportional = 0,
    integral_gain = integral_gain,
    integral = 0,
    max_integral = max_integral,
    derivitive_gain = derivitive_gain,
    derivitive = 0,
    max_derivitive = max_derivitive,
    setpoint = 0,
    process_variable = 0,
    error = 0,
    output = 0,
    max_value = max_value,
    Update = function (self, setpoint, process_variable)
        self.setpoint = setpoint
        self.process_variable = process_variable
        self.error = self.setpoint - self.process_variable

        self.proportional = self.error * self.proportional_gain

        self.integral = clamp(self.integral + self.error * self.integral_gain, -self.max_integral, self.max_integral)

        self.derivitive = clamp((self.previous_error and ((self.error - self.previous_error ) * self.derivitive_gain)) or 0, -self.max_derivitive, self.max_derivitive)
        self.previous_error = self.error

        self.output = clamp(self.proportional + self.integral + self.derivitive, -self.max_value, self.max_value)
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
PI2 = math.pi*2
minRange = property.getNumber('Min Range')
maxRange = property.getNumber('Max Range')
tickCorrection = property.getNumber('Tick Correction')
targetIndex = property.getNumber('Target')
debugMode = property.getBool('Debug Mode')
limitPrediction = property.getNumber('Limit Prediction')
targetYawVelocity = property.getNumber('Yaw Velocity')
yawP = property.getNumber('Yaw P')
yawI = property.getNumber('Yaw I')
yawD = property.getNumber('Yaw D')
yawMax = property.getNumber('Yaw Max')
yawIMax = property.getNumber('Yaw I Max')
yawDMax = property.getNumber('Yaw D Max')
maxYawVelocity = property.getNumber('Max Yaw Velocity')
targetPitchVelocity = property.getNumber('Pitch Velocity')
pitchP = property.getNumber('Pitch P')
pitchI = property.getNumber('Pitch I')
pitchD = property.getNumber('Pitch D')
pitchMax = property.getNumber('Pitch Max')
pitchIMax = property.getNumber('Pitch I Max')
pitchDMax = property.getNumber('Pitch D Max')
maxPitchVelocity = property.getNumber('Max Pitch Velocity')
disableTime = 0
previousTurretYaw = 0
previousTurretPitch = 0
zones = property.getText('Deadzones')
deadZones = {}
for yawPoint, minPitch in string.gmatch(zones, "%[([%w.-]+),([%w.-]+)%]") do
	table.insert(deadZones, {tonumber(yawPoint), tonumber(minPitch)})
end

yawPID = CreateNewPID(yawP, yawI, yawD, yawIMax, yawDMax, yawMax)
pitchPID = CreateNewPID(pitchP, pitchI, pitchD, pitchIMax, pitchDMax, pitchMax)

desiredPitch = 0
desiredYaw = 0
previousBallisticAzimuth = 0
previousBallisticElevation = 0

function onTick()
	clearOutputs()

	ballisticElevation = input.getNumber(32)/PI2
	ballisticAzimuth = input.getNumber(31)/PI2
	distance = input.getNumber(30)
	turretPitch = input.getNumber(1)
	turretYaw = input.getNumber(2)
	distA = input.getNumber(3)
	distB = input.getNumber(4)

	turretPitchVelocity = turretPitch - previousTurretPitch
	previousTurretPitch = turretPitch

	turretYawVelocity = turretYaw - previousTurretYaw
	previousTurretYaw = turretYaw
	futureTurretYaw = (turretYaw + turretYawVelocity*limitPrediction)%1

	ballisticAzimuthVelocity = (yawSpeed(previousBallisticAzimuth, ballisticAzimuth))*tickCorrection
	previousBallisticAzimuth = ballisticAzimuth
	futureBallisticAzimuth = yawSpeed(0, ballisticAzimuth + ballisticAzimuthVelocity)

	ballisticElevationVelocity = (ballisticElevation - previousBallisticElevation)*tickCorrection
	previousBallisticElevation = ballisticElevation
	futureBallisticElevation = ballisticElevation + ballisticElevationVelocity

	enable = input.getBool(1)
	range = input.getBool(31)

	fire = input.getBool(2) and distA > math.max(minRange, distance - 15) and distB > math.max(minRange, distance - 15)
	if debugMode and enable then
		disableTime = 0
		desiredPitch = clamp(input.getNumber(31), -0.25, 0.25)
		desiredYaw = input.getNumber(32)
	elseif enable and range then
		disableTime = 0
		desiredPitch = clamp(futureBallisticElevation, -0.25, 0.25)
		desiredYaw = futureBallisticAzimuth
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
		if desiredPitch < pitchPos then outputBools[1] = false end
		desiredPitch = math.max(desiredPitch, pitchPos)
	end
	wrappedYaw = yawSpeed(turretYaw, desiredYaw)
	yawPID:Update(clamp(wrappedYaw, -maxYawVelocity, maxYawVelocity), turretYawVelocity * targetYawVelocity)
	pitchPID:Update(clamp(desiredPitch - turretPitch, -maxPitchVelocity, maxPitchVelocity), turretPitchVelocity * targetPitchVelocity)
	outputNumbers[1] = pitchPID.output
	outputNumbers[2] = yawPID.output
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
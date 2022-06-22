require("Extended_Vector_Math")
require("Clamp")
require("In_Out")
require("PID")
yawPID = CreateNewPID(30, 1, 5, 0.1, 100, 100)
PI2 = math.pi*2
maxRange = property.getNumber('Max Range')
minRange = property.getNumber('Min Range')
tickCorrection = property.getNumber('Tick Correction')
maxAccel = property.getNumber('Max Acceleration')
target = property.getNumber('Target')
turretRoll = property.getNumber('Turret Mount Roll Offset')

turretPosition = newExtendedVector()
turretPitch = 0
turretYaw = 0
vehicleRotation = newExtendedVector()
targetPosition = newExtendedVector()
targetRelativePosition = newExtendedVector()
targetVelocity = newExtendedVector()
targetAcceleration = newExtendedVector()
travelTime = 10
wrappedYaw = 0
previousTurretYaw = 0

function onTick()
	clearOutputs()

	turretPosition:set(getInputVector(1))
	turretPitch = input.getNumber(7)
	turretYaw = input.getNumber(8)
	turretYawVelocity = turretYaw - previousTurretYaw
	previousTurretYaw = turretYaw
	vehicleRotation:set(getInputVector(4))
	vehicleYaw = vehicleRotation.z
	shouldFire = input.getBool(target)
	distA = input.getNumber(10)
	distB = input.getNumber(11)
	distC = input.getNumber(12)
	distLaser = input.getNumber(13)

	targetPosition:set(getInputVector(target))
	targetVelocity:set(getInputVector(target + 3))
	targetAcceleration:set(getInputVector(target + 6))

	enable = input.getBool(1)
	travelTime = input.getNumber(9)
	fire = input.getBool(target)

	for i = 1, travelTime + tickCorrection do
		targetPosition:setAdd(targetPosition, targetVelocity)
		if i < maxAccel then
			targetVelocity:setAdd(targetVelocity, targetAcceleration)
		end
	end
	outputNumbers[7] = vehicleRotation.z
	outputNumbers[11] = vehicleRotation.x
	outputNumbers[12] = vehicleRotation.y
	targetRelativePosition:setSubtract(targetPosition, turretPosition)
	vehicleRotation:setScale(PI2)
	targetRelativePosition:unRotate3D(vehicleRotation)
	vehicleRotation.y = vehicleRotation.y+((PI2/4)*turretRoll)
	targetRelativePosition:rotate3D(vehicleRotation)
    distance = targetRelativePosition:magnitude()
	fire = shouldFire and (distA > minRange) and (distB > minRange) and (distC > minRange) and (distLaser > minRange) and (distLaser > (distance - 15))
	targetPosition:setAdd(targetRelativePosition, turretPosition)
	setOutputToVector(1, targetPosition)
	setOutputToVector(4, turretPosition)
	outputNumbers[10] = turretYaw
	outputNumbers[13] = turretPitch
	if enable then
		outputNumbers[14] = (math.asin(targetRelativePosition.z/distance)/PI2)*4
		wrappedYaw = yawSpeed(turretYaw, vehicleYaw + math.atan(targetRelativePosition.x, targetRelativePosition.y)/PI2)
		outputBools[1] = fire and (math.abs(wrappedYaw) < 0.065) and (math.abs((outputNumbers[14]/4)-turretPitch) < 0.04)
	else
		wrappedYaw = yawSpeed(turretYaw, 0)
	end
	yawPID:Update(clamp(wrappedYaw, -0.25, 0.25), turretYawVelocity*2.5)
	outputNumbers[15] = yawPID.output
	setOutputs()
end

function onDraw()

end

function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end

function vector_magnitude(a)
return (a[1]^2+a[2]^2+a[3]^2)^0.5
end

function subtract_vectors(a,b)return{a[1]-b[1],a[2]-b[2],a[3]-b[3]}
end

function add_vectors(a,b)return{a[1]+b[1],a[2]+b[2],a[3]+b[3]}
end

function scale_vector(a,m)return{a[1]*m, a[2]*m, a[3]*m}
end
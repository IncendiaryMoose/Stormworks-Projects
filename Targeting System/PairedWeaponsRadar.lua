---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Max Er', 7)
simulator:setProperty('Max Mem', 30)
simulator:setProperty('Max Age', 20)
simulator:setProperty('Max Dist', 2000)
simulator:setProperty('Min Dist', 5)
simulator:setProperty('Ref Age', 10)
simulator:setProperty('Min Vel', 0.1)
simulator:setProperty('Sw Dist', 10)
simulator:setProperty('Dist F', 0.1)
simulator:setProperty('Con F', 0)
simulator:setProperty('Vel F', 1)
simulator:setProperty('Age F', 0.1)
simulator:setProperty('Max A', 80)

onLBSimulatorTick = function(simulator, ticks)
end
---@endsection
require("Vector_Math")
require("Target_Group")
require("In_Out")
maxError = 20
maxMemory = 30
maxAge = 15
velocityThreshold = 0.25
distanceFactor = 0.075
speedFactor = 60
ageFactor = 0.5
vehiclePosition = newVector()
worldClickPos = newVector()
h = 160
w = 288
zoom = 3
function onTick()
	clearOutputs()
    vehiclePosition:set(getInputVector(25))

	zoom = input.getNumber(32)
	click = input.getBool(2)
	worldClickPos:set(input.getNumber(30), input.getNumber(31), vehiclePosition.z)

	autoAim = input.getBool(3)
	autoFire = input.getBool(5)
	autoRange = input.getNumber(29)
	manualFire = input.getBool(6)

	trackTargets()
	highestAirThreat = highestAirThreat and oldTargetGroup[highestAirThreat.ID]
	highestGroundThreat = highestGroundThreat and oldTargetGroup[highestGroundThreat.ID]
	for i, potentialThreat in ipairs(targetThreats) do
		local newThreat = oldTargetGroup[potentialThreat.ID]
		local clickDist = worldClickPos:distanceTo(newThreat.position.predicted)
		highestAirThreat = (newThreat.verticalPlacement > -0.001 and selectThreat(highestAirThreat, newThreat, clickDist)) or highestAirThreat
		highestGroundThreat = (newThreat.verticalPlacement < 0.015 and selectThreat(highestGroundThreat, newThreat, clickDist)) or highestGroundThreat
	end
	outputNumbers[14] = finalCount
	setOutputToTarget(15, highestAirThreat)
	setOutputToTarget(24, highestGroundThreat)
	setOutputs()
end
function setOutputToTarget(channel, outputTarget)
	if outputTarget then
		setOutputToVector(channel, outputTarget.position.predicted)
		setOutputToVector(channel + 3, outputTarget.velocity.average)
		setOutputToVector(channel + 6, outputTarget.acceleration.average)
		outputBools[channel] = (outputTarget.age < 15) and (manualFire or (autoFire and outputTarget.distance < autoRange))
		outputBools[channel + 1] = true
	end
end
function selectThreat(currentThreat, newThreat, clickDist)
	if (not currentThreat) or (autoAim and newThreat.threat + 300 < currentThreat.threat) or (click and clickDist < worldClickPos:distanceTo(currentThreat.position.predicted)) then
		currentThreat = newThreat
	end
	return currentThreat
end
function onDraw()
	for l, targetData in pairs(oldTargetGroup) do
		local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, targetData.position.predicted.x, targetData.position.predicted.y)
		screen.setColor(0, 255, 0)
		--screen.drawTextBox(positionScreenX+10,positionScreenY, 90, 15, string.format('Speed: %.2f mph\nAltitude: %.0f ft\nHeading: %.2f deg',10, 500, 45), -1, 0)
		local airTarget, groundTarget, pointDirection, text = highestAirThreat and highestAirThreat.ID == targetData.ID, highestGroundThreat and highestGroundThreat.ID == targetData.ID, 11, nil
		if airTarget or groundTarget then
			text = (airTarget and groundTarget and "Target") or (airTarget and "Air\nTarget") or "Ground\nTarget"
			screen.setColor(255,255,255)
			screen.drawTextBox((positionScreenX-w/2 > 0 and clamp(positionScreenX-38, 57, w-87)) or clamp(positionScreenX+8, 57, w-87), clamp(positionScreenY-7, 0, h-14), 30, 15, text, 0, 0)
		end
		pointDirection = (inRect(positionScreenX, positionScreenY, 48, 4, w-48, h-4) and ((targetData.verticalPlacement < -0.01 and PI) or (targetData.verticalPlacement > 0.01 and 0) or 11)) or math.atan(positionScreenX-w/2, h/2-positionScreenY)
		if pointDirection ~= 11 then
			drawArrow(clamp(positionScreenX, 51, w-50), clamp(positionScreenY, 5, h-4), pointDirection)
		else
			screen.drawCircleF(positionScreenX, positionScreenY, 4)
		end
	end
end
function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
function inRect(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectW and y < rectH
end
function drawArrow(x, y, angle)
    x = x + 5 * math.sin(angle)
    y = y - 5 * math.cos(angle)
    local a1, a2 = angle + 0.45, angle - 0.45
    screen.drawTriangleF(x, y, x - 10*math.sin(a1), y + 10*math.cos(a1), x - 10*math.sin(a2), y + 10*math.cos(a2))
end
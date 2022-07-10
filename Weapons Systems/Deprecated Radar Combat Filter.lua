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
require("In_Out")
require('Deprecated_Radar_Target_Manager')
maxError = 20
maxMemory = 5
maxAge = 30
velocityThreshold = 0.25
distanceFactor = 0.075
speedFactor = 60
ageFactor = 0.5
vehiclePosition = newVector()
worldClickPos = newVector()
h = 160
w = 288
zoom = 3
autoTarget = 1
function onTick()
	clearOutputs()
    vehiclePosition:set(getInputVector(25))
	vehicleYaw = input.getNumber(28)
	zoom = input.getNumber(32)
	click = input.getBool(2)
	worldClickPos:set(input.getNumber(30), input.getNumber(31), vehiclePosition.z)

	autoAim = input.getBool(3)
	autoFire = input.getBool(5)
	autoRange = input.getNumber(29)
	manualFire = input.getBool(6)
	autoTargetButton = input.getBool(8)

	trackTargets()
	threatCount = 0
	for i, sectionTarget in ipairs(sectionTargets) do
		setOutputToTarget(9+(i-1)*3, oldTargetGroup[sectionTarget.ID])
	end
	setOutputToVector(1, worldClickPos)
	outputNumbers[4] = finalCount
	setOutputs()
end
function setOutputToTarget(channel, outputTarget)
	if outputTarget then
		setOutputToVector(channel, outputTarget.position.predicted)
		outputBools[channel] = (outputTarget.age < 15) and (manualFire or (autoFire and outputTarget.distance < autoRange))
		outputBools[channel + 1] = true
	end
end
function selectThreat(currentThreat, newThreat, clickDist)
	if (not currentThreat) or (autoAim and newThreat.threat < 300 and newThreat.threat + 300 < currentThreat.threat) or (click and clickDist < worldClickPos:distanceTo(currentThreat.position.predicted)) then
		currentThreat = newThreat
	end
	return currentThreat
end
function onDraw()
	for l, targetData in pairs(oldTargetGroup) do
		local positionScreenX, positionScreenY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, targetData.position.predicted.x, targetData.position.predicted.y)
		screen.setColor(0, 255, 0)
		local pointDirection, text = 11, nil
		text = string.format('%.3f', targetData.horizontalPlacement)
		screen.drawTextBox((positionScreenX-w/2 > 0 and clamp(positionScreenX-38, 57, w-87)) or clamp(positionScreenX+8, 57, w-87), clamp(positionScreenY-7, 0, h-14), 30, 15, text, -1, 0)
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
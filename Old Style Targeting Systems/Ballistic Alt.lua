-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
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
    simulator:setScreen(1, "9x5")
    simulator:setProperty("Weapon Type", 4)
    simulator:setProperty("Accel", 0.75)
    simulator:setProperty("Jerk", 0.1)
    simulator:setProperty("Sample", 2)
    simulator:setProperty('Turret Mount Roll Offset', 0)
    simulator:setProperty('Turret Mount Pitch Offset', 0)
    simulator:setProperty('Turret Mount Yaw Offset', 0)
    simulator:setProperty('Delay', 0)
    simulator:setProperty('Max Prediction', 60)
    simulator:setProperty('Target', 9)
    simulator:setProperty('Arc Resolution', 30)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    tarX = 1200
    tarY = 0
    tarZ = 500
    selfX = 0
    tarDist = 0
    function onLBSimulatorTick(simulator, tocks)
        tocks = (tocks%1000)/1000
        selfX = 1200*math.cos(tocks*math.pi*2)+1200
        if true then
            tarX = 500*math.cos(tocks*math.pi*2)+1000
            tarY = 50*math.cos(tocks*math.pi*2)
            tarZ = 500*math.sin(tocks*math.pi*2)+500
        end
        tarDist = (tarX^2+tarZ^2)^0.5
        -- touchscreen defaults
        elevationAngle = math.asin((tarZ)/tarDist)
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, 0)
        simulator:setInputNumber(2, 0)
        simulator:setInputNumber(3, 0)
        simulator:setInputNumber(4, 0)
        simulator:setInputNumber(5, 0)
        simulator:setInputNumber(6, math.pi*simulator:getSlider(1))
        simulator:setInputNumber(9, tarX)
        simulator:setInputNumber(10, 0)
        simulator:setInputNumber(11, tarZ)
        simulator:setInputBool(27, simulator:getIsToggled(1))
        simulator:setInputBool(32, true)
    end;
end
---@endsection

--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require('Extended_Vector_Math')
require('Advanced_Target_Fast_Decay')
require('In_Out')
require('Clamp')

zoom = 40
maxAttempts = 5
maxSteps = 5
targetIndex = property.getNumber('Target')
turretRollOffset = property.getNumber('Turret Mount Roll Offset')
turretPitchOffset = property.getNumber('Turret Mount Pitch Offset')
turretYawOffset = property.getNumber('Turret Mount Yaw Offset')
weaponType = property.getNumber('Weapon Type')
weaponData = {
	{800, 0.025, 300}, --MG
	{1000, 0.02, 300}, --LA
	{1000, 0.01, 300}, --RA
	{900, 0.005, 600}, --HA
	{800, 0.002, 3600}, --BA
	{700, 0.001, 3600}, --AR
	{600, 0.0005, 3600}, --BE
}
g = -30/3600
e = 2.71828182846
PI = math.pi
PI2 = PI*2
h = 160
w = 288
gravity = newVector(0, 0, g)
initialVelocity = newVector()
muzzleVelocity = weaponData[weaponType][1]/60
drag = weaponData[weaponType][2]
lifespan = weaponData[weaponType][3]
maxRange = (1/drag) * muzzleVelocity - 500
terminalVelocity = newVector(0, 0, g/drag)
turret = newTarget(newVector(), 2)
turretOffsetVector = newVector((PI2/4)*turretPitchOffset, (PI2/4)*turretRollOffset, (PI2/4)*turretYawOffset)
referenceRotation = newVector()
adjustedRotation = newVector()
relativeRotation = newVector()
vehicleRotation = newVector()
target = newTarget(newVector(), 1)
function newBullet(initialPosition, initialVelocity)
    return {
        position = initialPosition:clone(),
        initialVelocity = initialVelocity:clone(),
        velocity = initialVelocity:clone(),
        acceleration = newVector(),
        speed = muzzleVelocity,
        distance = 0,
        targetError = target.distance,
        age = 0,
        positionInTicks = function (self, t)
            self.age = t

            local A = e^(-drag * t)

            self.velocity:copy(self.initialVelocity)
            self.velocity:setScale(A)
            self.velocity:setScaledAdd(terminalVelocity, 1 - A)

            local vt = self.initialVelocity:clone()
            vt:setSubtract(terminalVelocity)
            vt:setScale((1 - A)/drag)
            vt:setScaledAdd(terminalVelocity, t)

            self.position:copy(vt)

            self.targetError = self.position:distanceTo(target.position.predicted)
            self.distance = self.position:magnitude()
            self.speed = self.velocity:magnitude()
        end
    }
end
travelTime = 60
range = false
accuracy = 0
efficiency = 0
runTime = 0
function onTick()
    local startTime = os.clock()
    clearOutputs()
    if input.getBool(32) then
        turret:refresh(newVector(getInputVector(1)))
        turret:update(target.position.current)
        turret:positionInTicks(0)
        turret.velocity.predicted:setScale((1 - e^(-drag * travelTime))/drag)
        turret.position.predicted:setAdd(turret.velocity.predicted)
        vehicleRotation:set(getInputVector(4))

        local newPos = newVector(getInputVector(targetIndex))
        if newPos:exists() then
            target:refresh(newPos)
        end
        if target.updateAge < maxPrediction then
            target:update(turret.position.predicted)
            target:positionInTicks(travelTime)
            target.position.predicted:setSubtract(turret.position.predicted)
            target.distance = target.position.predicted:magnitude()

            referenceRotation:set(math.asin((target.position.predicted.z)/target.distance), 0, -math.atan(target.position.predicted.x, target.position.predicted.y))
            adjustedRotation:copy(referenceRotation)
            range = false
            if target.position.predicted:exists() and target.distance < maxRange then
                travelTime, accuracy, range, efficiency = ballistic()
            end
            relativeRotation:set(1, -adjustedRotation.z, adjustedRotation.x)
            relativeRotation:toCartesian()
            relativeRotation:rotate3D(vehicleRotation, true)
            relativeRotation:rotate3D(turretOffsetVector)
            outputNumbers[32] = math.asin(relativeRotation.z)
            outputNumbers[31] = -math.atan(relativeRotation.x, relativeRotation.y)
            outputNumbers[30] = target.distance
            outputBools[31] = target.distance < maxRange and range
        end
    end
    setOutputs()
    local endTime = os.clock()
    print(((endTime-startTime)+runTime)/2)
    runTime = endTime-startTime
end
arcResolution = property.getNumber('Arc Resolution')
displayArcs = {}
function onDraw()
    for arcIndex, arc in ipairs(displayArcs) do
        local prevPoint = newVector()
        for pointIndex, point in ipairs(arc) do
            screen.setColor(clamp(pointIndex/lifespan*500, 0, 255), clamp(255-(arcIndex/maxAttempts)*255, 0, 255), 0)
            local drawPos = point:clone()
            if relative then
                drawPos:setSubtract(drawPos, turret.position.current)
            end
            drawPos:setScale(1/zoom)
            screen.drawLine(prevPoint.x, h - prevPoint.z - h/4, drawPos.x, h - drawPos.z - h/4)
            screen.drawLine(prevPoint.x, h/4 - prevPoint.y, drawPos.x, h/4 - drawPos.y)
            prevPoint:copy(drawPos)
        end
    end
    screen.setColor(255, 255, 255)
    local drawCurrent = target.position.current:clone()
    local drawLead = target.position.predicted:clone()
    if relative then
        drawCurrent:setSubtract(drawCurrent, turret.position.current)
        drawLead:setSubtract(drawLead, turret.position.current)
    else
        local drawTurret = turret.position.current:clone()
        drawTurret:setScale(1/zoom)
        screen.drawCircleF(drawTurret.x, h - drawTurret.z - h/4, 2.5)
    end
    drawCurrent:setScale(1/zoom)
    drawLead:setScale(1/zoom)
    screen.drawLine(drawCurrent.x, h - drawCurrent.z - h/4, drawLead.x, h - drawLead.z - h/4)
    screen.drawCircleF(drawCurrent.x, h - drawCurrent.z - h/4, 2.5)

    drawLead = target.position.predicted:clone()
    drawLead:setSubtract(drawLead, turret.position.predicted)
    drawLead:setScale(1/zoom)
    screen.drawLine(drawCurrent.x, h - drawCurrent.z - h/4, drawLead.x, h - drawLead.z - h/4)

    screen.drawText(1,1,string.format('Vi: %.5f', initialVelocity:magnitude()))
    screen.drawText(1,8,string.format('Efficiency: %.0f%%', efficiency))
    screen.drawText(1,15,string.format('Accuracy: %.5f', accuracy))
    screen.drawText(1,22,string.format('Travel Time: %.5f', travelTime))
end

function ballistic()
    local attempts, finalError, finalTime = 0, 0, 0
    displayArcs = {}
    while true do
        if attempts < maxAttempts then
            attempts = attempts + 1
        else
            break
        end
        displayArcs[attempts] = {}
        initialVelocity:set(0, muzzleVelocity, 0)
        initialVelocity:rotate3D(adjustedRotation)
        local bullet = newBullet(newVector(), initialVelocity)
        local approxTime = 0
        local steps = 0
        while true do
            steps = steps + 1
            if steps > maxSteps or bullet.age > lifespan then break end

            local previousTargetError, timeAdjust = bullet.targetError, bullet.targetError/bullet.speed
            bullet:positionInTicks(approxTime + timeAdjust)

            if previousTargetError - bullet.targetError <= 0 then break end

            approxTime = approxTime + timeAdjust
        end
        for i = 1, approxTime, arcResolution do
            bullet:positionInTicks(i)
            table.insert(displayArcs[attempts], bullet.position:clone())
        end
        bullet:positionInTicks(approxTime)
        adjustedRotation.x = adjustedRotation.x + (referenceRotation.x - math.asin(bullet.position.z/bullet.distance))*1.05
        adjustedRotation.z = adjustedRotation.z - (referenceRotation.z + math.atan(bullet.position.x, bullet.position.y))
        finalError = bullet.targetError
        finalTime = bullet.age
        if bullet.targetError < 0.5 then
            break
        end
    end
    return finalTime, finalError, attempts < maxAttempts, (maxAttempts - attempts)/maxAttempts*100
end
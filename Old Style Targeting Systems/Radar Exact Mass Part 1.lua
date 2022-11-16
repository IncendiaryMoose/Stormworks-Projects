---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
onLBSimulatorTick = function(simulator, ticks)
    screenConnection = simulator:getTouchScreen(1)
    sfirstClick = screenConnection.isTouched and 1000000 or 0
    ssecondClick = screenConnection.isTouched and 1000000 or 0
    sfirstClick = sfirstClick + screenConnection.touchX + screenConnection.touchY * 1000
    ssecondClick = ssecondClick + screenConnection.touchX + screenConnection.touchY * 1000
    local screenConnection = simulator:getTouchScreen(1)
    simulator:setInputBool(1, screenConnection.isTouched)
    simulator:setInputNumber(3, screenConnection.touchX)
    simulator:setInputNumber(7, sfirstClick)
end
---@endsection
require('In_Out')
require('Screen_Utility')
require('Button')
require('Clamp')
require('Slider')

newVector = function (x, y, z, w)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        w = w or 0,
        set = function (self, a, b, c, d)
            self.x = a or self.x
            self.y = b or self.y
            self.z = c or self.z
            self.w = d or self.w
        end,
        setAdd = function (self, other)
            self:set(self.x + other.x, self.y + other.y, self.z + other.z)
        end,
        distanceTo = function (self, other)
            return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
        end,
        toCartesian = function (self)
            self:set(self.x * math.sin(self.y) * math.cos(self.z), self.x * math.cos(self.y) * math.cos(self.z), self.x * math.sin(self.z))
        end,
        rotate3D = function (self, rotation)
            local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
            self:set(
                self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
                self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
                self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
            )
        end,
        get = function (self)
            return self.x, self.y, self.z
        end,
        clone = function (self)
            return newVector(self.x, self.y, self.z)
        end,
        copy = function (self, other)
            self:set(other.x, other.y, other.z)
        end,
        exists = function (self)
            return self.x ~= 0 or self.y ~= 0 or self.z ~= 0 or self.w ~= 0
        end
    }
end

redOff = {100,0,0}
redOn = {150,0,0}
greenOff = {0,100,0}
greenOn = {0,150,0}
blueOff = {0,0,50}
blueOn = {0,0,150}
orangeOff = {110,30,0}
orangeOn = {180,70,0}
grey = {20, 20, 20}
lightGrey = {100, 100, 100}
whiteOff = {150,150,150}
whiteOn = {200,200,200}
h = 160
w = 288

buttonHeight = 10
buttons = {}
buttons.zoom = newSlider(1, 1, 196, 9, 5, 46, lightGrey, whiteOff, 'Zoom:', blueOn, blueOff, true)
--buttons.range = newSlider(1, h - buttonHeight, 196, 9, 5, 46, lightGrey, whiteOff, 'Range:', orangeOn, orangeOff, true)
buttons.addZone = newButton(1, 1 + buttonHeight, 43, 9, greenOff, whiteOff, 'Add Zone', greenOn, whiteOn)
buttons.removeZone = newButton(1, 1 + buttonHeight * 2, 43, 9, redOff, whiteOff, 'Remove', redOn, whiteOn)
buttons.clearZones = newButton(1, 1 + buttonHeight * 3, 43, 9, redOff, whiteOff, 'Clear', redOn, whiteOn)

PI = math.pi
PI2 = PI*2

screenClickPos = newVector()
worldClickPos = newVector()
secondScreenClickPos = newVector()
secondWorldClickPos = newVector()
click = false
secondClick = false
zoom = 5
safeZones = {}

vehiclePosition = newVector()
vehicleRotation = newVector()

previousVehiclePosition = newVector()
previousVehicleRotation = newVector()

function onTick()
    clearOutputs()

    targets = {}
    outputNumbers[4] = input.getNumber(7)
    outputNumbers[5] = zoom
    screenClickPos:set(input.getNumber(7)%1000, math.floor((input.getNumber(7)%1000000)/1000))
    secondScreenClickPos:set(input.getNumber(8)%1000, math.floor((input.getNumber(8)%1000000)/1000))
    wasClick = click
    secondWasClick = secondClick
    click = math.floor(input.getNumber(7)/1000000) == 1
    secondClick = math.floor(input.getNumber(8)/1000000) == 1
    worldClick = click and screenClickPos.x > 45 and screenClickPos.x < w-45
    secondWorldClick = secondClick and secondScreenClickPos.x > 45 and secondScreenClickPos.x < w-45

    zoom = buttons.zoom.onPercent * 49 + 1

    vehiclePosition:set(getInputVector(1))
    setOutputToVector(vehiclePosition)
    vehicleRotation:set(getInputVector(4))

    for i = 0, 7 do
        local targetPosition = newVector(getInputVector(i*3 + 9))
        if targetPosition:exists() then
            targetPosition:rotate3D(previousVehicleRotation)
            targetPosition:setAdd(previousVehiclePosition)
            setOutputToVector(i*3 + 9, targetPosition)
        end
    end

    previousVehiclePosition:copy(vehiclePosition)
    previousVehicleRotation:copy(vehicleRotation)

    setOutputs()
end

function onDraw()
    screen.setMapColorGrass(75, 75, 75)
	screen.setMapColorLand(50, 50, 50)
	screen.setMapColorOcean(25, 25, 75)
	screen.setMapColorSand(100, 100, 100)
	screen.setMapColorSnow(100, 100, 100)
	screen.setMapColorShallows(50, 50, 100)

	screen.drawMap(vehiclePosition.x, vehiclePosition.y, zoom)

	if worldClick then
        worldClickPos.z = vehiclePosition.z
        worldClickPos.x, worldClickPos.y = map.screenToMap(vehiclePosition.x, vehiclePosition.y, zoom, w, h, screenClickPos.x, screenClickPos.y)
    end

    if secondWorldClick then
        secondWorldClickPos.z = vehiclePosition.z
        secondWorldClickPos.x, secondWorldClickPos.y = map.screenToMap(vehiclePosition.x, vehiclePosition.y, zoom, w, h, secondScreenClickPos.x, secondScreenClickPos.y)
    end

    screen.setColor(0, 255, 0, 50)
    for z, zone in ipairs(safeZones) do
        local safeX, safeY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, zone.x, zone.y)
        screen.drawCircleF(safeX, safeY, zone.w*(w/(zoom*1000)))
    end

    if buttons.addZone.pressed and worldClick then
        if wasAddingZone then
            if secondWorldClick then
                safeZones[#safeZones].w = safeZones[#safeZones]:distanceTo(secondWorldClickPos)
                buttons.addZone.pressed = false
            end
        else
            table.insert(safeZones, worldClickPos:clone())
        end
    end
    wasAddingZone = buttons.addZone.pressed and worldClick

    if buttons.removeZone.pressed and worldClick then
        local nearestZone, nearestDist = nil, math.huge
        for z, zone in ipairs(safeZones) do
            local zoneDist = zone:distanceTo(worldClickPos)
            if zoneDist < nearestDist then
                nearestDist = zoneDist
                nearestZone = z
            end
        end
        if nearestZone then
            table.remove(safeZones, nearestZone)
        end
        buttons.removeZone.pressed = false
    end

    if buttons.clearZones.pressed then
        buttons.clearZones.pressed = false
        safeZones = {}
    end

    screen.setColor(255, 255, 255)
    drawArrow(w/2, h/2, 15, -vehicleRotation.z)

    screen.setColor(15, 15, 25)
    screen.drawRectF(0, 0, 45, h)
    screen.drawRectF(w - 45, 0, 45, h)
    for b, button in pairs(buttons) do
        button:update(click, wasClick, screenClickPos.x, screenClickPos.y)
    end
end
---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Speed', 8)
simulator:setProperty('GPS Delay', 1)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Max Age', 100)
simulator:setProperty('Delay', 1)
simulator:setProperty('Sample', 5)
simulator:setProperty('Accel', 1)
simulator:setProperty('Jerk', 1)
simulator:setProperty('Max Prediction', 800)

testTargs = {
    50,
    150,
    250,
    350,
    450,
    550,
    650,
    750
}
onLBSimulatorTick = function(simulator, ticks)
    simulator:setInputNumber(1, 0)
    simulator:setInputNumber(2, 0)
    simulator:setInputNumber(3, 0)
    simulator:setInputNumber(4, 0)
    simulator:setInputNumber(5, 0)
    simulator:setInputNumber(6, 0.125)
    tickMod = ticks%10
    for ti = 0, 7 do
        simulator:setInputNumber(ti*3+7, 100 + ti*100 + tickMod*800 + ticks)
        simulator:setInputNumber(ti*3+8, 100 + ti*100 + tickMod*800)
        simulator:setInputNumber(ti*3+9, 100 + ti*100 + tickMod*800)
    end
    simulator:setInputNumber(31, 10101010)
    simulator:setInputNumber(32, 10101010)
end
---@endsection
newVector = function (x, y, z, w)
return {
    x = x or 0,
    y = y or 0,
    z = z or 0,
    w = w or 0,
    set = function (self, a, b, c, d)
        self.x = a
        self.y = b
        self.z = c
    end,
    setAdd = function (self, other)
        self:set(self.x + other.x, self.y + other.y, self.z + other.z)
    end,
    setScaledAdd = function (self, other, scalar)
        self:set(self.x + other.x * scalar, self.y + other.y * scalar, self.z + other.z * scalar)
    end,
    setSubtract = function (self, other)
        self:set(self.x - other.x, self.y - other.y, self.z - other.z)
    end,
    setScale = function (self, scalar)
        self:set(self.x * scalar, self.y * scalar, self.z * scalar)
    end,
    distanceTo = function (self, other)
        return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
    end,
    rotate3D = function (self, rotation)
        local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
        self:set(
            self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
            self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
            self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
        )
    end,
    clone = function (self)
        return newVector(self.x, self.y, self.z)
    end,
    copy = function (self, other)
        self:set(other.x, other.y, other.z)
    end,
    exists = function (self)
        return self.x ~= 0 or self.y ~= 0 or self.z ~= 0
    end
}
end
require('Advanced_Target_Fast_Decay')
require('In_Out')
require('Binary_To_Float')

minDist = 1750
minSeperation = 10
distanceSeperationRatio = 0.1
maxAge = 300
targetSize = 2

vehiclePosition = newVector()

vehicleRotation = newVector()

screenClickPos = newVector()
worldClickPos = newVector()

PI = math.pi
PI2 = PI*2
h = 160
w = 288
targets = {}
function onTick()
    clearOutputs()

    -- screenClickPos:set(input.getNumber(8)%1000, math.floor((input.getNumber(8)%1000000)/1000))
    -- click = math.floor(input.getNumber(8)/1000000) == 1
    -- worldClick = click and screenClickPos.x > 45 and screenClickPos.x < w-45

    vehiclePosition:set(input.getNumber(8), input.getNumber(12), input.getNumber(16))

    vehicleRotation:set(input.getNumber(20), input.getNumber(24), input.getNumber(28))

    controlBits = {}
    floatToBinary(input.getNumber(32), 8, 24, controlBits)
    bitsCompleted = 0
    zoom = binaryToFloat(controlBits, 3, 5) + 25
    range = binaryToFloat(controlBits, 3, 5) * 2000 + 500

    timeSinceUpdate = input.getNumber(4)
    if timeSinceUpdate == 0 then
        for i = 0, 7, 1 do
            local distance, azimuth, elevation = input.getNumber(i*4+1), input.getNumber(i*4+2)*PI2, input.getNumber(i*4+3)*PI2
            if distance == 0 then
                break
            end
            if distance > minDist then
                local targetPosition = newVector(
                    distance * math.sin(azimuth) * math.cos(elevation),
                    distance * math.cos(azimuth) * math.cos(elevation),
                    distance * math.sin(elevation)
                )
                targetPosition:rotate3D(vehicleRotation)
                targetPosition:setAdd(vehiclePosition)
                for targetIndex, target in ipairs(targets) do
                    if targetPosition:distanceTo(target.position) < minSeperation + distance*distanceSeperationRatio then
                        target.age = 0
                        goto skipTarget
                    end
                end
                table.insert(targets, {position = targetPosition, age = 0})
            end
            ::skipTarget::
        end
    end
    for i = #targets, 1, -1 do
        targets[i].age = targets[i].age + 1
        if targets[i].age > maxAge then
            table.remove(targets, i)
        end
    end
end
function onDraw()
    screen.setMapColorGrass(75, 75, 75)
	screen.setMapColorLand(50, 50, 50)
	screen.setMapColorOcean(25, 25, 75)
	screen.setMapColorSand(100, 100, 100)
	screen.setMapColorSnow(100, 100, 100)
	screen.setMapColorShallows(50, 50, 100)

	screen.drawMap(vehiclePosition.x, vehiclePosition.y, zoom)
    screen.setColor(0, 15, 100, 255)
    for targetIndex, target in ipairs(targets) do
        local pixelX, pixelY = map.mapToScreen(vehiclePosition.x, vehiclePosition.y, zoom, w, h, target.position.x, target.position.y)
        screen.drawCircleF(pixelX, pixelY, targetSize)
    end
    screen.setColor(255, 0, 0, 50)
    screen.drawCircle(w/2, h/2, toScreen(2500))
    screen.drawCircleF(w/2, h/2, toScreen(range))
    screen.setColor(255, 255, 255)
    drawArrow(w/2, h/2, 15, -vehicleRotation.z)
end

function toScreen(n)
    return n*(w/(zoom*1000))
end

function drawArrow(x, y, size, angle)
    x = x + size/2 * math.sin(angle)
    y = y - size/2 * math.cos(angle)
    local a1, a2 = angle + 0.35, angle - 0.35
    screen.drawTriangleF(x, y, x - size*math.sin(a1), y + size*math.cos(a1), x - size*math.sin(a2), y + size*math.cos(a2))
end
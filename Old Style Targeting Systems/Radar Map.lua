---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Minimum Distance', 60)
simulator:setProperty('Maximum Distance', 3000)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Autoshoot Distance', 800)
onLBSimulatorTick = function(simulator, ticks)

end
---@endsection
require('Extended_Vector_Math')
require('In_Out')
require('Clamp')
minDist = property.getNumber('Minimum Distance')
maxDist = property.getNumber('Maximum Distance')
wepRange = property.getNumber('Weapons Range')
gpsDelay = property.getNumber('GPS Delay')
vehiclePosition = newVector()
previousVehiclePosition = newVector()
vehiclePositionVelocity = newVector()
vehicleRotation = newVector()
zoom = 5
killZone = 800
PI = math.pi
PI2 = PI*2
h = 160
w = 288
function onTick()

    radarSpin = input.getNumber(7)
    zoom = input.getNumber(8)
    killZone = input.getNumber(9)

    vehiclePosition:set(getInputVector(1))
    vehiclePositionVelocity:copy(vehiclePosition)
    vehiclePositionVelocity:setSubtract(previousVehiclePosition)
    previousVehiclePosition:copy(vehiclePosition)
    vehiclePosition:setScaledAdd(vehiclePositionVelocity, gpsDelay)

    vehicleRotation:set(getInputVector(4))
    vehicleRotation:setScale(PI2)
end
function onDraw()

    screen.setMapColorGrass(75, 75, 75)
	screen.setMapColorLand(50, 50, 50)
	screen.setMapColorOcean(25, 25, 75)
	screen.setMapColorSand(100, 100, 100)
	screen.setMapColorSnow(100, 100, 100)
	screen.setMapColorShallows(50, 50, 100)

	screen.drawMap(vehiclePosition.x, vehiclePosition.y, zoom)

    screen.setColor(255, 0, 0, 50)
    screen.drawCircle(w/2, h/2, toScreen(wepRange))
    screen.drawCircleF(w/2, h/2, toScreen(killZone))

    screen.setColor(0, 255, 0, 50)
    screen.drawCircle(w/2, h/2, toScreen(maxDist))

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
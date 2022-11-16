---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
onLBSimulatorTick = function(simulator, ticks)
    screenConnection = simulator:getTouchScreen(1)
    simulator:setInputBool(1, screenConnection.isTouched)
    simulator:setInputNumber(3, screenConnection.touchX)
    simulator:setInputNumber(4, screenConnection.touchY)
end
---@endsection
require('Screen_Utility')
require('Buttons')
require('Binary')
require('Clamp')
clickX = 0
clickY = 0
click = false
wasClick = false
PI = math.pi
PI2 = PI*2
h = 160
w = 288
redOff = {100,0,0}
redOn = {150,0,0}
greenOff = {0,100,0}
greenOn = {0,150,0}
blueOff = {0,0,100}
blueOn = {0,0,150}
orangeOff = {140,60,0}
orangeOn = {180,70,0}
purpleOff = {100,0,30}
purpleOn = {120,0,50}
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
whiteOn = {200,200,200}
buttonHeight = 16

newButton('mapZoomIn', false, 29, 1, 15, 7, blueOff, whiteOff, '+', blueOn, whiteOn)
newButton('mapZoomOut', false, 29, 9, 15, 7, blueOff, whiteOff, '-', blueOn, whiteOn)
newButton('mapZoom', false, 1, 1, 27, 15, blueOn, whiteOn, 'Map\nZoom')

newButton('addZone', true, 1, buttonHeight+1, 43, 15, greenOff, whiteOff, 'Add Safe\nZone', greenOn, whiteOn)
newButton('removeZone', true, 1, buttonHeight*2+1, 43, 15, redOff, whiteOff, 'Remove\nZone', redOn, whiteOn)
newButton('clearZones', true, 1, buttonHeight*3+1, 43, 15, redOff, whiteOff, 'Clear\nZones', redOn, whiteOn)

newButton('fireRangeIn', false, 29, buttonHeight*4+9, 15, 7, orangeOff, whiteOff, '-', orangeOn, whiteOn)
newButton('fireRangeOut', false, 29, buttonHeight*4+1, 15, 7, orangeOff, whiteOff, '+', orangeOn, whiteOn)
newButton('fireRange', false, 1, buttonHeight*4+1, 27, 15, orangeOn, whiteOn, 'Auto\nRange')

newButton('combatMode', true, 1, buttonHeight*5+1, 43, 15, orangeOff, whiteOff, 'Combat\nMode', orangeOn, whiteOn)
newButton('autoFire', true, 1, buttonHeight*6+1, 43, 15, orangeOff, whiteOff, 'Auto\nFire', orangeOn, whiteOn)

newButton('attackCivilian', true, 1, buttonHeight*7+1, 43, 15, purpleOff, whiteOff, 'Civilian', purpleOn, whiteOn)
newButton('attackUnknown', true, 1, buttonHeight*8+1, 43, 15, purpleOff, whiteOff, 'Unknown', purpleOn, whiteOn)
newButton('attackMilitary', true, 1, buttonHeight*8+1, 43, 15, purpleOff, whiteOff, 'Military', purpleOn, whiteOn)
newButton('rM', true, 1, h-15, 43, 14, purpleOff, whiteOff, 'Raise\nScreen', purpleOn, whiteOn)

shouldAddZone = false
shouldRemoveZone = false

switch = false
camZoom = 0.1
function onTick()
    if input.getBool(2) then
        switch = true
    end
    if switch then
        clickX, clickY = input.getNumber(5), input.getNumber(6)
        switch = input.getBool(1)
    else
        clickX, clickY = input.getNumber(3), input.getNumber(4)
    end
    binaryX, binaryY = intToBinary(clamp(clickX - 44, 0, 198), 8), intToBinary(clickY, 8)
    for k, bit in ipairs(binaryX) do
        output.setBool(k, bit)
    end
    for k, bit in ipairs(binaryY) do
        output.setBool(k+8, bit)
    end
    click = input.getBool(1) or input.getBool(2)
    output.setBool(17, click)
    output.setBool(18, buttons['mapZoomIn'].pressed)
    output.setBool(19, buttons['mapZoomOut'].pressed)
    output.setBool(20, shouldAddZone)
    output.setBool(21, shouldRemoveZone)
    output.setBool(22, buttons['clearZones'].pressed)
    output.setBool(23, buttons['fireRangeIn'].pressed)
    output.setBool(24, buttons['fireRangeOut'].pressed)
    output.setBool(25, buttons['autoFire'].pressed)
    output.setBool(26, buttons['trackCivilian'].pressed)
    output.setBool(27, buttons['trackUnknown'].pressed)
    output.setBool(28, buttons['trackMilitary'].pressed)
    output.setBool(29, buttons['attackCivilian'].pressed)
    output.setBool(30, buttons['attackUnknown'].pressed)
    output.setBool(31, buttons['attackMilitary'].pressed)
end

function onDraw()

    if buttons['addZone'].pressed then
        if click and not wasClick then
            shouldAddZone = true
        end
    end
    if shouldAddZone and not click then
        shouldAddZone = false
        buttons['addZone'].pressed = false
    end
    if buttons['removeZone'].pressed then
        if click and not wasClick then
            shouldRemoveZone = true
        end
    end
    if shouldRemoveZone and not click then
        buttons['removeZone'].pressed = false
        shouldRemoveZone = false
    end
    if buttons['clearZones'].pressed and not shouldAddZone then
        buttons['clearZones'].pressed = false
    end
    screen.setColor(15,15,25)
    screen.drawRectF(0,0,45,h)
    screen.drawRectF(w-45,0,45,h)
    for b, button in pairs(buttons) do
        button:update(click, wasClick, clickX, clickY)
    end
    wasClick = click
end
function upDown(up, down, upDownValue, upDownSpeed, min, max)
    return math.min(math.max(down and (upDownValue - upDownSpeed) or up and (upDownValue + upDownSpeed) or upDownValue, min), max)
end
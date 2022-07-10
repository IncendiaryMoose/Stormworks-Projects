---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
onLBSimulatorTick = function(simulator, ticks)
    screenConnection = simulator:getTouchScreen(1)
    simulator:setInputBool(1, screenConnection.isTouched)
    simulator:setInputNumber(3, screenConnection.touchX)
    simulator:setInputNumber(4, screenConnection.touchY)
end
---@endsection
require("Screen_Utility")
require("Buttons")
require("Binary")
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
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
whiteOn = {200,200,200}

newButton('viewAA', true, w-44, 1, 43, 15, blueOff, whiteOff, 'Anti-Air\nTurret', blueOn, whiteOn)
newButton('viewAG', true, w-44, 17, 43, 15, blueOff, whiteOff, 'Lower\nTurret', blueOn, whiteOn)
newButton('viewTail', true, w-44, 33, 43, 15, blueOff, whiteOff, 'Rear\nTurret', blueOn, whiteOn)
newButton('viewHeavy', true, w-44, 49, 43, 15, blueOff, whiteOff, 'Heavy\nTurret', blueOn, whiteOn)

newButton('mZI', false, 29, 1, 15, 7, blueOff, whiteOff, '+', blueOn, whiteOn)
newButton('mZO', false, 29, 9, 15, 7, blueOff, whiteOff, '-', blueOn, whiteOn)
newButton('mZ', false, 1, 1, 27, 15, blueOn, whiteOn, 'Map\nZoom')

newButton('rRI', false, 29, 25, 15, 7, greenOff, whiteOff, '-', greenOn, whiteOn)
newButton('rRO', false, 29, 17, 15, 7, greenOff, whiteOff, '+', greenOn, whiteOn)
newButton('rR', false, 1, 17, 27, 15, greenOn, whiteOn, 'Radar\nRange')

newButton('kZI', false, 29, 41, 15, 7, redOff, whiteOff, '-', redOn, whiteOn)
newButton('kZO', false, 29, 33, 15, 7, redOff, whiteOff, '+', redOn, whiteOn)
newButton('aR', false, 1, 33, 27, 15, redOn, whiteOn, 'Auto\nRange')

newButton('aA', true, 1, 49, 21, 15, redOff, whiteOff, 'Auto\nAim', redOn, whiteOn)
newButton('aF', true, 23, 49, 21, 15, redOff, whiteOff, 'Auto\nFire', redOn, whiteOn)
newButton('aT', true, 1, 65, 43, 15, redOff, whiteOff, 'Aim\nGround', redOff, whiteOff, 'Aim\nAir')

newButton('aZ', true, 1, 81, 43, 15, greenOff, whiteOff, 'Add Safe\nZone', greenOn, whiteOn)
newButton('rZ', true, 1, 97, 43, 15, redOff, whiteOff, 'Remove\nZone', redOn, whiteOn)
newButton('cZ', true, 1, 113, 43, 15, redOff, whiteOff, 'Clear\nZones', redOn, whiteOn)
shouldAddZone = false
shouldRemoveZone = false

switch = false
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
    binaryX, binaryY = intToBinary(clickX, 9), intToBinary(clickY, 9)
    for k, bit in ipairs(binaryX) do
        output.setBool(k, bit)
    end
    for k, bit in ipairs(binaryY) do
        output.setBool(k+9, bit)
    end
    click = input.getBool(1) or input.getBool(2)
    yaw = input.getNumber(7)-input.getNumber(9)
    count = input.getNumber(8)
    output.setBool(19, click)
    output.setBool(20, buttons['mZI'].pressed)
    output.setBool(21, buttons['mZO'].pressed)
    output.setBool(22, buttons['rRI'].pressed)
    output.setBool(23, buttons['rRO'].pressed)
    output.setBool(24, buttons['kZI'].pressed)
    output.setBool(25, buttons['kZO'].pressed)
    output.setBool(26, buttons['aA'].pressed)
    output.setBool(27, buttons['aF'].pressed)
    output.setBool(29, buttons['aT'].pressed)
    output.setBool(30, buttons['cZ'].pressed)
    output.setBool(31, shouldRemoveZone)
    output.setBool(32, shouldAddZone)
    output.setNumber(1, (buttons['viewAA'].pressed and 1) or (buttons['viewAG'].pressed and 2) or (buttons['viewHeavy'].pressed and 3) or (buttons['viewTail'].pressed and 4) or 0)
    output.setNumber(2, ((buttons['aT'].pressed and 15) or 24))
end

function onDraw()

    if buttons['aZ'].pressed then
        if click and not wasClick then
            shouldAddZone = true
        end
    end
    if shouldAddZone and not click then
        shouldAddZone = false
        buttons['aZ'].pressed = false
    end
    if buttons['rZ'].pressed then
        if click and not wasClick then
            shouldRemoveZone = true
        end
    end
    if shouldRemoveZone and not click then
        buttons['rZ'].pressed = false
        shouldRemoveZone = false
    end
    if buttons['cZ'].pressed and not shouldAddZone then
        buttons['cZ'].pressed = false
    end
    screen.setColor(15,15,25)
    screen.drawRectF(0,0,45,h)
    screen.drawRectF(w-45,0,45,h)
    for b, button in pairs(buttons) do
        button:update(click, wasClick, clickX, clickY)
    end
    if buttons['viewAA'].poked then
        buttons['viewAG'].pressed = false
        buttons['viewHeavy'].pressed = false
        buttons['viewTail'].pressed = false
    elseif buttons['viewAG'].poked then
        buttons['viewAA'].pressed = false
        buttons['viewHeavy'].pressed = false
        buttons['viewTail'].pressed = false
    elseif buttons['viewHeavy'].poked then
        buttons['viewAG'].pressed = false
        buttons['viewAA'].pressed = false
        buttons['viewTail'].pressed = false
    elseif buttons['viewTail'].poked then
        buttons['viewAG'].pressed = false
        buttons['viewHeavy'].pressed = false
        buttons['viewAA'].pressed = false
    end
    wasClick = click
    screen.setColor(255,255,255)
    drawArrow(w/2, h/2, 10, (-yaw*PI2) or 0)
	screen.setColor(0, 255, 0)
	screen.drawTextBox(1, h-12, w, 11, string.format('Targets:\n%.0f',(count or 0)), -1, -1)
end
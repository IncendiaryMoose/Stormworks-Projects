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
orangeOff = {140,60,0}
orangeOn = {180,70,0}
purpleOff = {100,0,30}
purpleOn = {120,0,50}
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
whiteOn = {200,200,200}
buttonHeight = 16

newButton('viewA', true, w-44, 33, 43, 15, blueOff, whiteOff, 'Nose\nCam', blueOn, whiteOn)
newButton('viewB', true, w-44, 49, 43, 15, blueOff, whiteOff, 'Upper\nTurret', blueOn, whiteOn)
newButton('viewC', true, w-44, 65, 43, 15, blueOff, whiteOff, 'Lower\nTurret', blueOn, whiteOn)
newButton('viewD', true, w-44, 81, 43, 15, blueOff, whiteOff, 'Debug', blueOn, whiteOn)
newButton('nV', true, w-44, 17, 43, 15, greenOff, whiteOff, 'Night\nVision', greenOn, whiteOn)
newButton('cZoI', false, w-44, 1, 15, 7, greenOff, whiteOff, '+', greenOn, whiteOn)
newButton('cZoO', false, w-44, 9, 15, 7, greenOff, whiteOff, '-', greenOn, whiteOn)
newButton('cZo', false, w-28, 1, 27, 15, greenOn, whiteOn, 'Cam\nZoom')

newButton('mZI', false, 29, 1, 15, 7, blueOff, whiteOff, '+', blueOn, whiteOn)
newButton('mZO', false, 29, 9, 15, 7, blueOff, whiteOff, '-', blueOn, whiteOn)
newButton('mZ', false, 1, 1, 27, 15, blueOn, whiteOn, 'Map\nZoom')

newButton('aZ', true, 1, buttonHeight+1, 43, 15, greenOff, whiteOff, 'Add Safe\nZone', greenOn, whiteOn)
newButton('rZ', true, 1, buttonHeight*2+1, 43, 15, redOff, whiteOff, 'Remove\nZone', redOn, whiteOn)
newButton('cZ', true, 1, buttonHeight*3+1, 43, 15, redOff, whiteOff, 'Clear\nZones', redOn, whiteOn)

newButton('kZI', false, 29, buttonHeight*4+9, 15, 7, orangeOff, whiteOff, '-', orangeOn, whiteOn)
newButton('kZO', false, 29, buttonHeight*4+1, 15, 7, orangeOff, whiteOff, '+', orangeOn, whiteOn)
newButton('aR', false, 1, buttonHeight*4+1, 27, 15, orangeOn, whiteOn, 'Auto\nRange')

newButton('cM', true, 1, buttonHeight*5+1, 43, 15, orangeOff, whiteOff, 'Combat\nMode', orangeOn, whiteOn)
newButton('aF', true, 1, buttonHeight*6+1, 43, 15, orangeOff, whiteOff, 'Auto\nFire', orangeOn, whiteOn)

newButton('fR', true, 1, buttonHeight*7+1, 43, 15, purpleOff, whiteOff, 'Force\nRepair', purpleOn, whiteOn)
newButton('fE', true, 1, buttonHeight*8+1, 43, 15, purpleOff, whiteOff, 'Force\nSpray', purpleOn, whiteOn)
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
    binaryX, binaryY = intToBinary(clickX, 9), intToBinary(clickY, 9)
    for k, bit in ipairs(binaryX) do
        output.setBool(k, bit)
    end
    for k, bit in ipairs(binaryY) do
        output.setBool(k+9, bit)
    end
    click = input.getBool(1) or input.getBool(2)
    output.setBool(19, click)
    output.setBool(20, buttons['mZI'].pressed)
    output.setBool(21, buttons['mZO'].pressed)
    output.setBool(22, buttons['nV'].pressed)
    output.setBool(23, buttons['cM'].pressed)
    output.setBool(24, buttons['kZI'].pressed)
    output.setBool(25, buttons['kZO'].pressed)
    output.setBool(26, buttons['aF'].pressed)
    output.setBool(27, buttons['fR'].pressed)
    output.setBool(28, buttons['fE'].pressed)
    output.setBool(29, buttons['rM'].pressed)
    output.setBool(30, buttons['cZ'].pressed)
    output.setBool(31, shouldRemoveZone)
    output.setBool(32, shouldAddZone)
    output.setNumber(1, (buttons['viewA'].pressed and 1) or (buttons['viewB'].pressed and 2) or (buttons['viewC'].pressed and 3) or (buttons['viewD'].pressed and 4) or 0)
    camZoom = upDown(buttons['cZoI'].pressed, buttons['cZoO'].pressed, camZoom, 0.01, 0, 1)
    output.setNumber(2, camZoom)
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
    if buttons['viewA'].poked then
        buttons['viewB'].pressed = false
        buttons['viewD'].pressed = false
        buttons['viewC'].pressed = false
    elseif buttons['viewB'].poked then
        buttons['viewA'].pressed = false
        buttons['viewD'].pressed = false
        buttons['viewC'].pressed = false
    elseif buttons['viewD'].poked then
        buttons['viewB'].pressed = false
        buttons['viewA'].pressed = false
        buttons['viewC'].pressed = false
    elseif buttons['viewC'].poked then
        buttons['viewB'].pressed = false
        buttons['viewD'].pressed = false
        buttons['viewA'].pressed = false
    end
    wasClick = click
end
function upDown(up, down, upDownValue, upDownSpeed, min, max)
    return math.min(math.max(down and (upDownValue - upDownSpeed) or up and (upDownValue + upDownSpeed) or upDownValue, min), max)
end
-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "5x3")
    simulator:setProperty('Max Ammo', 1)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(5, simulator:getSlider(1))         -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(6, simulator:getSlider(2))         -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(7, simulator:getSlider(3))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(8, simulator:getSlider(2) * 500)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection
require('Buttons')

maxAmmo = property.getNumber('Max Ammo')
menuStartup = property.getNumber('Menu Startup')

currentColor = {0, 0, 0}
function setToColor(newColor)
    if currentColor[1] ~= newColor[1] or currentColor[2] ~= newColor[2] or currentColor[3] ~= newColor[3] then
        screen.setColor(newColor[1], newColor[2], newColor[3])
        currentColor[1] = newColor[1]
        currentColor[2] = newColor[2]
        currentColor[3] = newColor[3]
    end
end
clickX = 0
clickY = 0
click = false
wasClick = false
PI = math.pi
PI2 = PI*2
h = 96
w = 160
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
yellowOff = {100,100,0}
yellowOn = {120,120,0}
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
greyOff = {70,70,70}
grey = {20, 20, 20}
lightGrey = {100, 100, 100}
whiteOn = {200,200,200}
buttonHeight = 10


buttons.throttle = newSlider(1, h - buttonHeight, 63, 9, 5, 1, lightGrey, whiteOff, '', orangeOn, redOn, 1)
buttons.ammoDoor = newSlider(78, 64, 15, 9, 5, 25, lightGrey, whiteOff, 'AMDR:', orangeOn, grey)
buttons.ammoConnector = newSlider(120, 64, 15, 9, 5, 25, lightGrey, whiteOff, 'AMCN:', orangeOn, grey)
buttons.auto = newSlider(1, 64, 15, 9, 5, 15, lightGrey, whiteOff, 'AP:', purpleOn, grey)
buttons.intake = newSlider(36, 64, 15, 9, 5, 25, lightGrey, whiteOff, 'INTK:', blueOn, grey)
progressBars.iAmmo = newProgressBar(67, h - buttonHeight * 2, 92, 9, 3, lightGrey, whiteOff, 'Ammo [I]', redOn, grey, 0, maxAmmo, 1)
progressBars.heAmmo = newProgressBar(67, h - buttonHeight, 92, 9, 3, lightGrey, whiteOff, 'Ammo [HE]', redOn, grey, 0, maxAmmo, 1)

buttons.throttle.onPercent = 1
--progressBars.iAmmo = newProgressBar(45, 1, 114, 9, 5, lightGrey, whiteOff, 'Ammo [I]', redOn, grey)
--progressBars.heAmmo = newProgressBar(45, 1 + buttonHeight, 114, 9, 5, lightGrey, whiteOff, 'Ammo [HE]', blueOn, grey)
ticks = 0
function onTick()
    if ticks < menuStartup then
        ticks = ticks + 1
        output.setBool(3, true)
    else
        output.setBool(3, buttons.intake.pressed)
    end
    wasClick = click
    click = input.getBool(1)
    clickX, clickY = input.getNumber(3), input.getNumber(4)
    iAmmo, heAmmo = input.getNumber(1), input.getNumber(2)
    output.setNumber(1, 1 - buttons.throttle.onPercent)
    output.setBool(1, buttons.ammoDoor.pressed)
    output.setBool(2, not buttons.ammoConnector.pressed)
    output.setBool(4, buttons.auto.pressed)
end

function onDraw()
    setToColor(whiteOff)
    screen.drawLine(0, 61, w, 61)
    screen.drawText(1, 80, 'throttle hold')
    progressBars.iAmmo:update(iAmmo)
    progressBars.heAmmo:update(heAmmo)

    for b, button in pairs(buttons) do
        button:update(click, wasClick, clickX, clickY)
    end
    for i, indicator in pairs(indicators) do
        indicator:update()
    end
end

function roughEquals(a, b, c)
    return(math.abs(a-b) <= c)
end
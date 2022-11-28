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
    simulator:setProperty('Max Main Gen', 45000)
    simulator:setProperty('Max Sys Gen', 300)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(4, screenConnection.isTouched)
        simulator:setInputNumber(9, screenConnection.touchX)
        simulator:setInputNumber(10, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(1, simulator:getIsToggled(1))
        simulator:setInputNumber(1, simulator:getSlider(1) * 300)
        simulator:setInputNumber(2, simulator:getSlider(2) * 15000)
        simulator:setInputNumber(5, simulator:getSlider(5) * 45000)
        simulator:setInputNumber(6, simulator:getSlider(6))

    end;
end
---@endsection
require('Buttons')

minTemp = property.getNumber('Min Temp')
maxTemp = property.getNumber('Max Temp')
maxWater = property.getNumber('Max Water')
maxWaterLoss = property.getNumber('Max Water Loss')
maxMainGen = property.getNumber('Max Main Gen')
maxSysGen = property.getNumber('Max Sys Gen')

standbyPosition = 1.25
doorTimer = 0

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
--orangeOff = {140,60,0}
orangeOn = {180,70,0}
--purpleOff = {100,0,30}
--purpleOn = {120,0,50}
--yellowOff = {100,100,0}
yellowOn = {120,120,0}
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
--greyOff = {70,70,70}
grey = {20, 20, 20}
lightGrey = {100, 100, 100}
whiteOn = {200,200,200}
buttonHeight = 10

buttons.mag = newSlider(1, 1, 15, 9, 5, 25, lightGrey, whiteOff, 'Mag:', orangeOn, grey)
buttons.refill = newButton(false, 1, 1 + buttonHeight, 43, 9, whiteOff, 'Refill', blueOn, blueOff)
buttons.reload = newButton(false, 1, 1 + buttonHeight * 2, 43, 9, whiteOff, 'Reload', greenOn, greenOff)

progressBars.temp = newProgressBar(45, 1, 114, 9, 5, lightGrey, whiteOff, 'Temp', redOn, grey, 0, minTemp + 100, 1, 'C')
progressBars.water = newProgressBar(45, 1 + buttonHeight, 114, 9, 5, lightGrey, whiteOff, 'Water', blueOn, grey, 0, maxWater, 1, 'L')
progressBars.mainGen = newProgressBar(45, 1 + buttonHeight * 2, 114, 9, 5, lightGrey, whiteOff, 'Main Gen', orangeOn, grey, 0, maxMainGen, 1/1000, 'K-Swatts')
progressBars.mainCharge = newProgressBar(45, 1 + buttonHeight * 3, 114, 9, 5, lightGrey, whiteOff, 'Main Charge', yellowOn, grey, 0, 1, 100, '%%')
progressBars.sysGen = newProgressBar(45, 1 + buttonHeight * 4, 114, 9, 5, lightGrey, whiteOff, 'Sys Gen', orangeOn, grey, 0, maxSysGen, 1, 'Swatts')
progressBars.sysCharge = newProgressBar(45, 1 + buttonHeight * 5, 114, 9, 5, lightGrey, whiteOff, 'Sys Charge', yellowOn, grey, 0, 1, 100, '%%')

indicators.safe = newIndicator(1, 1 + buttonHeight * 3, 43, 9, whiteOff, 'Unsafe', greenOn, redOff, 'Safe')
indicators.ready = newIndicator(1, 1 + buttonHeight * 4, 43, 9, whiteOff, 'Cold', greenOn, blueOff, 'Ready')
indicators.broken = newIndicator(1, 1 + buttonHeight * 5, 43, 9, whiteOff, 'Working', redOn, greenOff, 'Broken!')

function onTick()

    wasClick = click
    click = input.getBool(4)
    clickX, clickY = input.getNumber(9), input.getNumber(10)

    for b, button in pairs(buttons) do
        button:updateTick(click, wasClick, clickX, clickY)
    end

    on = input.getBool(1)
    connected = input.getBool(2)
    recv = input.getBool(3)

    reactorTemp = input.getNumber(1)
    reactorWater = input.getNumber(2)
    rods = input.getNumber(3) == 1
    sliderPosition = input.getNumber(4) - 0.25

    mainGen = input.getNumber(5)
    mainBatt = input.getNumber(6)
    sysGen = input.getNumber(7)
    sysBatt = input.getNumber(8)

    door = recv
    if not recv then
        if doorTimer < 120 then
            doorTimer = doorTimer + 1
        else
           disconect = false
        end
    else
        doorTimer = 0
        disconect = true
    end
    mag = buttons.mag.pressed or recv or disconect
    safe = reactorWater > maxWater - maxWaterLoss
    unsafe = (not safe) and (not connected)
    ready = reactorTemp > minTemp
    if on and safe and rods then
        releaseRods = false
        controlRod = ((reactorTemp - minTemp)/(maxTemp - minTemp))^3
        sliderTarget = 0
        if reactorTemp > maxTemp then
            releaseRods = true
        end
    else
        releaseRods = true
        controlRod = 1
        sliderTarget = standbyPosition
    end
    indicators.safe.pressed = safe
    indicators.ready.pressed = ready
    indicators.broken.pressed = unsafe
    output.setBool(1, releaseRods)
    output.setBool(2, safe)
    output.setBool(3, unsafe)
    output.setBool(4, ready)
    output.setBool(5, mag)
    output.setBool(6, door)
    output.setBool(7, connected and roughEquals(sliderPosition, standbyPosition, 0.015))
    output.setBool(8, buttons.reload.pressed)
    output.setBool(9, buttons.refill.pressed)
    output.setNumber(1, controlRod)
    output.setNumber(2, (sliderPosition - sliderTarget) * 5)
    output.setNumber(3, sliderPosition)
end

function onDraw()
    progressBars.temp:update(reactorTemp)
    progressBars.water:update(reactorWater)
    progressBars.mainGen:update(mainGen)
    progressBars.mainCharge:update(mainBatt)
    progressBars.sysGen:update(sysGen)
    progressBars.sysCharge:update(sysBatt)

    for b, button in pairs(buttons) do
        button:updateDraw(click, wasClick, clickX, clickY)
    end
    for i, indicator in pairs(indicators) do
        indicator:update()
    end
end

function roughEquals(a, b, c)
    return(math.abs(a-b) <= c)
end
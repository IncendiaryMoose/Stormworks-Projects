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
    simulator:setScreen(1, "5x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection
require('Buttons')

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
--paleBlueOff = {75,75,255}
--paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
whiteOn = {200,200,200}
buttonHeight = 16

newButton('mag', true, 1, 1, 43, 15, orangeOff, whiteOff, 'Docking\nMag', orangeOn, whiteOn)
newButton('reload', false, 1, 17, 43, 15, greenOff, whiteOff, 'Request\nReload', greenOn, whiteOn)
newButton('refill', true, 1, 33, 43, 15, blueOff, whiteOff, 'Refill\nWater', blueOn, whiteOn)

function onTick()
    wasClick = click
    click = input.getBool(1)
    clickX, clickY = input.getNumber(3), input.getNumber(4)

    temp = input.getNumber(1)
    waterLevel = input.getNumber(2)
    powerGen = input.getNumber(3)
    
end

function onDraw()
    for b, button in pairs(buttons) do
        button:update(click, wasClick, clickX, clickY)
    end
end

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
require('Screen_Utility')
require('Clamp')
require('Button')
require('Slider')
require('Vertical_Slider')

redOff = {100,0,0}
redOn = {150,0,0}
greenOff = {0,100,0}
greenOn = {0,150,0}
blueOff = {0,0,50}
blueOn = {0,0,150}
orangeOff = {110,30,0}
orangeOn = {180,70,0}
yellowOff = {110,110,0}
purpleOff = {90,0,20}
purpleOn = {120,0,50}
grey = {20, 20, 20}
lightGrey = {100, 100, 100}
paleBlueOff = {75,75,255}
paleBlueOn = {100,100,255}
whiteOff = {150,150,150}
whiteOn = {200,200,200}
h = 160
w = 288

buttonHeight = 10
buttons = {}
buttons.viewSelect = newVerticalSlider(3, 2, 9, 120, 5, 20, lightGrey, whiteOff, 'Cam', purpleOn, purpleOff, true)
buttons.zoom = newVerticalSlider(20, 2, 9, 114, 5, 26, lightGrey, whiteOff, 'Zoom', blueOff, blueOn, true)
buttons.zoom.onPercent = 1

buttons.nightVision = newSlider(2, h - buttonHeight - 2, 13, 9, 5, 15, lightGrey, whiteOff, 'IR:', greenOn, grey)

click = false
function onTick()
    clickX = input.getNumber(3)
    clickY = input.getNumber(4)
    wasClick = click
    click = input.getBool(1)

    for b, button in pairs(buttons) do
        button:updateTick(click, wasClick, clickX, clickY)
    end

    output.setNumber(1, 1 - buttons.zoom.onPercent)
    output.setNumber(2, buttons.viewSelect.onPercent)
    output.setBool(1, buttons.nightVision.pressed)
end

function onDraw()
    screen.setColor(15, 15, 25)
    screen.drawRectF(0, 0, 32, h)

    setToColor(purpleOff)
    screen.drawRect(1, 1, 29, 157)

    for b, button in pairs(buttons) do
        button:updateDraw()
    end

    setToColor(lightGrey)
    screen.drawLine(13, 23, 13, 45) -- 22 to 45
    screen.drawLine(13, 47, 13, 68) -- 46 to 68
    screen.drawLine(13, 70, 13, 92) -- 69 to 92
    screen.drawLine(13, 94, 13, 115) -- 93 to 115
    screen.drawLine(13, 117, 13, 139) -- 116 to 139
end
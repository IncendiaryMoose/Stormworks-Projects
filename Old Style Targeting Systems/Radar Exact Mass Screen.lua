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
require('Binary_Output')

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
buttons.zoom = newSlider(1, 1, 196, 9, 5, 46, lightGrey, whiteOff, 'Zoom:', blueOn, blueOff, true)
buttons.range = newSlider(1, h - buttonHeight - 1, 196, 9, 5, 46, lightGrey, whiteOff, 'Range:', orangeOn, orangeOff, true)

toggleStart = 11
buttons.trackCivilian = newSlider(7, toggleStart + buttonHeight, 13, 9, 5, 20, lightGrey, whiteOff, 'TRK:', greenOn, grey)
buttons.attackCivilian = newSlider(7, toggleStart + buttonHeight * 2, 13, 9, 5, 20, lightGrey, whiteOff, 'ATK:', redOn, grey)

buttons.trackUnknown = newSlider(7, toggleStart + buttonHeight * 4, 13, 9, 5, 20, lightGrey, whiteOff, 'TRK:', greenOn, grey)
buttons.attackUnknown = newSlider(7, toggleStart + buttonHeight * 5, 13, 9, 5, 20, lightGrey, whiteOff, 'ATK:', redOn, grey)

buttons.trackMilitary = newSlider(7, toggleStart + buttonHeight * 7, 13, 9, 5, 20, lightGrey, whiteOff, 'TRK:', greenOn, grey)
buttons.attackMilitary = newSlider(7, toggleStart + buttonHeight * 8, 13, 9, 5, 20, lightGrey, whiteOff, 'ATK:', redOn, grey)

buttons.weld = newSlider(7, 105, 13, 9, 5, 20, lightGrey, whiteOff, 'WLD:', paleBlueOn, grey)
buttons.sprinkle = newSlider(7, 105 + buttonHeight, 13, 9, 5, 20, lightGrey, whiteOff, 'EXT:', paleBlueOn, grey)

buttons.combat = newSlider(3, 130, 13, 9, 5, 25, lightGrey, whiteOff, 'CMBT:', orangeOn, grey)
buttons.autoAttack = newSlider(3, 130 + buttonHeight, 13, 9, 5, 25, lightGrey, whiteOff, 'AATK:', orangeOn, grey)

screenControlls = {}
screenControlls.camView = newSlider(w - 41, 118, 13, 9, 5, 25, lightGrey, whiteOff, 'CAMS:', purpleOn, grey)
screenControlls.massView = newSlider(w - 41, 128, 13, 9, 5, 25, lightGrey, whiteOff, 'MASS:', purpleOn, grey)
screenControlls.adjustScreen = newSlider(w - 41, 138, 13, 9, 5, 25, lightGrey, whiteOff, 'SCRN:', purpleOn, grey)
screenControlls.debug = newSlider(w - 41, 148, 13, 9, 5, 25, lightGrey, whiteOff, 'DBG:', purpleOn, grey)

buttons.trackCivilian.pressed = true
buttons.trackUnknown.pressed = true
buttons.trackMilitary.pressed = true
buttons.attackMilitary.pressed = true

buttons.zoom.onPercent = 0.1
screenControlls.adjustScreen.pressed = true

ticks = 0
click = false
zoom = 5
range = 500
function onTick()
    ticks = ticks%3 + 1
    clickX = input.getNumber(3)
    clickY = input.getNumber(4)
    wasClick = click
    click = input.getBool(1)
    firstClick = click and 1000000 or 0
    --secondClick = input.getBool(2) and 1000000 or 0
    firstClick = firstClick + clickX + clickY * 1000
    --secondClick = secondClick + input.getNumber(5) + input.getNumber(6) * 1000
    outputBits = {}
    floatToBinary(zoom - 25, 3, 5, outputBits)
    floatToBinary(range, 3, 5, outputBits)
    outputBits[17] = buttons.combat.pressed
    outputBits[18] = buttons.autoAttack.pressed
    outputBits[19] = buttons.trackCivilian.pressed
    outputBits[20] = buttons.trackUnknown.pressed
    outputBits[21] = buttons.trackMilitary.pressed
    outputBits[22] = buttons.attackCivilian.pressed
    outputBits[23] = buttons.attackUnknown.pressed
    outputBits[24] = buttons.attackMilitary.pressed
    outputBits[25] = screenControlls.massView.pressed
    outputBits[26] = input.getBool(3)
    bitsCompleted = 0
    output.setNumber(1, binaryToOutput(outputBits))
    output.setNumber(2, firstClick)
    output.setBool(1, buttons.combat.pressed)
    output.setBool(2, screenControlls.adjustScreen.pressed)
    output.setBool(3, screenControlls.debug.pressed)
    output.setBool(4, buttons.weld.pressed)
    output.setBool(5, buttons.sprinkle.pressed)
    output.setBool(6, screenControlls.camView.pressed)
end

function onDraw()
    --[[
    screen.setMapColorGrass(75, 75, 75)
	screen.setMapColorLand(50, 50, 50)
	screen.setMapColorOcean(25, 25, 75)
	screen.setMapColorSand(100, 100, 100)
	screen.setMapColorSnow(100, 100, 100)
	screen.setMapColorShallows(50, 50, 100)

	screen.drawMap(vehiclePosition.x, vehiclePosition.y, zoom)]]

    screen.setColor(15, 15, 25)
    screen.drawRectF(w - 45, 0, 45, h)

    if not screenControlls.camView.pressed then
        screen.drawRectF(0, 0, 45, h)
        setToColor(greenOff)
        screen.drawRect(1, toggleStart + 8, 42, 22)
        setToColor(yellowOff)
        screen.drawRect(1, toggleStart + 38, 42, 22)
        setToColor(redOff)
        screen.drawRect(1, toggleStart + 68, 42, 22)
        setToColor(paleBlueOff)
        screen.drawRect(1, 103, 42, 22)
        setToColor(orangeOff)
        screen.drawRect(1, 128, 42, 30)
        for b, button in pairs(buttons) do
            button:update(click, wasClick, clickX, clickY)
        end
        zoom = buttons.zoom.onPercent * 49 + 1
        range = buttons.range.onPercent
        buttons.trackCivilian.pressed = buttons.trackCivilian.pressed or buttons.attackCivilian.pressed and buttons.attackCivilian.stateChange
        buttons.attackCivilian.pressed = buttons.attackCivilian.pressed and buttons.trackCivilian.pressed

        buttons.trackUnknown.pressed = buttons.trackUnknown.pressed or buttons.attackUnknown.pressed and buttons.attackUnknown.stateChange
        buttons.attackUnknown.pressed = buttons.attackUnknown.pressed and buttons.trackUnknown.pressed

        buttons.trackMilitary.pressed = buttons.trackMilitary.pressed or buttons.attackMilitary.pressed and buttons.attackMilitary.stateChange
        buttons.attackMilitary.pressed = buttons.attackMilitary.pressed and buttons.trackMilitary.pressed
        setToColor(whiteOff)
        screen.drawText(1, toggleStart + 2, 'FRIENDLY:')
        screen.drawText(1, toggleStart + 2 + buttonHeight * 3, 'UNKNOWN:')
        screen.drawText(1, toggleStart + 2 + buttonHeight * 6, 'HOSTILE:')
    end

    setToColor(purpleOff)
    screen.drawRect(w - 44, 116, 42, 42)
    for b, button in pairs(screenControlls) do
        button:update(click, wasClick, clickX, clickY)
    end

end
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
require('Custom_Binary_Output')

function printBinary(binary)
    local readableBinary = ''
    for binaryIndex, bit in ipairs(binary) do
        readableBinary = bit and readableBinary..'1' or readableBinary..'0'
    end
    return readableBinary
end

binaryStorage = {}

for i = 1, 1056 do
    binaryStorage[i] = false
end

click = false
function onTick()
    clickX = input.getNumber(3)
    clickY = input.getNumber(4)
    wasClick = click
    click = input.getBool(1)
    clickedBit = click and math.min(math.floor((clickX/288)*57) + 1 + math.floor(clickY/6) * 57, 1056) or 0
    if click and not wasClick then
        binaryStorage[clickedBit] = not binaryStorage[clickedBit]
    end
    bitsCompleted = 0
    for i = 1, 32 do
        output.setNumber(i, binaryToOutput(binaryStorage))
    end
    for i = 1, 32 do
        output.setBool(i, binaryStorage[bitsCompleted + i])
    end
end

function onDraw()
    screen.setColor(255, 255, 255)
    readable = printBinary(binaryStorage)
    screen.drawTextBox(2, 2, 288, 160, readable, -1, -1)
    screen.drawTextBox(2, 150, 288, 160, clickedBit, -1, -1)
end

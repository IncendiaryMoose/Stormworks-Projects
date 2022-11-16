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
require('Binary_To_Float')

math.randomseed(52562)
testNumbers = {}
for i = 1, 64 do
    testNumbers[i] = math.random(100)
end

ticks = 1
startTime = 0
function onTick()
    --startTime = os.clock()
    ticks = ticks%64 + 1
    if ticks%16 == 1 then
        for i = 1, 64 do
            testNumbers[i] = math.random(-100, 100)
        end
    end
    --testNumbers[ticks] = math.random()*10

    sentBits = {}
    for index, testNumber in ipairs(testNumbers) do
        floatToBinary(testNumber, 4, 12, sentBits)
    end
    bitsCompleted = 0
    for i = 1, 32 do
        output.setNumber(i, binaryToFloat(sentBits, 8, 24))
    end
    --print(os.clock() - startTime)
end

function onDraw()
    for index, value in ipairs(testNumbers) do
        screen.drawText((index - 1)%3*80 + 1, (index - (index - 1)%3)*2 + 1, string.format('Sent:%.0f', value))
    end
end

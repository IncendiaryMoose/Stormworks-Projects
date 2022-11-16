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
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        simulator:setInputBool(1, simulator:getIsToggled(1))
        simulator:setInputBool(2, simulator:getIsToggled(2))
        simulator:setInputBool(3, simulator:getIsToggled(3))
        simulator:setInputBool(4, simulator:getIsToggled(4))
        simulator:setInputBool(5, simulator:getIsToggled(5))
        simulator:setInputBool(6, simulator:getIsToggled(6))
        simulator:setInputBool(7, simulator:getIsToggled(7))
        simulator:setInputBool(8, simulator:getIsToggled(8))
    end;
end
---@endsection
require('In_Out')

numbers = {}
bools = {}
for i = 1, 32 do
    numbers[i] = {
        timer = 0,
        value = 0,
        hasChanged = false
    }
    bools[i] = {
        timer = 0,
        value = false,
        hasChanged = false
    }
end

function onTick()
    clearOutputs()
    for i = 1, 32 do
        local newNum, newBool = input.getNumber(i), input.getBool(i)
        numbers[i].hasChanged = numbers[i].value ~= newNum
        numbers[i].value = newNum
        bools[i].hasChanged = bools[i].value ~= newBool
        bools[i].value = newBool
    end
    sysBatt = numbers[1].value
    engineBatt = numbers[2].value
    onOff = bools[1].value
    outputBools[1] = onOff
    outputBools[2] = bools[2].value and engineBatt
    setOutputs()
end

function onDraw()
end

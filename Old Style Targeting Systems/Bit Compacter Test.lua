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
    --simulator = simulator
    simulator:setScreen(1, "3x3")
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
require('Mini_Binary_To_Float')

function printBinary(binary)
    local readableBinary = ''
    for binaryIndex, bit in ipairs(binary) do
        readableBinary = bit and readableBinary..'1' or readableBinary..'0'
    end
    print(readableBinary)
end

binaryOutput = {}
floatToBinary(0.1, 8, 24, binaryOutput)
printBinary(binaryOutput)

--[[
0.1
    00111101110011001100110011001101
    00111101110011001100110011001101
    00111101110011001100110011001101

0.00000000000000000000000000000000000001
    00000000011011001110001111101110
    00000000011011001110001111101110
-    
    10000000011011001110001111101110
    10000000011011001110001111101110

math.randomseed(52562)

testNumbers = {}
for i = 1, 4 do
    testNumbers[i] = 1000000
end

sentBits = {}
for index, testNumber in ipairs(testNumbers) do
    floatToBinary(testNumber, 6, 4, sentBits)
end

sentNumbers = {}
for i = 1, 8 do
    --print(#sentBits)
    sentNumbers[i] = binaryToFloat(sentBits, 8, 24)
end

receivedNumbers = sentNumbers

receivedBits = {}
for index, receivedNumber in ipairs(receivedNumbers) do
    floatToBinary(receivedNumber, 8, 24, receivedBits)
end
--printBinary(receivedBits)

decodedNumbers = {}
for i = 1, 4 do
    decodedNumbers[i] = binaryToFloat(receivedBits, 6, 4)
    print(string.format('Sent Number: %.8f\nReceived Number: %.8f', testNumbers[i], decodedNumbers[i]))
end]]
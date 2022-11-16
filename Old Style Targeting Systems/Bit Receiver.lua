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

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, -0)
        simulator:setInputNumber(2, 0)
        simulator:setInputNumber(3, 0)
        simulator:setInputNumber(4, 0)
        
    end;
end
---@endsection
require('Custom_Binary_Input')

function printBinary(binary)
    local readableBinary = ''
    for binaryIndex, bit in ipairs(binary) do
        readableBinary = bit and readableBinary..'1' or readableBinary..'0'
    end
    return readableBinary
end

function onTick()
    binaryStorage = {}
    for i = 1, 32 do
        inputToBinary(input.getNumber(i), binaryStorage)
    end
    for i = 1, 32 do
        binaryStorage[#binaryStorage+1] = input.getBool(i)
    end
end

function onDraw()
    screen.setColor(255, 255, 255)
    readable = printBinary(binaryStorage)
    screen.drawTextBox(2, 2, 288, 160, readable, -1, -1)
end

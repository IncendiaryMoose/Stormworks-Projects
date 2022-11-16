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
    simulator:setScreen(1, "9x3")
    simulator:setProperty('Masses', '2400=2,40960=0,20480=0,460=0,17280=0,9920=0,7040=0,2320=2,4160=0,3840=0,2160=2,3680=0,3040=0,1440=0,1360=0,1240=2,800=0,720=0,920=2,220=2,1200=2,48640=2,4960=2')

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
        simulator:setInputNumber(1, 1250 * (simulator:getSlider(1) + simulator:getSlider(2) + simulator:getSlider(3) + simulator:getSlider(4) + simulator:getSlider(5)) + simulator:getSlider(6)/2)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection
require('Mini_Binary_To_Float')
require('Custom_Binary_Format')

defaultMassValues =
{
    478, -- CIV Small Prop Plane (Blue/White)
    731, -- CIV Small Coax Copter (Red/White)
    824, -- CIV Small Prop Plane (Yellow/Black)
    1418, -- CIV Small Prop Plane (Red/White)
    1452, -- CIV Small Copter
    1482, -- CIV Medium Copter (Red/White)
    3125, -- CIV Medium Copter (Blue/Red/White)
    3834, --96, -- CIV Medium Copter (Blue/White)
    3863, -- CIV Medium Twin Prop Plane (Blue/White)
    4279, -- CIV Small Boat
    7264, -- CIV Refueller Plane
    10218, -- CIV Tugboat (Green)
    17715, -- CIV Medium Boat (Red)
    21200, --177, -- CIV Medium Boat (Grey)
    42511 -- CIV Oil Tanker (Blue/Red)
}

impwepMassValues =
{
    229, -- IMP 2x2 Missile
    941, -- IMP Small Prop Plane (O-2 Skymaster)
    1252, -- IMP SAM Turret
    2174, -- IMP Small Copter (Tiger)
    2372, 200, 111, 59, -- IMP Jet, Jet Hardpoint (Eurofighter)
    2426, 61, -- IMP Small Copter (Venom)
    5071, -- IMP Patrol Boat (BS-H1)
    48726, 1218 -- IMP Battleship, Battleship Turret (Destroyer)
}

compressedCivMasses =
{
    480,
    728,
    824,
    1424,
    1456,
    1488,
    3136,
    3840,
    3872,
    4288,
    7296,
    10240,
    17664,
    21248,
    42496
}

compressedMilMasses =
{
    478,731,824,1418,1452,1482,3125,3834,3863,4279,7264,10218,17716,21200,42512,3822,1416,2721,2167,1309,80240
}
table.sort(compressedMilMasses, function (a, b)
    return a < b
end)

massString = ''
for index, value in pairs(compressedMilMasses) do
  massString = massString..string.format('%.0f,', value)
end
print(massString)
--[[
for index, value in ipairs(compressedMilMasses) do
    class[value] = 2
end
for index, value in ipairs(compressedCivMasses) do
    class[value] = 0
end

masses = property.getText('Masses')
class = {}
for massValue, classValue in string.gmatch(masses, "(%d+)=(%d+)") do
	class[tonumber(massValue)] = tonumber(classValue)
end]]

function printBinary(binary)
    local readableBinary = ''
    for binaryIndex, bit in ipairs(binary) do
        readableBinary = bit and readableBinary..'1' or readableBinary..'0'
    end
    return readableBinary
end

math.randomseed(4598)
testPoses = {}
testCount = 500
for i = 1, testCount do
    testPoses[i] = math.random(1, 1000000)--math.random(0, 5000*100000000000000)/100000000000000
    --print(testPoses[i])
end
testPoses[testCount] = 60
testPoses[testCount - 1] = 101
testPoses[testCount - 2] = 100
testPoses[testCount - 3] = 1041
testPoses[testCount - 4] = 2499
testPoses[testCount - 5] = 2372
testPoses[testCount - 6] = 2500
print(#testPoses)

resultPoses = {}
ticks = 0
totalErr = 0
-- 1k Values
-- 5, 24 == 3.2614843403022e-10
-- 8, 24 == 3.2614843403022e-10
-- 5, 23 == 4.496706884716e-05
-- 5, 25 == 1.9309478940724e-13
-- 1, 28 == 5k Val, 5k Rad, 9.9217968601169e-06
-- 5, 24 == ^ 1.9954864148574e-13
-- 5, 24 == 5k Val, 2.6k Rad, 9.7778179054353e-14
-- 1, 28 == ^ 4.9350495116896e-06
-- 4, 25, 0 works for +- 5k
--[
for index, value in ipairs(defaultMassValues) do
    outputBits = {}
    floatToBinary(4272, 4, 13, -4, outputBits, 1)
    print(printBinary(outputBits))
    bitsCompleted = 0
    resultPoses[index] = binaryToFloat(outputBits, 4, 13, -4, 1)
end
--]]
--[[]
    for index, value in ipairs(testPoses) do
        outputBits = {}
        floatToBinary(value, 6, 7, outputBits, true)
        bitsCompleted = 0
        resultPoses[index] = binaryToFloat(outputBits, 6, 7, true)
    end
    --]]
--[[]
for index, value in ipairs(testPoses) do
    outputBits = {}
    customToBinary(value, 13, 0.008, outputBits)

    resultPoses[index] = binaryToCustom(outputBits, 13, 0.008)
end
--]]
totalErr = 0
for index, value in ipairs(resultPoses) do
    totalErr = totalErr + abs(testPoses[index] - value)
    print(string.format('IN: %.11f , OUT: %.11f', testPoses[index], value))
end
print(totalErr/(testCount - 1))

massString = ''
for index, value in pairs(resultPoses) do
  massString = massString..string.format('%.0f=%.0f,', value, 2)
end
print(massString)
--[[
function onTick()
    testBits = {}
    sBits = {}
    lBits = {}
    num = input.getNumber(1)
    floatToBinary(num, 11, 53, lBits)
    floatToBinary(num, 8, 24, sBits)
    floatToBinary(num, 4, 4, testBits)
    luaBits = printBinary(lBits)
    stormworksBits = printBinary(sBits)
    custom = printBinary(testBits)
    bitsCompleted = 0
    normalNum = binaryToFloat(sBits, 8, 24)
    bitsCompleted = 0
    compressedNum = binaryToFloat(testBits, 4, 4)
end

function onDraw()
    screen.drawText(1, 6, string.format('Sent     : %.8f', num))
    screen.drawText(1, 16, string.format('Received: %.8f', compressedNum))
    screen.drawText(1, 26, string.format('Normal  : %.8f', normalNum))
    screen.drawText(1, 36, luaBits)
    screen.drawText(1, 46, stormworksBits)
    screen.drawText(1, 56, custom)
end]]
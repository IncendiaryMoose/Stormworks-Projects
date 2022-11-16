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
    simulator:setScreen(1, "3x3")
    simulator:setProperty('Cycle Time', 60)
    simulator:setProperty('Cycle Count', 10)
    simulator:setProperty('V', 2)

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


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require('In_Out')
cycleTime = property.getNumber('Cycle Time')
cycleCount = property.getNumber('Cycle Count')
maxSpeed = property.getNumber('Max Speed')
speedScale = property.getNumber('Speed Scale')
maxDelta = property.getNumber('Max Delta')
heatScale = property.getNumber('Heat Scale')
speedHeat = 1-heatScale
H = property.getNumber('H')
S = property.getNumber('S')
V = property.getNumber('V')
ticks = 0

function onTick()
    clearOutputs()
    heat = math.max(input.getNumber(1)/maxDelta, 0)
    speed = math.abs(input.getNumber(2)/maxSpeed)
    adjCycleTime = cycleTime-speed*speedScale
    outputNumbers[1], outputNumbers[2] = H, S
    ticks = (ticks + 1)%(adjCycleTime*cycleCount)
    for cycle = 1, cycleCount do
        local currentCycle = (ticks + cycle*adjCycleTime)%(adjCycleTime*cycleCount)
        local fade = math.min(1-math.sin((currentCycle/(adjCycleTime*cycleCount))*math.pi)/V, heat*heatScale + speed*speedHeat)
        outputNumbers[cycle + 2] = fade
    end
    setOutputs()
end
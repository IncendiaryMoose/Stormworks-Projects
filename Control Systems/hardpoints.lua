-- Author: <Authorname> (Please change this in user settings, Ctrl+Comma)
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
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
        simulator:setInputNumber(11, simulator:getSlider(2))     -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(21, math.floor((simulator:getSlider(1))*5+1))           -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
hardpoints = {}
ordinances = {"UTIL", "FUEL", "UNG BMB", "LSR BMB", "GPS BMB", "RKT", "RKT POD", "LSR MSL", "GPS MSL", "RDR MSL", "TORP", "CANNON"}

numOfHardpoints = property.getNumber("Number of Hardpoints")

function initialize()
    for i = 1, numOfHardpoints do
           hardpoints[i] = input.getNumber(i + 10)
    end
end

function onTick()
    initialize()

    isP1 = input.getBool(1)
    isP2 = input.getBool(2)

    in1X = input.getNumber(3)
    in1Y = input.getNumber(4)
    in2X = input.getNumber(5)
    in2Y = input.getNumber(6)

    selectedHardpoint = input.getNumber(21)
end

function onDraw()
    screen.setColor(0,0,0)
    screen.drawRectF(0,0,64,32)
    screen.drawRectF(1,1,62,30)
    screen.setColor(96,96,96)
    screen.drawTextBox(0, 0, 64, 32, ordinances[hardpoints[selectedHardpoint]], 0, 0)
end

function isInRect(x,y,w,h,px,py)
    return px>=x and px<=x+w and py>=y and py<=y+h
end
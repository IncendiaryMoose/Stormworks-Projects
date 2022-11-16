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
    simulator:setScreen(1, "5x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)

        simulator:setInputBool(32, simulator:getIsToggled(2))
        simulator:setInputNumber(1, simulator:getSlider(1) * 50)
        simulator:setInputNumber(2, simulator:getSlider(2))
        simulator:setInputNumber(5, simulator:getSlider(3) * 50)
        simulator:setInputNumber(6, simulator:getSlider(4))
    end;
end
---@endsection
filterMassValues =
{
    12, 13, --Player (Technically 12.5)
    20,   --Lifesaver
    25,   --Player
    35,   --Fire Ext Prop
    50,   --Pallet
    80,   --Barrel
    100,  --Fluid Crate, Propane, Large Propane
    112, -- Small Fuel Gantry
    125,  --Tool Cart
    175,  --Large Cart
    300,  --Large Chest
    397, -- Coal Gantry
    400,  --Loot Crate
    2499, --Container
    2500  --Tree
}

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
    2372, --200, 111, 59, -- IMP Jet, Jet Hardpoint (Eurofighter)
    2426, --61, -- IMP Small Copter (Venom)
    5071, -- IMP Patrol Boat (BS-H1)
    48726, 1218, -- IMP Battleship, Battleship Turret (Destroyer)
}

priorityMassValues =
{
    229, -- IMP 2x2 Missile
    941, -- IMP Small Prop Plane (O-2 Skymaster)
    1252, -- IMP SAM Turret
    2174, -- IMP Small Copter (Tiger)
    2372, 200, 111, 59, -- IMP Jet, Jet Hardpoint (Eurofighter)
    2426, 61, -- IMP Small Copter (Venom)
    5071, -- IMP Patrol Boat (BS-H1)
    48726, 1218, -- IMP Battleship, Battleship Turret (Destroyer)
    112, -- CIV Small Fuel Gantry
    397, -- CIV Coal Gantry
    478, -- CIV Small Prop Plane (Blue/White)
    731, -- CIV Small Coax Copter (Red/White)
    824, -- CIV Small Prop Plane (Yellow/Black)
    1418, -- CIV Small Prop Plane (Red/White)
    1452, -- CIV Small Copter
    1482, -- CIV Medium Copter (Red/White)
    3125, -- CIV Medium Copter (Blue/Red/White)
    3834, 96, -- CIV Medium Copter (Blue/White) 
    3863, -- CIV Medium Twin Prop Plane (Blue/White)
    4279, -- CIV Small Boat
    7264, -- CIV Refueller Plane
    10218, -- CIV Tugboat (Green)
    17715, -- CIV Medium Boat (Red)
    21200, 177, -- CIV Medium Boat (Grey)
    42511 -- CIV Oil Tanker (Blue/Red)
}

excludeMasses = {}

for index, value in ipairs(specialMassValues) do
    excludeMasses[value] = true
end

massRanges =
{
    {1, 50}, --Player, 1
    {50, 500},  --Prop, 2
    {500, 1000}, --Ultra Light Vehicle, 3
    {1000, 2500}, --4
    {2500, 5000}, --5
    {5000, 7500}, --6
    {7500, 10000}, --7
    {10000, 12500}, --8
    {12500, 15000}, --9
    {15000, 17500}, --10
    {20000, 22500}, --11
    {25000, 27500}, --12
    {27500, 50000}, --Medium Vehicle, 13
    {50000, 100000}, --Heavy Vehicle, 14
    {100000, 300000}, --Very Heavy Vehicle, 15
    {300000, math.huge}, --Ultra Heavy Vehicle, 16
}

displayMasses = {
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0},
    {mass = 0, group = 0}
}

function inRange(a, b, c)
	return (a > b and a < c)
end

function onTick()
    for i = 0, 7 do
        local distance = input.getNumber(i*4+1)
        if distance > 0 then
            local mass = math.floor(distance * input.getNumber(i*4+2) + 0.5)
            displayMasses[i+1].mass = mass
            if excludeMasses[mass] then
                displayMasses[i+1].group = -1
            end
            for massIndex, massRange in ipairs(massRanges) do
                if inRange(mass, massRange[1], massRange[2]) then
                    displayMasses[i+1].group = massIndex
                    break
                end
            end
        else
            displayMasses[i+1].mass = 0
            displayMasses[i+1].group = 0
        end
    end
end

function onDraw()
    screen.setColor(255, 255, 255)
    for index, displayMass in ipairs(displayMasses) do
        screen.drawText(1, (index - 1) * 8 + 1, string.format('Group:%.0f', displayMass.group))
        screen.drawText(50, (index - 1) * 8 + 1, string.format('Mass:%.0f', displayMass.mass))
    end
end

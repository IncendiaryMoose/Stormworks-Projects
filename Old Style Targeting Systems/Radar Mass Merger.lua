require('Extended_Vector_Math')
function manage_list(listToManage, itemToAdd, maxItems)
	table.insert(listToManage, itemToAdd)
	if #listToManage > maxItems then
		table.remove(listToManage, 1)
	end
end
spinTime = property.getNumber('Spin Time')
spinCorrection = property.getNumber('Spin Correction')
minDist = property.getNumber('Minimum Distance')
maxDist = property.getNumber('Maximum Distance')
minMass = property.getNumber('Minimum Mass')
filterCivilians = property.getBool('Filter Civilians')
groupDist = property.getNumber('Group Distance')
spinCounter = 0
spin = 0
facing = 0
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

missileMassValues =
{
    229
}

excludeMasses = {}

for index, value in ipairs(filterMassValues) do
    excludeMasses[value] = true
end

if filterCivilians then
    for index, value in ipairs(defaultMassValues) do
        excludeMasses[value] = true
    end
end

civMasses = {}

for index, value in ipairs(defaultMassValues) do
    civMasses[value] = true
end

milMasses = {}

for index, value in ipairs(impwepMassValues) do
    milMasses[value] = true
end

priorityMasses = {}

for index, value in ipairs(missileMassValues) do
    priorityMasses[value] = true
end

--[[
massRanges =
{
    {0, 500}, --Player/Prop, 1
    {500, 1000}, --Ultra Light Vehicle, 2
    {1000, 2500}, --3
    {2500, 5000}, --4
    {5000, 7500}, --5
    {7500, 10000}, --6
    {10000, 12500}, --7
    {12500, 15000}, --8
    {15000, 17500}, --9
    {20000, 22500}, --10
    {25000, 27500}, --11
    {27500, 50000}, --Medium Vehicle, 12
    {50000, 100000}, --Heavy Vehicle, 13
    {100000, 300000}, --Very Heavy Vehicle, 14
    {300000, math.huge}, --Ultra Heavy Vehicle, 15
}
]]

massRanges =
{
    {0, 1000}, --1
    {1000, 2500}, --2
    {2500, 5000}, --3
    {5000, 10000}, --4
    {10000, 25000}, --5
    {25000, 75000}, --6
    {75000, 125000}, --7
    {125000, math.huge} --8
}

outputNumbers = {}
PI = math.pi
PI2 = PI*2
oldFacings = {}

function onTick()
    clearOutputs()

    targets = {}

    spinCounter = (spinCounter + 1)%spinTime
    spin = (spinCounter/spinTime) - 0.5
    facing = spin * PI2
    manage_list(oldFacings, facing, spinCorrection)

    for i = 0, 7 do
        local distance = input.getNumber(i*4+1)
        local mass = math.floor(distance * input.getNumber(i*4+2) + 0.5)
        if not excludeMasses[mass] then
            if mass >= minMass and distance > minDist and distance < maxDist then

                local elevation, azimuth = input.getNumber(i*4+3)*PI2, input.getNumber(i*4+4)*PI2
                azimuth = math.asin(math.sin(azimuth)/math.cos(elevation))
                local targetPosition = newVector(distance, oldFacings[1] + azimuth, elevation)
                targetPosition:toCartesian()

                for targetIndex, target in ipairs(targets) do
                    if targetPosition:distanceTo(target.position) < groupDist then
                        if mass > target.mass then
                            targets[targetIndex] = {
                                position = targetPosition:clone(),
                                mass = mass
                            }
                        end
                        goto safe
                    end
                end
                table.insert(targets, {
                    position = targetPosition:clone(),
                    mass = mass
                })
                ::safe::
            end
        end
    end

    massNumber = 0
    for targetIndex, target in ipairs(targets) do
        setOutputToVector((targetIndex - 1) * 3 + 7, target.position)
        if not civMasses[target.mass] then
            local massOffset = milMasses[target.mass] and 8 or 0
            for massIndex, massRange in ipairs(massRanges) do
                if inRange(target.mass, massRange[1], massRange[2]) then
                    massNumber = massNumber + (massIndex + massOffset) * (100^(8 - targetIndex))
                    break
                end
            end
        end
    end

    outputNumbers[1] = spin
    outputNumbers[31] = math.floor(massNumber/100000000)
    outputNumbers[32] = massNumber%100000000

    setOutputs()
end
function inRange(a, b, c)
	return (a >= b and a <= c)
end
function clearOutputs()
    for i = 1, 32, 1 do
        outputNumbers[i] = 0
    end
end
function setOutputs()
    for i = 1, 32, 1 do
        output.setNumber(i, outputNumbers[i])
    end
end
function setOutputToVector(startChannel, vector)
	outputNumbers[startChannel], outputNumbers[startChannel + 1], outputNumbers[startChannel + 2] = vector:get()
end
---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty("Spin Time", 9)
simulator:setProperty("Spin Correction", 4)
simulator:setProperty("Minimum Distance", 9)
simulator:setProperty("Maximum Distance", 9)
onLBSimulatorTick = function(simulator, ticks)
    screenConnection = simulator:getTouchScreen(1)
    sfirstClick = screenConnection.isTouched and 1000000 or 0
    ssecondClick = screenConnection.isTouched and 1000000 or 0
    sfirstClick = sfirstClick + screenConnection.touchX + screenConnection.touchY * 1000
    ssecondClick = ssecondClick + screenConnection.touchX + screenConnection.touchY * 1000
    local screenConnection = simulator:getTouchScreen(1)
    simulator:setInputBool(1, screenConnection.isTouched)
    simulator:setInputNumber(3, screenConnection.touchX)
    simulator:setInputNumber(7, sfirstClick)
end
---@endsection
require('Extended_Vector_Math')
require('Custom_Binary_Output')

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

spinCounter = 0
spin = 0
facing = 0
filterMassValues =
{
    12, 13, --Player (Technically 12.5)
    20,   --Lifesaver
    25,   --Player
    30,
    35,   --Fire Ext Prop
    50,   --Pallet
    80,   --Barrel
    100,  --Fluid Crate, Propane, Large Propane
    112, -- Small Fuel Gantry
    125,  --Tool Cart
    175,  --Large Cart
    300,  --Large Chest
    347,  --Gas Gantry
    397, -- Coal Gantry
    400,  --Loot Crate
    2499, --Container
    2500  --Tree
}

excludeMasses = {}

for index, value in ipairs(filterMassValues) do
    excludeMasses[value] = true
end

PI = math.pi
PI2 = PI*2

oldFacings = {}

function onTick()
    outputBits = {}
    outputBoolBits = {}

    spinCounter = (spinCounter + 1)%spinTime
    spin = (spinCounter/spinTime) - 0.5
    facing = spin * PI2
    manage_list(oldFacings, facing, spinCorrection)

    for i = 0, 7 do
        local distance, targetPosition = input.getNumber(i*4+1), newVector()
        mass = floor(distance * input.getNumber(i*4+2) + 0.5)
        if not excludeMasses[mass] and distance >= minDist and distance <= maxDist then
            local elevation, azimuth = input.getNumber(i*4+3)*PI2, input.getNumber(i*4+4)*PI2
            azimuth = math.asin(math.sin(azimuth)/math.cos(elevation))
            targetPosition:set(distance, oldFacings[1] + azimuth, elevation)
            targetPosition:toCartesian()
            targetPosition.z = targetPosition.z - 0.5
        end
        local xb, yb, zb, mb = {}, {}, {}, {}
        floatToBinary(targetPosition.x, 4, 24, 0, xb) --floatToBinary(targetPosition.x, 5, 24, outputBits)
        floatToBinary(targetPosition.y, 4, 24, 0, yb) --floatToBinary(targetPosition.y, 5, 24, outputBits)
        floatToBinary(targetPosition.z, 4, 24, 0, zb) --floatToBinary(targetPosition.z, 5, 24, outputBits)
        floatToBinary(mass, 4, 13, -4, mb, 1) --floatToBinary(mass, 6, 7, outputBits)
        joinTables(outputBits, xb, 1, 28)
        joinTables(outputBits, mb, 1, 4)
        joinTables(outputBits, yb, 1, 28)
        joinTables(outputBits, mb, 5, 8)
        joinTables(outputBits, zb, 1, 28)
        joinTables(outputBits, mb, 9, 12)
        joinTables(outputBoolBits, mb, 13, 16)
        --5, 23 + 5, 5 == 752/(768 + 32) (6 extra per target)
    end
    output.setNumber(1, spin)

    bitsCompleted = 0
    for i = 9, 32 do
        output.setNumber(i, binaryToOutput(outputBits))
    end
    for i = 1, 32 do
        output.setBool(i, outputBoolBits[i])
    end
end

function joinTables(tableA, tableB, startIndex, endIndex)
    for index = startIndex, endIndex do
        tableA[#tableA+1] = tableB[index]
    end
end

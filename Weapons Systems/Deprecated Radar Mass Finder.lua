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
spinCounter = 0
spin = 0
facing = 0
specialMassValues =
{
    12.5, --Player
    20,   --Lifesaver
    25,   --Player
    35,   --Fire Ext Prop
    50,   --Pallet
    80,   --Barrel
    100,  --Fluid Crate, Propane, Large Propane
    125,  --Tool Cart
    175,  --Large Cart
    300,  --Large Chest
}
massRanges =
{
    {24.9, 25.1}, --Player, 1
    {490, 500},  --Prop, 2
    {500, 1000}, --Ultra Light Vehicle, 3
    {1000, 2498}, --4
    {2502, 5000}, --5
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
outputNumbers = {}
PI = math.pi
PI2 = PI*2
oldFacings = {}
function onTick()
    spinCounter = (spinCounter + 1)%spinTime
    spin = (spinCounter/spinTime) - 0.5
    facing = spin * PI2
    manage_list(oldFacings, facing, spinCorrection)
    clearOutputs()
    massNumber = 0
    for i = 0, 7 do
        local distance = input.getNumber(i*4+1)
        local mass = distance * input.getNumber(i*4+2)
        if mass >= minMass and distance > minDist and distance < maxDist then
            local elevation, azimuth = input.getNumber(i*4+3)*PI2, input.getNumber(i*4+4)*PI2
            azimuth = math.asin(math.sin(azimuth)/math.cos(elevation))
            local targetPosition = newExtendedVector(distance, oldFacings[1] + azimuth, elevation)
            targetPosition:toCartesian()
            setOutputToVector(i*3+7, targetPosition)
            for massIndex, massRange in ipairs(massRanges) do
                if inRange(mass, massRange[1], massRange[2]) then
                    massNumber = massNumber + massIndex * (100^(7-i))
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
	return (a > b and a < c)
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
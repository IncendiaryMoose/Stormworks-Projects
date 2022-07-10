---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
simulator:setProperty('Minimum Distance', 60)
simulator:setProperty('Maximum Distance', 3000)
simulator:setProperty('Weapons Range', 1500)
simulator:setProperty('Autoshoot Distance', 800)
onLBSimulatorTick = function(simulator, ticks)

end
---@endsection
require("Rotation_Vector_Math")
require("In_Out")

minDist = property.getNumber('Minimum Distance')
maxDist = property.getNumber('Maximum Distance')
vehiclePosition = newRotatableVector()
vehicleRotation = newRotatableVector()
PI = math.pi
PI2 = PI*2
function onTick()
    clearOutputs()
    time = input.getNumber(4)
    vehiclePosition:set(input.getNumber(8), input.getNumber(12), input.getNumber(16))
    vehicleRotation:set(input.getNumber(20), input.getNumber(24), input.getNumber(28), input.getNumber(32))
    vehicleRotation:setScale(PI2)
    vehicleRotation.y = math.atan(math.sin(vehicleRotation.y), math.sin(vehicleRotation.w))
    if time == 0 then
        for i=0, 7, 1 do
            local targetPosition = newRotatableVector(input.getNumber(i*4+1), input.getNumber(i*4+2)*PI2, input.getNumber(i*4+3)*PI2)
            if targetPosition.x > minDist and targetPosition.x < maxDist then
                targetPosition:toCartesian()
                targetPosition:rotate3D(vehicleRotation)
                targetPosition:setAdd(targetPosition, vehiclePosition)
                setOutputToVector(i*3+1, targetPosition)
                outputBools[i*3+1] = true
            end
        end
    end
    setOutputToVector(25, vehiclePosition)
    setOutputs()
end
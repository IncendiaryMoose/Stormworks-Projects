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
require('In_Out')

PI = math.pi
PI2 = PI*2

directTargetPosition = newVector()
aziTargetPosition = newVector()
addTargetPosition = newVector()
aziAddTargetPosition = newVector()

vehiclePosition = newVector()
vehicleRotation = newVector()

function onTick()
    clearOutputs()
    vehiclePosition:set(getInputVector(6))
    vehicleRotation:set(getInputVector(9))
    rYaw = input.getNumber(12) * PI2
    local distance = input.getNumber(1)
    local elevation, azimuth = input.getNumber(3)*PI2, input.getNumber(4)*PI2
    azimuth2 = math.asin(math.sin(rYaw)/math.cos(elevation))
    azimuth3 = math.asin(math.sin(azimuth)/math.cos(elevation))

    directTargetPosition:set(distance, rYaw + azimuth, elevation)
    addTargetPosition:set(distance, azimuth2 + azimuth3, elevation)

    directTargetPosition:toCartesian()
    addTargetPosition:toCartesian()

    addTargetPosition.z = addTargetPosition.z - 0.5

    directTargetPosition:rotate3D(vehicleRotation)
    directTargetPosition:setAdd(vehiclePosition)

    addTargetPosition:rotate3D(vehicleRotation)
    addTargetPosition:setAdd(vehiclePosition)

    azimuth = math.asin(math.sin(azimuth)/math.cos(elevation))

    aziTargetPosition:set(distance, rYaw + azimuth, elevation)
    aziAddTargetPosition:set(distance, rYaw + azimuth, elevation)

    aziTargetPosition:toCartesian()
    aziAddTargetPosition:toCartesian()

    aziAddTargetPosition.z = aziAddTargetPosition.z - 0.5

    aziTargetPosition:rotate3D(vehicleRotation)
    aziTargetPosition:setAdd(vehiclePosition)

    aziAddTargetPosition:rotate3D(vehicleRotation)
    aziAddTargetPosition:setAdd(vehiclePosition)

    setOutputToVector(1, directTargetPosition)
    setOutputToVector(4, addTargetPosition)
    setOutputToVector(7, aziTargetPosition)
    setOutputToVector(10, aziAddTargetPosition)

    setOutputs()

end

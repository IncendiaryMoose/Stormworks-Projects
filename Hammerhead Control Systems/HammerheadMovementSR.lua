---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
target = 0
targetspeed = 0
simulator:setProperty('Autopilot Distance Threshold',100)
simulator:setProperty('X-P',1)
simulator:setProperty('Y-P',1)
onLBSimulatorTick = function(simulator, ticks)
    -- this function is called by the simulator, JUST before the in-game tick runs
    --   so you can have inputs that change over time, etc.
    --   e.g. simulating the altitude of your helicopter, or whatever else
    targetspeed = targetspeed + (math.random() - 0.5)/10
    targetspeed = targetspeed/2
    target = target + targetspeed
    simulator:setInputNumber(1, 0)
    simulator:setInputNumber(2, 0)
    simulator:setInputNumber(11, 0)
    simulator:setInputNumber(12, 0)
    simulator:setInputNumber(13, 0)

    -- wrap every 10 seconds (600 ticks), then check if we're above 300 ticks (5 seconds)
    if ticks  > 200 then
        simulator:setInputNumber(9, 0)
        simulator:setInputNumber(10, 0)
    end
end
---@endsection

moving = false
numbers = {}
bools = {}
function onTick()
    for i = 1, 4, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    if sorta_equal(numbers[1],0,2) and sorta_equal(numbers[2],0,2) then
        moving = false
    end
    if not (sorta_equal(numbers[3],0,0.1) and sorta_equal(numbers[4],0,0.1)) then
        moving = true
    end
    output.setBool(1,moving)
end

function sorta_equal(a,b,e)
    return (math.abs(a-b)<e)
end
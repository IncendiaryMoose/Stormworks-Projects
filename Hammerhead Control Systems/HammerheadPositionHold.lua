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
    simulator:setInputNumber(9, -10)
    simulator:setInputNumber(10, 0)
    simulator:setInputNumber(11, 0)
    simulator:setInputNumber(12, 0)
    simulator:setInputNumber(13, 0.4)

    -- wrap every 10 seconds (600 ticks), then check if we're above 300 ticks (5 seconds)
    if ticks  > 200 then
        simulator:setInputNumber(9, 0)
        simulator:setInputNumber(13, 0.4)
    end
end
---@endsection

PID = {
    proportional_gain = 0,
    proportional = 0,
    integral_gain = 0,
    integral = 0,
    max_integral = 0,
    derivitive_gain = 0,
    derivitive = 0,
    previous_error = 0,
    setpoint = 0,
    process_variable = 0,
    error = 0,
    output = 0,
    max_value = 0,
    startup = true
}
function PID:CreateNew(proportional_gain,integral_gain,derivitive_gain,max_integral,max_derivitive,max_value)
    return {
    proportional_gain = proportional_gain,
    proportional = 0,
    integral_gain = integral_gain,
    integral = 0,
    max_integral = max_integral,
    derivitive_gain = derivitive_gain,
    derivitive = 0,
    max_derivitive = max_derivitive,
    previous_error = 0,
    setpoint = 0,
    process_variable = 0,
    error = 0,
    output = 0,
    max_value = max_value,
    startup = true,
    Update = function (self,setpoint,process_variable)
        self.setpoint = setpoint
        self.process_variable = process_variable
        self.error = self.setpoint - self.process_variable
        self.proportional = self.error * self.proportional_gain
        self.integral = self.integral + self.error * self.integral_gain
        if self.max_integral ~= 0 then
            self.integral = clamp(self.integral, -self.max_integral, self.max_integral)
        end
        if self.startup then
            self.derivitive = 0
        else
            self.derivitive = (self.error - self.previous_error ) * self.derivitive_gain
        end
        if self.max_derivitive ~= 0 then
            self.derivitive = clamp(self.derivitive,-self.max_derivitive,self.max_derivitive)
        end
        self.previous_error = self.error
        self.output = self.proportional + self.integral + self.derivitive
        if self.max_value ~= 0 then
            self.output = clamp(self.output, -self.max_value, self.max_value)
        end
        self.startup = false
        return self.output
    end
    }
end

xHoldPID = PID:CreateNew(property.getNumber('X-P'),property.getNumber('X-I'),property.getNumber('X-D'),property.getNumber('P-I-Max'),property.getNumber('P-D-Max'),1)
yHoldPID = PID:CreateNew(property.getNumber('Y-P'),property.getNumber('Y-I'),property.getNumber('Y-D'),property.getNumber('P-I-Max'),property.getNumber('P-D-Max'),1)
APThreshold = property.getNumber('Autopilot Distance Threshold')
numbers = {}
bools = {}
targetX = 0
targetY = 0
gpsX = 0
gpsY = 0
xError = 0
yError = 0
correctedX = 0
correctedY = 0
xThrottle = 0
yThrottle = 0
distance = 0
direction = 0
heading = 0
APHeading = 0
headingError = 0
pi2 = math.pi * 2
startup = 0
auto = false
function onTick()
    for i = 1, 32, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    gpsX = numbers[9]
    gpsY = numbers[10]
    heading = numbers[13] * pi2
    if bools[2] or auto then
        auto = true
        if bools[3] then
            targetX = numbers[17]
            targetY = numbers[18]
        else
            targetX = numbers[14]
            targetY = numbers[15]
        end
    elseif bools[1] or startup < 60 then
        targetX = numbers[9]
        targetY = numbers[10]
        if startup < 60 then
            startup = startup + 1
        end
    end
    xError = targetX - gpsX
    yError = targetY - gpsY
    distance = len(xError,yError)
    direction = math.atan(xError,yError)
    APHeading = direction/pi2
    headingError = direction + heading
    if bools[1] then
        correctedY = numbers[2] * numbers[3] * 10
        correctedY = numbers[1] * numbers[3] * 10
    else
        if distance > APThreshold then
            auto = true
            correctedX = numbers[2] * numbers[3] * 10
        else
            auto = false
            correctedX = math.sin(headingError) * distance
        end
        correctedY = math.cos(headingError) * distance
    end
    xHoldPID:Update(correctedX,numbers[11])
    yHoldPID:Update(correctedY,numbers[12])
    output.setNumber(1,xHoldPID.output)
    output.setNumber(2,yHoldPID.output)
    output.setNumber(3,distance)
    output.setNumber(4,-APHeading)
    output.setNumber(5,targetX)
    output.setNumber(6,targetY)
    output.setBool(1,auto)
end

function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
function len(a,b)
    return (a^2+b^2)^0.5
end
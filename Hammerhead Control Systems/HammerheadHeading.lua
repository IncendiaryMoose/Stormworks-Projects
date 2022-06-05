---@section _SIMULATOR_ONLY_
simulator:setScreen(1, "9x5")
target = 0
targetspeed = 0
simulator:setProperty('Autopilot Distance Threshold',100)
simulator:setProperty('X-P',1)
simulator:setProperty('H-P',1)
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
    simulator:setInputNumber(13, 0)
    simulator:setInputNumber(32, 0.0)

    -- wrap every 10 seconds (600 ticks), then check if we're above 300 ticks (5 seconds)
    if ticks  > 100 then
        simulator:setInputNumber(13, 0.1)
        simulator:setInputNumber(32, -0.4)
        simulator:setInputNumber(10, 0)
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
headingPID = PID:CreateNew(property.getNumber('H-P'),property.getNumber('H-I'),property.getNumber('H-D'),property.getNumber('H-I-Max'),property.getNumber('H-D-Max'),1)
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
prevDistance = 0
distanceDeltas = {}
avgDistanceDelta = 0
timeToTarget = 0
direction = 0
heading = 0
APHeading = 0
headingError = 0
targetHeading = 0
steering = 0
driveThrottle = 0
strafeThrottle = 0
sensetivity = 0
pi2 = math.pi * 2
startup = 0
auto = false
onOff = false
function onTick()
    for i = 1, 32, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    onOff = bools[4]
    gpsX = numbers[9]
    gpsY = numbers[10]
    heading = numbers[13]
    steering = numbers[4]
    driveThrottle = numbers[1]
    strafeThrottle = numbers[2]
    sensetivity = numbers[3]
    timeToTarget = 0
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
    end
    if startup < 60 then
        targetHeading = heading
        startup = startup + 1
    end
    xError = targetX - gpsX
    yError = targetY - gpsY
    distance = len(xError,yError)
    direction = math.atan(xError,yError)
    APHeading = direction/pi2
    headingError = direction + heading * pi2
    if bools[1] then
        correctedX = strafeThrottle * sensetivity * 10
        correctedY = driveThrottle * sensetivity * 10
    else
        if distance > APThreshold then
            auto = true
            correctedX = strafeThrottle * sensetivity * 10
        else
            auto = false
            correctedX = math.sin(headingError) * distance
        end
        correctedY = math.cos(headingError) * distance
    end
    if auto then
        if math.abs(driveThrottle) > 0.1 or math.abs(strafeThrottle) > 0.1 then
            auto = false
        end
        distanceDeltas = manage_list(distanceDeltas,prevDistance-distance,25)
        prevDistance = distance
        avgDistanceDelta = avg_list(distanceDeltas)
        timeToTarget = distance/avgDistanceDelta/60
        targetHeading = -APHeading
    elseif math.abs(steering) > 0.01 then
        targetHeading = heading-(steering/250*sensetivity)
    end
    if onOff then
        rollover = ((heading-targetHeading+0.5)%1)-0.5
        headingPID:Update(rollover,numbers[21])
        xHoldPID:Update(correctedX,numbers[11])
        yHoldPID:Update(correctedY,numbers[12])
        output.setNumber(1,xHoldPID.output)
        output.setNumber(2,yHoldPID.output)
        output.setNumber(4,headingPID.output)
    else
        output.setNumber(1,0)
        output.setNumber(2,0)
        output.setNumber(4,0)
    end
    output.setNumber(3,distance)
    output.setNumber(5,targetX)
    output.setNumber(6,targetY)
    output.setNumber(7,targetHeading)
    output.setNumber(8,timeToTarget)
    output.setBool(1,auto)
end

function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
function map_value(value,currentMin,currentMax,newMin,newMax)
    currentRange = currentMax - currentMin
    newRange = newMax - newMin
    return (((value-currentMin)/currentRange)*newRange+newMin)
end
function remap_list(list,currentMin,currentMax,newMin,newMax)
    listout = {}
    for j, item in ipairs(list) do
        table.insert(listout,map_value(item,currentMin,currentMax,newMin,newMax))
    end
    return listout
end
function manage_list(self, item, maxItems)
	table.insert(self, item)
	if #self > maxItems then
		table.remove(self, 1)
	end
	return self
end
function getRange(list)
    currentMin = math.huge
    currentMax = -math.huge
    for j, item in ipairs(list) do
        if item < currentMin then
            currentMin = item
        end
        if item > currentMax then
            currentMax = item
        end
    end
    if math.abs(currentMin) > math.abs(currentMax) then
        currentMax = currentMin+math.abs(currentMin)*2
    else
        currentMin = currentMax-math.abs(currentMax)*2
    end
    return {currentMin - 0.1, currentMax + 0.1}
end
function len(a,b)
    return (a^2+b^2)^0.5
end
function avg_list(list)
	total = 0
	for i, j in ipairs(list) do
		total = total + j
	end
	return total/#list
end
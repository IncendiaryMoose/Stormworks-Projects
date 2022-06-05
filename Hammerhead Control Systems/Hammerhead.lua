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
    speed = 0,
    speed_error = 0,
    setpoint = 0,
    process_variable = 0,
    error = 0,
    output = 0,
    max_value = max_value,
    startup = true,
    offset = 0,
    power_offset = 0,
    Update = function (self,setpoint,process_variable)
        self.setpoint = setpoint + self.offset
        self.speed = process_variable - self.process_variable
        self.process_variable = process_variable
        self.error = (self.setpoint - self.process_variable)/10
        self.speed_error = self.error - self.speed
        self.proportional = self.speed_error * self.proportional_gain
        self.integral = self.integral + self.speed_error * self.integral_gain
        if self.max_integral ~= 0 then
            self.integral = clamp(self.integral, -self.max_integral, self.max_integral)
        end
        if self.startup then
            self.derivitive = 0
        else
            self.derivitive = (self.speed_error - self.previous_error ) * self.derivitive_gain
        end
        if self.max_derivitive ~= 0 then
            self.derivitive = clamp(self.derivitive, -self.max_derivitive, self.max_derivitive)
        end
        self.previous_error = self.speed_error
        self.output = self.proportional + self.integral + self.derivitive + self.power_offset
        if self.max_value ~= 0 then
            self.output = clamp(self.output, -self.max_value, self.max_value)
        end
        self.startup = false
        return self.output
    end
    }
end
altitude_pids = {}
for i = 1, 8, 1 do
    altitude_pids[i] = PID:CreateNew(property.getNumber('Alt-P'),property.getNumber('Alt-I'),property.getNumber('Alt-D'),property.getNumber('Alt-I-Max'),property.getNumber('Alt-D-Max'),property.getNumber('Alt-Max'))
end
altitude_pids[1].offset = -3.25
altitude_pids[5].offset = -3.25
altitude_pids[1].power_offset = 0.3
altitude_pids[2].power_offset = 0.4
altitude_pids[3].power_offset = 0.4
altitude_pids[4].power_offset = 0.4
altitude_pids[5].power_offset = 0.3
altitude_pids[6].power_offset = 0.4
altitude_pids[7].power_offset = 0.4
altitude_pids[8].power_offset = 0.4
numbers = {}
bools = {}
average_altitude = 0
on = false
motors = 0
function onTick()
    for i = 1, 32, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    average_altitude = ((numbers[1]+3.25)+(numbers[2]+3.25)+numbers[7]+numbers[8])/4
    for i,pid in ipairs(altitude_pids) do
		pid:Update(clamp(numbers[32],average_altitude-10,average_altitude+10),numbers[i])
	end
    output.setNumber(1,altitude_pids[1].output)
    output.setNumber(2,clamp(numbers[30]/altitude_pids[1].output,-0.125,0.2))
    output.setNumber(3,(numbers[29]+(numbers[31]/16))/altitude_pids[1].output)

    output.setNumber(4,altitude_pids[2].output)
    output.setNumber(5,numbers[30]/altitude_pids[2].output)
    output.setNumber(6,numbers[31]/altitude_pids[2].output)

    output.setNumber(7,altitude_pids[3].output)
    output.setNumber(8,numbers[30]/altitude_pids[3].output)
    output.setNumber(9,(-numbers[29]+(numbers[31]/4))/altitude_pids[3].output)

    output.setNumber(10,altitude_pids[4].output)
    output.setNumber(11,numbers[30]/altitude_pids[4].output)
    output.setNumber(12,-numbers[29]/altitude_pids[4].output)

    output.setNumber(13,altitude_pids[5].output)
    output.setNumber(14,clamp(numbers[30]/altitude_pids[5].output,-0.125,0.2))
    output.setNumber(15,(-numbers[29]-(numbers[31]/16))/altitude_pids[5].output)

    output.setNumber(16,altitude_pids[6].output)
    output.setNumber(17,numbers[30]/altitude_pids[6].output)
    output.setNumber(18,-numbers[31]/altitude_pids[6].output)

    output.setNumber(19,altitude_pids[7].output)
    output.setNumber(20,numbers[30]/altitude_pids[7].output)
    output.setNumber(21,(numbers[29]-(numbers[31]/4))/altitude_pids[7].output)

    output.setNumber(22,altitude_pids[8].output)
    output.setNumber(23,numbers[30]/altitude_pids[8].output)
    output.setNumber(24,numbers[29]/altitude_pids[8].output)

    output.setNumber(32,average_altitude)
    if bools[1] then
        on = true
        motors = 1
    else
        on = false
        motors = 0
    end
    output.setNumber(25,motors)
end

function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
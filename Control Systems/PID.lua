function CreateNewPID(proportional_gain,integral_gain,derivitive_gain,max_integral,max_derivitive,max_value)
    return {
    proportional_gain = proportional_gain,
    proportional = 0,
    integral_gain = integral_gain,
    integral = 0,
    max_integral = max_integral,
    derivitive_gain = derivitive_gain,
    derivitive = 0,
    max_derivitive = max_derivitive,
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
        self.derivitive = (self.previous_error and ((self.error - self.previous_error ) * self.derivitive_gain)) or 0
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
function CreateNewVelocityPID(proportional_gain,integral_gain,derivitive_gain,max_integral,max_derivitive,max_value)
    return {
    proportional_gain = proportional_gain,
    proportional = 0,
    integral_gain = integral_gain,
    integral = 0,
    max_integral = max_integral,
    derivitive_gain = derivitive_gain,
    derivitive = 0,
    max_derivitive = max_derivitive,
    speed = 0,
    speed_error = 0,
    setpoint = 0,
    process_variable = 0,
    error = 0,
    output = 0,
    max_value = max_value,
    power_offset = 0,
    Update = function (self,setpoint,process_variable)
        self.setpoint = setpoint
        self.speed = process_variable - self.process_variable
        self.process_variable = process_variable
        self.error = (self.setpoint - self.process_variable)/15
        self.speed_error = self.error - self.speed
        self.proportional = self.speed_error * self.proportional_gain
        self.integral = self.integral + self.speed_error * self.integral_gain
        if self.max_integral ~= 0 then
            self.integral = clamp(self.integral, -self.max_integral, self.max_integral)
        end
        self.derivitive = (self.previous_error and ((self.speed_error - self.previous_error ) * self.derivitive_gain)) or 0
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
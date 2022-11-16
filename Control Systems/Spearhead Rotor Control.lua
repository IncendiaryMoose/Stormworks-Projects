-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection

PI = math.pi
PI2 = PI * 2

newVector = function (x, y, z, w)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        w = w or 0,
        set = function (self, a, b, c, d)
            self.x = a or self.x
            self.y = b or self.y
            self.z = c or self.z
            self.w = d or self.w
        end,
        setAdd = function (self, other)
            self:set(self.x + other.x, self.y + other.y, self.z + other.z)
        end,
        setScaledAdd = function (self, other, scalar)
            self:set(self.x + other.x * scalar, self.y + other.y * scalar, self.z + other.z * scalar)
        end,
        setSubtract = function (self, other)
            self:set(self.x - other.x, self.y - other.y, self.z - other.z)
        end,
        setScale = function (self, scalar)
            self:set(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)
        end,
        magnitude = function (self)
            return (self.x^2 + self.y^2 + self.z^2)^0.5
        end,
        distanceTo = function (self, other)
            return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
        end,
        toCartesian = function (self)
            self:set(self.x * math.sin(self.y) * math.cos(self.z), self.x * math.cos(self.y) * math.cos(self.z), self.x * math.sin(self.z))
        end,
        rotate3D = function (self, rotation, transposed)
            local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
            if transposed then
                self:set(
                    self.x*(cz*cy-sz*sx*sy) + self.y*(sz*cy+cz*sx*sy) + self.z*(-cx*sy),
                    self.x*(-sz*cx) + self.y*(cz*cx) + self.z*(sx),
                    self.x*(cz*sy+sz*sx*cy) + self.y*(sz*sy-cz*sx*cy) + self.z*(cx*cy)
                )
            else
                self:set(
                    self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
                    self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
                    self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
                )
            end
        end,
        get = function (self)
            return self.x, self.y, self.z
        end,
        clone = function (self)
            return newVector(self.x, self.y, self.z)
        end,
        copy = function (self, other)
            self:set(other.x, other.y, other.z)
        end,
        exists = function (self)
            return self.x ~= 0 or self.y ~= 0 or self.z ~= 0 or self.w ~= 0
        end
    }
end

outputNumbers = {}
outputBools = {}

function clearOutputs()
    for i = 1, 32, 1 do
        outputNumbers[i] = 0
        outputBools[i] = false
    end
end

function setOutputs()
    for i = 1, 32, 1 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end

function setOutputToVector(startChannel, vector)
	outputNumbers[startChannel], outputNumbers[startChannel + 1], outputNumbers[startChannel + 2] = vector:get()
end

function getInputVector(startChannel)
	return input.getNumber(startChannel), input.getNumber(startChannel + 1), input.getNumber(startChannel + 2), input.getNumber(startChannel + 3)
end

function max(a, b)
    return a > b and a or b
end

function min(a, b)
    return a < b and a or b
end

function clamp(a, b, c)
    return min(max(a, c), b)
end

function sign(n)
    return (n >= 0 and 1) or -1
end

function outputRotor(startChannel, collective, p, r, pMax, rMax)
    outputNumbers[startChannel] = collective
    outputNumbers[startChannel + 1] = -collective
    outputNumbers[startChannel + 2] = collective * sign(velocity.y) * liftFlapRange
    outputNumbers[startChannel + 3] = clamp(p * sign(collective), -pMax, pMax)
    outputNumbers[startChannel + 4] = clamp(p * -sign(collective), -pMax, pMax)
    outputNumbers[startChannel + 5] = clamp(r * sign(collective), -rMax, rMax)
    outputNumbers[startChannel + 6] = clamp(r * -sign(collective), -rMax, rMax)
end

seat = newVector()

vehiclePosition = newVector()
previousVehiclePosition = newVector()
vehicleVelocity = newVector()

vehicleRotation = newVector()


function onTick()
    onOff = input.getBool(1)

    seat:set(getInputVector(1))

    vehiclePosition:set(getInputVector(5))
    vehicleVelocity:copy(vehiclePosition)
    vehicleVelocity:setSubtract(previousVehiclePosition)
    previousVehiclePosition:copy(vehiclePosition)

    vehicleRotation:set(getInputVector(8))
end

function onDraw()
    screen.drawCircle(16,16,5)
end

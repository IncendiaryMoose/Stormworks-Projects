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
    simulator:setScreen(1, "9x5")
    simulator:setProperty("Max Memory", 10)

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


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require('Extended_Vector_Math')
maxMemory = property.getNumber('Max Memory')
tickCorrection = property.getNumber('Tick Correction')
sampleAge = property.getNumber('Sample Age')
function newVectorList(initial)
    return {
        memory = {
            {value = initial:clone(), timeStamp = 0}
        },
        differenceFrom = function (self, fromValue)
            local memCount, difference, toValue = #self.memory, newExtendedVector()
            fromValue = self.memory[memCount - fromValue]
            toValue = self.memory[memCount]
            if fromValue and toValue and fromValue.value:exists() then
                difference:setSubtract(toValue.value, fromValue.value)
                difference:setScale(1/(toValue.timeStamp - fromValue.timeStamp))
            end
            return difference:clone()
        end,
        newValue = function (self, value, timeStamp)
            self.current:copy(value)
            self.predicted:copy(value)
            manage_list(self.memory, {value = value:clone(), timeStamp = timeStamp}, maxMemory)
        end,
        current = initial:clone(),
        predicted = initial:clone()
    }
end
function newTarget(position, mass, ID)
    return {
        ID = ID,
        mass = mass,
        totalAge = 0,
        updateAge = 0,
        distance = 0,
        position = newVectorList(position),
        velocity = newVectorList(newExtendedVector()),
        acceleration = newVectorList(newExtendedVector()),
        jerk = newVectorList(newExtendedVector()),
        update = function (self, referencePosition)
            self:positionInTicks(self.updateAge)
            if referencePosition then
                self.distance = self.position.predicted:distanceTo(referencePosition)
            end
            self.totalAge = self.totalAge + 1
            self.updateAge = self.updateAge + 1
        end,
        refresh = function (self, newPosition)
            self.position:newValue(newPosition, self.totalAge)
            self.velocity:newValue(self.position:differenceFrom(sampleAge), self.totalAge)
            self.acceleration:newValue(self.velocity:differenceFrom(sampleAge), self.totalAge)
            self.jerk:newValue(self.acceleration:differenceFrom(sampleAge), self.totalAge)
            self.updateAge = 0
        end,
        positionInTicks = function (self, ticks)
            ticks = ticks + tickCorrection
            self.jerk.predicted:copy(self.jerk.current)
            self.acceleration.predicted:copy(self.acceleration.current)
            self.velocity.predicted:copy(self.velocity.current)
            self.position.predicted:copy(self.position.current)
            local accelerationCorrection = self.jerk.current:clone()
            accelerationCorrection:setScale(0.5)
            self.acceleration.predicted:setAdd(self.acceleration.predicted, accelerationCorrection)
            local velocityCorrection = self.acceleration.predicted:clone()
            velocityCorrection:setScale(0.5)
            self.velocity.predicted:setAdd(self.velocity.predicted, velocityCorrection)
            self.velocity.predicted:setScale(ticks)
            self.acceleration.predicted:setScale((ticks^2)/2)
            self.jerk.predicted:setScale((ticks^3)/6)
            self.position.predicted:setAdd(self.position.predicted, self.velocity.predicted)
            self.position.predicted:setAdd(self.position.predicted, self.acceleration.predicted)
            self.position.predicted:setAdd(self.position.predicted, self.jerk.predicted)
        end
    }
end
function manage_list(listToManage, itemToAdd, maxItems)
	table.insert(listToManage, itemToAdd)
	if #listToManage > maxItems then
		table.remove(listToManage, 1)
	end
end
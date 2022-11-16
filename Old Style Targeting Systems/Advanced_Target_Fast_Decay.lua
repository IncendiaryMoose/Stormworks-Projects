-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

tickCorrection = property.getNumber('Delay')
sampleAge = property.getNumber('Sample')
accelerationDecay = 1 - property.getNumber('Accel')
jerkDecay = 1 - property.getNumber('Jerk')
maxPrediction = property.getNumber('Max Ref')
function newVectorList(initial)
    return {
        memory = {
            {value = initial:clone(), timeStamp = 0}
        },
        differenceFrom = function (self, fromValue)
            local memCount, difference, toValue = #self.memory, newVector()
            fromValue = self.memory[memCount - fromValue]
            toValue = self.memory[memCount]
            if fromValue and toValue and fromValue.value:exists() then
                difference:copy(toValue.value)
                difference:setScaledAdd(fromValue.value, -1)
                difference:setScale(1/(toValue.timeStamp - fromValue.timeStamp))
            end
            return difference:clone()
        end,
        newValue = function (self, value, timeStamp)
            self.current:copy(value)
            self.predicted:copy(value)
            table.insert(self.memory, {value = value:clone(), timeStamp = timeStamp})
            if #self.memory > sampleAge + 1 then
                table.remove(self.memory, 1)
            end
        end,
        current = initial:clone(),
        predicted = initial:clone()
    }
end
function newTarget(position, mass, class)
    return {
        mass = mass,
        class = class,
        totalAge = 0,
        updateAge = 0,
        distance = 1,
        position = newVectorList(position),
        velocity = newVectorList(newVector()),
        acceleration = newVectorList(newVector()),
        jerk = newVectorList(newVector()),
        update = function (self, referencePosition)
            self:positionInTicks(math.min(self.updateAge, maxPrediction))
            self.distance = self.position.predicted:distanceTo(referencePosition)
            self.elevationAngle = math.asin((self.position.predicted.z-referencePosition.z)/self.distance)
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

            --self.acceleration.predicted:setScaledAdd(self.jerk.current, 0.5)
            --self.velocity.predicted:setScaledAdd(self.acceleration.predicted, 0.5)

            self.position.predicted:setScaledAdd(self.velocity.predicted, ticks)
            self.position.predicted:setScaledAdd(self.acceleration.predicted, ticks^2/(2*(ticks*accelerationDecay + 1)))
            self.position.predicted:setScaledAdd(self.jerk.predicted, ticks^3/(6*(ticks*jerkDecay + 1)))
        end
    }
end
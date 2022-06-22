require("Vector_Math")
PI = math.pi
PI2 = PI*2
finalCount = 0
tickCorrection = property.getNumber('Tick Correction')
oldTargetGroup = {}
newTargetGroup = {}
function manage_list(listToManage, itemToAdd, maxItems)
	table.insert(listToManage, itemToAdd)
	if #listToManage > maxItems then
		table.remove(listToManage, 1)
	end
end
function newVectorData(initial)
    return {
        current = initial:clone(),
        memory = {},
        average = initial:clone(),
        previous = initial:clone(),
        predicted = initial:clone(),
        update = function (self, dataToUse, timeScale)
            if dataToUse then
                self.current:setSubtract(dataToUse.average, dataToUse.previous)
                self.current:setScale(1/timeScale)
            end
            manage_list(self.memory, self.current:clone(), maxMemory)
            self.average:set(HMA_vector_list(self.memory))
            self.predicted:copy(self.average)
            if dataToUse then
                dataToUse.previous:copy(dataToUse.average)
            end
        end
    }
end
function makeTarget(position)
    return {
        distanceDelta = 0,
        position = newVectorData(position),
        velocity = newVectorData(newVector()),
        acceleration = newVectorData(newVector()),
        ID = string.format('%.2f',position.x),
        age = 1,
        updateTarget = function(self)
            if self.updated then
                --[[
                if self.age > refreshThreshold then
                    self.position.memory = {}
                    self.velocity.memory = {}
                    self.acceleration.memory = {}
                end
                ]]
                --self.position.current:setAdd(self.position.current, self.position.predicted)
                --self.position.current:setScale(0.5)
                self.position:update()
                self.position.predicted:copy(self.position.current)
                self.velocity:update(self.position, self.age)
                self.acceleration:update(self.velocity, self.age)
                for j = 1, tickCorrection, 1 do
                    self.velocity.predicted:setAdd(self.velocity.predicted, self.acceleration.average)
                    self.position.predicted:setAdd(self.position.predicted, self.velocity.predicted)
                end
                self.age = 0
                self.updated = false
            end

            self.speed = self.velocity.average:magnitude()
            if self.speed > velocityThreshold then
                self.velocity.predicted:setAdd(self.velocity.predicted, self.acceleration.average)
                self.position.predicted:setAdd(self.position.predicted, self.velocity.predicted)
            end
            self.verticalPlacement = self.position.predicted.z - vehiclePosition.z
            self.distance = self.position.current:distanceTo(vehiclePosition)
            self.distanceDelta = (self.distance - self.position.predicted:distanceTo(vehiclePosition) + self.distanceDelta)/2
            self.timeToImpact = self.distance/self.distanceDelta
            self.verticalPlacement = math.asin(self.verticalPlacement/self.distance)/PI2
            self.threat = self.distance/1.5-self.speed*60
            self.threat = (self.distanceDelta > 0 and self.threat + self.timeToImpact) or (1000+self.threat)
            self.age = self.age + 1
        end
    }
end
function trackTargets()
    matches = {}
    newTargetGroup = {}
	for i=1, 24, 3 do
		if input.getBool(i) then
			local newPosition = newVector(getInputVector(i))
			table.insert(newTargetGroup,newPosition)
			for j, oldTarget in pairs(oldTargetGroup) do
				local positionDifference, distToFactor = oldTarget.position.predicted:distanceTo(newPosition), vehiclePosition:distanceTo(newPosition)
				if positionDifference < maxError + oldTarget.speed * speedFactor + distToFactor * distanceFactor + oldTarget.age * ageFactor then
					table.insert(matches, {matchDistance = positionDifference, ID1 = #newTargetGroup, ID2 = j})
				end
			end
		end
	end
	table.sort(matches, function (a, b) return a.matchDistance < b.matchDistance end)
	for i, match in ipairs(matches) do
		newTarget = newTargetGroup[match.ID1]
		oldTarget = oldTargetGroup[match.ID2]
		if newTarget and not oldTarget.updated then
			oldTarget.position.current:copy(newTarget)
			oldTarget.updated = true
			newTargetGroup[match.ID1] = nil
		end
	end
	for i, newTarget in pairs(newTargetGroup) do
        local targetToAdd = makeTarget(newTarget)
		oldTargetGroup[targetToAdd.ID] = targetToAdd
	end
	targetCount = 0
	targetThreats = {}
	for i, oldTarget in pairs(oldTargetGroup) do
		if oldTarget.age > maxAge then
			oldTargetGroup[i] = nil
			goto targetRemoved
		end
		oldTarget:updateTarget()
		targetCount = targetCount + 1
        table.insert(targetThreats, {threat = oldTarget.threat, ID = oldTarget.ID, verticalPlacement = oldTarget.verticalPlacement})
		::targetRemoved::
	end
	table.sort(targetThreats, function (a, b)
		return a.threat < b.threat
	end)
	finalCount = targetCount
end
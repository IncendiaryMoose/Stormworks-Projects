require("Vector_Math")
PI = math.pi
PI2 = PI*2
finalCount = 0
tickCorrection = property.getNumber('Tick Correction')
oldTargetGroup = {}
newTargetGroup = {}
function getMass(index)
    return math.floor(massNumber/(100^(8-index)))%100
end
function newVectorData(initial)
    return {
        current = initial:clone(),
        previous = initial:clone(),
        predicted = initial:clone(),
        update = function (self, dataToUse, timeScale)
            if dataToUse then
                self.current:setSubtract(dataToUse.current, dataToUse.previous)
                self.current:setScale(1/timeScale)
            end
            self.predicted:copy(self.current)
            if dataToUse then
                dataToUse.previous:copy(dataToUse.current)
            end
        end
    }
end
function makeTarget(position, mass)
    return {
        distanceDelta = 0,
        position = newVectorData(position),
        velocity = newVectorData(newVector()),
        acceleration = newVectorData(newVector()),
        jerk = newVectorData(newVector()),
        ID = string.format('%.2f',position.x),
        age = 1,
        mass = mass,
        updateTarget = function(self)
            if self.updated then
                self.position:update()
                self.position.predicted:copy(self.position.current)
                self.velocity:update(self.position, self.age)
                self.acceleration:update(self.velocity, self.age)
                self.jerk:update(self.acceleration, self.age)
                self.age = 0
                self.updated = false
            end

            self.speed = self.velocity.predicted:magnitude()
            if self.age > 0 and self.speed > velocityThreshold then
                --self.acceleration.predicted:setAdd(self.acceleration.predicted, self.jerk.current)
                self.velocity.predicted:setAdd(self.velocity.predicted, self.acceleration.predicted)
                self.acceleration.predicted:setScale(0.75)
                self.position.predicted:setAdd(self.position.predicted, self.velocity.predicted)
            end
            self.verticalPlacement = self.position.predicted.z - vehiclePosition.z
            self.distance = self.position.current:distanceTo(vehiclePosition)
            self.distanceDelta = (self.distance - self.position.predicted:distanceTo(vehiclePosition) + self.distanceDelta)/2
            self.timeToImpact = self.distance/self.distanceDelta
            self.verticalPlacement = math.asin(self.verticalPlacement/self.distance)/PI2
            self.horizontalPlacement = (math.atan(self.position.predicted.x - vehiclePosition.x, self.position.predicted.y - vehiclePosition.y)/PI2) + vehicleYaw
            self.threat = self.distance/1.5-self.speed*60
            self.threat = (self.distanceDelta > 0 and self.threat + self.timeToImpact) or (1000+self.threat)
            self.age = self.age + 1
        end
    }
end
sections = {{-0.5, -0.25}, {-0.25, -0.25}, {0, -0.25}, {0.25, -0.25}, {-0.5, 0.25}, {-0.25, 0.25}, {0, 0.25}, {0.25, 0.25}}
sectionTargets = {}
function trackTargets()
    matches = {}
    newTargetGroup = {}
	for i = 1, 24, 3 do
		if input.getBool(i) then
			local newPosition = newVector(getInputVector(i))
            local newMass = getMass((i+2)/3)
			table.insert(newTargetGroup, {mass = newMass, position = newPosition:clone()})
			for j, oldTarget in pairs(oldTargetGroup) do
				local positionDifference, distToFactor = oldTarget.position.predicted:distanceTo(newPosition), vehiclePosition:distanceTo(newPosition)
				if oldTarget.mass == newMass and positionDifference < clamp(maxError + oldTarget.speed * speedFactor + distToFactor * distanceFactor + oldTarget.age * ageFactor, 1, 150) then
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
			oldTarget.position.current:copy(newTarget.position)
			oldTarget.updated = true
			newTargetGroup[match.ID1] = nil
		end
	end
	for i, newTarget in pairs(newTargetGroup) do
        local targetToAdd = makeTarget(newTarget.position, newTarget.mass)
		oldTargetGroup[targetToAdd.ID] = targetToAdd
	end
	targetCount = 0
    sectionTargets = {}
	for i, oldTarget in pairs(oldTargetGroup) do
		if oldTarget.age > maxAge then
			oldTargetGroup[i] = nil
			goto targetRemoved
		end
		oldTarget:updateTarget()
		targetCount = targetCount + 1
        if oldTarget.mass >= 3 then
            table.insert(sectionTargets, {ID = oldTarget.ID, mass = oldTarget.mass, distance = oldTarget.distance})
        end
		::targetRemoved::
	end
    table.sort(sectionTargets, function (a, b) return a.distance - a.mass*5 < b.distance - b.mass*5 end)
	finalCount = targetCount
end
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end
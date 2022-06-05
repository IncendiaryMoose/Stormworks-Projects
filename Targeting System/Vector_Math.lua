MA_vector_list = function (list, startPoint)
    local total, weight = newVector(), 0
    for i, j in ipairs(list) do
        if i >= startPoint then
            weight = weight + i*2
            j = j:clone()
            j:setScale(i*2)
            total:setAdd(total, j)
        end
    end
    total:setScale(1/weight)
    return total:clone()
end
HMA_vector_list = function (list)
    local fulltotal, halftotal, sqrttotal = MA_vector_list(list, 1), MA_vector_list(list, math.floor((#list)/2 + 0.5)), MA_vector_list(list, #list-math.floor((#list)^0.5 + 0.5))
    halftotal:setScale(2)
    halftotal:setSubtract(halftotal, fulltotal)
    halftotal:setAdd(halftotal, sqrttotal)
    halftotal:setScale(0.5)
    return halftotal:get()
end
newVector = function (x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        set = function (self, a, b, c)
            self.x = a
            self.y = b
            self.z = c or self.z
        end,
        setAdd = function (self, vecA, vecB)
            self:set(vecA.x + vecB.x, vecA.y + vecB.y, vecA.z + vecB.z)
        end,
        setSubtract = function (self, vecA, vecB)
            self:set(vecA.x - vecB.x, vecA.y - vecB.y, vecA.z - vecB.z)
        end,
        setScale = function (self, scalar)
            self:set(self.x * scalar, self.y * scalar, self.z * scalar)
        end,
        magnitude = function (self)
            return (self.x^2 + self.y^2 + self.z^2)^0.5
        end,
        distanceTo = function (self, other)
            return ((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5
        end,
        get = function (self)
            return self.x, self.y, self.z
        end,
        clone = function (self)
            return newVector(self.x, self.y, self.z)
        end,
        copy = function (self, other)
            self:set(other.x, other.y, other.z)
        end
    }
end
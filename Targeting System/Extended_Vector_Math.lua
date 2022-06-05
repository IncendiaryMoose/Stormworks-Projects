newExtendedVector = function (x, y, z, w)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        w = w or 0,
        set = function (self, a, b, c, d)
            self.x = a
            self.y = b
            self.z = c or self.z
            self.w = d or self.w
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
            return newExtendedVector(self.x, self.y, self.z)
        end,
        copy = function (self, other)
            self:set(other.x, other.y, other.z)
        end,
        exists = function (self)
            return self.x ~= 0 or self.y ~= 0 or self.z ~= 0 or self.w ~= 0
        end
    }
end
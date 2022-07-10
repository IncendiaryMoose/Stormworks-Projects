newRotatableVector = function (x, y, z, w)
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
        setAdd = function (self, vecA, vecB)
            self:set(vecA.x + vecB.x, vecA.y + vecB.y, vecA.z + vecB.z)
        end,
        setSubtract = function (self, vecA, vecB)
            self:set(vecA.x - vecB.x, vecA.y - vecB.y, vecA.z - vecB.z)
        end,
        setScale = function (self, scalar)
            self.x = self.x * scalar
            self.y = self.y * scalar
            self.z = self.z * scalar
            self.w = self.w * scalar
        end,
        get = function (self)
            return self.x, self.y, self.z
        end,
        clone = function (self)
            return newRotatableVector(self.x, self.y, self.z)
        end,
        copy = function (self, other)
            self:set(other.x, other.y, other.z)
        end,
        distanceTo = function (self, other)
            return (((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2)^0.5)
        end,
        toCartesian = function (self)
            self.x, self.y, self.z = self.x * math.sin(self.y) * math.cos(self.z), self.x * math.cos(self.y) * math.cos(self.z), self.x * math.sin(self.z)
        end,
        rotate3D = function (self, rotation)
            local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
            self.x, self.y, self.z =
            self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
            self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
            self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
        end
    }
end
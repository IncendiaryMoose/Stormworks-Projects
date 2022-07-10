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
        toCartesian = function (self)
            self.x, self.y, self.z = self.x * math.sin(self.y) * math.cos(self.z), self.x * math.cos(self.y) * math.cos(self.z), self.x * math.sin(self.z)
        end,
        rotate3D = function (self, rotation)
            local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
            self.x, self.y, self.z =
            self.x*(cz*cy-sz*sx*sy) + self.y*(-sz*cx) + self.z*(cz*sy+sz*sx*cy),
            self.x*(sz*cy+cz*sx*sy) + self.y*(cz*cx) + self.z*(sz*sy-cz*sx*cy),
            self.x*(-cx*sy) + self.y*(sx) + self.z*(cx*cy)
        end,
        unRotate3D = function (self, rotation)
            local sx, sy, sz, cx, cy, cz = math.sin(rotation.x), math.sin(rotation.y), math.sin(rotation.z), math.cos(rotation.x), math.cos(rotation.y), math.cos(rotation.z)
            self.x, self.y, self.z =
            self.x*(cz*cy-sz*sx*sy) + self.y*(sz*cy+cz*sx*sy) + self.z*(-cx*sy),
            self.x*(-sz*cx) + self.y*(cz*cx) + self.z*(sx),
            self.x*(cz*sy+sz*sx*cy) + self.y*(sz*sy-cz*sx*cy) + self.z*(cx*cy)
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
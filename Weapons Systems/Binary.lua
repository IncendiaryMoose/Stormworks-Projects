function intToBinary(num, bits)
    local remainder = num
    local result = {}
    local bitCount = 0
    while remainder > 0 or bitCount < bits do
        table.insert(result, remainder%2 == 1)
        remainder = remainder//2
        bitCount = bitCount + 1
    end
    return result
end
function binaryToInt(binary)
    local result = 0
    for i, bit in ipairs(binary) do
        if bit then
            result = result + 2^(i-1)
        end
    end
    return result
end
function getBinaryInput(startChannel, endChannel)
    local result = 0
    for i = 0, endChannel-startChannel, 1 do
        local bit = input.getBool(i+startChannel)
        if bit then
            result = result + 2^(i)
        end
    end
    return result
end
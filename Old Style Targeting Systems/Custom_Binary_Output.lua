-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

-- Chars to beat: 560

floor = math.floor
log = math.log
abs = math.abs

function max(a, b)
    return a > b and a or b
end

function binaryToOutput(binaryTable)
    bitsCompleted = bitsCompleted + 1
    local exponent, sign, mantissa = 0, binaryTable[bitsCompleted] and -1 or 1

    for bitIndex = 1, 8 do
        bitsCompleted = bitsCompleted + 1
        exponent = binaryTable[bitsCompleted] and exponent + 2 ^ (8 - bitIndex) or exponent
    end

    mantissa = exponent > 0 and 1 or 0
    for bitIndex = 1, 23 do
        bitsCompleted = bitsCompleted + 1
        mantissa = binaryTable[bitsCompleted] and mantissa + 1 / 2 ^ bitIndex or mantissa
    end

    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    return mantissa * sign * 2 ^ max(exponent - 127, -126)
end

function floatToBinary(float, exponentBits, mantissaBits, bias, binaryTable, unsigned)

    binaryTable[#binaryTable + 1] = float < 0 -- Sign bit
    float = abs(float) -- Sign is no longer needed, and would cause problems

    local exponent, startIndex, mantissa, factor = floor(log(float, 2)), #binaryTable - (unsigned and 1 or 0) -- Determine what exponent is needed, and how much to offset it (based on the bits allocated to it)

    mantissa = (float / 2 ^ max(exponent, -bias + 1))%1 -- Also known as the significand

    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    exponent = max(exponent + bias, 0)
    for bitIndex = exponentBits, 1, -1 do
        binaryTable[startIndex + bitIndex] = exponent%2 == 1
        exponent = exponent // 2
    end

    for bitIndex = 1, mantissaBits - 1 do
        factor = 1 / 2 ^ bitIndex
        binaryTable[#binaryTable + 1] = mantissa >= factor
        mantissa = mantissa%factor
    end

    if mantissa >= 1 / 2 ^ mantissaBits then -- If the next digit would have been a 1, then rounding up will improve accuracy
        for bitIndex = 0, mantissaBits - 2 do
            binaryTable[#binaryTable - bitIndex] = not binaryTable[#binaryTable - bitIndex]
            if binaryTable[#binaryTable - bitIndex] then break end
        end
    end
end
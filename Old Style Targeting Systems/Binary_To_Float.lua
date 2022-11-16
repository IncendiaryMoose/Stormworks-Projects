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

floor, log, abs = math.floor, math.log, math.abs

function max(a, b)
    return a >= b and a or b
end

function binaryToFloat(binaryTable, exponentBits, mantissaBits)
    local bias = 2 ^ exponentBits / 2 - 1

    local exponent = 0
    for bitIndex = 1, exponentBits do
        if binaryTable[bitsCompleted + bitIndex + 1] then
            exponent = exponent + 2 ^ (exponentBits - bitIndex)
        end
    end

    local mantissa = exponent > 0 and 1 or 0
    for bitIndex = 1, mantissaBits - 1 do
        if binaryTable[bitsCompleted + bitIndex + exponentBits + 1] then
            mantissa = mantissa + 1 / (2 ^ bitIndex)
        end
    end

    exponent = max(exponent - bias, -bias + 1)

    local float = 2 ^ exponent * mantissa * (binaryTable[bitsCompleted + 1] and -1 or 1)

    bitsCompleted = bitsCompleted + exponentBits + mantissaBits
    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    return float
end

function floatToBinary(float, exponentBits, mantissaBits, binaryTable)
    local bias = 2 ^ exponentBits / 2 - 1

    local exponent = max(floor(log(abs(float), 2)), -bias)
    local mantissa = abs(float) / 2 ^ max(exponent, -bias + 1)

    --print(string.format('Exponent = %.0f\nMantissa = %.16f\nValue = %.64f', exponent, mantissa, float))

    binaryTable[#binaryTable + 1] = float < 0
    local binaryStart = #binaryTable
    local remainder = exponent + bias
    for bitIndex = 1, exponentBits do
        binaryTable[binaryStart + exponentBits + 1 - bitIndex] = remainder%2 == 1
        remainder = remainder // 2
    end

    remainder = mantissa%1
    for bitIndex = 1, mantissaBits - 1 do
        local factor = 1 / (2 ^ bitIndex)
        binaryTable[binaryStart + bitIndex + exponentBits] = remainder >= factor
        remainder = remainder%factor
    end
end
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


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection

function angleBetween(a, b)
	return (b - a + 0.5)%1 - 0.5
end

suffixes = {
    'K',
    'M',
    'B',
    'T',
    'Q',
    'S'
}

function numformat(n, l)
    local remainingLength, prefix, suffix, suffixSize = n < 0 and l - 1 or l, n < 0 and '-' or '', '', 0

    n = math.abs(n)
    local intLength = math.floor(math.log(n, 10)) + 1

    if intLength > remainingLength then
        suffixSize = math.floor((intLength - remainingLength)/3 + 1)
        suffix = suffixes[suffixSize]

        n = n/(1000^suffixSize)
        intLength = intLength - suffixSize*3

        if intLength < 1 then
            n = string.format('%.1f', n)
            n = string.gsub(n, '%d', '', 1)
            return prefix..n..suffix
        end

        remainingLength = remainingLength - 1
    end

    if intLength < remainingLength - 1 then
        return string.format(prefix..'%.'..math.max(remainingLength - 1 - intLength, 0)..'f'..suffix, n)
    end

    return string.format(prefix..'%0'..remainingLength..'d'..suffix, math.floor(n))
end

print(numformat(-22, 4))
print(numformat(22, 4))
print(numformat(0, 4))
print(numformat(1234.5, 4))
print(numformat(1234.5, 5))
print(numformat(1234.5, 6))
print(numformat(1234.5, 7))
print(numformat(1222456.5, 4))
print(numformat(-13124456.5, 4))
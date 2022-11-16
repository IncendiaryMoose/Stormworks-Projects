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
    simulator:setProperty('Working Threshold', 15)
    simulator:setProperty('Value Groups', '[n5,n6,n7][n15][n16][n17]')

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
        for k = 1, 10 do
            simulator:setInputBool(k, not simulator:getIsClicked(k))
            simulator:setInputNumber(k, 1 - simulator:getSlider(k))
        end
    end;
end
---@endsection
--[[
    Front = [n1,n2,n3][n4,n5,n6,n7,n8,n9,b1][b2][b3][n10,n11,n12,n13,n14,n15,n16,b4][b5]
        Front rotor = [n1,n2,n3]
        Front Battery/Sensors = [n4,n5,n6,n7,n8,n9,b1]
        Left Condenser = [b2]
        Right Condenser = [b3]
        Rear Battery/Generator = [n10,n11,n12,n13,n14,n15,n16,b4]
        Cabin = [b5]

    Mid = [n1,b1][n2,n3,n4,n5,n6,n7][n8,n9,n10,n11,n12,n13][b2][b3]
        Core = [n1,b1]
        Upper Turret = [n2,n3,n4,n5,n6,n7]
        Lower Turret = [n8,n9,n10,n11,n12,n13]
        Left Turbine = [b2]
        Right Turbine = [b3]

    Rear = [b2][b3][n1,n2,n3,n4,n5,n6,n7,n8,n9,n10][n19][n20][n11,n12,n13,n14,n15,n16,n17,n18,b1]
        Left Engine = [b2]
        Right Engine = [b3]
        Main Battery = [n1,n2,n3,n4,n5,n6,n7,n8,n9,n10]
        Left Rotor = [n19]
        Right Rotor = [n20]
        Reactor = [n11,n12,n13,n14,n15,n16,n17,n18,b1]

    Rear 2 = [n1,n2,n3,n4,n5,n6,n7,n8,n9,n10][n11,n12,n13,n14,n15,n16,n17,n18,n19,n20][b1][b2]
        Left Capacitor = [n1,n2,n3,n4,n5,n6,n7,n8,n9,n10]
        Right Capacitor = [n11,n12,n13,n14,n15,n16,n17,n18,n19,n20]
        Left Engine = [b1]
        Right Engine = [b2]
]]
workingThreshold = property.getNumber('Working Threshold')
valueGroups = property.getText('Value Groups')
groups = {}
values = {}
for group in string.gmatch(valueGroups, '%b[]') do
    table.insert(groups, {{}, {}, workingThreshold})
    for pre, num in string.gmatch(group, '(n)(%d+)') do
        table.insert(groups[#groups][1], tonumber(num))
    end
    for pre, num in string.gmatch(group, '(b)(%d+)') do
        table.insert(groups[#groups][2], tonumber(num))
    end
end

function onTick()
    for groupIndex, group in ipairs(groups) do
        if group[3] < workingThreshold then
            group[3] = group[3] + 1
        end
        for indexIndex, index in ipairs(group[1]) do
            if input.getNumber(index) == 0 then
                group[3] = 0
                goto broken
            end
        end
        for indexIndex, index in ipairs(group[2]) do
            if not input.getBool(index) then
                group[3] = 0
                goto broken
            end
        end
        ::broken::
        output.setBool(groupIndex, group[3] < workingThreshold)
    end
end

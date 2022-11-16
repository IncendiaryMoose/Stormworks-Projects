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
    simulator:setScreen(1, "9x5")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        simulator:setInputBool(1, simulator:getIsToggled(1))
        simulator:setInputBool(2, simulator:getIsToggled(2))
        simulator:setInputBool(3, simulator:getIsToggled(3))
        simulator:setInputBool(4, simulator:getIsToggled(4))
        simulator:setInputBool(5, simulator:getIsToggled(5))
        simulator:setInputBool(6, simulator:getIsToggled(6))
        simulator:setInputBool(7, simulator:getIsToggled(7))
        simulator:setInputBool(8, simulator:getIsToggled(8))
    end;
end
---@endsection
require('In_Out')
columnSpacing = 125
rowSpacing = 7
currentColor = {0, 0, 0, 255}
function setToColor(newColor)
    if currentColor[1] ~= newColor[1] or currentColor[2] ~= newColor[2] or currentColor[3] ~= newColor[3] or currentColor[4] ~= newColor[4] then
        screen.setColor(newColor[1], newColor[2], newColor[3], newColor[4] or 255)
    end
end

ErrorType = 'Error'
InfoType = 'Info'
CancelType = 'Abort'
WarningType = 'Warn'
RequestType = 'Request'
CompleteType = 'Complete'
CriticalType = 'Critical'
SystemSource = 'Sys'
UserSource = 'User'
RemoteSource = 'Remote'

typeNames = {
    InfoType,
    RequestType,
    CompleteType,
    WarningType,
    CriticalType,
    ErrorType,
    CancelType
}

typeColors = {
    Info = {255, 255, 255},
    Request = {0, 100, 200},
    Complete = {0, 150, 0},
    Warn = {255, 255, 0},
    Critical = {255, 255, 255},
    Error = {255, 0, 0},
    Abort = {150, 0, 0}
}

logs = {}
for index, typeName in ipairs(typeNames) do
    logs[typeName] = {}
end
pendingRequests = {}

function newEvent(source, type, item, action)
    local logEntry = {
        source = source,
        type = type,
        item = item,
        action = action,
        text = item..' '..action,
        printableText = '['..source..']['..type..']:'..item..' '..action,
        color = typeColors[type],
        draw = function (self, column, row)
            setToColor(self.color)
            screen.drawText(1 + column*columnSpacing, 1 + row*rowSpacing, self.printableText)
        end
    }
    if type == RequestType then
        local cancledTasks = removeEventByItem(pendingRequests, item)
        for index, cancledTask in ipairs(cancledTasks) do
            newEvent(source, CancelType, cancledTask.item, cancledTask.action)
        end
        table.insert(pendingRequests, 1, logEntry)
    elseif type == CompleteType then
        removeEventByItem(pendingRequests, item)
    end
    table.insert(logs, 1, logEntry)
    table.insert(logs[type], 1, logEntry)
end

function removeEventByItem(eventTable, eventText)
    local removedItems = {}
    for eventIndex, event in ipairs(eventTable) do
        if event.item == eventText then
            table.insert(removedItems, table.remove(eventTable, eventIndex))
        end
    end
    return removedItems
end
numbers = {}
bools = {}
for i = 1, 32 do
    numbers[i] = {
        timer = 0,
        value = 0,
        hasChanged = false
    }
    bools[i] = {
        timer = 0,
        value = false,
        hasChanged = false
    }
end
User = 'User'
System = 'System'
Request = 'Request'
Complete = 'Complete'
Vehicle = 'Vehicle'
Engine = 'Engine'
Weapons = 'Weapons'
Reactor = 'Reactor'
Startup = 'Startup'
Shutdown = 'Shutdown'
Enable = 'Enable'
Disable = 'Disable'
Damaged = 'Damaged'
Repair = 'Repair'
Left = 'Left'
Right = 'Right'
Upper = 'Upper'
Lower = 'Lower'
Gear = 'Gear'
Up = 'Up'
Down = 'Down'
newEvent(UserSource, RequestType, Vehicle, Startup)
newEvent(SystemSource, WarningType, Engine, Damaged)
newEvent(SystemSource, RequestType, Engine, Repair)
newEvent(SystemSource, CompleteType, Engine, Repair)
function onTick()
    clearOutputs()
    for i = 1, 32 do
        local newNum, newBool = input.getNumber(i), input.getBool(i)
        numbers[i].hasChanged = numbers[i].value ~= newNum
        numbers[i].value = newNum
        bools[i].hasChanged = bools[i].value ~= newBool
        bools[i].value = newBool
    end
    sysBatt = numbers[1]
    engineBatt = numbers[2]
    if bools[1].hasChanged then
        newEvent(UserSource, RequestType, Vehicle, bools[1].value and Startup or Shutdown)
    end
    if bools[2].hasChanged then
        newEvent(SystemSource, CompleteType, Vehicle, bools[2].value and Startup or Shutdown)
    end
    if bools[3].hasChanged then
        newEvent(SystemSource, RequestType, Engine, bools[3].value and Startup or Shutdown)
    end
    if bools[4].hasChanged then
        newEvent(SystemSource, CompleteType, Engine, bools[4].value and Startup or Shutdown)
    end
    if bools[5].hasChanged then
        newEvent(SystemSource, RequestType, Gear, bools[5].value and Up or Down)
    end
    if bools[6].hasChanged then
        newEvent(SystemSource, CompleteType, Gear, bools[6].value and Up or Down)
    end
    if bools[7].hasChanged then
        newEvent(UserSource, RequestType, Reactor, bools[7].value and Startup or Shutdown)
    end
    if bools[8].hasChanged then
        newEvent(SystemSource, CompleteType, Reactor, bools[8].value and Startup or Shutdown)
    end
    if bools[9].hasChanged then
        newEvent(UserSource, RequestType, Weapons, bools[9].value and Enable or Disable)
    end
    if bools[10].hasChanged then
        newEvent(SystemSource, CompleteType, Weapons, bools[10].value and Enable or Disable)
    end
    setOutputs()
end

maxLines = 15
function onDraw()
    setToColor({255, 255, 255, 255})
    screen.drawText(1, 1, 'Event Log:')
    screen.drawText(1, 1 + (maxLines + 2)*rowSpacing, 'Pending Requests:')
    for index = 1, maxLines do
        if logs[index] then
            logs[index]:draw(0, index)
        end
        if pendingRequests[index] then
            pendingRequests[index]:draw(0, maxLines + index + 2)
        end
    end
end

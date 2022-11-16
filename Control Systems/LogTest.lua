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
currentColor = {0, 0, 0}
function setToColor(newColor)
    if currentColor[1] ~= newColor[1] or currentColor[2] ~= newColor[2] or currentColor[3] ~= newColor[3] then
        screen.setColor(newColor[1], newColor[2], newColor[3])
        currentColor[1] = newColor[1]
        currentColor[2] = newColor[2]
        currentColor[3] = newColor[3]
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

typeColors = {}
typeColors[InfoType] = {255, 255, 255}
typeColors[RequestType] = {0, 100, 200}
typeColors[CompleteType] = {0, 150, 0}
typeColors[WarningType] = {255, 255, 0}
typeColors[CriticalType] = {255, 255, 255}
typeColors[ErrorType] = {255, 0, 0}
typeColors[CancelType] = {150, 0, 0}
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
        color = (action == Repair and type ~= CompleteType and typeColors[WarningType]) or typeColors[type],
        draw = function (self, column, row)
            setToColor(self.color)
            screen.drawText(46 + column*columnSpacing, 13 + row*rowSpacing, self.printableText)
        end
    }
    if type == RequestType then
        local cancledTasks = removeEventByItem(pendingRequests, item)
        for index, cancledTask in ipairs(cancledTasks) do
            newEvent(source, CancelType, cancledTask.item, cancledTask.action)
        end
        pendingRequests[#pendingRequests+1] = logEntry
    elseif type == CompleteType then
        removeEventByItem(pendingRequests, item)
    end
    logs[#logs+1] = logEntry
    logs[type][#logs[type]+1] = logEntry
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
--newEvent(UserSource, RequestType, Vehicle, Startup)
--newEvent(SystemSource, WarningType, Engine, Damaged)
--newEvent(SystemSource, RequestType, Engine, Repair)
--newEvent(SystemSource, CompleteType, Engine, Repair)
ticks = 1
repairIndex = 0
logRepairs = true
controlIndex = 20
logControls = true
newEvent(SystemSource, RequestType, Reactor, Startup)
function onTick()
    clearOutputs()
    for i = 1, 32 do
        local newNum, newBool = input.getNumber(i), input.getBool(i)
        numbers[i].hasChanged = numbers[i].value ~= newNum
        numbers[i].value = newNum
        bools[i].hasChanged = bools[i].value ~= newBool
        bools[i].value = newBool
    end
    if ticks < 60 then
        ticks = ticks + 1
    else
        if logControls then
            if bools[controlIndex + 1].hasChanged then
                newEvent(UserSource, RequestType, Vehicle, bools[controlIndex + 1].value and Startup or Shutdown)
            end
            if bools[controlIndex + 2].hasChanged then
                newEvent(SystemSource, CompleteType, Vehicle, bools[controlIndex + 2].value and Startup or Shutdown)
            end
            if bools[controlIndex + 3].hasChanged then
                newEvent(SystemSource, RequestType, Engine, bools[controlIndex + 3].value and Startup or Shutdown)
            end
            if bools[controlIndex + 4].hasChanged then
                newEvent(SystemSource, CompleteType, Engine, bools[controlIndex + 4].value and Startup or Shutdown)
            end
            if bools[controlIndex + 5].hasChanged then
                newEvent(SystemSource, RequestType, Gear, bools[controlIndex + 5].value and Down or Up)
            end
            if bools[controlIndex + 6].hasChanged then
                newEvent(SystemSource, CompleteType, Gear, bools[controlIndex + 6].value and Down or Up)
            end
            if bools[controlIndex + 7].hasChanged then
                newEvent(UserSource, RequestType, Reactor, bools[controlIndex + 7].value and Startup or Shutdown)
            end
            if bools[controlIndex + 8].hasChanged then
                newEvent(SystemSource, CompleteType, Reactor, bools[controlIndex + 8].value and Startup or Shutdown)
            end
        end
        if logRepairs then
            if bools[repairIndex + 1].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 1].value and RequestType or CompleteType, 'Front Rotor', Repair)
            end
            if bools[repairIndex + 2].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 2].value and RequestType or CompleteType, 'Front Sensors', Repair)
            end
            if bools[repairIndex + 3].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 3].value and RequestType or CompleteType, 'Left Condenser', Repair)
            end
            if bools[repairIndex + 4].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 4].value and RequestType or CompleteType, 'Right Condenser', Repair)
            end
            if bools[repairIndex + 5].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 5].value and RequestType or CompleteType, 'Generator', Repair)
            end
            if bools[repairIndex + 6].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 6].value and RequestType or CompleteType, 'Turret Loader', Repair)
            end
            if bools[repairIndex + 7].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 7].value and RequestType or CompleteType, 'Upper Turret', Repair)
            end
            if bools[repairIndex + 8].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 8].value and RequestType or CompleteType, 'Lower Turret', Repair)
            end
            if bools[repairIndex + 9].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 9].value and RequestType or CompleteType, 'Left Turbine', Repair)
            end
            if bools[repairIndex + 10].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 10].value and RequestType or CompleteType, 'Right Turbine', Repair)
            end
            if bools[repairIndex + 11].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 11].value and RequestType or CompleteType, 'Left Engine', Repair)
            end
            if bools[repairIndex + 12].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 12].value and RequestType or CompleteType, 'Right Engine', Repair)
            end
            if bools[repairIndex + 13].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 13].value and RequestType or CompleteType, 'Main Battery Bank', Repair)
            end
            if bools[repairIndex + 14].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 14].value and RequestType or CompleteType, 'Left Rotor', Repair)
            end
            if bools[repairIndex + 15].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 15].value and RequestType or CompleteType, 'Right Rotor', Repair)
            end
            if bools[repairIndex + 16].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 16].value and RequestType or CompleteType, Reactor, Repair)
            end
            if bools[repairIndex + 17].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 17].value and RequestType or CompleteType, 'Left Capacitor', Repair)
            end
            if bools[repairIndex + 18].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 18].value and RequestType or CompleteType, 'Right Capacitor', Repair)
            end
            if bools[repairIndex + 19].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 19].value and RequestType or CompleteType, 'Rear Left Engine', Repair)
            end
            if bools[repairIndex + 20].hasChanged then
                newEvent(SystemSource, bools[repairIndex + 20].value and RequestType or CompleteType, 'Rear Right Engine', Repair)
            end
            if bools[29].hasChanged then
                newEvent(UserSource, bools[29].value and RequestType or CompleteType, 'Extinguish Fires', ' ')
            end
            if bools[30].hasChanged then
                newEvent(UserSource, bools[30].value and RequestType or CompleteType, Vehicle, Repair)
            end
            if bools[31].hasChanged then
                newEvent(SystemSource, bools[31].value and RequestType or CompleteType, 'Cabin', Repair)
            end
            if bools[32].hasChanged then
                newEvent(SystemSource, bools[32].value and RequestType or CompleteType, 'Extinguish Fires', ' ')
            end
        end
    end
    setOutputs()
end

maxLines = 12
function onDraw()
    setToColor({255, 255, 255})
    screen.drawText(46, 12, 'Event Log:')
    screen.drawText(46, 12 + (maxLines + 2)*rowSpacing, 'Pending Requests:')
    for index = 0, maxLines - 1 do
        if logs[#logs - index] then
            logs[#logs - index]:draw(0, math.min(#logs, maxLines) - index)
        end
        if pendingRequests[index] then
            pendingRequests[index]:draw(0, maxLines + index + 2)
        end
    end
end

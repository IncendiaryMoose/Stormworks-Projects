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

ticks = 0

function onTick()
    if ticks < 600 then
        ticks = ticks + 1
    else
        cabin = input.getBool(31)
        frontRotor = input.getBool(1)
        frontSensors = input.getBool(2)
        leftCondenser = input.getBool(3)
        rightCondenser = input.getBool(4)
        generator = input.getBool(5)

        turretLoader = input.getBool(6)
        upperTurret = input.getBool(7)
        lowerTurret = input.getBool(8)
        leftTurbine = input.getBool(9)
        rightTurbine = input.getBool(10)

        leftEngine = input.getBool(11)
        rightEngine = input.getBool(12)
        mainBattery = input.getBool(13)
        leftRotor = input.getBool(14)
        rightRotor = input.getBool(15)
        reactor = input.getBool(16)

        leftCapacitor = input.getBool(17)
        rightCapacitor = input.getBool(18)
        rearLeftEngine = input.getBool(19)
        rearRightEngine = input.getBool(20)

        all = input.getBool(30)

        output.setBool(32, mainBattery or leftCapacitor or rightCapacitor or frontSensors or generator)

        leftCapacitor = leftCapacitor or rearLeftEngine
        rightCapacitor = rightCapacitor or rearRightEngine
        reactor = reactor or leftRotor or rightRotor or leftCapacitor or rightCapacitor
        mainBattery = mainBattery or reactor or leftEngine or rightEngine
        turretLoader = turretLoader or upperTurret or lowerTurret or mainBattery or leftTurbine or rightTurbine
        generator = generator or turretLoader
        frontSensors = frontSensors or generator or leftCondenser or rightCondenser
        frontRotor = frontRotor or cabin or frontSensors

        output.setBool(1, frontRotor or all)
        output.setBool(2, frontSensors or all)
        output.setBool(3, leftCondenser or all)
        output.setBool(4, rightCondenser or all)
        output.setBool(5, generator or all)

        output.setBool(6, turretLoader or all)
        output.setBool(7, upperTurret or all)
        output.setBool(8, lowerTurret or all)
        output.setBool(9, leftTurbine or all)
        output.setBool(10, rightTurbine or all)

        output.setBool(11, leftEngine or all)
        output.setBool(12, rightEngine or all)
        output.setBool(13, mainBattery or all)
        output.setBool(14, leftRotor or all)
        output.setBool(15, rightRotor or all)
        output.setBool(16, reactor or all)

        output.setBool(17, leftCapacitor or all)
        output.setBool(18, rightCapacitor or all)
        output.setBool(19, rearLeftEngine or all)
        output.setBool(20, rearRightEngine or all)
        output.setBool(31, cabin or all)
    end
end

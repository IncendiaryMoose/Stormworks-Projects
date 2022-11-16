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

reload = false
loaderUp = false
feed = false
function onTick()
    enabled = input.getBool(1)
    parked = input.getBool(2)
    turretPitch = input.getNumber(1)
    turretYaw = input.getNumber(2)
    leftTurretMag = input.getNumber(3) + input.getNumber(4)
    leftLoaderMag = input.getNumber(5)
    rightTurretMag = input.getNumber(6) + input.getNumber(7)
    rightLoaderMag = input.getNumber(8)
    sliderLock = input.getNumber(9) > 0

    canLoad = leftTurretMag < 150 or rightTurretMag < 150

    needsLoad = leftTurretMag < 2 or rightTurretMag < 2

    feed = reload or leftLoaderMag < 50 or rightLoaderMag < 50

    if (parked and canLoad) or needsLoad then
        reload = true
    end

    if not canLoad then
        reload = false
        loaderUp = false
    end

    if reload then
        if leftLoaderMag > 48 and rightLoaderMag > 48 then
            loaderUp = true
        end
        if leftLoaderMag < 2 or rightLoaderMag < 2 then
            loaderUp = false
        end
    end

    output.setNumber(1, ((loaderUp and (math.abs(yawSpeed(0, turretYaw)) < 0.05) and (math.abs(turretPitch) < 0.05)) and 1) or (sliderLock and 0) or -1)
    output.setBool(1, reload)
    output.setBool(2, feed)
    output.setBool(3, enabled and not reload)
end
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end

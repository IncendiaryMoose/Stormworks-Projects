-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
require('In_Out')
slideLength = property.getNumber('Slide Length')
elevateLength = property.getNumber('Elevate Length')
elevateDist = property.getNumber('Elevate Dist')
slidePower = property.getNumber('Slide Power')
elevatePower = property.getNumber('Elevate Power')
fetchPower = property.getNumber('Fetch Power')
rodLength = property.getNumber('Rod Length')
doorTime = property.getNumber('Door Time') * 60
slideError = 0
elevateError = 0
spinError = 0
stage = -11
releaseTimer = 0
ammoToUse = 1
currentAmmo = 1
currentStore = 0
doorTimer = 0
function onTick()
    clearOutputs()
    slide = 0
    elevate = 0
    spin = 1
    fetch = 0
    connected = input.getBool(1)
    reload = input.getBool(31) or reload
    store = input.getBool(32) or store
    loaderHardpoint = input.getNumber(32)
    slidePosition = input.getNumber(31) - 0.25
    elevatePosition = input.getNumber(30) - 0.25
    spinPosition = input.getNumber(29)*4
    fetchHardpoint = input.getNumber(28)
    fetchPosition = input.getNumber(27) - 0.25
    fetchDepth = input.getNumber(26)
    airlockWater = input.getNumber(24)
    pumpAirlock = airlockWater > 0
    ammoStored = input.getNumber(currentStore + 1) == 1
    ammoTaken = input.getNumber(currentAmmo + 1) == 0
    if reload then
        if stage == -11 then
            outputBools[31] = true
            innerDoor = true
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = -10
            end
        elseif stage == -10 then
            outputBools[31] = true
            fetch = rodLength
            if roughEquals(fetchPosition, rodLength, 0.015) then
                stage = -9
            end
        elseif stage == -9 then
            innerDoor = false
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = -8
            end
        elseif stage == -8 then
            outerDoor = true
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = -7
            end
        elseif stage == -7 then
            fetch = fetchDepth
            if fetchHardpoint == 1 and roughEquals(fetchPosition, fetchDepth, 0.015) then
                stage = -6
            end
        elseif stage == -6 then
            fetch = rodLength
            if roughEquals(fetchPosition, rodLength, 0.015) then
                stage = -5
            end
        elseif stage == -5 then
            outerDoor = false
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                if not pumpAirlock then
                    stage = -4
                end
            end
        elseif stage == -4 then
            innerDoor = true
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = -3
            end
        elseif stage == -3 then
            if roughEquals(fetchPosition, 0, 0.015) then
                stage = -2
            end
        elseif stage == -2 then
            if loaderHardpoint == 1 then
                stage = -1
            end
        elseif stage == -1 then
            outputBools[31] = true
            if fetchHardpoint == 0 then
                stage = 0
            end
        elseif stage == 0 then
            slide = 0
            elevate = 0
            spin = 1
            stage = 1
        elseif stage == 1 then
            slide = slideLength/2
            elevate = 0
            spin = 1
            if roughEquals(slidePosition, slideLength/2, 0.015) then
                stage = 2
            end
        elseif stage == 2 then
            slide = slideLength/2
            elevate = currentStore * elevateDist
            spin = -1
            if roughEquals(spinPosition, -1, 0.05) and roughEquals(elevatePosition, currentStore * elevateDist, 0.015) then
                stage = 3
            end
        elseif stage == 3 then
            slide = slideLength
            elevate = currentStore * elevateDist
            spin = -1
            if ammoStored then
                stage = 4
            end
        elseif stage == 4 then
            outputBools[32] = true
            slide = slideLength
            elevate = currentStore * elevateDist
            spin = -1
            if loaderHardpoint == 0 then
                stage = 5
            end
        elseif stage == 5 then
            slide = slideLength/2
            elevate = currentAmmo * elevateDist
            spin = -1
            if roughEquals(elevatePosition, currentAmmo * elevateDist, 0.015) then
                stage = 6
            end
        elseif stage == 6 then
            slide = slideLength
            elevate = currentAmmo * elevateDist
            spin = -1
            if loaderHardpoint == 1 then
                stage = 7
            end
        elseif stage == 7 then
            outputBools[currentAmmo + 1] = true
            slide = slideLength
            elevate = currentAmmo * elevateDist
            spin = -1
            if ammoTaken then
                stage = 8
            end
        elseif stage == 8 then
            slide = slideLength/2
            elevate = currentAmmo * elevateDist
            spin = -1
            if roughEquals(slidePosition, slideLength/2, 0.015) then
                stage = 9
            end
        elseif stage == 9 then
            slide = slideLength/2
            elevate = 0
            spin = 1
            if roughEquals(elevatePosition, 0, 0.015) and roughEquals(spinPosition, 1, 0.05) then
                stage = 10
            end
        elseif stage == 10 then
            slide = 0
            elevate = 0
            spin = 1
            if roughEquals(slidePosition, 0, 0.015) and fetchHardpoint == 1 then
                stage = 11
            end
        elseif stage == 11 then
            outputBools[32] = true
            fetch = rodLength
            if roughEquals(fetchPosition, rodLength, 0.015) and loaderHardpoint == 0 then
                stage = 12
            end
        elseif stage == 12 then
            innerDoor = false
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = 13
            end
        elseif stage == 13 then
            outerDoor = true
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = 14
            end
        elseif stage == 14 then
            fetch = fetchDepth
            if roughEquals(fetchPosition, fetchDepth, 0.015) then
                stage = 15
            end
        elseif stage == 15 then
            outputBools[31] = true
            fetch = fetchDepth
            if fetchHardpoint == 0 then
                stage = 16
            end
        elseif stage == 16 then
            outputBools[31] = true
            fetch = rodLength
            if roughEquals(fetchPosition, rodLength, 0.015) then
                stage = 17
            end
        elseif stage == 17 then
            outerDoor = false
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                if not pumpAirlock then
                    stage = 18
                end
            end
        elseif stage == 18 then
            innerDoor = true
            fetch = rodLength
            if doorTimer < doorTime then
                doorTimer = doorTimer + 1
            else
                doorTimer = 0
                stage = 19
            end
        elseif stage == 19 then
            if roughEquals(fetchPosition, 0, 0.015) then
                stage = -11
                innerDoor = false
                outerDoor = false
                reload = false
                currentAmmo = currentAmmo + 1
                currentStore = currentStore + 1
            end
        end
    end
    slideError = slidePosition - slide
    elevateError = elevatePosition - elevate
    spinError = spinPosition - spin
    fetchError = fetchPosition - fetch
    outputNumbers[1] = slideError * slidePower
    outputNumbers[2] = elevateError * elevatePower
    outputNumbers[3] = spin
    outputNumbers[4] = fetchError * fetchPower
    outputBools[30] = outerDoor
    outputBools[29] = innerDoor
    outputBools[28] = pumpAirlock
    setOutputs()
end

function roughEquals(a, b, c)
    return(math.abs(a-b) <= c)
end
-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
minTemp = property.getNumber('Min Temp')
maxTemp = property.getNumber('Max Temp')
maxWater = property.getNumber('Max Water')
maxWaterLoss = property.getNumber('Max Water Loss')
standbyPosition = 1.25
doorTimer = 0
function onTick()
    on = input.getBool(1)
    connected = input.getBool(2)
    recv = input.getBool(3)
    door = recv
    if not recv then
        if doorTimer < 120 then
            doorTimer = doorTimer + 1
        else
           disconect = false
        end
    else
        doorTimer = 0
        disconect = true
    end
    mag = input.getBool(4) or recv or disconect
    reactorTemp = input.getNumber(1)
    reactorWater = input.getNumber(2)
    rods = input.getNumber(3) == 1
    sliderPosition = input.getNumber(4) - 0.25
    safe = reactorWater > maxWater - maxWaterLoss
    unsafe = (not safe) and (not connected)
    ready = reactorTemp > minTemp
    if on and safe and rods then
        releaseRods = false
        controlRod = ((reactorTemp - minTemp)/(maxTemp - minTemp))^3
        sliderTarget = 0
        if reactorTemp > maxTemp then
            releaseRods = true
        end
    else
        releaseRods = true
        controlRod = 1
        sliderTarget = standbyPosition
    end
    output.setBool(1, releaseRods)
    output.setBool(2, safe)
    output.setBool(3, unsafe)
    output.setBool(4, ready)
    output.setBool(5, mag)
    output.setBool(6, door)
    output.setBool(7, connected and roughEquals(sliderPosition, standbyPosition, 0.015))
    output.setNumber(1, controlRod)
    output.setNumber(2, (sliderPosition - sliderTarget) * 5)
    output.setNumber(3, sliderPosition)
end

function roughEquals(a, b, c)
    return(math.abs(a-b) <= c)
end
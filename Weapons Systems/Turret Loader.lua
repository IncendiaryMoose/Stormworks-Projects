-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end
reloading = false
slider = 0
yawPivot = 0
pitchPivot = 0
reloadTime = 0
restockTime = 0
previousTurretPitch = 0
turretPitchVelocity = 0
previousTurretYaw = 0
currentTurretYaw = 0
turretYawVelocity = 0
function onTick()
    loaderYaw = (input.getNumber(1))%1
    currentTurretYaw = input.getNumber(2)
    turretYawVelocity = currentTurretYaw - previousTurretYaw
    previousTurretYaw = currentTurretYaw
    turretYaw = (currentTurretYaw+turretYawVelocity*10)%1
    turretPitch = input.getNumber(3)
    turretPitchVelocity = turretPitch - previousTurretPitch
    previousTurretPitch = turretPitch
    turretPitch = turretPitch + turretPitchVelocity*10
    leftMag = input.getNumber(4)
    rightMag = input.getNumber(5)
    if leftMag >= 18 and rightMag >= 18 then
        reloading = true
    elseif leftMag <= 2 or rightMag <= 2 then
        reloading = false
    end
    if reloading then
        restockTime = 0
        reloadTime = reloadTime + 1
		yawPivot = 4*yawSpeed(loaderYaw, 0)
    else
        reloadTime = 0
        restockTime = restockTime + 1
		yawPivot = 4*yawSpeed(loaderYaw, turretYaw)
    end
    if restockTime > 8 then
        slider = -1
        pitchPivot = 0
    else
        slider = 1
        pitchPivot = turretPitch*4
    end
	output.setNumber(1, yawPivot)
    output.setNumber(2, pitchPivot)
    output.setNumber(3, slider)
    output.setBool(1, not reloading)
end
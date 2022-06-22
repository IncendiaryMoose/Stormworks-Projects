-- Author: Incendiary Moose
-- GitHub: <GithubLink>
-- Workshop: https://steamcommunity.com/profiles/76561198050556858/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
require("Clamp")
s = "[-0.5,0.07][-0.35,-0.03][-0.25,-0.03][-0.11,-0.03][0,.06][.11,-.03][.25,-.03][.35,-.03][.5,.07]"
deadZones = {}
for yawPoint, minPitch in string.gmatch(s, "%[([%w.-]+),([%w.-]+)%]") do
	table.insert(deadZones, {tonumber(yawPoint), tonumber(minPitch)})
end
function yawSpeed(a,b)
	return (((b-a+0.5)%1)-0.5)
end
desiredPitch = -0.515
desiredYaw = 1.400001
turretPitch = -0.027
wrappedDesiredYaw = yawSpeed(0, desiredYaw)
		local yawStart, yawEnd, pitchStart, pitchEnd = -1, 1, 0, 0
		for j, deadZone in ipairs(deadZones) do
			local yawPoint, minPitch = deadZone[1], deadZone[2]
			if wrappedDesiredYaw >= yawPoint then
				yawStart = yawPoint
				pitchStart = minPitch
			else
				yawEnd = yawPoint
				pitchEnd = minPitch
				break
			end
		end
		local yawRange, pitchRange = yawEnd - yawStart, pitchEnd - pitchStart
		local yawPos = (wrappedDesiredYaw-yawStart)/yawRange
		local pitchPos = pitchStart + (pitchRange*yawPos)
		desiredPitch = math.max(desiredPitch, pitchPos)
        power = yawSpeed(0, desiredYaw)
print(string.format('Start: %f, End: %f, A: %f, B: %f', yawStart, yawEnd, pitchStart, pitchEnd))
print(string.format('Range: %f, Pos: %f, Pitch: %f, B: %f', yawRange, yawPos, pitchPos, power))
--[[
"Front" [-0.5,0.04][-0.1,-0.04][0,-0.005][0.1,-0.04][0.5,0.04]
"front Lower" [-0.5, 0.05], [-0.25, 0.05], [-0.2, -0.03], [-0.1, -0.03], [0, 0.03], [0.1, -0.03], [0.2, -0.03], [0.25, 0.05], [0.5, 0.05]
"front Lower" [-0.5,0.05][-0.25,0.05][-0.2,-0.03][-0.1,-0.03][0,0.03][0.1,-0.03][0.2,-0.03][0.25,0.05][0.5,0.05]
"rear Lower" [-0.5, -0.03], [-0.31, -0.03], [-0.3, 0.04], [-0.08, 0.04], [-0.06, -0.01], [-0.03, -0.01], [0, 0.04], [0.03, -0.01], [0.06, -0.01], [0.08, 0.04], [0.3, 0.04], [0.31, -0.03], [0.5, -0.03]
"rear Lower" [-.5,-.03][-.31,-.03][-.3,.04][-.08,.04][-.06,-.01][-.03,-.01][0,.04][.03,-.01][.06,-.01][.08,.04][.3,.04][.31,-.03][.5,-.03]
             [-.5,-.03][-.31,-.03][-.3,.04][-.08,.04][-.06,-.01][-.03,-.01][0,.04][.03,-.01][.06,-.01][.08,.04][.3,.04][.31,-.03][.5,-.03]
"Front Side" [-0.5, 0.07], [-0.35, -0.03], [-0.25, -0.03], [-0.11, -0.03], [0, 0.06], [0.11, -0.03], [0.25, -0.03], [0.35, -0.03], [0.5, 0.07]
"Front SIde" [-0.5,0.07][-0.35,-0.03][-0.25,-0.03][-0.11,-0.03][0,0.06][0.11,-0.03][0.25,-0.03][0.35,-0.03][0.5,0.07]
"Rear Side" [-0.5,-0.05][-0.25,0.15][0,0.12][0.25,0.15][0.5,-0.05]
--]]
-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/ID/Bilkokuya/myworkshopfiles/?appid=573090
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Please note, this is an example setup, but as you do not have the MCs it expects - it will NOT "just run"
-- If you are not confident with Lua, it is advised you DO NOT use this feature
-- Simulating multiple MCs has a lot of quirks and you may be making your life harder.
-- Remember: The job of simulation is not replacing the game - it's to make your life easier.

-- After configuring this, you would run it with F6, and it should simulate multiple MCs for you.
-- That said, it is fully supported; hence the lua for the extension is provided for you to edit if needed

require('LifeBoatAPI.Tools.Simulator.MultiSimulatorExtension')
local __multiSim = LifeBoatAPI.Tools.MultiSimulator:new()

-----------LOAD MCS-------------------------------------------------------------------------------
-- set your MCs here
-- LoadMC takes the same parameter as require(...)
-- Order matters, they will draw to screen in this order (last over the top)
local send = __multiSim:loadMC('Bit Setter')
local recv = __multiSim:loadMC("Bit Receiver")

-----------CONFIG----------------------------------------------------------------------------------
-- set which MC should show it's inputs and outputs
__multiSim:setDisplayMC(send)

-- configure how many screens to use
--__multiSim._originalSim.config:configureScreen(1, "9x5", true, false)
--__multiSim._originalSim.config:configureScreen(2, "9x5", true, false)
--converter.onLBSimulatorShouldDraw = function (screenNumber) return screenNumber == 1 end
--targeting.onLBSimulatorShouldDraw = function (screenNumber) return screenNumber == 1 end

for i = 1, 32, 1 do
    recv.__simulator.config:addNumberHandler(i, function() return send.output._numbers[i] end)
    recv.__simulator.config:addBoolHandler(i, function() return send.output._bools[i] end)
end

-----------RUN----------------------------------------------------------------------------------
-- do not remove or edit this
onTick = __multiSim:generateOnTick()
onDraw = __multiSim:generateOnDraw()

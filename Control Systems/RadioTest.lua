-- Author: <Authorname> (Please change this in user settings, Ctrl+Comma)
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
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
compatibleChar = {
    "ended",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
    ".",
    ",",
    ":",
    ";",
    "!",
    "?",
    '"',
    "'",
    " "
}

charMappings = {
    ["a"] = 1,
    ["b"] = 2,
    ["c"] = 3,
    ["d"] = 4,
    ["e"] = 5,
    ["f"] = 6,
    ["g"] = 7,
    ["h"] = 8,
    ["i"] = 9,
    ["j"] = 10,
    ["k"] = 11,
    ["l"] = 12,
    ["m"] = 13,
    ["n"] = 14,
    ["o"] = 15,
    ["p"] = 16,
    ["q"] = 17,
    ["r"] = 18,
    ["s"] = 19,
    ["t"] = 20,
    ["u"] = 21,
    ["v"] = 22,
    ["w"] = 23,
    ["x"] = 24,
    ["y"] = 25,
    ["z"] = 26,
    ["1"] = 27,
    ["2"] = 28,
    ["3"] = 29,
    ["4"] = 30,
    ["5"] = 31,
    ["6"] = 32,
    ["7"] = 33,
    ["8"] = 34,
    ["9"] = 35,
    ["0"] = 36,
    ["."] = 37,
    [","] = 38,
    [":"] = 39,
    [";"] = 40,
    ["!"] = 41,
    ["?"] = 42,
    ['"'] = 43,
    ["'"] = 44,
    [" "] = 45
}

scroll = 0
firstPulse = true
messageList = {}
ended = true
stringCount = 0

outgoingMessage = ""


function onTick()

    receivePulsent = input.getBool(11)
    x = input.getNumber(3)
    y = input.getNumber(4)
    tch = input.getBool(1)
    keyboardIn = input.getNumber(32) + 1
    keyboardPulse = input.getBool(32)

    receiveLetter = input.getNumber(11) + 1
    receivetime = input.getNumber(13)

    receivePulse = receivePulsent and not whatIsThis
    whatIsThis = receivePulsent

	if receivePulsent then
        if firstPulse then
            table.insert(messageList, 1, {message = nil, time = receivetime})
		    messageBuild = compatibleChar[receiveLetter]
            firstPulse = false
		elseif receiveLetter == 1 then
            messageList[1].message = messageBuild
            firstPulse = true
		else
		    messageBuild = messageBuild..compatibleChar[receiveLetter]
        end
	end

	if not (tchdelay or tch) then
	    tchdelay = true
	end

	if TouchTangle(x, y, 81, 1, 13, 13) and tch then
	    scroll = scroll + 1
	end

	if TouchTangle(x, y, 81, 15, 13, 13) and tch then
	    scroll = scroll - 1
	end

	if TouchTangle(x, y, 81, 32, 13, 13) and tch and tchdelay and not writeMessage then
        writeMessage = true
        tchdelay = false
	end

	if TouchTangle(x, y, 0, 0, 8, 8) and tch and tchdelay and writeMessage then
        writeMessage = false
        tchdelay = false
	end

	if TouchTangle(x, y, 8, 0, 22, 8) and tch and tchdelay and writeMessage then
        writeMessage = false
        tchdelay = false
        runSend = true
	end

	if runSend then
		if comeBackOnce then
            comeBackOnce = false
            runSend = false
            outgoingMessage = ""
            output.setBool(11, false)
            output.setBool(1, false)
		end
        length = string.len(outgoingMessage)
        output.setBool(1, true)
        count = count + 1
		if count == 1 then
		    stringCount = stringCount + 1
			if stringCount > length then
                output.setNumber(11, 0)
                output.setBool(11, true)
                comeBackOnce = true
			else
                output.setNumber(11, charMappings[string.sub(outgoingMessage, stringCount, stringCount)])
                output.setBool(11, true)
			end
		elseif count == 2 then
            output.setBool(11, false)
            count = 0
		end
	else
        count = 0
        output.setBool(1, false)
	end
end

function onDraw()
	if hasTouchedEntry then
	    screen.drawTextBox(1, 1, 94, 62, messageList[touchedEntry]["message"])
		if tch and tchdelay then
		    hasTouchedEntry = false
		    tchdelay = false
		end
	elseif writeMessage then
        screen.drawRect(1, 1, 7, 7)
        screen.drawText(2, 2, "X")
        screen.drawRect(9, 1, 21, 7)
        screen.drawText(12, 2, "SND")
        screen.drawTextBox(1, 10, 94, 62, outgoingMessage)
	--[[	
	keyboardIn	
	outgoingMessage 	
	]]
		if keyboardPulse then
			if keyboardIn == 421 then
				if #outgoingMessage > 1 then
				    outgoingMessage = string.sub(outgoingMessage, 0, #outgoingMessage - 1)
				elseif #outgoingMessage == 1 then
				    outgoingMessage = ""
				end
			else
			    outgoingMessage = outgoingMessage..tostring(compatibleChar[math.floor(keyboardIn)])
			end
		end
	else
        screen.drawRect(82,2,12,12)
        screen.drawText(84,5,"UP")
        screen.drawRect(82,16,12,12)
        screen.drawText(84,19,"DN")
        screen.drawRect(82,30,12,12)
        screen.drawText(84,33,"WR")

		if #messageList ~= 0 then
			for i = 1, #messageList do
                if messageList[i].message then
                    offset = i - 1
                    screen.drawRect(2, 2 + scroll + offset * 17, 78, 15)
                    screen.drawText(3, 3 + scroll + offset * 17, string.sub(messageList[i].message, 1, 7))
                    screen.drawText(3, 10 + scroll + offset * 17, "TIME SENT")
                    if TouchTangle(x, y, 1, 1 + scroll + offset * 17, 79, 16) and tch and tchdelay then
                        touchedEntry = i
                        hasTouchedEntry = true
                        tchdelay = false
                    end
                end
            end
		end
	end
end

function TouchTangle(x, y, rectX, rectY, rectW, rectH)
    return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end
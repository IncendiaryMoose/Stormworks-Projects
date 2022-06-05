outputNumbers = {}
outputBools = {}
function clearOutputs()
    for i = 1, 32, 1 do
        outputNumbers[i] = 0
        outputBools[i] = false
    end
end
function setOutputs()
    for i = 1, 32, 1 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end
function setOutputToVector(startChannel, vector)
	outputNumbers[startChannel], outputNumbers[startChannel + 1], outputNumbers[startChannel + 2] = vector:get()
end
function getInputVector(startChannel)
	return input.getNumber(startChannel), input.getNumber(startChannel + 1), input.getNumber(startChannel + 2)
end
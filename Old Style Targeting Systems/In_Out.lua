outputNumbers = {}
outputBools = {}
function clearOutputs()
    for i = 1, 32 do
        outputNumbers[i] = 0
        outputBools[i] = false
    end
end
function setOutputs()
    for i = 1, 32 do
        output.setNumber(i, outputNumbers[i])
        output.setBool(i, outputBools[i])
    end
end
function setOutputToVector(startChannel, vector)
	outputNumbers[startChannel] = vector.x
    outputNumbers[startChannel + 1] = vector.y
    outputNumbers[startChannel + 2] = vector.z
end
function getInputVector(startChannel)
	return input.getNumber(startChannel), input.getNumber(startChannel + 1), input.getNumber(startChannel + 2)
end
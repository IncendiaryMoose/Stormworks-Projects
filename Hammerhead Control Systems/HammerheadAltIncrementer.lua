startup = 0
targetAlt = 0
numbers = {}
bools = {}
function onTick()
    for i = 1, 32, 1 do
        numbers[i] = input.getNumber(i)
        bools[i] = input.getBool(i)
    end
    if bools[1] then
        if startup < 60 then
            targetAlt = numbers[2] + 0.5
            startup = startup + 1
        end
        if numbers[1] > 0.001 or numbers[1] < 0.001 then
            targetAlt = targetAlt + (numbers[1]/90*numbers[3])
        elseif bools[2] then
            targetAlt = numbers[16]
            if bools[3] then
                targetAlt = numbers[19]
            end
        end
    else
        startup = 0
    end
    output.setNumber(1,targetAlt)
end
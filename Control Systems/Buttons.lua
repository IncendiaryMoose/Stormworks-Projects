function inRect(x, y, rectX, rectY, rectW, rectH)
	return x >= rectX and y >= rectY and x < rectX + rectW and y < rectY + rectH
end
function clamp(value, min, max)
    return math.min(math.max(min, value), max)
end
currentColor = {0, 0, 0}
function setToColor(newColor)
    if currentColor[1] ~= newColor[1] or currentColor[2] ~= newColor[2] or currentColor[3] ~= newColor[3] then
        screen.setColor(newColor[1], newColor[2], newColor[3])
        currentColor[1] = newColor[1]
        currentColor[2] = newColor[2]
        currentColor[3] = newColor[3]
    end
end

buttons = {}
progressBars = {}
indicators = {}
function newButton(toggle, x, y, w, h, textColor, text, onColor, offColor)
    return {
        toggle = toggle,
        x = x,
        y = y,
        w = w - 1,
        h = h - 1,
        textColor = textColor,
        text = text,
        onColor = onColor,
        offColor = offColor,
        pressed = false,
        onPercent = 0,
        stateChange = false,
        updateTick = function (self, clicked, wasClicked, clickX, clickY)
            local priorState = self.pressed
            if self.toggle then
                if clicked and not wasClicked and inRect(clickX, clickY, self.x, self.y, self.w, self.h) then
                    self.pressed = not self.pressed
                end
            else
                self.pressed = clicked and inRect(clickX, clickY, self.x, self.y, self.w, self.h)
            end
            self.stateChange = priorState ~= self.pressed
        end,
        updateDraw = function (self)
            setToColor(whiteOn)
            screen.drawRect(self.x, self.y, self.w, self.h)

            if self.pressed then
                setToColor(self.onColor)
            else
                setToColor(self.offColor)
            end

            screen.drawRectF(self.x + 1, self.y + 1, self.w - 1, self.h - 1)

            setToColor(self.textColor)
            screen.drawTextBox(self.x, self.y + 1, self.w, self.h, self.text, 0, 0)
        end
    }
end

function newIndicator(x, y, w, h, textColor, text, onColor, offColor, onText)
    return {
        x = x,
        y = y,
        w = w - 1,
        h = h - 1,
        textColor = textColor,
        text = text,
        onText = onText,
        onColor = onColor,
        offColor = offColor,
        pressed = false,
        update = function (self)

            setToColor(whiteOn)
            screen.drawRect(self.x, self.y, self.w, self.h)

            if self.pressed then
                setToColor(self.onColor)
            else
                setToColor(self.offColor)
            end

            screen.drawRectF(self.x + 1, self.y + 1, self.w - 1, self.h - 1)

            setToColor(self.textColor)
            if self.pressed then
                screen.drawTextBox(self.x, self.y + 1, self.w, self.h, self.onText, 0, 0)
            else
                screen.drawTextBox(self.x, self.y + 1, self.w, self.h, self.text, 0, 0)
            end
        end
    }
end

function newSlider(x, y, w, h, sW, tW, sliderColor, textColor, text, onColor, offColor, slider)
    return {
        x = x,
        y = y,
        x1 = x + tW - 1,
        w = w - 1,
        h = h - 1,
        sW = sW,
        tW = tW,
        sliderColor = sliderColor,
        textColor = textColor,
        text = text,
        onColor = onColor,
        offColor = offColor,
        pressed = false,
        onPercent = 0,
        stateChange = false,
        slider = slider,
        updateTick = function (self, clicked, wasClicked, clickX, clickY)
            local priorState = self.pressed
            if self.slider then
                self.pressed = clicked and inRect(clickX, clickY, self.x1, self.y, self.w, self.h)
            elseif clicked and inRect(clickX, clickY, self.x1, self.y, self.w, self.h) and not wasClicked then
                self.pressed = not self.pressed
            end
            self.stateChange = priorState ~= self.pressed
            self.onPercent = clamp((self.slider and (self.pressed and ((clickX - self.x1 - self.sW/2)/(self.w-3)) or self.onPercent)) or (self.pressed and self.onPercent + 0.1) or (self.onPercent - 0.1), 0, 1)
        end,
        updateDraw = function (self)
            setToColor(whiteOn)
            screen.drawRect(self.x1, self.y + 2, self.w, self.h - 4)
            setToColor(self.offColor)
            screen.drawRectF(self.x1 + 1, self.y + 3, self.w - 1, self.h - 5)

            setToColor(self.onColor)
            screen.drawRectF(self.x1 + 1, self.y + 3, self.onPercent*(self.w - self.sW - 1), self.h - 5)

            setToColor(self.textColor)
            screen.drawTextBox(self.x, self.y + 1, self.tW, self.h, self.text, 0, 0)

            setToColor(self.sliderColor)
            screen.drawRectF(self.x1 + 1 + self.onPercent*(self.w - self.sW - 1), self.y, self.sW, self.h + 1)
        end

    }
end

function newProgressBar(x, y, w, h, sW, sliderColor, textColor, text, onColor, offColor, minValue, maxValue, valueFormat, suffix)
    return {
        x = x,
        y = y,
        w = w - 1,
        h = h - 1,
        sW = sW,
        sliderColor = sliderColor,
        textColor = textColor,
        onColor = onColor,
        offColor = offColor,
        onPercent = 0,
        minValue = minValue,
        maxValue = maxValue,
        valueRange = maxValue - minValue,
        valueFormat = valueFormat,
        text = text..' [%.0f'..(suffix or '')..']',
        update = function (self, value)
            self.onPercent = clamp((value - self.minValue) / self.valueRange, 0, 1)
            setToColor(whiteOn)
            screen.drawRect(self.x, self.y, self.w, self.h)
            setToColor(self.offColor)
            screen.drawRectF(self.x + 1, self.y + 1, self.w - 1, self.h - 1)

            setToColor(self.onColor)
            screen.drawRectF(self.x + 1, self.y + 1, self.onPercent*(self.w - self.sW - 1), self.h - 1)

            setToColor(self.sliderColor)
            screen.drawRectF(self.x + 1 + self.onPercent*(self.w - self.sW - 1), self.y + 1, self.sW, self.h - 1)

            setToColor(self.textColor)
            screen.drawTextBox(self.x + 2, self.y + 1, self.w, self.h, string.format(self.text, value * self.valueFormat), 0, 0)

        end
    }
end
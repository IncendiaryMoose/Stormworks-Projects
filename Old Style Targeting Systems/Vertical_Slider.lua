function newVerticalSlider(x, y, w, h, sH, tH, sliderColor, textColor, text, onColor, offColor, slider)
    return {
        x = x,
        y = y,
        y1 = y + tH - 1,
        w = w - 1,
        h = h - 1,
        sH = sH,
        tH = tH,
        sliderColor = sliderColor,
        textColor = textColor,
        text = text,
        onColor = onColor,
        offColor = offColor,
        pressed = false,
        onPercent = 0,
        stateChange = false,
        slider = slider,
        update = function (self, clicked, wasClicked, clickX, clickY)
            local priorState = self.pressed
            if self.slider then
                self.pressed = clicked and inRect(clickX, clickY, self.x, self.y1, self.w, self.h)
            elseif clicked and inRect(clickX, clickY, self.x, self.y1, self.w, self.h) and not wasClicked then
                self.pressed = not self.pressed
            end
            self.stateChange = priorState ~= self.pressed

            setToColor(whiteOn)
            screen.drawRect(self.x + 2, self.y1, self.w - 4, self.h)
            setToColor(self.offColor)
            screen.drawRectF(self.x + 3, self.y1 + 1, self.w - 5, self.h - 1)

            self.onPercent = clamp((self.slider and (self.pressed and ((clickY - self.y1 - self.sH/2)/(self.h-3)) or self.onPercent)) or (self.pressed and self.onPercent + 0.1) or (self.onPercent - 0.1), 0, 1)

            setToColor(self.onColor)
            screen.drawRectF(self.x + 3, self.y1 + 1, self.w - 5, self.onPercent*(self.h - self.sH - 1))

            setToColor(self.textColor)
            screen.drawTextBox(self.x + 3, self.y, 5, self.tH, self.text, 0, 0)

            setToColor(self.sliderColor)
            screen.drawRectF(self.x, self.y1 + 1 + self.onPercent*(self.h - self.sH - 1), self.w + 1, self.sH)
        end
    }
end
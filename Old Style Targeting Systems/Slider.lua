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
        update = function (self, clicked, wasClicked, clickX, clickY)
            local priorState = self.pressed
            if self.slider then
                self.pressed = clicked and inRect(clickX, clickY, self.x1, self.y, self.w, self.h)
            elseif clicked and inRect(clickX, clickY, self.x1, self.y, self.w, self.h) and not wasClicked then
                self.pressed = not self.pressed
            end
            self.stateChange = priorState ~= self.pressed

            setToColor(whiteOn)
            screen.drawRect(self.x1, self.y + 2, self.w, self.h - 4)
            setToColor(self.offColor)
            screen.drawRectF(self.x1 + 1, self.y + 3, self.w - 1, self.h - 5)

            self.onPercent = clamp((self.slider and (self.pressed and ((clickX - self.x1 - self.sW/2)/(self.w-3)) or self.onPercent)) or (self.pressed and self.onPercent + 0.1) or (self.onPercent - 0.1), 0, 1)

            setToColor(self.onColor)
            screen.drawRectF(self.x1 + 1, self.y + 3, self.onPercent*(self.w - self.sW - 1), self.h - 5)

            setToColor(self.textColor)
            screen.drawTextBox(self.x, self.y + 1, self.tW, self.h, self.text, 0, 0)

            setToColor(self.sliderColor)
            screen.drawRectF(self.x1 + 1 + self.onPercent*(self.w - self.sW - 1), self.y, self.sW, self.h + 1)
        end
    }
end
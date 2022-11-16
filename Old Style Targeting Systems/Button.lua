function newButton(x, y, w, h, boxColor, textColor, text, boxPushColor, textPushColor)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        boxColor = boxColor,
        textColor = textColor,
        text = text,
        boxPushColor = boxPushColor or boxColor,
        textPushColor = textPushColor or textColor,
        pressed = false,
        poked = false,
        update = function (self, clicked, wasClicked, clickX, clickY)
            self.poked = not self.pressed
            if clicked and not wasClicked and inRect(clickX, clickY, self.x, self.y, self.w - 1, self.h - 1) then
                self.pressed = not self.pressed
            end
            self.poked = self.poked and self.pressed
            local boxColorToDraw, textColorToDraw = self.boxColor, self.textColor
            if self.pressed then
                boxColorToDraw = self.boxPushColor
                textColorToDraw = self.textPushColor
            end
            setToColor(boxColorToDraw)
            screen.drawRectF(self.x, self.y + 1, self.w, self.h - 2)
            screen.drawRectF(self.x + 1, self.y, self.w - 2, self.h)
            setToColor(textColorToDraw)
            screen.drawTextBox(self.x + 1, self.y, self.w, self.h, self.text, 0, 0)
        end
    }
end

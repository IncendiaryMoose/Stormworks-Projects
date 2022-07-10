buttons = {}
function newButton(name, toggle, x, y, w, h, boxColor, textColor, text, boxPushColor, textPushColor, pushText)
    buttons[name] = {
        toggle = toggle,
        x = x,
        y = y,
        w = w,
        h = h,
        boxColor = boxColor,
        textColor = textColor,
        text = text,
        boxPushColor = boxPushColor or boxColor,
        textPushColor = textPushColor or textColor,
        pushText = pushText or text,
        pressed = false,
        poked = false,
        update = function (self, clicked, wasClicked, clickX, clickY)
            self.poked = not self.pressed
            if self.toggle then
                if clicked and not wasClicked and inRect(clickX, clickY, self.x, self.y, self.w, self.h) then
                    self.pressed = not self.pressed
                end
            else
                self.pressed = clicked and inRect(clickX, clickY, self.x, self.y, self.w, self.h)
            end
            self.poked = self.poked and self.pressed
            local boxColorToDraw, textColorToDraw, textToDraw = self.boxColor, self.textColor, self.text
            if self.pressed then
                boxColorToDraw = self.boxPushColor
                textColorToDraw = self.textPushColor
                textToDraw = self.pushText
            end
            screen.setColor(boxColorToDraw[1], boxColorToDraw[2], boxColorToDraw[3])
            screen.drawRectF(self.x, self.y+1, self.w, self.h-2)
            screen.drawRectF(self.x+1, self.y, self.w-2, self.h)
            screen.setColor(textColorToDraw[1], textColorToDraw[2], textColorToDraw[3])
            screen.drawTextBox(self.x + 1, self.y, self.w, self.h, textToDraw, 0, 0)
        end
    }
end
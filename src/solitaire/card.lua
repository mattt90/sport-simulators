local Card = {}
Card.__index = Card
local CARD_WIDTH, CARD_HEIGHT = 80, 120

function Card:new(suit, rank, front)
    local obj = {
        suit = suit,
        rank = rank,
        faceup = false,
        x = 0,
        y = 0,
        isDragged = false,
        mouseX = 0,
        mouseY = 0,
        currentX = 0,
        currentY = 0,
        front = front or nil
    }
    setmetatable(obj, Card)
    return obj
end

function Card:draw(x, y)
    self.x = x
    self.y = y
    if self.faceup then
		love.graphics.draw(self.front, self.x, self.y, 0, CARD_WIDTH/140, CARD_HEIGHT/190)
	else
		-- draw card back
		love.graphics.setColor(0.2,0.2,0.7)
		love.graphics.rectangle("fill", self.x, self.y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("line", self.x, self.y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(1,1,1)
		love.graphics.printf("?", self.x, self.y+CARD_HEIGHT/2-8, CARD_WIDTH, "center")
	end
	love.graphics.setColor(1,1,1)
end

function Card:isRed()
    return self.suit == "H" or self.suit == "D"
end

return Card

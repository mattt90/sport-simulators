local SolitaireGame = {}
SolitaireGame.__index = SolitaireGame

function SolitaireGame:new()
    local obj = {
        tableau = {},
        foundations = {},
        stock = {},
        waste = {}
    }
    setmetatable(obj, SolitaireGame)
    return obj
end

function SolitaireGame:update(dt)
	-- Update logic for the game (e.g., handling moves, checking win conditions)
end

function SolitaireGame:draw()
    -- Draw tableau
	for i = 1, 7 do
		for j, card in ipairs(self.tableau[i]) do
			--local isDragged = false
			--if dragging and draggedCard == card and draggedFrom and draggedFrom.type == "tableau" and draggedFrom.pile == i and draggedFrom.index == j then
			--	isDragged = true
			--end
			if not card.isDragged then
				card:draw()
            else
                draggedCard = card
                -- TODO: draw outline where it was
			end
		end
	end
	-- Draw stock
	if self.stock > 0 then
		self.stock:draw()
	end
	-- Draw waste
	if self.waste > 0 then
		self.waste:draw()
	end
	-- Draw foundations
	for i = 1, 4 do
		local x = 400 + (CARD_WIDTH+20)*(i-1)
		if self.foundations[i] > 0 then
			self.foundations[i]:draw()
		else
			love.graphics.setColor(0.8,0.8,0.8)
			love.graphics.rectangle("line", x, 40, CARD_WIDTH, CARD_HEIGHT)
			love.graphics.setColor(1,1,1)
		end
	end

	-- Draw dragged card or stack on top
	if draggedCard then -- or stack??
		local mx, my = love.mouse.getPosition()
		draggedCard:draw()
	end
end

return SolitaireGame

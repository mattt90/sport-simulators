local SolitaireGame = {}
SolitaireGame.__index = SolitaireGame

local suits = {"S", "H", "D", "C"}
local ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
local CARD_WIDTH, CARD_HEIGHT = 80, 120

function SolitaireGame:new()
    local obj = {
        tableau = {},
        foundations = {},
        stock = {},
        waste = {},
		dragging = false,
		draggedCard = nil,
		draggedFrom = nil,
		dragOffsetX = 0,
		dragOffsetY = 0,
		draggedStack = nil
    }

	local d = {}
	for _, suit in ipairs(suits) do
		for _, rank in ipairs(ranks) do
			local key = rank .. suit
			local path = "cards/" .. key .. ".png"
			local img = love.graphics.newImage(path)
			table.insert(d, require("solitaire/card"):new(suit, rank, img))
		end
	end
	-- Shuffle
	for i = #d, 2, -1 do
		local j = love.math.random(i)
		d[i], d[j] = d[j], d[i]
	end

	for i = 1, 7 do
		obj.tableau[i] = {}
		for j = 1, i do
			local card = table.remove(d)
			card.faceup = (j == i)
			table.insert(obj.tableau[i], card)
		end
	end
	obj.stock = d
	obj.waste = {}
	for i = 1, 4 do obj.foundations[i] = {} end
	
    setmetatable(obj, SolitaireGame)
    return obj
end


function SolitaireGame:update(dt)
	-- Update logic for the game (e.g., handling moves, checking win conditions)
end

function SolitaireGame:draw()
	-- Draw tableau
	for i = 1, 7 do
		local isDragged = false
		for j, card in ipairs(self.tableau[i]) do
			if not isDragged and self.dragging and self.draggedCard == card and self.draggedFrom and self.draggedFrom.type == "tableau" and self.draggedFrom.pile == i and self.draggedFrom.index == j then
				isDragged = true
			end
			if not isDragged and not isDragged then
				card:draw(40 + (CARD_WIDTH+20)*(i-1), 200 + 30*(j-1))
			end
		end
	end
	-- Draw stock
	if #self.stock > 0 then
		self.stock[#self.stock]:draw(40, 40)
		--self:drawCard({faceup=false}, 40, 40)
	end
	-- Draw waste
	if #self.waste > 0 then
		if self.dragging and self.draggedFrom and self.draggedFrom.type == "waste" then
			-- skip drawing top waste card if being dragged
			if #self.waste > 1 then
				self.waste[#self.waste - 1]:draw(40 + CARD_WIDTH + 20, 40)
			end
		else
			self.waste[#self.waste]:draw(40 + CARD_WIDTH + 20, 40)
		end
	end
	-- Draw foundations
	for i = 1, 4 do
		local x = 400 + (CARD_WIDTH+20)*(i-1)
		if #self.foundations[i] > 0 then
			self.foundations[i][#self.foundations[i]]:draw(x, 40)
		else
			love.graphics.setColor(0.8,0.8,0.8)
			love.graphics.rectangle("line", x, 40, CARD_WIDTH, CARD_HEIGHT)
			love.graphics.setColor(1,1,1)
		end
	end
	-- Draw dragged card or stack on top
	if self.dragging and self.draggedCard then
		local mx, my = love.mouse.getPosition()
		if self.draggedStack and #self.draggedStack > 1 then
			for k, card in ipairs(self.draggedStack) do
				card:draw(mx - self.dragOffsetX, my - self.dragOffsetY + 30*(k-1))
			end
		else
			self.draggedCard:draw(mx - self.dragOffsetX, my - self.dragOffsetY)
		end
	end
end

function SolitaireGame:cardAtPosition(mx, my)
	-- Check tableau
	for i = 1, 7 do
		for j = #self.tableau[i], 1, -1 do
			local card = self.tableau[i][j]
			local x = 40 + (CARD_WIDTH+20)*(i-1)
			local y = 200 + 30*(j-1)
			if card.faceup and mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
				return card, {type="tableau", pile=i, index=j}, x, y
			end
		end
	end
	-- Check waste (top card only)
	if #self.waste > 0 then
		local x = 40 + CARD_WIDTH + 20
		local y = 40
		if mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
			return self.waste[#self.waste], {type="waste", pile=nil, index=#self.waste}, x, y
		end
	end
	return nil
end

function SolitaireGame:foundationAtPosition(mx, my)
	for i = 1, 4 do
		local x = 400 + (CARD_WIDTH+20)*(i-1)
		local y = 40
		if mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
			return i
		end
	end
	return nil
end

function SolitaireGame:handleMousePressed(x, y, button, istouch, presses)
	if button == 1 and not self.dragging then
		-- Check if click is on stock pile
		local stockX, stockY = 40, 40
		if button == 1 and x >= stockX and x <= stockX + CARD_WIDTH and y >= stockY and y <= stockY + CARD_HEIGHT then
			if #self.stock > 0 then
				-- Deal top card from stock to waste
				local card = table.remove(self.stock)
				card.faceup = true
				table.insert(self.waste, card)
				--log("Dealt card from stock to waste: " .. (card.rank or "?") .. (card.suit or "?"))
			else
				-- If stock is empty, recycle waste back to stock (face down, reversed order)
				if #self.waste > 0 then
					for i = #self.waste, 1, -1 do
						local card = table.remove(self.waste, i)
						card.faceup = false
						table.insert(self.stock, card)
					end
					--log("Recycled waste back to stock.")
				end
			end
			return
		end

		local card, from, cx, cy = self:cardAtPosition(x, y)
		if card then
			self.dragging = true
			self.draggedCard = card
			self.draggedFrom = from
			self.dragOffsetX = x - cx
			self.dragOffsetY = y - cy
			-- If dragging from tableau, collect stack
			if from and from.type == "tableau" and from.pile and from.index then
				self.draggedStack = {}
				for k = from.index, #self.tableau[from.pile] do
					table.insert(self.draggedStack, self.tableau[from.pile][k])
				end
			else
				self.draggedStack = nil
			end
			local fromType = from and from.type or "unknown"
			local fromPile = (from and from.pile) and (" pile "..from.pile) or ""
			--log("Started dragging card: " .. (card.rank or "?") .. (card.suit or "?") .. " from " .. fromType .. fromPile)
		end
	end
end

function SolitaireGame:handleMouseReleased(x, y, button, istouch, presses)
	if button == 1 and self.dragging and self.draggedCard and self.draggedFrom then
		local foundationIdx = self:foundationAtPosition(x, y)
		local moved = false
		if foundationIdx then
			-- Check if move to foundation is valid
			local pile = self.foundations[foundationIdx]
			local card = self.draggedCard
			local valid = false
			local rankOrder = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
			if #pile == 0 then
				valid = (card.rank == "A")
			else
				local top = pile[#pile]
				valid = (card.suit == top.suit and rankOrder[card.rank] == rankOrder[top.rank]+1)
			end
			if valid then
				-- Remove from source
				if self.draggedFrom.type == "tableau" and self.draggedFrom.pile and self.draggedFrom.index then
					if self.tableau[self.draggedFrom.pile] and self.tableau[self.draggedFrom.pile][self.draggedFrom.index] then
						table.remove(self.tableau[self.draggedFrom.pile], self.draggedFrom.index)
						-- Flip next card if needed
						local pile = self.tableau[self.draggedFrom.pile]
						if #pile > 0 and not pile[#pile].faceup then
							pile[#pile].faceup = true
						end
					end
				elseif self.draggedFrom.type == "waste" and self.draggedFrom.index then
					if self.waste[self.draggedFrom.index] then
						table.remove(self.waste, self.draggedFrom.index)
					end
				end
				-- Add to foundation
				table.insert(self.foundations[foundationIdx], card)
				--log("Moved card " .. card.rank .. card.suit .. " to foundation " .. foundationIdx)
				moved = true
			else
				--log("Invalid move: " .. draggedCard.rank .. draggedCard.suit .. " to foundation " .. foundationIdx)
			end
		end

		-- Check tableau drop
		if not moved then
			-- Check if mouse is over a tableau column
			for i = 1, 7 do
				local colX = 40 + (CARD_WIDTH+20)*(i-1)
				local colY = 200
				local colH = 30 * (#self.tableau[i]) + CARD_HEIGHT
				if x >= colX and x <= colX+CARD_WIDTH and y >= colY and y <= colY+colH then
					-- Determine if move is valid
					local pile = self.tableau[i]
					local stack = self.draggedStack or {self.draggedCard}
					local card = stack[1]
					local rankOrder = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
					local valid = false
					if #pile == 0 then
						valid = true
					else
						local top = pile[#pile]
						valid = ((card:isRed() ~= top:isRed()) and (rankOrder[card.rank] == rankOrder[top.rank]-1))
					end
					if valid then
						-- Remove stack from source
						if self.draggedFrom.type == "tableau" and self.draggedFrom.pile and self.draggedFrom.index then
							if self.tableau[self.draggedFrom.pile] and self.tableau[self.draggedFrom.pile][self.draggedFrom.index] then
								for k = #self.tableau[self.draggedFrom.pile], self.draggedFrom.index, -1 do
									table.remove(self.tableau[self.draggedFrom.pile], k)
								end
								-- Flip next card if needed
								local pile = self.tableau[self.draggedFrom.pile]
								if #pile > 0 and not pile[#pile].faceup then
									pile[#pile].faceup = true
								end
							end
						elseif self.draggedFrom.type == "waste" and self.draggedFrom.index then
							if self.waste[self.draggedFrom.index] then
								table.remove(self.waste, self.draggedFrom.index)
							end
						end
						-- Add stack to tableau
						for _, c in ipairs(stack) do
							table.insert(self.tableau[i], c)
						end
						--log("Moved stack to tableau " .. i)
						moved = true
						break
					else
						--log("Invalid move: " .. card.rank .. card.suit .. " to tableau " .. i)
					end
				end
			end
		end

	self.dragging = false
	self.draggedCard = nil
	self.draggedFrom = nil
	self.draggedStack = nil
	end
end

return SolitaireGame

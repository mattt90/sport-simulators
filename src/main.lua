love = require("love")

-- Simple logging utility
local function log(msg)
	print("[LOG] " .. tostring(msg))
end


-- Place card images in src/cards/ as 'AS.png', '2S.png', ..., 'KH.png', etc.

-- Dragging state (must be above love.draw)
local dragging = false
local draggedCard = nil
local draggedFrom = nil -- {type="tableau"/"waste", pile=idx, index=cardIdx}
local draggedStack = nil -- for tableau stack dragging
local dragOffsetX, dragOffsetY = 0, 0

local suits = {"S", "H", "D", "C"}
local ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
local cardImages = {}
local deck = {}
local tableau = {}
local foundations = {{}, {}, {}, {}}
local stock = {}
local waste = {}

local CARD_WIDTH, CARD_HEIGHT = 80, 120

-- Load card images
local function loadCardImages()
	for _, suit in ipairs(suits) do
		for _, rank in ipairs(ranks) do
			local key = rank .. suit
			local path = "src/cards/" .. key .. ".png"
			local ok, img = pcall(love.graphics.newImage, path)
			if ok then
				cardImages[key] = img
			else
				-- Placeholder: draw rectangle if image missing
				cardImages[key] = false
			end
		end
	end
end

-- Create and shuffle deck
local function createDeck()
	local d = {}
	for _, suit in ipairs(suits) do
		for _, rank in ipairs(ranks) do
			table.insert(d, {rank=rank, suit=suit, faceup=false})
		end
	end
	-- Shuffle
	for i = #d, 2, -1 do
		local j = love.math.random(i)
		d[i], d[j] = d[j], d[i]
	end
	return d
end

-- Deal cards to tableau
local function dealSolitaire()
	tableau = {}
	for i = 1, 7 do
		tableau[i] = {}
		for j = 1, i do
			local card = table.remove(deck)
			card.faceup = (j == i)
			table.insert(tableau[i], card)
		end
	end
	stock = deck
	waste = {}
	for i = 1, 4 do foundations[i] = {} end
	log("Dealt cards to tableau.")
end

function love.load()
	love.window.setTitle("Solitaire")
	love.window.setMode(900, 700)
	loadCardImages()
	deck = createDeck()
	dealSolitaire()
	log("Game started. Deck created and dealt.")
end

-- Draw a card (image or placeholder)
local function drawCard(card, x, y)
	if not card.rank or not card.suit then
		-- Draw a generic card back
		love.graphics.setColor(0.2,0.2,0.7)
		love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(1,1,1)
		love.graphics.printf("", x, y+CARD_HEIGHT/2-8, CARD_WIDTH, "center")
		love.graphics.setColor(1,1,1)
		return
	end
	local key = card.rank .. card.suit
	if card.faceup then
		if cardImages[key] then
			love.graphics.draw(cardImages[key], x, y, 0, CARD_WIDTH/140, CARD_HEIGHT/190)
		else
			love.graphics.setColor(1,1,1)
			love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)
			love.graphics.setColor(0,0,0)
			love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
			love.graphics.printf(key, x, y+CARD_HEIGHT/2-8, CARD_WIDTH, "center")
		end
	else
		love.graphics.setColor(0.2,0.2,0.7)
		love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
		love.graphics.setColor(1,1,1)
		love.graphics.printf("?", x, y+CARD_HEIGHT/2-8, CARD_WIDTH, "center")
	end
	love.graphics.setColor(1,1,1)
end

function love.draw()
	-- Draw tableau
	for i = 1, 7 do
		for j, card in ipairs(tableau[i]) do
			local isDragged = false
			if dragging and draggedCard == card and draggedFrom and draggedFrom.type == "tableau" and draggedFrom.pile == i and draggedFrom.index == j then
				isDragged = true
			end
			if not isDragged then
				drawCard(card, 40 + (CARD_WIDTH+20)*(i-1), 200 + 30*(j-1))
			end
		end
	end
	-- Draw stock
	if #stock > 0 then
		drawCard({faceup=false}, 40, 40)
	end
	-- Draw waste
	if #waste > 0 then
		drawCard(waste[#waste], 40 + CARD_WIDTH + 20, 40)
	end
	-- Draw foundations
	for i = 1, 4 do
		local x = 400 + (CARD_WIDTH+20)*(i-1)
		if #foundations[i] > 0 then
			drawCard(foundations[i][#foundations[i]], x, 40)
		else
			love.graphics.setColor(0.8,0.8,0.8)
			love.graphics.rectangle("line", x, 40, CARD_WIDTH, CARD_HEIGHT)
			love.graphics.setColor(1,1,1)
		end
	end
	-- Draw dragged card or stack on top
	if dragging and draggedCard then
		local mx, my = love.mouse.getPosition()
		if draggedStack and #draggedStack > 1 then
			for k, card in ipairs(draggedStack) do
				drawCard(card, mx - dragOffsetX, my - dragOffsetY + 30*(k-1))
			end
		else
			drawCard(draggedCard, mx - dragOffsetX, my - dragOffsetY)
		end
	end
end


-- Dragging state
local dragging = false
local draggedCard = nil
local draggedFrom = nil -- {type="tableau"/"waste", pile=idx, index=cardIdx}
local draggedStack = nil -- for tableau stack dragging
local dragOffsetX, dragOffsetY = 0, 0

-- Helper: check if (mx, my) is over a card
local function cardAtPosition(mx, my)
	-- Check tableau
	for i = 1, 7 do
		for j = #tableau[i], 1, -1 do
			local card = tableau[i][j]
			local x = 40 + (CARD_WIDTH+20)*(i-1)
			local y = 200 + 30*(j-1)
			if card.faceup and mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
				return card, {type="tableau", pile=i, index=j}, x, y
			end
		end
	end
	-- Check waste (top card only)
	if #waste > 0 then
		local x = 40 + CARD_WIDTH + 20
		local y = 40
		if mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
			return waste[#waste], {type="waste", pile=nil, index=#waste}, x, y
		end
	end
	return nil
end

-- Helper: check if (mx, my) is over a foundation pile
local function foundationAtPosition(mx, my)
	for i = 1, 4 do
		local x = 400 + (CARD_WIDTH+20)*(i-1)
		local y = 40
		if mx >= x and mx <= x+CARD_WIDTH and my >= y and my <= y+CARD_HEIGHT then
			return i
		end
	end
	return nil
end

function love.mousepressed(x, y, button)
	if button == 1 and not dragging then
		   -- Check if click is on stock pile
		   local stockX, stockY = 40, 40
		   if button == 1 and x >= stockX and x <= stockX + CARD_WIDTH and y >= stockY and y <= stockY + CARD_HEIGHT then
			   if #stock > 0 then
				   -- Deal top card from stock to waste
				   local card = table.remove(stock)
				   card.faceup = true
				   table.insert(waste, card)
				   log("Dealt card from stock to waste: " .. (card.rank or "?") .. (card.suit or "?"))
			   else
				   -- If stock is empty, recycle waste back to stock (face down, reversed order)
				   if #waste > 0 then
					   for i = #waste, 1, -1 do
						   local card = table.remove(waste, i)
						   card.faceup = false
						   table.insert(stock, card)
					   end
					   log("Recycled waste back to stock.")
				   end
			   end
			   return
		   end

		   local card, from, cx, cy = cardAtPosition(x, y)
		   if card then
			   dragging = true
			   draggedCard = card
			   draggedFrom = from
			   dragOffsetX = x - cx
			   dragOffsetY = y - cy
			   -- If dragging from tableau, collect stack
			   if from and from.type == "tableau" and from.pile and from.index then
				   draggedStack = {}
				   for k = from.index, #tableau[from.pile] do
					   table.insert(draggedStack, tableau[from.pile][k])
				   end
			   else
				   draggedStack = nil
			   end
			   local fromType = from and from.type or "unknown"
			   local fromPile = (from and from.pile) and (" pile "..from.pile) or ""
			   log("Started dragging card: " .. (card.rank or "?") .. (card.suit or "?") .. " from " .. fromType .. fromPile)
		   end
	end
end

function love.mousereleased(x, y, button)
	if button == 1 and dragging and draggedCard and draggedFrom then
		local foundationIdx = foundationAtPosition(x, y)
		local moved = false
		if foundationIdx then
			-- Check if move to foundation is valid
			local pile = foundations[foundationIdx]
			local card = draggedCard
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
				if draggedFrom.type == "tableau" and draggedFrom.pile and draggedFrom.index then
					if tableau[draggedFrom.pile] and tableau[draggedFrom.pile][draggedFrom.index] then
						table.remove(tableau[draggedFrom.pile], draggedFrom.index)
						-- Flip next card if needed
						local pile = tableau[draggedFrom.pile]
						if #pile > 0 and not pile[#pile].faceup then
							pile[#pile].faceup = true
						end
					end
				elseif draggedFrom.type == "waste" and draggedFrom.index then
					if waste[draggedFrom.index] then
						table.remove(waste, draggedFrom.index)
					end
				end
				-- Add to foundation
				table.insert(foundations[foundationIdx], card)
				log("Moved card " .. card.rank .. card.suit .. " to foundation " .. foundationIdx)
				moved = true
			else
				log("Invalid move: " .. draggedCard.rank .. draggedCard.suit .. " to foundation " .. foundationIdx)
			end
		end

		-- Check tableau drop
		if not moved then
			-- Check if mouse is over a tableau column
			for i = 1, 7 do
				local colX = 40 + (CARD_WIDTH+20)*(i-1)
				local colY = 200
				local colH = 30 * (#tableau[i]) + CARD_HEIGHT
				if x >= colX and x <= colX+CARD_WIDTH and y >= colY and y <= colY+colH then
					-- Determine if move is valid
					local pile = tableau[i]
					local stack = draggedStack or {draggedCard}
					local card = stack[1]
					local rankOrder = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
					local function isRed(suit) return suit == "H" or suit == "D" end
					local function isBlack(suit) return suit == "S" or suit == "C" end
					local valid = false
					if #pile == 0 then
						valid = true
					else
						local top = pile[#pile]
						valid = ((isRed(card.suit) ~= isRed(top.suit)) and (rankOrder[card.rank] == rankOrder[top.rank]-1))
					end
					if valid then
						-- Remove stack from source
						if draggedFrom.type == "tableau" and draggedFrom.pile and draggedFrom.index then
							if tableau[draggedFrom.pile] and tableau[draggedFrom.pile][draggedFrom.index] then
								for k = #tableau[draggedFrom.pile], draggedFrom.index, -1 do
									table.remove(tableau[draggedFrom.pile], k)
								end
								-- Flip next card if needed
								local pile = tableau[draggedFrom.pile]
								if #pile > 0 and not pile[#pile].faceup then
									pile[#pile].faceup = true
								end
							end
						elseif draggedFrom.type == "waste" and draggedFrom.index then
							if waste[draggedFrom.index] then
								table.remove(waste, draggedFrom.index)
							end
						end
						-- Add stack to tableau
						for _, c in ipairs(stack) do
							table.insert(tableau[i], c)
						end
						log("Moved stack to tableau " .. i)
						moved = true
						break
					else
						log("Invalid move: " .. card.rank .. card.suit .. " to tableau " .. i)
					end
				end
			end
		end

	dragging = false
	draggedCard = nil
	draggedFrom = nil
	draggedStack = nil
	end
end

function love.mousemoved(x, y, dx, dy)
	-- No-op, but could be used for hover effects
end

-- (drawDraggedCard and patching love.draw are now merged into love.draw above)
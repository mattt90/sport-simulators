love = require("love")

local gameFactory = require("game_factory")
local logging = require("utils/logging")
local log = logging.log

local solitaireGame = nil

function love.load()

	--solitaireGame = require("solitaire/solitaire_game"):new()
	--log("Game started. Deck created and dealt.")
end

function love.update(dt)
	-- Update game state if needed
	if solitaireGame == nil then
		return
	end

	 if solitaireGame.goToMenu then
		solitaireGame = nil
		return
	 end

	if solitaireGame.resetRequested then
		solitaireGame = require("solitaire/solitaire_game"):new()
		return
	end
	solitaireGame:update(dt)
end

function love.draw()

	if solitaireGame == nil then
		gameFactory.draw()
		

		local x, y = love.mouse.getPosition()
		love.graphics.print("("..x..", "..y..")", x, y)
		return
	end
	
	if (solitaireGame:isGameWon()) then
		solitaireGame:drawEndScreen()
		return
	end

	solitaireGame:draw()

	local x, y = love.mouse.getPosition()
	love.graphics.print("("..x..", "..y..")", x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
	if solitaireGame == nil then
		solitaireGame = gameFactory.handleMousePressed(x, y, button, istouch, presses)
		return
	end
	solitaireGame:handleMousePressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	if solitaireGame == nil then
		return
	end
	solitaireGame:handleMouseReleased(x, y, button, istouch, presses)
end

love = require("love")

local logging = require("utils/logging")
local log = logging.log

local solitaireGame = {}

function love.load()
	solitaireGame = require("solitaire/solitaire_game"):new()
	log("Game started. Deck created and dealt.")
end

function love.update(dt)
	-- Update game state if needed
	if solitaireGame.resetRequested then
		solitaireGame = require("solitaire/solitaire_game"):new()
		return
	end
	solitaireGame:update(dt)
end

function love.draw()

	require("game_factory").draw()
	--[[
	if (solitaireGame:isGameWon()) then
		solitaireGame:drawEndScreen()
		return
	end

	solitaireGame:draw()

	local x, y = love.mouse.getPosition()
	love.graphics.print("("..x..", "..y..")", x, y)
	]]
end

function love.mousepressed(x, y, button, istouch, presses)
	solitaireGame:handleMousePressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	solitaireGame:handleMouseReleased(x, y, button, istouch, presses)
end

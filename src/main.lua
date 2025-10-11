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
local deck = {}
local tableau = {}
local foundations = {{}, {}, {}, {}}
local stock = {}
local waste = {}

local solitaireGame = {}

local CARD_WIDTH, CARD_HEIGHT = 80, 120

function love.load()
	solitaireGame = require("solitaire/solitaire_game"):new()
	log("Game started. Deck created and dealt.")
end

function love.update(dt)
	-- Update game state if needed
end

function love.draw()
	solitaireGame:draw()

	local x, y = love.mouse.getPosition()
	love.graphics.print("("..x..", "..y..")", x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
	solitaireGame:handleMousePressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	solitaireGame:handleMouseReleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy)
    --log("Mouse moved to: " .. x .. ", " .. y)
	if dragging then
		-- Card position will follow mouseX, mouseY in love.draw
	end
end
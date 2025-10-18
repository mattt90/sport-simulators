local games = {
    { name = "Solitaire", module = require("solitaire/solitaire_game"), x = 50, y = 50 },
   -- { name = "Poker", module = require("solitaire/solitaire_game"), x = 50, y = 100 },
    --{ name = "Blackjack", module = require("solitaire/solitaire_game"), x = 50, y = 150 },
    -- Add more games here as needed
}

local function draw()
    for _, game in ipairs(games) do
        --game:draw()
        love.graphics.rectangle("line", game.x, game.y, 100, 20)
	    love.graphics.printf(game.name, game.x + 5, game.y + 5, 100, "left")
    end
end

local function handleMousePressed(x, y, button, istouch, presses)
    for _, game in ipairs(games) do
        if x >= game.x and x <= game.x + 100 and y >= game.y and y <= game.y + 20 then
            -- Start the selected game
            return game.module:new()
        end
    end
    return nil
end

return {
    draw = draw,
    handleMousePressed = handleMousePressed
}
local Card = {}
Card.__index = Card

function Card:new(suite, rank, x, y, width, height)
    local obj = {
        suite = suite,
        rank = rank,
        x = x or 0,
        y = y or 0,
        width = width or 80,
        height = height or 120
    }
    setmetatable(obj, Card)
    return obj
end

return Card

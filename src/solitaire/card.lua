local Card = {}
Card.__index = Card

function Card:new(suite, rank, x, y, width, height, front)
    local obj = {
        suite = suite,
        rank = rank,
        x = x or 0,
        y = y or 0,
        width = width or 80,
        height = height or 120,
        isDragged = false,
        mouseX = 0,
        mouseY = 0,
        currentX = x or 0,
        currentY = y or 0,
        front = front or nil
    }
    setmetatable(obj, Card)
    return obj
end

return Card

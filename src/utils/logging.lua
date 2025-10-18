
local function log(msg)
	print("[LOG] " .. tostring(msg))
    io.flush()
end

return {
    log = log
}
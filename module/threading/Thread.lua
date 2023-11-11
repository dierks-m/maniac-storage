--- @class Thread
--- @field thread thread
--- @field running boolean
--- @field filter string
local Thread = {}

function Thread:resume(...)
    local eventType = select(1, ...)

    if not self.running or self.filter and self.filter ~= eventType then
        return
    end

    local ok, response = coroutine.resume(self.thread, ...)

    if not ok then
        error(response)
    end

    self.filter = response
end

function Thread:status()
    return coroutine.status(self.thread)
end

function Thread:start()
    self.running = true
    self:resume()
    
    return self
end

--- @param func function
--- @return Thread
function Thread.new(func)
    local thread

    thread = {
        thread = coroutine.create(function()
            local ok, err = pcall(func)

            if not ok then
                error(err)
            end

            thread.running = false
        end)
    }

    setmetatable(thread, {__index = Thread})

    return thread
end

return Thread
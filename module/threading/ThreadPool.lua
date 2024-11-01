--- @class ThreadPool
--- @field threads Thread[]
--- @field joinedThreads Thread[]
local ThreadPool = {}

--- @param self ThreadPool
local function resumeCoroutines(self, ...)
    for index, thread in pairs(self.threads) do
        if thread:status() ~= "dead" then
            thread:resume(...)
        else
            self.threads[index] = nil
        end
    end
end

--- @param self ThreadPool
local function allJoinedThreadsAlive(self)
    for _, thread in pairs(self.joinedThreads) do
        if thread:status() == "dead" then
            return false
        end
    end

    return true
end

--- @param thread Thread
function ThreadPool:add(thread)
    for _, t in pairs(self.threads) do
        if t == thread then
            return
        end
    end

    self.threads[#self.threads + 1] = thread
end

--- Joins this thread to the parent thread.
--- If this thread dies, the run method will return.
--- @param thread Thread
function ThreadPool:join(thread)
    self:add(thread)
    self.joinedThreads[#self.joinedThreads + 1] = thread
end

--- Runs all threads until one of the joined threads dies.
function ThreadPool:run()
    while allJoinedThreadsAlive(self) do
        local event = { coroutine.yield() }

        if event[1] == "terminate" then
            self.threads = {}
            error("Terminated", 0)
        end

        resumeCoroutines(self, unpack(event))
    end
end

--- @return ThreadPool
function ThreadPool.new()
    return setmetatable(
            { threads = {}, joinedThreads = {} },
            { __index = ThreadPool }
    )
end

return ThreadPool
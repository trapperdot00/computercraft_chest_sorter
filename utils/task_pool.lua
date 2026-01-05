local task_pool = {}
task_pool.__index = task_pool

-- Creates a new instance of
-- a task pool: a class that handles
-- the execution of parallelized tasks.
--
-- Fields:
--     tasks       : The array of tasks to run.
--     max_bufsize : Maximum amount of tasks
--                   in the buffer, execution
--                   happens when the task-buffer
--                   is full.
function task_pool.new(max_bufsize)
    return setmetatable(
        {
            tasks       = {},
            max_bufsize = max_bufsize or 256
        }, task_pool
    )
end

-- Run each task in parallel,
-- empty the task list.
function task_pool:run()
    parallel.waitForAll(
        table.unpack(self.tasks)
    )
    self.tasks = {}
end

-- Add a new task to the task list,
-- run them if the task buffer full.
function task_pool:add(task)
    table.insert(self.tasks, task)
    if #self.tasks >= self.max_bufsize then
        self:run()
    end
end

return task_pool

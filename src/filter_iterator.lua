local iterator = require("src.iterator")
local filter_iterator = setmetatable(
    {}, { __index = iterator }
)
filter_iterator.__index = filter_iterator

--==== INTERFACE ====--
--
-- filter_iterator:new(db)
--
-- filter_iterator:first()
-- filter_iterator:next()
-- filter_iterator:get()
-- filter_iterator:is_done()

--==== IMPLEMENTATION ====--

-- Constructs a new instance of filter_iterator:
-- an iterator that traverses the elements of
-- the inventory database that satisfy
-- a condition.
--
-- Traversal order: each slot of each inventory,
--                  with items satisfying a
--                  predicate.
-- Parameters:
--     `contents`: Table of inventory contents.
--     `predicate: Function that takes an element
--                 returned by get() as
--                 parameter.
--                 Returns a boolean value,
--                 indicating whether the
--                 current state of the iterator
--                 is valid.
function filter_iterator:new(contents, predicate)
    local self = setmetatable(
        iterator:new(contents),
        filter_iterator
    )
    self.predicate = predicate
    return self
end

-- Set the iterator to point to the first
-- element that satisfies the predicate.
function filter_iterator:first()
    iterator.first(self)
    if not self.predicate(self:get()) then
        self:next()
    end
end

-- Advance the iterator to point to the
-- next element that satisfies the predicate.
function filter_iterator:next()
    repeat
        iterator.next(self)
    until self:is_done()
    or self.predicate(self:get())
end

return filter_iterator

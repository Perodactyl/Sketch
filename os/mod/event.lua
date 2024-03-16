---@class EventEmitter
---  @field on fun(event: string, callback: function, count?: integer)
---  @field once fun(event: string, callback: function)
---  @field off fun(event: string, callback: function)
---  @field guard fun(): EventEmitter

local event = {}

---Creates an event emitter and returns the emitter as well as a function that emits an event.
---@return EventEmitter, fun(event: string, ...)
function event.emitter()
	local listeners = {}
	local emitter = {}
	local guards = {}
	function emitter.on(event, callback, count)
		if count == nil then count = math.huge end
		table.insert(listeners, {event, callback, count})
	end
	function emitter.once(event, callback)
		emitter.on(event, callback, 1)
	end
	function emitter.off(event, callback)
		for i,listener in ipairs(listeners) do
			if listener[1] == event and listener[2] == callback then
				listener[3] = 0
			end
		end
	end
	
	function emitter.guard()
		local newEmitter, newEmit = event.emitter()
		table.insert(guards, {newEmitter, newEmit})
		local function remove()
			for i,guard in ipairs(guards) do
				if guard[1] == newEmitter and guard[2] == newEmit then
					table.remove(guards, i)
					break
				end
			end
		end
		setmetatable(newEmitter, {
			__gc= function(t)
				remove()
			end,
			__close= function(t)
				remove()
			end,
		})
		return newEmitter
	end
	
	local function emit(event, ...)
		for i, guard in guards do
			guard[2](event, ...)
		end
		for i,listener in ipairs(listeners) do
			if listener[1] == event and listener[3] > 0 then
				listener[2](...)
				listener[3] = listener[3] - 1
			end
		end
		while true do
			local changed = false
			for i,listener in ipairs(listeners) do
				if listener[3] <= 0 then
					changed = true
					table.remove(listeners, i)
					break
				end
			end
			if not changed then break end
		end
	end
	return emitter, emit
end

return event
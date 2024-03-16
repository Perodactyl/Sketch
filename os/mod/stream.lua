---@class Stream
---  @field type "r" | "w"

---Stream that emits the "data" event when data is received.
---@class ReadStream: Stream, EventEmitter
---  @field type "r"

---Stream that can be written to.
---@class WriteStream: Stream
---  @field type "w"
---  @field write fun(data: string): integer

local event = require "event"
local stream = {}

---Creates a read stream and a write stream. Pipes the two together.
---@return ReadStream, WriteStream
function stream.createReadStream()
	local read = {}
	local write = {}
	
	local emitter, emit = event.emitter()
	read.on,read.off,read.once,read.guard = emitter.on,emitter.off,emitter.once,emitter.guard
	
	function write.write(data)
		emit("data", data)
		return #data
	end
	
	return read, write
end
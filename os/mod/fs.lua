--TODO
do
	if package.loaded[...] ~= nil then
		return package.loaded[...]
	end
	if os.ctl.fs == nil then
		os.ctl.fs = {
			mounts= {}
		}
	end
	local fs = {}
	
	---Returns all segments of a path.
	---@param fspath string path.
	---@return string? addressSegment, string[] pathSegments
	function fs.segments(fspath)
		local address = string.match(fspath, "^(%a+):%a+$")
		if address == nil then
			address = "#user"
		end
		local out = {}
		for segment in string.gmatch(fspath, "(%a-%/)+$") do
			table.insert(out, segment)
		end
		return out
	end
	
	function fs.address(fspath)
		local address,_ = fs.segments(fspath)
		return address
	end
	
	function fs.findMount(fspath)
		local fsAddress = fs.address(fspath)
		for mount,proxy in pairs(os.ctl.fs.mounts) do
			if mount == fsAddress then
				return proxy
			end
		end
		return nil
	end
	
	function fs.path(fspath)
		local _,segments = fs.segments(fspath)
		return table.concat(segments, "/")
	end
	
	package.loaded[...] = fs
	return fs
end
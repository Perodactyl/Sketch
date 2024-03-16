do
	local package = {
		searchers= {},
		path= {},
	}
	
	function package.searchpath(name, path, sep, rep)
		if path == nil then
			path = package.path
		end
		if sep == nil then
			sep = "[%/%.]"
		end
		if rep == nil then
			rep = "/"
		end
		
		name = string.gsub(name, sep, rep)
		
		for i, fn in ipairs(package.searchers) do
			local search, addr = fn(name, path)
			
			if search ~= nil then
				return search, addr
			end
		end
	end
	
	function package.require(modname)
		--Locate
		local path, addr = package.searchpath(modname)
		if path == nil then
			error(string.format("module '%s' not found", modname))
		end
		--Read
		local handle = component.invoke(addr, "open", path)
		local code = ""
		
		while true do
			local block = component.invoke(addr, "read", handle, math.huge)
			if block == nil then break end
			code = code .. block
		end
		
		--Load
		local exe, load_error = load(code, string.format("=<module %s [%s:%s]>", modname, addr, path))
		if not exe and load_error then
			error(string.format("load error in module %s [%s:%s]:\n%s", modname, addr, path, load_error))
		elseif not exe then
			error(string.format("load error in module %s [%s:%s]", modname, addr, path))
		end
		
		--Execute
		local output = { xpcall(exe, debug.traceback) }
		if not output[1] then
			error(string.format("error in module %s [%s:%s]:\n%s", modname, addr, path,output[2]))
		end
		return table.unpack(output, 2)
	end
	
	_G.package = package
	_G.require = package.require
end
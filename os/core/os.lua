do
	local os = {
		orig= os,
		fs= component.proxy(computer.getBootAddress()),
		ctl= {}
	}
	_G.os = os
	
	--Set up OS require.
	table.insert(package.searchers, function(modname, path)
		for i, entry in ipairs(path) do
			local value = string.match(string.format(entry,modname), "^:os:(.*)")
			if value == nil then goto continue end
			if os.fs.exists(value) then
				-- error("FOUND "..value)
				return value, os.fs.address
			end
			if os.fs.exists(value..".lua") then
				-- error("FOUND .lua "..value)
				return value..".lua", os.fs.address
			end
			::continue::
		end
		return nil, nil
	end)
	table.insert(package.path, ":os:/mod/%s")
	
	local fs = require "fs"
	
	--Set up FS require.
	table.insert(package.searchers, function(modname, path)
		for i, entry in ipairs(path) do
			local value = string.format(entry, modname)
			if fs.exists(value) then
				return fs.path(value), fs.address(value)
			end
			if os.fs.exists(value..".lua") then
				return fs.path(value), fs.address(value)
			end
		end
		return nil, nil
	end)
	table.insert(package.path, "%s")
	table.insert(package.path, "#wd:%s")
	table.insert(package.path, "#os:/mod/%s")
	table.insert(package.path, "#home:/mod/%s")
	table.insert(package.path, "#pkg:/mod/%s")
	
	function loadfile(path)
		local handle = fs.open(path, "r")
		local reader = function()
			return handle:read(2048)
		end
		local exe, load_error = load(reader, "="..path)
		if not exe and load_error then
			error(string.format("load error in file %s:\n%s", path, load_error))
		elseif not exe then
			error(string.format("load error in file %s", path))
		end
		
		return exe
	end
	
	function dofile(path, ...)
		return loadfile(path)(...)
	end
end
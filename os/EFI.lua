local function efi()
	_G._EFI_PROVIDER = "Sketch EFI vanilla"
	_G._EFI_FORMAT = "1"
	_G._EFI_V = "0.1"
	if not _PIXEL_V then
		error("This script is meant to run on PIXEL EFI.")
	end
	local fs = component.proxy(computer.getBootAddress())
	local function readFile(path)
		if not fs.exists(path) then
			return nil
		end
		local handle = fs.open(path, "r")
		local data = ""
		while true do
			local block = fs.read(handle, math.huge)
			if block == nil then break end
			data = data .. block
		end
		return data
	end
	local function run(text, name, env)
		if text == nil then error(string.format("corefile '%s' is missing!", name)) end
		local exe, loadError = load(text, "="..name, "bt", env)
		if loadError or not exe then
			error(loadError)
		end
		local out = { xpcall(exe, debug.traceback) }
		if not out[1] then
			error(out[2])
		end
		return table.unpack(out, 2)
	end
	
	local scripts = {
		"core/package.lua",
		"core/os.lua",
		"rc.lua",
	}
	
	local recursiveRunner
	recursiveRunner = function(scripts, i)
		if i == nil then i = 1 end
		local script = scripts[i]
		if i == #scripts then
			return run(readFile(script), script)
		else
			return run(readFile(script), script), recursiveRunner(scripts, i+1)
		end
	end
	-- run(readFile("core/os.lua"), "core/os.lua")
	-- run(readFile("core/package.lua"), "core/package.lua")
	-- run(readFile("rc.lua"), "rc.lua")
	
	return recursiveRunner(scripts)
end

--Debug if the EFI crashes

-- local success, err = xpcall(efi, debug.traceback)
-- if not success then error(err) end

return efi() --These tail calls should deallocate all traces of the EFI chain.
local function efi()
	_G._EFI_PROVIDER = "Sketch EFI vanilla"
	_G._EFI_FORMAT = 1
	_G._EFI_V = "0.2"
	if not _PIXEL_V then
		error("This script is meant to run on PIXEL EFI.")
	end
	
	-- "pretty"
	local function prettyError(...)
		local message = table.concat({...}, " ")
		---@type GPUProxy?
		local gpu = nil
		local bestResX, bestResY = -math.huge, -math.huge
		---@type ScreenProxy[]
		local screens = {}
		for addr, type in component.list() do
			if type == "gpu" then
				local resX, resY = component.invoke(addr, "maxResolution")
				local depth = component.invoke(addr, "maxDepth")
				if resX > bestResX or resY > bestResY then
					bestResX = resX
					bestResY = resY
					gpu = component.proxy(addr) --[[@as GPUProxy]]
				end
			elseif type == "screen" then
				table.insert(screens, component.proxy(addr))
			end
		end
		if not gpu then
			error(...)
		end
		for _,screen in ipairs(screens) do
			if screen.isOn() then
				gpu.bind(screen.address)
				gpu.setPaletteColor(0, 0x0000FF)
				gpu.setPaletteColor(1, 0xFFFFFF)
				gpu.setBackground(0, true)
				gpu.setForeground(1, true)
				
				local w,h = gpu.maxResolution()
				if w > 80 then w = 80 end
				if h > 25 then h = 25 end
				gpu.setResolution(w,h)
				
				local lines = {}
				for match in string.gmatch(message,"([^\n]+)") do
					table.insert(lines, (string.gsub(match, "\t", "    ")))
				end
				
				gpu.fill(1,1,w,h," ")
				
				gpu.set(1,1,"--ERROR--")
				
				for i,line in ipairs(lines) do
					gpu.set(2,i+2,line)
				end
			end
		end
		while true do coroutine.yield() end
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
		if text == nil then prettyError(string.format("corefile '%s' is missing!", name)) end
		local exe, loadError = load(text, "="..name, "bt", env)
		if loadError or not exe then
			prettyError(loadError)
		end
		local out = { xpcall(exe, debug.traceback) }
		if not out[1] then
			prettyError(out[2])
		end
	end
	
	local scripts = {
		"core/package.lua",
		"core/os.lua",
		"rc.lua",
	}
	
	local function recursiveRunner(scripts, i)
		if i == nil then i = 1 end
		local script = scripts[i]
		if i == #scripts then
			return run(readFile(script), script)
		else
			return run(readFile(script), script), recursiveRunner(scripts, i+1)
		end
	end
	
	return recursiveRunner(scripts)
end

--Debug if the EFI crashes

-- local success, err = xpcall(efi, debug.traceback)
-- if not success then pretty_error(err) end

return efi() --These tail calls should deallocate all traces of the EFI chain.
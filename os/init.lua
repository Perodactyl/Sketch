--Clearly PixelEFI isn't flashed, so we need to run it manually.

_G._PIXELSUB_V = "0.1"

---@diagnostic disable-next-line: undefined-field
local fs = component.proxy(computer.getBootAddress() --[[@as string]]) --[[@as FilesystemProxy?]]

if not fs then error("No boot FS!") end

if not fs.exists("pixel.lua") then
	error("EEPROM is unflashed and substitute pixel.lua is missing!")
end

---@type integer?
local handle = fs.open("pixel.lua", "r")
--no clue how this could happen but adding this line makes VSCode happy.
if not handle then goto stop end

local code = fs.read(handle, 2048)
if code == nil then --Pixel EEPROM is empty.
	goto stop
end
local block2 = fs.read(handle, 2048)
if block2 ~= nil then
	code = code .. block2
end
block2 = nil

fs.close(handle)
handle = nil
fs = nil

local exe, loadError = load(code, "=<s>Pixel EEPROM")
code = nil

if loadError or not exe then
	error(loadError)
end
loadError = nil

local success, result = xpcall(exe, debug.traceback)
if not success then
	error(result)
end

::stop::
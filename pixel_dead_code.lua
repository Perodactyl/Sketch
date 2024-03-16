goto pixel
::advancedLoader::
--See the top of https://pastebin.com/Cx4aTipt for copyright on advancedLoader. (sorry, I'm low on EEPROM space.)
do
	local a={}local b={}local c=component.invoke;local function d(e)local f={"B","KiB","MiB","GiB"}local g=1;while e>1024 and f[g]do g=g+1;e=e/1024 end;return e.." "..f[g]end;local function h(i)local j=c(i,"readSector",1)for k=1,#j do if j:sub(k,k)=="\0"then j=j:sub(1,k-1)break end end;return j end;local l=component.list("eeprom")()computer.getBootAddress=function()return c(l,"getData")end;computer.setBootAddress=function(i)return c(l,"setData",i)end;local function m(i)if component.type(i)=="drive"then local n,o=load(h(i))if not n then return false end;return true elseif component.type(i)=="filesystem"then return c(i,"exists","init.lua")and not c(i,"isDirectory","init.lua")else return false end end;for k,p in pairs(component.list("drive"))do if m(k)then a[#a+1]=k end end;for k,p in pairs(component.list("filesystem"))do if m(k)then b[#b+1]=k end end;local q=component.list("screen")()local r=component.list("gpu")()c(r,"bind",q)c(r,"setResolution",c(r,"maxResolution"))local s,t=c(r,"getResolution")local function u()c(r,"setForeground",0xFFFFFF)c(r,"setBackground",0x000000)c(r,"fill",1,1,s,t," ")end;u()local function v(w,x)local y=s/2-#w/2;c(r,"set",y,x,w)end;local z={}for p,A in pairs(a)do z[#z+1]=A end;for p,A in pairs(b)do z[#z+1]=A end;local B=computer.getBootAddress()for k,A in pairs(z)do if A==B then selected=k;break end end;local function C()v("Advanced Bootloader",2)v("Select boot medium",3)v("Computer Memory: "..d(computer.totalMemory()),4)for k,A in pairs(z)do if k==selected then c(r,"setForeground",0x000000)c(r,"setBackground",0xFFFFFF)end;c(r,"fill",1,k+5,s,1," ")v(A.."("..(c(A,"getLabel")or"No Label")..")",k+5)if k==selected then c(r,"setForeground",0xFFFFFF)c(r,"setBackground",0x000000)end end end;local function D(i)u()v("Booting "..i.."("..(c(i,"getLabel")or"No Label")..")",math.floor(t/2))v("Please wait...",math.floor(t/2)+1)computer.setBootAddress(i)if component.type(i)=="filesystem"then local E,o=c(i,"open","/init.lua")if not E then error(o)end;local F=""repeat local G=c(i,"read",E,math.huge)F=F..(G or"")until not G;load(F)()elseif component.type(i)=="drive"then load(h(i))()end;u()end;if#z==1 then D(z[1])elseif#z==0 then error("No bootable device!")end;C()while true do local H,p,p,I=computer.pullSignal()if H=="key_down"then if I==208 then selected=selected+1;if selected>#z then selected=1 end elseif I==200 then selected=selected-1;if selected<1 then selected=#z end elseif I==28 then D(z[selected])end;C()elseif H=="touch"then if z[I-5]then if selected==I-5 then D(z[selected])else selected=I-5 end end;C()end end
end
::pixel::
_G._PIXEL_V = "0.1"

local is_flashed = false

if not computer.getBootAddress then
	is_flashed = true
	local eeprom = component.list("eeprom")()
	---@diagnostic disable-next-line: inject-field
	function computer.getBootAddress()
		return component.invoke(eeprom, "getData")
	end
end

---@diagnostic disable-next-line: undefined-field
local fs = component.proxy(computer.getBootAddress() --[[@as string]]) --[[@as FilesystemProxy?]]

if not fs then error("No boot FS!") end

if not fs.exists("EFI.lua") then
	-- error("EFI file is missing!")
	goto advancedLoader
end

---@type integer?
local handle = fs.open("EFI.lua", "r")
--no clue how this could happen but adding this line makes VSCode happy.
if not handle then return end

local code = ""
while true do
	local block = fs.read(handle, math.huge)
	if block == nil then break end
	code = code .. block
end

fs.close(handle)
handle = nil
fs = nil

local exe, loadError = load(code, "=EFI")

if loadError or not exe then
	error(loadError)
end
loadError = nil

return exe() --These tail calls should deallocate all traces of the EFI chain.
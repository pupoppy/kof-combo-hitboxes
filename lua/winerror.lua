local ffi = require("ffi")
local types = require("winapi.types")
local winerror = {}

ffi.cdef[[
DWORD GetLastError(void);

void SetLastError(DWORD dwErrCode);
]]
local C = ffi.C

function winerror.testLastError(level)
	local err = C.GetLastError()
	local newLevel = (level or 1) + 1
	if err ~= 0 then
		error("Received Windows error code " .. err, newLevel)
	end
	return err
end

function winerror.checkZero(n)
	if n ~= 0 then winerror.testLastError(2) end
	return n
end

function winerror.checkNotZero(n)
	if n == 0 then winerror.testLastError(2) end
	return n
end

function winerror.checkEqual(n, key)
	if n ~= key then winerror.testLastError(2) end
	return n
end

function winerror.checkNotEqual(n, key)
	if n == key then winerror.testLastError(2) end
	return n
end

function winerror.clearLastError()
	C.SetLastError(0)
end

return winerror

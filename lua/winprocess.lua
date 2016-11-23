local winprocess = {}
local ffi = require("ffi")
local types = require("winapi.types")
local winerror = require("winerror")
local luautil = require("luautil")

ffi.cdef[[
HANDLE OpenProcess(DWORD access, BOOL inherit, DWORD pid);
BOOL CloseHandle(HANDLE hObject);
BOOL ReadProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);
BOOL WriteProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);
]]
local C = ffi.C

-- bit masks for process access rights used by OpenProcess
luautil.insertPairs(winprocess, {
	["PROCESS_TERMINATE"]       = 0x0001,
	["PROCESS_CREATE_THREAD"]   = 0x0002,
	["PROCESS_VM_OPERATION"]    = 0x0008,
	["PROCESS_VM_READ"]         = 0x0010,
	["PROCESS_VM_WRITE"]        = 0x0020,
	["PROCESS_DUP_HANDLE"]      = 0x0040,
	["PROCESS_CREATE_PROCESS"]  = 0x0080,
	["PROCESS_SET_QUOTA"]       = 0x0100,
	["PROCESS_SET_INFORMATION"] = 0x0200,
	["PROCESS_QUERY_INFORMATION"] = 0x0400,
	["PROCESS_SUSPEND_RESUME"]  = 0x0800,
	["PROCESS_QUERY_LIMITED_INFORMATION"] = 0x1000,
})
local defaultRights = bit.bor(
	winprocess.PROCESS_VM_READ,
	--winprocess.PROCESS_VM_WRITE,
	winprocess.PROCESS_QUERY_INFORMATION)

-- nonstandard argument order, to facilitate default arguments
function winprocess.open(pid, access, inherit)
	inherit = luautil.asBoolean(inherit)
	access = access or defaultRights
	local handle = C.OpenProcess(access, inherit, pid)
	winerror.checkNotEqual(handle, NULL)
	return handle
end

function winprocess.close(handle)
	local result = C.CloseHandle(handle)
	winerror.checkNotZero(result)
	return result
end

-- address MUST be cast to "void*" using ffi.cast() beforehand;
-- this is NOT done automatically, to avoid excess garbage collection
function winprocess.read(handle, buffer, address, n, bytesReadBuffer)
	local result = C.ReadProcessMemory(
		handle, address, buffer, n or ffi.sizeof(buffer),
		bytesReadBuffer or NULL)
	winerror.checkNotZero(result)
	return result, buffer
end

-- address MUST be cast to "void*" using ffi.cast() beforehand;
-- this is NOT done automatically, to avoid excess garbage collection
function winprocess.write(handle, buffer, address, n, bytesWrittenBuffer)
	local result = C.WriteProcessMemory(
		handle, address, buffer, n or ffi.sizeof(buffer),
		bytesWrittenBuffer or NULL)
	winerror.checkNotZero(result)
	return result, buffer
end

return winprocess
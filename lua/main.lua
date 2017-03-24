local ffi = require("ffi")
local types = require("winapi.types")
local winutil = require("winutil")
local detectgame = require("detectgame")
local window = require("window")
local hk = require("hotkey")

ffi.cdef[[
typedef struct tagMSG {
	HWND   hwnd;
	UINT   message;
	WPARAM wParam;
	LPARAM lParam;
	DWORD  time;
	POINT  pt;
} MSG, *PMSG, *LPMSG;

BOOL PeekMessageW(
	LPMSG lpMsg,         // out
	HWND  hWnd,          // optional
	UINT  wMsgFilterMin,
	UINT  wMsgFilterMax,
	UINT  wRemoveMsg);
BOOL TranslateMessage(MSG *lpMsg);
LRESULT DispatchMessageW(MSG *lpMsg);
VOID Sleep(DWORD ms);
]]
local C = ffi.C

function main(hInstance, CLibs)
	hInstance = ffi.cast("HINSTANCE", hInstance)
	local detected = detectgame.findSupportedGame(hInstance)
	if detected then
		local game = detectgame.moduleForGame(detected)
		game:loadConfigs()
		print(string.format(
			"For best visual results, a game window resolution of %dx%d is recommended.",
			game.basicWidth, game.basicHeight))
		game:extraInit()
		game:setupOverlay(CLibs.directx)
		return mainLoop(game)
	else
		print("Failed to detect a supported game running.")
	end
end

function mainLoop(game)
	local message = ffi.new("MSG[1]")
	local PM_REMOVE = 0x01
	local running = true
	local drawing = true
	local fg

	while running do
		fg = window.foreground()
		while C.PeekMessageW(message, NULL, 0, 0, PM_REMOVE) ~= 0 do
			C.TranslateMessage(message)
			C.DispatchMessageW(message)
		end

		game:nextFrame(drawing)
		if fg == game.consoleHwnd then
			if hk.down(hk.VK_Q) then
				winutil.flushConsoleInput()
				io.write("\n")
				running = false
			end
		end
		if fg == game.consoleHwnd or fg == game.overlayHwnd or fg == game.gameHwnd then
			-- space bar toggles rendering on/off (TEMPORARY)
			if hk.pressed(0x20) then drawing = not drawing end
		end
		C.Sleep(5)
	end
	game:close()
	return 0
end

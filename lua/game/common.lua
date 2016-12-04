local window = require("window")
local winprocess = require("winprocess")
local winutil = require("winutil")
local color = require("render.colors")
local Game_Common = {}

local RAM_LIMIT_EXCEEDED = "Attempted to exceed the upper limit of the RAM range."

-- value added to address parameter in every call to read()/write()
Game_Common.RAMbase = 0
-- upper limit for valid RAM addresses; it is an error if we go above this
Game_Common.RAMlimit = 0xFFFFFFFF
-- "ideal" screen width/height (at or nearest to 1:1 scale in the game)
Game_Common.basicWidth = 1
Game_Common.basicHeight = 1

-- pass a result from detectgame.findSupportedGame() as the "source" param
function Game_Common:new(source)
	source = (source or {})
	setmetatable(source, self)
	self.__index = self

	-- resources that MUST always be unique instances are init'd here
	source.addressBuf = winutil.ptrBufType() -- used by read()
	source.pointerBuf = winutil.ptrBufType() -- used by readPtr()
	source.rectBuf = winutil.rectBufType()
	source.pointBuf = winutil.pointBufType()
	-- values to be set at runtime
	source.width = 1
	source.height = 1
	source.xScale = 1
	source.yScale = 1

	source:extraInit()
	return source
end

-- to be (optionally) overridden by derived objects
function Game_Common:extraInit()
	return
end

function Game_Common:close()
	window.destroy(self.overlayHwnd)
	window.unregisterClass(self.atom, self.hInstance)
	winprocess.close(self.gameHandle)
end

function Game_Common:setupOverlay(directx)
	self.overlayHwnd, self.atom = window.createOverlayWindow(self.hInstance)
	self.directx = directx
	--self.overlayDC = window.getDC(self.overlayHwnd)
	-- TODO: change directx code on the C side to support multiple instances
	self.directx.setupD3D(self.overlayHwnd)
	self:setColor(color.rgba(255,0,0))
end

function Game_Common:read(address, buffer)
	local newAddress = address + self.RAMbase
	assert(newAddress < self.RAMlimit, RAM_LIMIT_EXCEEDED)
	self.addressBuf.i = newAddress
	local result = winprocess.read(self.gameHandle, self.addressBuf, buffer)
	return result, newAddress
end

function Game_Common:readPtr(address)
	local newAddress = address + self.RAMbase
	assert(newAddress < self.RAMlimit, RAM_LIMIT_EXCEEDED)
	self.pointerBuf.i = newAddress
	winprocess.read(self.gameHandle, self.pointerBuf, self.pointerBuf)
	return self.pointerBuf.i, newAddress
end

function Game_Common:getGameWindowSize()
	window.getClientRect(self.gameHwnd, self.rectBuf)
	self.width, self.height = self.rectBuf[0].right, self.rectBuf[0].bottom
	self.xScale = self.width / self.basicWidth
	self.yScale = self.height / self.basicHeight
	self.directx.setScissor(self.width, self.height)
end

function Game_Common:repositionOverlay()
	window.move(
		self.overlayHwnd, self.gameHwnd,
		self.rectBuf, self.pointBuf, false) -- TODO: don't resize for now
	self:getGameWindowSize()
end

function Game_Common:rect(...)
	self.directx.rect(...)
end

function Game_Common:getColor()
	return self.directx.getColor()
end

function Game_Common:setColor(newColor)
	return self.directx.setColor(newColor)
end

function Game_Common:shouldRenderFrame()
	local fg = window.foreground()
	if fg == self.gameHwnd then
		return true
	elseif fg == self.overlayHwnd and window.isVisible(self.gameHwnd) then
		return true
	end
	return false
end

-- to be overridden by derived objects
function Game_Common:captureState()
	return
end

-- to be overridden by derived objects
function Game_Common:renderState()
	return
end

function Game_Common:nextFrame()
	self:captureState()
	if self:shouldRenderFrame() then
		self:repositionOverlay()
		self.directx.beginFrame()
		self:renderState()
	else
		self.directx.beginFrame()
	end
	self.directx.endFrame()
end

return Game_Common

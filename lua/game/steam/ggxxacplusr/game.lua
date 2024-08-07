local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.steam.ggxxacplusr.types")
local boxtypes = require("game.steam.ggxxacplusr.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local Game_Common = require("game.common")
local Game_Common_Extra = require("game.common_extra")
local GGXX = Game_Common:new({ whoami = "GGXXACPlusR" })
local floor, band = math.floor, bit.band
luautil.extend(GGXX, Game_Common_Extra)

GGXX.configSection = "ggxx"
GGXX.basicWidth = 640
GGXX.basicHeight = 480
GGXX.aspectMode = "pillarbox"
GGXX.absoluteYOffset = 40
GGXX.pivotSize = 12
GGXX.useThickLines = false
GGXX.boxesPerLayer = 50
-- game-specific constants
GGXX.boxtypes = boxtypes
-- 2byte health値は初期値460、health減らして検索
-- healthアドレス - 0x1E してキャラIDアドレス算出
-- キャラIDアドレスを保持している4byteポインタ値を検索
GGXX.playerPtrs = { 0x006D1378, 0x006D4C84 } -- GGXX.playerPtrs = { 0x00516778, 0x0051A07C } -- pointers to pointers
-- "start" here is a pointer-to-pointer
-- 飛び道具はcameraPtr address - 0x4958で算出
GGXX.projectilesListInfo = { start = 0x006D137C, step = 0x130, count = 20 } --GGXX.projectilesListInfo = { start = 0x0051677C, step = 0x130, count = 20 }
GGXX.pushBoxTargetPointers = {
-- 下記値のアドレスを検索
-- 0C800000, 27100000
-- 0BB80000, 32C80000
-- 0BB80000, 32C80000
	{ 0x00573154, 0x00573B38 }, -- { 0x003D5124, 0x003D5B08 },
	{ 0x00573B6C, 0x00571E6C }, -- { 0x003D5B3C, 0x003D3E3C },
	{ 0x00571564, 0x00571E6C }, -- { 0x003D3534, 0x003D3E3C },
}
-- 4byte xCenter値はズームイン時中央0、右端44000、左端-44000
-- xCenterアドレス - 0x10 してカメラ先頭アドレスを調べる
-- カメラアドレスを保持している4byteポインタ値を検索
GGXX.cameraPtr = 0x006D5CD4 --GGXX.cameraPtr = 0x0051B0D4
GGXX.startupMessage = [[
This game has known issues.
* Grab boxes are currently not displayed.
* The projectile hitbox on Millia 236H is incorrect.]]

function GGXX:extraInit(noExport)
	if not noExport then types:export(ffi) end
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.projectileBuf = ffi.new("projectile")
	self.boxBuf = ffi.new("hitbox")
	self.pushBoxBuf = ffi.new("pushbox")
	self.wordBuf = ffi.new("word[1]")
	self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
		self.boxSlotConstructor, self.boxtypes)
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", (self.projectilesListInfo.count + 2), self.pivotSlotConstructor)
	self.zoom = 1.0
	luautil.ifNotEmpty(self.startupMessage)
end

function GGXX:relocate(base)
	local target = self.playerPtrs
	for i = 1, #target do
		target[i] = target[i] + base
	end
	target = self.pushBoxTargetPointers
	for i = 1, #target do
		for j = 1, #target[i] do
			target[i][j] = target[i][j] + base
		end
	end
	target = self.projectilesListInfo
	target.start = target.start + base
	self.cameraPtr = self.cameraPtr + base
end

function GGXX:captureState()
	local cam = self.camera
	self:read(self.cameraPtr, cam)
	self.zoom = cam.zoom / 100

	self.boxset:reset()
	self.pivots:reset()
	self:capturePlayerStates()
	if self.projectilesEnabled then
		self:captureProjectiles()
	end
end

function GGXX:capturePlayerStates()
	local players, extras = self.players, self.playerExtras
	local playerPtrs, player, extra, playerPtr = self.playerPtrs
	local pivotColor = self.pivotColor
	for i = 1, 2 do
		if not self.playersEnabled[i] then goto continue end
		playerPtr = self:readPtr(playerPtrs[i])
		if playerPtr ~= 0 then
			player, extra = players[i], extras[i]
			self:read(playerPtr, player)
			if player.playerExtraPtr ~= 0 then
				self:read(player.playerExtraPtr, extra)
				self:captureEntity(player, extra, false, pivotColor)
			end
		end
		::continue::
	end
end

function GGXX:captureProjectiles()
	local proj, projInfo = self.projectileBuf, self.projectilesListInfo
	local count, step = projInfo.count, projInfo.step
	local projPtr = self:readPtr(projInfo.start)
	local pivotColor = self.projectilePivotColor
	if projPtr == 0 then return end
	for i = 1, count do
		self:read(projPtr, proj)
		if proj.projStatus ~= 0 then
			self:captureEntity(proj, nil, true, pivotColor)
		end
		projPtr = projPtr + step
	end
end

function GGXX:captureEntity(player, extra, isProjectile, pivotColor)
	local boxset, boxAdder = self.boxset, self.addBox
	local boxBuf, bt, boxtype = self.boxBuf, self.boxtypes, "dummy"
	local boxPtr, boxCount = player.boxPtr, player.boxCount
	local facing = self:facingMultiplier(player)
	local invul = (extra and extra.invul) or 0
	if isProjectile then invul = 0 end
	local hitboxActive = (not isProjectile) or (player.projActive ~= -1)

	for i = 1, boxCount do
		self:read(boxPtr, boxBuf)
		boxtype = bt:typeForID(boxBuf.boxType)
		if boxtype == "dummy" then goto continue end
		if (boxtype == "vulnerable") and (invul ~= 0) then goto continue end
		if (boxtype == "attack") and not hitboxActive then goto continue end
		if isProjectile then boxtype = bt:asProjectile(boxtype) end
		boxset:add(boxtype, boxAdder, self, player, boxBuf, facing, false)
		::continue::
		boxPtr = boxPtr + 0x0C
	end

	if not isProjectile then
		local pushbox, wordBuf = self.pushBoxBuf, self.wordBuf
		local adjust, flags = player.characterID * 2, player.status
		local index = 3
		if band(flags, 0x400) ~= 0 then index = 1
		elseif band(flags, 0x20000) ~= 0 then index = 2 end
		local source = self.pushBoxTargetPointers[index]
		local targetX, targetY = source[1] + adjust, source[2] + adjust
		self:read(targetX, wordBuf)
		pushbox.width = wordBuf[0]
		self:read(targetY, wordBuf)
		pushbox.height = wordBuf[0]
		boxset:add("collision", boxAdder, self, player, pushbox, facing, true)
	end

	local px, py = player.xPivot, player.yPivot
	pivotColor = (pivotColor or colors.WHITE)
	self.pivots:add(self.addPivot, pivotColor, self:worldToScreen(px, py))
end

function GGXX:facingMultiplier(player)
	return ((player.facing == 0) and 1) or -1
end

function GGXX:deriveBoxPosition(player, hitbox, facing, isPushbox)
	local px, py = player.xPivot, player.yPivot
	local w, h, x1, y1, x2, y2 = hitbox.width, hitbox.height
	if isPushbox then
		x1, y1 = px - w, py - h
		x2, y2 = px + w, py
	else
		w, h = w * 100, h * 100
		x1, y1 = hitbox.xOffset * 100, hitbox.yOffset * 100
		x1, y1 = px + (x1 * facing), py + y1
		x2, y2 = x1 + (w * facing), y1 + h
	end
	x1, y1 = self:worldToScreen(x1, y1)
	x2, y2 = self:worldToScreen(x2, y2)
	return x1, y1, x2, y2
end

function GGXX:worldToScreen(x, y)
	local cam = self.camera
	local ground, z = self.basicHeight, self.zoom
	x = ((x - cam.leftEdge) * z)
	y = ((y - cam.bottomEdge) * z)
	y = ground + y
	return floor(x), floor(y)
end

-- "addFn" passed as parameter to BoxSet:add()
function GGXX.addBox(target, parent, player, hitbox, facing, isPushbox)
	if hitbox.width <= 0 or hitbox.height <= 0 then return false end
	local x1, y1, x2, y2 = parent:deriveBoxPosition(
		player, hitbox, facing, isPushbox)
	target.left, target.top = x1, y1
	target.right, target.bottom = x2, y2
	return true
end

-- "renderFn" passed as parameter to BoxSet:render()
function GGXX.drawBox(hitbox, parent, pivotSize, drawFill)
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	local edge, fill = colorPair[1], (drawFill and colorPair[2]) or colors.CLEAR
	parent:box(x1, y1, x2, y2, edge, fill)
	return 1
end

-- "renderFn" passed as parameter to BoxList:render()
function GGXX.drawPivot(pivot, parent, pivotSize)
	parent:pivot(pivot.x, pivot.y, pivotSize, pivot.color)
	return 1
end

function GGXX:renderState()
	self.boxset:render(self.drawBox, self,
		self.boxPivotSize, self.drawBoxFills)
	if self.drawPlayerPivot then
		self.pivots:render(self.drawPivot, self, self.pivotSize)
	end
end

return GGXX

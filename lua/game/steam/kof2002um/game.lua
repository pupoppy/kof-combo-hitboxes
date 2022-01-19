local colors = require("render.colors")
local boxtypes = require("game.steam.kof2002um.boxtypes")
local BoxSet = require("game.boxset")
local KOF98 = require("game.steam.kof98um.game")
local KOF02 = KOF98:new({ parent = KOF98, whoami = "KOF02" })

KOF02.configSection = "kof2002um"
-- game-specific constants
KOF02.boxtypes = boxtypes
KOF02.revisions = {
	["Steam"] = {
		-- 2022-01-19 game updated: adjust offset +0193C0h
		playerPtrs = { 0x040BA19C, 0x040BA3BC }, --playerPtrs = { 0x0167C3A0, 0x0167C5C0 },
		playerExtraPtrs = { 0x040AAF8C, 0x040AB2A4 }, -- playerExtraPtrs = { 0x0167EA00, 0x01683240 },
		cameraPtr = 0x040C251C, --cameraPtr = 0x02208BF8,
		projectilesListInfo = { start = 0x40ABC1C, count = 34, step = 0x220 }, --projectilesListInfo = { start = 0x0166DE20, count = 34, step = 0x220 },
	},
	["GOG.com"] = {
		playerPtrs = { 0x01BD33C0, 0x01BD35E0 },
		playerExtraPtrs = { 0x01BBFB80, 0x01BBFE98 },
		cameraPtr = 0x01BE0758,
		projectilesListInfo = { start = 0x01BC4A00, count = 41, step = 0x220 },
	},
}
KOF02.extraRecommendation = [[
Additionally, please set Screen to Type B in Game Options, Graphic Settings.]]

function KOF02:extraInit(noExport)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
end

function KOF02:setupGauges()
	self.parent.setupGauges(self)
	self.drawGuardGauge = false -- guard gauge is already displayed in-game
	local g = self.gauges
	local newWidth, newY = 121, 31 + self.absoluteYOffset
	for _, gauge in pairs(g[1]) do
		gauge.width, gauge.y = newWidth, newY
		gauge.x = 24
	end
	for _, gauge in pairs(g[2]) do
		gauge.width, gauge.y = newWidth, newY
		gauge.x = 174
	end
	-- hide the stun gauge (02UM only has stun via a single instant-stun move)
	for i = 1, 2 do
		g[i].stun.fillColor = colors.CLEAR
		g[i].stun.borderColor = colors.CLEAR
	end
end

return KOF02

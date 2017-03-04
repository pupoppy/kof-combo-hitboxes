local colors = require("render.colors")
local KOF_Common = {}

-- slot constructor function passed to BoxSet:new()
function KOF_Common.boxSlotConstructor(i, slot, boxtypes)
	return {
		centerX = 0, centerY = 0, width = 0, height = 0,
		colorPair = boxtypes:colorForType(slot),
	}
end

-- slot constructor function passed to BoxSet:new()
function KOF_Common.pivotSlotConstructor()
	return { x = 0, y = 0, color = colors.WHITE }
end

-- "addFn" passed as parameter to BoxSet:add();
-- this function is responsible for actually writing the new box set entry
function KOF_Common.addBox(target, parent, cx, cy, w, h)
	if w <= 0 or h <= 0 then return false end
	target.centerX, target.centerY = parent:worldToScreen(cx, cy)
	target.left,  target.top    = parent:worldToScreen(cx - w, cy - h)
	target.right, target.bottom = parent:worldToScreen(cx + w - 1, cy + h - 1)
	return true
end

-- "addFn" passed as parameter to BoxSet:add()
function KOF_Common.addPivot(target, color, x, y)
	target.color, target.x, target.y = color, x, y
	return true
end

-- "renderFn" passed as parameter to BoxSet:render()
function KOF_Common.drawBox(hitbox, parent, pivotSize)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	parent:box(x1, y1, x2, y2, colorPair[1], colorPair[2])
	parent:pivot(cx, cy, parent.boxPivotSize, colorPair[1])
	return 1
end

function KOF_Common.drawPivot(pivot, parent, pivotSize)
	parent:pivot(pivot.x, pivot.y, pivotSize, pivot.color)
	return 1
end

function KOF_Common:renderState()
	self.boxset:render(self.drawBox, self, self.boxPivotSize)
	self.pivots:render(self.drawPivot, self, self.pivotSize)
end

return KOF_Common

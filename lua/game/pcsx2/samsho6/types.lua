local commontypes = require("game.commontypes")
local types = commontypes:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- "Absolute" address references are given relative to the start of PCSX2's
-- emulated game RAM area, unless otherwise noted.  Add the value of
-- PCSX2_Common.RAMbase (see game/pcsx2/common.lua) in order to get the
-- "real" absolute address in PCSX2's memory space.  This also applies when
-- dereferencing pointer values within the game's emulated RAM space.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
types.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */
static const int PLAYERS = 2;

// Location in memory: 0x01E53CB4
typedef struct {
	byte padding01[0x004];    // +000h to +004h: Unknown
	float centerX;            // +004h: X position of center of screen
	// Y = 120.0 when both players are standing on solid ground.
	// Y value increases as camera moves upward.
	float y;                  // +008h: Camera Y position
	// Screen width is equal to 320.0 when the screen is fully zoomed in.
	// Increases as the screen gradually zooms out, to a maximum of 444.0.
	float width;              // +00Ch: Width of visible area
} camera;

// Locations in memory: 0x01E55FC0 (P1), 0x01E560F8 (P2)
typedef struct {
	byte padding01[0x03A];    // +000h to +03Ah: Unknown
	byte facing;              // +03Ah: Facing (00 = right, 08 = left)
	byte padding01[0x005];    // +03Bh to +040h: Unknown
	// Y is equal to 0 when standing on solid ground,
	// and increases as player moves upward (e.g., while jumping).
	floatPair position;       // +040h: X/Y axis coordinates
	byte padding02[0x008];    // +048h to +050h: Unknown
	fixed xSpeed;             // +050h: X velocity
	fixed xSpeedDelta;        // +054h: Adjustment to X velocity next frame
	byte padding03[0x004];    // +058h to +05Ch: Unknown
	fixed ySpeed;             // +05Ch: Y velocity
	fixed ySpeedDelta;        // +060h: Adjustment to Y velocity next frame
} player;

// Locations in memory: 0x01E5424C (P1), 0x01E55178 (P2)
typedef struct {
	byte padding01[0x018];    // +000h to +018h: Unknown
	dword superMeter;         // +018h: Super meter
	byte padding01[0x00C];    // +024h to +028h: Unknown
	dword attackMeter;        // +028h: Attack meter (below life bar)
	dword attackMeterLimit;   // +02Ch: Max. value of attack meter at +004h
	byte padding03[0x8F4];    // +030h to +924h: Unknown
	dword health;             // +924h: Life bar
} playerExtra;

// Locations in memory: 0x01E54140 (P1), 0x01E5506C (P2)
typedef struct {
	intptr_t player;          // +000h: Pointer to main "player" struct
} playerExtra2;

#pragma pack(pop)
]]

return types

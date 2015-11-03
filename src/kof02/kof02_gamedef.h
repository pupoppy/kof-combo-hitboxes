#ifndef NO_KOF_02
#include "../boxtypes.h"
#include "../gamedefs.h"
#include "kof02_roster.h"
#include "kof02_boxtypemap.h"

gamedef_t kof02_gamedef = {
	.windowTitle = "King of Fighters 2002 Unlimited Match",
	.shortName = "King of Fighters 2002UM (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448 or 796x448",
	.extraRecommendations = "Additionally, please set your game to Type B under Options, Graphics Settings.",
	.aspectMode = AM_PILLARBOX,
	.playerAddresses = {
		(player_t*)0x0167C3A0,
		(player_t*)0x0167C5C0
	},
	/* // TODO
	.playerExtraAddresses = {
		(player_extra_t*)0x
		(player_extra_t*)0x
	},
	.player2ndExtraAddresses = {
		(player_2nd_extra_t*)0x
		(player_2nd_extra_t*)0x
	},
	//*/
	.cameraAddress = (camera_t*)0x02208BF8,
	.rosterSize = KOF_02_ROSTER_SIZE,
	.roster = (character_def_t*)&kof02_roster,
	.boxTypeMap = (boxtype_t*)&kof02_boxTypeMap
};
#endif /* NO_KOF_02 */

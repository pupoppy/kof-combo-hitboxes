#include "playerstruct.h"

const facing_t FACING_LEFT = 0, FACING_RIGHT = 1;
const costume_t
	COSTUME_A  = 0, COSTUME_B  = 1, COSTUME_C  = 2, COSTUME_D  = 3,
	COSTUME_CD = 4, COSTUME_AB = 5, COSTUME_AD = 6, COSTUME_BC = 7;

void *CAMERA_ADDR = 0x0180C938;
#define P1_MAIN_STRUCT_ADDR 0x0170D000
#define P2_MAIN_STRUCT_ADDR 0x0170D200
void *PLAYER_STRUCT_ADDRS[] = {
	P1_MAIN_STRUCT_ADDR, P2_MAIN_STRUCT_ADDR
};

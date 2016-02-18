#ifndef BOXTYPES_H
#define BOXTYPES_H

#include <stdlib.h>

typedef enum {
	BOX_COLLISION, // pushbox
	BOX_VULNERABLE,
	BOX_COUNTER_VULN,
	BOX_ANYWHERE_VULN,
	BOX_OTG_VULN,
	BOX_GUARD,
	BOX_ATTACK,
	BOX_PROJECTILE_VULN,
	BOX_PROJECTILE_ATTACK,
	BOX_THROWABLE,
	BOX_THROW,
	validBoxTypes, // this must come immediately after the last valid box type
	// box types not meant for rendering onscreen start here
	BOX_DUMMY, // inactive boxes (don't render them onscreen)
	totalBoxTypes // this must come last
} boxtype_t;

extern char *boxTypeNames[];

// shorthand forms for box type mappings
#define b_x  BOX_DUMMY
#define b_c  BOX_COLLISION 
#define b_v  BOX_VULNERABLE
#define b_vc BOX_COUNTER_VULN
#define b_va BOX_ANYWHERE_VULN
#define b_vo BOX_OTG_VULN
#define b_g  BOX_GUARD
#define b_a  BOX_ATTACK
#define b_pv BOX_PROJECTILE_VULN
#define b_pa BOX_PROJECTILE_ATTACK
#define b_tv BOX_THROWABLE
#define b_t  BOX_THROW

#endif /* BOXTYPES_H */

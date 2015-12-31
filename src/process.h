#ifndef PROCESS_H
#define PROCESS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wingdi.h>
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501 /* this is silly */
#include <uxtheme.h>
#undef _WIN32_WINNT
#include <GL/gl.h>
#include <GL/glu.h>
#include <stdlib.h>
#include <stdbool.h>
#include "gamestate.h"

typedef HRESULT (WINAPI *dwm_extend_frame_fn)(HWND, PMARGINS);
typedef HRESULT (WINAPI *dwm_comp_enabled_fn)(BOOL *);

extern bool detectGame(game_state_t *target, gamedef_t *gamedefs[]);
extern void establishScreenDimensions(screen_dimensions_t *dims, gamedef_t *source);
extern bool openGame(game_state_t *target, HINSTANCE hInstance, WNDPROC wndProc);
extern void closeGame(game_state_t *target);

#endif /* PROCESS_H */
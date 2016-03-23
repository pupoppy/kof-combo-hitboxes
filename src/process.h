#ifndef PROCESS_H
#define PROCESS_H

#define WIN32_LEAN_AND_MEAN
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <tchar.h>
#include <winuser.h>
#include <wingdi.h>
#include <uxtheme.h>
#undef _WIN32_WINNT
#define CINTERFACE
#include <d3d9.h>
#include <d3dx9.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "directx.h"
#include "gamedefs.h"
#include "gamestate.h"
#include "controlkey.h"
#include "util.h"
#include "colors.h"
#include "config.h"

typedef HRESULT (WINAPI *dwm_extend_frame_fn)(HWND, PMARGINS);
typedef HRESULT (WINAPI *dwm_comp_enabled_fn)(BOOL *);

extern void startupProgram(HINSTANCE hInstance);
extern void cleanupProgram();
extern bool detectGame(game_state_t *target, gamedef_t *gamedefs[]);
extern void establishScreenDimensions(screen_dimensions_t *dims, gamedef_t *source);
extern bool openGame(game_state_t *target, HINSTANCE hInstance, WNDPROC wndProc);
extern void closeGame(game_state_t *target);
extern bool checkShouldContinueRunning(char **reason);
extern bool checkShouldRenderScene();

#endif /* PROCESS_H */

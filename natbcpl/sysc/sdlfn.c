/*
This is the natbcpl version of sdlfn.c

This contains the implemetation of the sys(Sys_sdl, fno, ...) facility.

Implemented by Martin Richards (c) June 2013

24/09/12
Added joystick events


Specification of res := sys(Sys_sdl, fno, a1, a2, a3, a4,...)

Note that this calls sdlfn(args, g)
where args[0] = fno, args[1]=a1,... etc
and   g points to the base of the global vector.

fno=0  Test the sdl is available
       res is TRUE if the sdl features are implemented.

fno=1 ...
*/

#include "bcpl.h"

#ifndef SDLavail
BCPLWORD sdlfn(BCPLWORD *args, BCPLWORD *g, BCPLWORD *W) {
    return 0;   // SDL is not available
}
#endif


#ifdef SDLavail
// SDL is available

#include <stdio.h>
#include <stdlib.h>
#include "sdldraw.h"

#ifdef forWIN32
#include <SDL.h>
#else
#include <SDL/SDL.h>
#endif

#ifdef GLavail
#include <GL/gl.h>
#include <GL/glu.h>
#endif

// These must agree with the declarations in g/sdl.h
#define sdl_avail           0
#define sdl_init            1
#define sdl_setvideomode    2
#define sdl_quit            3
#define sdl_locksurface     4
#define sdl_unlocksurface   5
#define sdl_getsurfaceinfo  6
#define sdl_getfmtinfo      7
#define sdl_geterror        8
#define sdl_updaterect      9
#define sdl_loadbmp        10
#define sdl_blitsurface    11
#define sdl_setcolorkey    12
#define sdl_freesurface    13
#define sdl_setalpha       14
#define sdl_imgload        15
#define sdl_delay          16
#define sdl_flip           17
#define sdl_displayformat  18
#define sdl_waitevent      19
#define sdl_pollevent      20
#define sdl_getmousestate  21
#define sdl_loadwav        22
#define sdl_freewav        23
// more to come ...

#define sdl_wm_setcaption  24
#define sdl_videoinfo      25
#define sdl_maprgb         26
#define sdl_drawline       27
#define sdl_drawhline      28
#define sdl_drawvline      29
#define sdl_drawcircle     30
#define sdl_drawrect       31
#define sdl_drawpixel      32
#define sdl_drawellipse    33
#define sdl_drawfillellipse   34
#define sdl_drawround      35
#define sdl_drawfillround  36
#define sdl_drawfillcircle 37
#define sdl_drawfillrect   38

#define sdl_fillrect       39
#define sdl_fillsurf       40
// Joystick functions
#define sdl_numjoysticks       41
#define sdl_joystickopen       42
#define sdl_joystickclose      43
#define sdl_joystickname       44
#define sdl_joysticknumaxes    45
#define sdl_joysticknumbuttons 46
#define sdl_joysticknumballs   47
#define sdl_joysticknumhats    48

#define sdl_joystickeventstate 49
#define sdl_getticks           50
#define sdl_showcursor         51
#define sdl_hidecursor         52
#define sdl_mksurface          53
#define sdl_setcolourkey       54

#define sdl_joystickgetbutton  55
#define sdl_joystickgetaxis    56
#define sdl_joystickgetball    57
#define sdl_joystickgethat     58

#define gl_setvideomode        200
#define gl_avail               201
#define gl_ShadeModel          202
#define gl_CullFace            203
#define gl_FrontFace           204
#define gl_Enable              205
#define gl_ClearColor          206
#define gl_ViewPort            207
#define gl_MatrixMode          208
#define gl_LoadIdentity        209
#define glu_Perspective        210
#define gl_Clear               211
#define gl_Translate           212
#define gl_Begin               213
#define gl_End                 214
#define gl_Color4v             215
#define gl_Vertex3v            216
#define gl_SwapBuffers         217
#define gl_Rotate              218



BCPLWORD decodeevent(SDL_Event*e, BCPLWORD *ptr) {
  if(e) {
    ptr[0] = (BCPLWORD)(e->type);
    switch (e->type) {
    default:
      printf("Unknown event type %d\n", e->type);
      return -1;

    case SDL_ACTIVEEVENT:      // 1
      ptr[1] = (BCPLWORD)(e->active).gain;  // 0 if loss, 1 if gain
      ptr[2] = (BCPLWORD)(e->active).state; // 0=mouse focus, 1=keyboard focus,
                                            // 2=minimised
      return -1;

    case SDL_KEYDOWN:          // 2
    case SDL_KEYUP:            // 3
    { SDL_keysym *ks = &(e->key).keysym;
      BCPLWORD sym = ks->sym;
      BCPLWORD mod = ks->mod;
      BCPLWORD ch = (BCPLWORD)(ks->unicode);
      if(ch==0) ch = sym;
      ptr[1] = mod;
      ptr[2] = ch;
      return -1;
    }

    case SDL_MOUSEMOTION:      // 4
      ptr[1] = (BCPLWORD)(e->motion).state;
      ptr[2] = (BCPLWORD)(e->motion).x;
      ptr[3] = (BCPLWORD)(e->motion).y;
      return -1;

    case SDL_MOUSEBUTTONDOWN:  // 5
    case SDL_MOUSEBUTTONUP:    // 6
      ptr[1] = (BCPLWORD)(e->button).state;
      ptr[2] = (BCPLWORD)(e->button).x;
      ptr[3] = (BCPLWORD)(e->button).y;
      return -1;

    case SDL_JOYAXISMOTION:    // 7
      ptr[1] = (BCPLWORD)(e->jaxis).which;  // Which joystick
      ptr[2] = (BCPLWORD)(e->jaxis).axis;   // Which axis
                                            // 0 = aileron
                                            // 1 = elevator
                                            // 2 = throttle
      ptr[3] = (BCPLWORD)(e->jaxis).value;  // What value  -32768 to + 32767
      return -1;

    case SDL_JOYBALLMOTION:    // 8
      ptr[1] = (BCPLWORD)(e->jball).which;  // Which joystick
      ptr[2] = (BCPLWORD)(e->jball).ball;   // Which ball
      ptr[3] = (BCPLWORD)(e->jball).xrel;   // X relative motion
      ptr[4] = (BCPLWORD)(e->jball).yrel;   // Y relative motion
      return -1;

    case SDL_JOYHATMOTION:     // 9
      ptr[1] = (BCPLWORD)(e->jhat).which;  // Which joystick
      ptr[2] = (BCPLWORD)(e->jhat).hat;    // Which hat
      ptr[3] = (BCPLWORD)(e->jhat).value;  // Hat position
      return -1;

    case SDL_JOYBUTTONDOWN:    // 10
    case SDL_JOYBUTTONUP:      // 11
      ptr[1] = (BCPLWORD)(e->jbutton).which;  // Which joystick
      ptr[2] = (BCPLWORD)(e->jbutton).button; // Which button
      ptr[3] = (BCPLWORD)(e->jbutton).state;  // What state
      return -1;

    case SDL_QUIT:             // 12
      return -1;

    case SDL_SYSWMEVENT:       // 13
      return -1;

    case SDL_VIDEORESIZE:      // 16
      ptr[1] = (BCPLWORD)(e->resize).w;  // New window width
      ptr[2] = (BCPLWORD)(e->resize).h;  // New window height
      printf("VIDEORESIZE=%d\n", SDL_VIDEORESIZE);
      return -1;

    case SDL_VIDEOEXPOSE:      // 17
      // Screen needs to be redrawn
      printf("VIDEOEXPOSE=%d\n", SDL_VIDEOEXPOSE);
      return -1;

    case SDL_USEREVENT:        // 24
      return -1;
    }
  }
  *ptr = 0;
  return 0;
}


BCPLWORD sdlfn(BCPLWORD *a, BCPLWORD *g, BCPLWORD *W) {
  char tmpstr[256];

  //printf("sdlfn: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
  //        a[0], a[1], a[2], a[3], a[4]);

  switch(a[0]) {
  default:
    printf("sdlfn: Unknown op: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
            a[0], a[1], a[2], a[3], a[4]);
    return 0;

  case sdl_avail: // Test whether SDL is available
    return -1;    // SDL is available

  case gl_avail:  // Test whether OpenGL is available
#ifdef GLavail
    return -1;    // OpenGL is available
#else
    return  0;    // OpenGL is not available
#endif

  case sdl_init:  // Initialise all SDL features
  { BCPLWORD res = (BCPLWORD) SDL_Init(SDL_INIT_EVERYTHING);
      // Enable Unicode translation of keyboard events.
    SDL_EnableUNICODE(1);
    SDL_JoystickEventState(SDL_ENABLE);
    //printf("sdl_init\n");
    return res;
  }

  case sdl_setvideomode:  // width, height, bbp, flags
  { SDL_Surface *scr;
    //printf("Calling SetVideoMode(%d, %d, %d, %8x)\n", a[1], a[2], a[3], a[4]);
    scr = SDL_SetVideoMode((int)a[1], (int)a[2], (int)a[3], (Uint32)a[4]);
    SDL_Flip(scr);
    return (BCPLWORD) scr;
    //return (BCPLWORD) SDL_SetVideoMode((int)a[1], (int)a[2], (int)a[3], (Uint32)a[4]);
  }

  case sdl_quit:      // Shut down SDL
    printf("sdl_quit\n");
    SDL_Quit();
    return -1;

  case sdl_locksurface: // surf
    // Return 0 on success
    // Return -1 on failure
    return (BCPLWORD) SDL_LockSurface((SDL_Surface*) a[1]);

  case sdl_unlocksurface: // surf
    SDL_UnlockSurface((SDL_Surface*) a[1]);
    return 0;

  case sdl_getsurfaceinfo:
  // surf, surfinfo -> [flag, format, w, h, pitch, pixels, cliprect, refcount]
  { SDL_Surface *surf = (SDL_Surface*)a[1];
    BCPLWORD *info = &W[a[2]];
    info[ 0] = (BCPLWORD) (surf->flags);
    info[ 1] = (BCPLWORD) (surf->format);
    info[ 2] = (BCPLWORD) (surf->w);
    info[ 3] = (BCPLWORD) (surf->h);
    info[ 4] = (BCPLWORD) (surf->pitch);
    info[ 5] = (BCPLWORD) (surf->pixels);
    //info[ 6] = (BCPLWORD) (surf->clip_rect); // fields: x,y, w, h
    info[ 7] = (BCPLWORD) (surf->refcount);
    //printf("getsurfaceinfo: format=%d\n", info[1]);
    return 0;        
  }

  case sdl_getfmtinfo:
  // fmt, pxlinfo -> [palette, bitspp, bytespp, rmask, gmask, rmask, amask,
  //                  rloss, rshift, gloss, gshift, bloss, bshift, aloss, ashift,
  //                  colorkey, alpha]
  { SDL_PixelFormat *fmt = (SDL_PixelFormat*)(a[1]);
    BCPLWORD *info = &(W[a[2]]);
    //printf("getfmtinfo: format=%d\n", (BCPLWORD)fmt);
    info[ 0] = (BCPLWORD) (fmt->palette);
    info[ 1] = (BCPLWORD) (fmt->BitsPerPixel);
    info[ 2] = (BCPLWORD) (fmt->BytesPerPixel);
    info[ 3] = (BCPLWORD) (fmt->Rmask);
    info[ 4] = (BCPLWORD) (fmt->Gmask);
    info[ 5] = (BCPLWORD) (fmt->Bmask);
    info[ 6] = (BCPLWORD) (fmt->Amask);
    info[ 7] = (BCPLWORD) (fmt->Rshift);
    info[ 8] = (BCPLWORD) (fmt->Gshift);
    info[ 9] = (BCPLWORD) (fmt->Bshift);
    info[10] = (BCPLWORD) (fmt->Ashift);
    info[11] = (BCPLWORD) (fmt->Rloss);
    info[12] = (BCPLWORD) (fmt->Gloss);
    info[13] = (BCPLWORD) (fmt->Rloss);
    info[14] = (BCPLWORD) (fmt->Aloss);
    info[15] = (BCPLWORD) (fmt->colorkey);
    info[16] = (BCPLWORD) (fmt->alpha);

    return 0;        
  }

  case sdl_geterror:   // str -- fill str with BCPL string for the latest SDL error
  { char *str = SDL_GetError();
    printf("sdl_geterror: %s\n", str);
    return c2b_str(str, a[1]); // Convert to BCPL string format
  }

  case sdl_updaterect: // surf, left, top, right, bottom
    return 0;     // Not yet available

  case sdl_loadbmp:    // filename of a .bmp image
  { char tmpstr[256];
    b2c_str(a[1], tmpstr);
    return (BCPLWORD) SDL_LoadBMP(tmpstr);
  }

  case sdl_mksurface: //(format, w, h)
  { SDL_PixelFormat *fmt = (SDL_PixelFormat*)(a[1]);
    Uint32 rmask = fmt->Rmask;
    Uint32 gmask = fmt->Gmask;
    Uint32 bmask = fmt->Bmask;
    Uint32 amask = fmt->Amask;
    //printf("rmask=%8x gmask=%8x bmask=%8x amask=%8x\n", rmask, gmask, bmask, amask);
    return (BCPLWORD)SDL_CreateRGBSurface(
                         SDL_SWSURFACE,
                         a[2], a[3], // Width, Height
                         32,     // Not using a palette
                         rmask, gmask, bmask, amask);
  }

  case sdl_blitsurface: // src, srcrect, dest, destrect
    //printf("blitsurface: %d, %d, %d, %d)\n", a[1], a[2], a[3], a[4]);
  { BCPLWORD *p = &W[a[4]];
    SDL_Rect dstrect = {p[0],p[1],p[2],p[3]};
    //printf("x=%d, y=%d, w=%d, h=%d\n", p[0], p[1], p[2], p[3]);
    return (BCPLWORD) SDL_BlitSurface((SDL_Surface*) a[1],
                                      (SDL_Rect*)    0,
                                      (SDL_Surface*) a[3],
                                      &dstrect);
  }

  case sdl_setcolourkey: //(surf, key)
    // If key=-1 unset colour key
    // otherwise set colour key to given value.
    // key must be in the pixel format of the given surface
    //printf("sdl_setcolourkey: %8x\n", a[2]);
    if(a[2]==-1) {
      return (BCPLWORD)SDL_SetColorKey((SDL_Surface*)a[1], 0, (Uint32)a[2]);
    } else {
      return (BCPLWORD)SDL_SetColorKey((SDL_Surface*)a[1], SDL_SRCCOLORKEY, (Uint32)a[2]);
    }

  case sdl_freesurface: // surf
    SDL_FreeSurface((SDL_Surface*)a[1]);
    return 0;

  case sdl_setalpha:    // surf, flags, alpha
    return 0;     // Not yet available

  case sdl_imgload:     // filename -- using the SDL_image library
    return 0;     // Not yet available

  case sdl_delay:       // msecs -- the SDL delay function
    SDL_Delay((int)a[1]);
    return 0;

  case sdl_getticks:    // return msecs since initialisation
    return (BCPLWORD)SDL_GetTicks();

  case sdl_showcursor:  // Show the cursor
    return (BCPLWORD)SDL_ShowCursor(SDL_ENABLE);

  case sdl_hidecursor:  // Hide the cursor
    return (BCPLWORD)SDL_ShowCursor(SDL_DISABLE);

  case sdl_flip:        // surf -- Double buffered update of the screen
    return (BCPLWORD) SDL_Flip((SDL_Surface*)a[1]);

  case sdl_displayformat: // surf -- convert surf to display format
    return 0;     // Not yet available

  case sdl_waitevent:    // (pointer) to [type, args, ... ] to hold details of the next event
                 // return 0 if no events available
    return 0;     // Not yet available

  case sdl_pollevent:    // (pointer) to [type, args, ... ] to hold details of
			 // the next event
    { SDL_Event test_event;
      if (SDL_PollEvent(&test_event))
      { decodeevent(&test_event, &W[a[1]]);
        return -1;
      }
      decodeevent(0, &W[a[1]]);
      return 0;
    }

  case sdl_getmousestate: // pointer to [x, y] returns bit pattern of buttons currently pressed
    return 0;     // Not yet available

  case sdl_loadwav:      // file, spec, buff, len
    return 0;     // Not yet available

  case sdl_freewav:      // buffer
    return 0;     // Not yet available

  case sdl_wm_setcaption:      // surf, string
  { char tmpstr[256];
    b2c_str(a[1], tmpstr);
    SDL_WM_SetCaption(tmpstr, 0);
    return 0;
  }

  case sdl_videoinfo:      // buffer
  { const SDL_VideoInfo* p = SDL_GetVideoInfo();
    BCPLWORD *info = &W[a[1]];
    info[ 0] = (BCPLWORD) ((p->hw_available) |
                           (p->hw_available)<<1 |
                           (p->blit_hw)<<2 |
                           (p->blit_hw_CC)<<3 |
                           (p->blit_hw_A)<<4 |
                           (p->blit_sw)<<5 |
                           (p->blit_sw_CC)<<6 |
                           (p->blit_sw_A)<<7
                          );
    info[ 1] = (BCPLWORD) (p->blit_fill);
    info[ 2] = (BCPLWORD) (p->video_mem);
    info[ 3] = (BCPLWORD) (p->vfmt);
    info[ 4] = (BCPLWORD) (p->vfmt->BitsPerPixel);
    //printf("videoinfo: a[2]=%d %8X %8X %d %d %d\n",
    //          a[2], info[0], info[1], info[2], info[3], info[4]);
 
    return 0;
  }


  case sdl_maprgb:      // format, r, g, b
  { 
    return (BCPLWORD) SDL_MapRGB((SDL_PixelFormat*)(a[1]), a[2], a[3], a[4]); 
  }

  case sdl_drawline:
  { SDL_Surface *surf = (SDL_Surface*)(a[1]);
    //printf("\nDraw Line: %d %d %d %d %d %8x\n", a[1], a[2], a[3], a[4], a[5], a[6]);
    Draw_Line(surf, a[2], a[3], a[4], a[5], a[6]);
    return 0;
  }

  case sdl_drawhline:
  case sdl_drawvline:
  case sdl_drawcircle:
  case sdl_drawrect:
  case sdl_drawpixel:
  case sdl_drawellipse:
  case sdl_drawfillellipse:
  case sdl_drawround:
  case sdl_drawfillround:
    return 0;

  case sdl_drawfillcircle:
  { SDL_Surface *surf = (SDL_Surface*)(a[1]);
    Draw_FillCircle(surf, a[2], a[3], a[4], a[5]);
    return 0;
  }
    //  case sdl_drawfillrect:
    //return  Draw_FillRect((SDL_Surface*)a[1], 500,200, 50,70, 0xF0FF00);

  case sdl_fillrect:
  { SDL_Rect rect = {a[2],a[3],a[4],a[5]};
    //printf("\nfillrect: surface=%d rect=(%d,%d,%d,%d) col=%8x\n",
    //       a[1], a[2], a[3], a[4], a[5], a[6]);
    SDL_FillRect((SDL_Surface*)(a[1]), &rect, a[6]);
    return 0;
  }

  case sdl_fillsurf:
    //printf("\nfillsurf: surface=%d col=%8x\n",
    //        a[1], a[2]);
    SDL_FillRect((SDL_Surface*)(a[1]), 0, a[2]);
    return 0;

// Joystick functions
  case sdl_numjoysticks:
    return SDL_NumJoysticks();

  case sdl_joystickopen:       // 42 (index) => joy
    return (BCPLWORD)SDL_JoystickOpen(a[1]);

  case sdl_joystickclose:      // 43 (joy)
    SDL_JoystickClose((SDL_Joystick *)a[1]);
    return 0;

  case sdl_joystickname:       // 44 (index)
  { const char *name = SDL_JoystickName(a[1]);
    return c2b_str(name, a[1]);
  }

  case sdl_joysticknumaxes:    // 45 (joy)
    return SDL_JoystickNumAxes((SDL_Joystick*)a[1]);

  case sdl_joysticknumbuttons: // 46 (joy)
    return SDL_JoystickNumButtons((SDL_Joystick*)a[1]);

  case sdl_joysticknumballs:   // 47 (joy)
    return SDL_JoystickNumBalls((SDL_Joystick*)a[1]);

  case sdl_joysticknumhats:    // 47 (joy)
    return SDL_JoystickNumHats((SDL_Joystick*)a[1]);

  case sdl_joystickeventstate: //49  sdl_enable=1 or sdl_ignore=0
    return SDL_JoystickEventState(a[1]);

  case sdl_joystickgetbutton: // 55 (joy)
    return SDL_JoystickGetButton((SDL_Joystick*)a[1], a[2]);

  case sdl_joystickgetaxis: // 56 (joy)
    return SDL_JoystickGetAxis((SDL_Joystick*)a[1], a[2]);

  case sdl_joystickgethat: // 58 (joy)
    return SDL_JoystickGetHat((SDL_Joystick*)a[1], a[2]);

  case gl_setvideomode: // 200 (width, height)
  { // Setup minimum bit sizes, a depth buffer and double buffering.
    const SDL_VideoInfo* info = NULL;
    int bpp = 0;
    SDL_Surface *scr;

    info = SDL_GetVideoInfo();
    if(!info) return 0;
    bpp = info->vfmt->BitsPerPixel;
    printf("bpp=%d width=%d height=%d\n", bpp, a[1], a[2]);
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    printf("Calling SDL_SetVideoMode\n");
    scr = SDL_SetVideoMode((int)a[1], (int)a[2], bpp, SDL_OPENGL);
    return (BCPLWORD)scr;
  }

#ifdef GLavail
  case gl_ShadeModel:
    //printf("gl_ShadeModel: a[1]=%d GL_SMOOTH=%d\n", a[1], GL_SMOOTH);
    //glShadeModel((int)a[1]);
    //glShadeModel(GL_SMOOTH);
    return 0;
  case gl_CullFace:
    //printf("gl_CullFace: %d GL_BACK=%d\n", a[1], GL_BACK);
    //glCullFace(a[1]);
    glCullFace(GL_BACK);
    return 0;
  case gl_FrontFace:
    //printf("gl_FrontFace: %d\n", a[1]);
    //printf("   GL_CCW=%d\n", GL_CCW);
    //glFrontFace(a[1]);
    glFrontFace(GL_CCW);
    return 0;
  case gl_Enable:
    //printf("gl_Enable: %d\n", a[1]);
    //printf("   GL_CULLFACE=%d\n", GL_CULL_FACE);
    glEnable(a[1]);
    return 0;
  case gl_ClearColor:
    //printf("gl_ClearColor: %d %d %d %d\n", a[1], a[2], a[3], a[4]);
    glClearColor(a[1]/255.0, a[2]/255.0, a[3]/255.0, a[4]/255.0);
    return 0;
  case gl_ViewPort:
    //printf("gl_Viewport: %d %d %d %d\n", a[1], a[2], a[3], a[4]);
    glViewport(a[1], a[2], a[3], a[4]);
    //glViewport(0, 0, 800, 500);
    return 0;
  case gl_MatrixMode:
    //printf("gl_MatrixMode: %d\n", a[1]);
    //printf("   GL_PROJECTION=%d\n", GL_PROJECTION);
    //printf("   GL_MODELVIEW=%d\n", GL_MODELVIEW);
    glMatrixMode(a[1]);
    return 0;
  case gl_LoadIdentity:
    //printf("gl_LoadIdentity:\n");
    glLoadIdentity();
    return 0;
  case glu_Perspective:
    //printf("gl_Perspective: %d %d %d %d\n", a[1], a[2], a[3], a[4]);
    gluPerspective(((float)a[1])/1000000, ((float)a[2])/1000000,
                   ((float)a[3])/1000, ((float)a[4])/1000);  
    //gluPerspective(60.0, 800.0/500.0, 1.0, 1024.0);
    return 0;
  case gl_Clear:
    //printf("gl_Clear: #x%8X\n", a[1]);
    //printf("   GL_COLOR_BUFFER_BIT=%8X\n", GL_COLOR_BUFFER_BIT);
    //printf("   GL_DEPTH_BUFFER_BIT=%8X\n", GL_DEPTH_BUFFER_BIT);
    glClear(a[1]);
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return 0;
  case gl_Translate:
    //printf("gl_Translate: %d %d %d\n", a[1], a[2], a[3]);
    glTranslatef(a[1]/1000.0, a[2]/1000.0, a[3]/1000.0);
    return 0;
  case gl_Rotate:
    //printf("gl_Rotate: %d %d %d %d\n", a[1], a[2], a[3], a[4]);
    glRotatef(a[1]/1000000.0, a[2]/1000.0, a[3]/1000.0, a[4]/1000.0);
    return 0;
  case gl_Begin:
    //printf("gl_Begin: %d\n", a[1]);
    //printf("   GL_TRIANGLES=%d\n", GL_TRIANGLES);
    glBegin(a[1]);
    return 0;
  case gl_End:
    //printf("gl_End:\n");
    glEnd();
    return 0;
  case gl_Color4v:
    //printf("gl_Color4v: %d\n", a[1]);
    glColor4ub(W[a[1]], W[a[1]+1], W[a[1]+2], W[a[1]+3]);
    return 0;
  case gl_Vertex3v:
    //printf("gl_Vertex3v: %d -> [%d %d %d]\n", a[1], W[a[1]], W[a[1]+1], W[a[1]+2]);
    glVertex3f(W[a[1]]/1000.0, W[a[1]+1]/1000.0, W[a[1]+2]/1000.0);
    return 0;
  case gl_SwapBuffers:
    //printf("gl_SwapBuffers:\n");
    SDL_GL_SwapBuffers();
    return 0;
#endif

// more to come ...

  }
}
#endif

/*!
  \file sdldrawtest.c
  \author Mario Palomo <mpalomo@ihman.com>
  \date 05-2002

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this library; if not, write to the Free Foundation,
  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
#ifdef WIN32
#include <windows.h>
#endif

#include "cintsys.h"

#include <stdlib.h>
#include "SDL.h"

#include "sdldraw.h"

/*Hardware surfaces*/
Uint32 FastestFlags(Uint32 flags, unsigned int width, unsigned int height,
 unsigned int bpp)
{
  const SDL_VideoInfo *info;

  flags |= SDL_FULLSCREEN;

  info = SDL_GetVideoInfo();
  if ( info->blit_hw_CC && info->blit_fill ) {
    flags |= SDL_HWSURFACE;
  }

  if ( (flags & SDL_HWSURFACE) == SDL_HWSURFACE ) {
    if ( info->video_mem*1024 > (height*width*bpp/8) ) {
      flags |= SDL_DOUBLEBUF;
    } else {
      flags &= ~SDL_HWSURFACE;
    }
  }

  return flags;
}

/*----------------------------------------------------------------------*/
#ifdef WIN32
int WINAPI WinMain(HINSTANCE hInstance,
                   HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine,
                   int iCmdShow)
{
  return main(__argc, __argv);
}
#endif //WIN32
/*----------------------------------------------------------------------*/
int main(int argc, char *argv[])
{
  SDL_Surface *screen;
  int width, height;
  Uint8  video_bpp;
  Uint32 videoflags;
  int done;
  SDL_Event event;
  Uint32 then, now, frames;

  if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
    fprintf(stderr, "SDL_Init problem: %s", SDL_GetError());
    exit(1);
  }
  atexit(SDL_Quit);

  videoflags = SDL_SWSURFACE | SDL_ANYFORMAT;
  width = 640;
  height = 480;
  video_bpp = 0;

  while ( argc > 1 ) {
      --argc;
           if ( strcmp(argv[argc-1], "-width") == 0 ) {
      width = atoi(argv[argc]);
      --argc;
    } else if ( strcmp(argv[argc-1], "-height") == 0 ) {
      height = atoi(argv[argc]);
      --argc;
    } else if ( strcmp(argv[argc-1], "-bpp") == 0 ) {
      video_bpp = atoi(argv[argc]);
      videoflags &= ~SDL_ANYFORMAT;
      --argc;
    } else if ( strcmp(argv[argc], "-fast") == 0 ) {
      videoflags = FastestFlags(videoflags, width, height, video_bpp);
    } else if ( strcmp(argv[argc], "-hw") == 0 ) {
      videoflags ^= SDL_HWSURFACE;
    } else if ( strcmp(argv[argc], "-flip") == 0 ) {
      videoflags ^= SDL_DOUBLEBUF;
    } else if ( strcmp(argv[argc], "-fullscreen") == 0 ) {
      videoflags ^= SDL_FULLSCREEN;
    } else {
      fprintf(stderr, "Use: %s [-bpp N] [-hw] [-flip] [-fast] [-fullscreen]\n",
              argv[0]);
      exit(1);
    }
  }/*while*/

  /*Video mode activation*/
  screen = SDL_SetVideoMode(width, height, video_bpp, videoflags);
  if (!screen) {
    fprintf(stderr, "I can not activate video mode: %dx%d: %s\n",
            width, height, SDL_GetError());
    exit(2);
  }

{/*BEGIN*/
  Uint32 c_white = SDL_MapRGB(screen->format, 255,255,255);
  Uint32 c_gray = SDL_MapRGB(screen->format, 200,200,200);
  Uint32 c_dgray= SDL_MapRGB(screen->format, 64,64,64);
  Uint32 c_cyan = SDL_MapRGB(screen->format, 32,255,255);

  //SDL_Rect r = {100,300,50,50};
  //SDL_SetClipRect(screen, &r);  //Test of clipping code

  frames = 0;
  then = SDL_GetTicks();
  done = 0;
  while( !done ) {
  
  Draw_Line(screen, 100,100, 30,0, c_white);
  Draw_Line(screen, 30,0, 100,100, c_white);

  Draw_Line(screen, 100,100, 30,0, c_white);
  Draw_Line(screen, 30,0, 100,100, c_white);
  Draw_Line(screen, 0,0, 100,100, c_white);
  Draw_Line(screen, 100,100, 300,200, c_white);
  Draw_Line(screen, 200,300, 250,400,
                SDL_MapRGB(screen->format, 128,128,255));
  Draw_Line(screen, 500,50, 600,70,
                SDL_MapRGB(screen->format, 128,255,128));
  Draw_Line(screen, 500,50, 600,70,
                SDL_MapRGB(screen->format, 128,255,128));
  //Draw_Circle(screen, 100+frames%200, 100, 50, c_white);
  Draw_Circle(screen, 100+(frames/3)%200, 100+(frames/2)%173, 50,
              SDL_MapRGB(screen->format, 128+frames,255+frames,68+frames));

  /*-------------*/
  Draw_Circle(screen, 150,150, 5, c_white);
  Draw_Circle(screen, 150,150, 4,
                 SDL_MapRGB(screen->format, 64,64,64));
  Draw_Circle(screen, 150,150, 3,
                 SDL_MapRGB(screen->format, 255,0,0));
  Draw_Circle(screen, 150,150, 2,
                 SDL_MapRGB(screen->format, 0,255,0));
  Draw_Circle(screen, 150,150, 1,
                 SDL_MapRGB(screen->format, 0,0,255));
  /*-------------*/

  Draw_Line(screen, 500,100, 600,120,
                SDL_MapRGB(screen->format, 128,255,128));
  Draw_Circle(screen, 601,121, 2, c_white);

  Draw_Circle(screen, 400,200, 2, c_white);
  Draw_Line(screen, 400,200, 409,200, c_white);
  Draw_Circle(screen, 409,200, 2, c_white);
  Draw_Line(screen, 400,200, 400,250, c_white);
  Draw_Circle(screen, 400,250, 2, c_white);
  Draw_Line(screen, 409,200, 400,250, c_white);


  Draw_Line(screen, 400,300, 409,300, c_gray);
  Draw_Line(screen, 400,300, 400,350, c_gray);
  Draw_Line(screen, 409,300, 400,350, c_dgray);
  Draw_Rect(screen, 398,298, 4,4, c_cyan);
  Draw_Rect(screen, 407,298, 4,4, c_cyan);
  Draw_Rect(screen, 398,348, 4,4, c_cyan);

  Draw_HLine(screen, 10,400, 50, c_white);
  Draw_VLine(screen, 60,400, 360, c_white);
  Draw_Rect(screen, 500,400, 50,50, c_white);
  Draw_Pixel(screen, 510,410, c_white);
  Draw_Pixel(screen, 520,420,
             SDL_MapRGB(screen->format, 255,0,0));
  Draw_Pixel(screen, 530,430,
             SDL_MapRGB(screen->format, 0,255,0));
  Draw_Pixel(screen, 540,440,
             SDL_MapRGB(screen->format, 0,0,255));


  Draw_Ellipse(screen, 100,300, 60,30, c_white);
  
  Draw_FillEllipse(screen, 300,300, 30,60,
               SDL_MapRGB(screen->format, 64,64,200));
  Draw_Ellipse(screen, 300,300, 30,60,
               SDL_MapRGB(screen->format, 255,0,0));

  Draw_Round(screen, 200,20, 70,50, 10, c_white);
  Draw_Round(screen, 300,20, 70,50, 20,
             SDL_MapRGB(screen->format, 255,0,0));
  Draw_FillRound(screen, 390,20, 70,50, 20,
                 SDL_MapRGB(screen->format, 255,0,0));
  Draw_Round(screen, 390,20, 70,50, 20, c_cyan);

  /*Draw_Round(screen, 500,400, 5,3, 4, c_cyan);*/

  Draw_Rect(screen, 499,199, 52,72,
            SDL_MapRGB(screen->format, 255,255,0));
  //Draw_FillRect(screen, 500,200, 50,70,
  //              SDL_MapRGB(screen->format, 64,200,64));

  Draw_FillCircle(screen, 500,330, 30, c_cyan);

  SDL_UpdateRect(screen, 0, 0, 0, 0);



    ++frames;
    while ( SDL_PollEvent(&event) ) {
      switch (event.type) {
        case SDL_KEYDOWN:
        /*break;*/
        case SDL_QUIT:
          done = 1;
        break;
        default:
        break;
      }
    }/*while*/
  }/*while(!done)*/

}/*END*/

  now = SDL_GetTicks();
  if ( now > then ) {
    printf("%2.2f frames per second\n",
          ((double)frames*1000)/(now-then));
  }

  fprintf(stderr, "[END]\n");
  return 0;

}/*main*/
/*----------------------------------------------------------------------*/


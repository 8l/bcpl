#include <stdio.h>
#include "SDL/SDL.h"

int main(int argc, char*args[]) {
  SDL_Surface *screen = NULL;
  SDL_Surface *hello = NULL;

  // Start SDL
  SDL_Init(SDL_INIT_EVERYTHING);

  //Set up screen
  screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE);

  if(screen==0) {
    printf("\nscreen=0 %s\n", SDL_GetError());
  }

  SDL_WM_SetCaption("Hello World", NULL);

  //Load image
  hello = SDL_LoadBMP("demo.bmp");

  //Apply image to screen
  SDL_BlitSurface(hello, NULL, screen, NULL);

  //Update screen
  SDL_Flip(screen);

  //Pause for 5 secs
  SDL_Delay(5000);

  //Free the loaded image
  SDL_FreeSurface(hello);

  //Quit SDL
  SDL_Quit();

  return 0;
}

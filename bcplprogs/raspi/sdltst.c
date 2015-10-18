#include <stdio.h>
#include "SDL/SDL.h"

int main(int argc, char*args[]) {
  SDL_Surface *screen = NULL;
  SDL_Surface *hello = NULL;
  int rc, i;

  // Start SDL
  SDL_Init(SDL_INIT_EVERYTHING);

  //Set up screen
  screen = SDL_SetVideoMode(640, 480, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);

  if(screen==0) {
    printf("\nscreen=0 %s\n", SDL_GetError());
  }

  SDL_WM_SetCaption("Hello World", NULL);

  //Load image
  printf("Loading demo.bmp\n");
  hello = SDL_LoadBMP("demo.bmp");

  if(hello==0) {
    printf("Can't load demo.bmp\n");
  }

  for(i=1; i<=4; i++) {
    //Apply image to screen
    rc = SDL_BlitSurface(hello, NULL, screen, NULL);
    if(rc) printf("BlitSursface returned %d\n", rc);

    //Update screen
    printf("Calling Flip\n");
    SDL_Flip(screen);

    //Pause for 2 secs
    SDL_Delay(2000);
  }

  //Free the loaded image
  SDL_FreeSurface(hello);

  //Quit SDL
  SDL_Quit();

  return 0;
}

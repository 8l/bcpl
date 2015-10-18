/*
This contains the implemetation of the sys(Sys_gl, fno, ...) facility.

###### Still under development ############

Implemented by Martin Richards (c) Mar 2015

This file is planned to provide and interface to either OpenGL using SDL or
OpenGL ES using EGL (typically for the Raspberry Pi).  To hide the differences
between these two versions of OpenGL, BCPL programs should use the g/gl.b
library with the g/gl.h header file.

SDLavail is defined only if GL is called from SDL
GLavail is defined if OpenGL or OpenGL ES libraries are available.
EGLavail is defined if GL is called from EGL

Note that RaspiGL uses EGL to call GL but also uses some features provided by
the SDL libraries. SDLavail and EGLavail will never both be defined.

Whichever version of OpenGL is used the BCPL interface using

res := sys(Sys_gl, fno, a1, a2, a3, a4,...)

has the same effect.

Note that this calls glfn(args, g, w)
where args[0] = fno, args[1]=a1,... etc
and   g points to the base of the global vector,
and   w points to the base of the Cintcode memory.

fno=0  Test that a version of OpenGL is available
       res is TRUE if it is.

fno=1 ...
*/

#include "cintsys.h"

extern char *b2c_str(BCPLWORD bstr, char *cstr);
extern BCPLWORD c2b_str(const char *cstr, BCPLWORD bstr);

#include <stdio.h>
#include <stdlib.h>

#ifdef forRaspiGL
#define GLavail
#define EGLavail
#endif

#ifndef GLavail
BCPLWORD glfn(BCPLWORD *args, BCPLWORD *g, BCPLWORD *W) {
  //printf("glfn: GLavail was not defined\n");
    return 0;   // GL is not available
}
#endif

#ifdef GLavail

// If SDLavail include the SDL headers since GL is being called from SDL
// and EGL is not present.
#ifdef SDLavail
#ifdef forWIN32
#include <SDL.h>
#else
#include <SDL/SDL.h>
#endif
#endif

// RaspiGL uses EGL to call GL but also uses some SDL features.
#ifdef forRaspiGL

#include <assert.h>

#include "bcm_host.h"
#include "GLES2/gl2.h"
#include "EGL/egl.h"
#include "EGL/eglext.h"
// If RaspiGL we use SDL to access keyboard, Mouse and Joystick events
// so include the SDL headers
#include <SDL.h>
#endif

#ifndef forRaspiGL
#include <GL/gl.h>
//#include <GL/glu.h>
//#include <GL/glut.h>
#include <EGL/egl.h>
#endif


#ifdef GLavail
// These must agree with the declarations in g/gl.h
#define gl_Init                1
#define gl_SetFltScale         2
#define gl_Quit                3
#define gl_GetError            4
#define gl_MkScreen            5
#define gl_SwapBuffers         6
#define gl_MkProg              7
#define gl_CompileVshader      8
#define gl_CompileFshader      9
#define gl_GetAttribLocation  10
#define gl_GetUniformLocation 11
#define gl_DeleteShader       12
#define gl_UseProgram         13
#define gl_LinkProgram        14
#define gl_Uniform1f          15
#define gl_Uniform2f          16
#define gl_Uniform3f          17
#define gl_Uniform4f          18
#define gl_BindAttribLocation 20
#define gl_UniformMatrix4fv   21
#define gl_ClearColour        22
#define gl_ClearBuffer        23
#define gl_M4mulM4            24
#define gl_pollevent          25
#define gl_Enable             26
#define gl_Disable            27
#define gl_DepthFunc          28
#define gl_VertexData         29
#define gl_DrawTriangles      30
#define gl_EnableVertexAttribArray 31
#define gl_DisableVertexAttribArray 32
#define gl_GenVertexBuffer    33
#define gl_GenIndexBuffer     34
#define gl_VertexAttribPointer 35
#define gl_M4mulV            36
#define gl_ScreenSize        37

// Joystick functions -- implemented using SDL
#define gl_numjoysticks       41
#define gl_joystickopen       42
#define gl_joystickclose      43
#define gl_joystickname       44
#define gl_joysticknumaxes    45
#define gl_joysticknumbuttons 46
#define gl_joysticknumballs   47
#define gl_joysticknumhats    48

#define gl_joystickeventstate 49

#define gl_joystickgetbutton  55
#define gl_joystickgetaxis    56
#define gl_joystickgetball    57
#define gl_joystickgethat     58



#endif

#ifdef EGLavail
typedef struct
{
   uint32_t screen_width;
   uint32_t screen_height;
// OpenGL|ES objects
   EGLDisplay display;
   EGLSurface surface;
   EGLContext context;

   GLuint verbose;
   GLuint vshader;
   GLuint fshader;
   GLuint mshader;
   GLuint program;
   GLuint program2;
   GLuint tex_fb;
   GLuint tex;
   GLuint buf;
// julia attribs
   GLuint unif_color, attr_vertex, unif_scale, unif_offset, unif_tex, unif_centre; 
// mandelbrot attribs
   GLuint attr_vertex2, unif_scale2, unif_offset2, unif_centre2;
} CUBE_STATE_T;

static CUBE_STATE_T _state, *state=&_state;

#define check() assert(glGetError() == 0)

#endif

typedef union fn {
  BCPLWORD i;
  GLfloat f;
} FN;

#ifdef SDLavail
const SDL_VideoInfo* info = NULL;
int width  = 700;
int height = 200;
int bpp = 0;
int flags=0; // Flag to pass to SDL_SetVideoMode
#endif

GLuint glProgram;


BCPLWORD decodeevent1(SDL_Event*e, BCPLWORD *ptr) {
  if(e) {
    ptr[0] = (BCPLWORD)(e->type);
    switch (e->type) {
    default:
      printf("glfn: Unknown event type %d\n", e->type);
      return -1;

    case SDL_ACTIVEEVENT:      // 1
      ptr[1] = (BCPLWORD)(e->active).gain;  // 0 if loss, 1 if gain
      ptr[2] = (BCPLWORD)(e->active).state; // 0=mouse focus, 1=keyboard focus,
                                            // 2=minimised
      return -1;

    case SDL_KEYDOWN:          // 2
    case SDL_KEYUP:            // 3
      //printf("getevent: KEYDOWN or UP\n");
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
      //printf("getevent: MOUSEMOTION %4d %4d %4d\n", ptr[1], ptr[2], ptr[3]);
      return -1;

    case SDL_MOUSEBUTTONDOWN:  // 5
    case SDL_MOUSEBUTTONUP:    // 6
      ptr[1] = (BCPLWORD)(e->button).state;
      ptr[2] = (BCPLWORD)(e->button).x;
      ptr[3] = (BCPLWORD)(e->button).y;
      //printf("getevent: MOUSEBUTTONDOWN/UP %4d %4d %4d\n", ptr[1], ptr[2], ptr[3]);
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
      //printf("VIDEORESIZE=%d\n", SDL_VIDEORESIZE);
      return -1;

    case SDL_VIDEOEXPOSE:      // 17
      // Screen needs to be redrawn
      //printf("VIDEOEXPOSE=%d\n", SDL_VIDEOEXPOSE);
      return -1;

    case SDL_USEREVENT:        // 24
      return -1;
    }
  }
  *ptr = 0;
  return 0;
}
#ifdef GLavail

BCPLWORD glfn(BCPLWORD *a, BCPLWORD *g, BCPLWORD *W) {
  char tmpstr[256];
  //int argc = 0;

  //printf("glfn: GLavail was defined\n");

  //printf("glfn: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
  //        a[0], a[1], a[2], a[3], a[4]);

  switch(a[0]) {
  default:
    printf("glfn: Unknown op: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
            a[0], a[1], a[2], a[3], a[4]);
    return 0;

#ifdef forRaspiGL
  case gl_Init:

   { //gl_init
   int32_t success = 0;
   EGLBoolean result;
   EGLint num_config;

   static EGL_DISPMANX_WINDOW_T nativewindow;

   DISPMANX_ELEMENT_HANDLE_T dispman_element;
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_UPDATE_HANDLE_T dispman_update;
   VC_RECT_T dst_rect;
   VC_RECT_T src_rect;

   static const EGLint attribute_list[] =
   {
      EGL_RED_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_BLUE_SIZE, 8,
      EGL_ALPHA_SIZE, 8,
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_DEPTH_SIZE, 16,
      EGL_NONE
   };
   
   static const EGLint context_attributes[] = 
   {
      EGL_CONTEXT_CLIENT_VERSION, 2,
      EGL_NONE
   };

   EGLConfig config;

   // RaspiGL uses some SDL features so initialise SDL
   //printf("Calling SDL_Init\n");

   { BCPLWORD res = (BCPLWORD) SDL_Init(SDL_INIT_EVERYTHING);
     // Enable Unicode translation of keyboard events.
     SDL_EnableUNICODE(1);
     SDL_JoystickEventState(SDL_ENABLE);
     printf("SDL_Init => %d\n", res);
   }

   printf("Calling bcm_host_init()\n");

   bcm_host_init();

   printf("Calling eglGetDisplay(..)\n");

   // get an EGL display connection
   state->display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
   if(state->display == EGL_NO_DISPLAY) {
     printf("ERROR: eglGetDisplay(..) failed\n");
     return 0;
   }

   // initialize the EGL display connection
   printf("Calling eglInitialize(..)\n");
   result = eglInitialize(state->display, NULL, NULL);
   if(result != EGL_TRUE) {
     printf("ERROR: eglInitialize(..) failed\n");
     return 0;
   }

   // Query the EGL implementation
   printf("Calling eglQueryString(..)\n");
   { const char *str = eglQueryString(state->display, EGL_CLIENT_APIS);
     printf("\nEGL_CLIENT_APIS = %s\n", str);
     str = eglQueryString(state->display, EGL_EXTENSIONS);
     printf("EGL_EXTENSIONS  = %s\n", str);
     str = eglQueryString(state->display, EGL_VENDOR);
     printf("EGL_VENDOR      = %s\n", str);
     str = eglQueryString(state->display, EGL_VERSION);
     printf("EGL_VERSION     = %s\n\n", str);
   }

   // get an appropriate EGL frame buffer configuration
   printf("Calling eglChooseConfig(..)\n");
   result = eglChooseConfig(state->display, attribute_list, &config, 1, &num_config);
   assert(EGL_FALSE != result);
   check();

   // get an appropriate EGL frame buffer configuration
   result = eglBindAPI(EGL_OPENGL_ES_API);
   assert(EGL_FALSE != result);
   check();

   // create an EGL rendering context
   printf("Calling eglCreateContext(..)\n");
   state->context = eglCreateContext(state->display, config, EGL_NO_CONTEXT, context_attributes);
   assert(state->context!=EGL_NO_CONTEXT);
   check();

   // create an EGL window surface
   printf("Calling graphics_get_display_size(..)\n");
   success = graphics_get_display_size(0 /* LCD */, &state->screen_width, &state->screen_height);
   assert( success >= 0 );

   dst_rect.x = 0;
   dst_rect.y = 0;
   dst_rect.width = state->screen_width;
   dst_rect.height = state->screen_height;
      
   printf("width=%d  height=%d\n", dst_rect.width, dst_rect.height);

   src_rect.x = 0;
   src_rect.y = 0;
   src_rect.width = state->screen_width << 16;
   src_rect.height = state->screen_height << 16;        

   printf("Calling vc_dispmanx_display_open(..)\n");

   dispman_display = vc_dispmanx_display_open( 0 /* LCD */);
   dispman_update = vc_dispmanx_update_start( 0 );
         
   dispman_element = vc_dispmanx_element_add ( dispman_update, dispman_display,
      0/*layer*/, &dst_rect, 0/*src*/,
      &src_rect, DISPMANX_PROTECTION_NONE, 0 /*alpha*/, 0/*clamp*/, 0/*transform*/);
      
   nativewindow.element = dispman_element;
   nativewindow.width = state->screen_width;
   nativewindow.height = state->screen_height;
   vc_dispmanx_update_submit_sync( dispman_update );
      
   check();

   state->surface = eglCreateWindowSurface( state->display, config, &nativewindow, NULL );
   assert(state->surface != EGL_NO_SURFACE);
   check();

   // connect the context to the surface
   result = eglMakeCurrent(state->display, state->surface, state->surface, state->context);
   assert(EGL_FALSE != result);
   check();

   // Set background color and clear buffers
   //glClearColor(0.15f, 0.25f, 0.35f, 1.0f);
   glClearColor(0.95f, 0.65f, 0.35f, 1.0f);
   glClear( GL_COLOR_BUFFER_BIT );

   check();

   eglSwapBuffers(state->display, state->surface);
   check();

   return -1;
   }
#endif

#ifdef SDLavail
   // This is for systems that use SDL to call GL

  case gl_Init:  // Initialise all SDL features

    { int argc = 0;
      BCPLWORD res = (BCPLWORD) SDL_Init(SDL_INIT_EVERYTHING);
      //BCPLWORD res = 0; //(BCPLWORD) SDL_Init(SDL_INIT_VIDEO);
      if (res<0) {
        fprintf(stderr, "Video initialization failed: %s\n", "error");
		//	SDL_GetError());
        return 0;
        //SDL_Quit();
      }

      //printf("glfn: SDL_init returned ok\n");

      info = SDL_GetVideoInfo();
  
      if( !info ) {
        fprintf(stderr, "Video query failed: %s\n",
                SDL_GetError());
        SDL_Quit();
        exit(0);
      }

      bpp = info->vfmt->BitsPerPixel;
      printf("bpp=%d\n", bpp);

      SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
      SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
      SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
      SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
      SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

      return -1;
    }
#endif


    case gl_Quit:      // Shut down SDL
#ifdef SDLavail
      SDL_Quit();
#else
      printf("Calling eglTerminate(..)\n");
      eglTerminate(state->display);
#endif
      return -1;

#ifdef SDLavail

      ///*
    case gl_GetError:   // str -- fill str with BCPL string for the latest SDL error
    { char *str = SDL_GetError();
      printf("sdl_GetError: %s\n", str);
      return c2b_str(str, a[1]); // Convert to BCPL string format
    }
    //*/
#endif

#ifdef EGLavail
    case gl_MkScreen: // (title, width, height)
      printf("EGLavail: gl_MkScreen does nothing\n");
      return -1; // Success
#endif

#ifdef SDLavail
    case gl_MkScreen: // (title, width, height)
    { char tmpstr[256];
      int i;
      char *title = (char *)(a[1]);
      SDL_Surface *scr;

      width  = a[2];
      height = a[3];

      flags = SDL_OPENGL;

      printf("glfn: SDLavail: gl_MkScreen width=%d height=%d\n",
	     width, height);

      //printf("Calling SetVideoMode(%d, %d, %d, %8x)\n", a[1], a[2], a[3], a[4]);
      scr = SDL_SetVideoMode(width, height, bpp, flags);

      if(scr==0){
        fprintf(stderr, "Video mode set failed: %s\n",
                SDL_GetError());
        SDL_Quit();
        exit(0);
      }

      b2c_str(a[1], tmpstr);

      //printf("gl_MkScreen: title=%s width=%d height=%d\n",
      //        tmpstr, a[2], a[3]);
      SDL_WM_SetCaption(tmpstr, 0);

      // Enable Unicode translation of keyboard events.
      SDL_EnableUNICODE(1);
      SDL_JoystickEventState(SDL_ENABLE);

      printf("gl_MkScreen: setting result2 height=%d\n", height);
      g[Gn_result2] = height;
      printf("gl_MkScreen: returning width=%d\n", width);
      return width;
      //return (BCPLWORD) scr;
    }
#endif

    case gl_MkProg: // ()
    { GLuint prog =  glCreateProgram();
      //printf("glfn: glCreateProgram => %d\n", prog);
      return (BCPLWORD) prog;
    }

    case gl_CompileVshader: // (prog, cstr)
    { // Compiler the vertex shader whose source is in the
      // C string cstr, and attach it to the given GL program.
      GLuint prog = (GLuint) a[1];
      const char* cstr = (char *) (&W[a[2]]);

      GLuint Vshader = glCreateShader(GL_VERTEX_SHADER);

      glShaderSource(Vshader, 1, &cstr, NULL);
      glCompileShader(Vshader);

      GLint nCompileResult = 0;

      glGetShaderiv(Vshader, GL_COMPILE_STATUS, &nCompileResult);

      if(!nCompileResult)
      { int i;
        char Log[1024];
        GLint nLength;
        glGetShaderInfoLog(Vshader, 1024, &nLength, Log);
        for(i=0; i<nLength; i++) printf("%c", Log[i]);
        printf("\n");
      }      

      glAttachShader(prog, Vshader);
      return Vshader;
    }

    case gl_CompileFshader: // (prog, cstr)
    { // Compiler the fragment shader whose source is in the
      // C string cstr, and attach it to the given GL program.
      GLuint prog = (GLuint) a[1];
      const char* cstr = (char *) (&W[a[2]]);
      GLuint Fshader = glCreateShader(GL_FRAGMENT_SHADER);

      glShaderSource(Fshader, 1, &cstr, NULL);
      glCompileShader(Fshader);

      GLint nCompileResult = 0;

      glGetShaderiv(Fshader, GL_COMPILE_STATUS, &nCompileResult);

      if(!nCompileResult)
      { int i;
        char Log[1024];
        GLint nLength=20;
        glGetShaderInfoLog(Fshader, 1024, &nLength, Log);
        for(i=0; i<nLength; i++) printf("%c", Log[i]);
        printf("\n");
      }      

      glAttachShader(prog, Fshader);
      return Fshader;
    }

    case gl_LinkProgram: // (prog)
    { GLuint prog = (GLuint)a[1];
      glLinkProgram(prog);

      GLint nLinkResult = 0;

      glGetProgramiv(prog, GL_LINK_STATUS, &nLinkResult);

      if(!nLinkResult)
      { int i;
        char Log[1024];
        GLint nLength;
        glGetProgramInfoLog(prog, 1024, &nLength, Log);
        for(i=0; i<nLength; i++) printf("%c", Log[i]);
        printf("\n");
      }
      //printf("glfn: gl_LinkProgram returning -1\n");
      return -1;
    }

#ifdef XXX
    case gl_BindAttribLocation: // (prog, loc, name)
    { // Specify the location of an attribute before linking
      GLuint prog = (GLuint) a[1];
      GLuint loc  = (GLuint) a[2];
      b2c_str(a[3], tmpstr);
      printf("glfn: BindAttribLocation prog=%d loc=%d name=%s\n", prog, loc, tmpstr);
      return (BCPLWORD) glBindAttribLocation(prog, loc, tmpstr);
    }

    case gl_Uniform1f: // (loc, x)
    { // Set 1 uniform element
      FN x;
      GLuint  loc   = (GLuint) a[1];
      x.i = a[2];
      printf("glfn: Uniform1f loc=%7d value=%6.3g\n", loc, (float)x.f);
      return (BCPLWORD) glUniform1f(loc, (float)x.f);
    }

    case gl_Uniform2f: // (loc, x, y)
    { // Set 2 uniform elements
      FN x;
      FN y;
      GLuint  loc   = (GLuint) a[1];
      x.i = a[2];
      y.i = a[3];
      //printf("glfn: Uniform2f loc=%7d values: %6.3g %6.3g\n",
      //        loc, x.f, y.f);
      return (BCPLWORD) glUniform2f(loc, (float)x.f, (float)y.f);
    }

    case gl_Uniform3f: // (loc, x, y, z)
    { // Set 3 uniform elements
      FN x;
      FN y;
      FN z;
      GLuint  loc   = (GLuint) a[1];
      x.i = a[2];
      y.i = a[3];
      z.i = a[4];
      //printf("glfn: Uniform3f loc=%7d values: %6.3f %6.3f %6.3f\n",
      //        loc, x.f, y.f, z.f);
      //return (BCPLWORD) glUniform3f(loc, (float)x.f, (float)y.f, (float)z.f);
      return (BCPLWORD) glUniform3f(loc, 1.0f, 0.0f, 0.0f);
    }

    case gl_Uniform4f: // (loc, x, y, z, w)
    { // Set 4 uniform elements
      FN x;
      FN y;
      FN z;
      FN w;
      GLuint  loc   = (GLuint) a[1];
      x.i = a[2];
      y.i = a[3];
      z.i = a[4];
      w.i = a[5];
      //printf("glfn: Uniform4f loc=%7d values: %6.3g %6.3g %6.3g %6.3g\n",
      //        loc, x.f, y.f, z.f, w.f);
      return (BCPLWORD) glUniform4f(loc, (float)x.f, (float)y.f, (float)z.f, (float)w.f);
    }
#endif

    case gl_GetAttribLocation: // (prog, name)
    { // Find out where the linker put an attribute variable
      GLuint prog = (GLuint) a[1];
      b2c_str(a[2], tmpstr);
      //printf("glfn: GetAttribLocation prog=%d name=%s\n", prog, tmpstr);
      return (BCPLWORD) glGetAttribLocation(prog, tmpstr);
    }

    case gl_GetUniformLocation: // (prog, name)
    { // Find out where the linker put a uniform variable
      GLuint prog = (GLuint) a[1];
      GLint loc;
      b2c_str(a[2], tmpstr);
      loc = glGetUniformLocation(prog, tmpstr);
      printf("glfn: GetAttribLocation prog=%d name=%s  => loc=%d\n", prog, tmpstr, loc);
      return (BCPLWORD)loc;
    }

    case gl_UniformMatrix4fv: // (loc, prog, matrix) -- 4x4 matrix
    { 
      GLuint loc = (GLuint) a[1];
      GLuint prog = (GLuint) a[2];
      float *matrix = (float *) (&W[a[3]]);
      //int i;
      //for(i=0; i<16; i++) printf("%9.3f\n", matrix[i]);
      glUniformMatrix4fv(loc, prog, GL_FALSE, matrix);
      //return (BCPLWORD) glUniformMatrix4fv(loc, prog, GL_FALSE, matrix);
      return -1;
    }

    case gl_DeleteShader: // (shader)
    { GLuint shader = (GLuint) a[1];
      glDeleteShader(shader);
      return -1;
    }

    case gl_UseProgram: // (prog)
    { GLuint prog = (GLuint)a[1];
      glUseProgram(prog);
      return -1;
    }

    case gl_Enable: // (op)
    { GLint op = (GLint)a[1];
      glEnable(op);
      return -1;
    }

    case gl_Disable: // (op)
    { GLint op = (GLint)a[1];
      glDisable(op);
      return -1;
    }

    case gl_DepthFunc: // (relation)
    { GLint relation = (GLint)a[1];
      glDepthFunc(relation);
      return -1;
    }

    case gl_VertexData: // (loc, n, stride, datav))
    { // datav<32 the a vertex object is being used and datav is an offset
      // The are n vertex items each containing stride floating point numbers
      GLint loc = (GLint)a[1];
      GLint n = (GLint)a[2];
      GLint stride = (GLint)(a[3]*4);
      GLfloat *datav = (GLfloat *)((0<=a[4] && a[4]<32) ? (const void *)(a[4]*4) : &W[a[4]]);
      //int i;
      //printf("glfn: calling glVertexAttribPointer loc=%d n=%d stride=%d a[4]=%d\n",
      //     loc, n, stride, a[4]);
      //printf("glfn: calling       glVertexAttribPointer loc=%d n=%d stride=%d a[4]=%d\n",
      //     loc, n, a[3], a[4]);

      glVertexAttribPointer(loc,
                            n, GL_FLOAT,   // n elements of type float
                            GL_FALSE,      // Do not normalise
                            stride,        // Stride
                            datav);
      glEnableVertexAttribArray(loc);
      //printf("glfn: gl_VertexData loc=%d n=%d stride=%d\n", loc, n, stride);
      //for(i = 0; i<3; i++) printf("%3d: %5.3f\n", i, datav[i]);
      //printf("glfn: returned from glVertexAttribPointer loc=%d n=%d stride=%d a[4]=%d\n",
      //     loc, n, a[3], a[4]);
      return -1;
    }

    case gl_DrawTriangles: // (n, indexv)
      // n = number of index values ( ie 3*n/3 triangles)
      // indexv is a vector of 16-bit integers.
      // If indexv=0 objects are being used
    { GLint n = (GLint)(a[1]); // Number of index values
      GLushort *datav = (GLushort *)(a[2] ? &W[a[2]]: 0);

      //printf("glfn: gl_DrawTriangles n=%d a[2]=%d\n", n, a[2]);
      //int i;
      //for(i=0; i<24; i++)
      //  printf("glfn: DrawTriangles i=%2d  datav[i]=%d\n", i, datav[i]);
      glDrawElements(GL_TRIANGLES,
                     n,                 // Number of vertices
                     GL_UNSIGNED_SHORT, // Type of index elements
                     datav);            // Index data
      //printf("glfn: returned from gl_DrawTriangles n=%d\n", n);
      return -1;
    }

    case gl_EnableVertexAttribArray: // (attrib)
    { GLint attrib = (GLint)(a[1]);
      //printf("glfn: EnableVertexAttribArray(%d)\n", attrib);
      glEnableVertexAttribArray(attrib);
      return -1;
    }

    case gl_DisableVertexAttribArray: // (attrib)
    { GLint attrib = (GLint)(a[1]);
      printf("glfn: DisableVertexAttribArray(%d)\n", attrib);
      glDisableVertexAttribArray(attrib);
      return -1;
    }

    case gl_GenVertexBuffer: // (size, data)
    { GLint size = (GLint)a[1]; // Number of floats
      GLfloat *data = (GLfloat *)&W[a[2]];
      GLuint buffer;
      glGenBuffers(1, &buffer);
      glBindBuffer(GL_ARRAY_BUFFER, buffer);
      glBufferData(GL_ARRAY_BUFFER,        // Copy vertex data to graphics memory
                   size * sizeof(GLfloat), // The size of data in bytes
                   data,                   // The vertex data
                   GL_STATIC_DRAW);        // Usage hint
      return (BCPLWORD)buffer;
    }

    case gl_GenIndexBuffer: // (data, size)
    { GLushort *data = (GLushort *)&W[a[1]];
      GLint size = (GLint)a[2]; // Number of 16-bit indices
      GLuint buffer;
      //int i;
      //for(i=0; i<size; i++) printf("glfn: i=%2d index=%3d\n", i, data[i]);
      glGenBuffers(1, &buffer);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, // Copy index data to graphics memory
                   size * sizeof(GLushort), // The size index data in bytes
                   data,                    // The vertex data
                   GL_STATIC_DRAW);         // Usage hint
      return (BCPLWORD)buffer;
    }

    case gl_ClearColour: // (r, g, b, a)
      glClearColor(a[1]/255.0f, a[2]/255.0f, a[3]/255.0f, a[4]/255.0f);
      return -1;

    case gl_ClearBuffer: // ()
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
      //glClear(GL_COLOR_BUFFER_BIT);
      return -1;

#ifdef EGLavail
    case gl_SwapBuffers: // ()
      eglSwapBuffers(state->display, state->surface);
      check();
      return -1;
#endif

#ifdef SDLavail
    case gl_SwapBuffers: // ()
      SDL_GL_SwapBuffers();
      return -1;
#endif

#ifdef SDLavail
  case gl_pollevent:    // (pointer) to [type, args, ... ] to hold details of
			// the next event
    { SDL_Event test_event;
      if (SDL_PollEvent(&test_event))
      { decodeevent(&test_event, &W[a[1]]);
        return -1;
      }
      decodeevent(0, &W[a[1]]);
      return 0;
    }
#endif

#ifdef forRaspiGL
    // RaspiGL uses SDL to pollevents
  case gl_pollevent:    // (pointer) to [type, args, ... ] to hold details of
			// the next event
    { SDL_Event test_event;
      if (SDL_PollEvent(&test_event))
      { decodeevent(&test_event, &W[a[1]]);
        return -1;
      }
      decodeevent(0, &W[a[1]]);
      return 0;
    }
#endif

    case gl_M4mulM4: // (A, B, C) performs C := A * B
    { float *A = (float *)(&W[a[1]]);
      float *B = (float *)(&W[a[2]]);
      float *C = (float *)(&W[a[3]]);
      float a00=A[ 0], a10=A[ 1], a20=A[ 2], a30=A[ 3];
      float a01=A[ 4], a11=A[ 5], a21=A[ 6], a31=A[ 7];
      float a02=A[ 8], a12=A[ 9], a22=A[10], a32=A[11];
      float a03=A[12], a13=A[13], a23=A[14], a33=A[15];

      float b00=B[ 0], b10=B[ 1], b20=B[ 2], b30=B[ 3];
      float b01=B[ 4], b11=B[ 5], b21=B[ 6], b31=B[ 7];
      float b02=B[ 8], b12=B[ 9], b22=B[10], b32=B[11];
      float b03=B[12], b13=B[13], b23=B[14], b33=B[15];

      //printf("gl_M4mulM4: entered %d %d %d\n", a[1], a[2], a[3]);

      //printf("%8.3f %8.3f %8.3f %8.3f \n",   a00, a01, a02, a03);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   a10, a11, a12, a13);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   a20, a21, a22, a23);
      //printf("%8.3f %8.3f %8.3f %8.3f \n\n", a30, a31, a32, a33);

      //printf("%8.3f %8.3f %8.3f %8.3f \n",   b00, b01, b02, b03);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   b10, b11, b12, b13);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   b20, b21, b22, b23);
      //printf("%8.3f %8.3f %8.3f %8.3f \n\n", b30, b31, b32, b33);

      C[ 0] = a00*b00 + a01*b10 + a02*b20 + a03*b30; // c00
      C[ 1] = a10*b00 + a11*b10 + a12*b20 + a13*b30; // c10
      C[ 2] = a20*b00 + a21*b10 + a22*b20 + a23*b30; // c20
      C[ 3] = a30*b00 + a31*b10 + a32*b20 + a33*b30; // c30

      C[ 4] = a00*b01 + a01*b11 + a02*b21 + a03*b31; // c01
      C[ 5] = a10*b01 + a11*b11 + a12*b21 + a13*b31; // c11
      C[ 6] = a20*b01 + a21*b11 + a22*b21 + a23*b31; // c21
      C[ 7] = a30*b01 + a31*b11 + a32*b21 + a33*b31; // c31

      C[ 8] = a00*b02 + a01*b12 + a02*b22 + a03*b32; // c02
      C[ 9] = a10*b02 + a11*b12 + a12*b22 + a13*b32; // c12
      C[10] = a20*b02 + a21*b12 + a22*b22 + a23*b32; // c22
      C[11] = a30*b02 + a31*b12 + a32*b22 + a33*b32; // c32

      C[12] = a00*b03 + a01*b13 + a02*b23 + a03*b33; // c03
      C[13] = a10*b03 + a11*b13 + a12*b23 + a13*b33; // c13
      C[14] = a20*b03 + a21*b13 + a22*b23 + a23*b33; // c23
      C[15] = a30*b03 + a31*b13 + a32*b23 + a33*b33; // c33

      //printf("%8.3f %8.3f %8.3f %8.3f \n",   C[0], C[4], C[ 8], C[12]);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   C[1], C[5], C[ 9], C[13]);
      //printf("%8.3f %8.3f %8.3f %8.3f \n",   C[2], C[6], C[10], C[14]);
      //printf("%8.3f %8.3f %8.3f %8.3f \n\n", C[3], C[7], C[11], C[15]);
      return 0;
    }

    case gl_M4mulV: // (A, B, C) performs C := A * B
                    // where A is a 4x4 matrix and B and C are
                    // 4 element vectors. B and C need not be distinct.
    { float *A = (float *)(&W[a[1]]);
      float *B = (float *)(&W[a[2]]);
      float *C = (float *)(&W[a[3]]);
      float a00=A[ 0], a10=A[ 1], a20=A[ 2], a30=A[ 3];
      float a01=A[ 4], a11=A[ 5], a21=A[ 6], a31=A[ 7];
      float a02=A[ 8], a12=A[ 9], a22=A[10], a32=A[11];
      float a03=A[12], a13=A[13], a23=A[14], a33=A[15];

      float b0=B[0], b1=B[1], b2=B[2], b3=B[3];
      C[0] = a00*b0 + a01*b1 + a02*b2 + a03*b3; // c0
      C[1] = a10*b0 + a11*b1 + a12*b2 + a13*b3; // c1
      C[2] = a20*b0 + a21*b1 + a22*b2 + a23*b3; // c2
      C[3] = a30*b0 + a31*b1 + a32*b2 + a33*b3; // c3

      return 0;
    }

    case gl_ScreenSize: // (@xsize, @ysize)
      printf("glfn: gl_ScreenSize called\n");
#ifdef EGLavail
      W[a[2]] = state->screen_width;
      W[a[3]] = state->screen_height;
#endif
      return -1;


// Joystick functions
  case gl_numjoysticks:
    return SDL_NumJoysticks();

  case gl_joystickopen:       // 42 (index) => joy
    return (BCPLWORD)SDL_JoystickOpen(a[1]);

  case gl_joystickclose:      // 43 (joy)
    SDL_JoystickClose((SDL_Joystick *)a[1]);
    return 0;

  case gl_joystickname:       // 44 (index)
  { const char *name = SDL_JoystickName(a[1]);
    return c2b_str(name, a[1]);
  }

  case gl_joysticknumaxes:    // 45 (joy)
    return SDL_JoystickNumAxes((SDL_Joystick*)a[1]);

  case gl_joysticknumbuttons: // 46 (joy)
    return SDL_JoystickNumButtons((SDL_Joystick*)a[1]);

  case gl_joysticknumballs:   // 47 (joy)
    return SDL_JoystickNumBalls((SDL_Joystick*)a[1]);

  case gl_joysticknumhats:    // 47 (joy)
    return SDL_JoystickNumHats((SDL_Joystick*)a[1]);

  case gl_joystickeventstate: //49  sdl_enable=1 or sdl_ignore=0
    return SDL_JoystickEventState(a[1]);

  case gl_joystickgetbutton: // 55 (joy)
    return SDL_JoystickGetButton((SDL_Joystick*)a[1], a[2]);

  case gl_joystickgetaxis: // 56 (joy)
    return SDL_JoystickGetAxis((SDL_Joystick*)a[1], a[2]);

  case gl_joystickgethat: // 58 (joy)
    return SDL_JoystickGetHat((SDL_Joystick*)a[1], a[2]);

  }
}
#endif
#endif


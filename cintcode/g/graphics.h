/*
This is the header file for the graphics library com/graphics.b

Implemented by Martin Richards (c) 9 December 2011

The manifest graphicsgbase must be declared before including
this header.
*/

GLOBAL {
opengraphics: g_grfbase
closegraphics

canvas      // Rectangular array of pixel bytes
canvassize  // Number of bytes in canvas
canvasupb   // UPB of canvas in words
xsize
ysize
colourtab   // Vector to map pixel bytes to RGB values
rowlen      // xsize rounded up to a multiple of 4 bytes
wrpixel     // (x,y,col)
wrpixel33   // (x,y,col)
plotx       // Current plotting x
ploty       // Cyrrent plotting y
plotcolour  // Current plotting colour
plotch      // (ch)
plotstr     // (s)
moveto      // (x,y)
moveby      // (dx,dy)
drawto      // (x,y)
drawby      // (dx,dy)
drawrect    // (x0,y0,x1,y1)
fillrect    // (x0,y0,x1,y1)
drawrndrect // (x0,y0,x1,y1,radius)
fillrndrect // (x0,y0,x1,y1, radius)
drawcircle  // (x0, y0, radius)
fillcircle  // (x0, y0, radius)
wrgraph     // (filename)
}

MANIFEST {
// Some colours
 col_white=   0
 col_rb   =  30
 col_b    =  70
 col_gb   = 110
 col_g    = 150
 col_rg   = 190
 col_r    = 230
 col_black= 255
}


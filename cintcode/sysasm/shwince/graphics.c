//======================================================================
// ceBCPL - The BCPL Cintcode System for Windows CE
//
// Written by Martin Richards (c) June 1999
//
// Functions relating to the graphics child window.
// 
//======================================================================
#include <windows.h>                 // For all that Windows stuff
#include <commdlg.h>                 // Command bar includes
#include "ceBCPL.h"                  // Program-specific stuff

extern INT32 *W;

typedef struct {
	BITMAPINFOHEADER bmih;
	COLORREF dwPal[256];
} DBMP;


BYTE *pxls = NULL;
int bpr;
int cx=100, cy=100; // Temporary values
int clrs = 8;
HBITMAP hDib=NULL;
BYTE *pbits;
DBMP bmp;
int bpp = 8; // Bits per pixel


//======================================================================
// Message handling procedures for GraphWindow
//
//----------------------------------------------------------------------
// TermWndProc - Callback function for Graphics window
//
LRESULT CALLBACK GraphWndProc (HWND hWnd, UINT wMsg, WPARAM wParam,
                               LPARAM lParam) {
    switch (wMsg) {
    default: return DefWindowProc   (hWnd, wMsg, wParam, lParam);
/*
    case WM_CHAR:
             return DoCharGraph      (hWnd, wMsg, wParam, lParam);
    case WM_DESTROY:
             return DoDestroyGraph   (hWnd, wMsg, wParam, lParam);
    case WM_SETFOCUS:
             return DoSetFocusGraph  (hWnd, wMsg, wParam, lParam);
    case WM_KILLFOCUS:
             return DoKillFocusGraph (hWnd, wMsg, wParam, lParam);
    case WM_SIZE:
             return DoSizeGraph      (hWnd, wMsg, wParam, lParam);
*/
    case WM_PAINT:
             return DoPaintGraph     (hWnd, wMsg, wParam, lParam);
/*
    case SCN_WRCH:
             return DoWrchGraph      (hWnd, wMsg, wParam, lParam);
*/
    }
}

//----------------------------------------------------------------------
// InitGraphics - Initialise the graphics window
//
void InitGraphics(HWND hwnd) {
    RECT rc;
    GetClientRect(hTermWnd, &rc);

    clrs = 8;
    cx = rc.right;
    cy = rc.bottom;

	bmp.bmih.biSize = sizeof (BITMAPINFOHEADER);
	bmp.bmih.biWidth         = cx;
	bmp.bmih.biHeight        = cy;
	bmp.bmih.biPlanes        = 1;
	bmp.bmih.biBitCount      = bpp;          // Bits per pixel
	bmp.bmih.biCompression   = BI_RGB;
	bmp.bmih.biSizeImage     = 0;
    bmp.bmih.biXPelsPerMeter = 0;
    bmp.bmih.biYPelsPerMeter = 0;
    bmp.bmih.biClrUsed       = clrs;
    bmp.bmih.biClrImportant  = clrs;

	bmp.dwPal[0] = 0xC00000;
	bmp.dwPal[1] = 0x0000FF;
	bmp.dwPal[2] = 0xFF00FF;
	bmp.dwPal[3] = 0x00FFFF;
	bmp.dwPal[4] = 0xFFFF00;
	bmp.dwPal[5] = 0x00FFFF;
	bmp.dwPal[6] = 0xFF00FF;
	bmp.dwPal[7] = 0x808080;
}

//----------------------------------------------------------------------
// DoPaintGraph - Process WM_PAINT message for Graphics window.
//
LRESULT DoPaintGraph (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    BYTE *p = pxls;
    int rowlen = bpr;
    PAINTSTRUCT ps;
    HDC hDC;
	HDC hOldSel;
	HDC hdcMem;

    InvalidateRect(hDC, NULL, FALSE);
    hDC = BeginPaint(hWnd, &ps);

	cx = ps.rcPaint.right;
	cy = ps.rcPaint.bottom;
	bpr = (((cx*bpp+31) & ~31)>>3); // Bytes per row

	 // Create a memory device context compatible with hDC
	hdcMem = CreateCompatibleDC(hDC);

    bmp.bmih.biWidth         = cx;
	bmp.bmih.biHeight        = cy;

    // create a device independent bitmap that can be written to directly
	if (hDib==NULL) hDib = CreateDIBSection(hDC, (BITMAPINFO *)&bmp,
		                                    DIB_RGB_COLORS,
			                         	    (void *)&pbits, NULL, 0);
	if (p &&
		cx ==((int *)p)[0] &&
		cy ==((int *)p)[1] &&
		bpr==((int *)p)[2]) {
          //printfd("copy %d\n", ((int *)p)[2]);
          memcpy(pbits, p+3*4, cy*bpr);
    }

	// select an object into the specified DC
	// the object can be a bitmap, Brush, Font, Pen or a Region
	// bitmaps can only be selected into memory DCs
	hOldSel = SelectObject(hdcMem, hDib);

    BitBlt(hDC, 2, 0, cx-4, cy, hdcMem, 0, 0, SRCCOPY);
    SelectObject(hdcMem, hOldSel);
	DeleteDC(hdcMem);
	//DeleteObject(hDib);

    EndPaint(hWnd, &ps);
    return 0;
}

extern INT32 sysGraphics(INT32 p) {
	switch (W[p+4]) {
		default: return 1234;
		
        case 3: SetWindowPos(hTermWnd, HWND_TOP,
		         0,0, 100,100,
				 SWP_NOSIZE+SWP_NOMOVE+SWP_SHOWWINDOW);
                return 0;
		case 4: SetWindowPos(hGraphicsWnd, HWND_TOP,
		         0,0, 100,100,
				 SWP_NOSIZE+SWP_NOMOVE+SWP_SHOWWINDOW);
                return 0;
        case 5: return cx;
		case 6: return cy;
        case 7: return bpr;
		case 8: // Display bit map image
                pxls = (BYTE *)&W[W[p+5]];
                InvalidateRect(hGraphicsWnd, NULL, FALSE);
                PostMessage(hGraphicsWnd, WM_PAINT, 0, 0);
    		    return 0;
		case 9: // Update Palette - sys(34, gr_palette, n, clrvec)
            {   int i;
                COLORREF *clrvec = (COLORREF *)&W[W[p+6]];
                clrs = W[p+5];
                for ( i = 0; i<clrs; i++) bmp.dwPal[i] = clrvec[i];
                bmp.bmih.biClrUsed       = clrs;
                bmp.bmih.biClrImportant  = clrs;
                if (hDib) {
                    DeleteObject(hDib);
                    hDib = NULL;
                }
                return 0;
            }
	}
}

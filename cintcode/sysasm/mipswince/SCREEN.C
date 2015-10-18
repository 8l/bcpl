/*****************************************************************************
This file implements a simple console interface for the ceBCPL system to
run under Windows CE 2.0.  It is loosely based on part of the Tty sample
program written by Microsoft.

  Copyright   Martin Richards (c) April 1999

screen.c

*****************************************************************************/

#include "windows.h"
#include "tchar.h"
#include "memory.h"

#include "ceBCPL.h"

int errorCount = 0;

void
error(TCHAR *mess) {
    if (++errorCount<=3)
        MessageBox(hTermWnd, mess, TEXT("ceBCPL System Error"), MB_OK);
}

//----------------------------------------------------------------------
// ScnPrintfs function
//
void ScnPrintfs(char *form, char *arg) {
    TCHAR szForm[128];
    TCHAR szArg[128];
    TCHAR szStr[128];
    int i;
    for (i=0; form[i]; i++) szForm[i] = (TCHAR)form[i];
    szForm[i] = 0;
    for (i=0; arg[i]; i++) szArg[i] = (TCHAR)arg[i];
    szArg[i] = 0;
    wsprintf (szStr, szForm, szArg);
    for (i=0; szStr[i]; i++) ScnWrch((BYTE)szStr[i]);
}

//----------------------------------------------------------------------
// ScnPrintfd function
//
void ScnPrintfd(char *form, INT arg) {
    TCHAR szForm[128];
    TCHAR szStr[128];
    int i;
    for (i=0; form[i]; i++) szForm[i] = (TCHAR)form[i];
    szForm[i] = 0;
    wsprintf (szStr, szForm, arg);
    for (i=0; szStr[i]; i++) ScnWrch((BYTE)szStr[i]);
}


void
ClearScreen()
{   Scn.Buf[0] = 0;       // Start with two empty lines
    Scn.Buf[1] = 0;       // used as Sentinal marks.
    Scn.Buf[2] = 0;       // Start of FirstLine

    Scn.FirstLine      = &Scn.Buf[2];
    Scn.LastLine       = Scn.FirstLine;
    Scn.LastLineNo     = 1;

    Scn.WinFirstLine   = Scn.FirstLine;
    Scn.WinFirstLineNo = 1;
    Scn.WinLastLine    = Scn.FirstLine;
    Scn.WinLastLineNo  = 1;
    Scn.WinIndent      = 0;

    Scn.CursorP        = Scn.FirstLine;
    Scn.CursorX        = 0;
    Scn.CursorY        = 0;

    Scn.LongestLine    = Scn.FirstLine;
    Scn.PrevMaxCols    = 1;
    Scn.MaxCols        = 1;
}

int Length(TCHAR *s) {
    int res = 0;
    while (*s++) res++;
    return res;
}

char *NextLineStart(char *p) {
    // On entry, p points to somewhere in a line.
    // It returns a pointer to the first character of the next line.
    while (*p++) continue;
    return p;
}

char *PrevLineStart(char *p) {
    // On entry, p points to somewhere in a line.
    // It returns a pointer to the first character of the previous line.
    // First find the end of the previous line.
    while (*--p) continue;
    // Then find the end of the line before that.
    while (*--p) continue;
    return p+1;
}

DWORD bits=0x123456;

void SetRandomColours() {
    // Set random colours to help debugging
    if (bits & 1) bits ^= 0xC01234;
    bits >>= 1;
    Scn.fgCol = bits;
    Scn.bgCol = ~bits & 0xFFFFFF;
}

void
PaintScreen (HWND hWnd, HDC hDC, RECT *pRect)
{
    // This paints the rectangular region of the client window of
    // hWnd. It is normally called to handle the WM_PAINT message
    // but is also called when part of the window needs immediate
    // update.
    // On entry, the following are correctly set:
    //   WinFirstLine, WinFirstLineNo,
    //   WinLastLine, WinLastLineNo,
    //   WinIndent, WinCols, WinRows,
    //   CharHeight and CharWidth
    // It paints all characters that lie in or intersect the rectangle,
    // having first painted the rectangle with the background colour.
    HFONT   oldhfont = NULL;
    HBRUSH  oldhBrush, hBrush;
    HPEN    oldhPen, hPen;
    TCHAR   CharV[256];
    int     X = pRect->left - pRect->left % Scn.CharWidth;
    int     Y = 0;
    char   *p = Scn.WinFirstLine;
    char   *q = Scn.WinLastLine;

    if(pRect==NULL) error(TEXT("pRect is NULL in PaintScreen"));

    //SetRandomColours(); // To help debugging

    // Paint the rectangle with the background colour
    hBrush = CreateSolidBrush(Scn.bgCol);
    oldhBrush = (HBRUSH)SelectObject(hDC, hBrush);
    hPen = CreatePen(PS_SOLID, 1, Scn.bgCol);
    oldhPen = (HPEN)SelectObject(hDC, hPen);
    Rectangle(hDC, pRect->left, pRect->top, pRect->right, pRect->bottom);
    if (oldhPen   != NULL) SelectObject (hDC, oldhPen);
    if (oldhBrush != NULL) SelectObject (hDC, oldhBrush);

    oldhfont = (HFONT)SelectObject(hDC, Scn.hFont);
    //SetRandomColours(); // To help debugging
    (void)SetTextColor(hDC, Scn.fgCol);
    (void)SetBkColor  (hDC, Scn.bgCol);

    while (p<=q) {
        char *np = NextLineStart(p);
        char *a, *b;
        int NY = Y + Scn.CharHeight;
        int n=0;

        // Deal with line starting at p.
        if (NY < pRect->top) {
            // The line is entirely above the rectangle.
            p = np;
            Y = NY;
            continue;
        }
        if (Y>=pRect->bottom) {
            // The line is entirely below the rectangle
            // so no more to paint.
            break;
        }

        a = p + Scn.WinIndent + pRect->left / Scn.CharWidth;
        b = p + Scn.WinIndent + pRect->right / Scn.CharWidth;
        if (b>np-2) b = np-2;
        if (b-a >= Scn.WinCols) b = a + Scn.WinCols - 1;
        while (a<=b) CharV[n++] = (TCHAR) *a++;
        ExtTextOut(hDC, X, Y, 0, NULL, CharV, n, NULL);

        p = np;
        Y = NY;
    }

    if (oldhfont != NULL) SelectObject (hDC, oldhfont);
}

void prDebug(TCHAR *mess) {
    HDC          hDC;
    HFONT hFont, oldhFont = NULL;
    TCHAR CharV[256];
    RECT rc;
    static int count = 0;
    int cX, X = 200;
    int cY, Y = 0;

    LOGFONT     lf;
    SIZE        sz;

    if (!Scn.Debug) return;

    GetClientRect(hTermWnd, &rc);
    count++;

    memset ((char *)&lf, 0, sizeof(lf));
    lf.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
    lf.lfHeight = 12;
    hFont = CreateFontIndirect (&lf);

    hDC = GetDC(hTermWnd);
    oldhFont = (HFONT)SelectObject (hDC, hFont);
    GetTextExtentPoint(hDC, TEXT("1234567890"), 10, &sz);
    cY = sz.cy;
    cX = sz.cx / 10; 

    HideCaret(hTermWnd);

    wsprintf (CharV, TEXT(" MaxCols = (%3d,%3d,%3d)"), 
                            Scn.PrevMaxCols,
                            Scn.CursorP-Scn.LastLine+1,
                            Scn.MaxCols);
    ExtTextOut(hDC, X, Y,     ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" XY = %3d(%3d), %3d(%3d)"), 
                            Scn.CursorX/Scn.CharWidth,
                            Scn.CursorX,
                            Scn.CursorY/Scn.CharHeight,
                            Scn.CursorY);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" Win size  = (%3d,%3d)  "), 
                            Scn.WinCols, Scn.WinRows);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" WinIndent      = %3d   "), 
                            Scn.WinIndent);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" char size = (%3d,%3d)  "), 
                            Scn.CharHeight, Scn.CharWidth);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" rc        = (%3d,%3d)  "),
                            rc.bottom, rc.right);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" Numbs = (%3d,%3d,%3d)  "), 
                            Scn.WinFirstLineNo, 
                            Scn.WinLastLineNo, 
                            Scn.LastLineNo);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" lines = (%3d,%3d,%3d)  "),
                            Scn.WinFirstLine-Scn.FirstLine, 
                            Scn.WinLastLine-Scn.FirstLine,
                            Scn.LastLine-Scn.FirstLine);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" HaveFocus = %3d        "),
                            Scn.HaveFocus);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" count = %5d          "),
                            count);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" %22s "), mess);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    wsprintf (CharV, TEXT(" Colours %6x %6x  "),
                       Scn.fgCol, Scn.bgCol);
    ExtTextOut(hDC, X, Y+=cY, ETO_OPAQUE, NULL, 
                       CharV, Length(CharV), NULL);

    if (oldhFont) SelectObject(hDC, oldhFont);
    ReleaseDC(hTermWnd, hDC);
    ShowCaret(hTermWnd);
//  Sleep(350);
}

void
SetScreenFont(int size) {
    // This changes the font to the specified size and updates the screen.
    // It is only called when all the Screen variables have
    // sensible values -- ie not until ClearScreen has been called
    // for the first time.
    //
    HDC         hDC = GetDC (hTermWnd);
    HFONT       oldhFont;
    LOGFONT     lf;
    SIZE        sz;

    memset ((char *)&lf, 0, sizeof(lf));
    lf.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
    lf.lfHeight = size;
    lf.lfWeight = size>24 ? FW_BOLD : 
                  size>16 ? FW_SEMIBOLD : 0;

    Scn.FontSize = size;
    Scn.hFont = CreateFontIndirect (&lf);
    oldhFont = (HFONT)SelectObject (hDC, Scn.hFont);
    GetTextExtentPoint(hDC, TEXT("1234567890"), 10, &sz);
    if (oldhFont) SelectObject(hDC,(HGDIOBJ)oldhFont);
    ReleaseDC (hTermWnd, hDC);

    Scn.CharHeight = sz.cy;
    Scn.CharWidth  = sz.cx / 10; 

    CreateCaret(hTermWnd, NULL, Scn.CharWidth, Scn.CharHeight);

    SetScrolls();
    ShowCaret(hTermWnd);
}

BOOL
InitScreenSettings (HWND hWnd)
{
    Scn.TabSep = 8;
    Scn.BufSize = 80000;
    Scn.FontSize = 0;                  // No Font initially

    Scn.HaveFocus = TRUE;             // Do we have focus?  
    Scn.fgCol = RGB(  0,   0, 200);    // Forground colour
    Scn.bgCol = RGB(210, 210, 130);    // Background colour
    Scn.Debug = FALSE;

    Scn.Buf = (char *)LocalAlloc (LPTR, Scn.BufSize);
    if (Scn.Buf == NULL) return FALSE;
    Scn.BufLast = Scn.Buf + Scn.BufSize - 1;

    ClearScreen();
    SetScreenFont(16);

    //DoCaption(hMainWnd, &Scn.FileName);
    SaveInitialize(hMainWnd);
    return TRUE;
}

void
SetScrolls() {
    // This is  called when the client rectangle may have changed 
    // size, usually as a result of a change in scrollbar visibility.
    // It recalculates WinRows and WinCols and corrects
    // WinFirstLine, WinFirstLineNo, WinLastLine and WinLastLineNo.
    // Then it redisplays the whole window, assuming nothing about 
    // what was previously displayed -- ie no use of ScrollWindowEx.
    // It does not change WinIndent.
    // The caret may go out of the window. 
    SCROLLINFO si;
    RECT rc;

    HideCaret(hTermWnd);

    // First set the vertical scroll bar so that it is not visible.
    si.cbSize = sizeof(SCROLLINFO);
    si.fMask = SIF_RANGE|SIF_POS|SIF_PAGE;
    si.nMin = 1;
    si.nMax = 100;
    si.nPage = 100;
    si.nPos = 1;
    SetScrollInfo(hTermWnd, SB_VERT, &si, FALSE);

    GetClientRect(hTermWnd, &rc);
    Scn.WinCols = rc.right / Scn.CharWidth;

    // Update the horizontal scroll bar assuming the 
    // vertical scroll bar is not visible.
    UpdateHScroll(FALSE);
    GetClientRect(hTermWnd, &rc);
    Scn.WinRows = rc.bottom / Scn.CharHeight;

    // Update the vertical scroll bar taking account of the possible
    // horizontal scroll bar.
    UpdateVScroll(FALSE);
    GetClientRect(hTermWnd, &rc);
    Scn.WinCols = rc.right / Scn.CharWidth;

    // Update the horizontal scroll bar. This must be done since
    // the vertical scroll bar may have just become visible.
    UpdateHScroll(FALSE);
    GetClientRect(hTermWnd, &rc);
    Scn.WinRows = rc.bottom / Scn.CharHeight;

    // Update the vertical scroll bar taking account of the possible
    // horizontal scroll bar.
    UpdateVScroll(FALSE);
    GetClientRect(hTermWnd, &rc);
    Scn.WinCols = rc.right / Scn.CharWidth;

    // Both scroll bars are now correctly set, and hence
    // the client rectangle and WinCols and WinRows are now correct,

    prDebug(TEXT("Client Rect Correct"));

    // Reposition the window (if necessary) and repaint
    // Correct WinFirstLine, if necessary.
    if (Scn.LastLineNo <= Scn.WinRows) {
        // All lines can be displayed
        Scn.WinFirstLine = Scn.FirstLine;
        Scn.WinFirstLineNo = 1;
        Scn.WinLastLine = Scn.LastLine;
        Scn.WinLastLineNo = Scn.LastLineNo;
    } else {
        int n = Scn.WinRows;
        // Not all lines can be displayed
        // Make sure the window is not too early
        while (Scn.WinLastLineNo<Scn.WinRows) {
            // Advance WinLastLine to the start of the next line
            Scn.WinLastLine = NextLineStart(Scn.WinLastLine);
            Scn.WinLastLineNo++;
        }
        // Now set WinFirstLine Rows-1 lines earlier than WinLastLine
        Scn.WinFirstLine = Scn.WinLastLine;
        while (--n) {
            // Go back one line
            Scn.WinFirstLine = PrevLineStart(Scn.WinFirstLine);
        }
        Scn.WinFirstLineNo = Scn.WinLastLineNo - Scn.WinRows + 1;
    }

     // Update the vertical scroll bar.
     UpdateVScroll(FALSE);

     // Update the horizontal scroll bar.
     UpdateHScroll(FALSE);

     // Repaint the whole screen now.
    InvalidateRect(hTermWnd, NULL, TRUE);
    UpdateWindow(hTermWnd);

    Scn.CursorX = (Scn.CursorP-Scn.LastLine-Scn.WinIndent) *
                      Scn.CharWidth;
    Scn.CursorY = (Scn.LastLineNo-Scn.WinFirstLineNo) *
                      Scn.CharHeight;

    SetCaretPos(Scn.CursorX, Scn.CursorY);
    ShowCaret(hTermWnd);
}

void
UpdateVScroll(BOOL redraw) {
    SCROLLINFO si;
    si.cbSize = sizeof(SCROLLINFO);
    si.fMask = SIF_RANGE|SIF_POS|SIF_PAGE;
    si.nMin = 1;
    si.nMax = Scn.LastLineNo;
    si.nPage = Scn.WinRows;
    si.nPos = Scn.WinFirstLineNo;
    SetScrollInfo(hTermWnd, SB_VERT, &si, redraw);
    if (redraw) UpdateWindow(hTermWnd);
}

void
UpdateHScroll(BOOL redraw) {
    SCROLLINFO si;
    si.cbSize = sizeof(SCROLLINFO);
    si.fMask = SIF_RANGE|SIF_POS|SIF_PAGE;
    si.nMin = 1;
    si.nMax = Scn.MaxCols;
    si.nPage = Scn.WinCols;
    si.nPos = Scn.WinIndent+1;
    SetScrollInfo(hTermWnd, SB_HORZ, &si, redraw);
    if (redraw) UpdateWindow(hTermWnd);
}

void
ScrollDown(int Rows)
{
    // This attempts to "increase" the line number of WinLastLine
    // by Rows (which may be negative), keeping
    //       WinLastLineNo <= LastLineNo
    // and   WinLastLineNo =  LastLineNo, if LastLineNo <= WinRows.
    //
    // On entry, the screen corresponds to the current setting of
    // WinFirstLine, WinLastLine but LastLineNo may have increased.
    //
    // It may scroll part of the window using ScrollWindowEx.
    //
    // It updates the vertical scroll bar, if necessary.
    RECT        rc;
    GetClientRect(hTermWnd, &rc);
    rc.bottom = Scn.WinRows*Scn.CharHeight;
 
    // Adjust Rows so that WinLastLineNo+Rows >= WinRows
    if (Rows < Scn.WinRows - Scn.WinLastLineNo)
        Rows = Scn.WinRows - Scn.WinLastLineNo;
    // Adjust Rows so that WinLastLineNo+Rows <= LastLineNo
    if (Rows > Scn.LastLineNo - Scn.WinLastLineNo)
        Rows = Scn.LastLineNo - Scn.WinLastLineNo;

    if (Scn.LastLineNo<=Scn.WinRows) {
        // All the lines are visible, so no scrolling is necessary.
        // Line WinFirstLineNo(=1) to WinLastLineNo are already displayed
        // so we only need to display lines WinLastLineNo+1 to LastLineNo.

        if (Scn.WinLastLine==Scn.LastLine) return;
        
        // At least one new line needs to be painted
        GetClientRect(hTermWnd, &rc);
        rc.top = Scn.WinLastLineNo * Scn.CharHeight;
        rc.bottom = Scn.LastLineNo * Scn.CharHeight;
        Scn.WinLastLineNo = Scn.LastLineNo;
        Scn.WinLastLine = Scn.LastLine;
        InvalidateRect(hTermWnd, &rc, FALSE);
        UpdateWindow(hTermWnd);
        return;
    }

    //There are more lines than can be displayed in the window

    if (Rows==0) return;


    if (Rows>0) {
        // The text will move up the screen
        int i;
        for (i=1; i<=Rows; i++) {
            // Move WinFirstLine and WinLastLine forward Rows lines
            // in the buffer
            Scn.WinFirstLine = NextLineStart(Scn.WinFirstLine);
            Scn.WinLastLine  = NextLineStart(Scn.WinLastLine);
        }
        Scn.WinFirstLineNo += Rows;
        Scn.WinLastLineNo  += Rows;

        if (Rows<Scn.WinRows) {
            // There is some overlap so ScrollWindowEx can be used.
            HideCaret(hTermWnd);

            ScrollWindowEx(hTermWnd, 0,
                           -Rows*Scn.CharHeight,
                           &rc, &rc,
                           NULL, NULL, 0);
            ShowCaret(hTermWnd);
            rc.top = rc.bottom - Rows*Scn.CharHeight;
        }
    } else {
        // The text will move down the screen
        int i;
        for (i=-1; i>=Rows; i--) {
            // Move WinFirstLine and WinLastLine back by Rows lines
            // in the buffer
            Scn.WinFirstLine = PrevLineStart(Scn.WinFirstLine);
            Scn.WinLastLine  = PrevLineStart(Scn.WinLastLine);
        }
        Scn.WinFirstLineNo += Rows; // Since Rows<0 these
        Scn.WinLastLineNo  += Rows; // line numbers decrease.


        if (-Rows < Scn.WinRows) {
            // There is some overlap so ScrollWindowEx can be used
            HideCaret(hTermWnd);
            ScrollWindowEx(hTermWnd, 0,
                           -Rows*Scn.CharHeight,
                           &rc, &rc,
                           NULL, NULL, 0);
            ShowCaret(hTermWnd);
            rc.bottom = rc.top - Rows*Scn.CharHeight;
        }
    }

    //busywait(2000);
    InvalidateRect(hTermWnd, &rc, FALSE);

    UpdateVScroll(TRUE);

    Scn.CursorX = (Scn.CursorP-Scn.LastLine-Scn.WinIndent) *
                      Scn.CharWidth;
    Scn.CursorY = (Scn.LastLineNo-Scn.WinFirstLineNo) *
                      Scn.CharHeight;
    SetCaretPos(Scn.CursorX, Scn.CursorY);
}

void
ScrollRight(int Cols)
{
    // This scroll so that WinIndent is "increased" by Cols
    // Cols may be negative.
    RECT        rc;
    int         OldIndent = Scn.WinIndent+Cols;
    Scn.WinIndent += Cols;
    if (Scn.WinIndent<=0) Scn.WinIndent = 0;


    UpdateHScroll(TRUE);

    GetClientRect(hTermWnd, &rc);
    HideCaret(hTermWnd);
    ScrollWindowEx(hTermWnd, 
                   (OldIndent - Scn.WinIndent)*Scn.CharWidth,
                   0, &rc, &rc,
                   NULL, NULL, 0);
    ShowCaret(hTermWnd);

    InvalidateRect(hTermWnd, NULL, FALSE); // Should be improved
    UpdateWindow(hTermWnd);
}

void
MakeCursorVisible() {
    // This will scroll the window vertically, if necessary,
    // to make WinLastLine = LastLine.
    // It then adjusts WinIndent to make the cursor visible,
    // scrolling horizontally, if necessary.
    // The visibility of both scroll bars will remain unchanged.
    if (Scn.WinLastLine != Scn.LastLine) {
        HideCaret(hTermWnd);
        ScrollDown(Scn.LastLineNo - Scn.WinLastLineNo);
        ShowCaret(hTermWnd);
        Scn.CursorY = (Scn.WinLastLineNo-Scn.WinFirstLineNo) *
                          Scn.CharHeight;
        SetCaretPos(Scn.CursorX, Scn.CursorY);
    }

    if (Scn.CursorP - Scn.WinLastLine - Scn.WinIndent >=
        Scn.WinCols) { 
            HideCaret(hTermWnd);
            ScrollRight(Scn.CursorP -   // This changes WinIndent
                        Scn.WinLastLine - 
                        Scn.WinCols -
                        Scn.WinIndent +
                        1);
            ShowCaret(hTermWnd);
            Scn.CursorX = ( Scn.CursorP     - 
                               Scn.WinLastLine - 
                               Scn.WinIndent ) * Scn.CharWidth;
            SetCaretPos(Scn.CursorX, Scn.CursorY);
        }
    // The cursor is now visible
}
        
void
PlaceScreenCh(TCHAR ch, int X, int Y) {
    HDC hDC = GetDC(hTermWnd);
    HFONT oldhfont = (HFONT) SelectObject(hDC, Scn.hFont);
    (void)SetTextColor(hDC, Scn.fgCol);
    (void)SetBkColor  (hDC, Scn.bgCol);

    HideCaret(hTermWnd); // Must hide the caret while writing
    ExtTextOut(hDC, X, Y, ETO_OPAQUE, NULL, &ch, 1, NULL);
    ShowCaret(hTermWnd);

    if (oldhfont) SelectObject(hDC, oldhfont);
    ReleaseDC(hTermWnd, hDC);
}

void busywait(DWORD msecs) {  // Busy wait for debugging purposes.
    DWORD t0 = GetTickCount();
    while (GetTickCount()<t0+msecs) continue;
}

void
ScnWrch (BYTE InChar)
{ 
    MakeCursorVisible();

    CheckBufSpace();

    // Do something with the character.
    switch (InChar) {
    case 0x08 :   // BACKSPACE
        // Ensure LastLine is displayed
        if (Scn.WinLastLine != Scn.LastLine) {
            HideCaret(hTermWnd);
            ScrollDown(Scn.LastLineNo - Scn.WinLastLineNo);
            ShowCaret(hTermWnd);
        }

        // Scroll horizontally if necessary
        if (Scn.CursorP - Scn.WinLastLine - Scn.WinIndent >=
            Scn.WinCols) { 
            HideCaret(hTermWnd);
            ScrollRight(Scn.CursorP -   // This changes WinIndent
                        Scn.WinLastLine - 
                        Scn.WinCols -
                        Scn.WinIndent);
            ShowCaret(hTermWnd);
        }
        // The cursor is now visible

        if (Scn.LastLine==Scn.CursorP) {
            // Can't backspace, so do nothing.
            return;
        }

        // We can backspace by one character
        *--Scn.CursorP = 0;
        Scn.CursorX -= Scn.CharWidth;
        // Overwrite curor position with a space
        PlaceScreenCh((TCHAR) ' ', Scn.CursorX, Scn.CursorY);
        SetCaretPos(Scn.CursorX, Scn.CursorY);

        {   // Correct MaxCols if necessary (the "+1" allows for the cursor)
            int MaxCols = Scn.CursorP - Scn.LastLine + 1;
            if (MaxCols < Scn.PrevMaxCols) MaxCols = Scn.PrevMaxCols;
            if (MaxCols < Scn.MaxCols) {
                // MaxCols has changed, so may need to correct WinIndent
                // and the horizontal scroll bar
                Scn.MaxCols = MaxCols;

                if (Scn.WinIndent > Scn.MaxCols-Scn.WinCols) {
                    Scn.WinIndent = Scn.MaxCols-Scn.WinCols;
                    if (Scn.WinIndent<0) Scn.WinIndent = 0;
                    SetScrolls();
                    return;
                }
                // Adjust the horizontal scroll bar
                UpdateHScroll(TRUE);
            }
        }
        prDebug(TEXT("ScnWrch: BS"));
        return;

    case 0x0d : return;
    case 0x0a :
        // Update PrevMaxCols and LongestLine if necessary
        if (Scn.PrevMaxCols <= Scn.CursorP-Scn.LastLine) {
            // Always keep LongestLine the latest possible.
            Scn.LongestLine = Scn.LastLine;
            if (Scn.PrevMaxCols < Scn.CursorP-Scn.LastLine) {
                Scn.PrevMaxCols = Scn.CursorP-Scn.LastLine;
                Scn.MaxCols = Scn.PrevMaxCols;
                prDebug(TEXT("Updated PrevMaxCols"));
                // If the horizontal scrollbar is visible, it needs
                // updating because its range has just been reduced.
                if (Scn.MaxCols>Scn.WinCols) UpdateHScroll(TRUE);
            }
        }

        // Ensure WinIndent is zero, scrolling if necessary
        if (Scn.WinIndent) {
            Scn.WinIndent = 0;
            SetScrolls();
        }

        // LastLine should be visible
        if (Scn.WinLastLineNo < Scn.LastLineNo)
            error(TEXT("ScnWrch: Bug"));

        // Create an empty line
        *++Scn.CursorP = 0; 
        Scn.LastLine = Scn.CursorP;
        Scn.LastLineNo++;

        // Test to see if the vertical scroll bar has just
        // become necessary.
        if (Scn.LastLineNo==Scn.WinRows+1) SetScrolls();

        // Scroll the new (empty) line into view
        ScrollDown(1);

        // Position the cursor
        Scn.CursorX = 0;
        Scn.CursorY = (Scn.WinLastLineNo - Scn.WinFirstLineNo) *
                         Scn.CharHeight;
        SetCaretPos(Scn.CursorX, Scn.CursorY);
        prDebug(TEXT("ScnWrch: newline"));
        //busywait(2000);
        return;

    case 0:    // Ignore character 0
        return;

    case '\t': // Convert tabs into spaces
        while (1) {
            ScnWrch(' ');
            if ((Scn.CursorP-Scn.LastLine)%Scn.TabSep == 0) return;
        }

    default :  // An ordinary character occupying just one position
        {   
            *Scn.CursorP++ = InChar;
            *Scn.CursorP = 0;             // EOL marker

            // Since the cursor is visible there is room for
            // one more character.
            PlaceScreenCh((TCHAR)InChar, Scn.CursorX, Scn.CursorY);
            Scn.CursorX += Scn.CharWidth;
            SetCaretPos(Scn.CursorX, Scn.CursorY);

            if (Scn.CursorP-Scn.LastLine-Scn.WinIndent+1 >= Scn.WinCols) {
                // There is no room for the cursor, so
                // WinIndent must be increased.
                if (Scn.MaxCols < Scn.CursorP-Scn.LastLine+1) {
                    // This character causes MaxCols to increase.
                    // The "+1" ensures there is room for the cursor
                    Scn.MaxCols = Scn.CursorP-Scn.LastLine+1;
                    if (Scn.MaxCols==Scn.WinCols+1) SetScrolls();
                    if (Scn.MaxCols>Scn.WinCols+1) UpdateHScroll(TRUE);
                }
                ScrollRight(1);
                Scn.CursorX = 
                    (Scn.CursorP-Scn.LastLine-Scn.WinIndent) * Scn.CharWidth;
                Scn.CursorY = 
                    (Scn.LastLineNo-Scn.WinFirstLineNo) * Scn.CharHeight;
            }
                
            SetCaretPos(Scn.CursorX, Scn.CursorY);
            prDebug(TEXT("ScnWrch: simple ch"));
        }
    }
}

void
CheckBufSpace() {
    // Check that there is room in the buffer for at least one
    // more character.
    if (Scn.CursorP >= Scn.BufLast) {
        // We must remove some lines from the start of the buffer
        // to release at least 10% of the buffer space
        int n=0;
        char *p = &Scn.Buf[2];
        char *q = p + Scn.BufSize/10;

        while (p<q) {
            // Remove a line
            p = NextLineStart(p);
            n++;  // Count of removed lines
        }
        // Shift the buffer contents
        memcpy(&Scn.Buf[2], p, Scn.CursorP-p+1);
        // Adjust the line pointers
        Scn.FirstLine = &Scn.Buf[2];;
        Scn.CursorP  -= p-Scn.FirstLine;
        Scn.LastLine -= p-Scn.FirstLine;
        Scn.LastLineNo -= n;
        if (Scn.LastLine<Scn.FirstLine) {
            Scn.LastLine = Scn.FirstLine;
            Scn.LastLineNo = 1;
        }

        Scn.WinFirstLine -= p-Scn.FirstLine;
        Scn.WinFirstLineNo -= n;
        Scn.WinLastLine -= p-Scn.FirstLine;
        Scn.WinLastLineNo -= n;
        if(Scn.WinFirstLine<Scn.FirstLine) {
            Scn.WinFirstLine = Scn.FirstLine;
            Scn.WinFirstLineNo = 1;
            Scn.WinLastLine = Scn.WinFirstLine;
            Scn.WinLastLineNo = 1;
        }

        Scn.LongestLine -= p-Scn.FirstLine;
        if (Scn.LongestLine<Scn.FirstLine) SetLongestLine();

        SetScrolls();
    }
}

void
SetLongestLine() {
    char *p = Scn.FirstLine;
    Scn.PrevMaxCols = 0;
    Scn.LongestLine = p;
    // Find the latest longest line
    while (p!=Scn.LastLine) {
        char *np = NextLineStart(p);
        if (Scn.PrevMaxCols <= np-p-1) {
           Scn.PrevMaxCols = np-p-1;
           Scn.LongestLine = p;
        }
        p = np;
    }
    Scn.MaxCols = Scn.PrevMaxCols;
    if (Scn.MaxCols < Scn.CursorP - Scn.LastLine + 1)
        Scn.MaxCols = Scn.CursorP - Scn.LastLine + 1;
    SetScrolls();
}



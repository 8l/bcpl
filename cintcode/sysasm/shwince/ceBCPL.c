//======================================================================
// ceBCPL - The BCPL Cintcode System for Windows CE
//
// Written by Martin Richards (c) April 1999
//
// The GUI programming was based on programs in Douglas Boling's book
// "Programming Windows CE"
//======================================================================

#include <windows.h>                 // For all that Windows stuff
#include <commctrl.h>                // Command bar includes
#include "ceBCPL.h"                  // Program-specific stuff

int main();

// Command Bar button structure
const TBBUTTON tbCBBtns[] = {
//   BitmapIndex   Command      State    Style           UserData  String
    {0,            0,           0,       TBSTYLE_SEP,    0,        0},
    {STD_PRINT+1,  IDM_BIGGER,  TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0},
    {STD_PRINT+2,  IDM_SMALLER, TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0},
    {0,            0,           0,       TBSTYLE_SEP,    0,        0},
    {STD_PRINT+3,  IDM_COLOURS, TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0},
    {0,            0,           0,       TBSTYLE_SEP,    0,        0},
    {STD_PRINT+4,  IDM_INTERRUPT, TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0},
    {0,            0,           0,       TBSTYLE_SEP,    0,        0},
    {STD_PRINT+5,  IDM_TEXT,      TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0},
    {STD_PRINT+6,  IDM_GRAPHICS, TBSTATE_ENABLED,
                                         TBSTYLE_BUTTON, 0,        0}
};

// Tooltip string list for the command bar buttons
const TCHAR *pTips[] = { TEXT(""),
                         TEXT("Increase Font Size"),
                         TEXT("Decrease Font Size"),
                         TEXT("Change Colours"),
                         TEXT("Set Intflag"),
                         TEXT("Select Text Window"),
                         TEXT("Select Graphics Window")
};

// A selection of text foreground and background colours
const DWORD colourVec[] = {
    0x000000, 0xFFa0a0,
    0x000000, 0xa0a0FF,
    0x000000, 0xFFFFFF,
    0x091a2b, 0xf6e5d4,
    0x000000, 0xf2da6e,
    0x79afee, 0x865011,
    0x000000, 0xa0c795,
    0x000000, 0x8bf2fc,
    0x000000, 0xa5f064,
    0x000000, 0xde58ee,
    0x2082ed, 0xdf7d12,
    0x000000, 0xa1b8ff,
    0x0ee7e7, 0xf11818,
    0xFFFFFF, 0x000000
};

int colourNo = 0;

//----------------------------------------------------------------------
// Global data
//
const TCHAR szAppName[] = TEXT ("ceBCPL");
HINSTANCE hInst;                     // Program instance handle
HWND hMainWnd;                       // Handle to Main window
HWND hTermWnd;                       // Handle to Terminal window
HWND hGraphicsWnd;                   // Handle to Graphics window
TERM_SCREEN Scn;

#define chBufSize 64
TCHAR chBuf[chBufSize];              // Circular keyboard input buffer
int chBufP=0;                        // buffer Put position
int chBufG=0;                        // buffer get position
CRITICAL_SECTION chBufCritSection;   // critical section object to
                                     // control access to
                                     // chBufP and chBufG
HANDLE hWakeup = 0;                  // Wakeup event
HANDLE hThread = 0;                  // for the interpreter thread
DWORD   Ticks  = 0;          // msecs since interpreter started
int Interrupted = 0;         // Tested by the BCPL intflag function


//======================================================================
// chBufPut and chBufGet functions to be used from different threads
// chBufPut is used by the primary thread to put keyboard characters
// into the buffer, and chBufGet is used by the interpreter thread to
// extract them from the buffer as needed.
//
void chBufPut(char ch) {
    int p;
    EnterCriticalSection(&chBufCritSection);
    p = chBufP+1;
    if (p>=chBufSize) p = 0;
    if (p==chBufG) {
        // the buffer is full
        LeaveCriticalSection(&chBufCritSection);
        return;
    }
    // If the buffer was empty wakeup the interpreter thread
    if(chBufP==chBufG) SetEvent(hWakeup);
    chBuf[chBufP] = ch;
    chBufP = p;
    LeaveCriticalSection(&chBufCritSection);
}

int chBufEmpty() {
  return chBufP==chBufG;
}

TCHAR chBufGet() {
    while (1) {
        EnterCriticalSection(&chBufCritSection);
        if (chBufP!=chBufG) {
            // The buffer is not empty
            TCHAR ch = chBuf[chBufG];
            chBufG++;
            if (chBufG>=chBufSize) chBufG = 0;
            LeaveCriticalSection(&chBufCritSection);
            return ch;
        }
        ResetEvent(hWakeup);
        LeaveCriticalSection(&chBufCritSection);
        WaitForSingleObject(&hWakeup, INFINITE);
    }
}

int InterpThread(PVOID pArg) {
    HWND hWnd = (HWND) pArg;

    main();
    SendMessage (hWnd, WM_CLOSE, 0, 0);
    return 0;
}



//======================================================================
// Program entry point
//
int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPWSTR lpCmdLine, int nCmdShow) {
    MSG msg;
    HWND hwndMain;

    // Initialize application.
    if (InitApp (hInstance)) return 1;

    // Initialize this instance.
    hwndMain = InitInstance (hInstance, lpCmdLine, nCmdShow);
    if (hwndMain == 0)
        return 0x10;

    // Application message loop
    while (GetMessage (&msg, NULL, 0, 0)) {
        TranslateMessage (&msg);
        DispatchMessage (&msg);
    }
    // Instance cleanup
    return TermInstance (hInstance, msg.wParam);
}

//----------------------------------------------------------------------
// InitApp - Application initialization
//
int InitApp (HINSTANCE hInstance) {
    WNDCLASS wc;
    INITCOMMONCONTROLSEX icex;

    icex.dwSize = sizeof (INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_BAR_CLASSES;
    InitCommonControlsEx (&icex);

    // Register application Main window class.
    wc.style = 0;                             // Window style
    wc.lpfnWndProc = MainWndProc;             // Callback function
    wc.cbClsExtra = 0;                        // Extra class data
    wc.cbWndExtra = 0;                        // Extra window data
    wc.hInstance = hInstance;                 // Owner handle
    wc.hIcon = NULL,                          // Application icon
    wc.hCursor = NULL;                        // Default cursor
    wc.hbrBackground = (HBRUSH) GetStockObject (GRAY_BRUSH);
    wc.lpszMenuName =  NULL;                  // Menu name
    wc.lpszClassName = szAppName;             // Window class name

    if (!RegisterClass (&wc)) return 1;

    // Register application Term window class.
    wc.style = 0;                             // Window style
    wc.lpfnWndProc = TermWndProc;             // Callback function
    wc.cbClsExtra = 0;                        // Extra class data
    wc.cbWndExtra = 0;                        // Extra window data
    wc.hInstance = hInstance;                 // Owner handle
    wc.hIcon = NULL,                          // Application icon
    wc.hCursor = NULL;                        // Default cursor
    wc.hbrBackground = (HBRUSH) GetStockObject (GRAY_BRUSH);
    wc.lpszMenuName =  NULL;                  // Menu name
    wc.lpszClassName = TEXT("TermClass");     // Window class name

    if (!RegisterClass (&wc)) return 1;

    // Register application Graphics window class.
    wc.style = 0;                             // Window style
    wc.lpfnWndProc = GraphWndProc;            // Callback function
    wc.cbClsExtra = 0;                        // Extra class data
    wc.cbWndExtra = 0;                        // Extra window data
    wc.hInstance = hInstance;                 // Owner handle
    wc.hIcon = NULL,                          // Application icon
    wc.hCursor = NULL;                        // Default cursor
    wc.hbrBackground = (HBRUSH) GetStockObject (GRAY_BRUSH);
    wc.lpszMenuName =  NULL;                  // Menu name
    wc.lpszClassName = TEXT("GraphicsClass"); // Window class name

    if (!RegisterClass (&wc)) return 1;

    return 0;
}

//----------------------------------------------------------------------
// InitInstance - Instance initialization
//
HWND InitInstance (HINSTANCE hInstance, LPWSTR lpCmdLine, int nCmdShow) {
    int retcode;
    HWND hwndCB;
    RECT rc;

    // Save program instance handle in global variable.
    hInst = hInstance;

    InitializeCriticalSection(&chBufCritSection);
    hWakeup = CreateEvent(NULL, FALSE, FALSE, NULL);

    // Create Main window.
    hMainWnd = CreateWindow (szAppName,             // Window class
                             TEXT ("ceBCPL"),       // Window title
                             WS_VISIBLE,            // Style flags
                             CW_USEDEFAULT,         // x position
                             CW_USEDEFAULT,         // y position
                             CW_USEDEFAULT,         // Initial width
                             CW_USEDEFAULT,         // Initial height
                             NULL,                  // Parent
                             NULL,                  // Menu, must be null
                             hInstance,             // Application instance
                             NULL);                 // Pointer to create
                                                    // parameters
    // Return fail code if window not created.
    if (!IsWindow (hMainWnd)) return 0;
    GetClientRect(hMainWnd, &rc);

    // Create a command bar.
    hwndCB = CommandBar_Create (hInst, hMainWnd, IDC_CMDBAR);

    // Insert the menu.
    CommandBar_InsertMenubar(hwndCB, hInst, ID_MENU, 0);

    // Insert buttons
    CommandBar_AddBitmap (hwndCB, HINST_COMMCTRL, IDB_STD_SMALL_COLOR,
                          STD_PRINT+1, 0, 0);

    CommandBar_AddBitmap (hwndCB, hInst, IDB_CBTNS, 6, 0, 0);
    
    CommandBar_AddButtons (hwndCB, dim(tbCBBtns), tbCBBtns);

    // Add tooltips to the command bar
    CommandBar_AddToolTips(hwndCB, dim(pTips), pTips);

    // Add exit button to command bar.
    CommandBar_AddAdornments (hwndCB, CMDBAR_HELP, 0);


    rc.top = CommandBar_Height (GetDlgItem (hMainWnd, IDC_CMDBAR));

    ShowWindow (hMainWnd, nCmdShow);
    UpdateWindow (hMainWnd);

    // Create Terminal window.  Size it so that it fits under
    // the command bar and fills the remaining client area.
    //

    hTermWnd = CreateWindowEx(
           0,
           TEXT ("TermClass"), TEXT ("ceBCPL Terminal"),
           WS_VISIBLE | WS_CHILD | WS_VSCROLL | WS_HSCROLL | WS_BORDER,
           rc.left, rc.top, rc.right-rc.left, rc.bottom-rc.top, 
           hMainWnd, NULL, hInst, NULL);

    if (!IsWindow(hTermWnd)) { DestroyWindow (hMainWnd); return 0; }

    InitScreenSettings(hTermWnd);
    InvalidateRect (hTermWnd, NULL, TRUE);
    UpdateWindow (hTermWnd);

    
    // The graphics window should only be create when first needed.
    hGraphicsWnd = CreateWindowEx(
           0,
           TEXT ("GraphicsClass"), NULL,
           WS_VISIBLE | WS_CHILD | WS_BORDER,
           rc.left+200, rc.top, (rc.right-rc.left-220), rc.bottom-rc.top, 
           hMainWnd, NULL, hInst, NULL);

    if (!IsWindow(hGraphicsWnd)) { DestroyWindow (hMainWnd); return 0; }

    InitGraphics(hGraphicsWnd);
    InvalidateRect (hGraphicsWnd, NULL, TRUE);
    UpdateWindow (hGraphicsWnd);

    SetFocus(hTermWnd);

    // Create the interpreter thread
    hThread = CreateThread(NULL, 0, 
                           (LPTHREAD_START_ROUTINE)InterpThread,
                           hMainWnd, 0, &retcode);
    // Run the interpreter at low priority
    SetThreadPriority(hThread, THREAD_PRIORITY_LOWEST);
    if (hThread)
        CloseHandle(hThread);
    else {
        DestroyWindow(hMainWnd);
        return 0;
    }

    return hMainWnd;
}

//----------------------------------------------------------------------
// TermInstance - Program cleanup
//
int TermInstance (HINSTANCE hInstance, int nDefRC) {

    DeleteCriticalSection(&chBufCritSection);
    if (hWakeup) CloseHandle (hWakeup);

    return nDefRC;
}

//======================================================================
// Message handling procedures for TermWindow
//
//----------------------------------------------------------------------
// TermWndProc - Callback function for Term window
//
LRESULT CALLBACK TermWndProc (HWND hWnd, UINT wMsg, WPARAM wParam,
                               LPARAM lParam) {
    switch (wMsg) {
    default: return DefWindowProc   (hWnd, wMsg, wParam, lParam);

    case WM_CHAR:
             return DoCharTerm      (hWnd, wMsg, wParam, lParam);
    case WM_DESTROY:
             return DoDestroyTerm   (hWnd, wMsg, wParam, lParam);
    case WM_SETFOCUS:
             return DoSetFocusTerm  (hWnd, wMsg, wParam, lParam);
    case WM_KILLFOCUS:
             return DoKillFocusTerm (hWnd, wMsg, wParam, lParam);
    case WM_SIZE:
             return DoSizeTerm      (hWnd, wMsg, wParam, lParam);
    case WM_PAINT:
             return DoPaintTerm     (hWnd, wMsg, wParam, lParam);
    case WM_VSCROLL:
             return DoVScrollTerm   (hWnd, wMsg, wParam, lParam);
    case WM_HSCROLL:
             return DoHScrollTerm   (hWnd, wMsg, wParam, lParam);
    case SCN_WRCH:
             return DoWrchTerm      (hWnd, wMsg, wParam, lParam);
    case SCN_PRINTFS:
             return DoPrintfsTerm   (hWnd, wMsg, wParam, lParam);
    case SCN_PRINTFD:
             return DoPrintfdTerm   (hWnd, wMsg, wParam, lParam);
    }
}

//----------------------------------------------------------------------
// DoCharTerm - Process WM_CHAR message for Term window.
//
LRESULT DoCharTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    chBufPut((INT) wParam);
    return 0;
}

//----------------------------------------------------------------------
// DoDestroyTerm - Process WM_DESTROY message for Term window.
//
LRESULT DoDestroyTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    PostQuitMessage(0);
    return 0;
}

//----------------------------------------------------------------------
// DoVScrollTerm - Process WM_VSCROLL message for Term window.
//
LRESULT DoVScrollTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    switch (LOWORD(wParam)) {
    case SB_LINEUP:
        ScrollDown(-1);
        break;
    case SB_LINEDOWN:
        ScrollDown(1);
        break;
    case SB_PAGEUP:
        ScrollDown(-(Scn.WinRows-1));
        break;
    case SB_PAGEDOWN:
        ScrollDown(Scn.WinRows-1);
        break;
    case SB_TOP:
        ScrollDown(-Scn.LastLineNo);
        break;
    case SB_BOTTOM:
        ScrollDown(Scn.LastLineNo);
        break;
    case SB_THUMBTRACK:
    case SB_THUMBPOSITION:
        ScrollDown(HIWORD(wParam)-Scn.WinFirstLineNo+1);
        break;
    }
    return 0;
}

//----------------------------------------------------------------------
// DoHScollTerm - Process WM_HSCROLL message for Term window.
//
LRESULT DoHScrollTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    switch (LOWORD(wParam)) {
    case SB_LINEUP:
        ScrollRight(-1);
        break;
    case SB_LINEDOWN:
        ScrollRight(1);
        break;
    case SB_PAGEUP:
        ScrollRight(-(Scn.WinCols-1));
        break;
    case SB_PAGEDOWN:
        ScrollRight(Scn.WinCols-1);
        break;
    case SB_TOP:
        ScrollRight(-Scn.MaxCols);
        break;
    case SB_BOTTOM:
        ScrollRight(Scn.MaxCols);
        break;
    case SB_THUMBTRACK:
    case SB_THUMBPOSITION:
        ScrollRight(HIWORD(wParam)-Scn.WinIndent);
        break;
    }
    return 0;
}


//----------------------------------------------------------------------
// DoPaintTerm - Process WM_PAINT message for Term window.
//
LRESULT DoPaintTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    PAINTSTRUCT ps;
    HDC hDC = BeginPaint(hWnd, &ps);
    PaintScreen(hWnd, hDC, &(ps.rcPaint));
    EndPaint(hWnd, &ps);
    prDebug(TEXT("Just done PaintTerm"));
    return 0;
}

//----------------------------------------------------------------------
// DoSetFocusTerm - Process WM_SETFOCUS message for Term window.
//
LRESULT DoSetFocusTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
//  printfd(TEXT("SetFocus\n"), 0);
    Scn.HaveFocus = TRUE;
    CreateCaret(hWnd, NULL, Scn.CharWidth, Scn.CharHeight);
    SetCaretPos(Scn.CursorX, Scn.CursorY);
    ShowCaret(hWnd);
    return 0;
}

//----------------------------------------------------------------------
// DoKillFocusTerm - Process WM_KILLFOCUS message for Term window.
//
LRESULT DoKillFocusTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
//  printfd("KillFocus\n", 0);
    Scn.HaveFocus = FALSE;
    HideCaret(hWnd);
    DestroyCaret();
    return 0;
}

//----------------------------------------------------------------------
// DoSizeTerm - Process WM_SIZE message for Term window.
//
LRESULT DoSizeTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
//  printfd(TEXT("SIZE received\n"), 0);
    return 0;
}

//----------------------------------------------------------------------
// DoWrchTerm - Process SCN_WRCH message for Term window.
//
LRESULT DoWrchTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    ScnWrch((BYTE) wParam);
    return 0;
}

//----------------------------------------------------------------------
// DoPrintfsTerm - Process SCN_PRINTFS message for Term window.
//
LRESULT DoPrintfsTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    ScnPrintfs((char *) wParam, (char *) lParam);
    return 0;
}

//----------------------------------------------------------------------
// DoPrintfdTerm - Process SCN_PRINTFD message for Term window.
//
LRESULT DoPrintfdTerm (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    ScnPrintfd((char *) wParam, (int) lParam);
    return 0;
}

//======================================================================
// Message handling procedures for MainWindow
//
//----------------------------------------------------------------------
// MainWndProc - Callback function for application window
//
LRESULT CALLBACK MainWndProc (HWND hWnd, UINT wMsg, WPARAM wParam,
                               LPARAM lParam) {
    switch (wMsg) {
    default: return DefWindowProc (hWnd, wMsg, wParam, lParam);
    //case WM_CHAR:
    case WM_SYSCHAR:
             return DoKeysMain     (hWnd, wMsg, wParam, lParam);
    case WM_COMMAND:
             return DoCommandMain  (hWnd, wMsg, wParam, lParam);
    case WM_CREATE:
             return DoCreateMain   (hWnd, wMsg, wParam, lParam);
    case WM_DESTROY:
             return DoDestroyMain  (hWnd, wMsg, wParam, lParam);
    case WM_HELP:
             return DoHelpMain     (hWnd, wMsg, wParam, lParam);
    case WM_NOTIFY:
             return DoNotifyMain   (hWnd, wMsg, wParam, lParam);
    case WM_SETFOCUS:
             return DoSetFocusMain (hWnd, wMsg, wParam, lParam);
    case WM_KILLFOCUS:
             return DoKillFocusMain(hWnd, wMsg, wParam, lParam);
    case WM_HIBERNATE:
             return DoHibernateMain(hWnd, wMsg, wParam, lParam);
    case WM_ACTIVATE:
             return DoActivateMain (hWnd, wMsg, wParam, lParam);
//    case WM_PAINT:
//           return DoPaintMain   (hWnd, wMsg, wParam, lParam);
    }
}

//----------------------------------------------------------------------
// DoPaintMain - Process WM_PAINT message for Main window.
//
LRESULT DoPaintMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    PAINTSTRUCT ps;
    HDC         hDC = BeginPaint(hWnd, &ps);

    EndPaint(hWnd, &ps);
    return 0;
}

//----------------------------------------------------------------------
// DoCreateMain - Process WM_CREATE message for window.
//
LRESULT DoCreateMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    // Nothing to do -- all now done in InitInstance
    return 0;
}

//----------------------------------------------------------------------
// Wrch function    (called from the interpreter thread)
//
void Wrch(char ch) {
    PostMessage(hTermWnd, SCN_WRCH, (WPARAM) ch, (LPARAM) NULL);
}

//----------------------------------------------------------------------
// printfs function    (called from the interpreter thread)
//
void printfs(char *form, char *arg) {
    PostMessage(hTermWnd, SCN_PRINTFS, (WPARAM) form, (LPARAM) arg);
}

//----------------------------------------------------------------------
// printfd function    (called from the interpreter thread)
//
void printfd(char *form, INT arg) {
    PostMessage(hTermWnd, SCN_PRINTFD, (WPARAM) form, (LPARAM) arg);
}

//----------------------------------------------------------------------
// DoCommandMain - Process WM_COMMAND message for window.
//
LRESULT DoCommandMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
    WORD idItem, wNotifyCode;
    HWND hwndCtl;

    // Parse the parameters.
    idItem = (WORD) LOWORD (wParam);
    wNotifyCode = (WORD) HIWORD (wParam);
    hwndCtl = (HWND) lParam;

    switch (idItem) {
    default:
        return 0;
    // File menu
    case IDM_INTERRUPT:
        return DoMainCommandInterrupt(hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_SAVE:
        return DoMainCommandSave     (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_SAVEAS:
        return DoMainCommandSaveAs   (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_EXIT:
        return DoMainCommandExit     (hWnd, idItem, hwndCtl, wNotifyCode);
    // Edit Menu
    case IDM_CLEAR:
        return DoMainCommandClear    (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_BIGGER:
        return DoMainCommandBigger   (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_SMALLER:
        return DoMainCommandSmaller  (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_COLOURS:
        return DoMainCommandColours  (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_DEBUG:
        return DoMainCommandDebug    (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_TEXT:
        return DoMainCommandText     (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_GRAPHICS:
        return DoMainCommandGraphics (hWnd, idItem, hwndCtl, wNotifyCode);
    // Help menu
    case IDM_DOCUMENTATION:
        return DoMainCommandDocs     (hWnd, idItem, hwndCtl, wNotifyCode);
    case IDM_ABOUT:
        return DoMainCommandAbout    (hWnd, idItem, hwndCtl, wNotifyCode);
    }
}

//----------------------------------------------------------------------
// DoNotifyMain - Process WM_NOTIFY message for window.
//
LRESULT DoNotifyMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
//  printfd(TEXT("NOTIFY received\n"), 0);
    return 0;
}

//----------------------------------------------------------------------
// DoSetFocusMain - Process WM_SETFOCUS message for window.
//
LRESULT DoSetFocusMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
//  printfd("SETFOCUS received\n", 0);
    if (hTermWnd) SetFocus(hTermWnd);
    return 0;
}

//----------------------------------------------------------------------
// DoKillFocusMain - Process WM_KILLFOCUS message for window.
//
LRESULT DoKillFocusMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
//  printfd("KILLFOCUS received\n", 0);
    return 0;
}

//----------------------------------------------------------------------
// DoHibernateMain - Process WM_Hibernate message for window.
//
LRESULT DoHibernateMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
//  printfd("HIBERNATE received\n", 0);
    return 0;
}

//----------------------------------------------------------------------
// DoActivateMain - Process WM_ACTIVATE message for window.
//
LRESULT DoActivateMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
//  printfd("ACTIVATE received\n", 0);
    return 0;
}

//----------------------------------------------------------------------
// DoKeysMain - Process Keybpard message for window.
//
LRESULT DoKeysMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                     LPARAM lParam) {
    switch (wMsg) {
    default: 
        printfd("Keyboard message received", 0);
        break;
    case WM_CHAR:
        chBufPut((INT) wParam);
        printfd("CHAR %d received", (INT) wParam);
        break;
    case WM_SYSCHAR:
        printfd("SYSCHAR %d received", (INT) wParam);
        break;
    }
    return 0;
}

//----------------------------------------------------------------------
// DoDestroyMain - Process WM_DESTROY message for window.
//
LRESULT DoDestroyMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                        LPARAM lParam) {
    PostQuitMessage (0);
    return 0;
}

//----------------------------------------------------------------------
// DoHelpMain - Process WM_HELP message.
//
LRESULT DoHelpMain (HWND hWnd, UINT wMsg, WPARAM wParam,
                       LPARAM lParam) {
    CreateProcess(TEXT("PegHelp.exe"),TEXT("BCPLhelp.htc"),
                  NULL, NULL, FALSE, 0, NULL, NULL,  NULL, NULL);
    return 0;
}


//----------------------------------------------------------------------
// DoMainCommandInterrupt - Process Program Stop command.
//
LRESULT DoMainCommandInterrupt (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    // Temp version
    Interrupted = 1;
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandSave - Process Program Save command.
//
LRESULT DoMainCommandSave (HWND hWnd, WORD idItem, HWND hwndCtl,
                           WORD wNotifyCode) {

    if (Scn.FileName[0]==0) FileSaveDlg(hWnd, Scn.FileName, Scn.TitleName);
    BufWrite(Scn.FileName);
    return 0;

}

//----------------------------------------------------------------------
// DoMainCommandSaveAs - Process Program SaveAs command.
//
LRESULT DoMainCommandSaveAs (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    FileSaveDlg(hWnd, Scn.FileName, Scn.TitleName);
    BufWrite(Scn.FileName);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandClear - Process Program Clear command.
//
LRESULT DoMainCommandClear (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    ClearScreen();
    SetScrolls();
    InvalidateRect (hTermWnd, NULL, TRUE);
//  printfd("Clear menu item activated\n", 0);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandBigger - Process Program Bigger Font command.
//
LRESULT DoMainCommandBigger(HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    int size = Scn.FontSize;
    size+=2;
    if (size>16) size+=2;
    if (size>36) size = 36;
    SetScreenFont(size);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandSmaller - Process Program Smaller Font command.
//
LRESULT DoMainCommandSmaller(HWND hWnd, WORD idItem, HWND hwndCtl,
                             WORD wNotifyCode) {
    int size = Scn.FontSize;
    size-=2;
    if (size>16) size-=2;
    if (size<6) size = 6;
    SetScreenFont(size);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandColours - Process Program Colours command.
//
LRESULT DoMainCommandColours (HWND hWnd, WORD idItem, HWND hwndCtl,
                              WORD wNotifyCode) {
    if (colourNo+2<=dim(colourVec)) {
        Scn.fgCol = colourVec[colourNo++];
        Scn.bgCol = colourVec[colourNo++];
    } else {
        colourNo = 0;
        SetRandomColours();
    }

    InvalidateRect(hTermWnd, NULL, FALSE);
    UpdateWindow(hTermWnd);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandText - Process Program Text command.
//
LRESULT DoMainCommandText (HWND hWnd, WORD idItem, HWND hwndCtl,
                           WORD wNotifyCode) {
	SetWindowPos(hTermWnd, HWND_TOP,
		         0,0, 100,100,
				 SWP_NOSIZE+SWP_NOMOVE+SWP_SHOWWINDOW);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandGraphics - Process Program Graphics command.
//
LRESULT DoMainCommandGraphics (HWND hWnd, WORD idItem, HWND hwndCtl,
                               WORD wNotifyCode) {
	SetWindowPos(hGraphicsWnd, HWND_TOP,
		         0,0, 100,100,
				 SWP_NOSIZE+SWP_NOMOVE+SWP_SHOWWINDOW);
    InvalidateRect(hGraphicsWnd, NULL, TRUE);
    UpdateWindow(hGraphicsWnd);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandDebug - Process Program Debug command.
//
LRESULT DoMainCommandDebug (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    Scn.Debug = !Scn.Debug;
    InvalidateRect(hTermWnd, NULL, FALSE);
    UpdateWindow(hTermWnd);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandExit - Process Program Exit command.
//
LRESULT DoMainCommandExit (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    SendMessage (hWnd, WM_CLOSE, 0, 0);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandDocs - Process the Help | Documentation command.
//
LRESULT DoMainCommandDocs (HWND hWnd, WORD idItem, HWND hwndCtl,
                           WORD wNotifyCode) {
    SendMessage (hWnd, WM_HELP, 0, 0);
//  printfd("Help-Docs menu item activated\n", 0);
    return 0;
}

//----------------------------------------------------------------------
// DoMainCommandAbout - Process the Help | About command.
//
LRESULT DoMainCommandAbout (HWND hWnd, WORD idItem, HWND hwndCtl,
                            WORD wNotifyCode) {
    DialogBox(hInst, TEXT("aboutbox"), hWnd, AboutDlgProc);
    return 0;
}

//=====================================================================
// About Dialog procedure
//
BOOL CALLBACK AboutDlgProc (HWND hWnd, UINT wMsg, WPARAM wParam,
                            LPARAM lParam) {
    switch (wMsg) {
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
            case IDOK:
            case IDCANCEL:
                EndDialog(hWnd, 0);
                return TRUE;
        }
        break;
    }
    return FALSE;
}


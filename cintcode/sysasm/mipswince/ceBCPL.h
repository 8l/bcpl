//======================================================================
// Header file for ceBCPL
//
// Copyright (C) 1998 Martin Richards
// derived from code by Douglas Boling
//======================================================================

#define dim(x) (sizeof(x) / sizeof(x[0]))

//----------------------------------------------------------------------
// Generic defines used by application
#define  IDI_BTNICON        20                  // Icon used on button

#define  IDB_CBTNS          301

#define  ID_ICON            1                   // Icon ID
#define  IDC_CMDBAR         2                   // Command bar ID
#define  ID_MENU            4                   // Main menu resource ID

// Menu item IDs
#define IDM_INTERRUPT       101                 // File menu
#define IDM_SAVE            103
#define IDM_SAVEAS          104
#define IDM_EXIT            105

#define IDM_CLEAR           110                 // Edit menu
#define IDM_BIGGER          111
#define IDM_SMALLER         112
#define IDM_COLOURS         113
#define IDM_TEXT            114
#define IDM_GRAPHICS        115
#define IDM_DEBUG           116

#define IDM_DOCUMENTATION   120                 // Help menu
#define IDM_ABOUT           121

#define SCN_WRCH            400                 // Calls ScnWrch
#define SCN_PRINTFS         401                 // Calls ScnPrintfs
#define SCN_PRINTFD         402                 // Calls ScnPrintfd




// --------------------------------------------------------------------
//  
// Structure Definitions
//  
// --------------------------------------------------------------------**/

typedef struct _TERM_SCREEN {
    int     WinRows;        // Total number of rows in the window
    int     WinCols;        // Total number of columns in the window
    char   *WinFirstLine;   // Start of the first window line
    char   *WinLastLine;    // Start of the last window line
    int     WinIndent;      // Indentation of the window        
    char   *FirstLine;      // Start of first line in the buffer
    char   *LastLine;       // Start of last line in the buffer
    int     WinFirstLineNo; // Start of first line in the window
    int     WinLastLineNo;  // Start of last line in the window
    int     LastLineNo;     // Start of last line in the buffer
    char   *CursorP;        // Position in the buffer of the cursor
    char   *LongestLine;    // Position longest complete line in buffer
    int     PrevMaxCols;    // Length of longest complete line in buffer
    int     MaxCols;        // Length of longest line in buffer
    int     CursorX;        // CursorX in pixels
    int     CursorY;        // CursorY in pixels
    int     TabSep;         // Distance between tab stops
    int     FontSize;       // Size of current font
    HFONT   hFont;          // Current Screen font
    int     CharHeight;     // Character Height
    int     CharWidth;      // Character Width
    BOOL    HaveFocus;      // Do we have focus?
    char    *Buf;           // The screen buffer byte vector
    int     BufSize;        // The buffer size in bytes
    char   *BufLast;        // Last position in the buffer
    TCHAR   FileName[MAX_PATH];   // Save/as filename
    TCHAR   TitleName[MAX_PATH];  // Save/as titlename
    COLORREF   fgCol;       // Forground colour
    COLORREF   bgCol;       // Background colour
    BOOL    Debug;          // debugging flag
} TERM_SCREEN;

//----------------------------------------------------------------------
// Function prototypes
//
int InitApp (HINSTANCE);
HWND InitInstance (HINSTANCE, LPWSTR, int);
int TermInstance (HINSTANCE, int);
void Wrch(char ch);
void printfs(char *, char *);
void printfd(char *, INT);
int chBufEmpty();
TCHAR chBufGet();

// Window procedures
LRESULT CALLBACK MainWndProc  (HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK TermWndProc  (HWND, UINT, WPARAM, LPARAM);

// Main Message handlers
LRESULT DoCreateMain    (HWND, UINT, WPARAM, LPARAM);
LRESULT DoPaintMain     (HWND, UINT, WPARAM, LPARAM);
LRESULT DoSetFocusMain  (HWND, UINT, WPARAM, LPARAM);
LRESULT DoKillFocusMain (HWND, UINT, WPARAM, LPARAM);
LRESULT DoSizeMain      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoCommandMain   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoNotifyMain    (HWND, UINT, WPARAM, LPARAM);
LRESULT DoAddLineMain   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoKeysMain      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoDestroyMain   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoHelpMain      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoHibernateMain (HWND, UINT, WPARAM, LPARAM);
LRESULT DoActivateMain  (HWND, UINT, WPARAM, LPARAM);

// Term Message handlers
LRESULT DoPaintTerm     (HWND, UINT, WPARAM, LPARAM);
LRESULT DoSetFocusTerm  (HWND, UINT, WPARAM, LPARAM);
LRESULT DoKillFocusTerm (HWND, UINT, WPARAM, LPARAM);
LRESULT DoSizeTerm      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoCharTerm      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoCommandTerm   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoNotifyTerm    (HWND, UINT, WPARAM, LPARAM);
LRESULT DoKeysTerm      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoDestroyTerm   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoVScrollTerm   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoHScrollTerm   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoWrchTerm      (HWND, UINT, WPARAM, LPARAM);
LRESULT DoPrintfsTerm   (HWND, UINT, WPARAM, LPARAM);
LRESULT DoPrintfdTerm   (HWND, UINT, WPARAM, LPARAM);

// Command functions
LPARAM DoMainCommandInterrupt (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandExit      (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandSave      (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandSaveAs    (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandClear     (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandBigger    (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandSmaller   (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandColours   (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandText      (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandGraphics  (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandDebug     (HWND, WORD, HWND, WORD);
LPARAM DoMainCommandDocs      (HWND, WORD, HWND, WORD); 
LPARAM DoMainCommandAbout     (HWND, WORD, HWND, WORD); 

// Window procedures
BOOL CALLBACK AboutDlgProc (HWND, UINT, WPARAM, LPARAM);

// Thread function
int InterpThread(PVOID pArg);

extern HWND hMainWnd;
extern HWND hTermWnd;
extern HWND hGraphicsWnd;
extern TERM_SCREEN Scn;      // The global screen
extern int Interrupted;

// Interpreter thread
extern  DWORD Ticks;         // msecs since Windows CE started

// screen.c
void ClearScreen();
void PaintScreen(HWND hWnd, HDC hDC, RECT *pRect);
BOOL InitScreenSettings(HWND hWnd);
void ScnWrch(BYTE ch);
void ScnPrintfs(char *, char *);
void ScnPrintfd(char *, int);
void UpdateHScroll(BOOL redraw);
void UpdateVScroll(BOOL redraw);
void ScrollDown(int Rows);
void ScrollRight(int Cols);
void SetLongestLine();
void SetScreenFont(int size);
void SetScrolls();
void makeCursorVisible();
void prDebug(TCHAR *);
void PlaceScreenCh(TCHAR ch, int X, int Y);
void error(TCHAR *mess);
void busywait(DWORD msecs);
void SetRandomColours();
void CheckBufSpace();

// graphics.c
LRESULT CALLBACK GraphWndProc (HWND, UINT, WPARAM, LPARAM);
LRESULT DoPaintGraph(HWND, UINT, WPARAM, LPARAM);
void InitGraphics(HWND hwnd);


// save.c
void SaveInitialize(HWND hwnd);
BOOL FileSaveDlg(HWND, PTSTR pstrFileName, PTSTR pstrTitleName);
void BufWrite(TCHAR *pstrFileName);
void OkMessage(TCHAR *pstrForm, TCHAR *pstrText);

//======================================================================
// ceBCPL - The BCPL Cintcode System for Windows CE
//
// Written by Martin Richards (c) June 1999
//
// Functions relating to Save and SaveAs Menu items.
// 
//======================================================================
#include <windows.h>                 // For all that Windows stuff
#include <commdlg.h>                 // Command bar includes
#include "ceBCPL.h"                  // Program-specific stuff

static OPENFILENAME ofn;

void SaveInitialize(HWND hwnd) {
    static TCHAR szFilter[] = 
            TEXT ("Text Files (*.TXT)\0*.txt\0") \
            TEXT ("ASCII Files (*.ASC)\0*.asc\0") \
            TEXT ("All Files (*.*)\0*.*\0\0") ;

    ofn.lStructSize       = sizeof(OPENFILENAME);
    ofn.hwndOwner         = hwnd;
    ofn.hInstance         = NULL;
    ofn.lpstrFilter       = szFilter;
    ofn.lpstrCustomFilter = NULL;
    ofn.nMaxCustFilter    = 0;
    ofn.nFilterIndex      = 0;
    ofn.lpstrFile         = NULL;       // Set in Open and Close fns
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrFileTitle    = NULL;       // Set in Open and Close fns
    ofn.nMaxFileTitle     = MAX_PATH;
    ofn.lpstrInitialDir   = NULL;
    ofn.lpstrTitle        = NULL;
    ofn.Flags             = 0;          // Set in Open and Close fns
    ofn.nFileOffset       = 0;
    ofn.nFileExtension    = 0;
    ofn.lpstrDefExt       = TEXT("txt");
    ofn.lCustData         = 0L;
    ofn.lpfnHook          = NULL;
    ofn.lpTemplateName    = NULL;
}

BOOL FileSaveDlg(HWND hwnd, PTSTR pstrFileName, PTSTR pstrTitleName) {
    ofn.hwndOwner        = hwnd;
    ofn.lpstrFile        = pstrFileName;
    ofn.lpstrFileTitle   = pstrTitleName;
    ofn.Flags            = OFN_OVERWRITEPROMPT;

    return GetSaveFileName(&ofn);
}

void BufWrite(TCHAR *pstrFileName) {
    char cv[1026];
    DWORD n=0;
    int i = 0;
    char *p;
    HANDLE fp = CreateFile(pstrFileName,
                           GENERIC_WRITE,
                           FILE_SHARE_WRITE,
                           NULL, // Security
                           CREATE_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL,
                           0);
    if (fp==0) {
        OkMessage(TEXT("Unable to write file %s"), pstrFileName);
        return;
    }
    for (p=Scn.FirstLine; p<Scn.CursorP; p++) {
        char ch = *p;
        if (ch==0) {
            cv[i++] = (char) 13;  // CR
            cv[i++] = (char) 10;  // LF
        } else {
            cv[i++] = (char) ch;
        }
        if (i>=1024) {
            WriteFile(fp, cv, 1024, &n, NULL);
            i -= 1024;
            cv[0] = cv[1024]; // Just is case CR LF inserted
        }
    }
    cv[i++] = (char) 13;  // CR
    cv[i++] = (char) 10;  // LF
    WriteFile(fp, cv, i, &n, NULL);
    CloseHandle(fp);
    return;
}

void OkMessage(TCHAR *szForm, TCHAR *szArg) {
    TCHAR szStr[256];
    wsprintf (szStr, szForm, szArg);
    MessageBox(hMainWnd, szStr, TEXT("Error"), MB_OK);
}





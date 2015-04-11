#include <windows.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/*  Declare Windows procedure  */
LRESULT CALLBACK WindowProcedure (HWND, UINT, WPARAM, LPARAM);

/*  Make the class name into a global variable  */
char szClassName[ ] = "WindowsApp";

int WINAPI WinMain (HINSTANCE hThisInstance,
                    HINSTANCE hPrevInstance,
                    LPSTR lpszArgument,
                    int nFunsterStil)

{
    HWND hwnd;               /* This is the handle for our window */
    MSG messages;            /* Here messages to the application are saved */
    WNDCLASSEX wincl;        /* Data structure for the windowclass */

    /* The Window structure */
    wincl.hInstance = hThisInstance;
    wincl.lpszClassName = szClassName;
    wincl.lpfnWndProc = WindowProcedure;      /* This function is called by windows */
    wincl.style = CS_DBLCLKS;                 /* Catch double-clicks */
    wincl.cbSize = sizeof (WNDCLASSEX);

    /* Use default icon and mouse-pointer */
    wincl.hIcon = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hIconSm = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hCursor = LoadCursor (NULL, IDC_ARROW);
    wincl.lpszMenuName = "MainMenu"; 
    wincl.cbClsExtra = 0;                      /* No extra bytes after the window class */
    wincl.cbWndExtra = 0;                      /* structure or the window instance */
    /* Use Windows's default color as the background of the window */
    wincl.hbrBackground = (HBRUSH) COLOR_BACKGROUND;

    /* Register the window class, and if it fails quit the program */
    if (!RegisterClassEx (&wincl))
        return 0;

    /* The class is registered, let's create the program*/
    hwnd = CreateWindowEx (
           0,                   /* Extended possibilites for variation */
           szClassName,         /* Classname */
           "Windows App",       /* Title Text */
           WS_OVERLAPPEDWINDOW, /* default window */
           CW_USEDEFAULT,       /* Windows decides the position */
           CW_USEDEFAULT,       /* where the window ends up on the screen */
           544,                 /* The programs width */
           375,                 /* and height in pixels */
           HWND_DESKTOP,        /* The window is a child-window to desktop */
           NULL,                /* No menu */
           hThisInstance,       /* Program Instance handler */
           NULL                 /* No Window Creation data */
           );

    /* Make the window visible on the screen */
    ShowWindow (hwnd, nFunsterStil);

    /* Run the message loop. It will run until GetMessage() returns 0 */
    while (GetMessage (&messages, NULL, 0, 0))
    {
        /* Translate virtual-key messages into character messages */
        TranslateMessage(&messages);
        /* Send message to WindowProcedure */
        DispatchMessage(&messages);
    }

    /* The program return-value is 0 - The value that PostQuitMessage() gave */
    return messages.wParam;
}

HWND RegisterWindowsHwnd[32];

void CreateRegisterWindows(HWND hwnd, LPARAM lParam)
{
    int xx, yy;
    int row, col;
    RECT r;
    char regstr[10];
    int regno;

    regno = 0;
    for (row = 0; row < 8; row++) {
        for (col = 0; col < 4; col++) {
            RegisterWindowsHwnd[row * 4 + col] = 
                 CreateWindow("EDIT","", WS_CHILD | WS_VISIBLE,30+col * 100,10+row * 25,60,20,hwnd,0,((LPCREATESTRUCT)lParam)->hInstance,NULL);
         }
     }
}

BOOL FAR PASCAL RegistersDlgProc(HWND hDlg, WORD iMessage, WORD wParam, LONG lParam)
{
WORD status;

switch(iMessage)
{
case WM_INITDIALOG:
     return FALSE;
case WM_COMMAND:
     switch(wParam) {
     case 106:
          EndDialog(hDlg,FALSE);
          return TRUE;
     case 107:
          EndDialog(hDlg,TRUE);
          return TRUE;
     }
     break;
}
return FALSE;
}

/*  This function is called by the Windows function DispatchMessage()  */

LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    int row, col;
    char regstr[10];
    int regno;
    static DLGPROC lpfnRegistersDlgProc;
    static HANDLE hInstance;

    switch (message)                  /* handle the messages */
    {
        case WM_CREATE:
             hInstance = ((LPCREATESTRUCT)lParam)->hInstance;
             lpfnRegistersDlgProc = MakeProcInstance((DLGPROC)RegistersDlgProc,hInstance);
             CreateRegisterWindows(hwnd, lParam);
             return 0;
/*
        case WM_PAINT:
             hdc = BeginPaint(hwnd, &ps);             
            regno = 0;
            for (row = 0; row < 8; row++) {
                for (col = 0; col < 4; col++) {
                    sprintf(regstr, "r%d", regno);
                    TextOut(hdc, 10+col*100, 10+row*25, regstr, strlen(regstr));
                    regno++;
                }
            }
            EndPaint(hwnd, &ps);
            return 0;
*/
        case WM_COMMAND:
             switch(wParam) {
             case 300:
                  DialogBox((HINSTANCE)hInstance, "RegisterDialog", hwnd, lpfnRegistersDlgProc);
                  return 0;
             }
             break;             
        case WM_DESTROY:
            PostQuitMessage (0);       /* send a WM_QUIT to the message queue */
            break;
        default:                      /* for messages that we don't deal with */
            return DefWindowProc (hwnd, message, wParam, lParam);
    }

    return 0;
}


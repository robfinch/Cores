class RegisterPanel
{
public:
    HWND CreateWindow(HWND hwnd, LPARAM lParam) {
         CreateWindow("RegisterWnd", "Registers", WS_CHILD|WS_VISIBLE|WS_OVERLAPPEDWINDOW,0,0,500,400,hwnd,1,((LPCREATESTRUCT)lParam)->hInstance,NULL);
    };
    void CreateWindows(HWND hwnd, LPARAM lParam)
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
};

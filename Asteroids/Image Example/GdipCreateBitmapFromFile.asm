include     GdipCreateBitmapFromFile.inc

.data

ClassName   db "BitmapClass",0
AppName     db "Bitmap from memory",0
filename    db "logo.png",0

.data?

hInstance           dd ?
hBitmap             dd ?
pNumbOfBytesRead    dd ?
StartupInfo         GdiplusStartupInput <?>
UnicodeFileName     db 32 dup(?)
BmpImage            dd ?
token               dd ?

.code

start:

    invoke  GetModuleHandle,NULL
    mov     hInstance,eax
    invoke  GetCommandLine
    invoke  WinMain,hInstance,NULL,eax,SW_SHOWDEFAULT
    invoke  ExitProcess,eax

WinMain PROC hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD

    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    xor     eax,eax
    mov     wc.cbSize,SIZEOF WNDCLASSEX
    mov     wc.style, CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, OFFSET WndProc
    mov     wc.cbClsExtra,eax
    mov     wc.cbWndExtra,eax
    push    hInstance
    pop     wc.hInstance
    mov     wc.hbrBackground,COLOR_WINDOW+1
    mov     wc.lpszMenuName,eax
    
    mov     wc.lpszClassName,OFFSET ClassName
    invoke  LoadIcon,eax,IDI_APPLICATION
    mov     wc.hIcon,eax
    mov     wc.hIconSm,eax
    invoke  LoadCursor,NULL,IDC_ARROW
    mov     wc.hCursor,eax
    invoke  RegisterClassEx, ADDR wc

    xor     eax,eax
    invoke  CreateWindowEx,eax,ADDR ClassName,ADDR AppName,\
            WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
            CW_USEDEFAULT,290,90,eax,eax,\
            hInst,eax
            
    mov     hwnd,eax
    invoke  ShowWindow, hwnd,SW_SHOWNORMAL
    invoke  UpdateWindow, hwnd
    
    .WHILE  TRUE
            invoke  GetMessage, ADDR msg,NULL,0,0
    .BREAK	.if (!eax)
            invoke  TranslateMessage, ADDR msg
            invoke  DispatchMessage, ADDR msg
    .ENDW
    
    mov     eax,msg.wParam
    ret

WinMain ENDP

WndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL hMemDC:HDC
    LOCAL bm:BITMAP

    .IF uMsg==WM_CREATE

        mov     eax,OFFSET StartupInfo
        mov     GdiplusStartupInput.GdiplusVersion[eax],1

        invoke  GdiplusStartup,ADDR token,ADDR StartupInfo,0
        invoke  UnicodeStr,ADDR filename,ADDR UnicodeFileName
								
        invoke  GdipCreateBitmapFromFile,ADDR UnicodeFileName,ADDR BmpImage
									
        invoke  GdipCreateHBITMAPFromBitmap,BmpImage,ADDR hBitmap,0

    .ELSEIF uMsg==WM_PAINT

        invoke  BeginPaint,hWnd,ADDR ps
        mov     hdc,eax

        invoke  CreateCompatibleDC,eax

        mov     hMemDC,eax
        invoke  SelectObject,eax,hBitmap

        invoke  GetObject,hBitmap,sizeof(BITMAP),ADDR bm
        lea     edx,bm
	
        xor     eax,eax

        invoke  BitBlt,hdc,eax,eax,\
                BITMAP.bmWidth[edx],\
                BITMAP.bmHeight[edx],\
                hMemDC,eax,eax,SRCCOPY
            
        invoke  DeleteDC,hMemDC
        invoke  EndPaint,hWnd,ADDR ps

    .ELSEIF uMsg==WM_DESTROY
    
        invoke  DeleteObject,hBitmap
        invoke  GdipDisposeImage,BmpImage
        invoke  PostQuitMessage,NULL
        
    .ELSE
    
        invoke  DefWindowProc,hWnd,uMsg,wParam,lParam		
        ret

    .ENDIF
    
    xor     eax,eax
    ret

WndProc ENDP

UnicodeStr  PROC USES esi ebx Source:DWORD,Dest:DWORD

    mov     ebx,1
    mov     esi,Source
    mov     edx,Dest
    xor     eax,eax
    sub     eax,ebx
@@:
    add     eax,ebx
    movzx   ecx,BYTE PTR [esi+eax]
    mov     WORD PTR [edx+eax*2],cx
    test    ecx,ecx
    jnz     @b
    ret

UnicodeStr  ENDP

END start


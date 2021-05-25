.386              
.model flat, stdcall  
option casemap :none   

include \masm32\include\masm32rt.inc
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\gdiplus.inc
include \masm32\include\Comctl32.inc
include \masm32\include\comdlg32.inc
include \masm32\include\shell32.inc
include \masm32\Include\msimg32.inc
include \masm32\Include\oleaut32.inc
include \masm32\irvine\Irvine32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\LIB\gdi32.lib
includelib \masm32\lib\gdiplus.lib
includelib \masm32\lib\Comctl32.lib
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\shell32.lib
includelib \masm32\irvine\Irvine32.lib
includelib \masm32\lib\msimg32.lib
includelib \masm32\lib\oleaut32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\masm32.lib

szText MACRO Name, Text:VARARG
  LOCAL lbl
    jmp lbl
      Name db Text,0
    lbl:
  ENDM


m2m MACRO M1, M2
  push M2
  pop  M1
ENDM

 
return MACRO arg
  mov eax, arg
  ret
ENDM


  WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
  WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD, :DWORD
  TopXY PROTO   :DWORD,:DWORD

.const
    ICONE   equ     500 
    WM_FINISH equ WM_USER+100h  
    foguete    equ     100
    bigAsteroid    equ     208
    CREF_TRANSPARENT  EQU 00FF00FFh

.data
    szDisplayName        db "Asteroids",0
    filename             db "vialactea.png",0
    CommandLine          dd 0
    hWnd                 dd 0
    buffer               db 128 dup(0)
    hInstance            dd 0
    rotation             dd 0
    xPosition            dd 375
    yPosition            dd 175
    gameStart            dd 0
    asteroidCount        dd 0
    isAlive              dd 1
    isOneAlive           dd 1  
    isTwoAlive           dd 1  
    isThreeAlive         dd 1  
    isFourAlive          dd 1
    xOne                 dd 1       
    yOne                 dd 1        
    xTwo                 dd 1   
    yTwo                 dd 1   
    xThree               dd 1   
    yThree               dd 1  
    xFour                dd 1   
    yFour                dd 1 
    direction1           dd 1
    direction2           dd 1
    direction3           dd 1
    direction4           dd 1

.data?
    dwThreadId dd ?
    hitpoint                  POINT <>
    hitpointEnd               POINT <>
    threadID                  DWORD ?    
    hEventStart               HANDLE ?
    hBmp                      dd ?
    hFoguete                  dd ?
    hHomeScreen               dd ?
    hBigAsteroid              dd ?
    StartupInfo               GdiplusStartupInput <?>
    UnicodeFileName           db 32 dup(?)
    BmpImage                  dd ?
    token                     dd ?

.code
  start:
    randomGeneratorDirection PROC
        call Randomize               

        mov  ax,8                 
        call RandomRange
        mov  direction1,ax 
        call RandomRange
        mov  direction2,ax  
        call RandomRange
        mov  direction3,ax  
        call RandomRange
        mov  direction4,ax          
    randomGeneratorDirection ENDP

    ; myThread PROC

    ;     mov     eax,[esp+4]               
    ;     .while isAlive == 1
    ;       .if asteroidCount == 0
    ;         ; gerar asteroides
    ;       .elseif asteroidCount != 0
    ;         ; andar com asteroides na direcao
    ;         .if direction == 1
    ;         ;move
    ;         .elseif direction == 2
    ;         ;move
    ;         .elseif direction == 3
    ;         ;move
    ;         .elseif direction == 4
    ;         ;move
    ;         .elseif direction == 5
    ;         ;move
    ;         .elseif direction == 6
    ;         ;move
    ;         .elseif direction == 7
    ;         ;move
    ;         .elseif direction == 8
    ;         ;move
    ;         .endif
    ;       .endif

    ;     INVOKE  ExitThread,eax

    ; myThread ENDP

    invoke GetModuleHandle, NULL 
    mov hInstance, eax

    invoke  GetCommandLine    
    mov     CommandLine, eax

    invoke LoadBitmap, hInstance, foguete
    mov    hFoguete, eax

    invoke LoadBitmap, hInstance, bigAsteroid
    mov hBigAsteroid, eax
    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       

    WinMain proc hInst :DWORD, hPrevInst :DWORD, CmdLine :DWORD, CmdShow :DWORD

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      szText szClassName,"Generic_Class"

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_BYTEALIGNWINDOW
      mov wc.lpfnWndProc,    offset WndProc      
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      push  hInst
      pop   wc.hInstance 

      ;m2m wc.hInstance,      hInst              
      mov wc.hbrBackground,  NULL  
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName  
      invoke LoadIcon,hInst,500                
      mov wc.hIcon,          eax
        invoke LoadCursor,NULL,IDC_ARROW         
      mov wc.hCursor,        eax
      mov wc.hIconSm,        0
      invoke RegisterClassEx, ADDR wc     

      mov Wwd, 800
      mov Wht, 450

      invoke GetSystemMetrics,SM_CXSCREEN 
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN 
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPEDWINDOW,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL

      mov   hWnd,eax  

      invoke ShowWindow,hWnd,SW_SHOWNORMAL     
      invoke UpdateWindow,hWnd                  

      StartLoop:
        invoke GetMessage,ADDR msg,NULL,0,0         
        cmp eax, 0                                
        je ExitLoop                                 
        invoke TranslateMessage, ADDR msg          
        invoke DispatchMessage,  ADDR msg       
        jmp StartLoop
      ExitLoop:

      return msg.wParam

    WinMain endp

    UnicodeStr  proc USES esi ebx Source:DWORD,Dest:DWORD

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

    WndProc proc hWin   :DWORD, uMsg   :DWORD, wParam :DWORD, lParam :DWORD, oldParam :DWORD

      LOCAL hDC    :DWORD
      LOCAL Ps     :PAINTSTRUCT
      LOCAL rect   :RECT
      LOCAL Font   :DWORD
      LOCAL Font2  :DWORD
      LOCAL hOld   :DWORD

      LOCAL memDC  :DWORD
      LOCAL memDC2 :DWORD
      LOCAL hBitmap:DWORD

    .if uMsg == WM_COMMAND
    
      .elseif uMsg == WM_LBUTTONDOWN
            
      .elseif uMsg == WM_LBUTTONUP
          
      .elseif uMsg == WM_CHAR

      .elseif uMsg == WM_KEYUP

        .if wParam == VK_UP
          mov oldParam, 0
        .endif
          
    .elseif uMsg == WM_KEYDOWN

      .if wParam == VK_UP

        .if rotation == 0
            .if yPosition >= 6
              sub yPosition, 6
            .endif

          .elseif rotation == 200  
              .if yPosition >= 4   
                .if xPosition <= 700 
                  add xPosition, 6
                  sub yPosition, 6
                .endif
              .endif

          .elseif rotation == 400
            .if xPosition <= 730     
              add xPosition, 6
            .endif

          .elseif rotation == 600 
              .if yPosition <= 360   
                .if xPosition <= 735     
                  add xPosition, 6
                  add yPosition, 6
                .endif
              .endif

          .elseif rotation == 800   
            .if yPosition <= 360     
              add yPosition, 6
            .endif

          .elseif rotation == 1000   
              .if yPosition <= 360   
                .if xPosition >= 4    
                  sub xPosition, 6
                  add yPosition, 6
                .endif
              .endif

          .elseif rotation == 1200   
            .if xPosition >= 6   
              sub xPosition, 6
            .endif  

          .elseif rotation == 1400    
              .if yPosition >= 4   
                .if xPosition >= 4
                  sub xPosition, 6
                  sub yPosition, 6
                .endif
              .endif        

        mov eax, wParam
        mov oldParam, eax
        mov ecx, oldParam
      .endif
    
      Invoke RedrawWindow, hWin, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN 

      .elseif wParam == VK_LEFT

        .if rotation == 0
            mov rotation, 1400

          .elseif rotation != 0     
              sub rotation, 200      
        .endif
        
        Invoke RedrawWindow, hWin, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN 
    
      .elseif wParam == VK_RIGHT

        .if rotation == 1400
            mov rotation, 0

          .elseif rotation != 1400     
              add rotation, 200      
        .endif
    
      Invoke RedrawWindow, hWin, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN

      .elseif wParam == VK_SPACE

      .endif
            
    .elseif uMsg == WM_FINISH
        
    .elseif uMsg == WM_PAINT

      .if gameStart == 0
          invoke BeginPaint,hWin,ADDR Ps
          mov    hDC, eax
          invoke CreateCompatibleDC, hDC
          mov   memDC, eax
          invoke CreateCompatibleDC, hDC
          invoke SelectObject, memDC, hHomeScreen
          invoke BitBlt, hDC, 0, 0,800,450, memDC, 10,10, SRCCOPY
      .elseif
          invoke BeginPaint,hWin,ADDR Ps    
          mov    hDC, eax
          
          invoke CreateCompatibleDC, hDC
          mov   memDC, eax
          invoke CreateCompatibleDC, hDC
          invoke SelectObject, memDC, hBitmap

          invoke SelectObject, memDC, hBmp
          invoke BitBlt, hDC, 0, 0,800,450, memDC, 10,10, SRCCOPY

          invoke SelectObject, memDC, hFoguete
          invoke TransparentBlt, hDC, xPosition, yPosition, 50, 50, memDC, rotation, 0, 200, 200, 16777215

          invoke SelectObject, memDC, hBigAsteroid
          invoke TransparentBlt, hDC, 0, 200, 70, 70, memDC, 0, 0, 242, 271, 16777215

          invoke SelectObject, memDC, hBigAsteroid
          invoke TransparentBlt, hDC, 400, 0, 70, 70, memDC, 0, 0, 242, 271, 16777215

          invoke SelectObject, memDC, hBigAsteroid
          invoke TransparentBlt, hDC, 400, 400, 70, 70, memDC, 0, 0, 242, 271, 16777215

          invoke SelectObject, memDC, hBigAsteroid
          invoke TransparentBlt, hDC, 800, 400, 70, 70, memDC, 0, 0, 242, 271, 16777215

          invoke DeleteDC,memDC

          invoke EndPaint,hWin,ADDR Ps
          return  0
    .endif

    .elseif uMsg == WM_CREATE
      mov     eax,OFFSET StartupInfo
      mov     GdiplusStartupInput.GdiplusVersion[eax],1

      invoke  GdiplusStartup,ADDR token,ADDR StartupInfo,0 
      invoke  UnicodeStr,ADDR filename,ADDR UnicodeFileName
								
      invoke  GdipCreateBitmapFromFile,ADDR UnicodeFileName,ADDR BmpImage
									
      invoke  GdipCreateHBITMAPFromBitmap,BmpImage,ADDR hBmp,0

      ;INVOKE  CreateThread,0,0,myThread,12345678h,0,offset dwThreadId
    
    .elseif uMsg == WM_CLOSE

        szText TheText,"Please Confirm Exit"
        invoke MessageBox,hWin,ADDR TheText,ADDR szDisplayName,MB_YESNO
          .if eax == IDNO
            return 0
          .endif

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

WndProc endp

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1    
    shr wDim, 1   
    mov eax, wDim  
    sub sDim, eax   

    return sDim

TopXY endp

end start

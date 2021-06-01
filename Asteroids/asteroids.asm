.386              
.model flat, stdcall  
option casemap :none

include asteroids.inc

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
    ICONE            equ 500 
    WM_FINISH        equ WM_USER+100h  
    CREF_TRANSPARENT equ 00FF00FFh

.data
    szDisplayName        db "Asteroids",0
    filename             db "vialactea.png",0
    CommandLine          dd 0
    buffer               db 128 dup(0)
    hInstance            dd 0
    rotation             dd 0
    xPosition            dd 375
    yPosition            dd 175
    asteroidCount        dd 0
    isAlive              dd 1
    isOneAlive           dd 1  
    isTwoAlive           dd 1  
    isThreeAlive         dd 1  
    isFourAlive          dd 1
    xOne                 dd 0       
    yOne                 dd 220        
    xTwo                 dd 280   
    yTwo                 dd 0
    xThree               dd 440   
    yThree               dd 340  
    xFour                dd 715 
    yFour                dd 140
    direction1           dd 1
    direction2           dd 1
    direction3           dd 1
    direction4           dd 1

.data?
    threadID DWORD ?
    hitpoint                  POINT <>
    hitpointEnd               POINT <> 
    hEventStart               HANDLE ?
    StartupInfo               GdiplusStartupInput <?>
    UnicodeFileName           db 32 dup(?)
    BmpImage                  dd ?
    token                     dd ?

.code

  start:
    randomGeneratorDirection PROC
        invoke  GetTickCount
        invoke  nseed, eax
        invoke  nrandom, 7
        invoke  dwtoa, eax, offset direction1
        invoke  StdOut, offset direction1   

        invoke  GetTickCount
        invoke  nseed, eax
        invoke  nrandom, 7
        invoke  dwtoa, eax, offset direction2
        invoke  StdOut, offset direction2    

        invoke  GetTickCount
        invoke  nseed, eax
        invoke  nrandom, 7
        invoke  dwtoa, eax, offset direction3
        invoke  StdOut, offset direction3    

        invoke  GetTickCount
        invoke  nseed, eax
        invoke  nrandom, 7
        invoke  dwtoa, eax, offset direction4
        invoke  StdOut, offset direction4         
    randomGeneratorDirection ENDP

    loop1 PROC 
    myLoop:  
      .if isAlive == 0
      ret
      .elseif isAlive == 1
        .if asteroidCount == 0
              ; gerar asteroides
            .elseif asteroidCount != 0
              ; andar com asteroides na direcao
              .if direction1 == 0
              sub yOne, 6
              .elseif direction1 == 1
              sub yOne, 6
              add xOne, 6
              .elseif direction1 == 2
              add xOne, 6
              .elseif direction1 == 3
              add yOne, 6
              add xOne, 6
              .elseif direction1 == 4
              add yOne, 6
              .elseif direction1 == 5
              ;move
              .elseif direction1 == 6
              ;move
              .elseif direction1 == 7
              ;move
              .endif
              .if direction2 == 0
              ;move
              .elseif direction2 == 1
              ;move
              .elseif direction2 == 2
              ;move
              .elseif direction2 == 3
              ;move
              .elseif direction2 == 4
              ;move
              .elseif direction2 == 5
              ;move
              .elseif direction2 == 6
              ;move
              .elseif direction2 == 7
              ;move
              .endif
              .if direction3 == 0
              ;move
              .elseif direction3 == 1
              ;move
              .elseif direction3 == 2
              ;move
              .elseif direction3 == 3
              ;move
              .elseif direction3 == 4
              ;move
              .elseif direction3 == 5
              ;move
              .elseif direction3 == 6
              ;move
              .elseif direction3 == 7
              ;move
              .endif
              .if direction4 == 0
              ;move
              .elseif direction4 == 1
              ;move
              .elseif direction4 == 2
              ;move
              .elseif direction4 == 3
              ;move
              .elseif direction4 == 4
              ;move
              .elseif direction4 == 5
              ;move
              .elseif direction4 == 6
              ;move
              .elseif direction4 == 7
              ;move
              .endif
            .endif
          .endif
        loop myLoop
      loop1 ENDP

    invoke GetModuleHandle, NULL 
    mov hInstance, eax

    invoke  GetCommandLine    
    mov     CommandLine, eax


    ; Invoca-se os bitmaps
    ;loadImages proc
      ; Backgrounds
      invoke LoadBitmap, hInstance, 130
      mov    h_inicio, eax
      invoke LoadBitmap, hInstance, 131
      mov h_universo, eax

      ; Elementos do jogo
      invoke LoadBitmap, hInstance, 110
      mov    foguete_spritesheet, eax
      invoke LoadBitmap, hInstance, 115
      mov naveInimiga_bitmap, eax

      invoke LoadBitmap, hInstance, 120
      mov meteoroG, eax
      invoke LoadBitmap, hInstance, 121
      mov meteoroM, eax
      invoke LoadBitmap, hInstance, 122
      mov meteoroP, eax

      invoke LoadBitmap, hInstance, 140
      mov vida, eax

      ; Tiros do Foguete
      invoke LoadBitmap, hInstance, 151
      mov TF_top_left, eax
      invoke LoadBitmap, hInstance, 152
      mov TF_top, eax
      invoke LoadBitmap, hInstance, 153
      mov TF_top_right, eax
      invoke LoadBitmap, hInstance, 154
      mov TF_right, eax
      invoke LoadBitmap, hInstance, 155
      mov TF_down_right, eax
      invoke LoadBitmap, hInstance, 156
      mov TF_down, eax
      invoke LoadBitmap, hInstance, 157
      mov TF_down_left, eax
      invoke LoadBitmap, hInstance, 158
      mov TF_left, eax

      ; Tiros da Nave
      invoke LoadBitmap, hInstance, 159
      mov TN_top_left, eax
      invoke LoadBitmap, hInstance, 160
      mov TN_top, eax
      invoke LoadBitmap, hInstance, 161
      mov TN_top_right, eax
      invoke LoadBitmap, hInstance, 162
      mov TN_right, eax
      invoke LoadBitmap, hInstance, 163
      mov TN_down_right, eax
      invoke LoadBitmap, hInstance, 164
      mov TN_down, eax
      invoke LoadBitmap, hInstance, 165
      mov TN_down_left, eax
      invoke LoadBitmap, hInstance, 166
      mov TN_left, eax
      ;ret
    ;loadImages endp

    
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

      mov Wwd, WINDOW_SIZE_X
      mov Wht, WINDOW_SIZE_Y

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

    .IF uMsg == WM_CREATE
      ;invoke loadImages

      ; mov     eax,OFFSET StartupInfo
      ; mov     GdiplusStartupInput.GdiplusVersion[eax],1

      ; invoke  GdiplusStartup,ADDR token,ADDR StartupInfo,0 
      ; invoke  UnicodeStr,ADDR filename,ADDR UnicodeFileName            
      ; invoke  GdipCreateBitmapFromFile,ADDR UnicodeFileName,ADDR BmpImage          
      ; invoke  GdipCreateHBITMAPFromBitmap,BmpImage,ADDR h_universo,0

    .elseif uMsg == WM_COMMAND
    
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
          .if GAMESTATE == 0
        mov GAMESTATE, 1
        Invoke RedrawWindow, hWin, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN 

        .elseif GAMESTATE != 0
          ;atirar
        .endif
      .endif
            
    .elseif uMsg == WM_FINISH
  
    
        
    .elseif uMsg == WM_PAINT

      .if GAMESTATE == 0
          invoke BeginPaint,hWin,ADDR Ps

          mov    hDC, eax
          invoke CreateCompatibleDC, hDC

          mov   memDC, eax
          invoke CreateCompatibleDC, hDC

          mov eax, h_inicio
          invoke SelectObject, memDC, eax
          invoke BitBlt, hDC, 0, 0,800,450, memDC, 10,10, SRCCOPY

          invoke DeleteDC,memDC

          invoke EndPaint,hWin,ADDR Ps
          return  0
      .elseif
          invoke BeginPaint,hWin,ADDR Ps    
          mov    hDC, eax
          invoke CreateCompatibleDC, hDC
          mov   memDC, eax
          
          invoke CreateCompatibleDC, hDC
          invoke SelectObject, memDC, hBitmap

          mov eax, h_universo
          invoke SelectObject, memDC, eax
          invoke BitBlt, hDC, 0, 0,800,450, memDC, 10,10, SRCCOPY
          
          invoke SelectObject, memDC, foguete_spritesheet
          ;invoke TransparentBlt, hDC, fogueteJogador.fogueteObj.pos.x, fogueteJogador.fogueteObj.pos.y, 50, 50, memDC, rotation, 0, 200, 200, 16777215
          invoke TransparentBlt, hDC, xPosition, yPosition, 50, 50, memDC, rotation, 0, 200, 200, 16777215

          invoke SelectObject, memDC, meteoroG
          invoke TransparentBlt, hDC, xOne, yOne, 70, 70, memDC, 0, 0, 250, 200, 16777215

          invoke SelectObject, memDC, meteoroG
          invoke TransparentBlt, hDC, xTwo, yTwo, 70, 70, memDC, 0, 0, 250, 200, 16777215

          invoke SelectObject, memDC, meteoroG
          invoke TransparentBlt, hDC, xThree, yThree, 70, 70, memDC, 0, 0, 250, 200, 16777215

          invoke SelectObject, memDC, meteoroG
          invoke TransparentBlt, hDC, xFour, yFour, 70, 70, memDC, 0, 0, 250, 200, 16777215

          invoke SelectObject, memDC, meteoroM
          invoke TransparentBlt, hDC, 130, 260, 70, 70, memDC, 0, 0, 250, 200, 16777215

          invoke SelectObject, memDC, meteoroP
          invoke TransparentBlt, hDC, 200, 260, 70, 70, memDC, 0, 0, 250, 200, 16777215 

          invoke DeleteDC,memDC

          invoke EndPaint,hWin,ADDR Ps
          return  0
    .endif

    ;mov  eax,OFFSET ThreadProc
    invoke CreateThread,0,0,loop1,0,0,threadID ; threadID can be NULL
    ;invoke CloseHandle,eax
    
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

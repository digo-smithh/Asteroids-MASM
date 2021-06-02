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

.data ;SEÇÃO DE VARIÁVEIS
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

.data? ;SEÇÃO DE VARIÁVEIS
    threadID                  DWORD ?
    hitpoint                  POINT <>
    hitpointEnd               POINT <> 
    hEventStart               HANDLE ?
    StartupInfo               GdiplusStartupInput <?>
    UnicodeFileName           db 32 dup(?)
    BmpImage                  dd ?
    token                     dd ?

.code ;CÓDIGO
  start: ;"MÉTODO MAIN"
  
      ; randomGeneratorDirection PROC ;PROCEDIMENTO PARA CRIAR DIREÇÕES ALEATÓRIAS
      ;   invoke  GetTickCount
      ;   invoke  nseed, eax
      ;   invoke  nrandom, 7
      ;   invoke  dwtoa, eax, offset direction1
      ;   invoke  StdOut, offset direction1   

      ;   invoke  GetTickCount
      ;   invoke  nseed, eax
      ;   invoke  nrandom, 7
      ;   invoke  dwtoa, eax, offset direction2
      ;   invoke  StdOut, offset direction2    

      ;   invoke  GetTickCount
      ;   invoke  nseed, eax
      ;   invoke  nrandom, 7
      ;   invoke  dwtoa, eax, offset direction3
      ;   invoke  StdOut, offset direction3    

      ;   invoke  GetTickCount
      ;   invoke  nseed, eax
      ;   invoke  nrandom, 7
      ;   invoke  dwtoa, eax, offset direction4
      ;   invoke  StdOut, offset direction4         
      ; randomGeneratorDirection ENDP

      invoke GetModuleHandle, NULL 
      mov hInstance, eax

      invoke  GetCommandLine    
      mov     CommandLine, eax

      ; CARREGA A IMAGEM DE INÍCIO E O BACKGROUND
      invoke LoadBitmap, hInstance, 130
      mov    h_inicio, eax
      invoke LoadBitmap, hInstance, 131
      mov h_universo, eax

      ; CARREGA OS ELEMENTOS DO JOGO
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

      ; TIROS DO FOGUETE
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

      ; TIROS DA NAVE
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
    
      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      
      invoke ExitProcess,eax       

      WinMain proc hInst :DWORD, hPrevInst :DWORD, CmdLine :DWORD, CmdShow :DWORD ;PROCEDIMENTO RESPONSÁVEL POR CRIAR O APLICATIVO

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

      UnicodeStr  proc USES esi ebx Source:DWORD,Dest:DWORD ;PROCEDIMENTO RESPONSÁVEL PELA ESCRITA DE STRINGS

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

      WndProc proc hWin   :DWORD, uMsg   :DWORD, wParam :DWORD, lParam :DWORD, oldParam :DWORD ;PROCEDIMENTO RESPONSÁVEL PELAS INTERAÇOES DO USER

        LOCAL hDC    :DWORD
        LOCAL Ps     :PAINTSTRUCT
        LOCAL rect   :RECT
        LOCAL Font   :DWORD
        LOCAL Font2  :DWORD
        LOCAL hOld   :DWORD

        LOCAL memDC  :DWORD
        LOCAL memDC2 :DWORD
        LOCAL hBitmap:DWORD

        
        .if uMsg == WM_CREATE

          invoke  CreateEvent, NULL, FALSE, FALSE, NULL
		      mov     hEventStart, eax
          mov eax, offset ThreadProc
		      invoke CreateThread, NULL, NULL, eax, NULL, NORMAL_PRIORITY_CLASS, ADDR threadID

        .elseif uMsg == WM_COMMAND    
        .elseif uMsg == WM_LBUTTONDOWN           
        .elseif uMsg == WM_LBUTTONUP        
        .elseif uMsg == WM_CHAR
        .elseif uMsg == WM_KEYUP

          .if wParam == VK_UP ;EVENTO DE SOLTAR UMA TECLA
            mov oldParam, 0
          .endif
          
        .elseif uMsg == WM_KEYDOWN ;EVENTO DE PRESSIONAR UMA TECLA

          .if wParam == VK_UP ;SETA PARA CIMA
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
  
          .elseif wParam == VK_LEFT ;SETA PARA ESQUERDA
            .if rotation == 0
                mov rotation, 1400
            .elseif rotation != 0     
                sub rotation, 200      
            .endif
         
          .elseif wParam == VK_RIGHT ;SETA PARA DIREITA
            .if rotation == 1400
                mov rotation, 0
            .elseif rotation != 1400     
                add rotation, 200      
            .endif
  
          .elseif wParam == VK_SPACE ;ESPAÇO
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
              invoke TransparentBlt, hDC, xPosition, yPosition, 50, 50, memDC, rotation, 0, 200, 200, 16777215

              invoke SelectObject, memDC, meteoroG
              invoke TransparentBlt, hDC, xOne, yOne, 70, 70, memDC, 0, 0, 250, 200, 16777215

              invoke SelectObject, memDC, meteoroG
              invoke TransparentBlt, hDC, xTwo, yTwo, 70, 70, memDC, 0, 0, 250, 200, 16777215

              invoke SelectObject, memDC, meteoroG
              invoke TransparentBlt, hDC, xThree, yThree, 70, 70, memDC, 0, 0, 250, 200, 16777215

              invoke SelectObject, memDC, meteoroG
              invoke TransparentBlt, hDC, xFour, yFour, 70, 70, memDC, 0, 0, 250, 200, 16777215

              ;invoke SelectObject, memDC, meteoroM
              ;invoke TransparentBlt, hDC, 130, 260, 70, 70, memDC, 0, 0, 250, 200, 16777215

              ;invoke SelectObject, memDC, meteoroP
              ;invoke TransparentBlt, hDC, 200, 260, 70, 70, memDC, 0, 0, 250, 200, 16777215 

              invoke DeleteDC,memDC
              invoke EndPaint,hWin,ADDR Ps
              
              return  0
          .endif
    
        .elseif uMsg == WM_CLOSE ;EVENTO DE FECHAR O APLICATIVO

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

      MoveAsteroids proc
        .if asteroidCount == 0
           ;invoke randomGeneratorDirection
           mov xOne, 0
           mov yOne, 220
           mov xTwo, 280
           mov yTwo, 0
           mov xThree, 440
           mov yThree, 340
           mov xFour, 715
           mov yFour, 140
           mov asteroidCount, 4
        .elseif asteroidCount != 0
          ; andar com asteroides na direcao
          .if direction1 == 0
          sub yOne, 1
          .elseif direction1 == 1
          sub yOne, 1
          add xOne, 1
           .elseif direction1 == 2
          add xOne, 1
          .elseif direction1 == 3
          add yOne, 1
          add xOne, 1
          .elseif direction1 == 4
          add yOne, 1
          .elseif direction1 == 5
          add yOne, 1
          sub xOne, 1
          .elseif direction1 == 6
          sub xOne, 1
          .elseif direction1 == 7
          sub yOne, 1
          sub xOne, 1
          .endif
          .if direction2 == 0
          sub yTwo, 1
          .elseif direction2 == 1
          sub yTwo, 1
          add xTwo, 1
          .elseif direction2 == 2
          add xTwo, 1
          .elseif direction2 == 3
          add yTwo, 1
          add xTwo, 1
          .elseif direction2 == 4
          add yTwo, 1
          .elseif direction2 == 5
          add yTwo, 1
          sub xTwo, 1
          .elseif direction2 == 6
          sub xTwo, 1
          .elseif direction2 == 7
          sub yTwo, 1
          sub xTwo, 1
          .endif
          .if direction3 == 0
          sub yThree, 1
          .elseif direction3 == 1
          sub yThree, 1
          add xThree, 1
          .elseif direction3 == 2
          add xThree, 1
          .elseif direction3 == 3
          add yThree, 1
          add xThree, 1
          .elseif direction3 == 4
          add yThree, 1
          .elseif direction3 == 5
          add yThree, 1
          sub xThree, 1
          .elseif direction3 == 6
          sub xThree, 1
          .elseif direction3 == 7
          sub yThree, 1
          sub xThree, 1
          .endif
          .if direction4 == 0
          sub yFour, 1
          .elseif direction4 == 1
          sub yFour, 1
          add xFour, 1
          .elseif direction4 == 2
          add xFour, 1
          .elseif direction4 == 3
          add yFour, 1
          add xFour, 1
          .elseif direction4 == 4
          add yFour, 1
          .elseif direction4 == 5
          add yFour, 1
          sub xFour, 1
          .elseif direction4 == 6
          sub xFour, 1
          .elseif direction4 == 7
          sub yFour, 1
          sub xFour, 1
          .endif



          .if xOne > WINDOW_SIZE_X && xOne < 80000000h
            mov xOne, 20                   ;sorry
          .endif
          .if xOne <= 10 ||  xOne > 80000000h
            mov xOne, WINDOW_SIZE_X - 20 
          .endif
          .if yOne > WINDOW_SIZE_Y - 70 && yOne < 80000000h
            mov yOne, 20
          .endif
          .if yOne <= 10 || yOne > 80000000h
            mov yOne, WINDOW_SIZE_Y - 80 
          .endif

          .if xTwo > WINDOW_SIZE_X && xTwo < 80000000h
            mov xTwo, 20                   ;sorry
          .endif
          .if xTwo <= 10 ||  xTwo > 80000000h
            mov xTwo, WINDOW_SIZE_X - 20 
          .endif
          .if yTwo > WINDOW_SIZE_Y - 70 && yTwo < 80000000h
            mov yTwo, 20
          .endif
          .if yTwo <= 10 || yTwo > 80000000h
            mov yTwo, WINDOW_SIZE_Y - 80 
          .endif

          .if xThree > WINDOW_SIZE_X && xThree < 80000000h
            mov xThree, 20                   ;sorry
          .endif
          .if xThree <= 10 ||  xThree > 80000000h
            mov xThree, WINDOW_SIZE_X - 20 
          .endif
          .if yThree > WINDOW_SIZE_Y - 70 && yThree < 80000000h
            mov yThree, 20
          .endif
          .if yThree <= 10 || yThree > 80000000h
            mov yThree, WINDOW_SIZE_Y - 80 
          .endif

          .if xFour > WINDOW_SIZE_X && xFour < 80000000h
            mov xFour, 20                   ;sorry
          .endif
          .if xFour <= 10 ||  xFour > 80000000h
            mov xFour, WINDOW_SIZE_X - 20 
          .endif
          .if yFour > WINDOW_SIZE_Y - 70 && yFour < 80000000h
            mov yFour, 20
          .endif
          .if yFour <= 10 || yFour > 80000000h
            mov yFour, WINDOW_SIZE_Y - 80 
          .endif
        .endif
        ret
      MoveAsteroids endp

      ThreadProc proc uses eax Param:DWORD
        invoke WaitForSingleObject, hEventStart, 33
        .if eax == WAIT_TIMEOUT

          mov eax, isAlive
          .if eax == 0
            ; MORREU
          .elseif eax == 1
            invoke MoveAsteroids
          .endif

          Invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN
        .endif

        jmp  ThreadProc
        ret
      ThreadProc endp

end start

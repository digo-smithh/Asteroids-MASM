; #########################################################################
;
;             GENERIC.ASM is a roadmap around a standard 32 bit 
;              windows application skeleton written in MASM32.
;
; #########################################################################

;           Assembler specific instructions for 32 bit ASM code

      .386                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive

; #########################################################################
      include \masm32\include\masm32rt.inc

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc

      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------

      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc
      include     \masm32\include\gdiplus.inc

      include \MASM32\INCLUDE\Comctl32.inc
      include \MASM32\INCLUDE\comdlg32.inc
      include \MASM32\INCLUDE\shell32.inc
      INCLUDE \Masm32\Include\msimg32.inc
      INCLUDE \Masm32\Include\oleaut32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
      includelib  \masm32\lib\gdiplus.lib
      includelib \MASM32\LIB\Comctl32.lib
      includelib \MASM32\LIB\comdlg32.lib
      includelib \MASM32\LIB\shell32.lib

    INCLUDELIB \Masm32\Lib\msimg32.lib
    INCLUDELIB \Masm32\Lib\oleaut32.lib
    INCLUDELIB \Masm32\Lib\msvcrt.lib
    INCLUDELIB \Masm32\Lib\masm32.lib
; #########################################################################

; ------------------------------------------------------------------------
; MACROS are a method of expanding text at assembly time. This allows the
; programmer a tidy and convenient way of using COMMON blocks of code with
; the capacity to use DIFFERENT parameters in each block.
; ------------------------------------------------------------------------

      ; 1. szText
      ; A macro to insert TEXT into the code section for convenient and 
      ; more intuitive coding of functions that use byte data as text.

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      ; 2. m2m
      ; There is no mnemonic to copy from one memory location to another,
      ; this macro saves repeated coding of this process and is easier to
      ; read in complex code.

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      ; 3. return
      ; Every procedure MUST have a "ret" to return the instruction
      ; pointer EIP back to the next instruction after the call that
      ; branched to it. This macro puts a return value in eax and
      ; makes the "ret" instruction on one line. It is mainly used
      ; for clear coding in complex conditionals in large branching
      ; code such as the WndProc procedure.

      return MACRO arg
        mov eax, arg
        ret
      ENDM

; #########################################################################

; ----------------------------------------------------------------------
; Prototypes are used in conjunction with the MASM "invoke" syntax for
; checking the number and size of parameters passed to a procedure. This
; improves the reliability of code that is written where errors in
; parameters are caught and displayed at assembly time.
; ----------------------------------------------------------------------

        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD, :DWORD
        TopXY PROTO   :DWORD,:DWORD

; #########################################################################

; ------------------------------------------------------------------------
; This is the INITIALISED data section meaning that data declared here has
; an initial value. You can also use an UNINIALISED section if you need
; data of that type [ .data? ]. Note that they are different and occur in
; different sections.
; ------------------------------------------------------------------------
.const
    ICONE   equ     500 ; define o numero associado ao icon igual ao arquivo RC
    ; define o numero da mensagem criada pelo usuario
    WM_FINISH equ WM_USER+100h  ; o numero da mensagem é a ultima + 100h
    foguete    equ     100
    bigAsteroid    equ     400
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
        asteroidCount        dd 4
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

; #########################################################################

.data?
        dwThreadId dd ?
        hitpoint                  POINT <>
        hitpointEnd               POINT <>
        threadID                  DWORD ?    
        hEventStart               HANDLE ?
        hBmp                      dd ?
        hFoguete                  dd ?
        hBigAsteroid              dd ?
        StartupInfo               GdiplusStartupInput <?>
        UnicodeFileName           db 32 dup(?)
        BmpImage                  dd ?
        token                     dd ?
; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------

    .code

; -----------------------------------------------------------------------
; The label "start:" is the address of the start of the code section and
; it has a matching "end start" at the end of the file. All procedures in
; this module must be written between these two.
; -----------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke  GetCommandLine        ; provides the command line address
    mov     CommandLine, eax

    ; carrego o bitmap
    invoke LoadBitmap, hInstance, foguete
    mov    hFoguete, eax

    invoke LoadBitmap, hInstance, bigAsteroid
    mov hBigAsteroid, eax

    ; eax tem o ponteiro para uma string que mostra toda linha de comando.
    ;invoke wsprintf,addr buffer,chr$("%s"), eax
    ;invoke MessageBox,NULL,ADDR buffer,ADDR szDisplayName,MB_OK

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

; ########################################################################
MyThread PROC

    mov     eax,[esp+4]                ;EAX = 12345678h
    ; .while isAlive == 1
    ; andar com os asteroids
    INVOKE  ExitThread,eax

MyThread ENDP

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Generic_Class"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+1     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
        ; id do icon no arquivo RC
        invoke LoadIcon,hInst,500                  ; icon ID   ; resource icon
        mov wc.hIcon,          eax
          invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

        ;================================
        ; Centre window at following size
        ;================================

        mov Wwd, 800
        mov Wht, 450

        invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
        invoke TopXY,Wwd,eax
        mov Wtx, eax

        invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
        invoke TopXY,Wht,eax
        mov Wty, eax

        ; ==================================
        ; Create the main application window
        ; ==================================
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR szDisplayName,
                              WS_OVERLAPPEDWINDOW,
                              Wtx,Wty,Wwd,Wht,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################
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

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD,
             oldParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL rect   :RECT
    LOCAL Font   :DWORD
    LOCAL Font2  :DWORD
    LOCAL hOld   :DWORD

    LOCAL memDC  :DWORD
    LOCAL memDC2 :DWORD
    LOCAL hBitmap:DWORD

    ; cuidado ao declarar variaveis locais pois ao terminar o procedimento
    ; seu valor é limpado colocado lixo no lugar.
; -------------------------------------------------------------------------
; Message are sent by the operating system to an application through the
; WndProc proc. Each message can have additional values associated with it
; in the two parameters, wParam & lParam. The range of additional data that
; can be passed to an application is determined by the message.
; -------------------------------------------------------------------------

    .if uMsg == WM_COMMAND
    ;----------------------------------------------------------------------
    ; The WM_COMMAND message is sent by menus, buttons and toolbar buttons.
    ; Processing the wParam parameter of it is the method of obtaining the
    ; control's ID number so that the code for each operation can be
    ; processed. NOTE that the ID number is in the LOWORD of the wParam
    ; passed with the WM_COMMAND message. There may be some instances where
    ; an application needs to seperate the high and low words of wParam.
    ; ---------------------------------------------------------------------
    
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
            invoke BeginPaint,hWin,ADDR Ps
            ; aqui entra o desejamos desenha, escrever e outros.
            mov    hDC, eax

            .if asteroidCount == 0
            ; add 4 asteroids
            .endif
            .if isOneAlive == 1
            ; repaint 1st asteroid
            .endif
            .if isTwoAlive == 1
            ; repaint 2nd asteroid
            .endif
            .if isThreeAlive == 1
            ; repaint 3rd asteroid
            .endif
            .if isFourAlive == 1
            ; repaint 4th asteroid
            .endif
            
            invoke CreateCompatibleDC, hDC
            mov   memDC, eax
            invoke CreateCompatibleDC, hDC
            mov   memDC2, eax
            invoke CreateCompatibleBitmap, hDC, 800, 450
            mov hBitmap, eax
            invoke SelectObject, memDC, hBitmap

            invoke SelectObject, memDC, hBmp
            invoke BitBlt, hDC, 0, 0,800,450, memDC, 10,10, SRCCOPY

            invoke SelectObject, memDC2, hFoguete
            invoke TransparentBlt, memDC, xPosition, yPosition, 50, 50, memDC2, rotation, 0, 200, 200, 16777215

            invoke SelectObject, memDC2, hBigAsteroid
            invoke TransparentBlt, memDC, 0, 0, 100, 100, memDC2, 0, 0, 240, 272, 16777215

            invoke DeleteDC,memDC
            invoke DeleteDC,memDC2

            invoke EndPaint,hWin,ADDR Ps
            return  0

    .elseif uMsg == WM_CREATE
      mov     eax,OFFSET StartupInfo
      mov     GdiplusStartupInput.GdiplusVersion[eax],1

      invoke  GdiplusStartup,ADDR token,ADDR StartupInfo,0 
      invoke  UnicodeStr,ADDR filename,ADDR UnicodeFileName
								
      invoke  GdipCreateBitmapFromFile,ADDR UnicodeFileName,ADDR BmpImage
									
      invoke  GdipCreateHBITMAPFromBitmap,BmpImage,ADDR hBmp,0

      INVOKE  CreateThread,0,0,MyThread,12345678h,0,offset dwThreadId
    ; --------------------------------------------------------------------
    ; This message is sent to WndProc during the CreateWindowEx function
    ; call and is processed before it returns. This is used as a position
    ; to start other items such as controls. IMPORTANT, the handle for the
    ; CreateWindowEx call in the WinMain does not yet exist so the HANDLE
    ; passed to the WndProc [ hWin ] must be used here for any controls
    ; or child windows.
    ; --------------------------------------------------------------------
    
    .elseif uMsg == WM_CLOSE
    ; -------------------------------------------------------------------
    ; This is the place where various requirements are performed before
    ; the application exits to the operating system such as deleting
    ; resources and testing if files have been saved. You have the option
    ; of returning ZERO if you don't wish the application to close which
    ; exits the WndProc procedure without passing this message to the
    ; default window processing done by the operating system.
    ; -------------------------------------------------------------------
        szText TheText,"Please Confirm Exit"
        invoke MessageBox,hWin,ADDR TheText,ADDR szDisplayName,MB_YESNO
          .if eax == IDNO
            return 0
          .endif

    .elseif uMsg == WM_DESTROY
    ; ----------------------------------------------------------------
    ; This message MUST be processed to cleanly exit the application.
    ; Calling the PostQuitMessage() function makes the GetMessage()
    ; function in the WinMain() main loop return ZERO which exits the
    ; application correctly. If this message is not processed properly
    ; the window disappears but the code is left in memory.
    ; ----------------------------------------------------------------
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ; --------------------------------------------------------------------
    ; Default window processing is done by the operating system for any
    ; message that is not processed by the application in the WndProc
    ; procedure. If the application requires other than default processing
    ; it executes the code when the message is trapped and returns ZERO
    ; to exit the WndProc procedure before the default window processing
    ; occurs with the call to DefWindowProc().
    ; --------------------------------------------------------------------

    ret

WndProc endp



TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp


; ########################################################################

end start

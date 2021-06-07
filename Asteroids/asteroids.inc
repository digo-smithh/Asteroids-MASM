include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib
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
include assets/libraries/ufmod.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\LIB\gdi32.lib
includelib \masm32\lib\gdiplus.lib
includelib \masm32\lib\Comctl32.lib
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\shell32.lib
includelib \masm32\lib\msimg32.lib
includelib \masm32\lib\oleaut32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\masm32.lib
includelib assets/libraries/ufmod.lib

point struct 
    x dd 0      
    y dd 0
point ends

gameObject struct
    pos      point <>
    speed    point <> ; horizontal and vertical speeds
gameObject ends

foguete struct
    fogueteObj            gameObject <>
    stopped               BYTE 0
    life                  BYTE 5
    move                  BYTE 0
    rotation              DWORD 0
    direction             BYTE 0
    left                  BYTE 0
    right                 BYTE 0
    points                DWORD 0
foguete ends

nave struct
    naveObj               gameObject <>
    direction             BYTE 0 ; Ele muda de direção a cada 1,5s (apenas sua speed Y varia, sua speed X é definida no momento de aparecimento)
    destroyed             BYTE 0 ;
nave ends

tiro struct
    tiroObj               gameObject <>
    remainingDistance     DWORD 0    ; A DISTANCIA A SER PERCORRIDA
    direction             BYTE  0 
    exists                BYTE  0    
tiro ends 

; tiroNave struct
;     tiroObj               gameObject <>
;     remainingDistance     DWORD 0    ; A DISTANCIA A SER PERCORRIDA
;     direction             BYTE  0   
;     exists                BYTE  0 
; tiroNave ends 

asteroideG struct
    asteroideObj          gameObject <>
    direction             dd 0
    destroyed             BYTE 0 ; PARA VERIFICAR SE FOI DESTRUIDO PELO FOGUETE OU PELO TIRO
    exploded              BYTE 0
asteroideG ends

asteroideM struct
    asteroideObj          gameObject <>
    direction             BYTE 0
    destroyed             BYTE 0 ; PARA VERIFICAR SE FOI DESTRUIDO PELO FOGUETE OU PELO TIRO
asteroideM ends

asteroideP struct
    asteroideObj          gameObject <>
    direction             BYTE 0
    destroyed             BYTE 0 ; PARA VERIFICAR SE FOI DESTRUIDO PELO FOGUETE OU PELO TIRO
asteroideP ends


.CONST
    WINDOW_SIZE_X      EQU 790
    WINDOW_SIZE_Y      EQU 440

    D_RIGHT            EQU 0 
    D_TOP              EQU 1  
    D_LEFT             EQU 2     
    D_DOWN             EQU 3
    D_DOWN_RIGHT       EQU 4
    D_TOP_RIGHT        EQU 5
    D_TOP_LEFT         EQU 6
    D_DOWN_LEFT        EQU 7

    FOGUETE_SIZE_POINT  point <50,50>
    ASTEROIDE_SIZE_POINT  point <70,70>
    TIRO_SIZE_POINT     point <20,20>
    NAVE_SIZE_POINT     POINT <55,55>

    FOGUETE_SIZE       EQU 50
    FOGUETE_HALF_SIZE  EQU FOGUETE_SIZE / 2

    NAVE_SIZE       EQU 55
    NAVE_HALF_SIZE  EQU NAVE_SIZE / 2

    TIRO_SIZE       EQU 20
    TIRO_HALF_SIZE  EQU TIRO_SIZE / 2

    ASTEROIDE_SIZE  EQU 70
    ASTEROIDE_HALF_SIZE EQU ASTEROIDE_SIZE / 2

    LIFE_SIZE          EQU 30

    FOGUETENAVE_SPEED  EQU 10
    TIRO_SPEED         EQU 40
    ASTEROIDG_SPEED    EQU 4
    ASTEROIDM_SPEED    EQU 6
    ASTEROIDP_SPEED    EQU 8


.DATA
    ;big_buffer  db 65536 dup(?)
    ;            db 65536 dup(?)
    ;            db 65536 dup(?)

    ;paintstruct        PAINTSTRUCT <>

    ;PLAYER_SIZE_POINT  point <46,46>
    ;ARROW_SIZE_POINT   point <42,42>
    ;ARROW_HALF_SIZE_P  point <21,21>

    ;Background bitmaps:
    h_inicio                dd 0
    h_universo              dd 0
    h_gameover              dd 0

    ; Player spritesheet
    foguete_spritesheet    dd 0
    ; Nave Inimiga Bitmap
    naveInimiga_bitmap     dd 0
    ; MeteoroG
    meteoroG               dd 0
    ; MeteoroM
    meteoroM               dd 0
    ; MeteoroP
    meteoroP               dd 0

    ; Meteoro destruido
    explosao               dd 0

    ; Tiro do Foguete bitmaps:
    TF_top_left       dd 0
    TF_top            dd 0
    TF_top_right      dd 0
    TF_right          dd 0
    TF_down_right     dd 0
    TF_down           dd 0
    TF_down_left      dd 0
    TF_left           dd 0

    ; Tiro da Nave bitmaps:
    TN_top_left       dd 0
    TN_top            dd 0
    TN_top_right      dd 0
    TN_right          dd 0
    TN_down_right     dd 0
    TN_down           dd 0
    TN_down_left      dd 0
    TN_left           dd 0

    ; Vida bitmaps:
    vida         dd 0

    ;test_header_format  db  "A: %d",13,10,0
    ;buffer              db 256 dup(?)
    ;msgBoxTitle         db "Testing",0

    acabou byte 0                                ; controla o estado do jogo, se está rolando ou acabou

    ; Players
    fogueteJogador foguete <<<375, 175>,  <FOGUETENAVE_SPEED,FOGUETENAVE_SPEED>>, 0, 5, 1, 0, 0, 1, 1, 0>  ; inicializando o foguete na direção do top

    naveInimiga nave <<<50, 50>, <FOGUETENAVE_SPEED, FOGUETENAVE_SPEED>>, 0, 0> 
    
    tiroF tiro <<<100, 100>, <TIRO_SPEED, TIRO_SPEED>>, 0, 0, 1>  
    tiroN tiro <<<150, 100>, <TIRO_SPEED, TIRO_SPEED>>, 0, 0, 1>
    ;tiroN tiroNave <<<-50, -50>, <TIRO_SPEED, TIRO_SPEED>>, 0, 1>

    asteroideG1 asteroideG <<<0, 0>, <ASTEROIDG_SPEED, ASTEROIDG_SPEED>>, 0, 1, 1> 
    asteroideG2 asteroideG <<<280, 0>, <ASTEROIDG_SPEED, ASTEROIDG_SPEED>>, 0, 1, 1> 
    asteroideG3 asteroideG <<<420, 340>, <ASTEROIDG_SPEED, ASTEROIDG_SPEED>>, 0, 1, 1> 
    asteroideG4 asteroideG <<<715, 140>, <ASTEROIDG_SPEED, ASTEROIDG_SPEED>>, 0, 1, 1> 

    asteroideM1 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM2 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM3 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM4 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM5 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM6 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM7 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 
    asteroideM8 asteroideM <<<-50, -50>, <ASTEROIDM_SPEED, ASTEROIDM_SPEED>>, 0, 0> 

    ; ASTEROIDEP ??????????
    
    GAMESTATE             BYTE 0 ; Define os estados do jogo, se está na gameplay em si, se está no início ou se acabou...


.DATA?
    hWnd HWND ?
    thread1ID DWORD ?
    thread2ID DWORD ?
    thread3ID DWORD ?
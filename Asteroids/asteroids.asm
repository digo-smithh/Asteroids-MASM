.386              
.model flat, stdcall  
option casemap :none

include asteroids.inc

;Program made by:
;Eduardo de Almeida Migueis, 19167
;Enzo Furegatti Spinella, 19168
;Rodrigo Smith Rodrigues, 19197

TEXT_ MACRO your_text:VARARG 
    LOCAL text_string
    .data
        text_string db your_text,0
    .code
    EXITM <addr text_string>
ENDM

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

TEXT_ MACRO your_text:VARARG 
    LOCAL text_string
    .data
        text_string db your_text,0
    .code
    EXITM <addr text_string>
ENDM

  WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
  WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD, :DWORD
  TopXY PROTO   :DWORD,:DWORD

.const ;constantes usadas pelo app
    ICONE            equ 500 ; app icon
    WM_FINISH        equ WM_USER+100h  

.data
    szDisplayName        db "Asteroids",0
    CommandLine          dd 0
    buffer               db 128 dup(0)
    hInstance            dd 0
    asteroidCount        dd 0
    isAlive              dd 1 ; jogador está vivo?
    counter              dd 0 ;contador das vezes jogadas
    randomArray          db "15372561372004356172061524", 0

    musica               db "assets/musics/music.mp3",0
    explosao_asteroide   db "assets/musics/explosion.mp3",0
    explosao_foguete     db "assets/musics/explosion2.mp3",0
    shoot                db "assets/musics/shoot.mp3",0
    game_over            db "assets/musics/game_over.mp3",0

    ; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
		open_dwCallback     dd ?
		open_wDeviceID     dd ?
		open_lpstrDeviceType  dd ?
		open_lpstrElementName  dd ?
		open_lpstrAlias     dd ?

		; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
		generic_dwCallback   dd ?

		; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
		play_dwCallback     dd ?
		play_dwFrom       dd ?
		play_dwTo        dd ?  

.data?
    dwThreadId dd ?
    hitpoint                  POINT <>
    hitpointEnd               POINT <>
    threadID                  DWORD ?    ;id da thread chamada pelo start
    hEventStart               HANDLE ?
    StartupInfo               GdiplusStartupInput <?>
    UnicodeFileName           db 32 dup(?)
    BmpImage                  dd ? ;bitmap image
    token                     dd ?

.code ; início da sessão de código
  start: ; "main"
    ; invoke  uFMOD_PlaySong,TEXT_("music.xm"),0,XM_FILE
    invoke GetModuleHandle, NULL 
    mov hInstance, eax
    invoke  GetCommandLine    ; invoke cmd
    mov     CommandLine, eax
    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    invoke ExitProcess,eax ; sai do processo

  ; Procedures
paintBackground proc _hdc:HDC, _hMemDC:HDC ; pinta o fundo na tela
  LOCAL rect   :RECT

  .if GAMESTATE == 0
    invoke SelectObject, _hMemDC, h_inicio
  .endif

  .if GAMESTATE == 1
    invoke SelectObject, _hMemDC, h_universo
    
    ; Print da pontuação
    invoke SetTextColor,_hMemDC,00FF8800h  
    invoke wsprintf, addr buffer, chr$("%d"), fogueteJogador.points
    mov   rect.left, 360
    mov   rect.top , 10
    mov   rect.right, 490
    mov   rect.bottom, 50  

    invoke DrawText, _hMemDC, addr buffer, -1, \
        addr rect, DT_CENTER 
  .endif

  .if GAMESTATE == 2
    invoke SelectObject, _hMemDC, h_gameover

    invoke SetTextColor,_hMemDC,00FF8800h
    invoke wsprintf, addr buffer, chr$("PONTUACAO FINAL: %d"), fogueteJogador.points
    mov   rect.left, 200
    mov   rect.top , 600
    mov   rect.right, 600
    mov   rect.bottom, 50  
    invoke DrawText, _hMemDC, addr buffer, -1, \
        addr rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE
  .endif

  invoke BitBlt, _hdc, 0, 0, 800, 450, _hMemDC, 0, 0, SRCCOPY

  ret
paintBackground endp ;fim da proc

paintVidas proc _hdc:HDC, _hMemDC:HDC ; pinta as vidas na tela
  invoke SelectObject, _hMemDC, vida
  mov ebx, 0
  movzx ecx, fogueteJogador.life
  .while ebx != ecx
      mov eax, LIFE_SIZE
      mul ebx
      push ecx
      mov edx, WINDOW_SIZE_X
      sub edx, LIFE_SIZE
      sub edx, eax
      invoke TransparentBlt, _hdc, edx, 5,\
              LIFE_SIZE, LIFE_SIZE, _hMemDC,\
              0, 0, 72, 98, 16777215
      pop ecx
      inc ebx
  .endw
  ret
paintVidas endp ;fim da proc

isColliding proc obj1Pos:point, obj2Pos:point, obj1Size:point, obj2Size:point  ; proc que verifica colisão 
    push eax
    push ebx

    mov eax, obj1Pos.x
    add eax, obj1Size.x ; eax = obj1Pos.x + obj1Size.x
    mov ebx, obj2Pos.x
    add ebx, obj2Size.x ; ebx = obj2Pos.x + obj2Size.x

    .if obj1Pos.x < ebx && eax > obj2Pos.x
        mov eax, obj1Pos.y
        add eax, obj1Size.y ; eax = obj1Pos.y + obj1Size.y
        mov ebx, obj2Pos.y
        add ebx, obj2Size.y ; ebx = obj2Pos.y + obj2Size.y
        
        .if obj1Pos.y < ebx && eax > obj2Pos.y
            mov edx, TRUE
        .else
            mov edx, FALSE
        .endif
    .else
        mov edx, FALSE
    .endif

    pop ebx
    pop eax

    ret
isColliding endp ;fim da proc

isStopped proc addrFoguete:dword ; detecta se o foguete parou
 assume edx:ptr foguete
     mov edx, addrFoguete

 .if [edx].fogueteObj.speed.x == 0  && [edx].fogueteObj.speed.y == 0
     mov [edx].stopped, 1
 .endif

 ret
isStopped endp ;fim da proc

paintFogueteNave proc _hdc:HDC, _hMemDC:HDC, rotation:DWORD
  ;FOGUETE___________________________________________
  invoke SelectObject, _hMemDC, foguete_spritesheet

  mov eax, rotation
  mov ebx, FOGUETE_SIZE
  mul ebx
  mov ecx, eax

  invoke isStopped, addr fogueteJogador

  .if fogueteJogador.stopped == 1
      mov edx, 0
  .endif

  ;________FOGUETE PAINTING________________________________________________________________________
  mov eax, fogueteJogador.fogueteObj.pos.x
  mov ebx, fogueteJogador.fogueteObj.pos.y
  sub eax, FOGUETE_HALF_SIZE
  sub ebx, FOGUETE_HALF_SIZE

  invoke TransparentBlt, _hdc, eax, ebx,\
      FOGUETE_SIZE, FOGUETE_SIZE, _hMemDC,\
      fogueteJogador.rotation, 0, 200, 200, 16777215


  ;NAVE___________________________________________
  invoke SelectObject, _hMemDC, naveInimiga_bitmap

  movsx eax, naveInimiga.direction
  mov ebx, NAVE_SIZE
  mul ebx
  mov ecx, eax

  ;________NAVE PAINTING________________________________________________________________________
  mov eax, naveInimiga.naveObj.pos.x
  mov ebx, naveInimiga.naveObj.pos.y
  sub eax, NAVE_HALF_SIZE
  sub ebx, NAVE_HALF_SIZE

  invoke TransparentBlt, _hdc, eax, ebx,\
      NAVE_SIZE, NAVE_SIZE, _hMemDC,\
      0, 0, 640, 417, 16777215
  ;________________________________________________________________________________   
   ret
paintFogueteNave endp ;fim da proc

paintBullets proc _hdc:HDC, _hMemDC:HDC ; pinta os tiros na tela

    ;________FOGUETE PAINTING_____________________________________________________________

 .if tiroF.exists == 1 ; SE NÃO EXISTIR (DESAPARECEU) 
     jmp nave_panting
 .else
     .if tiroF.direction == D_TOP_LEFT
         invoke SelectObject, _hMemDC, TF_top_left
     
     .elseif tiroF.direction == D_TOP
         invoke SelectObject, _hMemDC, TF_top

     .elseif tiroF.direction == D_TOP_RIGHT
         invoke SelectObject, _hMemDC, TF_top_right 

     .elseif tiroF.direction == D_RIGHT
         invoke SelectObject, _hMemDC, TF_right 

     .elseif tiroF.direction == D_DOWN_RIGHT
         invoke SelectObject, _hMemDC, TF_down_right 

     .elseif tiroF.direction == D_DOWN
        invoke SelectObject, _hMemDC, TF_down 

     .elseif tiroF.direction == D_DOWN_LEFT
         invoke SelectObject, _hMemDC, TF_down_left 

     .elseif tiroF.direction == D_LEFT ;left is the last possible direction
         invoke SelectObject, _hMemDC, TF_left  
     .endif  
 .endif

 mov eax, tiroF.tiroObj.pos.x
 mov ebx, tiroF.tiroObj.pos.y
 sub eax, TIRO_SIZE
 sub ebx, TIRO_SIZE

 invoke TransparentBlt, _hdc, eax, ebx,\
     TIRO_SIZE, TIRO_SIZE, _hMemDC,\
     0, 0, 70, 66, 16777215


;__NAVE PAINTING_____________________________________________________________
nave_panting: ; pinta a nave na tela
 .if tiroN.exists == 1
     ;invoke SelectObject, _hMemDC2, A2_ground
 .else
     .if tiroN.direction == D_TOP_LEFT
         invoke SelectObject, _hMemDC, TN_top_left
      
     .elseif tiroN.direction == D_TOP
         invoke SelectObject, _hMemDC, TN_top

     .elseif tiroN.direction == D_TOP_RIGHT
         invoke SelectObject, _hMemDC, TN_top_right 

     .elseif tiroN.direction == D_RIGHT
         invoke SelectObject, _hMemDC, TN_right 

     .elseif tiroN.direction == D_DOWN_RIGHT
        invoke SelectObject, _hMemDC, TN_down_right 

     .elseif tiroN.direction == D_DOWN
         invoke SelectObject, _hMemDC, TN_down 

     .elseif tiroN.direction == D_DOWN_LEFT
         invoke SelectObject, _hMemDC, TN_down_left 

     .elseif tiroN.direction == D_LEFT ;left is the last possible direction
         invoke SelectObject, _hMemDC, TN_left  
     .endif  
 .endif

 mov eax, tiroN.tiroObj.pos.x
 mov ebx, tiroN.tiroObj.pos.y
 sub eax, TIRO_SIZE
 sub ebx, TIRO_SIZE

;  invoke TransparentBlt, _hdc, eax, ebx,\
;      TIRO_SIZE, TIRO_SIZE, _hMemDC,\
;      0, 0, 70, 66, 16777215
    
  ret
paintBullets endp ;fim da proc

paintAsteroids proc _hdc:HDC, _hMemDC:HDC ; pinta os asteroides na tela
  invoke SelectObject, _hMemDC, meteoroG

  .if asteroideG1.destroyed == 1 
    mov eax, asteroideG1.asteroideObj.pos.x
    mov ebx, asteroideG1.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
  .elseif asteroideG1.exploded == 1 
    invoke SelectObject, _hMemDC, explosao
    mov eax, asteroideG1.asteroideObj.pos.x
    mov ebx, asteroideG1.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    
    invoke Sleep, 200
    mov asteroideG1.asteroideObj.pos.x, -50
    mov asteroideG1.asteroideObj.pos.y, -50
    invoke TransparentBlt, _hdc, -50, -50,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    mov asteroideG1.exploded, 0
  .endif

  .if asteroideG2.destroyed == 1
    mov eax, asteroideG2.asteroideObj.pos.x
    mov ebx, asteroideG2.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
  .elseif asteroideG2.exploded == 1
    invoke SelectObject, _hMemDC, explosao
    mov eax, asteroideG2.asteroideObj.pos.x
    mov ebx, asteroideG2.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215

    invoke Sleep, 200
    mov asteroideG2.asteroideObj.pos.x, -50
    mov asteroideG2.asteroideObj.pos.y, -50
    invoke TransparentBlt, _hdc, -50, -50,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    mov asteroideG2.exploded, 0
  .endif

  .if asteroideG3.destroyed == 1
    mov eax, asteroideG3.asteroideObj.pos.x
    mov ebx, asteroideG3.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
  .elseif asteroideG3.exploded == 1
    invoke SelectObject, _hMemDC, explosao
    mov eax, asteroideG3.asteroideObj.pos.x
    mov ebx, asteroideG3.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    
    invoke Sleep, 200
    mov asteroideG3.asteroideObj.pos.x, -50
    mov asteroideG3.asteroideObj.pos.y, -50
    invoke TransparentBlt, _hdc, -50, -50,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    mov asteroideG3.exploded, 0
  .endif

  .if asteroideG4.destroyed == 1
    mov eax, asteroideG4.asteroideObj.pos.x
    mov ebx, asteroideG4.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
  .elseif asteroideG4.exploded == 1
    invoke SelectObject, _hMemDC, explosao
    mov eax, asteroideG4.asteroideObj.pos.x
    mov ebx, asteroideG4.asteroideObj.pos.y
    sub eax, ASTEROIDE_HALF_SIZE
    sub ebx, ASTEROIDE_HALF_SIZE

    invoke TransparentBlt, _hdc, eax, ebx,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    
    invoke Sleep, 200
    mov asteroideG4.asteroideObj.pos.x, -50
    mov asteroideG4.asteroideObj.pos.y, -50
    invoke TransparentBlt, _hdc, -50, -50,\
        ASTEROIDE_SIZE, ASTEROIDE_SIZE, _hMemDC,\
        0, 0, 250, 200, 16777215
    mov asteroideG4.exploded, 0
  .endif

  ret
paintAsteroids endp ;fim da proc

updateScreen proc ; atualiza a tela chamando o PAINT
  LOCAL Ps:PAINTSTRUCT
  LOCAL hMemDC:HDC
  LOCAL hBitmap:HDC
  LOCAL hDC:HDC

  invoke BeginPaint, hWnd, ADDR Ps
  mov hDC, eax
  invoke CreateCompatibleDC, hDC
  mov hMemDC, eax

  invoke paintBackground, hDC, hMemDC

  .if GAMESTATE == 1
      invoke paintFogueteNave, hDC, hMemDC, fogueteJogador.rotation
      invoke paintBullets, hDC, hMemDC
      invoke paintVidas, hDC, hMemDC
      invoke paintAsteroids, hDC, hMemDC
  .endif

  invoke DeleteDC, hMemDC
  invoke EndPaint, hWnd, ADDR Ps

  ret
updateScreen endp ;fim da proc

paintThread proc p:DWORD
  .while !acabou
      invoke Sleep, 42 ; 24 FPS

      ;invoke updateScreen

      invoke InvalidateRect, hWnd, NULL, FALSE

  .endw
  ret
paintThread endp ;fim da proc

moveFoguete proc uses eax addrFoguete:dword
  assume ecx:ptr foguete
  mov ecx, addrFoguete

  ; X AXIS ______________
  mov eax, [ecx].fogueteObj.pos.x
  mov ebx, [ecx].fogueteObj.speed.x
  add eax, ebx

  mov [ecx].fogueteObj.pos.x, eax

  ; Y AXIS ______________
  mov eax, [ecx].fogueteObj.pos.y
  mov ebx, [ecx].fogueteObj.speed.y
  add eax, ebx

  mov [ecx].fogueteObj.pos.y, eax

  assume ecx:nothing
  ret
moveFoguete endp ;fim da proc

updateDirection proc addrFoguete:dword  ;atualiza a direção baseado na posição dos eixos x e y
  invoke Sleep, 40
  assume eax:ptr foguete
  mov eax, addrFoguete

  movzx ebx, [eax].right      ; Foguete's x axis 
  movzx edx, [eax].left       ; Foguete's y axis

  .if ebx != FALSE || edx != FALSE
    mov ecx, [eax].rotation
    .if ebx == 0 ; Virou para a direita

      .if ecx == 0 ; Se está para cima
        mov [eax].rotation, 200 ; Vira para nordeste
        mov [eax].direction, D_TOP_RIGHT

      .elseif ecx == 200 ; Se está para nordeste
        mov [eax].rotation, 400 ; Vira para direita
        mov [eax].direction, D_RIGHT

      .elseif ecx == 400 ; Se está para direita
        mov [eax].rotation, 600 ; Vira para sudeste
        mov [eax].direction, D_DOWN_RIGHT

      .elseif ecx == 600 ; Se está para sudeste
        mov [eax].rotation, 800 ; Vira para baixo
        mov [eax].direction, D_DOWN

      .elseif ecx == 800 ; Se está para baixo
        mov [eax].rotation, 1000 ; Virá para sudoeste
        mov [eax].direction, D_DOWN_LEFT

      .elseif ecx == 1000 ; Se está para sudoeste
        mov [eax].rotation, 1200 ; Vira para esquerda
        mov [eax].direction, D_LEFT

      .elseif ecx == 1200 ; Se está para esquerda
        mov [eax].rotation, 1400 ; Vira para noroeste
        mov [eax].direction, D_TOP_LEFT

      .elseif ecx == 1400 ; Se está para noroeste
        mov [eax].rotation, 0 ; Vira para cima
        mov [eax].direction, D_TOP
      .endif
    .elseif edx == 0 ; Virou para a esquerda
    
      .if ecx == 0 ; Se está para cima
        mov [eax].rotation, 1400 ; Vira para noroeste
        mov [eax].direction, D_TOP

      .elseif ecx == 200 ; Se está para nordeste
        mov [eax].rotation, 0 ; Vira para cima
        mov [eax].direction, D_TOP

      .elseif ecx == 400 ; Se está para direita
        mov [eax].rotation, 200 ; Vira para nordeste
        mov [eax].direction, D_TOP_RIGHT

      .elseif ecx == 600 ; Se está para sudeste
        mov [eax].rotation, 400 ; Vira para direita
        mov [eax].direction, D_RIGHT

      .elseif ecx == 800 ; Se está para baixo
        mov [eax].rotation, 600 ; Vira para sudeste
        mov [eax].direction, D_DOWN_RIGHT

      .elseif ecx == 1000 ; Se está para sudoeste
        mov [eax].rotation, 800 ; Vira para baixo
        mov [eax].direction, D_DOWN

      .elseif ecx == 1200 ; Se está para esquerda
        mov [eax].rotation, 1000 ; Virá para sudoeste
        mov [eax].direction, D_DOWN_LEFT

      .elseif ecx == 1400 ; Se está para noroeste
        mov [eax].rotation, 1200 ; Vira para esquerda
        mov [eax].direction, D_LEFT

      .endif
    .endif
  .endif
  ret
updateDirection endp ;fim da proc

moveBullet proc uses eax addrTiro:dword ; atualiza a posição de um GameObj a partir de sua velocidade
    assume eax:ptr tiro
    mov eax, addrTiro

    mov ebx, [eax].tiroObj.speed.x
    mov ecx, [eax].tiroObj.speed.y

    .if [eax].remainingDistance > 0
        .if [eax].direction == D_TOP_LEFT
            add [eax].tiroObj.pos.x, -TIRO_SPEED
            add [eax].tiroObj.pos.y, -TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_TOP
            add [eax].tiroObj.pos.y, -TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_TOP_RIGHT
            add [eax].tiroObj.pos.x,  TIRO_SPEED
            add [eax].tiroObj.pos.y, -TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED
        
        .elseif [eax].direction == D_RIGHT
            add [eax].tiroObj.pos.x,  TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_DOWN_RIGHT
            add [eax].tiroObj.pos.x,  TIRO_SPEED
            add [eax].tiroObj.pos.y,  TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_DOWN
            add [eax].tiroObj.pos.y,  TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_DOWN_LEFT
            add [eax].tiroObj.pos.x, -TIRO_SPEED
            add [eax].tiroObj.pos.y,  TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED

        .elseif [eax].direction == D_LEFT
            add [eax].tiroObj.pos.x,  -TIRO_SPEED
            sub [eax].remainingDistance, TIRO_SPEED
        .endif
    .else
        mov [eax].exists, 1
    .endif
    assume eax:nothing
    ret
moveBullet endp ;fim da proc

randomGeneratorDirection proc ; gera números pseudo-aleatorios a partir de um vetor
  .if counter > 25
    mov counter, 0
  .elseif counter < 25
    mov ecx, counter
    movzx eax, randomArray[ecx]
    sub eax, '0' ; conversão ASCII
    mov asteroideG1.direction, eax
    add counter, 1
    mov ecx, counter
    movzx eax, randomArray[ecx]
    sub eax, '0' ; conversão ASCII
    mov asteroideG2.direction, eax
    add counter, 1
    mov ecx, counter
    movzx eax, randomArray[ecx]
    sub eax, '0' ; conversão ASCII
    mov asteroideG3.direction, eax
    add counter, 1
    mov ecx, counter
    movzx eax, randomArray[ecx]
    sub eax, '0' ; conversão ASCII
    mov asteroideG4.direction, eax
  .endif
  ret
randomGeneratorDirection endp ;fim da proc

moveAsteroids proc ;move os asteroides de acordo com 8 possíveis direções e a velocidade atribuida
  .if asteroidCount == 0
     invoke randomGeneratorDirection
     mov asteroidCount, 4
  .elseif asteroidCount != 0
    ; andar com asteroides na direcao
    .if asteroideG1.direction == 0
    sub asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 1
    sub asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
     .elseif asteroideG1.direction == 2
    add asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 3
    add asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 4
    add asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 5
    add asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 6
    sub asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG1.direction == 7
    sub asteroideG1.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG1.asteroideObj.pos.x, ASTEROIDG_SPEED
    .endif
    .if asteroideG2.direction == 0
    sub asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 1
    sub asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 2
    add asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 3
    add asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 4
    add asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 5
    add asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 6
    sub asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG2.direction == 7
    sub asteroideG2.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG2.asteroideObj.pos.x, ASTEROIDG_SPEED
    .endif
    .if asteroideG3.direction == 0
    sub asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 1
    sub asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 2
    add asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 3
    add asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 4
    add asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 5
    add asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 6
    sub asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG3.direction == 7
    sub asteroideG3.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG3.asteroideObj.pos.x, ASTEROIDG_SPEED
    .endif
    .if asteroideG4.direction == 0
    sub asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 1
    sub asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 2
    add asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 3
    add asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    add asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 4
    add asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 5
    add asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 6
    sub asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .elseif asteroideG4.direction == 7
    sub asteroideG4.asteroideObj.pos.y, ASTEROIDG_SPEED
    sub asteroideG4.asteroideObj.pos.x, ASTEROIDG_SPEED
    .endif
  .endif
  ret
moveAsteroids endp ;fim da proc

changeFogueteSpeed proc uses eax addrFoguete : DWORD ;muda a velocidade do foguete
    assume eax: ptr foguete
    mov eax, addrFoguete

    mov ecx, [eax].rotation
    .if fogueteJogador.move == TRUE ; w
      .if ecx == 0 ; Se está para cima
      mov [eax].fogueteObj.speed.x, 0
        mov [eax].fogueteObj.speed.y, -FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 200 ; Se está para nordeste
        mov [eax].fogueteObj.speed.y, -FOGUETENAVE_SPEED
        mov [eax].fogueteObj.speed.x, FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 400 ; Se está para direita
      mov [eax].fogueteObj.speed.y, 0
        mov [eax].fogueteObj.speed.x, FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 600 ; Se está para sudeste
        mov [eax].fogueteObj.speed.y, FOGUETENAVE_SPEED
        mov [eax].fogueteObj.speed.x, FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 800 ; Se está para baixo
        mov [eax].fogueteObj.speed.x, 0
        mov [eax].fogueteObj.speed.y, FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 1000 ; Se está para sudoeste
        mov [eax].fogueteObj.speed.y, FOGUETENAVE_SPEED
        mov [eax].fogueteObj.speed.x, -FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 1200 ; Se está para esquerda
      mov [eax].fogueteObj.speed.y, 0
        mov [eax].fogueteObj.speed.x, -FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .elseif ecx == 1400 ; Se está para noroeste
        mov [eax].fogueteObj.speed.y, -FOGUETENAVE_SPEED
        mov [eax].fogueteObj.speed.x, -FOGUETENAVE_SPEED
        mov [eax].stopped, 0
      .endif
    .elseif fogueteJogador.move == FALSE
      .if [eax].fogueteObj.speed.y > 7fh
        mov [eax].fogueteObj.speed.y, 0 
      .endif
      .if [eax].fogueteObj.speed.x > 7fh
        mov [eax].fogueteObj.speed.x, 0 
      .endif
      .if [eax].fogueteObj.speed.y < 80h
        mov [eax].fogueteObj.speed.y, 0 
      .endif
      .if [eax].fogueteObj.speed.x < 80h
        mov [eax].fogueteObj.speed.x, 0
      .endif
    .endif

    assume ecx: nothing
    ret
changeFogueteSpeed endp ;fim da proc

fixCoordinates proc addrFoguete:dword
assume eax:ptr foguete
   mov eax, addrFoguete

   .if [eax].fogueteObj.pos.x > WINDOW_SIZE_X && [eax].fogueteObj.pos.x < 80000000h
       mov [eax].fogueteObj.pos.x, 20                   ;sorry
   .endif

   .if [eax].fogueteObj.pos.x <= 0 || [eax].fogueteObj.pos.x > 80000000h
       mov [eax].fogueteObj.pos.x, WINDOW_SIZE_X - 20 
   .endif


   .if [eax].fogueteObj.pos.y > WINDOW_SIZE_Y && [eax].fogueteObj.pos.y < 80000000h
       mov [eax].fogueteObj.pos.y, 20
   .endif

   .if [eax].fogueteObj.pos.y <= 0 || [eax].fogueteObj.pos.y > 80000000h
       mov [eax].fogueteObj.pos.y, WINDOW_SIZE_Y - 80 
   .endif
   ret
fixCoordinates endp ;fim da proc

fixBulletCoordinates proc addrTiro:dword ;verifica se as balas passaram da tela
assume eax:ptr tiro
   mov eax, addrTiro
    
  .if [eax].exists == 0
    .if [eax].tiroObj.pos.x > WINDOW_SIZE_X && [eax].tiroObj.pos.x < 80000000h
        mov [eax].tiroObj.pos.x, 20                  
    .endif

    .if [eax].tiroObj.pos.x <= 10 || [eax].tiroObj.pos.x > 80000000h
        mov [eax].tiroObj.pos.x, 1180 
    .endif


    .if [eax].tiroObj.pos.y > WINDOW_SIZE_Y - 80 && [eax].tiroObj.pos.y < 80000000h
        mov [eax].tiroObj.pos.y, 20
    .endif

    .if [eax].tiroObj.pos.y <= 10 || [eax].tiroObj.pos.y > 80000000h
        mov [eax].tiroObj.pos.y, WINDOW_SIZE_Y - 90 
    .endif
  .endif
  ret
fixBulletCoordinates endp ;fim da proc

fixAsteroidsCoordinates proc ; proc que verifica se os asteroides passaram da tela, e os reposiciona no lado oposto.
  .if asteroideG1.asteroideObj.pos.x > WINDOW_SIZE_X && asteroideG1.asteroideObj.pos.x < 80000000h
    mov asteroideG1.asteroideObj.pos.x, 20                   ;sorry
  .endif
  .if asteroideG1.asteroideObj.pos.x <= 0 ||  asteroideG1.asteroideObj.pos.x > 80000000h
    mov asteroideG1.asteroideObj.pos.x, WINDOW_SIZE_X 
  .endif
  .if asteroideG1.asteroideObj.pos.y > WINDOW_SIZE_Y && asteroideG1.asteroideObj.pos.y < 80000000h
    mov asteroideG1.asteroideObj.pos.y, 20
  .endif
  .if asteroideG1.asteroideObj.pos.y <= 0 || asteroideG1.asteroideObj.pos.y > 80000000h
    mov asteroideG1.asteroideObj.pos.y, WINDOW_SIZE_Y
  .endif

  .if asteroideG2.asteroideObj.pos.x > WINDOW_SIZE_X && asteroideG2.asteroideObj.pos.x < 80000000h
    mov asteroideG2.asteroideObj.pos.x, 20                   ;sorry
  .endif
  .if asteroideG2.asteroideObj.pos.x <= 0 ||  asteroideG2.asteroideObj.pos.x > 80000000h
    mov asteroideG2.asteroideObj.pos.x, WINDOW_SIZE_X 
  .endif
  .if asteroideG2.asteroideObj.pos.y > WINDOW_SIZE_Y && asteroideG2.asteroideObj.pos.y < 80000000h
    mov asteroideG2.asteroideObj.pos.y, 20
  .endif
  .if asteroideG2.asteroideObj.pos.y <= 0 || asteroideG2.asteroideObj.pos.y > 80000000h
    mov asteroideG2.asteroideObj.pos.y, WINDOW_SIZE_Y
  .endif

  .if asteroideG3.asteroideObj.pos.x > WINDOW_SIZE_X && asteroideG3.asteroideObj.pos.x < 80000000h
    mov asteroideG3.asteroideObj.pos.x, 20                   ;sorry
  .endif
  .if asteroideG3.asteroideObj.pos.x <= 0 ||  asteroideG3.asteroideObj.pos.x > 80000000h
    mov asteroideG3.asteroideObj.pos.x, WINDOW_SIZE_X 
  .endif
  .if asteroideG3.asteroideObj.pos.y > WINDOW_SIZE_Y && asteroideG3.asteroideObj.pos.y < 80000000h
    mov asteroideG3.asteroideObj.pos.y, 20
  .endif
  .if asteroideG3.asteroideObj.pos.y <= 0 || asteroideG3.asteroideObj.pos.y > 80000000h
    mov asteroideG3.asteroideObj.pos.y, WINDOW_SIZE_Y
  .endif

  .if asteroideG4.asteroideObj.pos.x > WINDOW_SIZE_X && asteroideG4.asteroideObj.pos.x < 80000000h
    mov asteroideG4.asteroideObj.pos.x, 20                   ;sorry
  .endif
  .if asteroideG4.asteroideObj.pos.x <= 0 ||  asteroideG4.asteroideObj.pos.x > 80000000h
    mov asteroideG4.asteroideObj.pos.x, WINDOW_SIZE_X 
  .endif
  .if asteroideG4.asteroideObj.pos.y > WINDOW_SIZE_Y && asteroideG4.asteroideObj.pos.y < 80000000h
    mov asteroideG4.asteroideObj.pos.y, 20
  .endif
  .if asteroideG4.asteroideObj.pos.y <= 0 || asteroideG4.asteroideObj.pos.y > 80000000h
    mov asteroideG4.asteroideObj.pos.y, WINDOW_SIZE_Y
  .endif

  ret
fixAsteroidsCoordinates endp ;fim da proc

gameOver proc
  mov fogueteJogador.fogueteObj.pos.x, 375
  mov fogueteJogador.fogueteObj.pos.y, 175
  mov naveInimiga.naveObj.pos.x, -100
  mov naveInimiga.naveObj.pos.y, -100

  mov fogueteJogador.fogueteObj.speed.x, 0
  mov fogueteJogador.fogueteObj.speed.y, 0

  mov fogueteJogador.stopped, 0

  mov fogueteJogador.life, 5

  mov tiroF.exists, 1
  mov tiroF.remainingDistance, 0
  mov tiroF.tiroObj.speed.x, 0
  mov tiroF.tiroObj.speed.y, 0
  mov tiroF.tiroObj.pos.x, -100
  mov tiroF.tiroObj.pos.y, -100

  mov tiroN.exists, 1
  mov tiroN.remainingDistance, 0
  mov tiroN.tiroObj.speed.x, 0
  mov tiroN.tiroObj.speed.y, 0
  mov tiroN.tiroObj.pos.x, -100
  mov tiroN.tiroObj.pos.y, -100

  mov asteroideG1.asteroideObj.pos.x, 0
  mov asteroideG1.asteroideObj.pos.y, 0
  mov asteroideG2.asteroideObj.pos.x, 280
  mov asteroideG2.asteroideObj.pos.y, 0
  mov asteroideG3.asteroideObj.pos.x, 440
  mov asteroideG3.asteroideObj.pos.y, 340
  mov asteroideG4.asteroideObj.pos.x, 715
  mov asteroideG4.asteroideObj.pos.y, 140

  ret
gameOver endp ;fim da proc

asteroideFogueteColisao proc uses eax addrAsteroide : DWORD 
  assume eax: ptr asteroideG
  mov eax, addrAsteroide

  invoke isColliding, fogueteJogador.fogueteObj.pos, [eax].asteroideObj.pos, FOGUETE_SIZE_POINT, ASTEROIDE_SIZE_POINT
  .if edx == TRUE
    mov fogueteJogador.fogueteObj.pos.x, 375
    mov fogueteJogador.fogueteObj.pos.y, 175
    dec fogueteJogador.life

    ; Som da explosão do Foguete
    mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
    mov   open_lpstrElementName,OFFSET explosao_foguete
    invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
    cmp   edx,0h                 	
    je    next		
    next:	
        invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback
  .endif

  ret
asteroideFogueteColisao endp

asteroideBalaColisao proc uses eax addrAsteroide : DWORD 
  assume eax: ptr asteroideG
  mov eax, addrAsteroide

  invoke isColliding, tiroF.tiroObj.pos, [eax].asteroideObj.pos, TIRO_SIZE_POINT, ASTEROIDE_SIZE_POINT
  .if edx == TRUE
    mov [eax].destroyed, 0
    mov tiroF.remainingDistance, 0
    add fogueteJogador.points, 100

    ; Som da explosão do asteroide
    mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
    mov   open_lpstrElementName,OFFSET explosao_asteroide
    invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
    cmp   edx,0h                 	
    je    next		
    next:	
        invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback
  .endif

  ret
asteroideBalaColisao endp

gameManager proc p:dword
  LOCAL area:RECT

  game:
  .while GAMESTATE == 1
    invoke Sleep, 30

    invoke asteroideFogueteColisao, addr asteroideG1
    invoke asteroideFogueteColisao, addr asteroideG2
    invoke asteroideFogueteColisao, addr asteroideG3
    invoke asteroideFogueteColisao, addr asteroideG4

    invoke asteroideBalaColisao, addr asteroideG1
    invoke asteroideBalaColisao, addr asteroideG2
    invoke asteroideBalaColisao, addr asteroideG3
    invoke asteroideBalaColisao, addr asteroideG4
    ; invoke isColliding, player1.playerObj.pos, arrow2.arrowObj.pos, PLAYER_SIZE_POINT, ARROW_SIZE_POINT
    ; .if edx == TRUE
    ;     mov player1.playerObj.pos.x, 100
    ;     mov player1.playerObj.pos.y, 350
    ;     dec player1.life
    ;     .if player1.life == 0
    ;         invoke gameOver
    ;         mov GAMESTATE, 4 ; player 2 won
    ;         .continue
    ;     .endif
    ; .endif

    ; invoke isColliding, player2.playerObj.pos, arrow2.arrowObj.pos, PLAYER_SIZE_POINT, ARROW_SIZE_POINT
    ; .if edx == TRUE
    ;     .if arrow2.onGround == 1
    ;         ;mov arrow1.onGround, 0               ; pick up arrow from the ground
    ;         mov arrow2.arrowObj.pos.x, -100
    ;         mov arrow2.arrowObj.pos.y, -100
    ;         mov arrow2.playerOwns, 1
    ;     .endif
    ; .endif

    ; .if arrow1.remainingDistance > 0
    ;     invoke moveArrow, addr arrow1
    ; .else
    ;     mov arrow1.onGround, 1
    ; .endif

    ; .if arrow2.remainingDistance > 0
    ;     invoke moveArrow, addr arrow2
    ; .else
    ;     mov arrow2.onGround, 1
    ; .endif
    
    invoke changeFogueteSpeed, ADDR fogueteJogador
    invoke updateDirection, addr fogueteJogador
    invoke moveFoguete, addr fogueteJogador     

    invoke moveBullet, addr tiroF 
    invoke moveAsteroids
    
    invoke fixBulletCoordinates, addr tiroF
    invoke fixCoordinates, addr fogueteJogador
    invoke fixAsteroidsCoordinates
    
    .if fogueteJogador.life == 0
      invoke gameOver
      mov GAMESTATE, 2
      ; Som de game over
      mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
      mov   open_lpstrElementName,OFFSET game_over
      invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
      cmp   edx,0h                 	
      je    next		
      next:	
          invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback
      .break
    .endif

    .if asteroideG1.destroyed == 0 && asteroideG2.destroyed == 0 && asteroideG3.destroyed == 0 && asteroideG4.destroyed == 0
      mov asteroideG1.destroyed, 1
      mov asteroideG2.destroyed, 1
      mov asteroideG3.destroyed, 1
      mov asteroideG4.destroyed, 1
    .endif
  .endw

  .while GAMESTATE == 2
    invoke Sleep, 30
  .endw

  jmp game
  ret
gameManager endp ;fim da proc

; Invoca-se os bitmaps
loadImages proc
  ; Backgrounds
  invoke LoadBitmap, hInstance, 130
  mov    h_inicio, eax
  invoke LoadBitmap, hInstance, 131
  mov h_universo, eax
  invoke LoadBitmap, hInstance, 132
  mov h_gameover, eax
  ; Elementos do jogo
  invoke LoadBitmap, hInstance, 150
  mov explosao, eax
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
  invoke LoadBitmap, hInstance, 100
  mov TF_top_left, eax
  invoke LoadBitmap, hInstance, 101
  mov TF_top, eax
  invoke LoadBitmap, hInstance, 102
  mov TF_top_right, eax
  invoke LoadBitmap, hInstance, 103
  mov TF_right, eax
  invoke LoadBitmap, hInstance, 100
  mov TF_down_right, eax
  invoke LoadBitmap, hInstance, 101
  mov TF_down, eax
  invoke LoadBitmap, hInstance, 102
  mov TF_down_left, eax
  invoke LoadBitmap, hInstance, 103
  mov TF_left, eax
  ; Tiros da Nave
  invoke LoadBitmap, hInstance, 104
  mov TN_top_left, eax
  invoke LoadBitmap, hInstance, 105
  mov TN_top, eax
  invoke LoadBitmap, hInstance, 106
  mov TN_top_right, eax
  invoke LoadBitmap, hInstance, 107
  mov TN_right, eax
  invoke LoadBitmap, hInstance, 104
  mov TN_down_right, eax
  invoke LoadBitmap, hInstance, 105
  mov TN_down, eax
  invoke LoadBitmap, hInstance, 106
  mov TN_down_left, eax
  invoke LoadBitmap, hInstance, 107
  mov TN_left, eax
  ret
loadImages endp ;fim da proc      
WinMain proc hInst :DWORD, hPrevInst :DWORD, CmdLine :DWORD, CmdShow :DWORD
  LOCAL clientRect:RECT

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
  
  invoke RegisterClassEx, addr wc ; register our window class 

  mov clientRect.left, 0
  mov clientRect.top, 0
  mov clientRect.right, WINDOW_SIZE_X
  mov clientRect.bottom, WINDOW_SIZE_Y

  invoke AdjustWindowRect, addr clientRect, WS_CAPTION, FALSE

  mov eax, clientRect.right
  sub eax, clientRect.left
  mov ebx, clientRect.bottom
  sub ebx, clientRect.top

  invoke CreateWindowEx, NULL, addr szClassName, NULL,\ 
        WS_OVERLAPPED or WS_SYSMENU or WS_MINIMIZEBOX,\ 
        CW_USEDEFAULT, CW_USEDEFAULT,\
        eax, ebx, NULL, NULL, hInst, NULL 

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
WinMain endp ;fim da proc

WndProc proc hWin   :DWORD, uMsg   :DWORD, wParam :DWORD, lParam :DWORD, oldParam :DWORD
  LOCAL direction : BYTE
  LOCAL move      : BYTE
  LOCAL teleport  : BYTE
  LOCAL keydown   : BYTE
  LOCAL left   : BYTE
  LOCAL right   : BYTE
  mov direction, -1
  mov keydown, -1
  mov move, -1
  mov teleport, -1
  mov left, -1
  mov right, -1

  .IF uMsg == WM_CREATE
    invoke loadImages

    ; Música
    mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
    mov   open_lpstrElementName,OFFSET musica
    invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
    cmp   eax,0h                 	
    je    next		
    next:	
        invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback

    mov eax, offset gameManager 
    invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1ID 
    invoke CloseHandle, eax 

    mov eax, offset paintThread
    invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2ID
    invoke CloseHandle, eax

  .elseif uMsg == WM_CLOSE
    szText TheText,"Confirme a saida"
    invoke MessageBox,hWin,ADDR TheText,ADDR szDisplayName,MB_YESNO
      .if eax == IDNO
        return 0
      .endif

  .elseif uMsg == WM_DESTROY
    invoke PostQuitMessage,NULL
    return 0 

.elseif uMsg == WM_PAINT
  invoke updateScreen

.elseif uMsg == WM_CHAR
  .if wParam == VK_SPACE
    .if (GAMESTATE == 0 || GAMESTATE == 2)
      mov GAMESTATE, 1
      mov fogueteJogador.points, 0
    .elseif (GAMESTATE == 1)
      mov tiroF.exists, 0
      mov tiroF.remainingDistance, 400 
      
      mov ah, fogueteJogador.direction
      mov tiroF.direction, ah
      
      mov eax, fogueteJogador.fogueteObj.pos.x
      mov tiroF.tiroObj.pos.x, eax

      mov eax, fogueteJogador.fogueteObj.pos.y
      mov tiroF.tiroObj.pos.y, eax  

      ; Som do tiro
      mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
      mov   open_lpstrElementName,OFFSET shoot
      invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
      cmp   edx,0h                 	
      je    next2
      next2:	
        invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback
    .endif
  .endif

.ELSEIF uMsg == WM_KEYUP
  .if (wParam == 77h || wParam == 57h) ;w
    mov keydown, FALSE
    ;mov direction, 1
    mov fogueteJogador.move, FALSE

  .elseif (wParam == 61h || wParam == 41h) ;a
    mov keydown, FALSE
    ;mov direction, 2
    mov fogueteJogador.left, 1

  .elseif (wParam == 73h || wParam == 53h) ;s
    mov keydown, FALSE
    ;mov direction, 3
    mov teleport, FALSE

  .elseif (wParam == 64h || wParam == 44h) ;d
    mov keydown, FALSE
    ;mov direction, 0
    mov fogueteJogador.right, 1

  .endif

  ;.if direction != -1
    ; invoke changeFogueteSpeed, ADDR fogueteJogador, direction, keydown, move
    ; mov direction, -1
    ; mov keydown, -1
    ; mov move, -1
    ; mov teleport, -1
  ;.endif        
;________________________________________________________________________________

.ELSEIF uMsg == WM_KEYDOWN
  .if (wParam == 77h || wParam == 57h) ; w
      mov keydown, TRUE
      ;mov direction, 1
      mov fogueteJogador.move, TRUE
      

  .elseif (wParam == 73h || wParam == 53h) ; s
      mov keydown, TRUE
      mov teleport, TRUE
      ;mov direction, 3

  .elseif (wParam == 61h || wParam == 41h) ; a
      mov keydown, TRUE
      ;mov direction, 2
      mov fogueteJogador.left, 0

  .elseif (wParam == 64h || wParam == 44h) ; d
      mov keydown, TRUE
      ;mov direction, 0
      mov fogueteJogador.right, 0
  .endif
        
.elseif uMsg == WM_FINISH

.endif
invoke DefWindowProc,hWin,uMsg,wParam,lParam
ret

WndProc endp ;fim da proc

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1    
    shr wDim, 1   
    mov eax, wDim  
    sub sDim, eax   

    return sDim

TopXY endp ;fim da proc

end start
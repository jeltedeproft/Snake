; ==============================================================================
; Programeerproject
; ==============================================================================
.MODEL small ; one data and one code segment, stack and data segment are grouped
.STACK 1024  ; stack, 1024 bytes

VIDEO_PALLETE_PORT = 3C8h
COLOR_SELECTION_PORT = 3C9h
COLOR_INDEX = 2
PALLETE_INDEX_BACKGROUND = 0
SET_VIDEO_MODE = 0
GET_VIDEO_MODE = 0Fh
VIDE0_SEGMENT = 0A000h
WAIT_FOR_KEYSTROKE = 10h
VIDEO_MODE_13 = 13h


; ----------------------------- DATA STARTS HERE -------------------------------
.DATA        ; data segment, static variables

LengteSlang DW 0001h
PositieSlang DW 100 dup (0000h)
positieHoofd DW 0000h
PositieBolletje DW 000ah
nieuwePositieSlang DW 0001h
snelheid DW 0001h
wideness   DW  0064h
height  DW  0064h
richtingsconstante DW  0001h
aantal_clock_ticks DD 00000000h
aantal_clock_ticks_2 DD 00000000h
savemode DB 01h
oudepositiebolletje DW 0100h
oude_achter DW 0010h




; ----------------------------- CODE STARTS HERE -------------------------------
.CODE        ; code segment
main PROC NEAR

        mov  ax, @data
        mov  ds, ax

        push dx
        push ax
        call SetVideoMode
        pop  dx
        pop  ax

        push ax
        push bx
        push cx
        push dx
        push di
        call drawscreen
        pop di
        pop dx
        pop cx
        pop bx
        pop ax

   beginwhileloop:
 
        push si       
        push bx
        push cx
        push di
        push ax
        mov  ax, ds:[lengteslang]
        push ax
        mov  ax, ds:[nieuwePositieSlang]
        push ax
        lea  ax, ds:[Positieslang]
        push ax
        call test_botsing
        cmp al, 0            ;in al zit een 1 als er een botsing is en een 0 indien niet                              
        jne endwhile
        pop  ax
        pop  di
        pop  cx
        pop  bx
        pop  si

  
   teken:
        push cx
        push di
        push ax
        push bx
        push si
        push dx
        lea  ax,  [positieslang]
        push ax
        mov  ax,  [lengteslang]
        push ax
        call Draw_snake
        pop  dx
        pop  si
        pop  bx
        pop  ax
        pop  di
        pop  cx

        push cx
        push si
        push ax
        push bx
        push di
        push dx
        mov  ax,  [positiebolletje]
        push ax
        lea  ax,  [positieslang]
        push ax
        mov  ax,  [lengteslang]
        push ax
        call Draw_bolletje
        pop  dx
        pop  di
        pop  bx
        pop  ax
        pop  si
        pop  cx

        push ax  ; slaag waarde ax op
        push di

   test_toets_ingedrukt:
        mov ah, 01h               ; function 01h (test key pressed)
        int 16h                   ; call keyboard BIOS
        jz update_zonder_toets    ; jump to some label if no key was pressed
        mov ah, 00h               ; function 00h (get key from buffer)
        int 16h
        cmp al, 115                     ;welke key is ingedrukt?, s,d,e, of f
        je update_richting_left
        cmp al, 102
        je update_richting_right
        cmp al, 100
        je update_richting_down
        cmp al, 101
        je update_richting_up

    update_richting_left:
        cmp richtingsconstante, 1
        je update_positie
        mov richtingsconstante, -1
        jmp update_positie

    update_richting_right:
        cmp richtingsconstante,-1
        je update_positie
        mov richtingsconstante, 1
        jmp update_positie
         
    update_richting_down:
        cmp richtingsconstante,-320
        je update_positie
        mov richtingsconstante, 320
        jmp update_positie

    update_richting_up:
        cmp richtingsconstante,320
        je update_positie
        mov richtingsconstante, -320
        jmp update_positie

   update_zonder_toets:
        mov ax,  nieuwepositieslang
        add ax,  richtingsconstante
        mov nieuwepositieslang,  ax

        pop  ax      ;zet ax terug op originele waarde
        pop  di        


   update_positie:
        


        push di
        push dx
        push cx
        push bx
        push ax
        lea  ax,  [positieslang]
        push ax
        mov  ax,  [lengteslang]
        push ax
        mov  ax,  [nieuwepositieslang]
        push ax
        call update_de_slang
        pop  ax
        pop  bx
        pop  cx
        pop  dx
        pop  di
       
        


   test_bolletje:
 
        push ax
        push di
        mov  ax,  positiebolletje
        mov  di, OFFSET positieslang
        cmp  ax, [di]
        jne  wait_while

        pop  ax      ;zet ax terug op originele waarde
        pop  di

        push dx
        push cx
        push si
        push di
        push bx
        push ax
        lea  ax,   [positieslang]
        push ax
        mov  ax,   [lengteslang]
        push ax
        mov  ax,   [nieuwepositieslang]
        push ax
        call maak_slang_langer
        pop  ax
        pop  bx
        pop  di
        pop  si
        pop  cx
        pop  dx
        add  [lengteslang], 1


        push ax
        push bx
        push dx
        call creeer_nieuw_bolletje
        mov  positiebolletje,   ax
        pop  dx
        pop  bx
        pop  ax
        jmp beginwhileloop


    wait_while:
        pop  ax  ; zet ax terug op originele waarde
        pop  di

        push ax
        push bp
        push cx
        push dx
        call wait_time
        pop  dx
        pop  cx
        pop  bp
        pop  ax


        jmp beginwhileloop

    
main endp



;---------------------------------------------------------------------------------
;deze procedure test op een botsing met zichzelf.
;
;ontvangt : de positie van het hoofd, de lengte van de slang en de positie van het lichaam op de stack.
;geeft terug: zet een 1 in al indien er een botsing is en een 0 indien niet.
;
;deze procedure wijzigt  ax,bx,cx, en di
;                                   
;---------------------------------------------------------------------------------
test_botsing PROC
        push  bp
        mov   bp,  sp
        mov   si,     0
        mov   bx,     ss:[bp + 4] ;positieslang
        mov   di,     ss:[bp + 8] ;lengteslang
        mov   cx,di
        pop   bp

        cmp   di,1
        je    geen_botsing
        
        mov   ax, di
        add   di, ax
        sub   di,2

        mov   ax,  ds:[bx + di]
          

testbotsing:   
        cmp   [bx + si],   ax
        je    botsing 
        add   si,     2
        cmp   si,     di
        je    geen_botsing
        jmp   testbotsing
        

    botsing:
        mov al, 1
        ret 6

    geen_botsing:
        mov al, 0
        ret 6
test_botsing ENDP








;----------------------------------------------------------------------------------
;deze procedure "eet" het bolletje op en verlengt de slang.
;
;
;ontvangt : array met alle elementen van de slang
;           lengte van de slang beiden op de stack
;geeft terug : /
;----------------------------------------------------------------------------------
maak_slang_langer PROC
        push  bp
        mov   bp,  sp 
        mov   bx,     ss:[bp + 8];positie
        mov   di,     ss:[bp + 6];lengte
        pop   bp

        mov   cx, di
        add   di, cx
        mov   ax,     ds:[bx + di - 2]; start van de array + de lengte  - 2 want de lengte start van 1 en de positie start van 0
        add   ax,     richtingsconstante
       
        mov  si,320
        xor  dx,dx
        div  si

        cmp  dx,100
        je  loop_rechts_over3
        cmp  dx,319
        je   loop_links_over3
        jmp  test3

 loop_rechts_over3:
      mov  ax,    ds:[bx + di - 2]
      sub  ax,100
      mov  ds:[bx + di], ax
      jmp finish3

 loop_links_over3:
      mov  ax,    ds:[bx + di - 2]
      add  ax,100
      mov  ds:[bx + di], ax
      jmp finish3

test3:
        mov  ax,   ds:[bx + di - 2]
        add  ax,   richtingsconstante

        cmp  ax,32000
        jg   loop_onder_over3

        cmp  ax,0
        jl   loop_boven_over3
        jmp einde_test3

 loop_onder_over3:
      mov  ax,    ds:[bx + di - 2]
      sub  ax,32000
      mov  ds:[bx + di], ax
      jmp finish3

 loop_boven_over3:
      mov  ax,    ds:[bx + di - 2]
      add  ax,32000
      mov  [bx + di], ax
      jmp finish3
      
      
einde_test3:
        mov  ax,    ds:[bx + di - 2]
        add  ax, richtingsconstante
        mov  ds:[bx + di], ax
finish3: 
        ret 6
maak_slang_langer ENDP



;---------------------
;
;---------------------
;- positieslang      -    bp + 8
;---------------------
;- lengteslang       -    bp + 6
;---------------------
;- nieuwepositieslang-    bp + 4
;---------------------
;- return address    -    bp + 2
;---------------------
;- bp                -  <---- stack pointer
;---------------------
;-                   -
;---------------------    voorbeeld stack
;-                   -
;---------------------
       
         






;----------------------------------------------------------------------------------
;deze procedure creeert een nieuw willekeurig bolletje, dat zich niet op dezelfde plaats als de slang bevind
;deze zelfgemaakte procedure maakt gebruik van het aantal clock ticks sinds middernacht,
;deelt dit getal door het totaal aantal pixels en slaagt de rest op in ax.
;ontvangt : 
;geeft terug : positie nieuw bolletje in ax
;
;
;----------------------------------------------------------------------------------
creeer_nieuw_bolletje PROC
        mov   ah, 00h   ;get system time
        int   1ah       ;cx:dx holds number of clock ticks since midnight

        mov   ax,dx     ;we nemen de onderste 16 bits van de clock ticks (tussen 0-65535)
        xor   dx,dx     ;maak dx leeg
        xor   cx,cx     ;maak cx leeg   
        mov   bx,100    ;dit getal zorgt voor max 100
        div   bx        ;in ax zit nu de lengte
        mov   bx,dx     ;nu zit in bx de lengte

        mov   ah, 00h   ;get system time
        int   1ah       ;cx:dx holds number of clock ticks since midnight

        mov   ax,dx
        add   ax,50
        xor   dx,dx
        xor   cx,cx
        mov   cx,100
        div   cx        ;dx bevat nu getal tussen 0-100
        mov   ax,dx     ;ax bevat getal 0-100
        mov   cx,320
        mul   cx
        add   ax,bx
        
        ret
creeer_nieuw_bolletje ENDP



;----------------------------------------------------------------------------------
;deze procedure update de positie van de slang
;
;ontvangt : array alle elementen slang
;           richting
;geeft terug : /
;
;----------------------------------------------------------------------------------
update_de_slang PROC
      push  bp
      mov   bp,  sp    
      mov   cx,  ss:[bp + 6]   ;lengteslang
      mov   bx,  ss:[bp + 8]   ;positieslang  
      mov   di,  2
      pop   bp

      mov ax, [bx]
      mov si, OFFSET oude_achter
      mov [si], ax
      
    
      cmp    cx,  1
      jne    loop_slang

 loop_slang_1:
      mov  ax,   [bx]
      add  ax,   richtingsconstante
      mov  si,320
      xor  dx,dx
      div  si

      cmp  dx,100
      je   loop_rechts_over
      cmp  dx,319
      je   loop_links_over
      jmp  test2

 loop_rechts_over:
      mov  ax,    [bx]
      sub  ax,100
      mov  [bx], ax
      jmp finish2

 loop_links_over:
      mov  ax,    [bx]
      add  ax,100
      mov  [bx], ax
      jmp finish2

test2:
      mov  ax,   [bx]
      add  ax,   richtingsconstante

      cmp  ax,32000
      jg   loop_onder_over

      cmp  ax,0
      jl   loop_boven_over
      jmp einde_test

 loop_onder_over:
      mov  ax,    [bx]
      sub  ax,32000
      mov  [bx], ax
      jmp finish2

 loop_boven_over:
      mov  ax,    [bx]
      add  ax,32000
      mov  [bx], ax
      jmp finish2
      
      
einde_test:
      mov  ax,    [bx]
      add  ax, richtingsconstante
      mov  [bx], ax
      jmp  finish2

 loop_slang:
      mov  ax,  [bx + di]
      mov  [bx + di - 2],  ax ; zet positie 2 op positie 1
      add   di,  2
      xor dx,dx
      mov ax,  di
      mov si,2
      div si
      cmp ax, cx
      ja  finish
      jmp loop_slang

 finish:
      sub  di,  6             ;zet di terug op de positie van het voorlaatste element in de slang
      mov  ax,  [bx + di]     ;zet voorlaatste elemnt in ax
      mov [bx + di + 2], ax   ;kopieer ax in laatste positie
      add ax, richtingsconstante ; tel er constante bij op
      mov  si,320
      xor  dx,dx
      div  si

      cmp  dx,100
      je  loop_rechts_over2
      cmp  dx,319
      je   loop_links_over2
      jmp  test_2

 loop_rechts_over2:
      mov  ax,    [bx + di]
      sub  ax,100
      mov  [bx + di + 2], ax
      jmp finish1

 loop_links_over2:
      mov  ax,    [bx + di]
      add  ax,100
      mov  [bx + di + 2], ax
      jmp finish1

test_2:
      mov  ax,   [bx + di]
      add  ax,   richtingsconstante

      cmp  ax,32000
      jg   loop_onder_over2

      cmp  ax,0
      jl   loop_boven_over2
      jmp einde_test2

 loop_onder_over2:
      mov  ax,    [bx + di]
      sub  ax,32000
      mov  [bx + di + 2], ax
      jmp finish1

 loop_boven_over2:
      mov  ax,    [bx + di]
      add  ax,32000
      mov  [bx + di + 2], ax
      jmp finish1
      
      
einde_test2:
      mov  ax,    [bx + di]
      add  ax, richtingsconstante
      mov  [bx + di + 2], ax
      jmp  finish2
      
      ret 6
 finish1:
      
      ret 6

 finish2:
      ret 6

update_de_slang ENDP
        





;----------------------------------------------------------------------------------
;deze procedure zet de videomodus, in dit geval op 13
;
;houd de vorig modus bij en zet de nieuwe
;           
;
;
;-----------------------------------------------------------------------------------
setvideomode PROC
       mov dx, 0a000h ;video segment adres
       mov ah,GET_VIDEO_MODE
       int 10h
       mov saveMode,al ; save it
       mov ah,SET_VIDEO_MODE
       mov al,VIDEO_MODE_13 ; to mode 13h
       int 10h
       push dx ; video segment address
       pop es ; ES points to video segment
       ret
setvideomode ENDP

;---------------------------------------------
RestoreVideoMode PROC
;
; zet oude video modus terug
; 
;----------------------------------------------
      mov ah,WAIT_FOR_KEYSTROKE
      int 16h
      mov ah,SET_VIDEO_MODE ; reset video mode
      mov al,saveMode ; to saved mode
      int 10h
      ret
      RestoreVideoMode ENDP

;--------------------------------------------
;deze procedure tekent snake
;
;
;ontvangt positie snake
;
;
;---------------------------------------------
draw_snake PROC
      ;verander de kleur op index 2 naar groen (0,63,0).

      push  bp
      mov   bp,  sp 
      mov   bx,  ss:[bp + 6]  ;positieslang
      mov   si,  ss:[bp + 4]  ;lengteslang
      pop   bp
      
      
      mov dx,VIDEO_PALLETE_PORT
      mov al,2 ; zet palette index 2
      out dx,al
      mov dx,COLOR_SELECTION_PORT
      mov al,0 ; red
      out dx,al
      mov al,63 ; green
      out dx,al
      mov al,0 ; blue
      out dx,al

      mov ax, si
      mov cx, 2
      mul cx
      mov si, ax
      sub si,   2 ; lengteslang als index

  teken_snake:
      mov di,  [bx + si]
      mov BYTE PTR es:[di],2
      cmp si, 0
      jne  extra_loop
      
      mov dx,VIDEO_PALLETE_PORT        ;zet de kleur gelijk aan de achtergrond kleur
      mov al,3 ; zet palette index 3
      out dx,al
      mov dx,COLOR_SELECTION_PORT
      mov al,0 ; red
      out dx,al
      mov al,0 ; green
      out dx,al
      mov al,0 ; blue
      out dx,al

      mov si, OFFSET oude_achter
      mov di, [si]                  ;zet de positie die weg is terug op de achtergrond kleur
      mov BYTE PTR es:[di],0

      ret 4

  extra_loop:
      sub si,2      ;1 element verder in de lijst van posities
      jmp teken_snake
      
draw_snake ENDP



;----------------------------------------------
;deze procedure tekent het bolletje
;
;
;
;
;
;
;----------------------------------------------
draw_bolletje PROC
     ;verander de kleur op index 3 naar rood (63,0,0).


      push  bp
      mov   bp,  sp       
      mov   bx, ss:[bp + 8] ; haal positiebolletje van de stack
      mov   cx, ss:[bp + 6] ;positieslang
      mov   ax, ss:[bp + 4] ;lengteslang
      pop   bp

      
      mov si, OFFSET oudepositiebolletje
      mov di, [si]
      mov si, 2
      mul si
      xor dx,dx
      mov si,ax
      push bp

  kijk_bolletje_in_slang:
     
      
      mov bp, cx     
      cmp di, ds:[bp + si - 2]
      je  plaats_nieuw_bolletje
      sub si, 2
      cmp si, 0
      jne kijk_bolletje_in_slang
      
      
      mov dx,VIDEO_PALLETE_PORT           ;zet kleur op achtergrond kleur
      mov al,4 ; zet palette index 4
      out dx,al
      mov dx,COLOR_SELECTION_PORT
      mov al,0 ; red
      out dx,al
      mov al,0 ; green
      out dx,al
      mov al,0 ; blue
      out dx,al

      mov si, OFFSET oudepositiebolletje
      mov di, [si]

      mov BYTE PTR eS:[di],0
            
      
plaats_nieuw_bolletje:
      pop bp      
      mov dx,VIDEO_PALLETE_PORT      ;zet de correcte kleur
      mov al,5 ; zet palette index 5
      out dx,al
      mov dx,COLOR_SELECTION_PORT
      mov al,0 ; red
      out dx,al
      mov al,0 ; green
      out dx,al
      mov al,63 ; blue
      out dx,al

      mov BYTE PTR es:[bx],2 ; kleur positiebolletje 
      mov si, OFFSET oudepositiebolletje                    ; we moeten de positie bijhouden in een 2e variabele om hem nadien te kunne zwartmaken
      mov [si], bx
      ret 6
draw_bolletje ENDP



;-----------------------------------------------------------------------------------
;deze procedure creeert een wachtmoment om de snelheid van snake te controleren
;
;
;ontvangt : snelheid
;geeft terug : niets
;
;
;-----------------------------------------------------------------------------------
wait_time PROC

      MOV AH, 00h  ; interrupts to get system time        
      INT 1AH      ; CX:DX now hold number of clock ticks since midnight

      mov  bp,       OFFSET aantal_clock_ticks  ; we zetten onze eerste tijd (t0) in een 32-bit variabele in het geheugen
      mov  ds:[bp],     cx
      mov  ds:[bp + 2], dx
      
  tijdsloop:
      mov ah, 00h
      int 1ah
      mov bp, OFFSET aantal_clock_ticks_2 ; we zetten onze tweede tijd en de daaropvolgende in een 2e  variabele en vergelijken met de eerste
      mov ds:[bp],     cx
      mov ds:[bp + 2], dx
      mov ax, WORD PTR [aantal_clock_ticks_2 + 2]
      sub ax, WORD PTR [aantal_clock_ticks + 2]
      cmp ax, 2        ;als het verschil tussen de eerste clock tiks en de x'e clock tick groter is dan 18, is er 1 seconde gepaseerd +-
      jg  stop_loop
      jmp tijdsloop
   stop_loop:
      ret
wait_time ENDP

;-----------------------------------------------------------------------------------
;deze procedure tekent het sherm
;
;
;ontvangt : /
;geeft terug : /
;
;
;-----------------------------------------------------------------------------------
drawscreen PROC
     mov  bx,32320
     mov  cx,101
     mov  di,0

drawbotline:
     mov BYTE PTR es:[bx + di],2
     add  di,1
     loop drawbotline

     mov cx,101

drawrightline:
     mov BYTE PTR es:[bx + di],2
     sub  bx,320
     loop drawrightline

     ret
     
drawscreen ENDP


   endwhile:
     push ax
     call RestoreVideoMode  
     pop  ax 


END main










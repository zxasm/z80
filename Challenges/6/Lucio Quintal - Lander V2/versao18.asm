
; +---+---+---+---+---+---+---+

; V2 now includes Score bar and pseudo-random restart position for the rocket.

; Z80 Assembly Programming On The ZX Spectrum - COMPO #6 - 256 byte game compo
; a Lander game in 256 bytes of machine code, including DATA.
; (C) by Lúcio Quintal (Islander LQ), 30-May-2016. This program is FREEWARE, but original author (me) should be acknowledged when using this code.
;
; Instructions:
; Your goal is to land your Falcon 9 rocket/ship safely on the landing platform (or sea drone as used by SpaceX).
; Press the SPACE key to make the ship descend. Enjoy your landings!
;
; Notes:
; When runing the game on an emulator please make sure "border" view is active since border colour changes to indicate success or failure of landing.
; Due to the limitation of 256 byte code length and no ROM access it wasn't possible to implement proper leveling: increase/decrease difficulty can be done in several ways, for e.g. by changing the starting altitude of the ship and/or the game speed.
;
; Engineering for this ship was based on the works for Falcon 9 rocket from SpaceX (R), so it also should be able to land on a sea drone, as proposed on the game.

ORG 32768        ; works as well on any other valid address if compiled to that address

LEFT      EQU 1   ; move left for any object
RIGHT     EQU 0   ; move right for any object
DOWNB     EQU 2   ; move down for ship
PLATSIZE  EQU 5   ; size/length of landing platform
BLUE      EQU 5   ; border color blue when landing on platform
RED       EQU 2   ; border color red when misses platform
YEL_SHIP  EQU 48  ; ship color in yellow
MAG_PLAT  EQU 24  ; platform color in magenta


;pointing IX to begining address of variables
ld IX,plx
ld de,32    ; DE will never change and will be used to move between lines, so D=0 and E=32


; *** BEGIN of  main cycle ***
main_loop:

;first call paints, second call clears, and so on
call draw_graphs

;loop main pause
        halt
        halt
        halt
        halt

;read_space_key:
       ld bc,32766         ;port for B, N, M, Symbol Shift, Space
       IN A,(C)
       rra                 ;Space key in bit 0: 0 if pressed
       jr c,cont_next      ;key is not pressed if bit 0 is 1
       ld (ix+4),DOWNB     ;(dir_ship) - make ship descend (set value to 4)
cont_next:                 ;carry on with main loop



; detect if ship landed on the platform -> has to hit inside the platform to be safe
; det_collision:
; only need to detect collision when ship is moving down
; while ply<20 we don't need to check for collision

       ld a,(ix+1)     ; (ply)
       ;cp 20          ; is the ship on its last line? If yes, we need to check if it landed on the platform
       cp 18           ; %00010010
       jr c,cont_main  ; if not then the ship keeps travelling down and collision detection is not yet necessary
       ld hl,(tmp)     ; recover value of HL for the last ship square that has been draw. It will be used for landing detection. Would use Push/Pop if not inside a Call/Return.
       add hl,de       ; DE equals 32 at this point and we want to check if the platform is just below the ship!
       ld a,(hl)       ; get color value at this location
       cp MAG_PLAT     ; if this square is magenta then the rigth landing gear of ship is on the landing platform
       ld b,RED        ; set border to RED to indicate a failed landing
       jr nz,missed    ; if not, the ship missed landing
       dec hl
       dec hl
       ld a,(hl)       ; now let's check if the left side landing gear is also on the platform
       cp MAG_PLAT     ; if this square is magenta then the rigth landing gear of ship is on the landing platform
       jr nz,missed    ; if not the ship missed landing
       ld b,BLUE       ; Otherwise, our ship is safe on the plataforma => let's make a celebration

       ; test score
       inc (ix+5)      ; increase (score)

missed:   ld a,b        ; recover intended colour into a
          out (254),a   ; set border to our color

         ;clear graphics / screen to BLACK color
         ld hl,16384 ; start of screen
         ld a,91     ; 91*256= 23296  = value of H at the end of the cycle
   cls   ld (hl),d   ; d is always 0
         inc hl
         cp h        ; check for end of screen: stop when HL = 23296
         jr nz,cls

            ; display score on line 0
            ld h,88         ; %01011000
            ld l,d          ;line 0 is at 22528. D is always 0
            ld a,(ix+5)     ; score begins at 0 and goes up to 31
            and %00011111   ; must fit in 1 line, so MAX score = 31
            ld b,a
            inc b          ; b will be always > 0 and score bar will restart after 32
score_loop  ld (hl),e      ; fill in green E=32
            inc hl          ; score resets only on a new LOAD (just to save CODE bytes)
            djnz score_loop


         ;ship restarts at its current X (plx) and is back to the top, with Y (ply) getting a "random" value
         ld a,(ix)      ; (plx)
         rra            ; divide a by 2
         and %00000111  ; keep A under 8 => new (ply) between 0 and 7
         ld (ix+1),a    ; (ply) gets new "random" value
         ld (ix+4),d   ; (dir_ship) put ship moving to the right (d=0). Ideally it should continue in the same direction it was before but that requires more code
         
         ; DEBUG...posso retirar seguinte???
         jr main_loop  ;continue next with main loop


;first call paints graphics, second call clears, and so on
cont_main: call draw_graphs


;update coordinates of the ship: it can be moving LEFT, RIGHT or DOWN
;atcoord_ship:
           ld a,(ix+4)    ; (dir_ship) holds the direction of movement: LEFT=1, RIGHT=0 or DOWN=2
           ;rra
           and a
           jr nz,movesq    ; if not moving right then continue checking
           ld a,(ix+0)    ; (plx)
           inc a          ; move ship to next column on its right
           cp 30          ; the limit on the right is column 29 since our ship takes 3 square wide
           jr nz,cont_right ; keep moving ship right if the right side end was not reached yet
           
           ld (ix+4),LEFT   ; (dir_ship) if we have reached the end of right side then start moving to the LEFT
           jr atcoordp      ; continue with updating landing platform coordinates

cont_right:  ld (ix+0),a    ; (plx) move to next position on the right
             jr atcoordp      ; continue with main loop

movesq:    rra
           jr nc,movdesc   ; here we get carry=1 if moving to the left since (dir_ship) will be 1
           ld a,(ix+0)     ; (plx) is the horizontal coordinate of the ship
           or a             ; have we reached left end?
           jr nz,cont_left  ; continue: keep moving to the left
           ld (ix+4),d     ; (dir_ship) make ship move to the right (D=0)
           jr atcoordp      ; continue with next block of code
cont_left: dec a            ; make (plx) to next place/value to the left
           ld (ix+0),a      ; (plx) gets its new value of next position of the ship to its left
           jr atcoordp      ; continue with next block of code

movdesc:   ;we reach this point when the ship is moving DOWN
           ld a,(ix+1)     ; (ply)
           inc a
           ;cp 21           ; if the ship stands on line 20 then we need to check if it's over the platform OR if it will miss safe landing.
           cp 19            ; %10011. (ply)=0 corresponds to line 2, so (ply)=18 corresponds to line 20
           jr nc,atcoordp  ; if the ship is already in line 20 it will not descend more.
cont_desc: ld (ix+1),a    ; (ply) continue with the ship moving down



;update platform coordinates
atcoordp:
           ld a,(ix+2)       ; (dir_plat) =0 if the platform moves to the right and equals 1 if it moves to the left.
           and a
           jr nz,mov_left_p  ; here we get Z if platform is moving to the right
           ld a,(ix+3)       ; (platx) holds current X position of the platform
           inc a
           cp 28             ; the limit on the right is column 27 since the platform takes 5 square wide
           jr c,cont_rightp  ; keep moving the platform right if the right side end was not reached yet
           ld (ix+2),LEFT    ; (dir_plat) indicate that the platform next moves to the left
           jr cont_cycle


mov_left_p:  ld a,(ix+3)      ; (platx) get X position of the platform
             or a
             jr nz,cont_esqp  ; if didn't reach left end then keep moving left
             ld (ix+2),d     ; (dir_plat) , otherwise start moving plataform to the right (D=0)
             jr cont_cycle
cont_esqp:   dec a
cont_rightp: ld (ix+3),a      ; (platx) : store next position of platform to its left


; continue main cycle
cont_cycle: jp main_loop

; *** END of  main cycle ***


; Next code either shows OR clears graphics alternatively
draw_graphs:
;DRAW SHIP
;to obtain starting address we simply make [(ply)*32 + (plx)] to 22528

         ;ld h,88
         ;ld l,64         ; line 2 is 64 bytes below 22528.
         ld hl,22592
         ld a,(ix+1)     ; (ply) holds vertical coordinate of the ship.
         and a
         jr z,scr_cont
         ld b,a
scr_sum: add hl,de       ; DE is defined as 32 at the begining and never changes
         djnz scr_sum
scr_cont:
         ld a,l
         add a,(ix)      ; (plx)
         ld l,a          ; HL now holds the starting address to draw the ship on the screen
         ld a,YEL_SHIP   ; XOR of (hl) with 24 will change alternatively BLACK <-> YELLOW on ship squares color

; the ship is a 3x3 block:
;  #
;  #
; # #
;line 1
       inc hl
       xor (hl)       ; 24 XOR (hl) makes it alternate between BLACK and YELLOW
       ld (hl),a
;line 1
       add hl,de
       ld (hl),a     ; line 2 of the ship is same as line 1
;line 3
       dec de        ; DE is now 31
       add hl,de
       ld (hl),a     ; char 1 of line 3 of the ship is same as lines 1 and 2
       inc hl
       ld (hl),d     ; char 2 of line 3 is always BLACK (d=0)
       inc hl
       ld (hl),a     ; char 3 of line 3 of the ship is same char 1
       inc de        ; DE is now back to 32
       ;keep the value of HL (to be used on the collision detection if necessary)
       ld (tmp),hl   ; would use Push/Pop if not inside a Call/Return


;DRAW PLATFORM
;clear_platf:
       ld hl,23264       ;  the platform moves on last line, which begins on address 23264
       ld a,(ix+3)       ; (platx)
       add a,l           ; the platform never leaves its line
       ld l,a
       ld b,PLATSIZE     ;  get platform SIZE (5 on this version of the game)
       ld a,(hl)
       xor MAG_PLAT       ; xor 24 will make (hl) alternate between black and magenta
drawplat:                ; paint/draw OR clear the platform, alternate
       ld (hl),a
       inc hl
       djnz drawplat
       ret


;VARIABLES
;IX points here
plx       defb 0       ; X coordinate of the ship (screen columns): 0 in the begining.
ply       defb 0       ; Y coordinate of the ship (screen lines): moves on line 2 in the begining.
dir_plat  defb 1       ; = 0 if platform is moving to the right, 1 if moving to the left: starts from right -> left.
platx     defb 27      ; X coordinate of the platform
dir_ship  defb 1       ; = 0 if the ship is moving to the right, 1 if moving to the left and 2 if moving down: starts from left -> right.
score     defb 0       ; score will be kept between 1 and 32 to be presented in line 0
tmp       defw 0       ; 2 byte used for generic storage. Used to store value of HL after drawing the ship. Useful when ship is in the lower part of screen to check if it is above the platform.






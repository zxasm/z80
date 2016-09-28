ccc; -----------------------------------------------------------------------------
; Name:     fbird
; Author:   John McManus
; Started:  19th May 2016
; Finished: 
;
;
; This is an entry for the 256 bytes game competition #6 on the Z80 Assembly programming
; on the ZX Spectrum Facebook Group https://www.facebook.com/groups/z80asm/
org 40000

;***** Constants *****
K_ATTR_ADDR        equ             0x5800 ; 22528
K_ATTR_BUFFER      equ             0XAF00 ; 44800
K_SCORE_ATT        equ             45738  
K_GRAVITY		equ		0x00AFF
K_BIRDX     equ   0
K_BIRDY			equ		5
K_BLANK			equ		0
K_BIRD			equ		32
K_WALL			equ		24	
K_SCORE     equ 8
K_COLDB     equ   0xA028 ; 41000
K_XSTART equ 0
K_XGAP equ 8
K_ENDCOL equ 31 
; **** Variables *****
bird_x       DEFB     K_BIRDX ; x position will be constant
bird_y       DEFB     K_BIRDY ; x position will be constant
score        DEFB     0x01;
gravcount    DEFW     K_GRAVITY 
lastkey   DEFB     0
;flapdelay    defb     255
;********************************************************
  call builddbnew
mainloop     	
  call keypress ; if key pressed move bird up
  call chkgrav ; counts down gravity function. all updates are based
  ret z     ; end of game 
  jr mainloop ; program loop 
 
updateloop ; this does all the update called from delay function
  call applygravity
  ;call clrbuffer
  ;call drawcolumns
;  call updatescore
  call refreshScreen
  call mvcl

ret

; ***************** Subroutines ----re organised to reduce number of calls
;check for key press

keypress
  ld a , (lastkey)
  ld b, a
  xor a 
  IN A,(254)     ;
  and 31 
  cp b 
  ret z
;statechange
  ld (lastkey), a

flap 
  ld hl, bird_y
  dec (hl)
  ;dec (hl)
endflap
  ret

; decrements garvity count until zero (just a timer)
; trigger the rest of the game movements
chkgrav   LD  BC,(gravcount)
    DEC BC
    LD  A,C
    OR  B
    JR  NZ,  SAVGRAV
    ;reset gravcount
    LD BC, K_GRAVITY
    ;LD  (gravcount), BC
    call SAVGRAV
    call  updateloop
    RET
SAVGRAV
    LD  (gravcount), BC
    RET

;move the bird down - should really make if 23 stop game 
applygravity
  ;ld a,(bird_y)
 ; cp 22
  ;jp Z, endgrav 
  ld hl, bird_y
  inc (hl)
endgrav
 ; ret

clrbuffer
  ld de, K_ATTR_BUFFER+1
  ld hl, K_ATTR_BUFFER
  ld (hl), 0
  ld bc ,767
  ldir

  ;ld de, K_ATTR_BUFFER+1
  ;ld hl, K_ATTR_BUFFER
  ;ld (hl), K_WALL
  ;ld bc ,31
  
  ;ldir

  ;ld de, K_ATTR_BUFFER+705
  ;ld hl, K_ATTR_BUFFER+704
  ;ld (hl), K_WALL
  ;ld bc ,31
  ;ldir

;; put bird back on

  ld de ,(bird_x)
  ld a, K_BIRD
  call drawpoint
  ;ret



drawcolumns
	ld ix , K_COLDB
  ld b, 0
getnext
  ;d,e hold x,y for drawpoint routine

	ld d, (ix)
	inc ix
	ld e, (ix)
  ;ld d ,(ix)
	;push hl
  ld a, K_WALL ; holds the attrib colour for drawpoint 
	call drawpoint
	;pop hl
	inc ix
	ld a ,(ix)
	cp 255 ; looking for end of DB 
	jr NZ , getnext
  ret

mvcl
  ld hl, K_COLDB+1
mvnxt
  ld a, 255
  cp (hl)
  jr z , endmvcl
  dec (hl)
  cp (hl)
  jr Z , wrap
  jr nowrap
wrap
  ;ok we are on 0 check if the bird is on 
  ld b,1
  ld (hl), 31
  
  dec hl ; move to y position
  ld a,(bird_y)
  cp (hl)
  jr z, kill
  inc hl 
nowrap
  inc hl
  inc hl 
  jr mvnxt
endmvcl
ld a,1
  xor b
  jp nz , donemv

  ld hl, score 
  inc (hl)
 ;

donemv

  ret 
  
kill
  xor a 
  ret


;de = x,y
;a = attrib setting  
drawpoint 
  push af
  LD a, d 
  sra a
  sra a
  sra a
  add a, 0xAF 
  ld h,a
  ld a,d 
  and 7
  RRCA
  RRCA
  RRCA
  ADD a,e 
  LD L,A
  pop af
  ld (hl), a 
  ret 

 
builddbnew
  ;db format is y,x - 
; try and build from the bottom up
; b = length of screen
  
  ld c, 5 ; number of columns
  ld d, 0
  ;xor d 
  ;xor d 
  ;ld d, K_XGAP
  ld hl, K_COLDB
  
newcol
  ld b, 22 ; number of rows and y value
  ;ld a, 15 ; start the gap at 15

  ld a, 6
  add a,d 
  ld d,a 

;  halt
;  halt
;  halt
  LD A, R     
  ;halt
  ;ld  a,(Rand8+1)
  and %00001111
  or  %00001000
  ;inc d
  ;inc d
  ;inc d
  ;inc d
  ;inc d
  ;inc d
  
ldxy
  cp b
  jp z , skipgap 
  ld (hl), b
  inc hl
  ld (hl), d 
  inc hl
  jp nextrow 
 skipgap
  rr b
  ;dec b
  ;dec b
  ;dec b
 nextrow 
  djnz ldxy 
  ;if b wraps from z to 255 jump to col done
  ;jp P, coldone
ld (hl), b
  inc hl
  ld (hl), d 
  inc hl
  
    dec c 
    xor a
    cp c
    jp nz, newcol


  ld (hl), 255
  inc hl
   ld (hl), 255
 
ret

;updatescore
;  ld hl, K_ATTR_BUFFER+768-32
;  ld a,(score)
;  ld b, a 
;  ld b,10
;  ld b,1
;  ld a, K_BIRD
;more
;  ld (hl),K_SCORE
;  inc hl
;  djnz more

refreshScreen
  ld de, K_ATTR_ADDR
  ld hl, K_ATTR_BUFFER
  ld bc, 768
  ldir
  ret
;ret







	org	0x6000
;SPACE RACE by Arcadiy Gobuzov. Made for COMPO #6 www.facebook.com/groups/z80asm
;First (?) Spectrum multiplayer game in 256 bytes
;
; Control keys:
; <ENTER> - Start
; <1,2> RED ROCKET
; <A,S> GREEN ROCKET
;
;tech details: we only draw in memory buffer [de00..ff3f]
;but on screen we see only 32x24 window
;     0123456789ABCDEF
;de00
;df00
;...
;e600    16 bytes     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;e700    offscreen    XX this window will on screen XX
;e800                 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
;...
;fc00                 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
;fd00                 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
;fe00
;ff00
STAR		equ	255	;/// colors
ASTEROID	equ	8	;
MAX_ASTEROIDS	equ	217	; 222-217 = 5
startpoint:
;	ld	hl,end-startpoint	;temp to know size
	ei
	ld	hl,0x5f5b	;hl,c as random seeds
	exx
;
;	jr	$
start_game:
	ld	a,8	; start energy
	ld	(player1+2),a
	ld	(player2+2),a
	ld	a,221	; one bad guy for begin
	ld	(update+1),a
	ld	d,0

loop:	ld	bc,0xbffe
	in	a,(c)
	rra
	jr	nc,start_game

clr_buf:xor	a
	ld	h,221
clrloop:ld	l,d	;first time 0; others 91
	ld	(hl),a
	dec	l
	jr	nz,$-2
	inc	h
	jr	nz,clrloop

;object struct: [dy, y, dx, x, color]
update:	ld	l,218	; 256-objects ; 220
updloop:ld	h,221
;
; 1: update & check only y
	ld	a,(hl)	; dy
	inc	h
	add	a,(hl)	; add y
	ld	(hl),a
	ld	d,a
	jr	nz,update_normal
; 2: if offscreen, init new object:
; now h=222
rand:	exx
	ld	a,h
	rra
	rrca
	rrca
	xor	l
	rra		
	rl	c
	adc	hl,hl
	exx
;//rand
	and	63
	ld	e,a	; newx
	and	3
	rla             ; a: [0,2,4,6]
	add	a,h	; h=DE
	ld	d,a	; newy
	ld	a,l
	cp	h	; DE: stars from XXDE..XXFF
	ld	bc,0x100; dx = 0; dy = 1
	jr	nc,init_star
;init_asteroid:
	res	0,e	; e= [0,2,4,6..62]
	inc	c	; c=dx; +1 from left
	ld	a,e     ;
	cp	16
	jr	c,asteroids	
	dec	c       ; dx=0 central direction
	cp      48
	jr	c,asteroids
	dec	c       ; c=-1 from right
asteroids:
	ld	a,ASTEROID
	jr	init_object
init_star:
	rra	;a-random
	ld	a,STAR
	jr	nc,$+3
	inc	b	; randomly iy++
;in:	a: color [STAR, ASTEROID]
;	bc: b=dy, c=dx
;	de: d=newy, e=newx
;object struct: [dy, y, dx, x, color]
init_object:
	dec	h	; h=221 again
	ld	(hl),b	; dy
	inc	h
	ld	(hl),d	; newy
	inc	h
	ld	(hl),c	; dx
	inc	h
	ld	(hl),e	; newx
	inc	h
	ld	(hl),a	; color
;
update_normal:
	ld	h,223	; skip dy & y; d already = y
	ld	a,(hl)	; dx
	inc	h
	add	a,(hl)
	ld	(hl),a	; newx
	inc	h
	ld	e,a	; xcoor
	ld	a,(hl)	; a-color
;de  e-[0..63] x;  d-[222..255] y;
;/// draw STAR or ASTEROID
	ld	(de),a
	cp	ASTEROID
	jr	nz,nextspr
	inc	e
	ld	(de),a
	inc	d
	ld	(de),a
	dec	e
	ld	(de),a
;
nextspr:inc	l
	jr	nz,updloop
;
player1:ld	de,0x1e	; D-energy; E-x coordinate
	ld	bc,0xf750 ; B-keyport; C-color
	ld	l,0x11
	call	player
	ld	(player1+1),de
;
player2:ld	de,0x21	; D-energy; E-x coordinate
	ld	bc,0xfd60
	ld	l,0x2e
	call	player
	ld	(player2+1),de
;
	halt
; check time for increment asteroids
	dec	xl
	jr	nz,no_incr
	ld	hl,update+1	;ld hl,update
	ld	a,(hl)
	cp	MAX_ASTEROIDS   ;ld a,(hl)
	jr	z,no_incr       ;cp N
	dec	(hl)
no_incr:
moveonscr:
	ld	de,22528	;16
	ld	h,222+8
movloop:ld	bc,32	;!
	ld	l,16	;!
	ldir
	inc	h
	jr	nz,movloop
;
	jp	loop

;in: de:lives,x; l:xbar; bc:keyport,color
;out: de:lives,x;
player:	inc	d
	dec	d
	ret	z       ; no lives return
	push	bc	; store keyport
	ld	b,d     ; lives
	ld	h,0xe7	; second line in buffer

barloop:ld	(hl),c
	inc	l
	bit	5,l     ; right or left side of screen (32-center of buffer)
	jr	z,barend
	dec	l
	dec	l
barend:	djnz	barloop
;// draw rocket
	ld	l,e	; xcoor
	ld	h,0xfb  ; ycoor
	ld	(hl),c
	inc	h
	inc	l
	ld	b,3
check:	ld	a,(hl)  ; collision detect here
	cp	ASTEROID
	jr	nz,draw
	dec	d
	jr	z,cont
draw:	ld	(hl),c
	dec	l
	djnz	check
;
cont:	pop	bc	; restore keyport
	ld	c,$fe
	in	a,(c)   ; check 0 & 1 bits
	rra
	jr	c,isright
	ld	a,e
	cp	18
	ret	z
	dec	e
	ret
isright:	
	rra
	ret	c
	ld	a,e
	cp	45	; right end x
	ret	z
	inc	e
	ret
end:
	savesna "space_race.sna",startpoint
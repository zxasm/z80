;
; Written by John Young (polomint77) 25/04/2014 using Polo'Ed (Z80 Asm Editor)
;
;
;
; Create lookup table for transferring flat screen to speccy screen..
;
; Used for transferring a back screen which has each pixel line 32 bytes after the previous one.
;
; NOTE: this will convert (x,y) 0, 0..191 to the correct address for the spectrum screen display
;          and place that address into the lookup table...
; 
;

generate_screen_table:
	;
	ld bc,0						; first clear the x,y coords (b=y, c=x)
	ld hl, screen_table				; where to put the table
	ld d, 192					; 192 lines on the display k, :p
	ld e, 0
next_screen_line:
	push de						; save the loop counter for now
	push bc						; save the coords
	
	ld a, b						; fetch vertical coords
	ld e, a
	; find line within cell
	and 7						; line 0-7 within character square
	add a, 64					; 64*256 = 16384 = start of screen display
	ld d, a						; line * 256
	; find which third of the screen we're in
	ld a, e						; restore the vertical
	and 192						; segment 0, 1 or 2 multiplied by 64
	rrca						; divide this by 8
	rrca
	rrca						; segment 0-2 multiplied by 8
	add a, d					; add to d give segment address
	ld d, a
	; find character cell within segment
	ld a, e						; 8 character squares per segment
	rlca						; divide x by 8 and multiply by 32
	rlca						; net calculation: multiply by 4
	and 224						; mask off bits we don't want
	ld e, a						; vertical coordinate calculation done

	; add the horizontal element
	; not really needed but ehhh what the hell, the table is only done once, :)
	;ld a, c						; x coordinate
	;rrca						; only need to divide by 8
	;rrca
	;rrca
	;and 31						; squares 0..31 across screen
	;add a, e					; add to total so far
	;ld e, a					; de = address of screen
	
	ld (hl), e
	inc hl
	ld (hl), d					; plonk the screen location for the current coord into the lookup table
	inc hl
	
	pop bc						; restore the coords
	inc b						; next line please

	pop de						; I take that loop counter back now, :)
	dec d						; decrement the loop...
	ld a, d
	and a
	jr nz, next_screen_line
	
	ld bc, screen_table				; remove this if you don't need the lookup_table location to be returned......
	ret						; exit before summat goes wrong, ;)
	
; the addresses of the start of each display line are here..  [0..191]
; DONT FORGET: Anything code/data located after here for 384 bytes will be destroyed when the generate routine is called !!!
; although 384 bytes is a handy chunk for other stuff, which can be overwritten if's only being used once, eg, music etc..
screen_table:
	ds 384

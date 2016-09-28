;
; Written by John Young (polomint77) 25/04/2014 using Polo'Ed (Z80 Asm Editor)
;
;
; Transfer back buffer screen to main spectrum screen
;
;
; The back buffer screen is at 32768 (you can re-org it at 49152 or whatever if you like)
; add 6912 bytes to get to transfer_back_to_front routine... (39680d or $9B00)
;
org 32768
back_buffer_screen:
incbin "jazz.bmp"		; remove if you don't have a scr to hand or don't need this...


org 32768+6912	

;-------------------------------------------------------------------------
; approx 100224 t-states to transfer the back buffer to the speccy screen
;-------------------------------------------------------------------------
init:
	call generate_screen_table
transfer_back_to_front:
	di
	ld hl, back_buffer_screen
	ld bc, 192*32
	ld (storesp), sp
	ld sp, screen_table
line_loop:
	pop de					; get the speccy screen line address using sp
	REPT 32
	ldi
	ENDM
	jp pe, line_loop
	ld sp, (storesp)
	ei
	ret
	

storesp: defw 0						; place to save sp	
include "generate_screen_table.asm"


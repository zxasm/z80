;***********************************************************
;* Size / Effect Coding #12 
;*
;* Adrian Brown - adrian@apbcomputerservices.co.uk
;*
;***********************************************************

				ORG	0c000h

;***********************************************************

Screen2:		incbin	"Screen2.scr"
Screen1:		incbin	"Screen1.scr"

;***********************************************************

Start:			
				; Set border
				xor		a
				out		(254), a

				; Copy the first screen to the physical screen
				ld		de, 16384
				ld		hl, Screen2
				ld		bc, 6912
				ldir

				; Call the routine we are measuring (or not in the effects version)
				call	MyRoutine

				; Wait a bit and go back
				ld		b, 240
PauseLoop:
				halt
				djnz	PauseLoop

				jr		Start

;***********************************************************

MyRoutine:
				ret

;***********************************************************

				END Start
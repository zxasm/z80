;-----------------------------------------------------------
;
; Z80 Assmebler - Part 1 - 5
;
;-----------------------------------------------------------

				ORG		$8000

;-----------------------------------------------------------

Start:
				; Clear the screen
				call	0x0DAF

				; Display Hello World
				ld		hl, String
				ld		b, 14

Loop:			; Get the character from HL and move on
				ld		a, (hl)
				inc		hl

				; Write it to the screen
				rst		16

				; Loop through them all
				djnz	Loop

				; Return to BASIC
				ret

;-----------------------------------------------------------

				; You can also use dm instead of db to define a message eg. dm "Hello World"
String:			db		22, 5, 5, 'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd'

;-----------------------------------------------------------
				
				END Start


;-----------------------------------------------------------
;
; Z80 Assmebler - Part 1 - 3
;
;-----------------------------------------------------------

				ORG		$8000

;-----------------------------------------------------------

Start:
				; Clear the screen
				call	0x0DAF

				; Display Hello World
				ld		a, 'H'
				rst		16
				ld		a, 'e'
				rst		16
				ld		a, 'l'
				rst		16
				ld		a, 'l'
				rst		16
				ld		a, 'o'
				rst		16
				ld		a, ' '
				rst		16
				ld		a, 'W'
				rst		16
				ld		a, 'o'
				rst		16
				ld		a, 'r'
				rst		16
				ld		a, 'l'
				rst		16
				ld		a, 'd'
				rst		16

				; Return to BASIC
				ret

;-----------------------------------------------------------
				
				END Start


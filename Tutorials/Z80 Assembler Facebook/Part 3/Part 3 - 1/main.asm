;-----------------------------------------------------------
;
; Z80 Assmebler - Part 3 - 1
;
;-----------------------------------------------------------

				ORG		$8000

;-----------------------------------------------------------

Start:
				; Clear the screen
				call	0x0DAF

				ld		a, %10011111

				; Display A
				ld		h, 0
				ld		l, 0
				call	DisplayBinary

				; Perform the NOT
				cpl

				; Display the new value below the first
				ld		h, 1
				ld		l, 0
				call	DisplayBinary

				; Return to BASIC
				ret

;-----------------------------------------------------------
; Inputs:
; A = Value to display
; L = X Position
; H = Y Position

DisplayBinary:
				push	bc
				push	hl
				push	af

				; Remember A
				ld		c, a

				; Write out the set position information
				ld		a, 22
				rst		&10
				ld		a, h
				rst		&10
				ld		a, l
				rst		&10

				; Need to do 8 bits
				ld		b, 8
Loop:
				; Shift the bit off the top
				rl		c

				; Set A to 0 or 1 as needed
				ld		a, '0'
				jr		nc, BitZero
				ld		a, '1'
BitZero:
				; Print it
				rst		&10

				; Do all 8 bits
				djnz	Loop
				pop		af
				pop		hl
				pop		bc
				ret

;-----------------------------------------------------------
				
				END Start


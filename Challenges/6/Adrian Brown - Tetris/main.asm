;***********************************************************
;* Size Coding #6 Entry
;*
;* Adrian Brown - adrian@apbcomputerservices.co.uk
;*
;***********************************************************

				ORG	08000h

;***********************************************************

Start:			
				; Clear the screen (plus the printer buffer which will be used as variables)
				ld		hl, $4000
				ld		de, $4001
				ld		(hl), l
				ld		bc, &1bff
				ldir

				; Draw the game border
				ld		hl, $5829
				ld		(hl), h
				ld		de, $5834
				ld		a, d
				ld		(de), a
				ld		e, $49
				ld		bc, 32*21
				ldir
				ld		b, 12
_Board:
				ld		(de), a
				inc		e
				djnz	_Board

				;******************************************
				; See if we want to drop any rows down
				;******************************************
CheckDrop:
				ld		hl, $5aca
				ld		c, 22
_NextRow:
				; See if this row is empty
				ld		b, 10
				push	hl
_CheckRow:
				ld		a, (hl)
				and		a
				jr		z, _NotFull
				inc		l
				djnz	_CheckRow

				; We can now drop the blocks down
				ld		a, c
_NotFull:
				pop		de
				ld		hl, -32
				add		hl, de

				; Cheeky - use the flag from the djnz above the first time to exit and the jr nz below after that
				jr		z, _DoNextRowCheck
				push	hl
				ld		c, 10
				ldir
				dec		a
				jr		nz, _NotFull

				pop		hl
				jr		CheckDrop

_DoNextRowCheck:
				dec		c
				jr		nz, _NextRow

				; We cant move down - redraw the piece where it was and check for falling
_GetBlock:		ld		a, r
				and		$38
				jr		z, _GetBlock
				ld		e, a
				rrca
				rrca
				rrca
				ld		(BlockNum + 1), a
				
				;******************************************
				; Set the starting position
				;******************************************
NewBlockLoop:
				ld		d, 1
				ld		ixh, d
				ld		hl, $582c		; (Block Starting Position)

				; End of game
				call	TestPiece
				jr		nz, Start

MainLoopResetFlag:
				;******************************************
				; Now clear the z flag - remember the flags (or h as h will never be 0)
				;******************************************
				or		h
				ex		af, af'

				;******************************************
				; Draw the block
				;******************************************
MainLoop:
				ld		a, e
				call	DrawPiece

				;******************************************
				; Wait a frame
				;******************************************
				halt

				;******************************************
				; Check for drop
				;******************************************
				ex		af, af'
				jr		z, CheckDrop

				;******************************************
				; Clear the block
				;******************************************
				call	ClearPiece

				; Store the current details
				push	de
				push	hl

				;******************************************
				; Keyboard system
				;******************************************
				ld		bc, $dffe
				in		a, (c)
				bit		3, a
				jr		z, _DroppingDown

				; Debounce the keys
				cpl
				ld		b, a
				xor		ixl
				ld		ixl, b
				and		b

				rra
				jr		nc, _NoRight
				inc		hl
_NoRight:
				rra
				jr		nc, _NoLeft
				dec		hl
_NoLeft:
				rra
				jr		nc, _NoRotate
				inc		d
_NoRotate:

				;******************************************
				; Handle the delay
				;******************************************
_DropDelay:		dec		ixh
				jr		nz, _NotDropping
_DroppingDown:
				; Handle the dropping - restore HL/DE as we cant move to the side and drop
				; else a block can get stuck on the side
				pop		hl
				pop		de
				push	de
				push	hl
				ld		bc, 32
				add		hl, bc
				ld		ixh, 16				
_NotDropping:
				; Check if it can be here
				ex		af, af'
				call	TestPiece

				; Restore our old positions into the exx pairs
				exx
				pop		hl
				pop		de

				; If we can move then start the loop again
				jr		nz, MainLoop

				; Get our new positions back
				exx

				jr		MainLoopResetFlag

;***********************************************************

ClearPiece:
				xor		a
				out		(254), a
DrawPiece:
				ld		b, $77			; OPCODE FOR ld (hl), a
				jr		BlockFunction
TestPiece:
				ld		b, $b6			; OPCODE FOR or (hl)
				xor		a
BlockFunction:
				push	de
				push	hl
				push	af
				ld		hl, NoData - 1
				ld		(hl), b

				;************************************
				; Get the block data
				;************************************
				ld		hl, Blocks
BlockNum:		ld		bc, 1
				add		hl, bc

				; Get rotations
				ld		a, d
				and		3
				inc		a
				rla
				ld		c, a

				;  Get AE as the data byte shifted 4
				ld		b, (hl)
				xor		a
				rld
				ld		e, (hl)
				ld		(hl), b

				;************************************
				; Rotate the block
				;************************************
_Twiddle1:
				ld		b, 8
_Twiddle2:		
				rl		e
				rla
				rr		h
				rl		e
				rla
				rr		l
				djnz	_Twiddle2

				ex		de, hl
				ld		a, d
				dec		c
				jr		nz, _Twiddle1

				;************************************
				; Get the position to draw the piece
				;************************************
BlockPosition:
				pop		af
				pop		hl
				push	hl

				ld		b, 4
_Loop1:
				push	bc
				ld		b, 4
_Loop2:
				; Wonder if we can link the get block data and this?
				sla		e
				rl		d
				jr		nc, NoData
				ld		(hl), a
NoData:
				inc		l
				djnz	_Loop2

				ld		c, 28
				add		hl, bc

				pop		bc
				djnz	_Loop1

				pop		hl
				pop		de

				; Do the test
				and		a
				ret

;***********************************************************
; DATA
;***********************************************************

Blocks:			EQU		$ - 1

				db		%11000110			; S
				db		%00110110			; Z
				db		%01100110			; O
				db		%11101000			; L
				db		%11100010			; J
				db		%01001110			; T
				db		%11110000			; I

;***********************************************************
; VARIABLES
;***********************************************************


				END 08000h
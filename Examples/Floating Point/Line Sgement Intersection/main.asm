;-----------------------------------------------------------
;
; Line Intesection by Adrian Brown
;
;-----------------------------------------------------------
; NOTES:
;		Remember 0,0 is the bottom left of the screen!
;		Based on the line segment intersection code from
;		http://paulbourke.net/geometry/pointlineplane/
;-----------------------------------------------------------

;-----------------------------------------------------------
; Useful Rom Routines
;-----------------------------------------------------------

ROM_CLS:		EQU		$0D6B
ROM_CHAN_OPEN:	EQU		$1601
ROM_PR_STRING:	EQU		$203C
ROM_DRAW_LINE:	EQU		$24B7
ROM_STACK_AEDCB:EQU		$2AB6
ROM_STK_TO_AEDCB:EQU	$2BF1
ROM_STACK_A:	EQU		$2D28
ROM_STACK_BC:	EQU		$2D2B
ROM_STK_TO_BC:	EQU		$2DA2
ROM_STK_TO_A:	EQU		$2DD5
ROM_FP_TESTZERO:EQU		$34E9

;-----------------------------------------------------------
; Floating Point commands
;-----------------------------------------------------------

FP_JUMP_TRUE:	EQU		0
FP_EXCHANGE:	EQU		1
FP_DELETE:		EQU		2
FP_SUBTRACT:	EQU		3
FP_MULTIPLY:	EQU		4
FP_DIVISION:	EQU		5
FP_TO_POWER:	EQU		6
FP_ADDITION:	EQU		15
FP_NEGATE:		EQU		27
FP_ABS:			EQU		42
FP_DUPLICATE:	EQU		49
FP_JUMP:		EQU		51
FP_LESS_ZERO:	EQU		54
FP_GREATER_ZERO:EQU		55
FP_END:			EQU		56
FP_STK_ZERO:	EQU		160
FP_STK_ONE:		EQU		161
FP_STK_HALF:	EQU		162
FP_STK_PI_2:	EQU		163
FP_STK_TEN:		EQU		164
FP_ST_MEM_0:	EQU		192
FP_ST_MEM_1:	EQU		193
FP_ST_MEM_2:	EQU		194
FP_ST_MEM_3:	EQU		195
FP_ST_MEM_4:	EQU		196
FP_ST_MEM_5:	EQU		197
FP_GET_MEM_0:	EQU		224
FP_GET_MEM_1:	EQU		225
FP_GET_MEM_2:	EQU		226
FP_GET_MEM_3:	EQU		227
FP_GET_MEM_4:	EQU		228
FP_GET_MEM_5:	EQU		229

;-----------------------------------------------------------
; Useful System Variables
;-----------------------------------------------------------

SVAR_COORDS_X:	EQU		$5C7D
SVAR_COORDS_Y:	EQU		$5C7E

;-----------------------------------------------------------

				ORG		$8000

;-----------------------------------------------------------

Start:
				; As we are using the ROM, it can get funny if we
				; mess up the EXX registers (especially HL), save them all
				exx	
				push	hl
				push	bc
				push	de
				exx

				; Clear the screen
				call	ROM_CLS

				; Lets open stream for writing etc, for testing
				ld		a, 2
				call	ROM_CHAN_OPEN

				; First lets set some point
				ld		a, 100
				ld		(Point1_StartX), a
				ld		a, 10
				ld		(Point1_StartY), a

				ld		a, 220
				ld		(Point1_EndX), a
				ld		a, 150
				ld		(Point1_EndY), a

				; Setup the next point
				ld		a, 120
				ld		(Point2_StartX), a
				ld		a, 100
				ld		(Point2_StartY), a

				ld		a, 200
				ld		(Point2_EndX), a
				ld		a, 40
				ld		(Point2_EndY), a

				; For debug lets draw the lines
				call	DrawDebug

				; Test if the lines collide
				call	LINES_CollideTest
				jr		c, _NoCollision

				ld		de, CollisionString
				ld		bc, CollisionStringEnd - CollisionString
				call	ROM_PR_STRING
				jr		_DonePrint
_NoCollision:	
				ld		de, NoCollisionString
				ld		bc, CollisionStringEnd - NoCollisionString
				call	ROM_PR_STRING

_DonePrint				
				; Restore the register pairs so we can return to basic
				exx
				pop		de
				pop		bc
				pop		hl
				exx

				ret

;-----------------------------------------------------------
; Returns with Carry Set if there is no collision, else carry clear
LINES_CollideTest:
				; We need to calculate a few things
				; denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)

				ld		a, (Point2_EndX)
				call	ROM_STACK_A
				ld		a, (Point2_StartX)
				call	ROM_STACK_A
				ld		a, (Point1_EndY)
				call	ROM_STACK_A
				ld		a, (Point1_StartY)
				call	ROM_STACK_A

				ld		a, (Point2_EndY)
				call	ROM_STACK_A
				ld		a, (Point2_StartY)
				call	ROM_STACK_A
				ld		a, (Point1_EndX)
				call	ROM_STACK_A
				ld		a, (Point1_StartX)
				call	ROM_STACK_A

				rst		$28							; x4, x3, y2, y1, y4, y3, x2, x1
				db		FP_SUBTRACT					; x4, x3, y2, y1, y4, y3, (x2-x1)
				db		FP_ST_MEM_0					; x4, x3, y2, y1, y4, y3, (x2-x1)
				db		FP_DELETE					; x4, x3, y2, y1, y4, y3
				db		FP_SUBTRACT					; x4, x3, y2, y1, (y4-y3)
				db		FP_GET_MEM_0				; x4, x3, y2, y1, (y4-y3), (x2-x1)
				db		FP_MULTIPLY					; x4, x3, y2, y1, (y4-y3)(x2-x1)
				db		FP_ST_MEM_1					; x4, x3, y2, y1, (y4-y3)(x2-x1)
				db		FP_DELETE					; x4, x3, y2, y1
				db		FP_SUBTRACT					; x4, x3, (y2-y1)
				db		FP_ST_MEM_0					; x4, x3, (y2-y1)
				db		FP_DELETE					; x4, x3
				db		FP_SUBTRACT					; (x4-x3)
				db		FP_GET_MEM_0				; (x4-x3), (y2-y1)
				db		FP_MULTIPLY					; (x4-x3)(y2-y1)
				db		FP_GET_MEM_1				; (x4-x3)(y2-y1), (y4-y3)(x2-x1)
				db		FP_EXCHANGE					; (y4-y3)(x2-x1), (x4-x3)(y2-y1)
				db		FP_SUBTRACT					; (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_ST_MEM_2					; (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_END

				call	ROM_FP_TESTZERO
				ret		c

				;numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)
				ld		a, (Point2_EndY)
				call	ROM_STACK_A
				ld		a, (Point2_StartY)
				call	ROM_STACK_A
				ld		a, (Point1_StartX)
				call	ROM_STACK_A
				ld		a, (Point2_StartX)
				call	ROM_STACK_A

				ld		a, (Point2_EndX)
				call	ROM_STACK_A
				ld		a, (Point2_StartX)
				call	ROM_STACK_A
				ld		a, (Point1_StartY)
				call	ROM_STACK_A
				ld		a, (Point2_StartY)
				call	ROM_STACK_A

				rst		$28							; y4, y3, x1, x3, x4, x3, y1, y3
				db		FP_SUBTRACT					; y4, y3, x1, x3, x4, x3, (y1-y3) 
				db		FP_ST_MEM_0					; y4, y3, x1, x3, x4, x3, (y1-y3)
				db		FP_DELETE					; y4, y3, x1, x3, x4, x3
				db		FP_SUBTRACT					; y4, y3, x1, x3, (x4-x3)
				db		FP_GET_MEM_0				; y4, y3, x1, x3, (x4-x3), (y1-y3)
				db		FP_MULTIPLY					; y4, y3, x1, x3, (x4-x3)(y1-y3)
				db		FP_ST_MEM_1					; y4, y3, x1, x3, (x4-x3)(y1-y3)
				db		FP_DELETE					; y4, y3, x1, x3
				db		FP_SUBTRACT					; y4, y3, (x1-x3) 
				db		FP_ST_MEM_0					; y4, y3, (x1-x3)
				db		FP_DELETE					; y4, y3
				db		FP_SUBTRACT					; (y4-y3)
				db		FP_GET_MEM_0				; (y4-y3), (x1-x3)
				db		FP_MULTIPLY					; (y4-y3)(x1-x3)
				db		FP_GET_MEM_1				; (y4-y3)(x1-x3), (x4-x3)(y1-y3)
				db		FP_EXCHANGE					; (x4-x3)(y1-y3), (y4-y3)(x1-x3)
				db		FP_SUBTRACT					; (x4-x3)(y1-y3)-(y4-y3)(x1-x3)
				db		FP_GET_MEM_2				; (x4-x3)(y1-y3)-(y4-y3)(x1-x3), (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_DIVISION					; (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_DUPLICATE				; (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_LESS_ZERO				; (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), (0/1)
				db		FP_JUMP_TRUE, 5				; Jump to end if less than 0
				db		FP_STK_ONE					; (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), 1
				db		FP_EXCHANGE					; 1, (x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_SUBTRACT					; 1-((x4-x3)(y1-y3)-(y4-y3)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1))
				db		FP_LESS_ZERO				; (<0)
				db		FP_END

				call	ROM_FP_TESTZERO
				ccf
				ret		c

				;numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)
				ld		a, (Point1_EndY)
				call	ROM_STACK_A
				ld		a, (Point1_StartY)
				call	ROM_STACK_A
				ld		a, (Point1_StartX)
				call	ROM_STACK_A
				ld		a, (Point2_StartX)
				call	ROM_STACK_A

				ld		a, (Point1_EndX)
				call	ROM_STACK_A
				ld		a, (Point1_StartX)
				call	ROM_STACK_A
				ld		a, (Point1_StartY)
				call	ROM_STACK_A
				ld		a, (Point2_StartY)
				call	ROM_STACK_A

				rst		$28							; y2, y1, x1, x3, x2, x1, y1, y3
				db		FP_SUBTRACT					; y2, y1, x1, x3, x2, x1, (y1-y3) 
				db		FP_ST_MEM_0					; y2, y1, x1, x3, x2, x1, (y1-y3)
				db		FP_DELETE					; y2, y1, x1, x3, x2, x1
				db		FP_SUBTRACT					; y2, y1, x1, x3, (x2-x1)
				db		FP_GET_MEM_0				; y2, y1, x1, x3, (x2-x1), (y1-y3)
				db		FP_MULTIPLY					; y2, y1, x1, x3, (x2-x1)(y1-y3)
				db		FP_ST_MEM_1					; y2, y1, x1, x3, (x2-x1)(y1-y3)
				db		FP_DELETE					; y2, y1, x1, x3
				db		FP_SUBTRACT					; y2, y1, (x1-x3) 
				db		FP_ST_MEM_0					; y2, y1, (x1-x3)
				db		FP_DELETE					; y2, y1
				db		FP_SUBTRACT					; (y2-y1)
				db		FP_GET_MEM_0				; (y2-y1), (x1-x3)
				db		FP_MULTIPLY					; (y2-y1)(x1-x3)
				db		FP_GET_MEM_1				; (y2-y1)(x1-x3), (x2-x1)(y1-y3)
				db		FP_EXCHANGE					; (x2-x1)(y1-y3), (y2-y1)(x1-x3)
				db		FP_SUBTRACT					; (x2-x1)(y1-y3)-(y2-y1)(x1-x3)
				db		FP_GET_MEM_2				; (x2-x1)(y1-y3)-(y2-y1)(x1-x3), (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_DIVISION					; (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_DUPLICATE				; (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_LESS_ZERO				; (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), (0/1)
				db		FP_JUMP_TRUE, 5				; Jump to end if less than 0
				db		FP_STK_ONE					; (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1), 1
				db		FP_EXCHANGE					; 1, (x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1)
				db		FP_SUBTRACT					; 1-((x2-x1)(y1-y3)-(y2-y1)(x1-x3) / (y4-y3)(x2-x1)-(x4-x3)(y2-y1))
				db		FP_LESS_ZERO				; (<0)
				db		FP_END

				call	ROM_FP_TESTZERO
				ccf

				ret

;-----------------------------------------------------------

DrawDebug:
				; Draw Line 1
				ld		a, (Point1_EndX)
				call	ROM_STACK_A
				ld		a, (Point1_StartX)
				ld		(SVAR_COORDS_X), a		; Remember the starting X point
				call	ROM_STACK_A

				; Get the length in floating point
				rst		$28
				db		FP_SUBTRACT
				db		FP_END

				ld		a, (Point1_EndY)
				call	ROM_STACK_A
				ld		a, (Point1_StartY)
				ld		(SVAR_COORDS_Y), a		; Remember the starting Y point
				call	ROM_STACK_A

				; Get the length in floating point
				rst		$28
				db		FP_SUBTRACT
				db		FP_END

				call	ROM_DRAW_LINE

				; Draw Line 2
				ld		a, (Point2_EndX)
				call	ROM_STACK_A
				ld		a, (Point2_StartX)
				ld		(SVAR_COORDS_X), a		; Remember the starting X point
				call	ROM_STACK_A

				; Get the length in floating point
				rst		$28
				db		FP_SUBTRACT
				db		FP_END

				ld		a, (Point2_EndY)
				call	ROM_STACK_A
				ld		a, (Point2_StartY)
				ld		(SVAR_COORDS_Y), a		; Remember the starting Y point
				call	ROM_STACK_A

				; Get the length in floating point
				rst		$28
				db		FP_SUBTRACT
				db		FP_END

				call	ROM_DRAW_LINE

				ret

;-----------------------------------------------------------
; Variables
;-----------------------------------------------------------

NoCollisionString:
				db		"No "
CollisionString:
				db		"Collision"
CollisionStringEnd:

Point1_StartX:	db		0
Point1_StartY:	db		0
Point1_EndX:	db		0
Point1_EndY:	db		0

Point2_StartX:	db		0
Point2_StartY:	db		0
Point2_EndX:	db		0
Point2_EndY:	db		0

;-----------------------------------------------------------
				
				END Start


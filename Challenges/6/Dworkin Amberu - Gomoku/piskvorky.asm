;  pasmo -d piskvorky.asm piskvorky.bin > test.asm ; ./bin2tap piskvorky.bin; ls -l piskvorky.bin
 
PROGSTART 		EQU	$C400		 ; 50176
ORG PROGSTART


PLAYER_COLOR	EQU	1*8
AI_COLOR		EQU	2*8
MASK_COLOR		EQU	$38

; Start game from basic
; RANDOMIZE USR 50369 (0xC4C1) = progStart + 193 (+ $00C1)

; ----------------------------------------------------
; Vstup: 	HL adresa kurzoru
;		A priznaky posunu
; Vystup:	pokud neni stisknuto FIRE tak zmeni jen registry AF,HL

;	4	3	2	1	0
;	F(5)	↑(4)	↓(3)	→(2)	←(1)	Sinclair 1 (Sinclair left)
MOVE:
; P_LEFT:
	PUSH	BC
	PUSH	DE
	
	LD	BC,$001F
	RRCA					; nastavi carry
	LD	D,A				; maska

	LD	A,L
	SBC	A,B
; P_RIGHT:
	SRL	D				; nastavi carry
	ADC	A,B
	
	AND	C				; orezani do 0..31 pokud pretekl/podtekl
	XOR	L
	AND	C
	XOR	L
	LD	L,A

; P_DOWN:
	SRL	D
	JR	nc,P_UP
	ADC	HL,BC
P_UP:
	SRL	D
	JR	nc,P_FIRE
	SBC	HL,BC
P_FIRE:

; 57 0101 0111 +3 -> 5A 0101 1010
; 58 0101 1000
; 59 0101 1001
; 5A 0101 1010
; 5B 0101 1011 -3 -> 58 0101 1000

	LD	A,H
	CP	$57
	JR	nz,P_NO_UNDERFLOW		; nepodtekl
	LD	H,$5A				; Y max
P_NO_UNDERFLOW:
	CP	$5B
	JR	nz,P_NO_OVERFLOW		; nepretekl
	LD	H,$58				; Y min
P_NO_OVERFLOW:

	SRL	D
	
	POP	DE
	POP	BC
	RET	nc				; pokud neni stisknuto FIRE tak zmeni jen registry A,HL

	LD	A,(HL)
	OR	A
	RET	nz				; neprepisujeme kameny
	LD	(HL),PLAYER_COLOR		; PLAYER_COLOR = 2

; Zjednodusene nalezeni nejlepsiho tahu
; Find_best:
	LD	HL,$5800
	LD	C,L				; = 0 hodnota nejlepsi pozice, $FF = konec hry, existuje rada 5 kamenu
	PUSH	HL				; souradnice nejlepsi pozice

BRAIN_LOOP:


; ------------------------------------
; Vystup:	ixh
; Zmeni:	IX, AF, DE
; COUNT_VALUE:	
	LD	IXH,0				; vynulujeme hodnotu aktualni pozice
	LD	DE,DATA_DIRECTION-1
CV_LOOP:
	INC	DE
	
; "zpetny chod" na okraj usecky v jejimz stredu je testovana pozice
	PUSH	HL				; na zasobnik adresu zkoumane pozice, protoze ji budeme menit jak prochazime usecky
	LD	B,5
EL_TO_EDGE:
	LD	A,(DE)
	CALL	MOVE				;
	DJNZ	EL_TO_EDGE
	
	INC	DE
; prepnuti do stinovych registru
	EXX

; ------------------------------------
; Vstup:	shadow nothing, HL = cursor address, IYH value address, (DE) direction, C best value, HL on stack
; Zmeni:	IX, AF, maybe C = $ff
; EXPLORE_LINE:
	
; inicializace smycky
		LD	BC,$0900		; B = citac, C = nalezeny kamen
		LD	HL,$0010		; hl hodnota souvisle rady, dame bonus pro ; dame bonus pro xxxx_ xxx._ xx.._ x..._
		LD	D,C			; = 0 hodnota linie
		LD	E,C			; = 0 prazdnych
		LD	IXL,C			; = 0 delka rady

EL_LOOP:
		INC	IXL			; zvedneme delku rady

	EXX
	; navrat do "normalnich" registru
	LD	A,(DE)			; nastaveni smeru
	CALL	MOVE		
	LD	A,(HL)			; 
	AND	MASK_COLOR			; chceme jen barvu PAPER
	EXX
		JR	nz,EL_FOUND_STONE

; ---------------
; EL_EMPTY:
	
		INC	E			; prodlouzime radu prazdnych
		ADD	HL,HL			; bonus za stred

		LD	A,B			; 
		CP	5
		JR	z,EL_NEXT		;

		ADD	HL,DE			; H = H + D, v L a E (pocet prazdnych) je "smeti" jehoz soucet nikdy nepretece pres bajt. Pokud se sejdou jednickove bity tak je L nizke. 
		LD	D,H
	
		LD	HL,$0010		; dostane bonus i pro priste
		JR	EL_NEXT	

; ---------------
EL_FOUND_STONE:				; A je nenulove
		CP	C			; shodne kameny?
		JR	z,EL_IDENTIC

		INC	C
		DEC	C			; pokud tam byla 0 mame prvni kamen
		LD	C,A			; ulozime novy kamen
		JR	z,EL_IDENTIC	; prvni kamen, jinak by to blblo pri rade ._x. udelalo by to .x.

; ---------------
; EL_DIFFERENT:
		CALL	ADD_VALUE_SERIES
	
		LD	HL,$0008
		LD	D,H

		INC	E			; 
		LD 	IXL,E			; delka nove rady = prazdnych + 1 kamen
		DEC	E
		JR	z,EL_IDENTIC
	
		ADD	HL,HL			; dame bonus 2x protoze zacal prazdnym

; ---------------
EL_IDENTIC:

		LD	E,0			; vymazeme radu prazdnych
		ADD	HL,HL
		ADD	HL,HL
	
		LD	A,H
		CP	$20
		JR	c,EL_NEXT
	
; Nalezena rada 5 kamenu (asi)
		EX	(SP),HL		; do HL adresa stredu zkoumane usecky
		LD	A,(HL)
		OR	A			;
		JR	z,EL_5_NOT_FOUND
; Fakt nalezena
		SET	6,(HL)		; zesvetlime kamen
	EXX
	LD	C,$FF				; Existuje_rada_5_kamenu = True
	EXX
EL_5_NOT_FOUND:
		EX	(SP),HL		; vratime jak to bylo

EL_NEXT:
		DJNZ	EL_LOOP
	
		ADD	HL,HL			; dame bonus pro _xxxx _.xxx _..xx _...x
		CALL	ADD_VALUE_SERIES
	
; end Explore_line --------------------------------------------
	EXX
	
	POP	HL				; obnovime pozici pred zkoumanim dalsiho smeru
	LD	A,(DE)			; posledni je 1
	DEC	A
	JR	nz,CV_LOOP

; end Count_value ----------------------------------------------

	LD	A,(HL)
	OR	A
	JR	nz,B_NEXT			; pokud je na pozici kamen tak uz vse ignorujeme a deme dal, test na existenci rady 5 kamenu uz probehl

	LD	A,IXH
	CP	C				; porovname s nejlepsim
	JR	c,B_NEXT			; pokud zname lepsi tak ignorujeme

; aktualne nejlepsi pozice
	POP	DE				; vytahneme nejlepsi a zahodime
	PUSH	HL				; ulozime lepsi
	LD	C,A				; nejlepsi hodnota je ulozena v C
B_NEXT:
	INC	HL
	LD	A,$5B				; $5800 + 3 * 256 = $5800 + $0300
	CP	H
	JP	nz,BRAIN_LOOP

	INC	C				; Existuje rada 5 kamenu == $FF -> $00
	
	POP	HL				; vytahneme nejlepsi ze zasobniku
	LD	(HL), AI_COLOR		;

	RET	nz				;
	LD	(HL),C			; = 0, zmensime pravdepodobnost ze 1/50 vteriny bude videt pixel navic nez smazem obrazovku
						; neni to korektni protoze teoreticky muzeme mit v HL uz obsazenou pozici pokud je $5800 uz rada peti
; propadnuti na Repeat_game


; --------------------------------
REPEAT_GAME:
	POP	HL				; vytahneme nepouzitou adresu navratu pro ret

NEW_GAME:
; clear screen
	LD	HL,$4000			; 3
	LD	A,$5B				; 2
CLEAR_LOOP:
	LD	(HL),$00			; 2
	INC	HL				; 1
	CP	H				; 1
	JR	nz,CLEAR_LOOP		; 2

; umistime na stred a polozime kamen AI
	LD	HL,$598F
	LD	(HL),AI_COLOR		
					
READ_INPUT:
	LD	E,(HL)
	LD	(HL),$B8			; 

	LD	BC,0XF7FE			;
	IN	A,(C)				;
	CPL
	CP	D
	LD	D,A
	
	LD	(HL),E			; vratim puvodni
	
	CALL	nz,MOVE	
	JR	READ_INPUT


; -------------------------------
ADD_VALUE_SERIES:

		LD	A,IXL			; delka rady
		CP	$06			; je tam pricten uz i odlisny kamen
		RET	c			; pokud ma rada i s mezerama delku kratsi jak 5 tak nema zadnou hodnotu

		ADD	HL,DE			; H = H + D, v L a E (pocet prazdnych) je "smeti" jehoz soucet nikdy nepretece pres bajt. Pokud se sejdou jednickove bity tak je L nizke. 
		LD	D,H
		ADD	IX,DE			; IXH = IXH + D, IXL si zaneradime souctem puvodni delky rady s poctem jeho prazdnych poli, ale bude se menit

		RET


;	4	3	2	1	0
;	F(5)	↑(4)	↓(3)	→(2)	←(1)	Sinclair 1 (Sinclair left)
DATA_DIRECTION:
DB	9,6,10,5,8,4,2,1			; posledni je cislo 1! Pouzito zaroven jako zarazka

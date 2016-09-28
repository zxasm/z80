	device zxspectrum48

	org	$c000
carx	db	0
roadx	db	0
gameframe	db	0
roadw	db	0

    org $c100
score	db	0

	org	$8000
numbers
    db	%11101011	;0
    db	%10101010	;1
    db	%11011011	;2
    db	%01110111	;3
    db	%10111101	;4
    db	%11100111	;5
    db	%10101111	;6
    db	%11010101	;7
    db	%11100111	;8
    db	%11110101	;9

start
.menu
	ld	a,%10111111
	in	a,(254)
	rra
	jr	c,.menu

	ld	hl,carx
	ld	(hl),15	;carx
	inc	l
	ld	(hl),8	;roadx
	ld	l,roadw&255
    ld 	(hl),12
    xor	a
    call cls

    ld	hl,score
.clrlp ld	(hl),a
    inc	l
    jr	nz,.clrlp

    ld	a,15
    ld	(.lp+1),a
        
.lp
    ld b,15
.lop  halt
	ld	a,($c300)
	xor	24
	ld	($c300),a
	and	24
	out	(254),a

    djnz .lop

	ld	hl,$5ADF
	ld	de,$5AFF
	ld	bc,$2E0
	lddr
	ld  hl,$5800
	ld	bc,31
	ld	a,4*8
	call fill
	ld	a,(roadx)
	ld	l,a
	ld	bc,(roadw)
	ld	b,0
	ld	a,7
	call fill
	ld	hl,(carx)
	ld	h,$5a
	ld	a,(hl)
	cp	4*8
	jp	z,.menu
	ld	(hl),2*8
	
	ld	a,%11011111
	in 	a,(254)
	ld	c,a
	ld	a,l
	rr	c
	jr	c,.nr
	cp	31
	jr	z,.nr
	inc	l
.nr	rr	c
	jr	c,.nl
	or	a
	jr	z,.nl
	dec	l
.nl	ld	a,l
	ld	(carx),a
	
	ld	a,r
	ld	b,a
.del	djnz .del
		
	ld	a,r
	rlca
	rlca
	rlca
	and	1
	add	a,a
	dec	a
	ld	h,a
.ss	
	ld	bc,(roadx)
	ld	a,31
	sub	c
	ld	b,a
	ld	a,(roadx)
	add	a,h
	or	a
	jr	z,.skp
	cp	b
	jr	z,.skp
	ld	(roadx),a
.skp

    ld	hl,score+1
    ld	a,9
.sl inc	(hl)
    cp	(hl)
    jr	nc,.ok
    ld	(hl),0
    inc	l
    jr	nz,.sl
.ok

	ld	de,$4000
	ld	hl,score+9
.sc
    ld c,(hl)
    ld	b,numbers/256
    ld	a,(bc)
	ld	b,4
.bl	ld	c,a
	and	$c0
	ld	(de),a
	ld	a,c
	rla
	rla
    inc d
	djnz .bl
	ld	d,$40
	inc	e  

	dec	l
	jr	nz,.sc

	ld	hl,gameframe
	inc	(hl)
	jr	nz,.skp1

	inc	l	; roadw
	ld	a,(hl)
	cp	4
	jr	nz,.skp2
	ld	a,(.lp+1)
	dec	a
	jr	z,.skp1
	ld	(.lp+1),a
	db	62
.skp2
	dec	(hl)
.skp1
	jp	.lp

cls	ld	hl,$5800
	ld	bc,$2ff
fill
	ld	d,h
	ld	e,l
	inc	de
	ld	(hl),a
	ldir
	ret


last
	savebin "test.bin",$8000,last-$8000
	savesna "test.sna",start

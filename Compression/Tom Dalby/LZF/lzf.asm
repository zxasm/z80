	;;
	;; ========================================================================
	;; LZF compressor for the z80 microprocessor (217bytes)
	;; input hl=memory to compress
	;; 	 de=size of memory to compress
	;; 	 bc=place to store the compression
	;; uses simple greedy parsing due to limitations of the machine
	;; slow to compress due to scanning of full dictionary every time
	;; ========================================================================
_lzf:
	ld (_lzf_start+1),hl	; 16t - put compression start into later code
	add hl,de				; 11t - resets the carry flag as well
	ld (_lzf_end1+1),hl		; 16t - put end into later code for checks
	ld (_lzf_end2+1),hl		; 16t
	ld (_lzf_end3+1),hl		; 16t	
	sbc hl,de				; 15t - restore hl
	ld d,b					; 4t
	ld e,c					; 4t
	inc de					; 6t - de=bc+1, bc=control byte, de=byte store
	call _lzf005			; 17t
	ld a,(bc)				; 7t - get last control byte
	cp 255					; 7t - if control byte already $ff then end marker in place already
	ret z					; 11/5t
	ld b,d					; 4t
	ld c,e					; 4t - bc=de
	ld a,255				; 7t - if not put one in
	ld (de),a				; 7t	
	ret						; 10t
	;; 
	;;  sort out the control byte for literals
_lzf000:	
	ld a,(bc)				; 7t - get control byte
	inc a					; 4t - add one to counter
	cp 32					; 7t - at max?
	jr nz,_lzf010			; 12/7t - if at max start a new control byte
	ld b,d					; 4t
	ld c,e					; 4t - move bc to current byte store pos
	inc de					; 6t - +1 to move to byte store past control byte
_lzf005:	
	xor a					; 4t - reset a to 0 which is 1 literal, 0=1 literal
_lzf010:	
	ld (bc),a				; 7t - put back in mem
	;;
	;; put literal in store
	ld a,(hl) 				; 7t - get screen byte
	ld (de),a 				; 7t - load into byte store
	inc de 					; 6t - next mem
	;;
	;; set-up search starting pos
_lzf020:	
	inc hl 					; 6t - move start scr check pos on one	
	;;
	;; check if at the end
	push de					; 11t
_lzf_end1:
	ld de,0000	    		; 10t - end
	xor a					; 4t - reset carry and reset a
	sbc hl,de				; 15t - this will set the zero flag
	add hl,de				; 11t - restore hl and leave zero flag alone
	pop de					; 10t
	ret z					; 11/5t
	;;
	;; check for match, hl=start scr check pos
	push bc 				; 11t - preserve control store pointer (sp=control store)
	push de 				; 11t - preserve byte store pointer (sp=byte store)
;;
;;
	push hl					; 11t - store hl
	ld de,7936				; 10t - max size of offset is 7936
	or a					; 4t - clear carry
	sbc hl,de				; 15t - get new dictionary start
	;;
	;; check if new dictionary start < lowest start then shift up to lowest start
_lzf_start:	
	ld de,0000				; 10t - lowest start possible
	jr c,_lzf025			; 12/7t - if carry from previous subtraction then gone below zero so just use lowest
	sbc hl,de				; 15t - if dictionary start < lowest start then use lowest start
	jr c,_lzf025			; 12/7t - if a carry then use lowest start instead
	add hl,de				; 11t - if no carry then use new dictionary start
	ex de,hl				; 4t - de now hl
_lzf025:	
	pop hl					; 10t
	ld b,a					; 4t - clear max length
	;;
	;; bc=offset, de=dictionary start, hl=start scr check pos
_lzf030:		
	ld c,a					; 4t - clear length counter
	push hl					; 11t - store start scr check pos (sp=start scr check pos)
	push de 				; 11t - store dictionary start (sp=dictionary start)
	;;
	;; do the check
_lzf040:	
	ld a,(de) 				; 7t - get byte from dictionary
	cp (hl) 				; 7t - check against scr check pos
	jr nz,_lzf070 			; 12/7t - jump if byte mismatch
	;;
	;; match found
	inc c 					; 4t - increase counter
	jr nz,_lzf060 			; 12/7t - if length=0, then at maximum of 256 so stop searching
	;; 
	;; small speed up as if at maximum no better match could possibly be found, exit keeping hl as last scr check pos
	ld a,c					; 4t
	ld (_lzf120+1),hl		; 16t - store end of last match pos
	pop de					; 10t - bring back current dictionary start into de (sp=start scr check pos)
	pop hl					; 10t - bring back start scr check pos into hl (sp=byte store)
	jr _lzf115				; 12t - jump into match>3 code
	;;
	;; keep checking
_lzf060:	
	inc de 					; 6t - move to next dictionary position
	inc hl 					; 6t - next scr pos to check
	;;
	;; if end of screen stop checking
	push de					; 11t
_lzf_end2:
	ld de,0000	    		; 10t
	xor a					; 4t - reset carry
	sbc hl,de				; 15t - this will set the zero flag
	add hl,de				; 11t - restore hl and leave zero flag alone
	pop de					; 10t - restore de
	jr nz,_lzf040			; 12t - if not at end just loop
	;; 
	;; no match or end of screen
_lzf070:
	pop de 					; 10t - bring back current dictionary start (sp=start scr check pos)
	ld a,c					; 4t - length into a for check
	cp 3					; 7t - is match >=minsize
	jr c,_lzf080			; 12/7t - <minsize so move on
	;;
	;; check if largest & if so store b=match size,hl=last scr check pos & de=dictionary start
	ld a,b		 			; 4t - a=last max
	cp c					; 4t
	jr nc,_lzf080			; 12/7t - if last>new then do nothing
	ld b,c					; 4t - store new max in b
	ld (_lzf110+1),de		; 20t - store dictionary start into later code	
	dec hl					; 6t - back one as last wasn't a match	
	ld (_lzf120+1),hl		; 16t - store end of last match pos
	;;
	;; if end of last match=end then stop
	push de		  			; 11t
_lzf_end3:
	ld de,0000	    		; 10t
	dec de					; 6t - at the end?
	or a					; 4t - reset carry
	sbc hl,de				; 15t - this will set the zero flag
	add hl,de				; 11t - restore hl and leave zero flag alone
	pop de					; 10t
	jr nz,_lzf080			; 12/7t - if not at end stop
	pop hl					; 10t
	ld a,b		 			; 4t - a=last max	
	jr _lzf115				; 12t
	;;
	;; keep moving the window along till checked all positions for optimal pattern size
_lzf080:	
	pop hl 					; 10t - bring back start scr check pos (sp=byte store)
	inc de 					; 6t - shift dictionary window along one
	;;
	;; check if caught up
	xor a					; 4t - clear carry & next counter
	sbc hl,de				; 15t
	add hl,de				; 11t - restore hl
	jr nz,_lzf030			; 12/7t (6b,42t)
	;;
	;; dictionary has caught up with scr check pos so bring back max and check if there was a large enough match
	ld a,b					; 4t - max length 
	or a					; 4t - has the match routine return >0?
	jr nz,_lzf110			; 12/7t - if >minsize then a match, otherwise just copy
_lzf160:	
	pop de 					; 10t - bring back byte store (sp=control store)
	pop bc 					; 10t - bring back bit store (sp clear)
	jp _lzf000 				; 10t - store new literal, no need to clear max as already 0, hl=start scr pos
	;; 
	;; store pattern routine a=length
_lzf110:	
	ld de,0000				; 10t - de=dictionary start, hl=start scr check pos
_lzf115:	
	and a					; 4t - clear carry
	sbc hl,de				; 15t - hl-de
 	ld b,h					; 4t
 	ld c,l 					; 4t - bc now the offset
	dec bc					; 6t - offset-1
	pop de 					; 10t - bring back byte store into de (sp=control store)
	pop hl					; 10t - bring back control store into hl (sp=free)
	ex af,af'				; 4t - alta
	ld a,(hl)				; 7t - get control store byte
	cp 255					; 7t - is it clear?
	jr z,_lzf180			; 12/7t - if 255 then free otherwise already in use for literals need to move to byte store
	ld h,d					; 4t
	ld l,e					; 4t - move hl to current byte store pos
	inc de					; 6t - move de to next byte as before
_lzf180:	
	ex af,af'				; 4t - norma
	sub 2					; 7t - 3->1, 9->7
	cp 7					; 7t - if >=7 then need an extra byte
	jr c,_lzf190			; 12/7t - no need for extra byte
	sub 7					; 7t - take away 7
	ld (de),a				; 7t - load length-7 into de
	inc de					; 6t - move de on one
	ld a,7					; 7t - set to 7 for next part
_lzf190:	
	rrca					; 4t
	rrca					; 4t
	rrca					; 4t - move length to last 3bits
	add a,b					; 7t - bring in offset hi byte
	ld (hl),a				; 7t - put into hl
	ld a,c					; 4t - offset low byte
	ld (de),a				; 7t - load offset low byte
	inc de					; 6t
	ld b,d					; 4t
	ld c,e					; 4t - move control store to new byte store pos
	inc de					; 6t - de=byte store, bc=control store
_lzf120:	
	ld hl,0000				; 10t - hl=last scr check pos loaded from elsewhere
	;; 
	;; clear max & new control bit
	ld a,255				; 7t
	ld (bc),a				; 7t - clear next control byte	
	jp _lzf020 				; 10t - back up to top and onto next using last scr check pos as next start
_lzfend:
; ==========================================================
; Simple ZX Spectrum heap memory manager
;
; (c) 2016 Peter Hanratty
; Email: peter.neil.hanratty@gmail.com
;
; Free for non-commercial use with the following conditions:
; - Credit where credit is due, do not remove this notice or
;   any other information identifying the author
; - Any additions or modifications should be clearly marked
;   with the contributor's name
; - Please include an honourable mention in any projects 
;   which use this lib
; ==========================================================
;
; Functions:
; ----------------------------------------------------------
;
; HEAP_INIT - Call this before doing anything else
;   HL = Address for allocation table
;        (NOTE: table is unbounded, beware of overruns)
;   DE = Start of heap, all memory allocated from this block
;   BC = Heap size
;
; HEAP_ALLOC - Allocates a block of memory from the heap
;   BC = Block size
;   Returns: Pointer address in HL (or 0000H if unsuccessfu)
;
; HEAP_FREE - Free previously allocated block
;             (if found in table, otherwise do nothing)
;   HL = Pointer to block
;
; HEAP_MEMSET - Fill a block of memory with a byte value
;   HL = Pointer to memory
;   BC = Number of bytes to fill
;   A  = Byte value
;
; ==========================================================

HEAP_ALLOCTABLE:

; Format: Unbounded dense list
; [2]     Heap start address
; [2(n)]  eassssss ssssssss (e=end, a=allocated, s=size)

; Pointer to allocation table (above label serves as address)
DW     FFFFH

; ==========================================================

HEAP_INIT:
; Initialise memory manager
; HL = allocation table
; DE = heap start
; BC = heap size

LD     (HEAP_ALLOCTABLE), HL
LD     (HL), E
INC    HL
LD     (HL), D
INC    HL
LD     (HL), C
INC    HL
LD     A, B       ; Set a single free block with BC
AND    3FH        ; as its size and flag as last
OR     80H
LD     (HL), A 
RET

; ----------------------------------------------------------

HEAP_ALLOC:
; Allocate pointer and return in HL
; BC = Size

LD     IY, (HEAP_ALLOCTABLE)
LD     D, (IY+1)  ; Read heap start address
LD     E, (IY+0)  ; Into DE

HEAP_ALLOC_FIRSTFREE:
INC    IY         ; Next block
INC    IY
LD     L, (IY+0)  ; Read block info
LD     A, (IY+1)  ; into HL
AND    3FH
LD     H, A       ; Block size only in HL
BIT    6, (IY+1)  ; Allocated?
JR     NZ, HEAP_ALLOC_NEXTBLOCK
PUSH   HL
SBC    HL, BC     ; Big enough?
POP    HL
JR     NC, HEAP_ALLOC_FOUNDFREE
BIT    7, (IY+1)  ; Was it the last block (remaining free space)?
JR     NZ, HEAP_ALLOC_NOROOM

HEAP_ALLOC_NEXTBLOCK:
ADD    HL, DE     ; Calculate address of next block
EX     DE, HL
JR     HEAP_ALLOC_FIRSTFREE

HEAP_ALLOC_FOUNDFREE:
LD     A, (IY+1)  
SBC    HL, BC     ; Leftover bytes in HL
SET    6, B       ; Flag block as allocated
LD     (IY+0), C  ; Write new block size
LD     (IY+1), B
BIT    7, A       ; Was it the last block (remaining free space)?
JR     Z, HEAP_ALLOC_INSERT
SET    7, H       ; Append new end block with remaining free space
LD     (IY+2), L
LD     (IY+3), H
EX     DE, HL
RET

HEAP_ALLOC_INSERT:
LD     A, L       ; Still need to deal with any leftover free space
OR     H
JR     NZ, HEAP_ALLOC_NEWBLOCK
EX     DE, HL
RET               ; Return if none

HEAP_ALLOC_NEWBLOCK:
PUSH   DE
LD     BC, 0002H  ; Else we have to shuffle everything else along...
PUSH   HL
PUSH   IY
POP    HL
INC    HL         
INC    HL         
INC    HL         ; Make sure we're looking at the high address bytes

HEAP_ALLOC_FINDLAST:
BIT    7, (HL)
JR     NZ, HEAP_ALLOC_SHUFFLE
INC    HL
INC    HL
INC    BC
INC    BC
JR     HEAP_ALLOC_FINDLAST

HEAP_ALLOC_SHUFFLE:
LD     D, H
LD     E, L
INC    DE
INC    DE
LDDR
EX     DE, HL
POP    DE
LD     (HL), D     ; Insert new free block
DEC    HL
LD     (HL), E
POP    HL
RET

HEAP_ALLOC_NOROOM:
LD     HL, 0000H
RET

; ----------------------------------------------------------

HEAP_FREE:
; Free memory pointed to by HL (if in table)

LD     IY, (HEAP_ALLOCTABLE)
LD     D, (IY+1)   ; Read heap start address
LD     E, (IY+0)
EX     DE, HL

HEAP_FREE_FINDPTR:
INC    IY
INC    IY
LD     C, (IY+0)
LD     A, (IY+1)
AND    3FH
LD     B, A       ; Store block size only in BC
LD     A, D
CP     H          ; Compare pointer with current offset in heap area
RET    C          ; Exit if past pointer address
JR     NZ, HEAP_FREE_NEXTPTR
LD     A, E
CP     L
JR     Z, HEAP_FREE_FOUNDPTR

HEAP_FREE_NEXTPTR:
BIT    7, (IY+1)  ; Last block?
RET    NZ         
ADD    HL, BC
JR     HEAP_FREE_FINDPTR

HEAP_FREE_FOUNDPTR:
RES    6, (IY+1)  ; clear allocated flag
PUSH   IY
POP    HL
LD     DE, (HEAP_ALLOCTABLE)
XOR    A   
LD     C, A
LD     (HEAP_FREE_MERGEUP_REWRITE-1), A     ; Zero offset
SBC    HL, DE     ; Look for previous free blocks to merge with
JR     Z, HEAP_FREE_MERGEUP_START
SRL    H          ; Dvide by 2
RR     L
LD     B, L       ; NOTE: This will cause problems with any more than 255 blocks

HEAP_FREE_MERGEDOWN:
DEC    IY
DEC    IY
BIT    6, (IY+1)
JR     NZ, HEAP_FREE_MERGEDOWN_FOUNDALLOC
DJNZ   HEAP_FREE_MERGEDOWN
JR     HEAP_FREE_MERGEUP_START

HEAP_FREE_MERGEDOWN_FOUNDALLOC:
INC    IY
INC    IY

HEAP_FREE_MERGEUP_START:
PUSH   IY         ; Merge all subsequent free blocks including last
LD     H, (IY+1)
LD     A, (IY+0)
AND    3FH
LD     L, A
XOR    A
LD     B, A
LD     c, A

HEAP_FREE_MERGEUP:
INC    IY
INC    IY
JR     HEAP_FREE_MERGEUP_REWRITE ; Code rewrite - stop merging when allocated
                                 ; block found (still need to shuffle the list)
HEAP_FREE_MERGEUP_REWRITE:
LD     A, (IY+1)                            ; 3
BIT    6, A                                 ; 2
JR     Z, HEAP_FREE_MERGEUP_ADDSIZE         ; 2
LD     A, 23  ; New offset                  ; 2
LD     (HEAP_FREE_MERGEUP_REWRITE-1), A     ; 3
JR     HEAP_FREE_MERGEUP_SKIPADD            ; 2

HEAP_FREE_MERGEUP_ADDSIZE:
AND    3FH                                  ; 2
LD     D, A                                 ; 2
LD     E, (IY+0)                            ; 3
ADD    HL, DE                               ; 1
INC    C                                    ; 1

HEAP_FREE_MERGEUP_SKIPADD:                  ; = 23
INC    B
BIT    7, (IY+1)                            ; Last block?
JR     Z, HEAP_FREE_MERGEUP
POP    DE
EX     DE, HL
LD     (HL), E                              ; Write new block size
INC    HL
LD     (HL), D
LD     A, B
SUB    C                                    ; Mereged all the way to the end?
JR     NZ, HEAP_FREE_SHUFFLE
SET    7, (HL)                              ; Set end flag
RET                                         ; and exit

HEAP_FREE_SHUFFLE:
DEC    C                                    ; If no merges (single block freed),
RET    M                                    ; no shuffle necessary
INC    C
INC    HL
LD     D, H
LD     E, L
LD     A, B
LD     B, 0
ADD    HL, BC
ADD    HL, BC
LD     C, A
SLA    C                                    ; Multiply by 2
RL     B
LDIR
RET

; ----------------------------------------------------------

HEAP_MEMSET:
; Fill memory with specified value
; HL = pointer
; BC = size
; A = value

DEC    BC
RET    M      ; Return if 0 bytes
INC    BC
LD     (HL), A
DEC    BC
RET    Z      ; Return if only 1 byte
LD     D, H
LD     E, L
INC    DE
LDIR          ; Fill the rest
RET

; ==========================================================

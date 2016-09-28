;Asteroidbelt

;Travel your ship trough the asteroidbelt.

;Controls:
;(Re)Startgame : 5, T, Y, G, H, B, N
;Left: Q, A, Shift
;Right: W, S, Z




?   * TORNADO *                                                 
; order of nrs going down                                       
                                                                
           ORG  49152                                           
           DUMP 49152                                           
                                                                
; characterset: ship, nr in reverse order, asteroid             
                                                                
ship       DEFB %00011000         ; ship                        
           DEFB %00100100                                       
           DEFB %01000010                                       
           DEFB %10011001                                       
           DEFB %11100111                                       
                                                                
           DEFB %00111100         ; 9                           
           DEFB %00100100                                       
           DEFB %00111100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
                                                                
           DEFB %00111100         ; 8                           
           DEFB %00100100                                       
           DEFB %00111100                                       
           DEFB %00100100                                       
           DEFB %00111100                                       
                                                                
           DEFB %00111100         ; 7                           
           DEFB %00000100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
                                                                
           DEFB %00111100         ; 6                           
           DEFB %00100000                                       
           DEFB %00111100                                       
           DEFB %00100100                                       
           DEFB %00111100                                       
                                                                
           DEFB %00111100         ; 5                           
           DEFB %00100000                                       
           DEFB %00111100                                       
           DEFB %00000100                                       
           DEFB %00111100                                       
                                                                
           DEFB %00100100         ; 4                           
           DEFB %00100100                                       
           DEFB %00111100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
                                                                
           DEFB %00111100         ; 3                           
           DEFB %00000100                                       
           DEFB %00111100                                       
           DEFB %00000100                                       
           DEFB %00111100                                       
                                                                
           DEFB %00111100         ; 2                           
           DEFB %00000100                                       
           DEFB %00111100                                       
           DEFB %00100000                                       
           DEFB %00111100                                       
                                                                
           DEFB %00000100         ; 1                           
           DEFB %00000100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
           DEFB %00000100                                       
                                                                
           DEFB %00111100         ; 0                           
           DEFB %00100100                                       
           DEFB %00100100                                       
           DEFB %00100100                                       
           DEFB %00111100                                       
                                                                
rock       DEFB %00101100         ; rock                        
           DEFB %01011010                                       
           DEFB %10000010                                       
           DEFB %10011001                                       
           DEFB %01100110                                       
                                                                
; no game yet, but already 60 bytes "gone"                      
                                                                
score      EQU  64000             ; somewhere in RAM #nn00      
                                                                
; the start of the game, first time just read A from any port                                         
                                                                
wstart     IN   A,(254)           ; 1st read can be skipped 
           AND  16                ; start bit? 5 T Y G H B N    
           JR   NZ,wstart         ; next read all rows but 6-0  
                                                                
cls        LD   DE,23295          ; erase screen and attr
           LD   HL,score+7        ; score in RAM and ATTR mask
cls1       LD   A,87
           CP   D
           SBC  A,A
           AND  L                
           LD   (DE),A                         
           DEC  DE                                              
           BIT  6,D               ; out of RAM                  
           JR   NZ,cls1           ; only clear RAM-screen       
                                                                
clscore    DEC  L                                               
           LD   (HL),10           ; set char "0"                
           JR   NZ,clscore        ; clear all positions         
                                                                
; from above Z-flag set, from below possible collision          
; placing test here makes a relative jump possible              
; saves a byte in the code.                                     
                                                                
scroll     JR   NZ,wstart         ; test from dispship          
                                                                
           LD   BC,#BF80          ; 191 lines, right side       
                                                                
scr1       CALL field             ; calculate screen            
           EX   DE,HL             ; set destination             
           PUSH BC                ; save original linenumber    
           LD   A,B                                             
           SUB  6                 ; calculate from line         
onscreen   LD   B,A               ; set from or use leftscreen               
           CALL NC,field          ; calculate from address      
           LD   BC,16                                           
           LDIR                   ; copy the line down          
           POP  BC                ; fetch original lines        
           DJNZ scr1              ; do 'full' screen            
                                                                
           LD   B,3               ; set star on top             
                                                                
           LD   A,R               ; better rnd than without     
rnd        ADD  A,0               ; add seed                    
           LD   C,A                                             
           RRCA                                                 
           RRCA                                                 
           RRCA                                                 
           XOR  31                                              
           ADD  A,C                                             
           SBC  A,255                                           
           LD   (rnd+1),A         ; next seed                   
           OR   128               ; second half of screen only  
           LD   C,A                                             
                                                                
           LD   E,rock-#C000      ; pointer to rock-char        
           CALL disp              ; AT B,C char from DE         
                                                                
           LD   HL,score+7        ; unvisible number            
tens       LD   (HL),10           ; reset number to "0"         
           DEC  HL                ; increase from prev. counter 
           DEC  (HL)              ; "increase" score            
           JR   Z,tens            ; do carry to next position   
                                                                
           LD   L,6               ; point to visible score      
           LD   BC,#0330          ; AT for score                
scdisp     LD   A,(HL)            ; fetch char                  
           ADD  A,A               ; x2                          
           ADD  A,A               ; x4                          
           ADD  A,(HL)            ; x5                          
           LD   E,A               ; index calculated            
           PUSH HL                ; save scorepointer           
           CALL disp              ; display character           
           POP  HL                ; get scorepointer            
           DEC  HL                ; next pointer                
           LD   A,C                               
           OUT (254),A            ; engine sound              
           SUB  8                 ; due to -8 sound on/off 6x                              
           LD   C,A                                             
           JR   NC,scdisp         ; do all pointers             
                                                                
                                                                
;          XOR  A                 ; not needed, use other keys  
           IN   A,(254)           ; read QWERT, set above       
           RRA                    ; test left key
           JR   NC,xposship       ; C holds -8                  
           LD   C,8               ; set for right               
           RRA                    ; test right key
xposship   LD   A,200             ; get old xpos                
           JR   C,okmove          ; false key only              
                                                                
           ADD  A,C               ; do move                     
           CP   127               ; test in range               
           JR   NC,okmove         ; valid move                  
           SUB  C                 ; undo move                   
                                                                
okmove     LD   (xposship+1),A    ; save new xpos               
           LD   C,A               ; set x for screen            
           LD   B,192-5           ; ypos of ship                
           XOR  A                                               
           LD   E,A               ; charindex of ship           
           DEC  A                 ; 255 for test on collision   
prship     CALL dispship          ; show ship                   
                                                                
           HALT                   ; some delay for gameplay     
           HALT                                                 
                                                                
           JR   scroll            ; Z from dispship = no coll.  
                                                                
; almost full copy of #22b0 from the ROM                        
                                                                
field      LD   A,B                                             
           AND  A                 ; reset needed from scroll    
           RRA                                                  
           SCF                                                  
           RRA                                                  
           AND  A                                               
           RRA                                                  
           XOR  B                                               
           AND  #F8                                             
           XOR  B                                               
           LD   H,A                                             
           LD   A,C                                             
           RLCA                                                 
           RLCA                                                 
           RLCA                                                 
           XOR  B                                               
           AND  #C7                                             
           XOR  B                                               
           RLCA                                                 
           RLCA                                                 
           LD   L,A                                             
           RET                                                  
                                                                
disp       XOR  A                 ; no collisiontest            
dispship   LD   (col+1),A         ; set collision yes/no        
           CALL field             ; screenaddress               
dloop      LD   D,#C0             ; character highbyte          
           LD   A,(DE)            ; fetch char                  
           INC  E                 ; point to next               
           LD   D,(HL)            ; fetch screen                
           LD   (HL),A            ; set char                    
           OR   D                 ; something on screen         
           XOR  D                                               
           SUB  (HL)              ; take off new value          
col        AND  0                 ; the actual test             
           RET  NZ                ; collision ?                 
nohit      INC  H                 ; next row on screen          
           LD   A,H                                             
           AND  7                                               
           JR   NZ,dloop          ; fill char                   
           RET                    ; print done                  

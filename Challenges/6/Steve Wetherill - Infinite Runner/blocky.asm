                    ; infinite blocky jumper
                    ; by steve wetherill 2016

SCREEN      EQU     $4000 
ATTRIBS     EQU     $5800 
ATTRIBS_SIZE EQU    $300 

JUMP_STEPS  EQU     4 
LOWER_GROUND EQU    2 
UPPER_GROUND EQU    15 

SURFACE_COLOR EQU   $28 
SOLID_COLOR EQU     $20 
CLEAR_COLOR EQU     $00 
BADDY_COLOR EQU     $70 
DEAD_COLOR  EQU     $10 
WIN_COLOR   EQU     $20 

            .ORG    $8000 
            .ENT    $8000 

RESTART_POINT:      
            XOR     a 

                    ; clear attributes
            CALL    get_ldir_params 

            PUSH    hl ; points to attribs

            LD      (hl),a 
            LDIR    

            OUT     (254),a ; border black
            LD      (player_y+1),a ; reset player y position

            LD      bc,$080c ; b' = segment width, c' = initial position of ground
            LD      l,a ; l' = old position of ground
            LD      h,b ; h' = counter for progress bar

            EXX     
            LD      ix,32 ; ixl = initial loop delay before player is active
                    ; ixh = jump

MAIN_LOOP:          
            HALT    
            HALT    
            HALT    
            HALT    

                    ; erase player @ old position
            XOR     a 
            CALL    get_or_draw_player 

            OR      ixl 
            JR      z,DELAY_START 
            DEC     ixl 
DELAY_START:        

SET_GROUND:         
                    ; setup the ground (incomin
            EXX     ; swap to alt reg set
            LD      e,-2 ; default baddy spawn y is off screen
            XOR     ixl 
            JR      nz,set_ground_exit 

            DJNZ    spawn_baddy ; loop to exit if not done

            RRC     h 
            JR      nc,no_bump 

            EX      (sp),hl 
            INC     hl 
            EX      (sp),hl 

NO_BUMP:            
            LD      b,8 ; loop count (width of horizontal section)
            LD      a,l ; get restore point
            OR      a ; if z, no restore needed
            JR      z,no_gap 
            LD      c,l ; restore
            LD      l,0 ; flag no restore point
            JR      set_ground_exit ; done
NO_GAP:             
            LD      a,r 
            AND     15 ; low 4 bits zero
            JR      nz,no_gap2 ; if not, no gap generated
            LD      l,c ; set restore point
            LD      c,a ; zero out height
            JR      set_ground_exit ; done
NO_GAP2:            
            RRA     
            LD      a,c ; get current height
            JR      c,go_down ; carry set == go down
            CP      UPPER_GROUND ; check for top limit
            JR      z,set_ground_exit ; if at limit, we're done

            INC     c ; otherwise move up
            JR      set_ground_exit ; we're done
GO_DOWN:            
            CP      LOWER_GROUND ; check for bottom limit
            JR      z,set_ground_exit ; if at limit, we're done
            DEC     c ; move down
            JR      set_ground_exit 

SPAWN_BADDY:        
            LD      a,r 
            AND     15 
            JR      nz,set_ground_exit 
            ADD     a,b 
            CP      4 

            JR      nz,set_ground_exit 
            LD      e,c ; trigger baddy at this y coord

SET_GROUND_EXIT:    
            EXX     ; restore alt reg set

            EX      (sp),hl 
            LD      (hl),h 
            EX      (sp),hl 

                    ; scroll
            CALL    get_ldir_params 
            EX      de,hl 
            LDIR    

                    ; draw_line of incoming ground and enemies
            LD      hl,attribs+31 
            LD      de,32 
            LD      b,24 
DL0:                
            LD      a,b 
            EXX     
            CP      e ; e is spawn point for baddies
            JR      z,baddy 
            INC     a 
            CP      e 
            JR      nz,no_baddy 
BADDY:              
            LD      a,BADDY_COLOR 
            JR      dl2 

STILL_ALIVE:        
            LD      a,$78 
            CALL    get_or_draw_player 
            JR      main_loop 

NO_BADDY:           
            SUB     c 
            JR      nc,open_space 
            INC     a 
            JR      nz,not_surface 
            LD      a,SURFACE_COLOR 
            DB      $c2 ; jp nz swallows ld a,solid_color
                    ;            JR      dl2

NOT_SURFACE:        
            LD      a,SOLID_COLOR 
            JR      dl2 

OPEN_SPACE:         
            LD      a,CLEAR_COLOR 

DL2:                
            EXX     
            LD      (hl),a 
            ADD     hl,de 
            DJNZ    dl0 

            CALL    move_player 
            OR      a 
            JR      z,still_alive 

                    ; b == 0 from the djnz above!
            LD      a,2 ; border red
            OUT     ($fe),a 
            LD      a,DEAD_COLOR 

            CALL    get_or_draw_player 
DEAD_LOOP:          
            HALT    
            DJNZ    dead_loop 
            POP     hl 
            JP      restart_point 

                    ; never returns!

                    ; ================
                    ; preserves:
                    ; bc
                    ; bc', de', hl'
MOVE_PLAYER:        
            LD      a,ixl 
            SRA     a 
            JR      nz,normal_continue 

            CALL    get_or_draw_player 
                    ; relies on a == 0
            OR      c 
            RET     nz ; we've collided with something, game over

                    ; relies on d == 0 from get_player_position
            LD      e,32 
            ADD     hl,de 
                    ; relies on a == 0
            OR      (hl) 
            JR      z,not_grounded 

CHECK_JUMP:         
            XOR     a 
            IN      a,($fe) 
            CPL     
            AND     $1f 
            RET     z 

            LD      ixh,4 ; start jump

NOT_GROUNDED:       
            LD      a,ixh 
            OR      a 
            LD      a,(player_y+1) 
            JR      z,falling 
            SUB     ixh 
            DEC     ixh 
FALLING:            
            INC     a 
            CP      24 
            RET     z ; we fell off the bottom of the screen, game over

            LD      (player_y+1),a 

NORMAL_CONTINUE:    
            XOR     a 
            RET     

GET_OR_DRAW_PLAYER: 
                    ; entry
                    ; a: color to write @ player location
                    ; carry set means don't draw player just return hl
                    ; preserves
                    ; c
                    ; bc', de', hl'

            LD      hl,attribs+4 
            LD      b,32 
PLAYER_Y:           
            LD      de,0 ; smc
LOOP:               
            ADD     hl,de 
            DJNZ    loop 

            LD      c,(hl) 
            LD      (hl),a 
            RET     


GET_LDIR_PARAMS:    
                    ; entry
                    ; none
                    ; returns
                    ; hl -> attribs
                    ; de -> attribs+1
                    ; bc = length of color file - 1
                    ; preserves
                    ; af
                    ; af', bc', de', hl'

            LD      hl,attribs 
            LD      de,attribs+1 
            LD      bc,attribs_size-1 
            RET     



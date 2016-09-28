; -----------------------------------------------------------------------------
; Name:     TRAPIT
; Author:   Mike Daley
; Started:  12th May 2016
; Finished: 19th May 2016
;
; The idea of the game is to move the red player square around the screen leaving a
; trail of black squares. The player and the ball are unable to move through black
; squares. The player must trap the ball so that it cannot move. When the ball cannot
; move any more the players green progress bar at the top of the screen is increased
; and the level is reset.
;
; If the player gets into a position where they are stuck and cannot trap the ball then
; pressing the Enter key will reset the level, loosing all their progress :) The aim of
; the game is to get the progress bar as long as possilbe.
;
; To move the player the Q, A, O, P keys are used and Enter resets the level.
; 
; Remember to be careful as the ball will pass through the players red square which can
; cause the ball to escape from the player just when you think you have it trapped.
;
; This game is very easy to play but hard to master :o)
;
; This is an entry for the 256 bytes game competition #6 on the Z80 Assembly programming
; on the ZX Spectrum Facebook Group https://www.facebook.com/groups/z80asm/
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
BITMAP_SCRN_ADDR        equ             0x4000
BITMAP_SCRN_SIZE        equ             0x1800
ATTR_SCRN_ADDR          equ             0x5800
ATTR_SCRN_SIZE          equ             0x300
ATTR_ROW_SIZE           equ             0x1f

BLACK                   equ             0x00
BLUE                    equ             0x01
RED                     equ             0x02
MAGENTA                 equ             0x03
GREEN                   equ             0x04
CYAN                    equ             0x05
YELLOW                  equ             0x06
WHITE                   equ             0x07
PAPER                   equ             0x08                        ; Multiply with inks to get paper colour
BRIGHT                  equ             0x40
FLASH                   equ             0x80                        ; e.g. ATTR = BLACK * PAPER + CYAN + BRIGHT

PLAYER_COLOUR           equ             RED * PAPER + WHITE + BRIGHT + FLASH
BALL_COLOUR             equ             YELLOW * PAPER + WHITE
PLAY_AREA_COLOUR        equ             BLUE * PAPER + BLACK
BORDER_COLOUR           equ             BLACK * PAPER               ; Must be Black on Black as that is what the attr memory is initialised too
PROGRESS_BAR_COLOUR     equ             GREEN * PAPER

UP_CELL                 equ             0xffe0                      ; - 32
DOWN_CELL               equ             0x0020                      ; + 32
LEFT_CELL               equ             0xffff                      ; -1 
RIGHT_CELL              equ             0x0001                      ; + 1

MAX_TRAPPED_COUNT       equ             0x03                        ; Numer of frames the ball has been unable to move. If the trapped
                                                                    ; count reaches this number then the ball is trapped and the level ends
PLAYING_AREA_DEPTH      equ             0x14                        ; How many rows to colour for the playing area

DYN_VAR_LEVELS_COMPLETE equ             0x00                        ; Stores the number of consecutive levels completed
DYN_VAR_TRAPPED_COUNT   equ             0x01                        ; Stores how many frames the ball has not been able to move

; -----------------------------------------------------------------------------
; MAIN CODE
; -----------------------------------------------------------------------------

                org     0x8000

; -----------------------------------------------------------------------------
; Initialiase the dynamic variables. They need to be reset each time the game
; is reset, so may as well set them to zero here and not used pre-assigned
; memory locations to save a 2 bytes
; -----------------------------------------------------------------------------
init:
                ld      hl, dynamicVariables + DYN_VAR_LEVELS_COMPLETE
                ld      (hl), 0                                     ; Reset level count
                inc     hl
                ld      (hl), 0                                     ; Reset trap count

; -----------------------------------------------------------------------------
; Initiaise the screen by clearing the bitmap screen and attributes. Everything
; is set to 0 which is why the border colour left behind the player is black to save
; some bytes ;o)
; -----------------------------------------------------------------------------
startGame:
                ld      hl, BITMAP_SCRN_ADDR                        ; Point HL at the start of the bitmap file. This approach saves
                                                                    ; 1 byte over using LDIR
clearLoop: 
                ld      (hl), BORDER_COLOUR                         ; Reset contents of addr in HL to 0
                inc     hl                                          ; Move to the next address
                ld      a, 0x5b                                     ; Have we reached 0x5b00
                cp      h                                           
                jr      nz, clearLoop                               ; It not then loop

; -----------------------------------------------------------------------------
; Draw playing area by drawing 20 rows of BLUE PAPER attributes into attributes
; memory
; -----------------------------------------------------------------------------
drawPlayingArea:
                ld      a, PLAYING_AREA_DEPTH                                    
                ld      hl, ATTR_SCRN_ADDR + (3 * 32) + 1           ; Start on the third row to leave some space for the progress bar
drawRow:
                push    hl                                          ; Save HL so it can then be 
                pop     de                                          ; ... loaded into DE
                inc     de                                          ; ... and incremented ready for the LDIR
                ld      bc, ATTR_ROW_SIZE - 2                       ; Only draw 29 cells as there needs to be a black border around the screen
                ld      (hl), PLAY_AREA_COLOUR                      ; Drop the screen colour into attribute memory
                ldir                                                ; Draw a row of play area
                ld      c, 3                                        ; Add three
                add     hl, bc                                      ; ... to HL for the start of the next line
                dec     a                                           ; Dec A which is counting the lines drawn
                jr      nz, drawRow                                 ; If more rows are needed then loop - 21 bytes

; -----------------------------------------------------------------------------
; Draw the progress bar
; -----------------------------------------------------------------------------
drawProgressBar:
                ld      a, (dynamicVariables + DYN_VAR_LEVELS_COMPLETE) ; If the level count == 0...
                or      a                                           ; ... then don't draw the...
                jr      z, mainLoop                                 ; ... progress bar

                ld      hl, ATTR_SCRN_ADDR + (1 * 32) + 1           ; Point HL to the start of the progress bar       
drawProgressBlock:
                ld      (hl), PROGRESS_BAR_COLOUR                   ; Paint the block
                inc     hl                                          ; Move to the right
                dec     a                                           ; Dec the level count
                jr      nz, drawProgressBlock                       ; If we are not at zero go again

                push    hl                                          ; Place an initial value on the stack
                                                                    ; to be used later when see if the ball has got trapped

; -----------------------------------------------------------------------------
; Main game loop
; -----------------------------------------------------------------------------
mainLoop:                                                          
            ; -----------------------------------------------------------------------------
            ; Read the keyboard and update the players direction vector            
                ld      hl, playerVector                            ; We will use HL in a few places so just load it once here
                ld      c, 0xfe                                     ; Set up the port for the keyboard as this wont change
            
_checkRight:                                                        ; Move player right
                ld      b, 0xdf                                     ; Read keys YUIOP by setting B only as C is already set
                in      a, (c)          
                rra         
                jr      c, _checkLeft                               ; If P was not pressed check O
                ld      a, 0xff                                     ; If the player is already move left
                cp      (hl)                                        ; ... then don't let the player move right
                jr      z, _movePlayer
                ld      (hl), 0x01                                  ; P pressed so set the player vector to 0x0001
                inc     hl          
                ld      (hl), 0x00          
                jr      _movePlayer                                 ; Don't check for any more keys
            
_checkLeft:                                                         ; Move player left
                rra         
                jr      c, _checkUp         
                ld      a, 01                                       ; If the player is already moving right
                cp      (hl)                                        ; ... then don't let them move left
                jr      z, _movePlayer
                ld      (hl), 0xff                                  ; O pressed so set the player vector to 0xffff
                inc     hl          
                ld      (hl), 0xff          
                inc     c                                           ; Break the next IN so _checkUp will jump to _checkDown so we not need
                                                                    ; JR which saves 1 byte
            
_checkUp:                                                           ; Move player up
                ld      b, 0xfb                                     ; Read keys QWERT
                in      a, (c)          
                rra         
                jr      c, _checkDown                               ; If the player is already moving down
                ld      a, 0x20                                     ; ... then don't let them move up
                cp      (hl)
                jr      z, _movePlayer          
                ld      (hl), 0xe0                                  ; Q pressed so set the player vector to 0xfffe
                inc     hl          
                ld      (hl), 0xff          
                inc     b                                           ; Break the next IN so _checkEnter will be called which uses less bytes than JR

_checkDown:                                                         ; Move player down
                inc     b                                           ; INC B from 0xFB to 0xFD to read ASDFG
                inc     b           
                in      a, (c)          
                rra         
                jr      c, _checkEnter
                ld      a, 0xe0                                     ; If the player is already moving down
                cp      (hl)                                        ; ... then don't let them move up
                jr      z, _movePlayer          
                ld      (hl), 0x20                                  ; A pressed so set the player vectory to 0x0020
                inc     hl          
                ld      (hl), 0x00          

_checkEnter:         
                ld      b, 0xbf                                     ; Read keys HJKLEnter
                in      a, (c)          
                rra         
                jr      c, _movePlayer          
                jp      init                                        ; Player wants to reset so init the game

            ; -----------------------------------------------------------------------------
            ; Update the players position based on the current player vector
_movePlayer:
                ld      hl, (playerAddr)                            ; Get the players location address             
                ld      (hl), BORDER_COLOUR                         ; Draw the border colour in the current location 
                ld      de, (playerVector)                          ; Get the players movement vector
                add     hl, de                                      ; Calculate the new player position address
                xor     a                                           ; Clear A to 0 which happens to be the BORDER_COLOUR saving 1 byte :o)
                cp      (hl)                                        ; Compare the new location with the border colour...
                jr      z, _drawplayer                              ; ... and if it is a border block then don't save HL
                ld      (playerAddr), hl                            ; New position is not a border block so save it
                
            ; -----------------------------------------------------------------------------
            ; Draw player 
_drawplayer:
                ld      hl, (playerAddr)                            ; Load the players position 
                ld      (hl), PLAYER_COLOUR                         ; and draw the player

            ; -----------------------------------------------------------------------------
            ; Move the ball
_moveBall:
                ld      de, xVector                                 ; We need to pass a pointer to the vector...
                ld      bc, (xVector)                               ; ... and the actual vector into the ball update routine
                call    updateBallWithVector                        ; Update the ball with the x vector

                ld      de, yVector
                ld      bc, (yVector)
                call    updateBallWithVector            

            ; -----------------------------------------------------------------------------
            ; Draw ball
_drawBall:
                ld      hl, (ballAddr)                              ; Draw the ball at the...
                ld      (hl), BALL_COLOUR                           ; ... current position 

            ; -----------------------------------------------------------------------------
            ; Sync screen and slow things down to 25 fps
_sync:
                halt                                    
                halt

            ; -----------------------------------------------------------------------------
            ; Erase ball
_eraseBall:
                ld      (hl), PLAY_AREA_COLOUR                      ; HL is already pointing to the balls location so erase it

            ; -----------------------------------------------------------------------------
            ; Has the ball been trapped    
                pop     de                                          ; Get the previous position 
                push    hl                                          ; Save the current position 
                or      a                                           ; Clear the carry flag
                sbc     hl, de                                      ; current pos - previous pos
                ld      hl, dynamicVariables + DYN_VAR_TRAPPED_COUNT; Do this now so we don't have to do it again in the
                                                                    ; _trapped branch :)
                jp      z, _trapped                                 ; If current pos == previous pos increment the trapped counter...
                ld      (hl), 0                                     ; ... else reset the trapped counter

                jp      mainLoop                                    ; Round we go again :)

_trapped:
                inc     (hl)                                        ; Up the trapped count
                ld      a, (hl)                                     ; Check to see if the trapped count...
                cp      MAX_TRAPPED_COUNT                           ; ... is equal to MAX_TRAPPED_COUNT
                jp      nz, mainLoop

                dec     hl                                          ; Point HL at the level pointer address
                inc     (hl)                                        ; Inc the level complete counter

                jp      startGame                                   ; Loop

; -----------------------------------------------------------------------------
; Update the balls position based on the vector provided
;
; DE = vector address
; BC = vector value
; -----------------------------------------------------------------------------
updateBallWithVector:
                ld      hl, (ballAddr)                              ; Get the balls current position address...
                add     hl, bc                                      ; ... and calculate the new position using the vector in BC
                cp      (hl)                                        ; A already holds the border colour at this point so see if..
                jr      nz, _saveBallPos                            ; ... the new position is a border block and is not save the new pos
    
                ld      hl, 0                                       ; The new position was a border block...
                or      a                                           ; Reset the carry flag
                sbc     hl, bc                                      ; ... so reverse the vector in BC
                    
                ex      de, hl                                      ; Need to save the new vector so switch DE and HL
                    
                ld      (hl), e                                     ; Save the new vector back into the vector addr
                inc     hl  
                ld      (hl), d 
    
_playClickLoop:
                ld      a, b                                        ; Not setting B for this loop saves us 2 bytes and woks fine :o)
                and     248                                         ; Make sure the border colour doesn't change
                out     (254), a                                    ; Push A to the port to get our high def 1 bit sond :oO
                djnz    _playClickLoop
                ret

_saveBallPos:        
                ld      (ballAddr), hl                              ; Save the new position in HL
                ret

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
playerAddr:     dw      ATTR_SCRN_ADDR + (12 * 32) + 16
playerVector:   dw      UP_CELL

ballAddr:       dw      ATTR_SCRN_ADDR + (12 * 32) + 16
xVector:        dw      LEFT_CELL
yVector:        dw      DOWN_CELL

dynamicVariables:       ; Points to the address in memory where we will store some dynamic variables
                        ; db Stores the count of levels completed
                        ; db Stores the # frames the ball has not moved

                END init
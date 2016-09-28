        org 08000h


waitingMoveUpBit      EQU   0
moveUpBit             EQU   1
enemyBit              EQU   2
flashBit   	      EQU   7

clearBit              EQU   6

paper                 EQU   8

siloColourBit          EQU   3
rocketColourBit        EQU   4
landColourBit          EQU   5
tunnelColour1          EQU   0
playerFrontColour1     EQU   7
playerBehindColour1    EQU   6
bulletColour           EQU   5

landAttr              EQU   ((1<<landColourBit)+(1<<enemyBit))               ;green ink & paper
tunnelAttr            EQU   (tunnelColour1)               ;black ink & paper
rocketSiloAttr        EQU   ((1<<siloColourBit)+(1<<waitingMoveUpBit)+(1<<enemyBit))   ;blue
movingRocketAttr      EQU   ((1<<clearBit)+(1<<rocketColourBit)+(1<<moveUpBit)+(1<<enemyBit))   ;red
rocketAttr      	  EQU   ((1<<rocketColourBit)+(1<<enemyBit))   ;red

playerFrontAttr       EQU   ((1<<clearBit)+(playerFrontColour1*paper))
playerBehindAttr      EQU   ((1<<clearBit)+(playerBehindColour1*paper))
bulletAttr            EQU   ((1<<clearBit)+(bulletColour*paper))

playerStartX          EQU 10
playerStartY          EQU 10


bufferStart        EQU 49152
bufferLength       EQU 6144
bufferEndHi        EQU 216


startLandDir        EQU 2
startLandTimer      EQU 1
startRandomSeed     EQU 123
startLandHeight     EQU 7
scrollSpeed         EQU 2  ;speed of scroll compared to sprites

startDifficulty          EQU      17
difficultySpeed          EQU      64



start:
          xor   a                   ;clear buffer
          ld  (bufferStart),a
          call copyBuffer

;setup vars
           ld    hl,bufferStart+playerStartX+(256*playerStartY)   ;player start position
           push  hl
           exx
           ld  de,startLandDir+(startLandTimer*256)
           ld  bc,scrollSpeed+(startLandHeight*256)
           ld  h,startDifficulty                                      ;start difficulty (tunnel size)
           exx


mainLoop:



;copy buffer to attr map (buffer is 256 bytes wide)

           ld  hl,bufferStart
           ld  de,5800h
bufferCopyLoop:
           push    hl
           ld      bc,32
           ldir
           pop hl
           inc h
           bit 2,d      ;end of attr map? (d=05bh)
           jr  z,bufferCopyLoop


          ld   d,tunnelAttr                 ;load up the compare colours for the following section
          ld   e,movingRocketAttr

;scan the buffer and move stuff


logic:
         ld   hl,bufferStart             ;start
         ld   c,0                      ;have we found a bullet?
moveLoop:
         ld   a,(hl)
         or   a
         jr   z,moveJump

         ;check for bullet

         cp     bulletAttr
         jr     nz,noBullet
         inc    c                      ;found bullet, don't fire another
         ld     (hl),d
         inc    l
         bit    enemyBit,(hl)
         jr     z,noHit
         ld     (hl),d
         jr     noBullet
noHit:
         ld     (hl),a
         inc    l
noBullet:

         ;check for a moving rocket

         cp    e                         ;movingRocketColour
         jr    nz,noMoveUp
launch:
         dec   h                        ;move up
         bit   landColourBit,(hl)       ;hit land?
         jr    nz,rocketDead
         ld    (hl),e                   ;store in new position
rocketDead
	 inc h                          ;restore addr for scan
noMoveUp:

         ;check for a rocket silo

         cp    rocketSiloAttr
         jr    nz,noLaunch
         ld    a,r
varLaunchChance:
         and    31                       ;chance of launching a static rocket
         jr    z,launch                 ;launch it, logic will come back here to maybe launch another but that doesn't matter, it'll get out eventually
noLaunch:

         ;delete everything with the clearBit set

         bit   clearBit,(hl)
         jr    z,moveJump
         ld    (hl),d    ;tunnelColour

moveJump:
         inc   hl
         ld    a,h        ;compare with the end
         cp    bufferEndHi
         jr    nz,moveLoop
         push  bc                  ;save bullet state (launched?)
                                      ;a will be non zero here
         exx                         ;swap in the variables held in alternate regs

;set difficulty
          dec l                      ;increase difficulty
          dec l
          dec l
	  jr	nz,noIncrease
	  dec	h
	  ld   a,h
          ld   (varTunnelHeight+1),a
noIncrease:


varScrollSpeed:
          dec  c                      ;speed of scrolling
          call z,copyBuffer            ;to scroll, a should be non zero when calling here, which it should be from above


;time for the land to change direction?

varLandTimer:

          dec d                         ;time for land to change direction?

          jr  nz,landTimerNotZero
          ld  a,r                   ;time before next land change random 0-7
          and  7
          inc  a
          ld   d,a                  ;store land timer
          inc  e                    ;new land dir
landTimerNotZero:


;move the land up, down or flat

varLandDir:
          ld a,e                    ;get current land dir
          rrca
          jr  nc,landDone              ;if land direction is 1 or 3, it's flat
          rrca
          jr  c,landDown               ;if land direction is 2, it's going down
landUp:                                ;else it's going up
          bit   4,b                     ;has height gone too much? (max 16)
          jr nz,landDone
          inc b
          jr  landDone
landDown:
          dec b                             ;going down
          jr  nz,landDone                   ;hit floor?
          inc b                             ;go back up
landDone:



noScroll:      ;this could go below the next bit bit we need to preserve the alternate registers

          ld  a,b                      ;get the height into 'a' ready for the next bit befire we swap out the registers

          exx                          ;swap out the vars in the alternate regs

;draw the land

          ld  e,landAttr             ;d should still hold tunnel attr...
          ld  d,tunnelAttr          ;load up the compare colours


          ld b,a                       ;a should hold the height from above
          ld  hl,bufferStart+31+(256*23)  ;start at bottom right of attr map
ceilingLoop:
          ld  (hl),e                                ;fill
          dec h                    ;next line
          djnz    ceilingLoop          ;repeat
;do we draw a rocket?
          ld  a,r                       ;get the random number
varRocketChance:
          cp 32                         ;greater than this?
          jr nc,drawTunnel              ;no rocket

          ld  (hl),rocketSiloAttr       ;draw the silo

          dec h                     ;this makes the tunnel bigger at this point. Don't care for the moment
drawTunnel:
varTunnelHeight:                       ;draw the tunnel
          ld  b,15
tunnelLoop:
          ld  (hl),d                   ;fill (might go off the buffer but we don't care. Plenty of nothing below here)
          dec   h
          djnz    tunnelLoop
          ld   b,24
landLoop:
          ld (hl),e                    ;fill the top of the tunnel (this will zip off through memory as above but won't reach anything critical)
          dec  h
          djnz  landLoop



movePlayer:
           pop  de                                   ;retrieve bullet state
           pop hl                                     ;retrieve player position
           ld bc,0fdfeh
           in a,(c)
           bit 0,a                                    ;read 'a'
           jr  nz,noUp
           dec h
noUp:
           inc b                                      ;read 'z'
           in a,(c)
           bit 1,a
           jr nz,noDown
           inc h
noDown:
           bit 2,a                                    ;read 'x'
           jr nz,noLeft
           dec l
noLeft:
           bit 3,a                                    ;read 'c'
           jr nz,noRight
           inc l
noRight:
         push  hl                                    ;save player again
         bit   enemyBit,(hl)                          ;test for death
         jp    nz,start
         ld    (hl),playerFrontAttr                 ;draw the player
         bit   4,a                                    ;read 'v'
         jr    nz,noFire
         bit   1,e                                     ;is there already a bullet?
         jr    nz,noFire
         inc   l
         ld    (hl),bulletAttr                        ;put bullet in front of player
         dec   l
noFire:
         dec   l
         ld    (hl),playerBehindAttr

         jp mainLoop


copyBuffer:
           exx                      ;just is case we are using the alternate regs
          ld hl,bufferStart         ;assume normal forward copy
          ld de,bufferStart+1
          or a                      ;are we scrolling?
          jr z,noSwap
          ex de,hl                  ;swap so everything gets copied to the left
noSwap:
          ld bc,bufferLength
          ldir
          exx
          ld  c,scrollSpeed            ;reset scroll speed (assuming we're doing a scroll. If we're not, it doesn't matter)
          ret




end 08000h
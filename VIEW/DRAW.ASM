;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/STD.INC"
INCLUDE "INC/FILE.INC"
INCLUDE "INC/DRAW.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG
;;;;;;;;;;;;;;;;;;;;; VGA PROCS ;;;;;;;;;;;;;;;;;;;;;;;;::::

PROC setVideoMode
  ARG @@mode:BYTE
  USES EAX

  MOVZX AX, [@@mode]
  INT 10h

  RET

ENDP setVideoMode

PROC updateVideoBuffer
  USES ESI, EDI, ECX

  CLD
  MOV ESI, OFFSET double_buff
  MOV EDI, FRAME_BUFF_ADR
  
  MOV ECX, DBUFF_SIZE ; Amount of pixels on screen
  REP MOVSB

  RET
ENDP updateVideoBuffer

PROC waitVBI
  USES EDX, ECX

  MOV DX, 03DAH ;VGA status port
  MOV ECX, 3

  @@waitForEnd:
    IN AL, DX
    AND AL, 8
    JZ @@waitForEnd

  @@waitForStart:
    IN AL, DX
    AND AL, 8
    JNZ @@waitForStart

  LOOP @@waitForEnd

  RET
ENDP waitVBI

;;;;;;;;;;;;;;;;;;;;; DRAW PROCS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Update the colour palette.
; 	* Ncolours: number of colours that have to be updated [word]
PROC updateColourPalette
	ARG	 	@@Ncolours: WORD
	USES 	EAX, ECX, EDX, ESI

	MOV ESI, offset palette	; pointer to source palette
	MOVZX ECX, [@@Ncolours] ; amount of colors to read (movzx = zero extend)
	
	; multiply ecx by 3 (three color components per color)
	; do it efficiently (2*ecx + ecx)
	MOV EAX, ECX
	SAL EAX, 1
	ADD ECX, EAX

	MOV DX, 03C8h ; DAC write port
	XOR AL, AL		; index of first color to change (0)
	OUT DX, AL		; write to IO

	INC DX
	REP OUTSB		; update all colors

	RET
ENDP updateColourPalette

PROC fillBuffer
  ARG @@color:BYTE, @@buffer:DWORD
  USES EAX, ECX, EDI

  MOV EDI, [@@buffer] ; Frame buffer start address
  
  MOV AL, [@@color]
  MOV AH, AL
  MOV CX, AX
  SHL EAX, 16
  MOV AX, CX

  MOV ECX, DBUFF_SIZE ; Amount of pixels on screen

  REP STOSD

  RET
ENDP fillBuffer

PROC draw
  ARG @@image:DWORD, @@column:DWORD, @@row:DWORD
  USES ESI, EDI

	CALL loadFile, [@@image], OFFSET image_buff, IMAGE_BUFF_SIZE

  CLD
  ; Set up Index registers
  MOV ESI, OFFSET image_buff
  MOV EDI, OFFSET double_buff

  CALL scaleBuff, [@@column], [@@row]

  RET
ENDP draw

PROC drawLevel
  USES ESI, EDI

  CLD
  MOV ESI, OFFSET level_buff
  MOV EDI, OFFSET double_buff
  
  MOV ECX, DBUFF_SIZE ; Amount of pixels on screen
  REP MOVSB

  RET
ENDP drawLevel

PROC scaleBuff
  ARG @@column:DWORD, @@row:DWORD
  USES ECX, EAX, EBX, EDX

  ; Calculate the drawing start position => EDI
  MOV EBX, [@@row]
  IMUL EBX, SCALE
  MOV EAX, EBX
  IMUL EAX, SCRW
  MOV EBX, [@@column]
  IMUL EBX, SCALE
  ADD EAX, EBX
  ADD EDI, EAX

  LODSW         ; Load image height
  MOV ECX, EAX  ; Outer loop index
  LODSW         ; Load image width

  @@nextLine:
    PUSH ECX
    MOV ECX, SCALE  ; Inner Loop index (draw each line SCALE time)

    @@scale:
      CALL drawLine, EAX ; pass line length (image width)

      ; Go one line down
      ADD EDI, SCRW 

      ; Go back to the start of the line
      PUSH EAX
      IMUL EAX, SCALE
      SUB EDI, EAX
      POP EAX

      LOOP @@scale

    ADD ESI, EAX      ; Go to the next line of the image
    POP ECX
    LOOP @@nextLine
    
    RET
ENDP scaleBuff

PROC drawLaser ; draw laser directly into double_buff
  ARG @@x0:DWORD, @@y0:DWORD, @@direction:DWORD
  USES EAX, EDX
  CALL directionNext, [@@direction]  ; set up EAX (-> x) and EDX (-> y) to calculate next position



  RET
ENDP drawLaser

PROC updateLevel
  ARG @@newLevel:DWORD
  USES ESI, EDI, ECX, EAX, EBX, EDX

	CALL loadFile, [@@newLevel], OFFSET lvl_buff, LVL_BUFF_SIZE             ; Load LVL#.BIN in lvl_buff
  CALL generateLevel                                                ; Generates the level from lvl_buff -> image_buff

  CALL fillBuffer, 00H, OFFSET level_buff

  CLD
  ; Set up Index registers
  MOV ESI, OFFSET image_buff
  MOV EDI, OFFSET level_buff
  CALL scaleBuff, 0, 0

  RET
ENDP updateLevel

;;;;;;;;;;;;;;;;;;;;; ANIMATION PROCS ;;;;;;;;;;;;;;;;;;;;;;;

PROC resetAnimated
  ARG @@animated_ptr:DWORD
  USES EAX, EBX
  MOV EAX, [@@animated_ptr]

  MOV EBX, [@@animated_ptr]
  MOV EBX, [EBX + Animated.images]
  MOV [EAX + Animated.image], EBX                    ; save adrres in animated.images to animated.image
  RET

ENDP resetAnimated

PROC setPortalFrame
  ARG @@animated_ptr:DWORD, @@portal_direction:DWORD
  USES EAX, EBX, EDX                       ; return value in EDX

  MOV EAX, [@@animated_ptr]           ; animated.current

  CMP [@@portal_direction], UP
  JE @@horizontal
  CMP [@@portal_direction], DOWN
  JE @@horizontal
  JMP @@vertical

  @@horizontal:
    MOV [EAX + Animated.current], PRT_HORIZONTAL
    RET

  @@vertical:
    MOV [EAX + Animated.current], PRT_VERTICAL
    RET

ENDP setPortalFrame

PROC getNextFrame
  ARG @@animated_ptr:DWORD
  USES EAX, EBX, EDX                       ; return value in EDX

  MOV EAX, [@@animated_ptr]           ; animated.current
  MOV EAX, [EAX + Animated.current]   ; get current
  INC EAX

  MOV EBX, [@@animated_ptr]         ; get pointer
  MOV EBX, [EBX + Animated.length]  ; get length
	LEA EDX, [0]
  DIV EBX
    
  MOV EAX, [@@animated_ptr]
  MOV [EAX + Animated.current], EDX

  RET
ENDP getNextFrame

PROC updateFrame    ; function expect image pointer to be ESI
  ARG @@animated_ptr:DWORD
  USES EAX, EBX, ECX, EDX, ESI

  MOV EAX, [@@animated_ptr]              ; get pointer
  MOV EAX, [EAX + Animated.images]       ; get animated.images
  MOV ESI, EAX                         ; ESI hold start of list images

  MOV ECX, [@@animated_ptr] 
  MOV ECX, [ECX + Animated.current]      ; Find the Frame path on given index
  JECXZ @@save                           ; Skip if index = 0
  @@loop:
    @@next_frame:       ; Find the next path name by using the tailing 0
      LODSB
      CMP AL, 0
      JNE @@next_frame
    LOOP @@loop

  @@save:
    MOV EAX, [@@animated_ptr]
    MOV [EAX + Animated.image], ESI
    RET
ENDP updateFrame

;;;;;;;;;;;;;;;;;;;;; AUXILIARY PROCS ;;;;;;;;;;;;;;;;;;;;;;;

PROC drawLine ; Auxiliary proc for draw procedure
  ARG @@length:DWORD
  USES ESI, EAX, ECX ; ESI -> Reset ESI after proc, so line can be redrawn

  MOV ECX, [@@length]

  @@nextPixel:   ; Draw each pixel SCALE time
    PUSH ECX
    MOV ECX, SCALE
    LODSB        ; Load next pixel
    CMP AL, 00H
    JE @@skip
    REP STOSB    ; Draw pixel SCALE time
    JMP @@next
    @@skip:
      ADD EDI, ECX
    @@next:
      POP ECX
      LOOP @@nextPixel

  RET
ENDP drawLine

PROC drawBlock
  ARG @@type:DWORD, @@location:DWORD
  USES EAX, EBX, EDX, ECX, EDI, ESI

  CMP [@@type], 00H
  JE @@empty

  CMP [@@type], 01H
  JE @@wall

  CMP [@@type], 02H
  JE @@untargetable

  CMP [@@type], 03H
  JE @@portalA

  CMP [@@type], 04H
  JE @@portalB
  RET

  ;; LOAD the correct block sprite in block_buff
  @@empty:
	  CALL loadFile, OFFSET empty, OFFSET block_buff, BLOCK_BUFF_SIZE
    JMP @@place_block

  ;; LOAD the correct block sprite in block_buff
  @@wall:
	  CALL loadFile, OFFSET wall, OFFSET block_buff, BLOCK_BUFF_SIZE
    JMP @@place_block

  @@untargetable:
	  CALL loadFile, OFFSET untargetable, OFFSET block_buff, BLOCK_BUFF_SIZE
    JMP @@place_block

  @@portalA:
	  CALL loadFile, OFFSET PRT_A, OFFSET block_buff, BLOCK_BUFF_SIZE
    JMP @@place_block

  @@portalB:
	  CALL loadFile, OFFSET PRT_B, OFFSET block_buff, BLOCK_BUFF_SIZE
    JMP @@place_block

  ;; PLACE the block_buff in the correct place in image_buff
  @@place_block:

    ;; Calculate loctation into EAX
    MOV EAX, LVL_BUFF_SIZE 
    SUB EAX, [@@location]       ; value will go from [0 -> 159]
		XOR EDX, EDX
    MOV EBX, LVLBW
    DIV EBX                     ; x -> EDX and y -> EAX

    MOV EBX, BLOCK_LEN

    PUSH EDX                    ; y*[block_width]
    MUL EBX                     ; value will be in [0 -> 45] so no need to look in EDX

    POP EDX                     ; x*[block_width]
    PUSH EAX
    MOV EAX, EDX                
    MUL EBX                     ; value will be in [0 -> 75] so no need to look in EDX

    MOV EDX, EAX                ; restor x
    POP EAX                     ; restor y

    PUSH EDX                    ; image_buff location = y*IMGBW + x            
    MOV EBX, IMGBW
    MUL EBX         
    POP EDX
    ADD EAX, EDX

    LEA EDI, [OFFSET image_buff + EAX + 2*2] ;Load destination location
    MOV ECX, BLOCK_LEN          ; Outer loop = height
    MOV ESI, OFFSET block_buff  ; Load sprite to draw
    CLD
    @@next_line:
      PUSH ECX
      MOV ECX, BLOCK_LEN       ; Inner loop = width
      REP MOVSB                ; Place line lvl_buff -> image_buff
      ADD EDI, IMGBW - BLOCK_LEN ; Load next line
      POP ECX
      LOOP @@next_line
    RET

ENDP drawBlock

; generate a level in image_buff with the lvl_buff (later moved to LEVEL.BIN)
PROC generateLevel
  USES ESI, EAX, ECX

  ; Add size of level first in image_buff
  MOV AX, IMGBH
  MOV [OFFSET image_buff], AX
  MOV AX, IMGBW
  MOV [OFFSET image_buff + 2], AX

  ; LVL that needs to be drawn
  MOV ESI, OFFSET lvl_buff

  MOV ECX, LVL_BUFF_SIZE

  MOV EDI, OFFSET image_buff
  @@loop:                       ;Loop through each block of the level
    LODSB                       ;Load byte from lvl_buff
    CALL drawBlock, EAX, ECX    ;Place block in the buffer image_buff
    LOOP @@loop
  RET
ENDP generateLevel

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  palette DB 40, 43, 36   ; white -> green
				  DB 13, 13, 13 	; black -> dark gray
				  DB 8, 25, 33 	; temp portal A -> blue
				  DB 33, 25, 8 	; temp portal B -> orange

	empty DB "VIEW/IMG/EMPTY.BIN", 0
	wall DB "VIEW/IMG/WALL.BIN", 0
	untargetable DB "VIEW/IMG/UWALL.BIN", 0

  PRT_A Animated <2, 0, OFFSET PRT_A_Images, OFFSET PRT_A_Images>
	PRT_A_Images DB "VIEW/IMG/PRT_A_H.BIN", 0
	             DB "VIEW/IMG/PRT_A_V.BIN", 0

  PRT_B Animated <2, 0, OFFSET PRT_B_Images, OFFSET PRT_B_Images>
	PRT_B_Images DB "VIEW/IMG/PRT_B_H.BIN", 0
	             DB "VIEW/IMG/PRT_B_V.BIN", 0

  character_R Animated <6, 0, OFFSET character_R_Images, OFFSET character_R_Images>

  character_R_Images DB "VIEW/IMG/P_R_0.BIN", 0
                     DB "VIEW/IMG/P_R_1.BIN", 0
                     DB "VIEW/IMG/P_R_1.BIN", 0
                     DB "VIEW/IMG/P_R_0.BIN", 0
                     DB "VIEW/IMG/P_R_2.BIN", 0
                     DB "VIEW/IMG/P_R_2.BIN", 0

  character_L Animated <6, 0, OFFSET character_L_Images, OFFSET character_L_Images>
  character_L_Images DB "VIEW/IMG/P_L_0.BIN", 0
                     DB "VIEW/IMG/P_L_1.BIN", 0
                     DB "VIEW/IMG/P_L_1.BIN", 0
                     DB "VIEW/IMG/P_L_0.BIN", 0
                     DB "VIEW/IMG/P_L_2.BIN", 0
                     DB "VIEW/IMG/P_L_2.BIN", 0

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  double_buff DD DBUFF_SIZE DUP(?)
  level_buff DD DBUFF_SIZE DUP(?)
  lvl_buff DB LVL_BUFF_SIZE DUP(?)
  image_buff DB IMAGE_BUFF_SIZE DUP(?)
  block_buff DB BLOCK_BUFF_SIZE DUP(?)

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END

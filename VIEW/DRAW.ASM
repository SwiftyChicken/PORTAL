;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/DRAW.INC"
INCLUDE "INC/FILE.INC"

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
  MOV ESI, OFFSET dbuff
  MOV EDI, FBADR
  
  MOV ECX, SCRW * SCRH ; Amount of pixels on screen
  REP MOVSB

  RET
ENDP updateVideoBuffer

PROC waitVBI
  USES EDX, ECX

  MOV DX, 03DAH ;VGA status port
  MOV ECX, 2

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

	MOV DX, 03C8h 	; DAC write port
	XOR AL, AL		; index of first color to change (0)
	OUT DX, AL		; write to IO

	INC DX
	REP OUTSB		; update all colors

	RET
ENDP updateColourPalette

PROC fillBackground
  ARG @@color:BYTE
  USES EAX, ECX, EDI

  MOV EDI, OFFSET dbuff ; Frame buffer start address
  
  MOV AL, [@@color]
  MOV AH, AL
  MOV CX, AX
  SHL EAX, 16
  MOV AX, CX

  MOV ECX, DBUFF_SIZE ; Amount of pixels on screen

  REP STOSD

  RET

ENDP fillBackground

PROC draw
  ARG @@image:DWORD, @@column:DWORD, @@row:DWORD
  USES ESI, EDI, ECX, EAX, EBX, EDX

	CALL loadFile, [@@image], OFFSET filebuff, FBUFF_SIZE

  ; Set up Index registers
  MOV ESI, OFFSET filebuff
  MOV EDI, OFFSET dbuff

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
ENDP draw

PROC updateLevel
  ARG @@newLevel:DWORD
  USES ESI, EDI, ECX, EAX, EBX, EDX

	CALL loadFile, [@@newLevel], OFFSET sbuff, SBUFF_SIZE

  CALL generateLevel  ; Generates the level from sbuff -> filebuff
  RET
ENDP updateLevel

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
  USES ECX

  CMP [@@type], 01H
  JE @@wall
  CMP [@@type], 02H
  JE @@untargetable
  RET

  @@wall:
	  CALL loadFile, OFFSET wall, OFFSET spritebuff, SPRITE_BUFF_SIZE
    JMP @@place_block

  @@untargetable:
	  CALL loadFile, OFFSET untargetable, OFFSET spritebuff, SPRITE_BUFF_SIZE
    JMP @@place_block

  @@place_block:
    ;; Calculate loctation into EAX
    MOV EAX, SBUFF_SIZE 
    SUB EAX, [@@location]
    MOV EDI, [OFFSET filebuff + EAX + 2] ;Load destination location
    MOV ECX, BLOCK_LEN
    @@next_line:
      PUSH ECX
      MOV ECX, BLOCK_LEN
      
      POP ECX
      LOOP @@next_line
    RET

ENDP drawBlock

; generate a level in filebuff with the sbuff (later moved to LEVEL.BIN)
PROC generateLevel
  USES ESI, ECX

  ; LVL that needs to be drawn
  MOV ESI, OFFSET sbuff

  MOV ECX, SBUFF_SIZE

  @@loop:                       ;Loop through each block of the level
    LODSB                       ;Load byte from sbuff
    CALL drawBlock, EAX, ECX    ;Place block in the buffer filebuff
    LOOP @@loop

  RET
ENDP generateLevel
;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  palette DB 40, 43, 36   ; white -> green
				  DB 13, 13, 13 	; black - dark gray
	wall DB "VIEW/IMG/WALL.BIN", 0
	untargetable DB "VIEW/IMG/UWALL.BIN", 0

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  dbuff DD DBUFF_SIZE DUP(?)
  spritebuff DD SPRITE_BUFF_SIZE DUP(?)
  sbuff DD SBUFF_SIZE DUP(?)
  filebuff DD FBUFF_SIZE DUP(?)

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END

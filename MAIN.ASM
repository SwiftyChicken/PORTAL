;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc"
;-----------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------
FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen witdth
SCRH EQU 200	; screen height
SCALE EQU 4   ; image scale
FLOOR EQU 42

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

STRUC Player
  x dd ?
  y dd ?
  vx dd ?
  vy dd ?
ENDS Player

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

PROC fillBackground
  ARG @@color:BYTE
  USES EAX, ECX, EDI

  MOV EDI, OFFSET dbuff ; Frame buffer start address
  
  MOV AL, [@@color]
  MOV AH, AL
  MOV CX, AX
  SHL EAX, 16
  MOV AX, CX


  MOV ECX, SCRW * SCRH ; Amount of pixels on screen

  REP STOSB

  RET

ENDP fillBackground

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

PROC draw
  ARG @@image:DWORD, @@row:DWORD, @@column:DWORD
  USES ESI, EDI, ECX, EAX, EBX, EDX

	; open file, get filehandle in AX
	MOV AL, 0 ; read only
	MOV EDX, [@@image]
	MOV AH, 3DH
	INT 21H

	mov  edx, offset openErrorMsg
	jc @@print_error ; carry flag is set if error occurs

	; read file data
	MOV BX, AX ; move filehandle to bx
	MOV ECX, (SCRW*SCRH)/4
	MOV EDX, OFFSET filebuff
	MOV AH, 3FH
	INT 21H

	mov  edx, offset readErrorMsg
	jc @@print_error

	; close file
	MOV AH, 3EH
	INT 21H

	mov  edx, offset closeErrorMsg
	jc @@print_error
	
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

  MOV ECX, 50  ; Outer loop index aka height
  MOV EAX, 80         ; Load image width

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

@@print_error:
	call setVideoMode, 03h
	mov  ah, 09h
	int  21h
	
	mov	ah,00h
	int	16h
	call exit	

  RET

ENDP draw

PROC drawSprite
  ARG @@image:DWORD, @@sprite:DWORD
  USES ESI, EDI, ECX, EAX, EBX

	; open file, get filehandle in AX
	MOV AL, 0 ; read only
	MOV EDX, [@@image]
	MOV AH, 3DH
	INT 21H

	mov  edx, offset openErrorMsg
	jc @@print_error ; carry flag is set if error occurs

	; read file data
	MOV BX, AX ; move filehandle to bx
	MOV ECX, (SCRW*SCRH)/4
	MOV EDX, OFFSET filebuff
	MOV AH, 3FH
	INT 21H

	mov  edx, offset readErrorMsg
	jc @@print_error

	; close file
	MOV AH, 3EH
	INT 21H

	mov  edx, offset closeErrorMsg
	jc @@print_error
	
  ; Set up Index registers
  CLD
  MOV ESI, OFFSET filebuff
  MOV EDI, OFFSET dbuff

  ; Calculate the drawing start position => EDI
  MOV EBX, [@@sprite]
  MOV EBX, [EBX]
  IMUL EBX, SCALE
  MOV EAX, EBX
  IMUL EAX, SCRW
  MOV EBX, [@@sprite]
  MOV EBX, [EBX + 4]
  IMUL EBX, SCALE
  ADD EAX, EBX
  ADD EDI, EAX

  MOV ECX, 5
  MOV EAX, 5

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

  @@print_error:
  	call setVideoMode, 03h
  	mov  ah, 09h
  	int  21h
  	
  	mov	ah,00h
  	int	16h
  	call exit	
  
    RET
ENDP drawSprite

PROC checkEscape
  USES EAX


	RET
ENDP checkEscape

PROC exit
	USES EAX
	CALL setVideoMode, 03H
	MOV	AX, 04C00H
	INT 21H
  
	RET
ENDP exit

PROC keyboardHandler
  USES EAX, ECX, ESI
  
  LEA ESI, [keytracker]
  LODSW
  MOV ECX, EAX

  @@loop:
    LODSB
    MOVZX EAX, AL
    MOV BL, [offset __keyb_keyboardState + EAX]
    CMP BL, 1
    LODSB
    JNE @@skip
    CALL actionHandler

    @@skip:
    LOOP @@loop

    
  RET
ENDP keyboardHandler

PROC actionHandler
  ARG @@key:DWORD
  
	CMP	AL, 4BH
  JE @@left
	CMP	AL, 4DH
  JE @@right
	CMP	AL, 48H
  JE @@up
  JMP @@end

  @@left:
    SUB [player.vy], 1
    JMP @@end

  @@right:
    ADD [player.vy], 1
    JMP @@end

  @@up:
    CMP [player.x], FLOOR
    JNE @@end
    SUB [player.vx], 5
    JMP @@end

  @@end:

    RET
ENDP actionHandler

PROC physicsHandler
  USES EAX

  MOV EAX, [player.vy]
  ADD EAX, [player.y]
  MOV [player.y], EAX
  MOV [player.vy], 0
  
  MOV EAX, [player.vx]
  ADD EAX, [player.x]
  CMP EAX, FLOOR
  JG @@end
  MOV [player.x], EAX
  INC [player.vx]

  @@end:

    RET
ENDP physicsHandler

PROC WaitVBI
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
ENDP WaitVBI


PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

	CALL __keyb_installKeyboardHandler
  CALL setVideoMode, 13H
  CALL fillBackground, 00H
  CALL draw, OFFSET level, 0, 0

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL fillBackground, 00H
    CALL draw, OFFSET level, 0, 0
    CALL drawSprite, OFFSET character, OFFSET player
    CALL WaitVBI
    CALL updateVideoBuffer
	  MOV AL, [__keyb_rawScanCode] ; last pressed key
	  CMP AL, 01H
	  JNE	@@gameLoop
  CALL exit

ENDP main

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

  player    Player  <FLOOR, 20>
  
  level DB "lvl1.bin", 0	
  
  character DB "player.bin", 0

  ; keys to be tracked
  keytracker  DW 3
              DB 75, 4BH  ; left key
              DB 77, 4DH  ; right key
              DB 72, 48H  ; up key
  
  openErrorMsg db "could not open file", 13, 10, '$'
  readErrorMsg db "could not read data", 13, 10, '$'
  closeErrorMsg db "error during file closing", 13, 10, '$'
  
;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  dbuff DD (SCRW*SCRH)/4 DUP(?)
  filebuff DD (SCRW*SCRH)/4 DUP(?)

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END main

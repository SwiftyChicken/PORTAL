;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/DRAW.INC"

FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen witdth
SCRH EQU 200	; screen height
SCALE EQU 4   ; image scale
FLOOR EQU 42

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

PROC fillBackground
  ARG @@color:BYTE
  USES EAX, ECX, EDI

  MOV EDI, OFFSET dbuff ; Frame buffer start address
  
  MOV AL, [@@color]
  MOV AH, AL
  MOV CX, AX
  SHL EAX, 16
  MOV AX, CX


  MOV ECX, SCRW * SCRH/4 ; Amount of pixels on screen

  REP STOSD

  RET

ENDP fillBackground

PROC draw
  ARG @@image:DWORD, @@row:DWORD, @@column:DWORD
  USES ESI, EDI, ECX, EAX, EBX, EDX

	; open file, get filehandle in AX
	MOV AL, 0 ; read only
	MOV EDX, [@@image]
	MOV AH, 3DH
	INT 21H

	MOV  EDX, OFFSET openErrorMsg
	JC @@print_error ; carry flag is set if error occurs

	; read file data
	MOV BX, AX ; move filehandle to bx
	MOV ECX, (SCRW*SCRH)/4
	MOV EDX, OFFSET filebuff
	MOV AH, 3FH
	INT 21H

	MOV  EDX, OFFSET readErrorMsg
	JC @@print_error

	; close file
	MOV AH, 3EH
	INT 21H

	MOV  EDX, OFFSET closeErrorMsg
	JC @@print_error
	
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

  RET

ENDP draw

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

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

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

END

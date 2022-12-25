;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/KEYB.INC"
INCLUDE "INC/DRAW.INC"
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

;;;;;;;;;;;;;;;;;;;;; GAME LOGIC ;;;;;;;;;;;;;;;;;;;;;;;;::::

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
    SUB [player.vx], 1
    JMP @@end

  @@right:
    ADD [player.vx], 1
    JMP @@end

  @@up:
    CMP [player.y], FLOOR
    JNE @@end
    SUB [player.vy], 5
    JMP @@end

  @@end:

    RET
ENDP actionHandler

PROC physicsHandler
  USES EAX, EBX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]
  
  MOV EBX, [player.vy]
  ADD EBX, [player.y]

	CALL collisionHandler, EAX, EBX
		JCXZ @@dontMove 			; don't move if ECX is 0
		MOV [player.x], EAX	  ; move player
		MOV [player.vx], 0

		CMP EBX, FLOOR
		JG @@dontMove
		MOV [player.y], EBX   ; move player
		INC [player.vy] ; gravity

	@@dontMove:

    RET
ENDP physicsHandler


;; TO DO
PROC collisionHandler ; checkt lvl en lijst met portals
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX, EDI  ; return value in ECX

	;MOV EDI, 5		; size block
	;CALL loadFile, OFFSET level

	;MOV EAX, [@@y0]
	;DIV EDI
	;SHL EAX, 4		; times 16 = levelmatrix width
	;MOV EBX, EAX

	MOV EAX, [@@x0]
	;DIV EDI
	CMP EAX, 0		; left out of bounds
	JNG @@return0 
	;CMP EAX, 80 	; right out of bounds
	;JG @@return0
	
	;ADD EAX, EBX	; coord offset in EAX

	;MOV EAX, [OFFSET current + EAX]
	;CMP EAX, 0000
	;JE @@return1

	; CMP EAX,	; test for portal 
	; JE @@return2

	@@return1:		; move, no collision
		MOV ECX, 1
		RET

	@@return0:		; don't move, wall collision
		MOV ECX, 0
		RET

	; Special cases:
	@@return2:		; trigger, portal
		MOV ECX, 2
		RET

	@@return3:		; trigger, elevator (end of level)
		MOV ECX, 3
		RET

ENDP collisionHandler 

;;;;;;;;;;;;;;;;;;;;; GENERAL IO ;;;;;;;;;;;;;;;;;;;;;;;;::::

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

PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

	CALL __keyb_installKeyboardHandler
  CALL setVideoMode, 13H
  CALL updateColourPalette, 6
  CALL fillBackground, 00H
  CALL draw, OFFSET current, 0, 0

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL fillBackground, 00H
    CALL draw, OFFSET current, 0, 0
    CALL draw, OFFSET character, [player.x], [player.y]
    CALL waitVBI
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
  player    Player  <20, FLOOR, 0, 0>
  
  level DB "VIEW/IMG/LVL1.BIN", 0	
  current DB "VIEW/IMG/LEVEL.BIN", 0	
  
  character DB "VIEW/IMG/PLAYER.BIN", 0

  ; keys to be tracked
  keytracker  DW 3
              DB 75, 4BH  ; left key
              DB 77, 4DH  ; right key
              DB 72, 48H  ; up key
  
; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END main

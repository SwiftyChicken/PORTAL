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

PROC physicsHandlerPrev
  USES EAX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]
  MOV [player.x], EAX
  MOV [player.vx], 0
  
  MOV EAX, [player.vy]
  ADD EAX, [player.y]
  CMP EAX, FLOOR
  JG @@end
  MOV [player.y], EAX
  INC [player.vy] 			;gravity

  @@end:

    RET
ENDP physicsHandlerPrev

PROC physicsHandler
  USES EAX, EBX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]
  
  MOV EBX, [player.vy]
  ADD EBX, [player.y]

	CALL collisionHandler, EAX, EBX

    RET
ENDP physicsHandler

;; TO DO
PROC collisionHandler
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX, ECX, EDX

	MOV EAX, [@@x0]
  MOV [player.x], EAX				 ; move player
  MOV [player.vx], 0

	MOV EBX, [@@y0]
  CMP EBX, FLOOR
  JG @@dontMove
	MOV [player.y], EBX 			 ; move player
  INC [player.vy] ; gravity

	@@dontMove:

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
  CALL draw, OFFSET level, 0, 0

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL fillBackground, 00H
    CALL draw, OFFSET level, 0, 0
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
  player    Player  <20, FLOOR>
  
  level DB "VIEW/IMG/LVL1.BIN", 0	
  
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

;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;-----------------------------------------------------------
; INCLUDE
;-----------------------------------------------------------
INCLUDE "INC/KEYB.INC"
INCLUDE "INC/DRAW.INC"
INCLUDE "INC/PHYSICS.INC"

;-----------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------
FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen witdth
SCRH EQU 200	; screen height
SCALE EQU 4   ; image scale

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

;;;;;;;;;;;;;;;;;;;;; GENERAL IO ;;;;;;;;;;;;;;;;;;;;;;;;::::

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
    CMP [player.vy], 0
    JLE @@end
    SUB [player.vy], 5

  @@end:
    RET
ENDP actionHandler

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

PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

	CALL __keyb_installKeyboardHandler
  CALL setVideoMode, 13H
  CALL updateColourPalette, 6
  CALL fillBackground, 00H
  CALL loadLevel, OFFSET level
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

  RET
ENDP main

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  ;; IMAGES FILES
  level DB "VIEW/IMG/LVL1.BIN", 0	
  current DB "VIEW/IMG/LEVEL.BIN", 0	
  character DB "VIEW/IMG/PLAYER.BIN", 0

  ; keys to be tracked
  keytracker  DW 3        ; amount of keys to track
              DB 75, 4BH  ; left key
              DB 77, 4DH  ; right key
              DB 72, 48H  ; up key
  
; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END main

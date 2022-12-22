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

PROC checkEscape
  USES EAX


	RET
ENDP checkEscape

PROC exit
	USES EAX
	CALL __setVideoMode, 03H
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

PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

	CALL __keyb_installKeyboardHandler
  CALL __setVideoMode, 13H
  CALL __fillBackground, 00H
  CALL __draw, OFFSET level, 0, 0

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL __fillBackground, 00H
    CALL __draw, OFFSET level, 0, 0
    CALL __draw, OFFSET character, [player.x], [player.y]
    CALL __waitVBI
    CALL __updateVideoBuffer
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
  
  level DB "VIEW/IMG/LVL1.BIN", 0	
  
  character DB "VIEW/IMG/PLAYER.BIN", 0

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

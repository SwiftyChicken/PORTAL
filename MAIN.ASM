;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;-----------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------
FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen witdth
SCRH EQU 200	; screen height

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC setVideoMode
  ARG @@mode:BYTE
  USES EAX

  MOVZX AX, [@@mode]
  INT 10h

  RET

ENDP setVideoMode

PROC fillBackground
  ARG @@color:BYTE
  USES EAX, ECX, EDI

  MOV EDI, FBADR ; Frame buffer start address
  
  MOV AL, [@@color]

  MOV ECX, SCRW * SCRH ; Amount of pixels on screen

  REP STOSB

  RET

ENDP fillBackground

PROC checkEscape
	ARG 	@@key:BYTE
  USES EAX

  MOV	AH,00H
	INT	16H
	CMP	AL,[@@key]

	RET
ENDP checkEscape

PROC exit
	USES EAX
	CALL setVideoMode, 03H
	MOV	AX,04C00H
	INT 21H
	RET
ENDP exit

PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

  CALL setVideoMode, 13H
  CALL fillBackground, 0FH

  @@gameLoop:
    
    CALL checkEscape
	  JNE	@@gameLoop
    
  CALL exit
ENDP main

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
line DB 0FH
     DB 0FH
     DB 0FH
     DB 0FH

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100h

END main

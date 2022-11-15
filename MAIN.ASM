;-----------------------------------------------------------
; MAIN function of the Portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC setVideoMode
  ARG @@mode:BYTE
  USES EAX

  MOV AX, OFFSET @@mode
  INT 10h

  RET

ENDP setVideoMode

PROC main
  STI ;enable interupt
  CLD 
  
  PUSH DS
  POP ES

  CALL setVideoMode, 13h

  ; Test game loop
  MOV EDI, 0A0000H ;Frame buffer address
  ADD EDI, 320*2 + 10
  MOV AL, 15
  MOV [EDI], AL

  @@gameLoop:
    CMP AL, 10
    JNE @@gameLoop
  
ENDP main

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100h

END

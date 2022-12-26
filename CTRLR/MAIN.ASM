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
INCLUDE "INC/STD.INC"
INCLUDE "INC/KEYB.INC"
INCLUDE "INC/DRAW.INC"
INCLUDE "INC/LOGIC.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

;;;;;;;;;;;;;;;;;;;;; GENERAL IO ;;;;;;;;;;;;;;;;;;;;;;;;::::

PROC releaseHandler
	CMP	AL, N_KEY
  JE @@N_key
  RET

  @@N_key:
    MOV [N_released], TRUE
    RET

ENDP releaseHandler

PROC pressHandler
	CMP	AL, LEFT_KEY
  JE @@left

	CMP	AL, RIGHT_KEY
  JE @@right
  
	CMP	AL, UP_KEY
  JE @@up

	CMP	AL, N_KEY
  JE @@N_key

  RET

  @@left:
    MOV [player.direction], LEFT
    SUB [player.vx], 1

    ; Don't change frame mid air
    CMP [player.jumping], FALSE
    JNE @@end

    ; Update Frame
    CALL getNextFrame, OFFSET character_L.current,[character_L.length], [character_L.current]
    CALL updateFrame, OFFSET character_L.image, OFFSET character_L.images, [character_L.current]

    RET

  @@right:
    MOV [player.direction], RIGHT
    ADD [player.vx], 1

    ; Don't change frame mid air
    CMP [player.jumping], FALSE
    JNE @@end

    ; Update Frame
    CALL getNextFrame, OFFSET character_R.current,[character_R.length], [character_R.current]
    CALL updateFrame, OFFSET character_R.image, OFFSET character_R.images, [character_R.current]

    RET

  @@up:
    CMP [player.jumping], FALSE
    JNE @@end
      MOV [player.jumping], TRUE

      ; Reset Frame mid air
      MOV [character_L.current], 0
      MOV [character_L.image], OFFSET character_L_Images
      MOV [character_R.current], 0
      MOV [character_R.image], OFFSET character_R_Images

      CMP [player.vy], 0
      JNE @@end
        MOV [player.vy], -5
        RET

  @@N_key:
    CMP [N_released], FALSE
    JE @@end
      MOV [N_released], FALSE
      MOV [player.x], 0
      MOV [player.y], FLOOR
      ; Load next LEVEL
      CALL getNextFrame, OFFSET levels.current, [levels.length], [levels.current]
      CALL updateFrame, OFFSET levels.image, OFFSET levels.images, [levels.current]
      ; Set next LEVEL
      CALL loadLevel, [levels.image]
      CALL updateLevel, [levels.image]
    RET

  @@end:
    RET
ENDP pressHandler

PROC keyboardHandler
  USES EAX, ECX, ESI
  
  LEA ESI, [keytracker]
  LODSW
  MOV ECX, EAX

  @@loop:
    LODSB
    MOVZX EAX, AL
    MOV BL, [offset __keyb_keyboardState + EAX]
    CMP BL, TRUE
    JE @@pressed
      CMP BL, FALSE
    JE @@release
    JMP @@next
      @@pressed:
        LODSB
        CALL pressHandler
        JMP @@next

      @@release:
        LODSB
        CALL releaseHandler

      @@next:
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
  CALL updateColourPalette, 4
  CALL fillBackground, 00H
  CALL loadLevel, [levels.image]
  CALL updateLevel, [levels.image]
  CALL draw, OFFSET current, 0, 0

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL fillBackground, 00H
    CALL draw, OFFSET current, 0, 0
    CMP [player.direction], RIGHT
    JE @@right
      CALL draw, [character_L.image], [player.x], [player.y]
      JMP @@next

    @@right:
      CALL draw, [character_R.image], [player.x], [player.y]

    @@next:
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

  levels Animated <5, 0, OFFSET levels_list, OFFSET levels_list>
  levels_list DB "VIEW/IMG/LVL1.BIN", 0	
              DB "VIEW/IMG/LVL2.BIN", 0	
              DB "VIEW/IMG/LVL3.BIN", 0	
              DB "VIEW/IMG/LVL4.BIN", 0	
              DB "VIEW/IMG/LVL5.BIN", 0	

  current DB "VIEW/IMG/LEVEL.BIN", 0	

  ; keys to be tracked
  keytracker  DW 4        ; amount of keys to track
              DB 75, LEFT_KEY  ; left key
              DB 77, RIGHT_KEY  ; right key
              DB 72, UP_KEY  ; up key
              DB 49, N_KEY  ; N key -> load next Level

  N_released DB TRUE

  character_R Animated <4, 0, OFFSET character_R_Images, OFFSET character_R_Images>
  character_R_Images DB "VIEW/IMG/P_R_0.BIN", 0
                     DB "VIEW/IMG/P_R_1.BIN", 0
                     DB "VIEW/IMG/P_R_0.BIN", 0
                     DB "VIEW/IMG/P_R_2.BIN", 0

  character_L Animated <4, 0, OFFSET character_L_Images, OFFSET character_L_Images>
  character_L_Images DB "VIEW/IMG/P_L_0.BIN", 0
                     DB "VIEW/IMG/P_L_1.BIN", 0
                     DB "VIEW/IMG/P_L_0.BIN", 0
                     DB "VIEW/IMG/P_L_2.BIN", 0
;-----------------------------------------------------------
; UNSIGNED DATA
;-----------------------------------------------------------
UDATASEG
  up_pressed DB ?

; ----------------------------------------------------------
; STACK
; ----------------------------------------------------------
STACK 100H

END main

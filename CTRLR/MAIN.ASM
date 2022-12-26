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

	CMP	AL, LEFT_KEY
  JE @@left

	CMP	AL, RIGHT_KEY
  JE @@right

	CMP	AL, N_KEY
  JE @@N_key
  RET

  @@left:
    ; Reset Frame mid air
    CALL resetAnimated, OFFSET character_L
    RET

  @@right:
    CALL resetAnimated, OFFSET character_R
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
    CALL getNextFrame, OFFSET character_L
    CALL updateFrame, OFFSET character_L

    RET

  @@right:
    MOV [player.direction], RIGHT
    ADD [player.vx], 1

    ; Don't change frame mid air
    CMP [player.jumping], FALSE
    JNE @@end

    ;; Update Frame
    CALL getNextFrame, OFFSET character_R
    CALL updateFrame, OFFSET character_R

    RET

  @@up:
    CMP [player.jumping], FALSE
    JNE @@end
      MOV [player.jumping], TRUE

      ; Reset Frame mid air
      CALL resetAnimated, OFFSET character_L
      CALL resetAnimated, OFFSET character_R
      
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
      CALL getNextFrame, OFFSET levels

      CALL updateFrame, OFFSET levels
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

PROC checkLevelFinished
  CMP [player.x], FINISH
  JNE @@end
    MOV [player.x], 0
    MOV [player.y], FLOOR

    CALL getNextFrame, OFFSET levels
    CALL updateFrame, OFFSET levels

    CALL loadLevel, [levels.image]
    CALL updateLevel, [levels.image]
  @@end:
    RET
ENDP checkLevelFinished

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
  CALL loadLevel, [levels.image]
  CALL updateLevel, [levels.image]
  CALL drawLevel

  @@gameLoop:
    CALL keyboardHandler
    CALL physicsHandler
    CALL drawLevel
    CMP [player.direction], RIGHT
    JE @@right
      CALL draw, [character_L.image], [player.x], [player.y]
      JMP @@next

      @@right:
        CALL draw, [character_R.image], [player.x], [player.y]

    @@next:
      CALL waitVBI
      CALL updateVideoBuffer
      CALL checkLevelFinished
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
  ; keys to be tracked
  keytracker  DW 4        ; amount of keys to track
              DB 75, LEFT_KEY  ; left key
              DB 77, RIGHT_KEY  ; right key
              DB 72, UP_KEY  ; up key
              DB 49, N_KEY  ; N key -> load next Level

  N_released DB TRUE

  levels Animated <5, 0, OFFSET levels_list, OFFSET levels_list>
  levels_list DB "VIEW/IMG/LVL1.BIN", 0	
              DB "VIEW/IMG/LVL2.BIN", 0	
              DB "VIEW/IMG/LVL3.BIN", 0	
              DB "VIEW/IMG/LVL4.BIN", 0	
              DB "VIEW/IMG/LVL5.BIN", 0	
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

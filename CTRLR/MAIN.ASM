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

;;;;;;;;;;;;;;;;;;;;;;;;; KEYBOARD FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC releaseHandler

	CMP	AL, LEFT_KEY
  JE @@left

	CMP	AL, RIGHT_KEY
  JE @@right

	CMP	AL, N_KEY
  JE @@N_key

	CMP	AL, S_KEY
  JE @@swap_portal

  ;; Shooting Keys
	CMP	AL, Z_KEY
  JE @@shoot_up

	CMP	AL, E_KEY
  JE @@shoot_up_right

	CMP	AL, D_KEY
  JE @@shoot_right

	CMP	AL, C_KEY
  JE @@shoot_down_right

	CMP	AL, X_KEY
  JE @@shoot_down

	CMP	AL, W_KEY
  JE @@shoot_down_left

	CMP	AL, Q_KEY
  JE @@shoot_left

	CMP	AL, A_KEY
  JE @@shoot_up_left
  RET

  @@left:
    ; Reset Frame mid air
    CALL resetAnimated, OFFSET character_L
    CALL resetAnimated, OFFSET character_L
    RET

  @@right:
    CALL resetAnimated, OFFSET character_R
    RET

  @@N_key:
    MOV [N_released], TRUE
    RET

  @@swap_portal:
    RET

  @@shoot_up:
    RET

  @@shoot_up_right:
    RET

  @@shoot_right:
    RET

  @@shoot_down_right:
    MOV [C_released], TRUE
    RET

  @@shoot_down:
    MOV [X_released], TRUE
    RET

  @@shoot_down_left:
    RET

  @@shoot_left:
    RET

  @@shoot_up_left:
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

	CMP	AL, S_KEY
  JE @@swap_portal

  ;; Shooting Keys
	CMP	AL, Z_KEY
  JE @@shoot_up

	CMP	AL, E_KEY
  JE @@shoot_up_right

	CMP	AL, D_KEY
  JE @@shoot_right

	CMP	AL, C_KEY
  JE @@shoot_down_right

	CMP	AL, X_KEY
  JE @@shoot_down

	CMP	AL, W_KEY
  JE @@shoot_down_left

	CMP	AL, Q_KEY
  JE @@shoot_left

	CMP	AL, A_KEY
  JE @@shoot_up_left
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

      MOV [portal_B.active], FALSE
      MOV [portal_A.active], FALSE
    RET

  @@swap_portal:
    RET

  @@shoot_up:
    CMP [C_released], FALSE
    JE @@end
      MOV [C_released], FALSE
      CALL createPortal, [player.x], [player.y], UP
    RET

  @@shoot_up_right:
    RET

  @@shoot_right:
    RET

  @@shoot_down_right:
    RET

  @@shoot_down:
    CMP [X_released], FALSE
    JE @@end
      MOV [X_released], FALSE
      CALL createPortal, [player.x], [player.y], DOWN
    RET

  @@shoot_down_left:
    RET

  @@shoot_left:
    RET

  @@shoot_up_left:
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;; STATUS CHECKS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC checkLevelFinished
  CMP [player.x], FINISH
  JNE @@end
    MOV [player.x], 0
    MOV [player.y], FLOOR

    CALL getNextFrame, OFFSET levels
    CALL updateFrame, OFFSET levels

    CALL loadLevel, [levels.image]
    CALL updateLevel, [levels.image]

    MOV [portal_B.active], FALSE
    MOV [portal_A.active], FALSE
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
      JMP @@skip_right

      @@right:
        CALL draw, [character_R.image], [player.x], [player.y]

    @@skip_right:
      CMP [portal_B.active], FALSE
      JE @@prt_a
        CALL draw, [PRT_B.image], [portal_B.x], [portal_B.y]
      @@prt_a:
        CMP [portal_A.active], FALSE
        JE @@next
          CALL draw, [PRT_A.image], [portal_A.x], [portal_A.y]

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
  keytracker  DW 13        ; amount of keys to track
              DB 75, LEFT_KEY  ; left key
              DB 77, RIGHT_KEY  ; right key
              DB 72, UP_KEY  ; up key
              DB 49, N_KEY  ; N key -> load next Level
              DB 62, S_KEY  ; S key -> swap portal positions
              DB 78, Z_KEY  ; Z key -> shoot portal up
              DB 79, E_KEY  ; E key -> shoot portal up right
              DB 63, D_KEY  ; D key -> shoot portal right
              DB 46, C_KEY  ; C key -> shoot portal down right
              DB 45, X_KEY  ; X key -> shoot portal down
              DB 44, W_KEY  ; W key -> shoot portal down left
              DB 61, Q_KEY  ; Q key -> shoot portal left 
              DB 77, A_KEY  ; A key -> shoot portal up left

  N_released DB TRUE
  S_released DB TRUE
  Z_released DB TRUE
  E_released DB TRUE
  D_released DB TRUE
  C_released DB TRUE
  X_released DB TRUE
  W_released DB TRUE
  Q_released DB TRUE
  A_released DB TRUE

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

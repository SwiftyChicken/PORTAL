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

PROC nextLevel
    MOV [player.x], 0
    MOV [player.y], FLOOR

    CALL getNextFrame, OFFSET levels
    CALL updateFrame, OFFSET levels

    CALL loadLevel, [levels.image]
    CALL updateLevel, [levels.image]

    MOV [portal_B.active], FALSE
    MOV [portal_A.active], FALSE

    RET
ENDP nextLevel

;;;;;;;;;;;;;;;;;;;;;;;;; KEYBOARD FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC pressHandler
	CMP	AL, LEFT_KEY
  JNE @@check_right
    MOV [player.direction], LEFT
    SUB [player.vx], 1

    ; Don't change frame mid air
    CMP [player.jumping], FALSE
    JNE @@return

    ; Update Frame
    CALL getNextFrame, OFFSET character_L
    CALL updateFrame, OFFSET character_L
    RET

  @@check_right:
	  CMP	AL, RIGHT_KEY
    JNE @@check_up
      MOV [player.direction], RIGHT
      ADD [player.vx], 1

      ; Don't change frame mid air
      CMP [player.jumping], FALSE
      JNE @@return

      ;; Update Frame
      CALL getNextFrame, OFFSET character_R
      CALL updateFrame, OFFSET character_R
      RET

  @@check_up:
	  CMP	AL, UP_KEY
    JNE @@check_n
      CMP [player.jumping], FALSE
      JNE @@return
        MOV [player.jumping], TRUE

        ; Reset Frame mid air
        CALL resetAnimated, OFFSET character_L
        CALL resetAnimated, OFFSET character_R
        
        CMP [player.vy], 0
        JNE @@return
          MOV [player.vy], -3
          RET

  @@check_n:
	  CMP	AL, N_KEY
    JNE @@check_s
      CMP [N_released], FALSE
      JE @@return
        MOV [N_released], FALSE
        CALL nextLevel
      RET

  @@check_s:
	  CMP	AL, S_KEY
    JNE @@check_z
      CMP [S_released], FALSE
      JE @@return
        MOV [S_released], FALSE
        CALL swapPortals
      RET

  @@check_z:
	  CMP	AL, Z_KEY
    JNE @@check_e
      CMP [Z_released], FALSE
      JE @@return
        MOV [Z_released], FALSE
        CALL createPortal, [player.x], [player.y], UP
      RET

  @@check_e:
	  CMP	AL, E_KEY
    JNE @@check_d
      CMP [E_released], FALSE
      JE @@return
        MOV [E_released], FALSE
        CALL createPortal, [player.x], [player.y], UP_RIGHT
      RET

  @@check_d:
	  CMP	AL, D_KEY
    JNE @@check_c
      CMP [D_released], FALSE
      JE @@return
        MOV [D_released], FALSE
        CALL createPortal, [player.x], [player.y], RIGHT
      RET

  @@check_c:
	  CMP	AL, C_KEY
    JNE @@check_x
      CMP [C_released], FALSE
      JE @@return
        MOV [C_released], FALSE
        CALL createPortal, [player.x], [player.y], DOWN_RIGHT
      RET

  @@check_x:
	  CMP	AL, X_KEY
    JNE @@check_w
      CMP [X_released], FALSE
      JE @@return
        MOV [X_released], FALSE
        CALL createPortal, [player.x], [player.y], DOWN
      RET

  @@check_w:
	  CMP	AL, W_KEY
    JNE @@check_q
      CMP [W_released], FALSE
      JE @@return
        MOV [W_released], FALSE
        CALL createPortal, [player.x], [player.y], DOWN_LEFT
      RET

  @@check_q:
	  CMP	AL, Q_KEY
    JNE @@check_a
      CMP [Q_released], FALSE
      JE @@return
        MOV [Q_released], FALSE
        CALL createPortal, [player.x], [player.y], LEFT
      RET

  @@check_a:
	  CMP	AL, A_KEY
    JNE @@return
      CMP [A_released], FALSE
      JE @@return
        MOV [A_released], FALSE
        CALL createPortal, [player.x], [player.y], UP_LEFT
      RET

  @@return:
    RET
ENDP pressHandler

PROC releaseHandler
	CMP	AL, LEFT_KEY
  JNE @@check_right
    ; Reset Frame mid air
    CALL resetAnimated, OFFSET character_L
    CALL resetAnimated, OFFSET character_L
    RET

  @@check_right:
	  CMP	AL, RIGHT_KEY
    JNE @@check_n
      CALL resetAnimated, OFFSET character_R
      RET

  @@check_n:
	  CMP	AL, N_KEY
    JNE @@check_s
      MOV [N_released], TRUE
      RET

  @@check_s:
	  CMP	AL, S_KEY
    JNE @@check_z
      MOV [S_released], TRUE
      RET

  ;; Shooting Keys
  @@check_z:
	  CMP	AL, Z_KEY
    JNE @@check_e
      MOV [Z_released], TRUE
      RET

  @@check_e:
	  CMP	AL, E_KEY
    JNE @@check_d
      MOV [E_released], TRUE
      RET

  @@check_d:
	  CMP	AL, D_KEY
    JNE @@check_c
      MOV [D_released], TRUE
      RET

  @@check_c:
	  CMP	AL, C_KEY
    JNE @@check_x
      MOV [C_released], TRUE
      RET

  @@check_x:
	  CMP	AL, X_KEY
    JNE @@check_w
      MOV [X_released], TRUE
      RET

  @@check_w:
	  CMP	AL, W_KEY
    JNE @@check_q
      MOV [W_released], TRUE
      RET

  @@check_q:
	  CMP	AL, Q_KEY
    JNE @@check_a
      MOV [Q_released], TRUE
      RET

  @@check_a:
	  CMP	AL, A_KEY
    JNE @@return
      MOV [A_released], TRUE
      RET

  @@return:
    RET
ENDP releaseHandler

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
  JNE @@return
    CALL nextLevel
  @@return:
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
    ;; INPUT & LOGIC UPDATES
    CALL keyboardHandler
    CALL physicsHandler

    ;; DRAW FUNCTIONS
    CALL drawLevel

    ;;DRAW -> PLAYER ANIMATION
    CMP [player.direction], RIGHT
    JE @@right
      CALL draw, [character_L.image], [player.x], [player.y], TRUE
      JMP @@laser_animation

      @@right:
        CALL draw, [character_R.image], [player.x], [player.y], TRUE

    ;;DRAW -> LASER ANIMATION
    @@laser_animation:
      CMP [laser.active], FALSE
      JE @@portal_animation
        CALL useLaser
        CALL drawLaser, [laser.x0], [laser.y0], [laser.x1], [laser.y1], [laser.active], [laser.direction]

    ;;DRAW -> PORTAL ANIMATION
    @@portal_animation:
      CMP [portal_B.active], FALSE
      JE @@prt_a
        PUSH EAX
          CALL setPortalFrame, OFFSET PRT_B, [portal_B.direction]
          
          MOV EAX, [PRT_B.current]
          CALL getNextFrame, EAX
          CALL updateFrame, EAX
          CALL draw, [EAX + Animated.image], [portal_B.x], [portal_B.y], FALSE
        POP EAX

      @@prt_a:
        CMP [portal_A.active], FALSE
        JE @@next
          PUSH EAX
            CALL setPortalFrame, OFFSET PRT_A, [portal_A.direction]

            MOV EAX, [PRT_A.current]
            CALL getNextFrame, EAX
            CALL updateFrame, EAX
            CALL draw, [EAX + Animated.image], [portal_A.x], [portal_A.y], FALSE
          POP EAX

      ;; GAME CHECKS & SCREEN UPDATES
      @@next:
        CALL waitVBI
        CALL updateVideoBuffer
        CALL checkLevelFinished
	      MOVZX EAX, [__keyb_rawScanCode] ; last pressed key
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
              DB 31, S_KEY  ; S key -> swap portal positions
              DB 17, Z_KEY  ; Z key -> shoot portal up
              DB 18, E_KEY  ; E key -> shoot portal up right
              DB 32, D_KEY  ; D key -> shoot portal right
              DB 46, C_KEY  ; C key -> shoot portal down right
              DB 45, X_KEY  ; X key -> shoot portal down
              DB 44, W_KEY  ; W key -> shoot portal down left
              DB 30, Q_KEY  ; Q key -> shoot portal left 
              DB 16, A_KEY  ; A key -> shoot portal up left

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

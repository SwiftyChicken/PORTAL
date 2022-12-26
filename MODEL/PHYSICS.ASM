;-----------------------------------------------------------
; Contains all the physics procedure need for the portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;-----------------------------------------------------------
; INCLUDE
;-----------------------------------------------------------
INCLUDE "INC/STD.INC"
INCLUDE "INC/FILE.INC"
INCLUDE "INC/PHYSICS.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC physicsHandler
  USES EAX, EBX, EDX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]

  CALL checkCollision, EAX, [player.y]
  CMP DL, FALSE
  JNE @@dont_move_x
    MOV [player.x], EAX
  @@dont_move_x:
    MOV [player.vx], 0
  
  @@move_y:
    MOV EAX, [player.vy]
    SAR EAX, SLOW_DOWN      ; Slown down vertical movement
    ADD EAX, [player.y]

    CALL checkCollision, [player.x], EAX
    CMP DL, FALSE
    JNE @@slow_down_y
      MOV [player.y], EAX
      INC [player.vy]
      JMP @@end
  @@slow_down_y:
    CMP [player.vy], 0
    JL @@slow_up
    CMP [player.vy], 0
    JG @@slow_down
    
    @@slow_up:
      INC [player.vy]
      JMP @@move_y

    @@slow_down:
      DEC [player.vy]
      MOV EAX, [player.vy]
      SAR EAX, SLOW_DOWN
      CMP EAX, 0  ;IF 0 it has hit the ground
      JE @@dont_move_y
      JMP @@move_y

  @@dont_move_y:
    MOV [player.vy], 0
    MOV [player.jumping], FALSE

  @@end:
    RET
ENDP physicsHandler

; AABB collision
PROC checkCollision
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

	MOV EAX, [@@x0]
	ADD EAX, BLOCK_SIZE - 1
	MOV EBX, [@@y0]
	ADD EBX, BLOCK_SIZE - 1

  CALL collisionHandler, [@@x0], [@@y0] ; check upper left for collision
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, EAX, [@@y0]		; check upper right for collision
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, [@@x0], EBX		; check lower left for collision
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, EAX, EBX				; check lower right for collision

  @return:
    RET
ENDP checkCollision

; Checks level and list of portals
PROC collisionHandler 
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

  ;; Check for out of bound
  CMP [@@x0], START_BOUNDRY
  JL @outOfBound

  CMP [@@x0], WIDTH_BOUNDRY
  JG @outOfBound

  CMP [@@y0], START_BOUNDRY
  JL @outOfBound

  CMP [@@y0], HEIGHT_BOUNDRY
  JG @outOfBound

  ; CONVERT Y: 80x50 -> 16x10
	MOV EAX, [@@y0]
	MOV EBX, BLOCK_SIZE
  LEA EDX, [0]          ;Clear EDX
	DIV EBX
	IMUL EAX, 16
	PUSH EAX

  ;; CONVERT X in EAX: 80x50 -> 16x10
	MOV EAX, [@@x0]
	MOV EBX, BLOCK_SIZE
  LEA EDX, [0]          ;Clear EDX
	DIV EBX
	POP EBX
	ADD EAX, EBX

  MOV DL, [OFFSET level + EAX]
  RET

  @outOfBound:
    MOV DL, TRUE
    RET

ENDP collisionHandler 

PROC loadLevel
	ARG @@fileName:DWORD
	CALL loadFile, [@@fileName], OFFSET level, LEVEL_SIZE

	RET
ENDP

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  player  Player  <0, FLOOR>

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

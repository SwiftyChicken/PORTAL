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
			
  CALL checkCollision, EAX, [player.y] ; check collision on new x
  CMP DL, FALSE
  JNE @@dont_move_x			; if collision = FALSE
    MOV [player.x], EAX ; move x
  @@dont_move_x:				; if collision = TRUE
    MOV [player.vx], 0
  
  MOV EAX, [player.vy]
  SAR EAX, 1					; divide by 2
  ADD EAX, [player.y]

  CALL checkCollision, [player.x], EAX ; check collision on new y
  CMP DL, FALSE
  JNE @@reset_y
    MOV [player.y], EAX ; move y
    INC [player.vy]			; gravity
    JMP @@end						; done
  @@reset_y:
    MOV [player.vy], 1
    MOV EAX, [player.y]
    INC EAX

    CALL checkCollision, [player.x], EAX ; if collision on y + 1, on the floor
    CMP DL, FALSE
    JNE @@dont_move_y
    MOV [player.y], EAX
    JMP @@end

  @@dont_move_y:
    MOV [player.vy], 0
    MOV [player.jumping], FALSE

  @@end:
    RET
ENDP physicsHandler

; Check AABB collision
PROC checkCollision
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

	MOV EAX, [@@x0]
	ADD EAX, BLOCK_SIZE - 1
	MOV EBX, [@@y0]
	ADD EBX, BLOCK_SIZE - 1

  CALL collisionHandler, [@@x0], [@@y0] ; check collision left upper
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, EAX, [@@y0]		; check collision right upper
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, [@@x0], EBX		; check collision left lower
  CMP DL, FALSE
  JNE @return

  CALL collisionHandler, EAX, EBX				; check collision right lower

  @return:
    RET
ENDP checkCollision

PROC collisionHandler ; checkt lvl en lijst met portals
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

  ;; Check for out of bound
  CMP [@@x0], 0
  JL @outOfBound

  CMP [@@x0], 80
  JG @outOfBound

  CMP [@@y0], 0
  JL @outOfBound

  CMP [@@y0], 50
  JG @outOfBound

  ; CONVERT Y: 80x50 -> 16x10
	MOV EAX, [@@y0]
	MOV EBX, BLOCK_SIZE
  LEA EDX, [0]          ;Clear EDX
	DIV EBX
	IMUL EAX, 16
	PUSH EAX				; (y / BLOCK_SIZE) * 16

  ;; CONVERT X in EAX: 80x50 -> 16x10
	MOV EAX, [@@x0]
	MOV EBX, BLOCK_SIZE
  LEA EDX, [0]          ;Clear EDX
	DIV EBX
	POP EBX
	ADD EAX, EBX		; + (x / BLOCK_SIZE)

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
  player  Player  <40, 20>

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

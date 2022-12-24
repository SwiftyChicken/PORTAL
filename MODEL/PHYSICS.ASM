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
INCLUDE "INC/FILE.INC"
INCLUDE "INC/PHYSICS.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC physicsHandler
  USES EAX, EDX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]

  CALL checkAABB, EAX, [player.y]
  CMP DL, 00H
  JNE @@dont_move_x
    MOV [player.x], EAX
  @@dont_move_x:
    MOV [player.vx], 0
  
  MOV EAX, [player.vy]
  ADD EAX, [player.y]

  CALL checkAABB, [player.x], EAX
  CMP DL, 00H
  JNE @@reset_y
    MOV [player.y], EAX
    INC [player.vy]
    JMP @@end
  @@reset_y:
    MOV [player.vy], 1

    MOV EAX, [player.vy]
    ADD EAX, [player.y]

    CALL checkAABB, [player.x], EAX
    CMP DL, 00H
    JNE @@dont_move_y
    MOV [player.y], EAX
    JMP @@reset_y

  @@dont_move_y:
    MOV [player.vy], 0
    MOV [player.jumping], 0

  @@end:
    RET
ENDP physicsHandler

PROC checkAABB
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

	MOV EAX, [@@x0]
	ADD EAX, BLOCK_SIZE - 1
	MOV EBX, [@@y0]
	ADD EBX, BLOCK_SIZE - 1

  CALL collisionHandler, [@@x0], [@@y0]
  CMP DL, 00H
  JNE @return

  CALL collisionHandler, EAX, [@@y0]
  CMP DL, 00H
  JNE @return

  CALL collisionHandler, [@@x0], EBX
  CMP DL, 00H
  JNE @return

  CALL collisionHandler, EAX, EBX

  @return:
    RET
ENDP checkAABB

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
    MOV DL, 01H
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
  player  Player  <5, FLOOR>

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

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
INCLUDE "INC/LOGIC.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC createPortal
  ARG @@x0, @@y0, @@direction:DWORD
  USES EAX, EBX, EDX
  ;; Center position from player
  MOV EAX, [@@x0]
  ADD EAX, 2
  MOV [@@x0], EAX

  MOV EAX, [@@y0]
  ADD EAX, 2
  MOV [@@y0], EAX

  CALL directionNext, [@@direction]  ; Load (x+ -> EAX) & (y+ -> EDX)
  PUSH EAX  ; = x+
  PUSH EDX  ; = y+

  ;; find first Block on path
  @@findBlock:

    ; Move vertically
    MOV EAX, [@@y0]
    POP EDX ; = y+
    ADD EAX, EDX
    MOV [@@y0], EAX

    MOV EBX, EDX ; save y+

    ; Move horizontally
    MOV EAX, [@@x0]
    POP EDX ; = x+
    ADD EAX, EDX
    MOV [@@x0], EAX

    PUSH EDX ; = x+
    PUSH EBX ; = y+

    CALL collisionHandler, [@@x0], [@@y0] ; check upper left for collision
    CMP DL, FALSE
    JE @@findBlock

    ;; restore Stack
    POP EBX
    POP EBX

  CMP DL, 02H ; ignore untargatable wall
  JE @@end

  CMP DL, OUT_OF_BOUND ; ignore out of bound
  JE @@end
    
  CMP [nextPortal], PORTAL_A
  JE @@create_A
  JMP @@create_B
  
  @@create_A:
    MOV [nextPortal], PORTAL_B
    MOV EAX, [@@x0]
    MOV [portal_A.x], EAX
    MOV EAX, [@@y0]
    MOV [portal_A.y], EAX
    CALL opositeDirection, [@@direction]
    MOV [portal_A.direction], EDX
    MOV [portal_A.active], TRUE
    RET

  @@create_B:
    MOV [nextPortal], PORTAL_A
    MOV EAX, [@@x0]
    MOV [portal_B.x], EAX
    MOV EAX, [@@y0]
    MOV [portal_B.y], EAX
    CALL opositeDirection, [@@direction]
    MOV [portal_B.direction], EDX
    MOV [portal_B.active], TRUE
    RET

  @@end:
    RET
ENDP createPortal

PROC swapPortals
  USES EAX, EDX
  MOV EAX, [portal_A.x]
  MOV EDX, [portal_A.y]

  PUSH [portal_B.x]
  POP [portal_A.x]

  PUSH [portal_B.y]
  POP [portal_A.y]

  MOV [portal_B.x], EAX
  MOV [portal_B.y], EDX

  RET
ENDP swapPortals

; Return FALSE in DL for next level or end of game
PROC physicsHandler
  USES EAX, EBX

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
  JL @@outOfBound

  CMP [@@x0], WIDTH_BOUNDRY
  JG @@outOfBound

  CMP [@@y0], START_BOUNDRY
  JL @@outOfBound

  CMP [@@y0], HEIGHT_BOUNDRY
  JG @@outOfBound

  ; CONVERT Y: 80x50 -> 16x10
	MOV EAX, [@@y0]
	MOV EBX, BLOCK_SIZE
  XOR EDX, EDX          ;Clear EDX
	DIV EBX
	IMUL EAX, 16
	PUSH EAX

  ;; CONVERT X in EAX: 80x50 -> 16x10
	MOV EAX, [@@x0]
	MOV EBX, BLOCK_SIZE
  XOR EDX, EDX          ;Clear EDX
	DIV EBX
	POP EBX
	ADD EAX, EBX

  MOV DL, [OFFSET level + EAX]
  RET

  @@outOfBound:
    MOV DL, OUT_OF_BOUND
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
  portal_A  Portal  <0, 0, OFFSET portal_B, OFFSET clone_A, UP>
  portal_B  Portal  <0, 0, OFFSET portal_A, OFFSET clone_B, DOWN>

  player  Player  <40, 20>
  clone_A   Player  <portal_A.x, portal_A.y>
  clone_B   Player  <portal_B.x, portal_B.y>

  nextPortal DB PORTAL_A
;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

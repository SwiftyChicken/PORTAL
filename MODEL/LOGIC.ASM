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

PROC centerPostion
  ARG @@pos_ptr:DWORD
  USES EAX, EBX

  MOV EBX, [@@pos_ptr]

  MOV EAX, BLOCK_SIZE
  SHR EAX, 1
  ADD [EBX], EAX

  RET
ENDP centerPostion

PROC tryFitHor
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX

      ;; Check if start point in wall
      CALL checkCollision, [@@x], [@@y]
      CMP DL, WALL
      JNE @@failed

      ;; Check if end point in wall
      MOV EAX, [@@x]
      ADD EAX, PORTAL_SIZE - 1
      CALL checkCollision, EAX, [@@y]
      CMP DL, WALL
      JNE @@failed

      ;; Check opennings
      MOV EAX, [@@x]
      ADD EAX, [@@x_inc]
      MOV [@@x], EAX

      MOV EAX, [@@y]
      ADD EAX, [@@y_inc]
      MOV [@@y], EAX

      ;; Check start point openning
      CALL checkCollision, [@@x], [@@y]
      CMP DL, EMPTY
      JNE @@failed

      ;; Check end point openning
      MOV EAX, [@@x]
      ADD EAX, PORTAL_SIZE - 1
      CALL checkCollision, EAX, [@@y]
      CMP DL, EMPTY
      JNE @@failed

      MOV DL, TRUE
      RET

    @@failed:
      MOV DL, FALSE
      RET
ENDP tryFitHor

PROC tryFitVert
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX

      ;; Check if start point in wall
      CALL checkCollision, [@@x], [@@y]
      CMP DL, WALL
      JNE @@failed

      ;; Check if end point in wall
      MOV EAX, [@@y]
      ADD EAX, PORTAL_SIZE - 1
      CALL checkCollision, [@@x], EAX
      CMP DL, WALL
      JNE @@failed

      ;; Check opennings
      MOV EAX, [@@x]
      ADD EAX, [@@x_inc]
      MOV [@@x], EAX

      MOV EAX, [@@y]
      ADD EAX, [@@y_inc]
      MOV [@@y], EAX

      ;; Check start point openning
      CALL checkCollision, [@@x], [@@y]
      CMP DL, EMPTY
      JNE @@failed

      ;; Check end point openning
      MOV EAX, [@@y]
      ADD EAX, PORTAL_SIZE - 1
      CALL checkCollision, [@@x], EAX
      CMP DL, EMPTY
      JNE @@failed

      MOV DL, TRUE
      RET

    @@failed:
      MOV DL, FALSE
      RET
ENDP tryFitVert

PROC tryFitPortal   ;; Return FALSE in DL if couldn't fit the portal
  ARG @@x0_ptr:DWORD, @@y0_ptr:DWORD, @@direction:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX, EBX, ECX

  ;; Load the position increments of next position (x+ -> EAX) & (y+ -> EDX)
  CALL directionNext, [@@direction]  

  ;; Save increments to restore position later
  MOV [@@x_inc], EAX
  MOV [@@y_inc], EDX
  
  CMP [@@direction], UP
  JE @@horizontally
  CMP [@@direction], DOWN
  JE @@horizontally
  JMP @@vertically

  @@horizontally:
    ;; Try to fit portal from [x-half_size => x]
    MOV ECX, PORTAL_SIZE
    SHR ECX, 1

    @@hor_try_1:
      MOV EDX, [@@y0_ptr]
      MOV EDX, [EDX]

      MOV EAX, [@@x0_ptr]
      MOV EAX, [EAX]
      SUB EAX, ECX          ; x - <half_block_size -> 0>

      PUSH EDX
      CALL tryFitHor, EAX, EDX, [@@x_inc], [@@y_inc]
      CMP DL, TRUE
      POP EDX
      JE @@succeed
        DEC ECX
        CMP ECX, 0
        JGE @@hor_try_1

    ;; Try portal from [x-size => x-half_size[
    MOV ECX, PORTAL_SIZE
    SHR ECX, 1

    @@hor_try_2:
      MOV EDX, [@@y0_ptr]
      MOV EDX, [EDX]

      MOV EAX, [@@x0_ptr]
      MOV EAX, [EAX]
      SUB EAX, PORTAL_SIZE
      ADD EAX, ECX          ; x - <block_size -> half_block_size>

      PUSH EDX
      CALL tryFitHor, EAX, EDX, [@@x_inc], [@@y_inc]
      CMP DL, TRUE
      POP EDX
      JE @@succeed
        DEC ECX
        CMP ECX, 0
        JGE @@hor_try_2
    JMP @@failed

  @@vertically:
    ;; Try portal from [y + half_size => x]
    MOV ECX, PORTAL_SIZE
    SHR ECX, 1

    @@vert_try_1:
      MOV EDX, [@@y0_ptr]
      MOV EDX, [EDX]
      SUB EDX, ECX          ; y + <half_block_size>

      MOV EAX, [@@x0_ptr]
      MOV EAX, [EAX]

      PUSH EDX
      CALL tryFitVert, EAX, EDX, [@@x_inc], [@@y_inc]
      CMP DL, TRUE
      POP EDX
      JE @@succeed
        DEC ECX
        CMP ECX, 0
        JGE @@vert_try_1

    ;; Try portal from [x-size => x-half_size[
    MOV ECX, PORTAL_SIZE
    SHR ECX, 1

    @@vert_try_2:
      MOV EDX, [@@y0_ptr]
      MOV EDX, [EDX]
      SUB EDX, PORTAL_SIZE
      ADD EDX, ECX          ; y - <block_size -> 0>

      MOV EAX, [@@x0_ptr]
      MOV EAX, [EAX]

      PUSH EDX
      CALL tryFitVert, EAX, EDX, [@@x_inc], [@@y_inc]
      CMP DL, TRUE
      POP EDX
      JE @@succeed
        DEC ECX
        CMP ECX, 0
        JGE @@vert_try_2
    JMP @@failed

  @@succeed:
    MOV EBX, [@@x0_ptr]
    MOV [EBX], EAX      

    MOV EBX, [@@y0_ptr]
    MOV [EBX], EDX      

    MOV DL, TRUE  ; Couldn't fit the portal
    RET

  @@failed:
    MOV DL, FALSE  ; Couldn't fit the portal
    RET
ENDP tryFitPortal

PROC createPortal
  ARG @@x0, @@y0, @@direction:DWORD
  USES EAX, EBX, EDX

  ;; Center position from player
  LEA EAX, [@@x0]
  CALL centerPostion, EAX

  LEA EAX, [@@y0]
  CALL centerPostion, EAX

  ;; Save laser direction
  MOV EAX, [@@direction]
  MOV [laser.direction], EAX

  ;; Load the position increments of next position (x+ -> EAX) & (y+ -> EDX)
  CALL directionNext, [@@direction]  
  PUSH EAX  ; = x+
  PUSH EDX  ; = y+

  ;; Save laser start point
  MOV EBX, BLOCK_SIZE
  SHR EBX, 1

  IMUL EAX, EBX
  MOV [laser.x0], EAX
  
  IMUL EDX, EBX
  MOV [laser.y0], EDX

  ;; Find first Block on path
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

    CALL checkCollision, [@@x0], [@@y0] ; check upper left for collision
    CMP DL, EMPTY
    JE @@findBlock
  
  ;; Save laser end point
  MOV EAX, [@@x0]
  MOV [laser.x1], EAX

  MOV EAX, [@@y0]
  MOV [laser.y1], EAX
  
  ;; Activate laser
  MOV EAX, [laser.span]
  MOV [laser.active], EAX

  ;; restore Stack
  POP EBX ; = y+
  POP EAX ; = x+

  ;; Don't draw portal IF
  CMP DL, UNTARGETABLE ; ignore untargatable wall
  JE @@return

  CMP DL, OUT_OF_BOUND ; ignore out of bound
  JE @@return
    
  ;; Set the direction of Portal entrance
  CMP [@@direction], UP_RIGHT
  JNE @@check_up_left
    ; Check Block under it
    MOV EBX, POS_DOWN ; y+ := POS_UP -> POS_DOWN
    ADD EBX, [@@y0]   ; y of block under
    ADD EAX, [@@x0]   ; x of block under
    CALL checkCollision, EAX, EBX 
    CMP DL, EMPTY
    JE @@direction_down
    JMP @@direction_left

  @@check_up_left:
    CMP [@@direction], UP_LEFT
    JNE @@check_down_right
      ; Check Block under it
      MOV EBX, POS_DOWN ; y+ := POS_UP -> POS_DOWN
      ADD EBX, [@@y0]   ; y of block under
      ADD EAX, [@@x0]   ; x of block under
      CALL checkCollision, EAX, EBX 
      CMP DL, EMPTY
      JE @@direction_down
      JMP @@direction_right

  @@check_down_right:
    CMP [@@direction], DOWN_RIGHT
    JNE @@check_down_left
      ; Check Block under it
      MOV EBX, POS_UP ; y+ := POS_UP -> POS_DOWN
      ADD EBX, [@@y0]   ; y of block under
      ADD EAX, [@@x0]   ; x of block under
      CALL checkCollision, EAX, EBX 
      CMP DL, EMPTY
      JE @@direction_up
      JMP @@direction_left
  
  @@check_down_left:
    CMP [@@direction], DOWN_LEFT
    JNE @@not_slanting
      ; Check Block under it
      MOV EBX, POS_UP ; y+ := POS_UP -> POS_DOWN
      ADD EBX, [@@y0]   ; y of block under
      ADD EAX, [@@x0]   ; x of block under
      CALL checkCollision, EAX, EBX 
      CMP DL, EMPTY
      JE @@direction_up
      JMP @@direction_right

  @@not_slanting:
    ; if not of the above direction openning is the oposite direction
    CALL opositeDirection, [@@direction]
    MOV [@@direction], EDX
    JMP @@try_placing

  @@direction_down:
    MOV [@@direction], DOWN
    JMP @@try_placing

  @@direction_up:
    MOV [@@direction], UP
    JMP @@try_placing

  @@direction_left:
    MOV [@@direction], LEFT
    JMP @@try_placing

  @@direction_right:
    MOV [@@direction], RIGHT
    JMP @@try_placing

  @@try_placing:
    LEA EAX, [@@x0]
    LEA EDX, [@@y0]
    CALL tryFitPortal, EAX, EDX, [@@direction]
    CMP DL, TRUE     ; Did the function succeed?
    JNE @@return
  
  @@create_portal:
    CMP [portal_A.active], FALSE
    JE @@create_A
    JMP @@create_B

  @@create_A:
    MOV EAX, [@@x0]
    MOV [portal_A.x], EAX
    MOV EAX, [@@y0]
    MOV [portal_A.y], EAX
    MOV EAX, [@@direction]
    MOV [portal_A.direction], EAX
    MOV [portal_A.active], TRUE
    RET

  @@create_B:
    MOV EAX, [@@x0]
    MOV [portal_B.x], EAX
    MOV EAX, [@@y0]
    MOV [portal_B.y], EAX
    MOV EAX, [@@direction]
    MOV [portal_B.direction], EAX
    MOV [portal_B.active], TRUE
    CALL swapPortals
    RET

  @@return:
    RET
ENDP createPortal

PROC useLaser
  USES EAX
    MOV EAX, [laser.active]
    CMP EAX, FALSE
    JE @@return
      DEC EAX
      MOV [laser.active], EAX

  @@return:
    RET
ENDP useLaser

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

  MOV EAX, [portal_A.direction]
  MOV EDX, [portal_B.direction]

  MOV [portal_A.direction], EDX
  MOV [portal_B.direction], EAX

  RET
ENDP swapPortals

PROC physicsHandler
  USES EAX, EBX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]

  CALL checkBlockCollision, EAX, [player.y]
  CMP DL, EMPTY
  JNE @@dont_move_x
    MOV [player.x], EAX
  @@dont_move_x:
    MOV [player.vx], 0
  
  @@move_y:
    MOV EAX, [player.vy]
    SAR EAX, SLOW_DOWN      ; Slown down vertical movement
    ADD EAX, [player.y]

    CALL checkBlockCollision, [player.x], EAX
    CMP DL, EMPTY
    JNE @@slow_down_y
      MOV [player.y], EAX
      CMP [player.vy], MAX_VELOCITY
      JG @@return
        INC [player.vy]
        JMP @@return
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
      CMP EAX, 0  ;IF y velocity 0 it has hit the ground
      JE @@dont_move_y
      JMP @@move_y

  @@dont_move_y:
    MOV [player.vy], 0
    MOV [player.jumping], FALSE

  @@return:
    RET
ENDP physicsHandler

; AABB collision
PROC checkBlockCollision
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX

	MOV EAX, [@@x0]
	ADD EAX, BLOCK_SIZE - 1
	MOV EBX, [@@y0]
	ADD EBX, BLOCK_SIZE - 1

  CALL checkCollision, [@@x0], [@@y0] ; check upper left for collision
  CMP DL, EMPTY
  JNE @return

  CALL checkCollision, EAX, [@@y0]		; check upper right for collision
  CMP DL, EMPTY
  JNE @return

  CALL checkCollision, [@@x0], EBX		; check lower left for collision
  CMP DL, EMPTY
  JNE @return

  CALL checkCollision, EAX, EBX				; check lower right for collision

  @return:
    RET
ENDP checkBlockCollision

; Checks level and list of portals
PROC checkCollision 
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

ENDP checkCollision 

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

  laser     Laser   <>

  player    Player  <40, 20>
  clone_A   Player  <portal_A.x, portal_A.y>
  clone_B   Player  <portal_B.x, portal_B.y>
;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

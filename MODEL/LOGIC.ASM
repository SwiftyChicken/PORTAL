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
  ARG @@x_ptr:DWORD, @@y_ptr:DWORD
  USES EAX, EBX, EDX

  MOV EAX, [@@x_ptr]
  MOV EDX, [@@y_ptr]

  MOV EBX, BLOCK_SIZE
  SHR EBX, 1

  ADD [EAX], EBX
  ADD [EDX], EBX

  RET
ENDP centerPostion

PROC tryFitHor
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX, EBX
    ;; check if don't overlap with portal A
    ;; (Portal B will despawn anyways)
    CMP [portal_A.active], TRUE
    JNE @@check_fit

    ; New portal x end point
    MOV EAX, [@@x]
    ADD EAX, PORTAL_SIZE - 1

    CMP [portal_A.direction], UP
    JE @@horizontal_A
    CMP [portal_A.direction], DOWN
    JE @@horizontal_A
     ;@@vertical_A:
        MOV EBX, [portal_A.y]
        ADD EBX, PORTAL_SIZE - 1

        CALL checkIntersection, [@@x], [@@y], EAX, [@@y], [portal_A.x], [portal_A.y], [portal_A.x], EBX
        CMP DL, FALSE
        JE @@check_fit
          JMP @@failed

     @@horizontal_A:
        MOV EBX, [portal_A.x]
        ADD EBX, PORTAL_SIZE - 1

        CALL checkIntersection, [@@x], [@@y], EAX, [@@y], [portal_A.x], [portal_A.y], EBX, [portal_A.y]
        CMP DL, FALSE
        JE @@check_fit
          @@failed:
            MOV DL, FALSE
            RET

    @@check_fit:
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
ENDP tryFitHor

PROC tryFitVert
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX, EBX
    ;; check if don't overlap with portal A
    ;; (Portal B will despawn anyways)
    CMP [portal_A.active], TRUE
    JNE @@check_fit

    ; New portal y end point
    MOV EAX, [@@y]
    ADD EAX, PORTAL_SIZE - 1

    CMP [portal_A.direction], UP
    JE @@horizontal_A
    CMP [portal_A.direction], DOWN
    JE @@horizontal_A
     ;@@vertical_A:
        MOV EBX, [portal_A.y]
        ADD EBX, PORTAL_SIZE - 1

        CALL checkIntersection, [@@x], [@@y], [@@x], EAX, [portal_A.x], [portal_A.y], [portal_A.x], EBX
        CMP DL, FALSE
        JE @@check_fit
          @@failed:
            MOV DL, FALSE
            RET

     @@horizontal_A:
        MOV EBX, [portal_A.x]
        ADD EBX, PORTAL_SIZE - 1

        CALL checkIntersection, [@@x], [@@y], [@@x], EAX, [portal_A.x], [portal_A.y], EBX, [portal_A.y]
        CMP DL, FALSE
        JE @@check_fit
          JMP @@failed

    @@check_fit:
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

ENDP tryFitVert

PROC tryFitPortal   ;; Return FALSE in DL if couldn't fit the portal
  ARG @@x0_ptr:DWORD, @@y0_ptr:DWORD, @@direction:DWORD, @@x_inc:DWORD, @@y_inc:DWORD
  USES EAX, EBX, ECX

  ;; Load the position increments of next position (x+ -> EAX) & (y+ -> EDX)
  CALL directionNext, [@@direction]  

  ;; Save increments to restore position later
  MOV [@@x_inc], EAX
  MOV [@@y_inc], EDX
  
  CMP [@@direction], LEFT
  JE @@vertical
  CMP [@@direction], RIGHT
  JE @@vertical
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
      ADD EAX, ECX          ; x + <block_size -> half_block_size>

      PUSH EDX
      CALL tryFitHor, EAX, EDX, [@@x_inc], [@@y_inc]
      CMP DL, TRUE
      POP EDX
      JE @@succeed
        DEC ECX
        CMP ECX, 0
        JGE @@hor_try_2
          @@failed:
            MOV DL, FALSE  ; Couldn't fit the portal
            RET

  @@vertical:
    ;; Try portal from [y - half_size => x]
    MOV ECX, PORTAL_SIZE
    SHR ECX, 1

    @@vert_try_1:
      MOV EDX, [@@y0_ptr]
      MOV EDX, [EDX]
      SUB EDX, ECX          ; y - <half_block_size>

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
ENDP tryFitPortal

PROC createPortal
  ARG @@x0:DWORD, @@y0:DWORD, @@direction:DWORD
  USES EAX, EBX, EDX

 ;; Center position from player
  LEA EAX, [@@x0]
  LEA EDX, [@@y0]
  CALL centerPostion, EAX, EDX

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
  ADD EAX, [@@x0]
  MOV [laser.x0], EAX

  IMUL EDX, EBX
  ADD EDX, [@@y0]
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
      MOV EBX, POS_UP   ; y+ := POS_UP -> POS_DOWN
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
      MOV EBX, POS_UP   ; y+ := POS_UP -> POS_DOWN
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
    CALL tryFitPortal, EAX, EDX, [@@direction], 0, 0
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
    CALL updateClones, FALSE, FALSE, FALSE, FALSE, FALSE
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

  CMP [portal_A.active], TRUE
  JNE @@return
  CMP [portal_B.active], TRUE
  JNE @@return

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

  @@return:
    RET
ENDP swapPortals

PROC half_EAX
  CMP EAX, 0
  JGE @@positive
    SAR EAX, 1
    RET

  @@positive:
    NEG EAX
    SAR EAX, 1
    NEG EAX
    RET
ENDP half_EAX

PROC physicsHandler
  USES EAX, EBX, EDX

  @@try_move_x:
    MOV EAX, [player.vx]
    CALL half_EAX
    ADD EAX, [player.x]

    CALL tryTeleporting, [player.x], [player.y], EAX, [player.y]
    CMP DL, FALSE
    JNE @@return

    CALL checkPlayerCollision, EAX, [player.y]
    CMP DL, PORTAL
    JE @@move_x

    CMP DL, EMPTY
    JNE @@slow_down_x
      @@move_x:
        MOV [player.x], EAX
      @@dont_move_x:
        CMP [vertical_inc], TRUE   ; Simulate an slowing down of 0.5
          MOV [vertical_inc], TRUE
        JNE @@try_move_y
          MOV [vertical_inc], FALSE
          CMP [player.vx], 0
          JGE @@check_x_right
            INC [player.vx]
            JMP @@try_move_y
          @@check_x_right:
            CMP [player.vx], 0
            JE @@try_move_y
              DEC [player.vx]
              JMP @@try_move_y
    
    @@slow_down_x:
      CMP [player.vx], 0
      JG @@slow_right
        INC [player.vx]
        JMP @@try_move_x

      @@slow_right:
        DEC [player.vx]
        JMP @@try_move_x

  @@try_move_y:
    MOV EAX, [player.vy]
    CALL half_EAX
    ADD EAX, [player.y]

    CALL tryTeleporting, [player.x], [player.y], [player.x], EAX
    CMP DL, FALSE
    JNE @@return
    
    CALL checkPlayerCollision, [player.x], EAX
    CMP DL, PORTAL
    JE @@move_y

    CMP DL, EMPTY
    JNE @@slow_down_y
      @@move_y:
        MOV [player.y], EAX
        CMP [gravity_inc], TRUE   ; Should gravity be applied? (1/2 of the time)
          MOV [gravity_inc], TRUE
        JNE @@return
          MOV [gravity_inc], FALSE
          CMP [player.vy], MAX_VELOCITY
          JGE @@return
            INC [player.vy]
            JMP @@return
    @@slow_down_y:
      CMP [player.vy], 0
      JL @@slow_up
      CMP [player.vy], 0
      JG @@slow_down
      
      @@slow_up:
        INC [player.vy]
        JMP @@try_move_y

      @@slow_down:
        DEC [player.vy]
        MOV EAX, [player.vy]
        CALL half_EAX
        CMP EAX, 0  ;IF y velocity 0 it has hit the ground
        JE @@dont_move_y
        JMP @@try_move_y

    @@dont_move_y:
      MOV [player.vy], 1
      MOV [gravity_inc], FALSE ; reset gravity_inc
      MOV [player.jumping], FALSE

  @@return:
    CALL updateClones, FALSE, FALSE, FALSE, FALSE, FALSE
    RET
ENDP physicsHandler

; AABB collision
PROC checkPlayerCollision
	ARG @@x:DWORD, @@y:DWORD
	USES EAX, EBX

  CMP [portal_A.active], TRUE
  JNE @@block_collision
  CMP [portal_B.active], TRUE
  JNE @@block_collision

  CALL checkPortalCollision, [@@x], [@@y]
  CMP DL, EMPTY
  JNE @return

  @@block_collision:
	  MOV EAX, [@@x]
	  ADD EAX, BLOCK_SIZE - 1
	  MOV EBX, [@@y]
	  ADD EBX, BLOCK_SIZE - 1

    CALL checkCollision, [@@x], [@@y] ; check upper left for collision
    CMP DL, EMPTY
    JNE @return

    CALL checkCollision, EAX, [@@y]		; check upper right for collision
    CMP DL, EMPTY
    JNE @return

    CALL checkCollision, [@@x], EBX		; check lower left for collision
    CMP DL, EMPTY
    JNE @return

    CALL checkCollision, EAX, EBX				; check lower right for collision

  @return:
    RET
ENDP checkPlayerCollision

PROC checkPortalCollision
  ARG @@x:DWORD, @@y:DWORD
  USES EAX, EBX, ECX

  MOV DL, EMPTY     ; Start with no collision
  LEA EAX, [@@x]
  LEA EBX, [@@y]
  CALL centerPostion, EAX, EBX ; use player core position

  PUSH OFFSET portal_A
  PUSH OFFSET portal_B
  MOV ECX, 2

  @@check:          ; Check both portal in stack
    POP EBX                               ; EBX will hold portal ref
    CMP DL, EMPTY                         ; Check if collision is found
    JNE @@next                            ; Make sure to restore stack

    CMP [EBX + Portal.active], TRUE       ; No point in checking inactive portal
    JNE @@next

    PUSH EDX
      MOV EAX, [EBX + Portal.direction]
      CALL opositeDirection, EAX        ; direction in wich core is approaching
      MOV EAX, EDX

      CALL directionNext, EAX         ; EAX -> x+ EDX -> y+
      CALL checkApproachingPortal, [@@x], [@@y], EAX, EDX, EBX
      CMP EDX, FALSE
      JNE @@collision
      JMP @@no_collision

    @@collision:
      MOV DL, PORTAL  ; Collision with portal has been made
      JMP @@next

    @@no_collision:
      POP EDX
    @@next:
      LOOP @@check

  RET
ENDP checkPortalCollision

PROC checkInsidePortal
  ARG @@x:DWORD, @@y:DWORD
  USES EAX, EBX

  ;; Can't go inside portal if they aren't both active
  CMP [portal_A.active], TRUE
  JNE @@outside
  CMP [portal_B.active], TRUE
  JNE @@outside

    LEA EAX, [@@x]
    LEA EBX, [@@y]
    CALL centerPostion, EAX, EBX ; use player core position
     
    CALL opositeDirection, [portal_A.direction]
    CALL directionNext, EDX
    CALL checkApproachingPortal, [@@x], [@@y], EAX, EDX, OFFSET portal_A
    CMP EDX, FALSE
    JNE @@inside

    CALL opositeDirection, [portal_B.direction]
    CALL directionNext, EDX
    CALL checkApproachingPortal, [@@x], [@@y], EAX, EDX, OFFSET portal_B
    CMP EDX, FALSE
    JNE @@inside

  @@outside:
    MOV DL, FALSE
    RET

  @@inside:
    MOV DL, TRUE
    RET
ENDP checkInsidePortal

;; If Block center is entering the portal
;; -> RETURN: With how much pixel the block is entering in EDX
;; -> ELSE RETURN: FALSE
PROC checkApproachingPortal
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD, @@portal_ptr:DWORD
  USES EAX, EBX, ECX
  
  MOV EBX, [@@portal_ptr]   ; EBX will hold portal ref
  MOV EAX, [@@x_inc]
  CMP EAX, 0                ; If x+ is 0 => horizontal
  JE @@horizontal
   ;@@vertical:
      ;; check if y is in effective area
      MOV EAX, BLOCK_SIZE/2       ; EAX will not be used because it's 0
      ADD EAX, [EBX + Portal.y]   ; Calculate start effective area

      CMP EAX, [@@y]
      JG @@not_approaching

      MOV EAX, [EBX + Portal.size]; EAX will not be used because it's 0
      SUB EAX, BLOCK_SIZE/2
      ADD EAX, [EBX + Portal.y]   ; Calculate end effective area

      CMP EAX, [@@y]
      JLE @@not_approaching

      ;; check if x approach effective area with in half_block_size
      MOV ECX, BLOCK_SIZE/2
      @@approach_x:
        MOV EAX, [@@x_inc]
        ADD [@@x], EAX
        MOV EAX, [EBX + Portal.x]
        CMP EAX, [@@x]
        JE @@approaching
        LOOP @@approach_x
      JMP @@not_approaching

    @@horizontal:
      ;; check if x is in effective area
      MOV EAX, BLOCK_SIZE/2       ; EAX will not be used because it's 0
      ADD EAX, [EBX + Portal.x]   ; Calculate start effective area

      CMP EAX, [@@x]
      JG @@not_approaching

      MOV EAX, [EBX + Portal.size]; EAX will not be used because it's 0
      SUB EAX, BLOCK_SIZE/2
      ADD EAX, [EBX + Portal.x]   ; Calculate end effective area

      CMP EAX, [@@x]
      JLE @@not_approaching

      ;; check if y approach effective area with in half_block_size
      MOV ECX, BLOCK_SIZE/2
      @@approach_y:
        MOV EAX, [@@y_inc]
        ADD [@@y], EAX
        MOV EAX, [EBX + Portal.y]
        CMP EAX, [@@y]
        JE @@approaching
        LOOP @@approach_y
      JMP @@not_approaching
         
  @@not_approaching:
    MOV EDX, FALSE
    RET

  @@approaching:
    ;; return how much is inside the Portal
    MOV EDX, ECX
    RET
ENDP checkApproachingPortal

PROC updateClones
  ARG @@x:DWORD, @@y:DWORD, @@x_inc:DWORD, @@y_inc:DWORD, @@clone_ptr:DWORD, @@portal_ptr:DWORD ; => LOCAL VARIABLES (NOT PARAMETERS)
  USES EAX, EBX, ECX, EDX

  ;; Can't go inside portal if they aren't both active
  CMP [portal_A.active], TRUE
  JNE @@return
  CMP [portal_B.active], TRUE
  JNE @@return

  MOV EAX, [player.x]
  MOV [@@x], EAX
  LEA EAX, [@@x]

  MOV EBX, [player.y]
  MOV [@@y], EBX
  LEA EBX, [@@y]

  CALL centerPostion, EAX, EBX

  PUSH OFFSET clone_A
  PUSH OFFSET portal_A

  PUSH OFFSET clone_B
  PUSH OFFSET portal_B
  
  MOV ECX, 2      ; Clones to check

  @@update:
    POP [@@portal_ptr] ; Portal -> STRUC Portal
    POP [@@clone_ptr] ; Clone  -> STRUC Player

    ;; Get how much the player is in the other portal
    MOV EBX, [@@portal_ptr]
    MOV EBX, [EBX + Portal.portal]                    ; Get other portal pointer
    CALL opositeDirection, [EBX + Portal.direction]   ; exit direction -> entre direction (:= EDX)
    CALL directionNext, EDX
    MOV [@@x_inc], EAX
    MOV [@@y_inc], EDX

    CALL checkApproachingPortal, [@@x], [@@y], [@@x_inc], [@@y_inc], EBX

    ;; Place Clone based on how far in the player is into the portal
    CALL updateClonePosition, [@@clone_ptr], [@@portal_ptr], EDX

    @@continue:
      LOOP @@update

  @@return:
    RET
ENDP updateClones

PROC updateClonePosition
  ARG @@clone_ptr:DWORD, @@portal_ptr:DWORD, @@offset:DWORD
  USES EAX, EBX, EDX

    MOV EBX, PORTAL_SIZE  ; Offset to get clone in center of portal
    SUB EBX, BLOCK_SIZE
    SHR EBX, 1

    MOV EAX, [@@portal_ptr]
    CALL directionNext, [EAX +  Portal.direction]
    CMP EDX, 0
    JE @@vertical
      ;; horizontal portal
      MOV EAX, EBX          ; Set in center

      CMP EDX, 1
      JE @@direction_down
      ;; direction up
        MOV EDX, 0
        JMP @@update_position
      @@direction_down:
        MOV EDX, POSITION_CORRECTION
        JMP @@update_position

    @@vertical:
      MOV EDX, EBX          ; Set in center

      CMP EAX, 1
      JE @@direction_right
      ;; direction left
        MOV EAX, 0
        JMP @@update_position
      @@direction_right:
        MOV EAX, POSITION_CORRECTION
        JMP @@update_position

  @@update_position:
    MOV EBX, [@@portal_ptr]
    ADD EAX, [EBX + Portal.x]
    ADD EDX, [EBX + Portal.y]

    MOV EBX, [@@clone_ptr]
    MOV [EBX + Player.x], EAX
    MOV [EBX + Player.y], EDX
  
    ;; Offset player from initial position -> dedicated illusion position
    ;; Clone move direction
    MOV EBX, [@@portal_ptr]
    CALL directionNext, [EBX + Portal.direction]

    ;; Amount of time the clone need to offset
    MOV EBX, [@@offset]
    IMUL EAX, EBX
    IMUL EDX, EBX

    ;; Apply offset to clone
    MOV EBX, [@@clone_ptr]
    ADD [EBX + Player.x], EAX
    ADD [EBX + Player.y], EDX

    RET
ENDP updateClonePosition

;Checks level and list of portals
PROC checkCollision 
	ARG @@x:DWORD, @@y:DWORD
	USES EAX, EBX

  ;; Check for out of bound
  CMP [@@x], START_BOUNDRY
  JL @@outOfBound

  CMP [@@x], WIDTH_BOUNDRY
  JG @@outOfBound

  CMP [@@y], START_BOUNDRY
  JL @@outOfBound

  CMP [@@y], HEIGHT_BOUNDRY
  JG @@outOfBound

  ; CONVERT Y: 80x50 -> 16x10
	MOV EAX, [@@y]
	MOV EBX, BLOCK_SIZE
  XOR EDX, EDX          ;Clear EDX
	DIV EBX
	IMUL EAX, 16
	PUSH EAX

  ;; CONVERT X in EAX: 80x50 -> 16x10
	MOV EAX, [@@x]
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

;; check if the lines A and B are intersecting
;; A -> player (catch teleportation only if perpendicular movement)
;;   -> portal (catch overlap)
;; B -> portal
;; Note: the lines are ALWAYS horizontal or vertical
PROC checkIntersection
  ARG @@A_x0:DWORD, @@A_y0:DWORD, @@A_x1:DWORD, @@A_y1:DWORD, @@B_x0:DWORD, @@B_y0:DWORD, @@B_x1:DWORD, @@B_y1:DWORD
  USES EAX, EBX
  ;; Check if A is horizontal -> EAX
  MOV EAX, [@@A_y0]
  CMP EAX, [@@A_y1]
  JE @@A_horizontal
    MOV EAX, FALSE
    JMP @@check_horizontal_B
  @@A_horizontal:
    MOV EAX, TRUE

  ;; Check if B is horizontal -> EBX
  @@check_horizontal_B:
    MOV EBX, [@@B_y0]
    CMP EBX, [@@B_y1]
    JE @@B_horizontal
      MOV EBX, FALSE
      JMP @@check_type_intersection
    @@B_horizontal:
      MOV EBX, TRUE

  ;; Check if they have same orientation
  @@check_type_intersection:
    CMP EAX, EBX
    JNE @@checkPerpendicular
    ;; Check if they share points 
        CMP EAX, TRUE
        JE @@checkParallelHorizontal
       ;@@checkParallelVertical:
          MOV EAX, [@@A_x0]
          CMP EAX, [@@B_x0]
          JNE @@no_intersection               ; check if they are on the same x

          MOV EAX, [@@A_y0]
          CMP EAX, [@@B_y0]
          JL @@par_vert_situation1
          JMP @@par_vert_situation2

          @@par_vert_situation1:              ; Situation 1: A_y0<=B_y0<=A_y1<=B_y1
            MOV EAX, [@@B_y0]
            DEC EAX
            CMP EAX, [@@A_y1]     
            JLE @@intersection
            JMP @@no_intersection
            
          @@par_vert_situation2:              ; Situation 2: B_y0<=A_y0<=B_y1<=A_y1
            MOV EAX, [@@A_y0]
            DEC EAX
            CMP EAX, [@@B_y1]                   
            JLE @@intersection
            JMP @@no_intersection

        @@checkParallelHorizontal:
          MOV EAX, [@@A_y0]
          CMP EAX, [@@B_y0]
          JNE @@no_intersection               ; check if they are on the same y

          MOV EAX, [@@A_x0]
          CMP EAX, [@@B_x0]
          JLE @@par_hor_situation1
          JMP @@par_hor_situation2

          @@par_hor_situation1:              ; Situation 1: A_x0<=B_x0<=A_x1<=B_x1
            MOV EAX, [@@B_x0]
            DEC EAX
            CMP EAX, [@@A_x1]     
            JLE @@intersection
            JMP @@no_intersection
            
          @@par_hor_situation2:              ; Situation 2: B_x0<=A_x0<=B_x1<=A_x1
            MOV EAX, [@@A_x0]
            DEC EAX
            CMP EAX, [@@B_x1]                   
            JLE @@intersection
            JMP @@no_intersection

      @@checkPerpendicular:
        CMP EAX, TRUE
        JE @@checkHorizontalA
       ;@@check Vertical A:
          MOV EAX, [@@A_x0]
          CMP EAX, [@@B_x0]
          JL @@no_intersection
          CMP EAX, [@@B_x1]
          JG @@no_intersection  ; condition 1: B_x0<=A_x0==A_x1<=B_x1

          MOV EAX, [@@A_y0]
          CMP EAX, [@@A_y1]
          JG  @@per_vert_situation2
            MOV EAX, [@@B_y0]
            CMP EAX, [@@A_y0]
            JL @@no_intersection
            CMP EAX, [@@A_y1]
            JG @@no_intersection  ; condition 2 - situation 1: A_y0<=B_y0==B_y1<=A_y1
              JMP @@calculate_per_vert

          @@per_vert_situation2:
            MOV EAX, [@@B_y0]
            CMP EAX, [@@A_y1]
            JL @@no_intersection
            CMP EAX, [@@A_y0]
            JG @@no_intersection  ; condition 2 - situation 2: A_y1<=B_y0==B_y1<=A_y0

          ;; Calculate how much of A0->A1 goes over B0->B1
          @@calculate_per_vert:
            MOV EDX, [@@B_y1]         ; distance from their intersection to A_y1
            SUB EDX, [@@A_y1]
            CMP EDX, 0
            JG @@perpendicular
              NEG EDX                 ; return absolute value
              JMP @@perpendicular

        @@checkHorizontalA:
          MOV EAX, [@@A_y0]
          CMP EAX, [@@B_y0]
          JL @@no_intersection
          CMP EAX, [@@B_y1]
          JG @@no_intersection  ; condition 1: B_y0<=A_y0==A_y1<=B_y1

          MOV EAX, [@@A_x0]
          CMP EAX, [@@A_x1]
          JG @@per_hor_situation2
            MOV EAX, [@@B_x0]
            CMP EAX, [@@A_x0]
            JL @@no_intersection
            CMP EAX, [@@A_x1]
            JG @@no_intersection  ; situation 1 - condition 2: A_x0<=B_x0==B_x1<=A_x1
              JMP @@calculate_per_hor
            
          @@per_hor_situation2:
            MOV EAX, [@@B_x0]
            CMP EAX, [@@A_x1]
            JL @@no_intersection
            CMP EAX, [@@A_x0]
            JG @@no_intersection  ; situation 2 - condition 2: A_x1<=B_x0==B_x1<=A_x0

          ;; Calculate how much of A0->A1 goes over B0->B1
          @@calculate_per_hor:
            MOV EDX, [@@B_x1]         ; distance from their intersection to A_x1
            SUB EDX, [@@A_x1]
            CMP EDX, 0
            JGE @@perpendicular
              NEG EDX                 ; return absolute value
              JMP @@perpendicular

  @@perpendicular:
    INC EDX         ; The intersection counts as 1 point
    RET

  @@intersection:
    MOV EDX, TRUE
    RET

  @@no_intersection:
    MOV EDX, FALSE
    RET
ENDP checkIntersection

PROC tryTeleporting
  ARG @@x0:DWORD, @@y0:DWORD, @@x1:DWORD, @@y1:DWORD
  USES EAX, EBX, ECX

  MOV EDX, FALSE

  ;; Can't teleport if there aren't 2 portals
  CMP [portal_A.active], TRUE
  JNE @@return
  CMP [portal_B.active], TRUE
  JNE @@return

  LEA EAX, [@@x0]
  LEA EBX, [@@y0]
  CALL centerPostion, EAX, EBX

  LEA EAX, [@@x1]
  LEA EBX, [@@y1]
  CALL centerPostion, EAX, EBX

  PUSH OFFSET portal_A
  PUSH OFFSET portal_B

  MOV ECX, 2

  @@check_portals:
    POP EBX             ; portal_ptr in EBX
    CMP EDX, FALSE
    JNE @@next          ; Finish loop to restore stack
      CMP [EBX + Portal.direction], UP
      JNE @@check_down
        @@horizontal:
          MOV EAX, [EBX + Portal.x]
          ADD EAX, PORTAL_SIZE

          CALL checkIntersection, [@@x0], [@@y0], [@@x1], [@@y1], [EBX + Portal.x], [EBX + Portal.y], EAX, [EBX + Portal.y]

          JMP @@check_result

      @@check_down:
        CMP [EBX + Portal.direction] , DOWN
        JE @@horizontal
          MOV EAX, [EBX + Portal.y]
          ADD EAX, PORTAL_SIZE

          CALL checkIntersection, [@@x0], [@@y0], [@@x1], [@@y1], [EBX + Portal.x], [EBX + Portal.y], [EBX + Portal.x], EAX

      @@check_result:
        CMP EDX, FALSE
        JE @@next
          ;; Teleport player to other portal
          MOV EAX, EDX
          CALL opositeDirection, [EBX + Portal.direction]
          CALL teleport, [EBX + Portal.portal], EAX, EDX
          MOV DL, TRUE
    @@next:
      LOOP @@check_portals

  @@return:
    RET
ENDP tryTeleporting

PROC teleport
  ARG @@portal_ptr:DWORD, @@offset:DWORD, @@entering:DWORD
  USES EAX, EBX, EDX
    ADD [@@offset], BLOCK_SIZE/2 ; So player don't get stuck in portal
    CALL updateClonePosition, OFFSET player, [@@portal_ptr], @@offset

    ;; adjust the velocities
    CALL directionNext, [@@entering]

    MOV EBX, [@@portal_ptr]
    CALL adjustVelocity, EAX, EDX, [EBX + Portal.direction]

    MOV [player.jumping], TRUE ; assume you're mid air when teleporting
    MOV [gravity_inc], TRUE
    MOV [vertical_inc], TRUE
  RET
ENDP teleport

PROC adjustVelocity
  ARG @@x_inc:DWORD, @@y_inc:DWORD, @@direction:DWORD
  USES EAX, EDX
  CALL directionNext, [@@direction] ; exit direction

  CMP [@@x_inc], 0
  JE @@enter_vertically
    CMP EAX, 0
    JE @@exit_vertically
      CMP EAX, [@@x_inc]
      JE @@return
        NEG [player.vx]
        JMP @@return
      
    @@exit_vertically:
      CALL swapVelocity
      CMP EDX, [@@x_inc]
      JE @@return
        NEG [player.vy]
        JMP @@return

  @@enter_vertically:
    CMP EDX, 0
    JE @@exit_horizontally
      CMP EDX, [@@y_inc]
      JE @@return
        NEG [player.vy]
        JMP @@return

    @@exit_horizontally:
      CALL swapVelocity
      CMP EAX, [@@y_inc]
      JE @@return
        NEG [player.vx]

  @@return:
    RET
ENDP adjustVelocity

PROC swapVelocity
  PUSH [player.vx]
  PUSH [player.vy]
  POP [player.vx]
  POP [player.vy]

  RET
ENDP swapVelocity

PROC loadLevel
	ARG @@fileName:DWORD
	CALL loadFile, [@@fileName], OFFSET level, LEVEL_SIZE
	RET
ENDP loadLevel

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  portal_A  Portal  <0, 0, OFFSET portal_B, UP>
  portal_B  Portal  <0, 0, OFFSET portal_A, DOWN>

  laser     Laser   <>

  player    Player  <0, FLOOR>
  clone_A   Player  <0, 0>
  clone_B   Player  <0, 0>

  ; Simulate increase of 0.5
  gravity_inc DB FALSE 
  vertical_inc DB FALSE 
;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

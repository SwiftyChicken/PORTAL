;-----------------------------------------------------------
; Collection of procedures to read and write files
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/STD.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC directionNext
  ARG @@direction
  CMP [@@direction], UP
  JE @@up
  CMP [@@direction], UP_RIGHT
  JE @@up_right
  CMP [@@direction], RIGHT 
  JE @@right
  CMP [@@direction], DOWN_RIGHT 
  JE @@down_right
  CMP [@@direction], DOWN
  JE @@down
  CMP [@@direction], DOWN_LEFT
  JE @@down_left
  CMP [@@direction], LEFT
  JE @@left
  CMP [@@direction], UP_LEFT
  JE @@up_left

  @@up:
    MOV EAX, POS_SAME
    MOV EDX, POS_UP
    RET

  @@up_right:
    MOV EAX, POS_RIGHT
    MOV EDX, POS_UP
    RET

  @@right:
    MOV EAX, POS_RIGHT
    MOV EDX, POS_SAME
    RET

  @@down_right:
    MOV EAX, POS_RIGHT
    MOV EDX, POS_DOWN
    RET

  @@down:
    MOV EAX, POS_SAME
    MOV EDX, POS_DOWN
    RET

  @@down_left:
    MOV EAX, POS_LEFT
    MOV EDX, POS_DOWN
    RET

  @@left:
    MOV EAX, POS_LEFT
    MOV EDX, POS_SAME
    RET

  @@up_left:
    MOV EAX, POS_LEFT
    MOV EDX, POS_UP
    RET

  ENDP directionNext

PROC opositeDirection
  ARG @@direction
  CMP [@@direction], UP
  JE @@down
  CMP [@@direction], UP_RIGHT
  JE @@down_left
  CMP [@@direction], RIGHT 
  JE @@left
  CMP [@@direction], DOWN_RIGHT 
  JE @@up_left
  CMP [@@direction], DOWN
  JE @@up
  CMP [@@direction], DOWN_LEFT
  JE @@up_right
  CMP [@@direction], LEFT
  JE @@right
  CMP [@@direction], UP_LEFT
  JE @@down_right

  @@up:
    MOV EDX, UP
    RET

  @@up_right:
    MOV EDX, UP_RIGHT
    RET

  @@right:
    MOV EDX, RIGHT
    RET

  @@down_right:
    MOV EDX, DOWN_RIGHT
    RET

  @@down:
    MOV EDX, DOWN
    RET

  @@down_left:
    MOV EDX, DOWN_LEFT
    RET

  @@left:
    MOV EDX, LEFT
    RET

  @@up_left:
    MOV EDX, UP_LEFT
    RET

  ENDP opositeDirection

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

END

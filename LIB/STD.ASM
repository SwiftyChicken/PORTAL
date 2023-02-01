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
    MOV EAX, MOV_NONE
    MOV EDX, MOV_UP
    RET

  @@up_right:
    MOV EAX, MOV_RIGHT
    MOV EDX, MOV_UP
    RET

  @@right:
    MOV EAX, MOV_RIGHT
    MOV EDX, MOV_NONE
    RET

  @@down_right:
    MOV EAX, MOV_RIGHT
    MOV EDX, MOV_DOWN
    RET

  @@down:
    MOV EAX, MOV_NONE
    MOV EDX, MOV_DOWN
    RET

  @@down_left:
    MOV EAX, MOV_LEFT
    MOV EDX, MOV_DOWN
    RET

  @@left:
    MOV EAX, MOV_LEFT
    MOV EDX, MOV_NONE
    RET

  @@up_left:
    MOV EAX, MOV_LEFT
    MOV EDX, MOV_UP
    RET

  ENDP directionNext

PROC opositeDirection
  ARG @@direction
  USES EAX, EBX

    MOV EBX, 8 ; 8 different directions
    MOV EAX, [@@direction]
    ADD EAX, 4
    XOR EDX, EDX
    DIV EBX

  RET
ENDP opositeDirection

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

END

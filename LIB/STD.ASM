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
  CMP [@@direction], DOWN_LEFT
  JE @@down_left

  @@up:
    MOV EAX, 0
    MOV EDX, 1
    RET

  @@up_right:
    MOV EAX, 1
    MOV EDX, 1
    RET

  @@right:
    MOV EAX, 1
    MOV EDX, 0
    RET

  @@down_right:
    MOV EAX, 1
    MOV EDX, -1
    RET

  @@down:
    MOV EAX, 0
    MOV EDX, -1
    RET

  @@down_left:
    MOV EAX, -1
    MOV EDX, -1
    RET

  @@left:
    MOV EAX, -1
    MOV EDX, 0
    RET

  ENDP directionNext
;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

END

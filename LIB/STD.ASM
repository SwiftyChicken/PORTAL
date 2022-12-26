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

PROC stringEq
  ARG @@string1:BYTE, @@string2:BYTE
  USES EDI, ESI

  CLD ; compare left to right

  LEA ESI, [@@string1] ; first char of string1
  LEA EDI, [@@string2] ; first char of string2

  REPE CMPSB ; compares SI and DI bytes until mismatch
  JE @@equal

  @@not_equal:
    MOV DL, FALSE
    RET

  @@equal:
    MOV DL, TRUE
    RET
ENDP stringEq

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

END

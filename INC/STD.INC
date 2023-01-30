;-------------------------------------------------------------------
; LIB/FILE.ASM
;-------------------------------------------------------------------

;-----------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------
TRUE  EQU 1
FALSE EQU 0

;         0
;   7 ___ | ___ 1
;        \|/    
; 6 ----- O ----- 2
;        /|\     
;   5 __/ | \__ 3
;         4

UP          EQU 0
UP_RIGHT    EQU 1
RIGHT       EQU 2
DOWN_RIGHT  EQU 3
DOWN        EQU 4
DOWN_LEFT   EQU 5
LEFT        EQU 6
UP_LEFT     EQU 7

MOV_DOWN  EQU 1
MOV_UP    EQU -1
MOV_RIGHT EQU 1
MOV_LEFT  EQU -1
MOV_NONE  EQU 0
;-----------------------------------------------------------
; EXPORT
;-----------------------------------------------------------

GLOBAL directionNext:PROC
GLOBAL opositeDirection:PROC

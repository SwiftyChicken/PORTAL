;-------------------------------------------------------------------
; LIB/FILE.ASM
;-------------------------------------------------------------------

;-----------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------
TRUE  EQU 1
FALSE EQU 0

UP          EQU 0
UP_RIGHT    EQU 1
RIGHT       EQU 2
DOWN_RIGHT  EQU 3
DOWN        EQU 4
DOWN_LEFT   EQU 5
LEFT        EQU 6
UP_LEFT     EQU 7

POS_DOWN  EQU 1
POS_UP    EQU -1
POS_RIGHT EQU 1
POS_LEFT  EQU -1
POS_SAME  EQU 0
;-----------------------------------------------------------
; EXPORT
;-----------------------------------------------------------

GLOBAL directionNext:PROC
GLOBAL opositeDirection:PROC

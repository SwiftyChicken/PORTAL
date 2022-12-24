;-------------------------------------------------------------------
; MODEL/PHYSICS
;-------------------------------------------------------------------
FLOOR EQU 42
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5

STRUC Player
  x dd ?
  y dd ?
  vx dd ?
  vy dd ?
ENDS Player

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC

GLOBAL player:Player

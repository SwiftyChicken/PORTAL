;-------------------------------------------------------------------
; MODEL/PHYSICS
;-------------------------------------------------------------------
FLOOR EQU 40
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5

STRUC Player
  x dd ?
  y dd ?
  vx dd 0
  vy dd 0
  jumping dd 0
ENDS Player

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC

GLOBAL player:Player

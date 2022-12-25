;-------------------------------------------------------------------
; MODEL/PHYSICS
;-------------------------------------------------------------------
FLOOR EQU 40
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5
SLOW_DOWN EQU 1
UP EQU 0
RIGHT EQU 1
DOWN EQU 2
LEFT EQU 3

STRUC Player
  x dd ?
  y dd ?
  vx dd 0
  vy dd 0
  jumping dd 0
  direction dd RIGHT
ENDS Player

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC

GLOBAL player:Player

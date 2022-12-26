;-------------------------------------------------------------------
; MODEL/PHYSICS
;-------------------------------------------------------------------
FLOOR EQU 40
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5
SLOW_DOWN EQU 1
START_BOUNDRY EQU 0
WIDTH_BOUNDRY EQU 79
HEIGHT_BOUNDRY EQU 49

STRUC Player
  x dd ?
  y dd ?
  vx dd 0
  vy dd 0
  jumping dd 0
  direction dd RIGHT
ENDS Player

STRUC Laser
  active dd ?
  direction dd ?
  x dd ?
  y dd ?
ENDS Laser

STRUC Portal
  x dd ?
  y dd ?
  portal dd ?
  clone dd ?
  direction dd ?
ENDS Portal

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC

GLOBAL portal_A:Portal
GLOBAL portal_B:Portal

GLOBAL player:Player
GLOBAL clone_A:Player
GLOBAL clone_B:Player

GLOBAL laser:Laser

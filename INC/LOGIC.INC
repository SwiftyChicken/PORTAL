;-------------------------------------------------------------------
; MODEL/LOGIC
;-------------------------------------------------------------------
OUT_OF_BOUND EQU 255
FLOOR EQU 40
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5
PORTAL_SIZE EQU 7
SLOW_DOWN EQU 1
MAX_VELOCITY EQU 16
START_BOUNDRY EQU 0
WIDTH_BOUNDRY EQU 79
HEIGHT_BOUNDRY EQU 49
FINISH EQU WIDTH_BOUNDRY - BLOCK_SIZE
PORTAL_A EQU 0
PORTAL_B EQU 1

;; LVL CODES
EMPTY EQU 00H
WALL EQU 01H
UNTARGETABLE EQU 02H
PORTAL EQU 03H

STRUC Player
  x dd ?
  y dd ?
  vx dd 0
  vy dd 0
  jumping dd 0
  direction dd RIGHT
ENDS Player

STRUC Portal
  x dd ?
  y dd ?
  portal dd ?
  direction dd ?
  clone dd ?
  active dd FALSE
  size dd PORTAL_SIZE
ENDS Portal

STRUC Laser
  x0 dd ?
  y0 dd ?
  x1 dd ?
  y1 dd ?
  direction dd ?
  span dd 2
  active dd FALSE
ENDS Laser

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC
GLOBAL createPortal:PROC
GLOBAL useLaser:PROC
GLOBAL swapPortals:PROC

GLOBAL portal_A:Portal
GLOBAL portal_B:Portal

GLOBAL laser:Laser

GLOBAL player:Player
GLOBAL clone_A:Player
GLOBAL clone_B:Player

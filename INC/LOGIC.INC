;-------------------------------------------------------------------
; MODEL/LOGIC
;-------------------------------------------------------------------
OUT_OF_BOUND EQU 255
FLOOR EQU 40
LEVEL_SIZE EQU 16*10
BLOCK_SIZE EQU 5
SLOW_DOWN EQU 1
START_BOUNDRY EQU 0
WIDTH_BOUNDRY EQU 79
HEIGHT_BOUNDRY EQU 49
FINISH EQU WIDTH_BOUNDRY - BLOCK_SIZE
PORTAL_A EQU 0
PORTAL_B EQU 1
EMPTY EQU 00H
WALL EQU 01H
UNTARGETABLE EQU 02H

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
  clone dd ?
  direction dd ?
  active dd FALSE
  size dd BLOCK_SIZE
ENDS Portal

GLOBAL physicsHandler:PROC
GLOBAL loadLevel:PROC
GLOBAL createPortal:PROC
GLOBAL swapPortals:PROC

GLOBAL portal_A:Portal
GLOBAL portal_B:Portal

GLOBAL player:Player
GLOBAL clone_A:Player
GLOBAL clone_B:Player

;-------------------------------------------------------------------
; VIEW\DRAW.ASM
;-------------------------------------------------------------------

;-----------------------------------------------------------
; MACROS
;-----------------------------------------------------------
SCALE EQU 4  ; image scale
BLOCK_LEN EQU 5
FRAME_BUFF_ADR EQU 0A0000h	; video memory address

SCRW EQU 320	; screen width
SCRH EQU 200	; screen height

IMGBW EQU SCRW/SCALE	; max image width
IMGBH EQU SCRH/SCALE	; max image height

LVLBW EQU IMGBW/BLOCK_LEN	; LVL#.BIN width
LVLBH EQU IMGBH/BLOCK_LEN	; LVL#.BIN height

FLOOR EQU 42
DBUFF_SIZE EQU SCRW*SCRH             ; Doublebuffer (= Size screen)
IMAGE_BUFF_SIZE EQU (IMGBW*IMGBH)+2*2         ; Size maximum image file + 2 DW (= size image)
LVL_BUFF_SIZE EQU LVLBW*LVLBH               ; Size of LVL#.BIN
BLOCK_BUFF_SIZE EQU BLOCK_LEN*BLOCK_LEN ; Size of a LEVEL.BIN block

PRT_HORIZONTAL EQU 0
PRT_VERTICAL EQU 1*4
;-----------------------------------------------------------
; STRUC
;-----------------------------------------------------------
STRUC Animated
  length  DD ?
  current DD ?
  image   DD ?
  images  DD ?
ENDS

STRUC PortalView
  current DD ?
  frames  DD ?
          DD ?
ENDS

GLOBAL setVideoMode:PROC
GLOBAL updateVideoBuffer:PROC
GLOBAL waitVBI:PROC
GLOBAL fillBuffer:PROC
GLOBAL draw:PROC
GLOBAL drawLaser:PROC
GLOBAL drawLevel:PROC
GLOBAL updateLevel:PROC
GLOBAL resetAnimated:PROC
GLOBAL getNextFrame:PROC
GLOBAL setPortalFrame:PROC
GLOBAL updateFrame:PROC
GLOBAL updateColourPalette:PROC

GLOBAL levels:Animated
GLOBAL character_R:Animated
GLOBAL character_L:Animated
GLOBAL PRT_A:PortalView
GLOBAL PRT_B:PortalView

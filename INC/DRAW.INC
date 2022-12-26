;-------------------------------------------------------------------
; VIEW\DRAW.ASM
;-------------------------------------------------------------------

;-----------------------------------------------------------
; MACROS
;-----------------------------------------------------------
SCALE EQU 4  ; image scale
BLOCK_LEN EQU 5
FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen width
FBW EQU SCRW/SCALE	; max image width
SBW EQU FBW/BLOCK_LEN	; LVL#.BIN width
SCRH EQU 200	; screen height
FBH EQU SCRH/SCALE	; max image height
SBH EQU FBH/BLOCK_LEN	; LVL#.BIN height
FLOOR EQU 42
DBUFF_SIZE EQU SCRW*SCRH             ; Doublebuffer (= Size screen)
FBUFF_SIZE EQU (FBW*FBH)+2*2         ; Size maximum image file + 2 DW (= size image)
SBUFF_SIZE EQU SBW*SBH               ; Size of LVL#.BIN
SPRITE_BUFF_SIZE EQU BLOCK_LEN*BLOCK_LEN ; Size of a LEVEL.BIN block

;-----------------------------------------------------------
; STRUC
;-----------------------------------------------------------
STRUC Animated
  length DD ?
  current DD ?
  image DD ?
  images DD ?
ENDS

GLOBAL setVideoMode:PROC
GLOBAL updateVideoBuffer:PROC
GLOBAL waitVBI:PROC
GLOBAL fillBackground:PROC
GLOBAL draw:PROC
GLOBAL updateLevel:PROC
GLOBAL getNextFrame:PROC
GLOBAL updateFrame:PROC
GLOBAL updateColourPalette:PROC

GLOBAL dbuff:DWORD:DBUFF_SIZE

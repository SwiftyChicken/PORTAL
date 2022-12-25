;-------------------------------------------------------------------
; VIEW\DRAW.ASM
;-------------------------------------------------------------------

;-----------------------------------------------------------
; MACROS
;-----------------------------------------------------------
FBADR EQU 0A0000h	; video memory address
SCRW EQU 320	; screen witdth
FBW EQU 80	; screen witdth
SCRH EQU 200	; screen height
FBH EQU 50	; screen height
SCALE EQU 4  ; image scale
FLOOR EQU 42
BLOCK_LEN EQU 5
DBUFF_SIZE EQU SCRW*SCRH                 ; Doublebuffer (= Size screen)
FBUFF_SIZE EQU (FBH*FBW)+2*2             ; Size maximum image file + 2 DW (= size image)
SBUFF_SIZE EQU (FBH*FBW)/5               ; Size of LVL#.BIN
SPRITE_BUFF_SIZE EQU BLOCK_LEN*BLOCK_LEN ; Size of a LEVEL.BIN block

;-----------------------------------------------------------
; STRUC
;-----------------------------------------------------------
STRUC Player_View
  right_frames DB 1
  right DB "VIEW/IMG/P_R.BIN", 0 

  left_frames DB 1
  left DB "VIEW/IMG/P_L.BIN", 0 
ENDS

GLOBAL setVideoMode:PROC
GLOBAL updateVideoBuffer:PROC
GLOBAL waitVBI:PROC
GLOBAL fillBackground:PROC
GLOBAL draw:PROC
GLOBAL updateColourPalette:PROC

GLOBAL dbuff:DWORD:DBUFF_SIZE

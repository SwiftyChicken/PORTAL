;-------------------------------------------------------------------
; VIEW\DRAW.ASM
;-------------------------------------------------------------------
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

GLOBAL dbuff:DWORD:16000

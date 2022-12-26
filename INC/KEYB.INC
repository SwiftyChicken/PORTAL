;-------------------------------------------------------------------
; 32-bit Keyboard functionality.
;-------------------------------------------------------------------
UP_KEY EQU 48H
RIGHT_KEY EQU 4DH
LEFT_KEY EQU 4BH
N_KEY EQU 31H

GLOBAL __keyb_installKeyboardHandler:PROC
GLOBAL __keyb_uninstallKeyboardHandler:PROC

GLOBAL __keyb_keyboardState:BYTE:128
GLOBAL __keyb_rawScanCode:BYTE
GLOBAL __keyb_keysActive:BYTE

;-------------------------------------------------------------------
; Scancodes
;   see: http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
;-------------------------------------------------------------------

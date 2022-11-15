; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Wannes, Richard
; program:	Video mode 13h
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

; -------------------------------------------------------------------
CODESEG

; Set the video mode
PROC setVideoMode
ARG @@videoMode:byte
USES eax

movzx ax, [@@videoMode] ; mov met zero extending, kleiner arg in groter reg
int 10h

	ret
ENDP setVideoMode

PROC drawPixel
USES edi, eax

MOV EDI, 0A0000H    ; frame buffer address
ADD EDI, 320*2 + 10 ; add the appropriate offset
MOV AL, 15          ; index in the colour palette
MOV [EDI], AL       ; change pixel at column 10 of row 2

	ret
ENDP drawPixel


; Set the video mode
PROC setVideoMode
ARG @@videoMode:byte
USES eax

movzx ax, [@@videoMode] ; mov met zero extending, kleiner arg in groter reg
int 10h

	ret
ENDP setVideoMode

PROC drawPixel
USES edi, eax

MOV EDI, 0A0000H    ; frame buffer address
ADD EDI, 320*2 + 10 ; add the appropriate offset
MOV AL, 15          ; index in the colour palette
MOV [EDI], AL       ; change pixel at column 10 of row 2

	ret
ENDP drawPixel

; Wait for a specific keystroke.
PROC waitForSpecificKeystroke
ARG @@keyCode:word
USES eax

@@repeat:
mov ah, 01h
int 16h
jz @@repeat 			; flag checken of er een key is ingedrukt

mov ah, 00h
int 16h
cmp ax, [@@keyCode] ; scancode in ah
jne @@repeat			; als andere key opnieuw scanne

	ret
ENDP waitForSpecificKeystroke

; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

PROC main
	sti
	cld
	
	push ds
	pop	es

	call	setVideoMode,13h
	; call	fillBackground, 0

	mov	ah,00h
	int	16h
	; (replace by) call	waitForSpecificKeystroke, 001Bh ; keycode for ESC
	
	call terminateProcess
ENDP main

; -------------------------------------------------------------------
DATASEG
	palette		db 768 dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main

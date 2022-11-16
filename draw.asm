; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:		Wannes Dewit, Richard Rwema
; program:	Draw	
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320		; screen witdth
SCRHEIGHT EQU 200		; screen height
BLKDIM EQU 20 			; screen partitions/block is 20*20px

; -------------------------------------------------------------------
CODESEG

; Set the video mode
PROC setVideoMode
ARG @@videoMode:byte
USES eax

movzx ax, [@@videoMode] 
int 10h

	ret
ENDP setVideoMode


; Update the colour palette.
; 	* Ncolours: number of colours that have to be updated [word]
PROC updateColourPalette
	ARG	 	@@Ncolours: word
	USES 	eax, ecx, edx, esi

	mov esi, offset palette	; pointer to source palette
	movzx ecx, [@@Ncolours] ; amount of colors to read (movzx = zero extend)
	
	; multiply ecx by 3 (three color components per color)
	; do it efficiently (2*ecx + ecx)
	mov eax, ecx
	sal eax, 1
	add ecx, eax

	mov dx, 03C8h 	; DAC write port
	xor al, al		; index of first color to change (0)
	out dx, al		; write to IO

	inc dx
	rep outsb		; update all colors

	ret
ENDP updateColourPalette


; Fill the background (for mode 13h)
PROC fillBackground
	ARG @@color:dword
	USES eax, edi, ecx

mov eax, [@@color]
mov edi, VMEMADR 							; access video memory
mov ecx, SCRWIDTH * SCRHEIGHT ; amount of pixels on screen 
rep stosb

	ret
ENDP fillBackground


PROC drawSprite
	ARG @@sprite:dword, @@x0:word, @@y0:word
	USES eax, ebx, ecx, edx, edi, esi

; calculate top coord
movzx eax, [@@y0]
mov edx, SCRWIDTH
mul edx
add ax, [@@x0]

; top coord on screen
mov edi, VMEMADR
add edi, eax

mov ecx, BLKDIM	; loop counter
mov edx, ecx		; store for later reference
mov esi, [@@sprite]
cld

@@printRow:
push ecx					; store loop counter (for columns)
mov ecx, edx 			; reset loop counter (for row)
rep movsb

sub edi, edx 			; reset to leftmost coord (carriage return)
add edi, SCRWIDTH	; next row (newline)
pop ecx
loop @@printRow

	ret
ENDP drawSprite


; Wait for a specific keystroke.
PROC waitForSpecificKeystroke
ARG @@keyCode:word
USES eax

@@repeat:
mov ah, 01h
int 16h
jz @@repeat 			; check flag key was pressed 

mov ah, 00h
int 16h
cmp ax, [@@keyCode] ; scancode in ah
jne @@repeat				; if other key scan again

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
	call updateColourPalette, 6
	
	call	fillBackground, 00h
	call	drawSprite, offset character, SCRWIDTH / 2, SCRHEIGHT / 2 ; top coord in the middle

	call	waitForSpecificKeystroke, 011Bh ; keycode for ESC
	call terminateProcess
ENDP main

; -------------------------------------------------------------------
DATASEG
	palette db 20, 20, 20 ; background color
				db 0, 0, 0 			; black
				db 63, 63, 63		; white
				db 50, 50, 50		; light gray
				db 0, 16, 63		; blue
				db 63, 20, 2		; orange

	character	DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 02H, 02H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 02H, 02H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 02H, 02H, 02H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 02H, 02H, 02H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 02H, 02H, 02H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 02H, 02H, 02H, 00H, 00H, 00H
				DB 00H, 00H, 02H, 02H, 02H, 02H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 02H, 02H, 02H, 02H, 00H, 00H
				DB 00H, 00H, 02H, 02H, 02H, 02H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 02H, 02H, 02H, 02H, 00H, 00H
				DB 00H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 04H, 04H, 04H, 04H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 00H
				DB 00H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 04H, 04H, 04H, 04H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 00H
				DB 00H, 02H, 02H, 02H, 02H, 01H, 01H, 01H, 04H, 04H, 04H, 04H, 01H, 01H, 01H, 02H, 02H, 02H, 02H, 00H
				DB 00H, 02H, 01H, 01H, 01H, 01H, 02H, 02H, 04H, 04H, 04H, 04H, 02H, 02H, 01H, 01H, 01H, 01H, 02H, 00H
				DB 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 04H, 04H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H
				DB 02H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 02H
				DB 02H, 00H, 00H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 00H, 00H, 02H
				DB 02H, 02H, 00H, 03H, 03H, 03H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 02H, 03H, 03H, 03H, 00H, 02H, 02H
				DB 00H, 02H, 02H, 00H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 00H, 02H, 02H, 00H
				DB 00H, 02H, 00H, 02H, 00H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 03H, 00H, 02H, 00H, 02H, 00H
				DB 00H, 02H, 00H, 00H, 00H, 00H, 02H, 03H, 03H, 03H, 03H, 03H, 03H, 02H, 00H, 00H, 00H, 00H, 02H, 00H
				DB 00H, 00H, 02H, 00H, 00H, 02H, 00H, 02H, 00H, 00H, 00H, 00H, 02H, 00H, 02H, 00H, 00H, 02H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 02H, 02H, 02H, 02H, 00H, 00H, 00H, 00H, 02H, 02H, 02H, 02H, 00H, 00H, 00H, 00H
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main

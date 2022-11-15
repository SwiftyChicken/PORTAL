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


PROC drawPixel
USES edi, eax

MOV EDI, 0A0000H    ; frame buffer address
ADD EDI, 320*2 + 10 ; add the appropriate offset
MOV AL, 15          ; index in the colour palette
MOV [EDI], AL       ; change pixel at column 10 of row 2

	ret
ENDP drawPixel


; Fill the background (for mode 13h)
PROC fillBackground
	ARG @@color:dword
	USES eax, edi, ecx

mov eax, [@@color]
mov edi, VMEMADR 							; access video memory
mov ecx, SCRWIDTH * SCRHEIGHT ; amount of pixels on screen 
rep stosb

; 00H color is background/transparent
mov dx, 03C8H	; port to signal index for modification
mov al, 0H		; change the colour at index 0
out dx, al		; write AL to the appropriate port
mov dx, 03C9H	; port to communicate the new colour
;mov eax, [@@color]
mov al, 15h		; hardcoded value that corresponds to the bgcolor
out dx, al		; R value
;shl eax, 8		; next value
out dx, al		; G vaue
;shl eax, 8		; next value
out dx, al 		; B value

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
	call	fillBackground, 08h
	call	drawSprite, offset character, 100, 80 

	call	waitForSpecificKeystroke, 011Bh ; keycode for ESC (001Bh)

	call terminateProcess
ENDP main

; -------------------------------------------------------------------
DATASEG
	palette		db 768 dup (?)

	logo  DB 0FH, 00H, 00H, 0EH, 0EH, 27H, 27H, 0FH, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 22H, 22H, 22H, 22H, 22H, 22H, 22H, 22H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 22H, 22H, 0FH, 0FH, 0FH, 0FH, 22H, 22H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 22H, 22H, 0FH, 0FH, 0FH, 0FH, 22H, 22H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 22H, 22H, 0FH, 0FH, 0FH, 0FH, 22H, 22H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 22H, 22H, 0FH, 0FH, 0FH, 0FH, 22H, 22H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 0FH, 22H, 22H, 0FH, 0FH, 22H, 22H, 0FH, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        DB 0FH, 0FH, 22H, 22H, 22H, 22H, 0FH, 0FH, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 11H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 11H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 11H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 11H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H

	character	DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 00H, 0FH, 0FH, 0FH, 1CH, 1CH, 1CH, 1CH, 1CH, 1CH, 0FH, 0FH, 0FH, 00H, 00H, 00H, 00H
				DB 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 1CH, 1CH, 1CH, 1CH, 1CH, 1CH, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H
				DB 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 1CH, 1CH, 1CH, 1CH, 1CH, 1CH, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H
				DB 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 1CH, 1CH, 1CH, 1CH, 1CH, 1CH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H
				DB 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 1CH, 1CH, 1CH, 1CH, 1CH, 1CH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H
				DB 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 09H, 09H, 09H, 09H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H
				DB 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 09H, 09H, 09H, 09H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H
				DB 00H, 0FH, 0FH, 0FH, 0FH, 10H, 10H, 10H, 09H, 09H, 09H, 09H, 10H, 10H, 10H, 0FH, 0FH, 0FH, 0FH, 00H
				DB 00H, 0FH, 10H, 10H, 10H, 10H, 0FH, 0FH, 09H, 09H, 09H, 09H, 0FH, 0FH, 10H, 10H, 10H, 10H, 0FH, 00H
				DB 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 09H, 09H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH
				DB 0FH, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 0FH
				DB 0FH, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 0FH
				DB 0FH, 0FH, 00H, 1EH, 1EH, 1EH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 0FH, 1EH, 1EH, 1EH, 00H, 0FH, 0FH
				DB 00H, 0FH, 0FH, 00H, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 00H, 0FH, 0FH, 00H
				DB 00H, 0FH, 00H, 0FH, 00H, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 00H, 0FH, 00H, 0FH, 00H
				DB 00H, 0FH, 00H, 00H, 00H, 00H, 0FH, 1EH, 1EH, 1EH, 1EH, 1EH, 1EH, 0FH, 00H, 00H, 00H, 00H, 0FH, 00H
				DB 00H, 00H, 0FH, 00H, 00H, 0FH, 00H, 0FH, 00H, 00H, 00H, 00H, 0FH, 00H, 0FH, 00H, 00H, 0FH, 00H, 00H
				DB 00H, 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H, 00H, 0FH, 0FH, 0FH, 0FH, 00H, 00H, 00H, 00H
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main

;-----------------------------------------------------------
; Collection of procedures to read and write files
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "INC/FILE.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC loadFile
	ARG @@fileName:DWORD, @@fileBuffer:DWORD, @@size:DWORD
	USES EAX, EBX, EDX 

	; open bin file, get filehandle in AX
	MOV AL, 0 ; read only
	MOV EDX, [@@fileName]
	MOV AH, 3DH
	INT 21H

	MOV  EDX, OFFSET openErrorMsg
	JC @@error ; carry flag is set if error occurs

	; read bin file data
	MOV BX, AX ; move filehandle to bx
	MOV ECX, [@@size]
	MOV EDX, [@@fileBuffer]
	MOV AH, 3FH
	INT 21H

	MOV  EDX, OFFSET readErrorMsg
	JC @@error

	; close bin file
	MOV AH, 3EH
	INT 21H

	MOV  EDX, OFFSET closeErrorMsg
	JC @@error
	
	MOV ECX, 1		; succes
	RET

	@@error:
	MOV ECX, 0		; error
	RET

  @@printError:
    MOV EAX, 03H ; Set VideoMode
    INT 10h

	  MOV  AH, 09H ; Print text from EDX
	  INT  21H
	  
	  MOV	AH,00H ; 
	  INT	16H

    RET
ENDP loadFile

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

  openErrorMsg db "could not open file", 13, 10, '$'
  readErrorMsg db "could not read data", 13, 10, '$'
  closeErrorMsg db "error during file closing", 13, 10, '$'

END

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
	JC @@printError ; carry flag is set if error occurs

	; read bin file data
	MOV BX, AX ; move filehandle to bx
	MOV ECX, [@@size]
	MOV EDX, [@@fileBuffer]
	MOV AH, 3FH
	INT 21H

	MOV  EDX, OFFSET readErrorMsg
	JC @@printError

	; close bin file
	MOV AH, 3EH
	INT 21H

	MOV  EDX, OFFSET closeErrorMsg
	RET

  @@printError:
    CALL printError
    RET
ENDP loadFile

; generate bin file from given buffer
PROC generateFile
	ARG @@fileName:DWORD, @@fileBuffer:DWORD, @@size:DWORD
	USES EAX, EBX, EDX 

	; Open LEVEL.BIN file
	MOV AL, 0 ; read only
	LEA EDX, [current_level]
	MOV AH, 3DH
	INT 21H

	MOV  EDX, OFFSET openErrorMsg
	JC @@printError ; carry flag is set if error occurs

	; Write data to bin file
	MOV BX, AX ; move filehandle to bx
  MOV AH, 40H ;write to file
	MOV ECX, [@@size]
	MOV EDX, [@@fileBuffer]
	INT 21H

	MOV  EDX, OFFSET writeErrorMsg
	JC @@printError ; carry flag is set if error occurs

	; Close bin file
	MOV AH, 3EH
	INT 21H

	MOV  EDX, OFFSET closeErrorMsg
	JC @@printError
	  RET

  @@printError:
    CALL printError
    RET

ENDP generateFile

PROC printError 

    MOV EAX, 03H ; Set VideoMode
    INT 10h

	  MOV  AH, 09H ; Print text from EDX
	  INT  21H
	  
	  MOV	AH,4CH ; terminate program
	  MOV	AL,01H ; exit code 1

	  INT	21H

	  RET
ENDP printError
;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  current_level DB "VIEW/IMG/LEVEL.BIN", 0	

  openErrorMsg db "could not open file", 13, 10, '$'
  readErrorMsg db "could not read data", 13, 10, '$'
  writeErrorMsg db "could not write data", 13, 10, '$'
  closeErrorMsg db "error during file closing", 13, 10, '$'

END

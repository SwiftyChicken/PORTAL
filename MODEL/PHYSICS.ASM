;-----------------------------------------------------------
; Contains all the physics procedure need for the portal game
;-----------------------------------------------------------
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;-----------------------------------------------------------
; INCLUDE
;-----------------------------------------------------------
INCLUDE "INC/FILE.INC"
INCLUDE "INC/PHYSICS.INC"

;-----------------------------------------------------------
; CODE
;-----------------------------------------------------------
CODESEG

PROC physicsHandler
  USES EAX

  MOV EAX, [player.vx]
  ADD EAX, [player.x]
  MOV [player.x], EAX
  MOV [player.vx], 0
  
  MOV EAX, [player.vy]
  ADD EAX, [player.y]
  CMP EAX, FLOOR
  JG @@end
  MOV [player.y], EAX
  INC [player.vy] 			;gravity

  @@end:

    RET
ENDP physicsHandler

PROC collisionHandler ; checkt lvl en lijst met portals
	ARG @@x0:DWORD, @@y0:DWORD
	USES EAX, EBX, EDI  ; return value in ECX

	;MOV EDI, 5		; size block
	;CALL loadFile, OFFSET return

	;MOV EAX, [@@y0]
	;DIV EDI
	;SHL EAX, 4		; times 16 = levelmatrix width
	;MOV EBX, EAX

	;MOV EAX, [@@x0]
	;DIV EDI
	;CMP EAX, 0		; left out of bounds
	;JNG @@return0 
	;CMP EAX, 15 	; right out of bounds
	;JG @@return3
	
	;ADD EAX, EBX	; coord offset in EAX

	;MOV EAX, [OFFSET current + EAX]
	;CMP EAX, 0000
	;JE @@return1
	JMP @@return1

	; CMP EAX,	; test for portal 
	; JE @@return2

	@@return0:		; don't move, wall collision
		MOV ECX, 0
		RET

	@@return1:		; move, no collision
		MOV ECX, 1
		RET

	@@return2:		; trigger, portal
		MOV ECX, 2
		RET

	@@return3:		; trigger, elevator (end of level)
		MOV ECX, 3
		RET

ENDP collisionHandler 

PROC loadLevel
	ARG @@fileName:DWORD
	CALL loadFile, [@@fileName], OFFSET level, LEVEL_SIZE

	RET
ENDP

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG
  player  Player  <20, FLOOR>

;-----------------------------------------------------------
; UNINITIALISED DATA
;-----------------------------------------------------------
UDATASEG
  level DD LEVEL_SIZE DUP(?)
END

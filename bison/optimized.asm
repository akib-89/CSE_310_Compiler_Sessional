.MODEL SMALL
.STACK 400H
.DATA
.CODE
f PROC
PUSH BP
MOV BP, SP
PUSH 2
MOV BX, [BP + -2]
IMUL BX
MOV SP, BP
RET 2
PUSH [BP + -2]
MOV AX, 9
f ENDP
PUSH BP
MOV BP, SP
SUB SP, 2
PUSH [BP + -2]
PUSH [BP + -2]
CALLf
PUSH AX
MOV BX, [BP + -2]
ADD AX, BX
PUSH AX
MOV BX, [BP + -4]
ADD AX, BX
MOV [BP + -2], AX
POP AX
MOV AX, [BP + -2]
POP BP
RET 4
g ENDP
main PROC
MOV AX, @DATA
MOV DS, AX
PUSH BP
MOV BP, SP
SUB SP, 2
SUB SP, 2
PUSH [BP + -2]
MOV AX, 1
MOV AX, [BP + -4]
PUSH [BP + -2]
PUSH [BP + -4]
CALLg
MOV [BP + -2], AX
POP AX
PUSH [BP + -2]
CALL PRINT_DECIMAL_INTEGER
PUSH 0
MOV AH, 4CH
INT 21H
MOV AH, 4CH
INT 21H
main ENDP
PRINT_NEWLINE PROC
PUSH AX
PUSH DX
MOV AH, 2
MOV DL, 0Dh
INT 21h
MOV DL, 0Ah
INT 21h
POP DX
POP AX
RET
PRINT_NEWLINE ENDP
PRINT_CHAR PROC
PUSH BP
MOV BP, SP
PUSH AX
PUSH BX
PUSH CX
PUSH DX
PUSHF
MOV DX, [BP + 4]
MOV AH, 2
INT 21H
POPF
POP DX
POP CX
POP BX
POP AX
POP BP
RET 2
PRINT_CHAR ENDP
PRINT_DECIMAL_INTEGER PROC NEAR
PUSH BP
MOV BP, SP
PUSH AX
PUSH BX
PUSH CX
PUSH DX
PUSHF
MOV AX, [BP+4]
OR AX, AX
JNS @POSITIVE_NUMBER
PUSH AX
MOV AH, 2
MOV DL, 2Dh
INT 21h
POP AX
NEG AX
@POSITIVE_NUMBER:
XOR CX, CX      
MOV BX, 0Ah
@WHILE_PRINT:
XOR DX, DX
DIV BX
PUSH DX
INC CX
OR AX, AX
JZ @BREAK_WHILE_PRINT
JMP @WHILE_PRINT
@BREAK_WHILE_PRINT:
@LOOP_PRINT:
POP DX
OR DX, 30h
MOV AH, 2
INT 21h
LOOP @LOOP_PRINT
CALL PRINT_NEWLINE
POPF
POP DX
POP CX
POP BX
POP AX
POP BP
RET
PRINT_DECIMAL_INTEGER ENDP
END MAIN
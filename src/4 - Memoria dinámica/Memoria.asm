extern malloc
extern free
extern fprintf

section .data

section .text

global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **

; int32_t strCmp(char* a, char* b)
strCmp:
 push rbp
 mov rbp, rsp
 push rbx
 

 .ciclo:
	movzx ecx, byte[rdi]
 	movzx ebx, byte[rsi]

	cmp ecx, ebx
	jg .aEsMayor
	jl .bEsMayor

	cmp ecx, 0 				;llego al final del string
	je .sonIguales

	inc rsi
	inc rdi
	jmp .ciclo

	.sonIguales:
		mov eax, 0
		jmp .fin

	.aEsMayor:
		mov eax, -1
		jmp .fin

	.bEsMayor:
		mov eax, 1
		jmp .fin




	.fin:
 		pop rbx
		pop rbp
		ret

; char* strClone(char* a)
strClone:
 push rbp
 mov rbp, rsp
 push r12						; contador
 push r13						; r13 = len del string 
 push r14						; Muevo el tope de la pila para guardar rdi y 8 bytes + para alinear
 push r15						; puntero a la nueva memoria
 push rbx
 mov rbx, rdi					; rbx= el puntero del string 

 ; rdi sigue siendo el puntero
 call strLen						; Obteniene la longitud del string 
 mov r13, rax							; preserva rax, contiene la longitud del  string 
 add r13, 1							; Sumamos el caracter nulo
 
 ;Calcula el espacio que tendra la memoria 
 mov rdi, r13						; Son bytes entonces long(a)=espacio_de_mem_en_bytes
 call malloc						; rax= puntero se encuentra 
 
 mov r15, rax						; r15 = puntero a la nueva mem

; Copia byte a byte
 .ciclo:
	cmp r13,1
	je .fin

	mov r12b, byte[rbx]
	mov byte[r15], r12b
	inc rbx
	inc r15
	dec r13
	jmp .ciclo



	.fin:
		mov byte [r15], 0    ; Añade el carácter nulo de terminación
 		pop rbx
 		pop r15
		pop r14
		pop r13
		pop r12
 		pop rbp
		ret

; void strDelete(char* a)
strDelete:
	call free
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	ret

; uint32_t strLen(char* a)
strLen:
 push rbp
 push r12
 mov rbp, rsp
 xor eax, eax			; inicializo contador
 mov r12, rdi
 .ciclo:

	; Accede rdi al primer caracter
	cmp byte[r12], 0		; Es igual a NULL(0)?
	je .fin					; Si es igual, termino

	inc eax					; incremento el contador
	inc r12					; Incrementa en un Byte, el puntero al proximo caracter

	jmp .ciclo
	 
 .fin:
 	pop r12
 	pop rbp
	ret



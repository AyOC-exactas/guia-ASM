
;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar las definiciones (serán revisadas por ABI enforcer):
NODO_OFFSET_NEXT EQU 0
NODO_OFFSET_CATEGORIA EQU 8
NODO_OFFSET_ARREGLO EQU 16
NODO_OFFSET_LONGITUD EQU 24
NODO_SIZE EQU 32
PACKED_NODO_OFFSET_NEXT EQU 0
PACKED_NODO_OFFSET_CATEGORIA EQU 8
PACKED_NODO_OFFSET_ARREGLO EQU 9
PACKED_NODO_OFFSET_LONGITUD EQU 17
PACKED_NODO_SIZE EQU 21
LISTA_OFFSET_HEAD EQU 0
LISTA_SIZE EQU 8
PACKED_LISTA_OFFSET_HEAD EQU 0
PACKED_LISTA_SIZE EQU 8

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS
global cantidad_total_de_elementos
global cantidad_total_de_elementos_packed

;########### DEFINICION DE FUNCIONES
;extern uint32_t cantidad_total_de_elementos(lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos:
	push rbp
    mov rbp, rsp
    push rbx                ; Preservar rbx según convención de llamada

    mov rax, 0              ; Inicializar contador total en 0
    mov rbx, [rdi]          ; rbx = lista->head
    
    .ciclo:
        cmp rbx, 0          ; ¿Es NULL?
        je .fin             ; Si es NULL, terminar
        
        ; Sumar la longitud del arreglo actual
        mov ecx, [rbx + NODO_OFFSET_LONGITUD]
        add eax, ecx        ; Acumular la longitud en el contador
        
        ; Avanzar al siguiente nodo
        mov rbx, [rbx + NODO_OFFSET_NEXT]
        jmp .ciclo          ; Continuar ciclo
        
    .fin:
        pop rbx             ; Restaurar rbx
        pop rbp
        ret
;extern uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista);
;registros: lista[?]
cantidad_total_de_elementos_packed:
	push rbp
	push rbx; preservo el reg no volatil/ d3ebe preservar su valor anterior(CALLEE-SAVED)	
	;si una función necesita usar un registro callee-saved, tiene la obligación de guardar 
	;su valor inicial (por ejemplo, en la pila) y restaurarlo antes de regresar.

	mov rax, 0          ; inicializo contador
	mov rbx, [rdi] 		; rbx =lista->head

	.ciclo:
		cmp rbx,0		; es NULL?
		je .fin			;si es NULL, termino

		;Sumar la longitud del arreglo, del nodo actual 
		mov ecx, [rbx + PACKED_NODO_OFFSET_LONGITUD]
		add eax,ecx ; suma la longitud

		mov rbx, [rbx + PACKED_NODO_OFFSET_NEXT]; Pasa al siguiente nodo
		jmp .ciclo
	.fin:
		pop rbx
		pop rbp
		ret


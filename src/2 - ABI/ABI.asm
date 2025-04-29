extern sumar_c
extern restar_c
;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS

global alternate_sum_4
global alternate_sum_4_using_c
global alternate_sum_4_using_c_alternative
global alternate_sum_8
global product_2_f
global product_9_f

;########### DEFINICION DE FUNCIONES
; uint32_t alternate_sum_4(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; parametros: 
; x1 --> EDI
; x2 --> ESI
; x3 --> EDX
; x4 --> ECX
alternate_sum_4:
  sub EDI, ESI
  add EDI, EDX
  sub EDI, ECX

  mov EAX, EDI
  ret

; uint32_t alternate_sum_4_using_c(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; parametros: 
; x1 --> EDI
; x2 --> ESI
; x3 --> EDX
; x4 --> ECX
alternate_sum_4_using_c:
  ;prologo
  push RBP ;pila alineada
  mov RBP, RSP ;strack frame armado
  push R12
  push R13	; preservo no volatiles, al ser 2 la pila queda alineada

  mov R12D, EDX ; guardo los parámetros x3 y x4 ya que están en registros volátiles
  mov R13D, ECX ; y tienen que sobrevivir al llamado a función

  call restar_c 
  ;recibe los parámetros por EDI y ESI, de acuerdo a la convención, y resulta que ya tenemos los valores en esos registros
  
  mov EDI, EAX ;tomamos el resultado del llamado anterior y lo pasamos como primer parámetro
  mov ESI, R12D
  call sumar_c

  mov EDI, EAX
  mov ESI, R13D
  call restar_c

  ;el resultado final ya está en EAX, así que no hay que hacer más nada

  ;epilogo
  pop R13 ;restauramos los registros no volátiles
  pop R12
  pop RBP ;pila desalineada, RBP restaurado, RSP apuntando a la dirección de retorno
  ret


alternate_sum_4_using_c_alternative:
  ;prologo
  push RBP ;pila alineada
  mov RBP, RSP ;strack frame armado
  sub RSP, 16 ; muevo el tope de la pila 8 bytes para guardar x4, y 8 bytes para que quede alineada

  mov [RBP-8], RCX ; guardo x4 en la pila

  push RDX  ;preservo x3 en la pila, desalineandola
  sub RSP, 8 ;alineo
  call restar_c 
  add RSP, 8 ;restauro tope
  pop RDX ;recupero x3
  
  mov EDI, EAX
  mov ESI, EDX
  call sumar_c

  mov EDI, EAX
  mov ESI, [RBP - 8] ;leo x4 de la pila
  call restar_c

  ;el resultado final ya está en EAX, así que no hay que hacer más nada

  ;epilogo
  add RSP, 16 ;restauro tope de pila
  pop RBP ;pila desalineada, RBP restaurado, RSP apuntando a la dirección de retorno
  ret


; uint32_t alternate_sum_8(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4, uint32_t x5, uint32_t x6, uint32_t x7, uint32_t x8);
; registros y pila: x1[?], x2[?], x3[?], x4[?], x5[?], x6[?], x7[?], x8[?]
alternate_sum_8:
	;prologo

	push rbp
  mov rbp,rsp

  ; resta x1 - x2
  sub edi,esi
  
  ;resta x3 - x4
  sub edx, ecx

  ;resta x5 - x6
  sub r8d,r9d

  ; ahora rdi <-- x1 -x2 +x3 -x4
  add edi, edx

  ;sumo x1 - x2 + x3 -x4 +x5 -x6
  add edi, r8d


; traigo la los datos en la pila 
  mov esi, dword[rbp+16] ; en el stack estan packed 
 
  mov r8d, dword[rbp+24]

  sub esi,r8d
  ; sumo lo que queda
  add edi, esi

  mov eax, edi
	;epilogo
  pop rbp
	ret


; SUGERENCIA: investigar uso de instrucciones para convertir enteros a floats y viceversa
;void product_2_f(uint32_t * destination, uint32_t x1, float f1);
;registros: destination[rdi], x1[rsi], f1[xmm0]
product_2_f:
  ;epilogo
  push rbp
  mov rbp,rsp

  cvtsi2ss xmm1,esi
  mulss  xmm1,xmm0
  cvtss2si esi, xmm1

  mov dword[rdi], esi

  pop rbp
  ret

product_9_f:
;extern void product_9_f(double * destination
;, uint32_t x1, float f1, uint32_t x2, float f2, uint32_t x3, float f3, uint32_t x4, float f4
;, uint32_t x5, float f5, uint32_t x6, float f6, uint32_t x7, float f7, uint32_t x8, float f8
;, uint32_t x9, float f9);
;registros y pila: destination[rdi], x1[?], f1[?], x2[?], f2[?], x3[?], f3[?], x4[?], f4[?]
;	, x5[?], f5[?], x6[?], f6[?], x7[?], f7[?], x8[], f8[?],
;	, x9[rbp+32], f9[rbp+16]
	;prologo
  push rbp
	mov rbp, rsp


	;convertimos los flotantes de cada registro xmm en doubles
	cvtss2sd xmm0, xmm0
  cvtss2sd xmm1, xmm1
  cvtss2sd xmm2, xmm2
  cvtss2sd xmm3, xmm3
  cvtss2sd xmm4, xmm4
  cvtss2sd xmm5,xmm5
  cvtss2sd xmm6,xmm6
  cvtss2sd xmm7,xmm7
;buscamos a f9 que esta en la pila, lo paso a double, lo guardo nuevamente

  ;multiplicamos los doubles en xmm0 <- xmm0 * xmm1, xmmo * xmm2 , ...
  ; xmm0= xmm0*xmm1
	mulsd xmm0,xmm1
  ; xmm2= xmm2*xmm3
  mulsd xmm0, xmm2
; xmm4= xmm4*xmm5
  mulsd xmm0,xmm3
; xmm6= xmm6*xmm7
  mulsd xmm0,xmm4
  mulsd xmm0,xmm5

; xmm0= xmm0*xmm1*xmm2*xmm3
  mulsd xmm0,xmm6
; xmm4= xmm4*xmm5*xmm6*xmm7
  mulsd xmm0, xmm7

  ;xmm0= xmm0*xmm1*xmm2*xmm3*xmm4*xmm5*xmm6*xmm7
  ;pxor xmm1,xmm1
  movsd xmm1, [rbp+48]; f9
  cvtss2sd xmm1,xmm1
  mulsd xmm0, xmm1

  ;libere todos los xmm1 a xmm8

	; convertimos los enteros en doubles y los multiplicamos por xmm0.
	; COMPLETAR
  ;pxor xmm1,xmm1
  ;pxor xmm2, xmm2
  ;pxor xmm3, xmm3
  ;pxor xmm4,xmm4
  ;pxor xmm5,xmm5
  ;pxor xmm7,xmm7
  ;pxor xmm6,xmm6

  cvtsi2sd xmm1, esi
  cvtsi2sd xmm2, edx
  cvtsi2sd xmm3, ecx
  cvtsi2sd xmm4, r8d
  cvtsi2sd xmm5, r9d
  cvtsi2sd xmm6, dword[rbp+16]; x6 
  cvtsi2sd xmm7, dword[rbp+24]; x7

  ; ahora multiplico los enteros pasados a double
  mulsd xmm1,xmm2
  mulsd xmm1,xmm3
 mulsd xmm1, xmm4
 mulsd xmm1,xmm5
 mulsd xmm1,xmm6
 mulsd xmm1,xmm7

 cvtsi2sd xmm2, dword[rbp+32]; x8
 cvtsi2sd xmm3, dword[rbp+40]; x9

 mulsd xmm1,xmm2
 mulsd xmm1, xmm3

;(xmm8 a xmm15 hay problemas)


  ;float(f1-f9) * (entero x1-x9)
  mulsd xmm0,xmm1
;paso el double al puntero
 movsd [rdi], xmm0

	; epilogo

	pop rbp
	ret


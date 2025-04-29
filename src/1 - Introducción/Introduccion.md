# Introducción

Durante esta primer parte vamos a trabajar con la arquitectura Intel 64

Recuerden siempre tener a mano los [manuales de Intel](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)

- El volumen 1 describe la arquitectura básica
- El volumen 2 es la referencia del conjunto de instrucciones, que también pueden consultar en [felixcloutier](https://www.felixcloutier.com/x86/). Este es el que más les va a servir en las próximas clases.
- El volumen 3 es la guía de system programming, la vamos a usar en la segunda parte de la materia.

Contamos con el siguiente esquema de registros:

![Registros Intel 64](../../img/registros%20intel%2064.png)

Recuerden que las versiones de distintos tamaños de un mismo registro (por ejemplo: RAX, EAX, AX, AH, AL) conviven en el mismo circuito físico, es decir, EAX referencia a los 32 bits menos significativos del registro RAX, no se puede modificar el contenido del primero sin alterar el del segundo.

# Programación en Assembly x86

Vamos a empezar a trabajar con lenguaje ensamblador, observen el siguiente código que corresponde al típico "Hola Mundo", vamos a ver su estructura general:

```asm 
%define SYS_WRITE 1     ;;
%define SYS_EXIT 60     ;; Directivas de preprocesador
%define STDOUT 1        ;;

section .data           ;;--> Directiva de ensamblador          ;;
msg db '¡Hola Mundo!', 10   ;;--> Pseudo-instrucciones          ;; Sección .data
len EQU $ - msg             ;;                                  ;; 

global _start           ;;--> Directivas de ensamblador
section .text           ;;                                      ;;
_start:                                                         ;;
    mov rax, SYS_WRITE                                          ;;
    mov RDI, STDOUT                                             ;;
    mov rsi, msg                                                ;;
    mov rdx, len                                                ;; Sección .text
    syscall                                                     ;;
                                                                ;;
    mov rax, SYS_EXIT                                           ;;
    mov rdi, 0                                                  ;;
    syscall                                                     ;;

```

La idea no es que comprendan lo que hace este código, sino que puedan identificar las partes que lo componen:

- Directivas del preprocesador: estas son instrucciones que va a aplicar el preprocesador antes de pasarle el texto al ensamblador, en este caso se están definiendo etiquetas o renombres con ciertos valores. El preprocesador va a tomar estas definiciones y va a reemplazar todas las apariciones de las etiquetas en el resto del texto por sus valores. Por ejemplo, todas las apariciones de `SYS_WRITE` serán reemplazadas por `1`.
- Directivas de ensamblador: estas son instrucciones que le indican al ensamblador cómo interpretar las siguientes líneas de texto y así armar el binario. Por ejemplo, `global` es una directiva que indica que el siguiente símbolo, en este caso `_start`,debe poder ser identificado por fuera de este archivo, es decir, una vez ensamblado se debe poder hacer referencia a `_start` desde otra pieza de código, y un linker debe poder establecer esa conexión.
- Pseudo-instrucciones: estas son instrucciones que atenderá el ensamblador y no quedarán en el binario resultante que ejecutaría un procesador. 

  En este caso `msg db '¡Hola Mundo!', 10` define que debe haber un espacio de memoria identificado con la etiqueta `msg`, definido de a bytes (db = define bytes), con los siguientes valores `'¡Hola Mundo!', 10`. Luego, toda aparición de `msg` en el código será reemplazada por el puntero al comienzo de esa tira de bytes. (el byte 10 se correspone a un salto de línea)
  
  El caso de `len EQU $ - msg` es similar pero no se almacena nada en memoria, se calcula el valor declarado después de la palabra EQU al momento de ensamblar, y se reemplazan las apariciones de `len` por el valor resultante. `$` hace referencia a la posición de memoria en la que se está actualmente, luego, al restarle `msg`, obtenemos la cantidad de posiciones de memoria (bytes) que hay entre len y msg. Es decir, cada aparición de `len` se reemplaza por la longitud de lo declarado en `msg` (en este caso, 13).
- Sección .data: sección dedicada a definir los datos del programa.
- Sección .text: sección dedicada a definir el código del programa.


## Instrucciones

Tenemos muchas instrucciones disponibles, cuya sintaxis suele seguir una lógica común:

- Instruciones sin operandos (o con operandos implícitos). Ej: `ret` para retornar a la función llamadora.
- Instrucciones con un operando: puede ser un registro, una posición de memoria, un inmediato. Ej: `jmp .fin` salta a la etiqueta `.fin`, `call foo` llama a la función foo.
- Instrucciones con dos operandos: por lo general el primer operando es el destino (dst), donde se almacenará el resultado de ejecutar la instrucción, y el segundo operando es la fuente (src).
  - Hay que tener en cuenta que para muchas instrucciones el operando destino también es fuente.
  - Los pares dst-src pueden ser registro-memoria, registro-registro, memoria-registro, registro-inmediato y memoria-inmediato. Nótese como no es posible un par memoria-memoria, las lecturas siempre deben acabar en un registro y las escrituras siempre deben partir de uno o bien de un valor inmediato.
  - Los inmediatos pueden ser:
    - Decimales: 200
    - Hexadecimales
      - con el prefijo `0x`: 0xC8
      - con el prefijo `0h`: 0hC8
    - Octales, con el prefijo `0q`: 0q310
    - Binarios:
      - con el sufijo `b`: 11001000b
      - con el prefijo `0b`, que permite guiones: 0b1100_1000
  - Al trabajar con lecturas y escrituras de memoria hay que tener en cuenta el tamaño del dato que se está leyendo/escribiendo, de lo contrario acabaremos leyendo/escribiendo direcciones de memoria que no corresponden. Para especificar el tamaño de la lectura/escritura, es preciso utilizar el tamaño de registro correcto y añadir el tamaño (BYTE, WORD, DWORD) en el operando de memoria.
  - Ejemplos:
    - Registro-Registro:
      - `add rdi, rsi`
    - Memoria-Regitro: 
      - `mov [LABEL], rax`
      - `sub r10, [rdx + 4*rax + OFFSET]`  (Direccionamiento visto en la teórica: [Base + Indice * Escala + Desplazamiento])
      - mov ecx, DWORD [rbp - 8]
      - add BYTE [rdi], sil
    - Registro-Inmediato:
      - `sub rsp, 8`

## Pseudo-instrucciones

Algunos ejemplos de como usar pseudo-instrucciones para definir datos:

```asm
db 0x55                                 ; define sólo un byte, 0x55
db 0x55,0x56,0x57                       ; 3 bytes sucesivos
db 'a',0x55                             ; 0x97, 0x55
db 'hello',13,10,'$'                    ; strings como cadenas de bytes, cada caracter es un byte
db `hola\nmundo\n\0`                    ; strings con "C-style \-escapes"
dw 0x1234                               ; define una word, los bytes quedan: 0x34 0x12 (por little-endianness se guarda primero el byte menos significativo)
dd 0x12345678                           ; define una double word, los bytes quedan: 0x78 0x56 0x34 0x12
dq 0x123456789abcdef0                   ; define una quad word,constante de 8 bytes
times 4 db 'ja'                         ; define 4 veces la tira de bytes 'ja', quedando "jajajaja"
``` 
Recuerden que para acceder a los valores declarados podemos incluir un nombre de etiqueta antes de la directiva de declaración (`risa times 4 db 'ja'`).

## Herramientas

Para ensamblar vamos a usar NASM. Está diseñado para varios sistemas operativos y distintas versiones de ANSI-C, por eso tiene varios formatos de salida. Como trabajaremos con Linux, vamos a utilizar elfx32, elf32 y elf64, que generan formatos de salida ELF32 y ELF64 (Executable and Linkable Format) en los archivos objeto.

![Esquema de un archivo ELF](../../img/ELF.png)

En la sección _Material de cursada_ del campus virtual van a encontrar links para instalar todas las herramientas que vamos a usar durante el cuatrimestre. Si están trabajando en las compus de los labos ya deberían tener todo instalado.

## Ejercicio

Vamos a probar que todo ande como corresponde. 
Creen un archivo que contenga el código del programa HolaMundo que vimos antes. El archivo puede tener el nombre que prefieran, acá lo mencionaremos como `HolaMundo.asm`.

Para ensamblarlo podemos correr la siguiente línea en la terminal de comandos (estando en la misma carpeta que el código):
``` shell
$ nasm -f elf64 -g -F DWARF HolaMundo.asm
```
Si se fijan en el directorio se les habrá creado un archivo `HolaMundo.o`, un binario como lo que vimos que `GCC` genera la clase pasada.

Luego lo linkeamos con:
``` shell
$ ld -o HolaMundo HolaMundo.o
```
Y finalmente lo ejecutamos con:
``` shell
$ ./HolaMundo
```

De funcionar todo correctamente, los comandos de compilación no deben imprimir ninguna salida, y ejecutar el binario `./HolaMundo` debe imprimir `¡Hola Mundo!` en la terminal.

Podríamos crear un makefile para compilar el programa automáticamente ejecutando solo `make` en la terminal.
Dicho Makefile luciría similar a esto:

```
AS := nasm
ASFLAGS := -f elf64 -F DWARF -g -Wall
LD := ld
LDFLAGS := -g
TARGET := HolaMundo

.PHONY: all clean
all: $(TARGET)
# assembly
HolaMundo.o: HolaMundo.asm
        $(AS) $(ASFLAGS) $<

# linking
$(TARGET): HolaMundo.o
        $(LD) $(LDFLAGS) $< -o $@
clean:
        rm -rf *.o $(TARGET)
```




    
    
    
    
    
 
    

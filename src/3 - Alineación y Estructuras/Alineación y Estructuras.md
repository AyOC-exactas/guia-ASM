# Alineación

El hardware está diseñado para manipular una cantidad de bits por operación. A esta cantidad de bits la llamamos palabra (word), que no es lo mismo que el tamaño direccionable en memoria (byte) y varía según el procesador. En general el procesador es más eficiente al trabajar con lecturas y escrituras de tamaño palabra y sus múltiplos. Por eso, la alineación que tengan los datos en memoria es importante para el rendimiento.

Vamos a ver un ejemplo, pero antes repasemos el concepto de endianness. Cuando queremos almacenar en memoria un dato que es más grande que una unidad direccionable (en nuestro caso, más de un byte), debemos establecer en qué orden se almacenarán esos bytes. Esto es lo que se conoce como `Endianness`. Podemos establecer que cuanto menos significativo sea un byte, más baja será la dirección de memoria en la que se encuentre (`Little Endian`), o bien, lo contrario (`Big Endian`). Esto es algo definido a nivel de hardware, pero es necesario saberlo para poder interpretar correctamente los valores que observemos directamente en la memoria. **En el caso de Intel, se utiliza Little Endian.**

![Endianness](../../img/Endianness-white-background.png)

Cuando el procesador realiza lecturas de memoria, es posible que lea más de lo indicado por la instrucción para aprovechar el ancho del bus, apoyándose en la idea de que si se requiere el valor de una posición de memoria, es probable que se requieran las posiciones cercanas también. Además, no hay garantía de que la primer posición leída sea la solicitada, sino que leerá un bloque que contenga la dirección requerida, pero que esté alineado con el tamaño de palabra o un múltiplo del mismo. Supongamos que el tamaño de ese bloque es de 4 bytes, tenemos dos variables almacenadas como se muestra en la imagen, y queremos cargar el valor de `i` en AX.

![Ejemplo variable desalineada](../../img/Desalineado01.png)

Al haber quedado los bytes de `i` en bloques distintos, el procesador deberá realizar dos lecturas para obtener el valor completo y luego acomodarlo para copiarlo en el registro deseado. Se puede tomar el siguiente código de ASM como la serie de pasos a ser llevados a cabo por el procedador de forma implícita.

![Ejemplo variable desalineada](../../img/Desalineado02.png)

Esto es perfectamente evitable si nos preocupamos por la alineación de las variables. Cada tipo de dato tiene su propio requerimiento de alineación, debe estar alieado a su tamaño. Por ejemplo, un entero de 32 bits debe estar alineado a 4 bytes.

Observemos el siguiente caso particular. ¿Cómo hacemos para que cada variable esté alineada como corresponde?

![Múltiples Variables Desalineadas](../../img/Desalineadas.png)

Simplemente forzamos la alineación de cada una, dejando posiciones en blanco (pueden contener cualquier valor) entre ellas donde sea necesario, a las que llamamos padding.

![Variables alineadas con padding](../../img/Alineadas.png)

Se sacrifica memoria para reducir el tiempo de ejecución.

# Estructuras en memoria

Así como vimos los contratos de función y uso de registros, tenemos un **contrato de datos** que especifica cómo deben estar alineados los atributos de un struct de forma que sea compatible con C. Lean con atención, el contrato dice así:

- Cada atributo estará alineado al tamaño de su tipo de dato, insertando padding entre ellos en caso de ser necesario.
- La estructura en sí se alineará al tamaño del tipo más grande de sus atributos.
- El tamaño de la estructura será tal que la siguiente dirección de memoria estará alineada igual que la estructura, añadiendo padding al final de ella de ser necesario para que se cumpla. Piensen en un "array de estructuras", una al lado de la otra en memoria, el padding que se agrega al final de cada estructura es el que se necesita para que la siguiente esté alineada correctamente. Esto es importante porque, si no se respeta, al acceder a la siguiente estructura el procesador deberá realizar lecturas adicionales para obtener el valor completo, como en el caso de las variables desalineadas.

¡Ojo! No confundir tamaño del struct (resultado de `sizeof()`) con su requisito de alineación.

Veamos algunos ejemplos:

![Alineacion de structs](../../img/AlineacionStructs.png)

Observen cómo varía el tamaño de estas estructuras según el orden en que se definen sus atributos, a pesar de ser conceptualmente idénticas. Notarán que, además, el tercer caso no respeta el contrato de datos y no está alineado. A este tipo de estructuras se las denomina *empaquetadas* y se le indica al compilador agregando `__attribute__((packed))` al final de la declaración. Esta opción permite tener structs sin padding, para optimizar el tamaño a costa del tiempo de procesamiento que requerirán las lecturas.

:exclamation: Recuerden que la memoria no está organizada como una grilla, es una tira continua de bytes que uno puede ilustrar como mejor le convenga. En el caso de la imagen anterior elegimos mostrarla como una grilla de 8 bytes de ancho por cuestiones de espacio y comodidad.

¿Cómo afecta que un atributo del struct sea un array?

![Alineacion de structs con array](../../img/StructConArray.png)

Si bien el array es el atributo más grande (atentis que no es un puntero, es un array ocupando 21 bytes), lo que importa es el tamaño del tipo más grande de sus atributos. El array es de tipo `char`, que ocupa un byte, y por lo tanto el atributo con el tipo más grande es `elo`, que por ser `long` ocupa 8 bytes. Luego, el tamaño de la estructura es 40 bytes (8 + 21 + 3 (padding) + 4 + 4 (padding)), pero su requisito de alineación es de 8 bytes.

¿Cómo afecta que un atributo del struct sea un struct?

![Alineacion de structs con structs](../../img/StructConStruct.png)

Para este caso, se tiene en cuenta el requisito de alineación del struct interno (en el ejemplo llamado `hijo`) como el tamaño del "tipo" del struct interno. En este caso, tener al atributo `hijo` como un struct, es equivalente a tener un `long` en su lugar, en lo que respecta a las reglas de alineación. Entonces, el tamaño de esta estructura es 32 bytes (1 + 7(padding) + 16(`sizeof(hijo)`) + 4 + 4(padding)).

Si encuentran otro caso que les genere duda, recuerden que pueden hacer un código de prueba en el que declaran el struct y lo inspeccionan con GDB.

# Un buen uso para las etiquetas

Ya sabemos calcular los offsets de los atributos de un struct y los podemos usar para acceder a ellos desde assembler. Veamos un ejemplo con el `struct alumno` que vimos antes:

``` ASM
funcion_que_recorre:
  ;prologo
  push RBP ;pila alineada
  mov RBP, RSP ;strack frame armado

  ;tengo en RDI un puntero al comienzo de un array de alumnos
  ;y en RSI el tamaño del array
  ;asumimos que al menos hay un elemento en el array

  XOR R8, R8 ;usamos R8 como índice en el array
  
  .ciclo:
    mov RDX, [RDI + R8 * 16 + 0]
    ;16 es el tamaño del struct, por eso lo usamos para escalar el índice 
    ;0 es el offset del atributo nombre, así que tengo en RDX el valor del atributo nombre del alumno de índice R8
    
    mov CL, BYTE [RDI + R8 * 16 + 8] 
    ; tengo en el byte mas bajo de RCX el atributo comision
    
    mov R9D, DWORD [RDI + R8 * 16 + 12] 
    ; tengo en los 32 bits menos significativos de R9 el valor del atributo dni

    INC R8 ;avanzo el índice del array
    CMP R8, RSI
    JL .ciclo

  ;epilogo
  pop RBP ;pila desalineada, RBP restaurado, RSP apuntando a la dirección de retorno
  ret
```

Esta función recorre el array y lee los atributos de cada elemento. Imaginemos que luego, como es natural, tenemos la necesidad de modificar la definición del struct, por ejemplo le agregamos `__attribute__((packed))` porque precisamos ahorrar memoria e intercambiamos el orden de los atributos `comision` y `dni` (así nos queda como alumno3 en el ejemplo anterior). Ahora `funcion_que_recorre` ya no va a andar correctamente, los offsets que usamos no son los correctos y tenemos que actualizarlos en cada lugar que se usan. Acá es fácil ver y reconocer qué número corresponde a qué offset y actualizarlo, pero en un escenario más realista estaríamos trabajando con varias estructuras distintas a la vez, y algunos de sus offsets van a coincidir sin tener relación alguna. Hay muchas chances de meter la pata y pasarla muy mal. La solución: definir etiquetas para los offsets.

``` ASM
%define OFFSET_NOMBRE 0
%define OFFSET_COMISION 12
%define OFFSET_DNI 8
%define ALUMNO_SIZE 13

section .data          

section .text

funcion_que_recorre:
  ;prologo
  push RBP ;pila alineada
  mov RBP, RSP ;strack frame armado

  ;tengo en RDI un puntero al comienzo de un array de alumnos
  ;y en RSI el tamaño del array
  ;asumimos que al menos hay un elemento en el array

  XOR R8, R8 ;usamos R8 como índice en el array
  
  .ciclo:
    mov RDX, [RDI + R8 * ALUMNO_SIZE + OFFSET_NOMBRE]
    ;ALUMNO_SIZE es el tamaño del struct, por eso lo usamos para escalar el índice 
    ;OFFSET_NOMBRE es el offset del atributo nombre, así que tengo en RDX el valor del atributo nombre del alumno de índice R8
    
    mov CL, BYTE [RDI + R8 * ALUMNO_SIZE + OFFSET_COMISION] 
    ; tengo en el byte mas bajo de RCX el atributo comision
    
    mov R9D, DWORD [RDI + R8 * ALUMNO_SIZE + OFFSET_DNI] 
    ; tengo en los 32 bits menos significativos de R9 el valor del atributo dni

    INC R8 ;avanzo el índice del array
    CMP R8, RSI
    JL .ciclo

  ;epilogo
  pop RBP ;pila desalineada, RBP restaurado, RSP apuntando a la dirección de retorno
  ret
```

Como se comenta brevemente en `Introduccion.md`, las etiquetas son directivas del preprocesador. No forman parte del programa final, sino que se hace un reemplazo de las etiquetas por sus valores en todo el archivo antes de ensamblar. Ahora podemos modificar la definición del struct y actualizar sólo las etiquetas, con la seguridad de que no se nos va a escapar ningún caso y el código va a funcionar correctamente. Además hace que el código sea más declarativo y legible, win win.

# Ejercicios

Pongamos en práctica lo que acabamos de ver. Vamos a usar dos estructuras muy similares a lista\char_t de la clase anterior y vamos a implementar en ASM la función que contaba la cantidad total de elementos de la lista, para ambas estructuras. Pueden encontrar el código necesario en `Estructuras.c` y `Estructuras.asm`.
Las definiciones de las funciones las pueden encontrar en el archivo `Estructuras.h`, y las definiciones de los structs están en `structs.h`.

Programen en assembly las funciones:

``` C
uint32_t cantidad_total_de_elementos(lista_t* lista)

uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista)
```

El archivo que tienen que editar es `Estructuras.asm`. Para todas las declaraciones de las funciones en ASM van a encontrar la firma de la función. Completar para cada parámetro en qué registro o posición de la pila se encuentra cada uno.

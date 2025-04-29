
# ABI (Aplication Binary Interface)

En la teórica vieron contratos que definen cómo llamar a una función de C y el uso de los registros y la pila (stack). Son contratos porque no hay nada que nos ate realmente a esas definiciones, nada en hardware al menos. Es el modo en que el compilador de C lo maneja, y las reglas que debemos seguir desde assembler para interactuar con programas creados en C. Repasémoslos brevemente.

## Contrato de funciones

Cuando declaramos una función en C, por ejemplo:

```C
int32_t product(int32_t *arr, uint32_t length)
```

Nos brinda información sobre el nombre que la identifica, la cantidad y tipo de parámetros que recibe, y el tipo del dato que devuelve. Siempre que se use o implemente esta función, debe coincidir en todos estas características. Cuando trabajamos con el compilador de C, este contrato es respetado automáticamente.

 Pero, ¿Qué pasa si se quiere llamar a esta función desde ASM? ¿Y si queremos implementarla en ASM y luego llamarla desde C?
 Depende de la plataforma, vamos a tener que definir el alcance de nuestro contrato en términos de la plataforma particular.

 Luego, cualquier lenguaje que genere código objeto y respete el contrato de función puede interactuar con funciones ubicadas en bibliotecas binarias (código objeto) que adhieran al contrato. 
 
 Para detallar este comportamiento vamos a precisar hablar de la ABI (Interfaz Binaria de Aplicación). Una ABI define contratos sobre varios elementos tales como el formato de los archivos objeto y ejecutables, el uso de bibliotecas compartidas, parámetros pasados a un proceso, ubicación de las tablas globales del sistema, etc. Pero los que nos interesan en este momento son:

 - El conjunto de instrucciones.
 - El tamaño y alineación de los tipos de datos primitivos ¹.
 - La forma de enviar y recibir información usando funciones del sistema (Convención de llamada para System Calls, como la que usamos en `HolaMundo.asm` para imprimir por consola).
 - La forma de enviar y recibir información usando funciones de usuario (Convención de llamada) .

¹ Decimos que un dato está alineado a N bytes cuando la dirección de memoria dónde está almacenado es múltiplo de N.

La ABI que usamos define dos convenciones:

- En x86-64/Linux (64bits) se denomina System V AMD64 ABI
- En x86/Linux (32bits) se denomina System V i386 ABI

Nos interesan las dos ya que la primera la usaremos durante la primer mitad de la materia y la segunda cuando trabajemos en System Programming.

## Convención de llamadas

La convención de llamadas define:

- En qué registros o posiciones de memoria deben estar los parámetros para llamar a una función (o donde esperarlos, desde el punto de vista de la función llamada).

  - En 32 bits, los parámetros se pasan pusheados a la pila de **derecha a izquierda**¹.
  - En 64 bits, los parámetros se pasan por distintos registros según su tipo:
  
    - Enteros y punteros se pasan por RDI, RSI, RDX, RCX, R8 y R9 (de **izquierda a derecha**²).
    - Flotantes se pasan por XMM0, XMM1, ... , XMM7 (de **izquierda a derecha**²).
    - Para todos los tipos, si se agotan los registros antes mencionados (hay más pero no forman parte de la convención, por ejemplo los XMM del 8 al 15), se pasarán por la pila pusheando de **derecha a izquierda**¹.
- En qué registro esperar el valor de retorno de la función llamada (o donde escribirlo, desde el punto de vista de la función llamada).
  
  - En 32 bits, el valor de retorno se espera en EAX.
  - En 64 bits, el valor de retono se espera en RAX, si es un entero o puntero, y en XMM0 si es un flotante.
- Qué alineamiento debe tener la **pila** (**stack**) al llamar a una función. Tanto en 32 como en 64 bits, la pila debe estar alineada a 16 bytes al momento de llamar a una función de C. ¿Por qué? Hay funcioes que hacen uso operaciones de registros largos (XMM, YMM) que requieren datos alineados a 16 bytes. Si nosotros al llamar a una función no respetamos la alineación y resulta que esa función no llama a ninguna otra que dependa de la alineación de la pila para operar, no pasa nada. Pero si sin que lo sepamos llama a otra que utiliza dichas operaciones, no va a chequear el estado de alineación de la pila antes de hacerlo, porque asume que fue llamada con la pila correctamente alineada, y por tanto va a fallar.

¹ En relación al orden en que están en la declaración de la función. También se puede decir que se pushean desde el último al primero.

² También en relación al orden en que están en la declaración de la función.

## Convención de registros

¿Qué pasa con los registros en uso al realizar una llamada? ¿Conservan sus valores al regresar? Algunos sí, otros no.

Vamos a dividir los registros entre
- ***no volátiles*** o ***callee-saved***: la función llamada debe encargarse de que, al terminar, estos registros tengan los mismos valores que al comienzo. Estos son:
  
  - En 64 bits: RBX, RBP, R12, R13, R14, R15.
  - En 32 bits: EBX, EBP, ESI, EDI
  
- ***volátiles*** o ***caller-saved*** : la función llamada no tiene obligación de conservarlos, si los quiere debe conservalos la función llamadora. 

Menciones especiales: 

- RSP/ESP se puede considerar como un registro no volátil dada su función específica como tope de la pila.
- R10 y R11 no están ni en el grupo de los registros por los que se pasan parámetros ni en el grupo de los registros no volátiles, no se olviden de su existencia.
- XMM8 a XMM15 no están en el grupo de los registros por los que se pasan parámetros pero están a disposición, no se olviden de su existencia.

## Stack frame

El stack frame es la porción de la pila que le corresponde a una función durante su ejecución. Está delimitado por el puntero en el registro RBP, que corresponde a la base de la pila y en cuya posición se encuentra el puntero a la base de la pila de la función llamadora, y el puntero en el registro RSP, que corresponde al tope de la pila y es el que usan las instruciones PUSH, POP, CALL y RET (entre otras), para interactuar con la pila.

- PUSH decrementa el valor de RSP (le resta 8 al puntero, recordemos que la pila "crece hacia abajo", o sea, crece hacia direcciones más chicas) y luego escribe sobre la posición a la que apunta.
- POP primero lee el valor almacenado en la posición apuntada por el RSP y luego incrementa su valor (le suma 8 al puntero).
- CALL realiza un PUSH de la dirección de retorno y luego escribe la dirección de salto al RIP.
- RET realiza un POP de la dirección de retorno y la escribe en el RIP.

Dicho esto, cabe destacar que si la convención de llamada dice que debemos llamar a las funciones de C con la pila alineada a 16, y si la instrucción CALL hace un PUSH, entonces cuando la función ejecute su primer instrucción la pila estará **desalineada**. Para alinearla y mantener en condiciones el stack frame, utilizamos dos secciones de código en toda función (que queremos que interactúe con C) denominadas prólogo y epílogo.

![Prólogo y Epílogo](../../img/prólogo%20y%20epílogo.png)

Prólogo: esta es la sección en la que alineamos la pila a la vez que establecemos la base para el stack frame. Pusheamos el valor actual de RBP que contiene el puntero a la base del stack frame de la función llamadora, y luego asignamos el valor del RSP actual al RBP como nueva base. En esta sección también estarían los push de los registros no volátiles que querramos usar, para así preservar los valores que corresponden a la función llamadora.

Epílogo: acá restauramos los valores de los registros no volátiles que preservamos en el prólogo, popeandolos en el orden contrario al que los pusheamos. Esto incluye al RBP, el primer registro no volátil pusheado, que recupera el valor de la base del stack de la función anterior y deja al RSP apuntando al mismo lugar al que apuntaba al ejecutarse la primer instrucción. Dadas esas condiciones, el RET puede recuperar correctamente el valor de retorno, y la función llamadora retomar su ejecución.



# Bajando a tierra

Pongamos un poco en práctica estos conceptos implementando algunas funciones simples.

``` C
uint32_t alternate_sum_4(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
```

Tenemos una función simple con 4 parámetros de tipo entero no signado de 32 bits, que devuelve un resultado del mismo tipo: `x1 - x2 + x3 - x4 = y`.
Lo primero que tenemos que identificar es dónde vamos a encontrar estos valores, siempre sirve dejar un comentario en el cuerpo de la función que establezca la relación entre los registros y sus valores, no solo para los parámetros sino también para aquellos que usamos como variables locales.

``` ASM
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
```
Noten cómo la solución utiliza los registros del tamaño adecuado. Bien podría haber utilizado RDI, RSI, RDX y RCX y que funcione bien, pero nada garantiza que los 32 bits más significativos del registro vayan a estar limpios cuando el tipo de dato especificado es más pequeño. El problema se vuelve aún más molesto cuando tenemos en cuenta que los movimientos entre registros de 32 bits no limpian los bits más altos que corresponden al registro completo, cosa que sí garantizan los movimientos entre registros menores a 32 bits. En conclusión, siempre presten atención al tamaño del dato, usen los registros del tamaño correcto, y no van a tener problemas.

¿Y qué pasó con el stack frame?¿Por qué no hay prólogo y epílogo? Esta función es muy pequeña y no llama a otras funciones en ningún momento, por lo que no necesita conformar con ninguna convención. Si, en cambio, tuviese que llamar a funciones de C para realizar las operaciones, sería necesario el armado del stack frame. En general, las funciones son más complejas y largas que esta, y tarde o temprano precisan llamar a otras funciones, por lo que es buena práctica que lo primero que hagamos al implementar cualquier función sea escribir el prólogo y el epílogo.
Veamos cómo se implementaría la misma función pero si hubiese que llamar a funciones de C:

``` ASM
;importamos las funciones de C que queremos usar
extern sumar_c 
extern restar_c

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

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
```

En esta implementación utilizamos registros no volátiles para preservar valores a través de un llamado a función pero es posible que en algunas funciones tengamos más datos que registros no volátiles disponibles. En ese caso utilizaríamos la pila para almacenarlos, ya sea guardandolos en una posición fija respecto de la base del stack frame (previa reserva de ese espacio) o bien pusheandolos justo antes del llamado y popeandolos al regresar del mismo. Cuál de las dos opciones es conveniente depende del caso de uso. Por ejemplo, en este caso tenemos a x3 que precisamos que sobreviva un llamado a función y x4 que precisamos que sobreviva dos llamados, si no tuviésemos registros no volátiles, podríamos pushear x3 justo antes de llamar a sumar_c y popearlo justo después, pero si lo hacemos con x4 tendríamos que hacerlo dos veces, una por sumar_c y otra por restar_c, o bien podríamos pushearlo antes de sumar_c y popearlo después de restar_c, pero hacer este tipo de movimientos no es aconsejable, es fácil cometer errores y difícil encontrarlos. En cambio, conviene reservar una posición en la pila para x4 y leerlo de ahí cuando sea necesario. Veamos cómo quedaría:

``` ASM
;importamos las funciones de C que queremos usar
extern sumar_c 
extern restar_c

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

; parametros: 
; x1 --> EDI
; x2 --> ESI
; x3 --> EDX
; x4 --> ECX
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
  mov ESI, DWORD [RBP - 8] ;leo x4 de la pila
  call restar_c

  ;el resultado final ya está en EAX, así que no hay que hacer más nada

  ;epilogo
  add RSP, 16 ;restauro tope de pila
  pop RBP ;pila desalineada, RBP restaurado, RSP apuntando a la dirección de retorno
  ret
```

Por si tienen dudas sobre qué hacen sumar_c y restar_c, acá están sus implementaciones:

``` C
uint32_t sumar_c(uint32_t a,uint32_t b){
	return a + b; 
}

uint32_t restar_c(uint32_t a,uint32_t b){
	return a - b; 
}
```

# Un poco de GDB

Si no lo conocían, les presento a su nuevo mejor amigo: `GDB`. GDB (GNU Debugger) es un debugger que se utiliza desde la consola de comandos. Puede parecer un poco feo y complicado al comienzo, pero al final sólo resulta ser feo, y es infinitamente útil a la hora de encontrar problemas en nuestro código, más aún en un lenguaje como assembler, que no se caracteriza por ser fácil de leer. Cuanto antes se acostumbren a usarlo, mejor la van a pasar en esta materia, así que veamos las cuestiones básicas.

Vamos a explorarlo con la función que implementamos recién, les recomiendo que vayan reproduciendo los pasos a medida que leen, así ya se van interiorizando.
Para ejecutar un programa con GDB basta con escribir 'gdb' antes del nombre del ejecutable en la consola:

``` shell
  $ gdb <ejecutable>
```

En este caso, compilaremos y exploraremos `main.c`

``` shell
  $ make main
  $ gdb ./main
```
Veremos un texto similar a este en la consola:

![GDB - 1](../../img/GDB%20-%201.png)

Para ejecutar el código basta con tipear `r` y darle `enter`, pero, como no establecimos ningún breakpoint, la ejecución terminará y no veremos nada.

Para establecer breakpoints tenemos varias opciones, las que más vamos a usar son estas:

``` gdb
  >>> b <nombre_de_funcion>
  >>> b <nombre_de_archivo>:<numero_de_linea>
```

Que en nuestro caso lucirían así:

``` gdb
  >>> b alternate_sum_4_using_c
  >>> b ABI.asm:36
```
Nos confirma que se estableció correctamente:

![GDB - 2](../../img/GDB%20-%202.png)

Y ahora sí podemos ejecutarlo para inspeccionar. Si tienen instalado [gdb-dashboard](https://github.com/cyrus-and/gdb-dashboard) (junto con pygments), van a ver algo como esto:

![GDB - 3](../../img/GDB%20-%203.png)

Observemos algunas de sus secciones:
- En la sección Assembly pueden ver una reconstrucción del assembly siendo ejecutado a partir del binario.
- En la sección Breakpoints pueden ver un listado de los breakpoints establecidos en este momento. Pueden establecer nuevos en cualquier punto de la ejecución y pueden eliminarlos con el comando `delete x` donde x es el id del breakpoint (número entre corchetes a la izquierda de todo).
- En la sección Registers verán el valor contenido actualmente por los registros de propósito general, además de las eflags y los selectores de segmento (estos últimos los veremos en la segunda mitad de la materia).
- En la sección Source tenemos la porción del archivo fuente que corresponde a los alrededores del código binario que se está ejecutando. Acá vemos assembly pero si estuviesemos debuggeando una función en C veríamos C.
- En la sección Stack vemos la cadena de llamadas que nos trajeron hasta este punto del código. En este caso primero se llamó a la función `main` de `main.c` y esta llamó a `alternate_sum_4_using_c` de `ABI.asm`.

Estamos parados en la primer instrucción de `alternate_sum_4_using_c`, aún no se ejecutó. Podemos observar que el valor de RSP termina en 8, eso indica que la pila no está alineada, como es de esperar al inicio de una función (si terminase en 0 estaría alineada). Desde aquí podemos avanzar línea por línea usando el comando `n` o `next` y ver cómo cambian los valores de los registros en cada paso.

![GDB - 4](../../img/GDB%20-%204.png)

Llegando a la línea 46, si queremos inspeccionar la ejecución de la función llamada tenemos que usar el comando `si` o `step`. 

![GDB - 5](../../img/GDB%20-%205.png)

Observen que ahora en la sección Source vemos el código de C y en la sección Variables vemos las variables de la función con sus valores actuales. En la sección Assembly vemos que el compilador decidió (a priori, de forma arbitraria) utilizar EDX para uno de los operandos de la suma, un ejemplo de por qué debíamos preservarlo antes de la llamada.

Cuando hayan terminado de inspeccionar la función, pasemos a inspeccionar la implementación alternativa que comienza en la ĺínea 69.

Ponemos un breakpoint en dicha línea y luego ejecutamos `c` o `continue` para retomar la ejecución normal hasta el próximo checkpoint o el fin de la ejecución.

Si avanzamos hasta la línea 75 ya se habrá guardado el parámetro `x4` en la posición de la pila reservada. Podemos inspeccionar la memoria para ver sus contenidos de varias formas. La más sencilla y directa es usar el comando `p` o `print`.

``` GDB
>>> p $rcx  //imprime el contenido del registro RCX
>>> p *(uint32_t*)$rbp //castea el contenido de RBP como puntero a uint32_t, lo desferencia e imprime el contenido de la dirección de memoria
```

Observen que al nombrar registros se precisa añadir un símbolo `$` al comienzo, de lo contrario se interpretaría como un nombre de variable y daría error al no encontrarla.

Además, el casteo podría haber sido a cualquier otro tipo, incluso structs propios, y los imprimiría de forma prolija y legible. Pueden probarlos con los ejercicios de la guía de C.

Este comando también permite hacer cálculos aritméticos entre varios registros y constantes, e imprimir el resultado, experimenten por su cuenta. En este momento, nos sirve para imprimir una posición de memoria relativa a la base de la pila y corroborar que se guardó el valor de `x4`:

![GDB - 6](../../img/GDB%20-%206.png)

La otra forma de inspeccionar los contenidos de la memoria es mediante el comando `x`, que se puede ejecutar de las siguientes maneras:

``` GDB
>>> x <expresión de dirección>
>>> x /<formato> <expresión de dirección>
>>> x /<largo> <formato> <expresión de dirección>
```
Donde: 
- `expresión de dirección` especifica la dirección de memoria cuyos contenidos se mostrarán. Puede ser una dirección o cualquier expresión de C/C++ que evalúe a una dirección.
- `formato` especifica el formato en que se mostrarán los contenidos de la memoria, pueden ser:

  - o - octal
  - x - hexadecimal
  - d - decimal
  - u - decimal sin signo
  - t - binario
  - f - punto flotante
  - a - dirección
  - c - caracter
  - s - string
  - i - instrucción

  Y se pueden agregar los siguientes modificadores para especificar el tamaño de los elementos:

  - b - byte
  - h - word (16-bit)
  - w - double word (32-bit)
  - g - quad word (64-bit)
- `largo` especifica la cantidad de elementos que se imprimirán.

Algunos ejemplos tomados de [Visual GDB](https://visualgdb.com/gdbreference/commands/x):

![GDB - 7](../../img/GDB%20-%207.png)

![GDB - 8](../../img/GDB%20-%208.png)

Como se imaginarán, esto es solo la punta del iceberg de lo que GDB es capaz de hacer. Les recomiendo revisar la [documentación](https://www.sourceware.org/gdb/documentation/) para profundizar en su uso.


# Ejercicios

Programen en assembly las siguientes funciones:

- alternate_sum_8
- product_2_f
- product_9_f

El archivo que tienen que editar es `ABI.asm`. Para todas las declaraciones de las funciones en ASM van a encontrar la firma de la función en `ABI.h`. Completar para cada parámetro en qué registro o posición de la pila se encuentra cada uno.

### Compilación y Testeo

En cada sección encontrarán un archivo [`main.c`] para que ustedes realicen pruebas básicas de sus funciones. Siéntanse a gusto de manejarlo como crean conveniente.
Para compilar el código y poder correr las pruebas cortas implementadas por ustedes en main deberá ejecutar `make main` y luego `./runMain.sh`.

En cambio, para compilar el código y correr las pruebas intensivas deberán ejecutar `./tester`.
El programa puede correrse con `./runTester.sh` para verificar que no se pierde memoria ni se realizan accesos incorrectos a la misma.

Finalmente, para ejecutarlas pruebas de ABI deberán compilar con `make abi_enforcer_tester` (o `make_abi_enforcer_main`) y correr con `./runAbi.sh`.

:warning: Por favor lean las advertencias en el README.md principal del repositorio antes de utilizar el abi tester.
Esta herramienta se utilizará para evaluar los parciales, así que no dejen de utilizarla!

#### Pruebas intensivas (Testing)

Entregamos también una serie de *tests* o pruebas intensivas para que pueda verificarse el buen funcionamiento del código de manera automática. Para correr el testing se debe ejecutar `./runTester.sh`, que compilará el *tester* y correrá todos los tests de la sección provistos por la cátedra. Presten atención a la correcta administración de la memoria dinámica, el script correrá los tests con valgrind y alertará en caso de encontrar errores de memoria.
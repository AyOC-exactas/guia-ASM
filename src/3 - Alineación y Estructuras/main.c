#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "../test-utils.h"
#include "Estructuras.h"

uint32_t cantidad_total_de_elementos(lista_t *lista){
    nodo_t *actualNodo= lista->head;
    uint32_t count=0;
    while (actualNodo==NULL){
        actualNodo->next;
        count++;
    }
    
    return count;
}

int main() {
	/* Acá pueden realizar sus propias pruebas */
	return 0;
}

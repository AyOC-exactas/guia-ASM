CC=cc
CFLAGS= -std=c11 -Wall -Wextra -pedantic -O0 -g -lm -Wno-unused-variable -Wno-unused-parameter -no-pie -z noexecstack -I ../
NASM=nasm
NASMFLAGS=-f elf64 -g -F DWARF
NASM_ABI_FLAGS=$(NASMFLAGS) -p "abi_enforcer.mac"

all: main tester abi_enforcer_tester abi_enforcer_main

C_OBJS := ABI_c.o
ASM_OBJS := ABI_asm.o ABI_c.o
ABI_OBJS := ABI_abi.o abi_enforcer_regsave.o ABI_c.o

tester: tester.o $(ASM_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

main: main.o $(ASM_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

abi_enforcer_tester: tester.o $(ABI_OBJS)
	$(CC) $(CFLAGS) -DWITH_ABI_ENFORCER=1 $^ -o $@

abi_enforcer_main: main.o $(ABI_OBJS)
	$(CC) $(CFLAGS) -DWITH_ABI_ENFORCER=1 $^ -o $@

tester.o: tester.c
	$(CC) $(CFLAGS) -c $< -o $@

main.o: main.c
	$(CC) $(CFLAGS) -c $< -o $@

ABI_c.o: ABI.c
	$(CC) $(CFLAGS) -c $< -o $@

ABI_asm.o: ABI.asm
	$(NASM) $(NASMFLAGS) $< -o $@

ABI_abi.o: ABI.asm abi_enforcer.mac
	$(NASM) $(NASM_ABI_FLAGS) $< -o $@

abi_enforcer_regsave.o: abi_enforcer_regsave.asm
	$(NASM) $(NASMFLAGS) $< -o $@

clean:
	rm -f *.o
	rm -f tester tester_c main main_c abi_enforcer_tester abi_enforcer_main

.PHONY: ABI_abi.o
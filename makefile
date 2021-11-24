all:
	nasm -f elf64 simulA.asm -o simulA.o
	gcc -no-pie -Wno-unused-result -O2 -o simul simulC.c simulA.o
clean:
	rm simulA.o simul
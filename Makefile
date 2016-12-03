all: 1

1.o: 1.asm
	yasm -Worphan-labels -Wno-unrecognized-char -f macho -o 1.o -m amd64 1.asm
1: 1.o
	gcc -fno-pie -o 1 1.o

clean:
	rm *.o

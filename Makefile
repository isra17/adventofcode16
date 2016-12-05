%.o: %.asm
	yasm -Worphan-labels -Wno-unrecognized-char -f macho -o $@ -m amd64 $^
%: %.o
	gcc -fno-pie -o $@ $^

all: 1 2 2_5

test: all
	./1
	./2
	./2_5

clean:
	rm *.o

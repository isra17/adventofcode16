%.o: %.asm
	yasm -Worphan-labels -Wno-unrecognized-char -f macho -o $@ -m amd64 $^
%: %.o
	gcc -fno-pie -o $@ $^

all: 2

test: all
	./2

clean:
	rm *.o

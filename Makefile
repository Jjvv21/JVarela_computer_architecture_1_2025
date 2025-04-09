# Nombre del programa (sin extensión)
PROGRAM = test

all: $(PROGRAM)

$(PROGRAM): $(PROGRAM).o
	ld -m elf_i386 -o $(PROGRAM) $(PROGRAM).o

$(PROGRAM).o: $(PROGRAM).asm
	nasm -f elf32 $(PROGRAM).asm -o $(PROGRAM).o

run: 
	./$(PROGRAM)

clean:
	rm -f $(PROGRAM) $(PROGRAM).o


EXE=space_invaders.exe
SRC=$(wildcard *.asm)
OBJ=$(SRC:.asm=.obj)

$(EXE): $(OBJ)
	gcc -o $(EXE) $(OBJ) SDL2.lib

%.obj: %.asm
	nasm -f win64 -o $@ $<

clean:
	@rm $(EXE) $(OBJ)

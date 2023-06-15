EXE=space_invaders.exe
SRC=$(wildcard *.asm)
OBJ=$(SRC:.asm=.obj)

$(EXE): $(OBJ)
	gcc -o $(EXE) $(OBJ) SDL2.lib

$(OBJ): $(SRC)
	nasm -f win64 $(SRC)

clean:
	@rm $(EXE) $(OBJ)

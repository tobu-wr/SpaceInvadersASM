SRCDIR=src/
OUTDIR=out/
SRC=$(wildcard $(SRCDIR)*.asm)
LIB=$(wildcard ext/*.lib)
EXE=$(OUTDIR)space_invaders.exe
OBJ=$(SRC:$(SRCDIR)%.asm=$(OUTDIR)%.obj)

$(EXE): $(OBJ)
	gcc -o $(EXE) $(OBJ) $(LIB)

$(OUTDIR)%.obj: $(SRCDIR)%.asm
	nasm -f win64 -I$(SRCDIR) -o $@ $<

$(OBJ): | $(OUTDIR)

$(OUTDIR):
	@mkdir $(OUTDIR)

.PHONY: clean
clean:
	@rm $(EXE) $(OBJ)

SRCDIR=
OUTDIR=out/
SRC=$(SRCDIR)$(wildcard *.asm)
EXE=$(OUTDIR)space_invaders.exe
OBJ=$(SRC:$(SRCDIR)%.asm=$(OUTDIR)%.obj)

$(EXE): $(OBJ)
	gcc -o $(EXE) $(OBJ) SDL2.lib

$(OUTDIR)%.obj: $(SRCDIR)%.asm
	nasm -f win64 -o $@ $<

$(OBJ): | $(OUTDIR)

$(OUTDIR):
	@mkdir $(OUTDIR)

.PHONY: clean
clean:
	@rm $(EXE) $(OBJ)

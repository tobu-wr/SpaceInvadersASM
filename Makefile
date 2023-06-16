SRCDIR=
OUTDIR=out/
SRC=$(SRCDIR)$(wildcard *.asm)
EXE=$(OUTDIR)space_invaders.exe
OBJ=$(SRC:$(SRCDIR)%.asm=$(OUTDIR)%.obj)

$(EXE): $(OBJ)
	gcc -o $(EXE) $(OBJ) SDL2.lib

$(OUTDIR)%.obj: $(SRCDIR)%.asm $(OUTDIR) 
	nasm -f win64 -o $@ $<

$(OUTDIR):
	@mkdir -p $(OUTDIR)

clean:
	@rm $(EXE) $(OBJ)

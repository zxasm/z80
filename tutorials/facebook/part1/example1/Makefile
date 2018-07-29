
OBJ=prog.tap
SYM=prog.sym
SRC=main.asm

ASMCMD=pasmo
AFLAGS=-1 --tapbas

EMUCMD=fuse
EFLAGS=-g hq3x -m plus3

all: $(OBJ)

$(OBJ): $(SRC)
	$(ASMCMD) $(AFLAGS) $< $@ $(SYM)

emu: $(OBJ)
	$(EMUCMD) $(EFLAGS) -tap $(OBJ)

clean:
	rm -rf $(OBJ) $(SYM)

#!/usr/bin/make

# The subdirectory where intermediate files (.o, etc.) will be stored
DOBJDIR = bin

# The doxygen config file name
DOXYFILE=Doxyfile

C_LIBS=-lncurses -lzmq
D_LIBS=${addprefix -L, $(C_LIBS)}
DMAIN=${SRC_PREFIX}/chatty.d
DFILES=${wildcard chatty/*.d}
D_FLAGS=-property -wi -od"$(DOBJDIR)" $(D_LIBS) $(DMAIN) -I"src"
SRC_PREFIX=chatty
DBLD=rdmd --build-only $(D_FLAGS)
#DBLD=rdmd --build-only --dry-run $(D_FLAGS)
#DBLD=dmd $(D_FLAGS)

all: chatty

chatty: $(DFILES)
	${DBLD} -of"bin/chatty"

docs:
	doxygen $(DOXYFILE)

clean:
	rm -rf $(DOBJDIR) docs &> /dev/null

#
#

# Change this to match your expat installation.
EXPAT_LIB=-lexpat
EXPAT_LIBDIR=/usr/local/lib
EXPAT_INCDIR=/usr/local/include

NAME=expat
OBJECTS=expat.cmo
XOBJECTS=$(OBJECTS:.cmo=.cmx)
C_OBJECTS=expat_stubs$(EXT_OBJ)

ARCHIVE=$(NAME).cma
XARCHIVE=$(ARCHIVE:.cma=.cmxa)
CARCHIVE_NAME=mlexpat
CARCHIVE=lib$(CARCHIVE_NAME)$(EXT_LIB)

# Flags for the C compiler.
CFLAGS=-DFULL_UNROLL -O2 -I$(EXPAT_INCDIR)

OCAMLFIND=ocamlfind
OCAMLC=$(OCAMLFIND) ocamlc
OCAMLOPT=$(OCAMLFIND) ocamlopt
OCAMLDEP=$(OCAMLFIND) ocamldep
OCAMLMKLIB=$(OCAMLFIND) ocamlmklib
OCAMLDOC=$(OCAMLFIND) ocamldoc
OCAMLDIR=$(shell $(OCAMLFIND) query stdlib)
include $(OCAMLDIR)/Makefile.config

.PHONY: all
all: $(ARCHIVE)
.PHONY: allopt
allopt:  $(XARCHIVE)

depend: *.c *.ml *.mli
	gcc -I $(OCAMLDIR) -MM *.c > depend
	$(OCAMLDEP) *.mli *.ml >> depend

## Library creation
$(CARCHIVE): $(C_OBJECTS)
	$(OCAMLMKLIB) -oc $(CARCHIVE_NAME) $(C_OBJECTS) \
	-L$(EXPAT_LIBDIR) $(EXPAT_LIB)
$(ARCHIVE): $(CARCHIVE) $(OBJECTS)
	$(OCAMLMKLIB) -o $(NAME) $(OBJECTS) -oc $(CARCHIVE_NAME) \
	-L$(EXPAT_LIBDIR) $(EXPAT_LIB)
$(XARCHIVE): $(CARCHIVE) $(XOBJECTS)
	$(OCAMLMKLIB) -o $(NAME) $(XOBJECTS) -oc $(CARCHIVE_NAME) \
	-L$(EXPAT_LIBDIR) $(EXPAT_LIB)

## Installation
.PHONY: install
install: all
	{ test ! -f $(XARCHIVE) || extra="$(XARCHIVE) $(NAME)$(EXT_LIB)"; }; \
	$(OCAMLFIND) install $(NAME) META $(NAME).cmi $(NAME).mli $(ARCHIVE) \
	dll$(CARCHIVE_NAME)$(EXT_DLL) lib$(CARCHIVE_NAME)$(EXT_LIB) $$extra

.PHONY: uninstall
uninstall:
	$(OCAMLFIND) remove $(NAME)

## Documentation
.PHONY: doc
doc: FORCE
	cd doc; $(OCAMLDOC) -html -I .. ../$(NAME).mli

## Testing
.PHONY: testall
testall: test testopt
.PHONY: test
test: unittest
	CAML_LD_LIBRARY_PATH=$(pwd) ./unittest
.PHONY: testopt
testopt: unittest.opt
	./unittest.opt
unittest: all unittest.ml
	$(OCAMLFIND) ocamlc -o unittest -package oUnit -ccopt -L. -linkpkg \
	$(ARCHIVE) unittest.ml
unittest.opt: allopt unittest.ml
	$(OCAMLFIND) ocamlopt -o unittest.opt -package oUnit -ccopt -L. -linkpkg \
	$(XARCHIVE) unittest.ml

## Cleaning up
.PHONY: clean
clean::
	rm -f *~ *.cm* *$(EXT_OBJ) *$(EXT_LIB) *$(EXT_DLL) doc/*.html doc/*.css depend \
	unittest unittest.opt

FORCE:

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $(COMPFLAGS) $<
.ml.cmo:
	$(OCAMLC) -c $(COMPLAGS) $<
.ml.cmx:
	$(OCAMLOPT) -c $(COMPFLAGS) $<
.c.o:
	$(OCAMLC) -c -ccopt "$(CFLAGS)" $<

include depend

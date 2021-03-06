#########################################################################
#                                                                       #
#                            Objective Caml                             #
#                                                                       #
#            Xavier Leroy, projet Cristal, INRIA Rocquencourt           #
#                                                                       #
#   Copyright 1999 Institut National de Recherche en Informatique et    #
#   en Automatique.  All rights reserved.  This file is distributed     #
#   under the terms of the GNU Library General Public License, with     #
#   the special exception on linking described in file ../LICENSE.      #
#                                                                       #
#########################################################################

# $Id: Makefile,v 1.91 2008/07/24 05:18:31 frisch Exp $

include Makefile.shared

allopt: stdlib.cmxa std_exit.cmx allopt-$(PROFILING)

allopt-noprof:

allopt-prof: stdlib.p.cmxa std_exit.p.cmx
	rm -f std_exit.p.cmi

installopt: installopt-default installopt-$(PROFILING)
	cp *.cmi *.mli *.ml $(LIBDIR)

installopt-default:
	cp stdlib.cmxa stdlib.a std_exit.o *.cmx $(LIBDIR)
	cd $(LIBDIR); $(TARGETRANLIB) stdlib.a

installopt-noprof:
	rm -f $(LIBDIR)/stdlib.p.cmxa; ln -s stdlib.cmxa $(LIBDIR)/stdlib.p.cmxa
	rm -f $(LIBDIR)/stdlib.p.a; ln -s stdlib.a $(LIBDIR)/stdlib.p.a
	rm -f $(LIBDIR)/std_exit.p.cmx; \
          ln -s std_exit.cmx $(LIBDIR)/std_exit.p.cmx
	rm -f $(LIBDIR)/std_exit.p.o; ln -s std_exit.o $(LIBDIR)/std_exit.p.o

installopt-prof:
	cp stdlib.p.cmxa stdlib.p.a std_exit.p.cmx std_exit.p.o $(LIBDIR)
	cd $(LIBDIR); $(TARGETRANLIB) stdlib.p.a

stdlib.p.cmxa: $(OBJS:.cmo=.p.cmx)
	$(CAMLOPT) -a -o stdlib.p.cmxa $(OBJS:.cmo=.p.cmx)

camlheader camlheader_ur: header.c ../config/Makefile
	if $(SHARPBANGSCRIPTS); then \
          echo '#!$(BINDIR)/ocamlrun' > camlheader && \
          echo '#!' | tr -d '\012' > camlheader_ur; \
        else \
	  $(BYTECC) $(BYTECCCOMPOPTS) $(BYTECCLINKOPTS) \
                    -DRUNTIME_NAME='"$(BINDIR)/ocamlrun"' \
                    header.c -o tmpheader$(EXE) && \
          strip tmpheader$(EXE) && \
	  mv tmpheader$(EXE) camlheader && \
          cp camlheader camlheader_ur; \
        fi

.PHONY: all allopt allopt-noprof allopt-prof install installopt
.PHONY: installopt-default installopt-noprof installopt-prof clean depend

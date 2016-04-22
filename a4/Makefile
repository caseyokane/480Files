#   Dylan Wright - dylan.wright@uky.edu
#   EE480 - Assignment 2: The Making Of An IDIOT
#   Makefile
#   Version:
#	   02-14-2016

VERILOG = iverilog
SIMENGINE = vvp
WAVEVIEWER = gtkwave

MODULES=
COMPILED=dsn
TESTS=
SIMS=test.vcd

NOTE=notes.tex
PDF=$(NOTE:.tex=.pdf)

all: test.vcd

$(COMPILED):
	$(VERILOG) -o $(COMPILED) $(MODULES) $(TESTS)

$(SIMS): $(COMPILED)
	$(SIMENGINE) $(COMPILED)

view:
	$(WAVEVIEWER) $(SIMS) &

note: $(NOTE)
	pdflatex $^
	pdflatex $^

idiocc:
	gcc -o IDIOT/idiocc idiocc.c

clean:
	-rm dsn
	-rm *.vcd
	-rm *.aux *.log
	-rm idiocc

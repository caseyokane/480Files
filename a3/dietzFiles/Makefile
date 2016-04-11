VERILOG=iverilog
SIMENGINE=vvp
WAVEVIEWER=gtkwave

MODULES=ee480MultiCycle.v
COMPILED=dsn
TESTS=ee480MultiCycle_tb.v
SIMS=ee480MultiCycle_tb.vcd


all: $(SIMS)

$(COMPILED): $(MODULES) $(TESTS)
	$(VERILOG) -o $(COMPILED) $(MODULES) $(TESTS)

$(SIMS): $(COMPILED)
	$(SIMENGINE) $(COMPILED)

clean: 
	rm $(COMPILED) 

VERILOG = iverilog
SIMENGINE = vvp
WAVEVIEWER = gtkwave

MODULES=alu.v
COMPILED=dsn
TESTS=alu_tb.v
SIMS=alu_tb.vcd

all: $(SIMS)

$(COMPILED): $(MODULES) $(TESTS)
	$(VERILOG) -o $(COMPILED) $(MODULES) $(TESTS)

$(SIMS): $(COMPILED)
	$(SIMENGINE) $(COMPILED)

clean:
	rm $(COMPILED) $(SIMS)

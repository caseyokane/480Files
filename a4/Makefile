VERILOG = iverilog
SIMENGINE = vvp
WAVEVIEWER = gtkwave

MODULES=floatpipe.v
COMPILED=dsn
SIMS=results.vcd

all: $(SIMS)

$(COMPILED): $(MODULES) 
	$(VERILOG) -o $(COMPILED) $(MODULES) 

$(SIMS): $(COMPILED)
	$(SIMENGINE) $(COMPILED)

clean:
	rm $(COMPILED) $(SIMS)

// defining global constants
`define WORD	[15:0]
`define REGSIZE	[63:0]
`define MEMSIZE	[65535:0]
`define OPBITS	[3:0]
`define SDBITS	[5:0]

// opcode definitions
`define ADD     4'b0000
`define INVF    4'b0001
`define ADDF    4'b0010
`define MULF    4'b0011
`define AND     4'b0100
`define OR      4'b0101
`define XOR     4'b0110
`define ANY     4'b0111
`define DUP     4'b1000
`define SHR     4'b1001
`define F2I     4'b1010
`define I2F     4'b1011
`define LD      4'b1100
`define ST      4'b1101
`define JZSYSSZ 4'b1110
`define LI      4'b1111

<<<<<<< HEAD
module pc(pcIn, pcOut, rw)
	input 'WORD pcIn;
	input rw;
	output 'WORD pcOut;
	reg current_pc [15:0];
	if (rw==0) pcOut = current_pc;
	else current_pc = pcIn;
endmodule

module instmem(addr, op, s, d)
	input [15:0] addr;
	output [3:0] op;
	output [5:0] s, d;
=======
module instmem(addr, op, s, d, reset);
	input `WORD addr;
	input reset;
	output reg `OPBITS op;
	output reg `SDBITS s, d;
>>>>>>> 73f4d909e692e353ed9378854598b6b8c49d9db4
	// define the memory cells
	reg `WORD mem `MEMSIZE; 
	// output the correct instruction
	always @(addr) begin
		op = mem[addr][15:12];
		d =  mem[addr][11:6];
		s =  mem[addr][5:0];
	end
	// reset the instructions
	always @(reset) $readmemh("inst.txt", mem);
endmodule

module registers(addrS, addrD, sOut, dOut, writeAddr, writeVal, writeEn, reset);
	input `SDBITS addrS, addrD, writeAddr;
	input `WORD writeVal;
	input writeEn, reset;
	output `WORD sOut, dOut;
	// define the memory cells
	reg `WORD mem `MEMSIZE; 
	// output the correct instruction
	assign sOut = mem[addrS];
	assign dOut = mem[addrD];
	always @(writeEn, writeAddr, writeVal) begin
	if (writeEn==1) 
		// make sure you're not overwriting one of the bottom 4 special registers
		if (writeAddr >= 4) mem[writeAddr] = writeVal; 
	end
	// reset the registers
	always @(reset) begin 
		$readmemh("reg.txt", mem);
		mem [0] = 0;
		mem [1] = 1;
		mem [2] = 16'h8000;
		mem [3] = 16'hffff;
	end
endmodule

module mux16bit2to1(a, b, s, out);
	input `WORD a, b;
	input s;
	output reg `WORD out;
	always @(s, a, b) begin
		if(s==0) out = a;
		else out = b;
	end
endmodule

module alu(op, num1, num2, out);
	input `OPBITS op;
	input `WORD num1, num2;
	output reg `WORD out;
	always @(op, num1, num2) begin case(op)
		`ADD: out = num1 + num2;
		`AND: out = num1 & num2;
		`ANY: begin	
			if (num2 != 0)
				out = 1;
			else
				out = 0;
			end
		`OR: out = num1 | num2;
		`SHR: out = num1 >> 1;
		`XOR: out = num1 ^ num2;
		`DUP: out = num1;
		default: out = 0;
 	endcase end
endmodule

module datamem(readAddr, writeAddr, writeVal, out, readEn, writeEn, reset);
	input `WORD readAddr, writeAddr, writeVal;
	input readEn, writeEn, reset;
	output reg `WORD out;
	// define the memory cells
	reg `WORD mem`MEMSIZE; 
	// output the correct data
	always @(readAddr or readEn or writeAddr or writeEn or writeVal)
	begin
	if (readEn==1) 
		out = mem[readAddr];
	if (writeEn==1)
		mem[writeAddr] = writeVal;
	end
	// reset the mem
	always @(reset) $readmemh("datamem.txt", mem);
endmodule

module instBuffer (enable, opIn, sIn, dIn, opOut, sOut, dOut, clock, nop, reset);
	input clock, enable, nop, reset;
	input `OPBITS opIn;
	input `SDBITS sIn, dIn;
	output reg `OPBITS opOut;
	output reg `SDBITS sOut, dOut;
	always @(posedge clock) if(nop) begin
		opOut <= 0;
		sOut <= 0;
		dOut <= 0;
	end else if(enable) begin
		opOut <= opIn;
		sOut <= sIn;
		dOut <= dIn;
	end

	always@(reset) begin
		opOut = 0;
		sOut = 0;
		dOut = 0;
	end
endmodule

module regBuffer (enable, sIn, dIn, sOut, dOut, clock, opIn, opOut, dAddrIn, dAddrOut, nop, reset);
	input clock, enable, reset;
	input `WORD sIn, dIn;
	input `OPBITS opIn;
	input `SDBITS dAddrIn;
	input nop;
	output reg `WORD sOut, dOut;
	output reg `OPBITS opOut;
	output reg `SDBITS dAddrOut;
	always @(posedge clock) if(nop) begin
		sOut <= 0;
		dOut <= 0;
		opOut <= 0;
		dAddrOut <= 0;
	end else if(enable) begin
		sOut <= sIn;
		dOut <= dIn;
		opOut <= opIn;
		dAddrOut <= dAddrIn;
	end
	always @(reset) begin
		sOut = 0;
		dOut = 0;
		opOut = 0;
		dAddrOut = 0;
	end
endmodule

module aluBuffer (enable, clock, aluIn, aluOut, memIn, memOut, opIn, opOut, aluD, storeD, nop, reset);
	input clock, enable, reset;
	input `WORD aluIn, memIn;
	input `OPBITS opIn;
	input `SDBITS aluD;
	input nop;
	output reg `WORD aluOut, memOut;
	output reg `OPBITS opOut;
	output reg `SDBITS storeD;
	always @(posedge clock) if(nop) begin
		aluOut <= 0;
		memOut <= 0;
		opOut <= 0;
		storeD <= 0;
	end else if(enable) begin
		aluOut <= aluIn;
		memOut <= memIn;
		opOut <= opIn;
		storeD <= aluD;
	end
	
	always @(reset) begin
		aluOut = 0;
		memOut = 0;
		opOut = 0;
		storeD = 0;
	end
endmodule

module incrementor(in, out, clock, enable, reset);
	input clock, enable, reset;
	input `WORD in;
	output reg `WORD out;
	always @* begin
		if (enable) out = in+1;
	end
	always @(reset) out = 1;
endmodule

module dependDetect(reset, opif, oprr, opalu, oprw, sif, srr, dif, drr, dalu, drw, ifenable, rrenable, aluenable, ifNop, rrNop, aluNop);
	input `OPBITS opif, oprr, opalu, oprw;
	input `SDBITS sif, srr;
	input `SDBITS dif, drr, dalu, drw;
	input reset, ifNop, rrNop, aluNop;
	output reg ifenable, rrenable, aluenable;
	
	// reset
	always @(reset) begin
		ifenable = 1;
		rrenable = 1;
		aluenable = 1;
	end
	
	always @* begin
	// pause the reg read stage
		if( 
			((oprr==0&srr==0&drr==0)|(
				(srr!=dalu)&(srr!=drw)
			))&(
			(opalu==0&dalu==0)|(
				(drr!=dalu)&(drr!=drw)
			)))
		rrenable = 1;
		else rrenable = 0;
	// pause the instruction fetch stage
		if(rrenable == 1) ifenable = 1;
		else ifenable = 0;
	end
endmodule

module processor (halt, clock, reset);
input clock, reset;
output reg halt;
	// instruction fetch wires
	wire `WORD pcIn, pcOut, pcInc, instmemAddr;
	wire `OPBITS instOp;
	wire `SDBITS instS, instD;
	wire ifBufferEnable;
	reg pcWriteEnable, liFlag, ifNop;
	reg `SDBITS liDest;
	reg `WORD pc;
	// register read wires
	wire `OPBITS regOp;
	wire `SDBITS regS, regD;
	wire `WORD regValS, regValD;
	wire rrBufferEnable;
	reg rrNop;
	// ALU/DataMem wires
	wire `WORD aluOut, memOut, aluS, aluD;
	wire `OPBITS aluOp;
	wire `WORD memWriteAddr, writeValIn;
	wire `SDBITS aluDAddr;
	wire aluBufferEnable;
	reg memReadEn, aluNop;
	// register store wires
	wire `WORD aluStore, memStore, storeVal, jumpAddr;
	wire `OPBITS storeOp;
	wire `SDBITS regWriteAddr;
	reg jumpEn;
	reg aludatacontrol, regWriteEn, memWriteEn;
	
	// dependancy detection
	dependDetect dependDetect1(reset, instOp, regOp, aluOp, storeOp, instS, regS, instD, regD, aluDAddr, regWriteAddr, ifBufferEnable, rrBufferEnable, aluBufferEnable, ifNop, rrNop, aluNop);
	
	// processor reset
	always @(reset) begin
		halt = 0;
		pc = 0;
		pcWriteEnable = 1;
		jumpEn = 0;
		liFlag = 0;
		ifNop = 0;
		rrNop = 0;
		aluNop = 0;
	end
	
	// nops
	always @* begin
		// if nop
		if (!ifBufferEnable & rrBufferEnable)
		ifNop = 1;
		else ifNop = 0;
		// rr nop
		if (!rrBufferEnable & aluBufferEnable) rrNop = 1;
		else rrNop = 0;
		// alu nop
		if (!aluBufferEnable) aluNop = 1;
		else aluNop = 0;
	end
	
	// instruction fetch stage
	// program counter
	always @(posedge clock)	if (pcWriteEnable&ifBufferEnable) pc <= pcIn;
	assign pcOut = pc;
	// li instructions
	always @(instOp) begin
		if (instOp==`LI) begin liFlag = 1; liDest = instD; end
		else liFlag = 0;
	end
	
	instmem instmem1(pc,instOp, instS, instD, reset);
	instBuffer instBuffer1(ifBufferEnable, instOp, instS, instD, regOp, regS, regD, clock, ifNop, reset);
	incrementor incrementor1(pcOut, pcInc, clock, ifBufferEnable, reset);
	mux16bit2to1 pcMux(pcInc, jumpAddr, jumpEn, pcIn);
	
	// register read stage
	registers registers1(regS, regD, regValS, regValD, regWriteAddr, storeVal, regWriteEn, reset);
	regBuffer regBuffer1(rrBufferEnable, regValS, regValD, aluS, aluD, clock, regOp, aluOp, regD, aluDAddr, rrNop, reset);
	
	// ALU/DataMem stage
	alu alu1(aluOp, aluS, aluD, aluOut);	
	datamem datamem1(aluD, memWriteAddr, writeValIn, memOut, memReadEn, memWriteEn, reset);
	aluBuffer aluBuffer1(aluBufferEnable, clock, aluOut, aluStore, memOut, memStore, aluOp, storeOp, aluDAddr, regWriteAddr, aluNop, reset);
	
	// register store stage
<<<<<<< HEAD
	wire [15:0] aluStore, memStore, storeVal;
	wire [3:0] storeOp;
	wire regWriteEn, aludatacontrol;
	// because of the way the opcodes were chosen, an alu op occured as long 
	//as bits 2 and 3 of the opcode were not both 1s.
	if (storeOp[3:2] != 2'b11) aludatacontrol = 0;
	else aludatacontrol = 1;
	mux8bit2to1 mux_aludatacontrol(aluStore, memStore, aludatacontrol, storeVal);
	if ((storeOp!=`ST)&(storeOp!=`JZSYSSZ)) regWriteEn = 1;
	else regWriteEn = 0;
	
endmodule
=======
	// because of the way the opcodes were chosen, an alu op occurred as long as bits 2 and 3 of the opcode were not both 1
	always @(storeOp) begin
		// storing from alu or memory
		if (storeOp[3:2] != 2'b11) assign aludatacontrol = 0;
		else assign aludatacontrol = 1;
		// store into registers
		if ((storeOp!=`ST)&(storeOp!=`JZSYSSZ)) assign regWriteEn = 1; 
		else assign regWriteEn = 0;
		// store into main memory
		if (storeOp==`ST) assign memWriteEn = 1;
		else assign memWriteEn = 0;
	end
	mux16bit2to1 mux_aludatacontrol(aluStore, memStore, aludatacontrol, storeVal);
endmodule

module testbench();
	reg reset = 0;
	reg clk = 0;
	wire halted;
	processor PE(halted, clk, reset);
	initial begin
		$dumpfile("ee480.2.0.txt");
		$dumpvars(0, PE);
		#10 reset = 1;
		#10 reset = 0;
		while (!halted) begin
			#10 clk = 1;
			#10 clk = 0;
		end
		$finish;
	end
endmodule

>>>>>>> 73f4d909e692e353ed9378854598b6b8c49d9db4

// defining global constants
`define WORD	[15:0]
`define REGSIZE	[63:0]
`define MEMSIZE	[65535:0]
`define OPBITS	[3:0]
`define SDBITS	[5:0]
`define OPCODE	[15:12]
`define SRC		[11:6]
`define DST		[5:0]


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

//No definitions for state numbers?

module pc(pcIn, pcOut, rw)
	input `WORD pcIn;
	input rw;
	output `WORD pcOut;
	reg current_pc `WORD;
	if (rw==0) pcOut = current_pc;
	else current_pc = pcIn;
endmodule

module instmem(addr, op, s, d)
	input `WORD addr;
	output `OPBITS op;
	output `SDBITS s, d;
	// define the memory cells
	reg `WORD mem `MEMSIZE; 
	// output the correct instruction
	always @(addr) begin
		op = mem[addr]`OPCODE;
		s =  mem[addr]`SRC;
		d =  mem[addr]`DST;
	end
endmodule

module registers(addrS, addrD, sOut, dOut, writeAddr, writeVal, writeEn)
	input `WORD addrS, addrD, writeAddr, writeVal;
	input writeEn; // write enable
	output `WORD sOut, dOut;
	// define the memory cells
	reg `WORD mem `MEMSIZE; 
	// output the correct instruction
	always @(addrS, addrD) begin
		sOut = mem[addrS];
		dOut = mem[addrD];
	end
	if (writeEn==1) assign mem[writeAddr] = writeVal;
endmodule

module mux8bit2to1(a, b, s, out)
	input `WORD a, b;
	intput s;
	output `WORD out;
	if(s==0) assign out = a;
	else assign out = b;
endmodule

module alu(op, num1, num2, out)
	input `OPBITS op;
	input `WORD num1, num2;
	output `WORD out;
endmodule

module datamem
endmodule

module instBuffer (opIn, sIn, dIn, opOut, sOut, dOut, clock)
	input clock;
	input `OPBITS opIn;
	input `SDBITS sIn, dIn;
	output `OPBITS opOut;
	output `SDBITS sOut, dOut;
	always @(posedge clock) begin
		opOut <= opIn;
		sOut <= sIn;
		dOut <= dIn;
	end
endmodule

module regBuffer (sIn, dIn, sOut, dOut, clock)
	input clock;
	input `WORD sIn, dIn;
	output `WORD sOut, dOut;
	always @(posedge clock) begin
		sOut <= sIn;
		dOut <= dIn;
	end
endmodule

module processor (clock, reset)
input clock, reset;
	// instruction fetch stage
	wire `WORD pcIn, pcOut, instmemAddr;
	wire `OPBITS instOp;
	wire `SDBITS instS, instD;
	reg liFlag;
	pc pc1(pcIn, pcOut);
	instmem instmem1(instmemAddr,instOp, instS, instD);
	instBuffer instBuffer1(instOp, instS, instD, regOp, regS, regD, clock);
	always @(posedge clock) begin
		if(instOp==`LI) liFlag = 1;
		else liFlag = 0;
	end
	
	// register read stage
	wire `OPBITS regOp;
	wire `SDBITS regS, regD;
	wire `WORD sValReg, dValReg;
	registers(regS, regD, sValReg, dValReg, writeAddr, writeVal, writeEn)
	regBuffer (sValReg, dValReg, 
	
	// ALU/DataMem stage
	wire `WORD aluS, aluD;
	
endmodule
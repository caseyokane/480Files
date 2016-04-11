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

module pc(pcIn, pcOut, rw)
	input [15:0] pcIn;
	input rw;
	output [15:0] pcOut;
	reg current_pc [15:0];
	if (rw==0) pcOut = current_pc;
	else current_pc = pcIn;
endmodule

module instmem(addr, op, s, d)
	input [15:0] addr;
	output [3:0] op;
	output [5:0] s, d;
	// define the memory cells
	reg [15:0] mem [65535:0]; 
	// output the correct instruction
	always @(addr) begin
		op = mem[addr][15:12];
		s =  mem[addr][11:6];
		d =  mem[addr][5:0];
	end
endmodule

module registers(addrS, addrD, sOut, dOut, writeAddr, writeVal, writeEn)
	input [15:0] addrS, addrD, writeAddr, writeVal;
	input writeEn; // write enable
	output [15:0] sOut, dOut;
	// define the memory cells
	reg [15:0] mem [65535:0]; 
	// output the correct instruction
	always @(addrS, addrD) begin
		sOut = mem[addrS];
		dOut = mem[addrD];
	end
	if (writeEn==1) assign mem[writeAddr] = writeVal;
endmodule

module mux8bit2to1(a, b, s, out)
	input [15:0] a, b;
	intput s;
	output [15:0] out;
	if(s==0) assign out = a;
	else assign out = b;
endmodule

module alu(op, num1, num2, out)
	input [3:0] op;
	input [15:0] num1, num2;
	output [15:0] out;
endmodule

module datamem(addrIn, valIn, out, readEn, writeEn)
	input [15:0] addrIn, valIn, out;
	input readEn, writeEn; // write enable
	output [15:0] out;
	// define the memory cells
	reg [15:0] mem [65535:0]; 
	// output the correct instruction
	always @(addrIn) if (readEn==1) assign out = mem[addr];
	if (writeEn==1) assign mem[writeAddr] = writeVal;
endmodule

module instBuffer (opIn, sIn, dIn, opOut, sOut, dOut, clock)
	input clock;
	input [3:0] opIn;
	input [5:0] sIn, dIn;
	output [3:0] opOut;
	output [5:0] sOut, dOut;
	always @(posedge clock) begin
		opOut <= opIn;
		sOut <= sIn;
		dOut <= dIn;
	end
endmodule

module regBuffer (sIn, dIn, sOut, dOut, clock, opIn, opOut)
	input clock;
	input [15:0] sIn, dIn;
	output [15:0] sOut, dOut;
	always @(posedge clock) begin
		sOut <= sIn;
		dOut <= dIn;
	end
endmodule

module aluBuffer (clock, aluIn, aluOut, memIn, memOut, opIn, opOut);
	input clock;
	input [15:0] aluIn, memIn;
	output [15:0] aluOut, memOut;
	always @(posedge clock) begin
		aluOut <= aluIn;
		memOut <= memIn;
		opOut <= opIn;
	end
endmodule

module incrementor(in, out, clock, enable)
	input clock;
	input [15:0] in;
	output [15:0] out;
	always @(posedge clock) if(enable) out <= in+1;
endmodule

module processor (clock, reset)
input clock, reset;
	// instruction fetch stage
	wire [15:0] pcIn, pcOut, instmemAddr;
	wire [3:0] instOp;
	wire [5:0] instS, instD;
	reg liFlag;
	pc pc1(pcIn, pcOut);
	instmem instmem1(instmemAddr,instOp, instS, instD);
	instBuffer instBuffer1(instOp, instS, instD, regOp, regS, regD, clock);
	incrementor incrementor1(pcOut, pcInc, clock, incEn);
	mux8bit2to1 pcMux(pcInc, jumpAddr, jumpEn, pcIn);
	always @(posedge clock) begin
		if(instOp==`LI) liFlag = 1;
		else liFlag = 0;
	end
	
	// register read stage
	wire [3:0] regOp;
	wire [5:0] regS, regD;
	wire [15:0] sValReg, dValReg;
	registers registers1(regS, regD, sValReg, dValReg, writeAddr, storeVal, regWriteEn)
	regBuffer regBuffer1(sValReg, dValReg, aluS, aluD, clock, regOp, aluOp);
	
	// ALU/DataMem stage
	wire [15:0] aluS, aluD, aluOut, memOut;
	wire [3:0] aluOp;
	alu alu1(aluOp, aluS, aluD, aluOut);	
	aluBuffer aluBuffer1(clock, aluOut, aluStore, memOut, memStore, storeOp);
	
	// register store stage
	wire [15:0] aluStore, memStore, storeVal;
	wire [3:0] storeOp;
	wire regWriteEn, aludatacontrol;
	// because of the way the opcodes were chosen, an alu op occured as long as bits 2 and 3 of the opcode were not both 1s.
	if (storeOp[3:2] != 2'b11) aludatacontrol = 0;
	else aludatacontrol = 1;
	mux8bit2to1 mux_aludatacontrol(aluStore, memStore, aludatacontrol, storeVal);
	if ((storeOp!=`ST)&(storeOp!=`JZSYSSZ)) regWriteEn = 1;
	else regWriteEn = 0;
	
endmodule
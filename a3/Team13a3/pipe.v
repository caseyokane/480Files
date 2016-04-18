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

module instmem(addr, op, s, d, reset);
	input `WORD addr;
	input reset;
	output reg `OPBITS op;
	output reg `SDBITS s, d;
	// define the memory cells
	reg `WORD mem `MEMSIZE; 
	// output the correct instruction
	always @(addr) begin
		op = mem[addr][15:12];
		d =  mem[addr][11:6];
		s =  mem[addr][5:0];
	end
	// reset the instructions
	always @(reset) $readmemh("ReqFiles/inst.txt", mem);
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
		$readmemh("ReqFiles/reg.txt", mem);
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
		`ST: out = num1;
		default: out = 0;
 	endcase end
endmodule

module datamem(readAddr, writeAddr, writeVal, out, writeEn, reset);
	input `WORD readAddr, writeAddr, writeVal;
	input readEn, writeEn, reset;
	output reg `WORD out;
	// define the memory cells
	reg `WORD mem`MEMSIZE; 
	// output the correct data
	always @* begin
		out = mem[readAddr];
		if (writeEn==1) mem[writeAddr] = writeVal;
	end
	// reset the mem
	always @(reset) $readmemh("ReqFiles/datamem.txt", mem);
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

module regBuffer (enable, sIn, dIn, sOut, dOut, clock, opIn, opOut, dAddrIn, dAddrOut, sAddrIn, sAddrOut, nop, reset);
	input clock, enable, reset;
	input `WORD sIn, dIn;
	input `OPBITS opIn;
	input `SDBITS dAddrIn, sAddrIn;
	input nop;
	output reg `WORD sOut, dOut;
	output reg `OPBITS opOut;
	output reg `SDBITS dAddrOut, sAddrOut;
	always @(posedge clock) if(nop) begin
		sOut <= 0;
		dOut <= 0;
		opOut <= 0;
		dAddrOut <= 0;
		sAddrOut <= 0;
	end else if(enable) begin
		sOut <= sIn;
		dOut <= dIn;
		opOut <= opIn;
		dAddrOut <= dAddrIn;
		sAddrOut <= sAddrIn;
	end
	always @(reset) begin
		sOut = 0;
		dOut = 0;
		opOut = 0;
		dAddrOut = 0;
		sAddrOut = 0;
	end
endmodule

module aluBuffer (enable, clock, aluIn, aluOut, memIn, memOut, opIn, opOut, aluD, storeD, memAddrIn, memAddrOut, nop, reset);
	input clock, enable, reset;
	input `WORD aluIn, memIn, memAddrIn;
	input `OPBITS opIn;
	input `SDBITS aluD;
	input nop;
	output reg `WORD aluOut, memOut, memAddrOut;
	output reg `OPBITS opOut;
	output reg `SDBITS storeD;
	always @(posedge clock) if(nop) begin
		aluOut <= 0;
		memOut <= 0;
		opOut <= 0;
		storeD <= 0;
		memAddrOut <= 0;
	end else if(enable) begin
		aluOut <= aluIn;
		memOut <= memIn;
		opOut <= opIn;
		storeD <= aluD;
		memAddrOut <= memAddrIn;
	end
	
	always @(reset) begin
		aluOut = 0;
		memOut = 0;
		opOut = 0;
		storeD = 0;
		memAddrOut = 0;
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

module dependDetect(reset, opif, oprr, opalu, oprw, sif, srr, dif, drr, dalu, drw, ifenable, rrenable, aluenable, ifNop, rrNop, aluNop, liALU, liRW, liRR);
	input `OPBITS opif, oprr, opalu, oprw;
	input `SDBITS sif, srr;
	input `SDBITS dif, drr, dalu, drw;
	input reset, ifNop, rrNop, aluNop, liALU, liRW, liRR;
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
			(((oprr==0&srr==0&drr==0)|(
				((srr!=dalu)|liRR)&((srr!=drw)|liALU)
			))&(
			(opalu==0&dalu==0)|(
				((drr!=dalu)|liRR)&((drr!=drw)|liALU)
			))|(oprr==`LI))
			&opalu!=`JZSYSSZ)
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
	reg pcWriteEnable, ifNop;
	reg `WORD pc;
	// register read wires
	wire `OPBITS regOp;
	wire `SDBITS regS, regD;
	wire `WORD regValS, regValD;
	wire rrBufferEnable;
	reg rrNop;
	// ALU/DataMem wires
	wire `WORD aluOut, memOut, aluS, aluD, memWriteAddr, writeValIn, li2ndWord;
	wire `OPBITS aluOp;
	wire `SDBITS aluDAddr, aluSAddr;
	wire aluBufferEnable;
	reg aluNop; 
	reg `SDBITS aluAddr;
	reg `OPBITS aluOpOut;
	reg `WORD aluORli;
	// register store wires
	wire `WORD aluStore, memStore, storeVal, jumpAddr;
	wire `OPBITS storeOp;
	wire `SDBITS regWriteAddr;
	reg jumpEn, squashEn;
	reg aludatacontrol, regWriteEn, memWriteEn;
	reg `SDBITS liAddr;
	
	// liflags
	reg liIF, liRR, liALU, liRW;
	
	// dependancy detection
	dependDetect dependDetect1(reset, instOp, regOp, aluOp, storeOp, instS, regS, instD, regD, aluAddr, regWriteAddr, ifBufferEnable, rrBufferEnable, aluBufferEnable, ifNop, rrNop, aluNop, liALU, liRW, liRR);
	
	// processor reset
	always @(reset) begin
		halt = 0;
		pc = 0;
		pcWriteEnable = 1;
		jumpEn = 0;
		ifNop = 0;
		rrNop = 0;
		aluNop = 0;
		liIF = 0;
		liRR = 0;
		liALU = 0;
		liRW = 0;
	end
	
	// nops
	always @* begin
		// if nop
		if ((!ifBufferEnable & rrBufferEnable)|jumpEn|(squashEn&liIF))
		ifNop = 1;
		else ifNop = 0;
		// rr nop
		if ((!rrBufferEnable & aluBufferEnable)|jumpEn|squashEn) rrNop = 1;
		else rrNop = 0;
		// alu nop
		if (!aluBufferEnable|jumpEn|squashEn) aluNop = 1;
		else aluNop = 0;
	end
	
	// li flag handling
	always @* begin
		if (regOp==`LI&!liRR) liIF = 1; else liIF = 0;
	end
	always @(posedge clock) begin
		if (liIF&rrBufferEnable) liRR <= 1; else liRR <= 0;
		if (liRR&aluBufferEnable) liALU <= 1; else liALU <= 0;
		if (liALU) liRW <= 1; else liRW <= 0;
	end
	
	// instruction fetch stage
	//  - gets the address from the program counter
	//  - passes that to the instruction memory
	//  - retrieves the instruction, parses into op, s, and d fields
	//  - stores these directly in the IF buffer
	// program counter
	always @(posedge clock)	if ((pcWriteEnable&ifBufferEnable)|jumpEn) begin
		pc <= pcIn;
		jumpEn <= 0;
		squashEn <= 0;
	end
	assign pcOut = pc;

	instmem instmem1(pc,instOp, instS, instD, reset);
	instBuffer instBuffer1(ifBufferEnable, instOp, instS, instD, regOp, regS, regD, clock, ifNop, reset);
	incrementor incrementor1(pcOut, pcInc, clock, ifBufferEnable, reset);
	mux16bit2to1 pcMux(pcInc, jumpAddr, jumpEn, pcIn);
	
	// register read stage
	//	- passes the s and d fields of the instruction to the registers
	//	- passes s and d regvals to the buffer, along with s, d, and op
	registers registers1(regS, regD, regValS, regValD, regWriteAddr, storeVal, regWriteEn, reset);
	regBuffer regBuffer1(rrBufferEnable, regValS, regValD, aluS, aluD, clock, regOp, aluOp, regD, aluDAddr, regS, aluSAddr, rrNop, reset);
	
	// ALU/DataMem stage
	//	- passes the s and d regvals to the alu
	//	- passes the d regval to the memeory
	//	- buffers the alu and mem out values, as well as op and d
	//	- if the op of the instruction in the reg store stage is an LI,
	//	  mux the full instruction into the alu buffer slot instead of
	//	  the actual alu result (because this is the "next word")
	//	- jz op ...
	//		- if the value is 0, set the pc to the jumpAddr and squash 
	//		  all the previous instructions
	alu alu1(aluOp, aluS, aluD, aluOut);	
	datamem datamem1(aluS, memWriteAddr, storeVal, memOut, memWriteEn, reset);
	aluBuffer aluBuffer1(aluBufferEnable, clock, aluORli, aluStore, memOut, memStore, aluOpOut, storeOp, aluAddr, regWriteAddr, aluD, memWriteAddr, aluNop, reset);
	assign li2ndWord [15:12] = aluOp;
	assign li2ndWord [11:6] = aluDAddr;
	assign li2ndWord [5:0] = aluSAddr;
	assign jumpAddr = aluS;
	always @* begin
		// if this is the second word of an li instruction, feed that directly in
		if (liALU) begin 
			aluORli = li2ndWord;
			aluOpOut = `ADD;
			aluAddr = regWriteAddr;
			end
		else begin
			aluORli = aluOut;
			aluOpOut = aluOp;
			aluAddr = aluDAddr;
			end
		// jump/squash
		if (aluOp==`JZSYSSZ) begin
			if (aluD==0) begin
				// do we have a jump?
				if (aluS>1) begin
					ifNop = 0;
					rrNop = 0;
					aluNop = 0;
					jumpEn = 1;
					liIF = 0;
					liRR = 0;
					liALU = 0;
					liRW = 0;
					end
				// do we have a squash?
				else if(aluS==1) begin
					squashEn = 1;
					end
				// do we have a sys call?
				else if(aluS==0) halt = 1;
			end
		end
		// unimplemented floating point calls
		if ((aluOp==`INVF|aluOp==`ADDF|aluOp==`MULF|aluOp==`F2I|aluOp==`I2F)&!liALU) halt = 1;
	end
	
	// register store stage
	// chose between the alu and mem buffer values
	// because of the way the opcodes were chosen, an alu op occurred as long as bits 2 and 3 of the opcode were not both 1
	always @(storeOp,regWriteAddr) begin
		// storing from alu or memory
		if ((storeOp[3:2] != 2'b11)|(storeOp==`LI)|(storeOp==`ST)) assign aludatacontrol = 0;
		else assign aludatacontrol = 1;
		// store into registers
		if ((storeOp!=`ST)&(storeOp!=`JZSYSSZ)&(storeOp!=`LI)&(regWriteAddr>4)) assign regWriteEn = 1; 
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

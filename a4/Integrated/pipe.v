// basic sizes of things
`define WORD	[15:0]
`define RNAME   [5:0]
`define OP	[4:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]
`define REGSIZE [63:0]
`define MEMSIZE [65535:0]

// opcode values, also state numbers
`define OPadd	4'b0000
`define OPinvf	4'b0001
`define OPaddf	4'b0010
`define OPmulf	4'b0011
`define OPand	4'b0100
`define OPor	4'b0101
`define OPxor	4'b0110
`define OPany	4'b0111
`define OPdup	4'b1000
`define OPshr	4'b1001
`define OPf2i	4'b1010
`define OPi2f	4'b1011
`define OPld	4'b1100
`define OPst	4'b1101
`define OPjzsz	4'b1110
`define OPli	4'b1111

// extended opcode values
`define OPjz	5'b10000
`define OPsz	5'b10001
`define OPsys	5'b10010
`define OPnop	5'b11111

// source field values for sys and sz
`define SRCsys	6'b000000
`define SRCsz	6'b000001


module decode(opout, regdst, opin, ir);
output reg `OP opout;
output reg `RNAME regdst;
input wire `OP opin;
input `WORD ir;

always @(opin, ir) begin
  if (opin == `OPli) begin
    opout = `OPnop;       // 2nd word of li becomes nop
    regdst = 0;	  	  // no writing
  end else begin
    case (ir `Opcode)
      `OPjzsz: begin
        regdst = 0;		   // no writing
        case (ir `Src)	           // use Src as extended opcode
          `SRCsys: opout = `OPsys;
          `SRCsz: opout = `OPsz;
          default: opout = `OPjz;
        endcase
      end
      `OPst: begin opout = ir `Opcode; regdst <= 0; end
      default: begin opout = ir `Opcode; regdst <= ir `Dest; end
    endcase
  end
end
endmodule


//Provided helper module for determining the number of leading 0s
//Provide a 16 bit floating point number and receive the number of 0s
module lead0s(d, s);

input wire `WORD  s;
output reg[4:0] d; 
reg[7:0] s8; reg[3:0] s4; reg[1:0] s2;

always @(*) begin
  if(s[15:0] == 0) d = 16; 
  else begin
    d[4] = 0;
    {d[3],s8} = ((|s[15:8]) ? {1'b0,s[15:8]} : {1'b1,s[7:0]});  
    {d[2],s4} = ((|s8[7:4]) ? {1'b0,s8[7:4]} : {1'b1,s8[3:0]});  
    {d[1],s2} = ((|s4[3:2]) ? {1'b0,s4[3:2]} : {1'b1,s4[1:0]});  
    d[0] = !s2[1];
  end
end
endmodule

module alu(result, op, in1, in2);

output reg `WORD result;
input wire `OP op;
input wire `WORD in1, in2;

//Added variables
reg `WORD absValue; reg `WORD tempResult; 
reg[23:0] valueNew;
reg signBit; reg[7:0] expVal; reg[6:0] mantissa;  
wire[4:0] numZero; 
reg [7:0] lookupArr [0:127];

//Initialize the lookup array
initial begin
   $readmemh("reqFiles/recip.vmem", lookupArr);
end


//Always block that determines if the input is positive or negative and finds
//
always@(*) begin

  if(in1[15]) begin
    absValue <= ~in1 +1;
  end
  else begin
    absValue <= in1;
  end

end

//Find the number of leading zeros for the 2's complment value of input
lead0s findZeros(numZero, absValue);

always @(*) begin
  case (op)
    `OPadd: begin result = in1 + in2; end
    `OPand: begin result = in1 & in2; end
    `OPany: begin result = |in1; end
    `OPor: begin result = in1 | in2; end
    `OPshr: begin result = in1 >> 1; end
    `OPxor: begin result = in1 ^ in2; end
    //Floating point operations - Currently Under construction

    `OPf2i: begin
      //Get the exponent value
      //Subtract 127 from exponent
      //Shift fraction right by exponent value
      //normalize using leading 0s 
      //account for sign

      //looking for positve/negative/zero. Create three distinct cases 
     end

    `OPi2f: begin 
//TODO: How should ints be passed to i2f? 1.5 is 0x3fc0 after conversion 
//but what about before? 

      //Make positive, set sign :
      //If in1[15] then it's negative, so subtract num by 0x8000 to get pos val
      if(in1[15]) begin
        signBit =1; 
        //tempResult = ~in1 +1;
        tempResult = absValue;
      end 
      else begin
        signBit = 0;
        //tempResult = in1;
        tempResult = absValue;
      end

      //Assign value to a 24 bit buffer and pad with zeros
      valueNew = {tempResult, 8'b0};
      //Make a mantissa by indexing the buffer at 15-numzero +7 and 15-numzero
      mantissa = valueNew[((15-numZero)+7) -: 7];
      //mantissa = valueNew[((15-numZero)+8) -: 7];
      //Figure out exponent which is 142 - #zeros 
      expVal = (16'h7f + 15) - numZero;
      //cat all these parts together
      result = {signBit, expVal, mantissa};
     end

    `OPinvf: begin 
      //First set the sign bit like the other operations 
      if(in1[15]) begin
        signBit=1;
        tempResult = absValue;
      end
      else begin
        signBit=0;
        tempResult = absValue;
      end 

      //To find the mantissa, use a lookup table
      mantissa = lookupArr[absValue[6:0]][7:0];
      //$display("lookupValue: %x", lookupArr[2][7:0]);
      //Read the table into a 127 element array 

      //Need to determine the exponent based on the mantissa value
      if(!mantissa) begin 
        expVal = 254 - absValue[14:7];
      end
      else begin
        expVal = 253 - absValue[14:7];
      end

      //Finally, we set the result of the inverse based on whether the input
      //was 0 or not. For this assignment, we treat 1/0 as 0. 
      if(!absValue)begin
        result = 0;
      end 
      else begin
        result = {signBit, expVal, mantissa};
      end

     end
    
    `OPaddf: begin end
    `OPmulf: begin end
    default: begin result = in1; end
  endcase
end
endmodule

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD ir, srcval, dstval, newpc;
reg ifsquash, rrsquash;
wire `OP op;
wire `RNAME regdst;
wire `WORD res;
reg `OP s0op, s1op, s2op;
reg `RNAME s0src, s0dst, s0regdst, s1regdst, s2regdst;
reg `WORD pc;
reg `WORD s1srcval, s1dstval;
reg `WORD s2val;

always @(reset) begin
  halt = 0;
  pc = 0;
  s0op = `OPnop;
  s1op = `OPnop;
  s2op = `OPnop;
  //TODO: Store instructions here
  $readmemh("reqFiles/pipe0.vmem", regfile);
  //$readmemh("reqFiles/pipe1.vmem", mainmem);
  $readmemh("reqFiles/pipinv.vmem", mainmem);
end

decode mydecode(op, regdst, s0op, ir);
alu myalu(res, s1op, s1srcval, s1dstval);

always @(*) ir = mainmem[pc];

// compute srcval, with value forwarding... also from 2nd word of li
always @(*) if (s0op == `OPli) srcval = ir; // catch immediate for li
            else srcval = ((s1regdst && (s0src == s1regdst)) ? res :
                           ((s2regdst && (s0src == s2regdst)) ? s2val :
                            regfile[s0src]));

// compute dstval, with value forwarding
always @(*) dstval = ((s1regdst && (s0dst == s1regdst)) ? res :
                      ((s2regdst && (s0dst == s2regdst)) ? s2val :
                       regfile[s0dst]));

// new pc value
always @(*) newpc = (((s1op == `OPjz) && (s1dstval == 0)) ? s1srcval :
                     (pc + 1));

// IF squash? Only for jz... with 2-cycle delay if taken
always @(*) ifsquash = ((s1op == `OPjz) && (s1dstval == 0));

// RR squash? For both jz and sz... extra cycle allows sz to squash li
always @(*) rrsquash = (((s1op == `OPsz) || (s1op == `OPjz)) && (s1dstval == 0));


// Instruction Fetch
always @(posedge clk) if (!halt) begin
  s0op <= (ifsquash ? `OPnop : op);
  s0regdst <= (ifsquash ? 0 : regdst);
  s0src <= ir `Src;
  s0dst <= ir `Dest;
  pc <= newpc;
end

// Register Read
always @(posedge clk) if (!halt) begin
  s1op <= (rrsquash ? `OPnop : s0op);
  s1regdst <= (rrsquash ? 0 : s0regdst);
  s1srcval <= srcval;
  s1dstval <= dstval;
end

// ALU and data memory operations
always @(posedge clk) if (!halt) begin
  s2op <= s1op;
  s2regdst <= s1regdst;
  s2val <= ((s1op == `OPld) ? mainmem[s1srcval] : res);
  if (s1op == `OPst) mainmem[s1srcval] <= s1dstval;
  if (s1op == `OPsys) halt <= 1;
end

// Register Write
always @(posedge clk) if (!halt) begin
  if (s2regdst != 0) regfile[s2regdst] <= s2val;
end
endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
integer i = 0;
processor PE(halted, reset, clk);
initial begin
  $dumpfile("results.vcd");
  $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted && (i < 200)) begin
    #10 clk = 1;
    #10 clk = 0;
    i=i+1;
  end
  $finish;
end
endmodule

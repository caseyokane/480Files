// basic sizes of things
`define WORD	[15:0]
`define OP	[4:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]

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
reg `WORD tempResult; 
reg[23:0] valueNew;
reg signBit; reg[7:0] expVal; reg[6:0] mantissa;  
wire[4:0] numZero; 

//Instantiate the module to find the number of zeros 
lead0s findZeros(numZero, in1);

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

      //Make positive, set sign :
      //If in1[15] then it's negative, so subtract num by 0x8000 to get pos val
      if(in1[15]) begin
        signBit =1; 
        tempResult = 0 - in1;
      end 
      else begin
        signBit = 0;
        tempResult = in1;
      end

      //count leading zeros
      //Assign value to a 24 bit buffer and padde with zeros
      valueNew = {tempResult, 8'b0};
      
      //Make a mantissa
      mantissa = valueNew[((15-numZero)+8) -: 7];
    
      //Figure out exponent
      expVal = (16'h7f + 15) - numZero;
      //$display("numZero: %d", numZero);
      //cat all these parts together
      result = {signBit, expVal, mantissa};
      //$display(mantissa);
     end

    `OPinvf: begin end
    `OPaddf: begin end
    `OPmulf: begin end
    default: begin result = in1; end
  endcase
end
endmodule

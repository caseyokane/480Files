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

input wire[15:0] s;
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
reg[1:0] signBit;
reg[7:0] decodedExp; 
reg[7:0] expVal; 
reg[6:0]trail;
reg[7:0]trailSignif; 
wire[4:0] numZero; 

//Instantiate the module to find the number of zeros 
//TODO: Should I shift in1, so that it takes the trailing significand instead
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
      //TODO: Issues 
      /*Get the exponent value
      currExp = in1[14:7];
      //Subtract 127 from exponent
      expVal = currExp - 127;
      //Shift fraction right by exponent value
      shrFrac = in1[7:0] >> expVal; 
      //normalize using leading 0s 
      //account for sign
      result =  shrFrac >> numZero;
      */
     end

    `OPi2f: begin 
      //Make positive, set sign
      signBit = in1[15];
      //If in1[15] then it's negative, so subtract num by 0x8000 to get pos val
      if(in1[15] ==1) begin
        in1 = in1 - 0x8000;
      end 
      
      //Take the exponent and place into register
      expVal = in1[14:7];
      //Calculate the exponent value for the formula, with 127 bias and 8 precision
      decodedExp = expVal - 127 - 7;

      //set exponent to normalize result
      //once the significand is normalized, assign it to the specified register
      if(in1[6] ==1) begin
        trail = in1[6:0];
      end
      //If the most signficant bit isn't normalized, shift it based on the num 
      else begin
        //TODO: Shifting by a wire?
        //trail = in1[6:0] >> numZeros;
      end

      //Construct the significant trail
      trailSignif = {1'b1, trail};

      //$display("2**%x == %x\n", decodedExp, (2**decodedExp));
      $display("Decoded: %d, Result: %d", decodedExp,  2**decodedExp);
      //Use the provided formula to actually calculate the floating point result
      //TODO: Getting a 0 here? Assuming it has something to do with decodedExp 
      result = ( ((-1)**signBit) * (2**decodedExp) * (trailSignif));
     end

    `OPinvf: begin end
    `OPaddf: begin end
    `OPmulf: begin end
    default: begin result = in1; end
  endcase
end
endmodule

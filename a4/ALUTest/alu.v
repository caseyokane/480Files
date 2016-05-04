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
reg `WORD absValue; reg `WORD tempResult; 
reg[23:0] valueNew;
reg signBit; reg[7:0] expVal; reg[6:0] mantissa;  
wire[4:0] numZero; 
reg [7:0] lookupArr [0:127];

//For Mulf
reg[7:0] expVal1; reg[7:0] expVal2; reg[7:0] temexpVal;
reg[7:0] tem1; reg[7:0] tem2;
reg `WORD temV;

//For addF
reg `WORD smVal; reg `WORD bgVal; reg `WORD diff;
reg[8:0] smMant; reg[8:0] bgMant; reg[8:0] rsltMant;

//Initialize the lookup array
initial begin
   $readmemh("reqFiles/recip.vmem", lookupArr);
end


//Always block that determines if the input is positive or negative and finds
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
    
    //Floating point operations
    `OPf2i: begin
      
      //Check initial case that input is 0
      if(!in1) begin
        result = in1;
      end

      //If not zero, continue 
      else begin
        //Set the buffer to leading 1 bit followed by the mantissa 
        valueNew= {1'b1, in1[6:0]};

        //Check that the exponent value is positive (>=127)
        if(in1[14:7] >= 127) begin
          //Get the exponent value and subtract 127
          expVal = in1[14:7] - 127;
          //Shift using the exponent value with an offset of 1 to account for 
          //mantissa length
          valueNew = valueNew << (expVal +1);
          //set the result to the 16 most significant bits 
          result = valueNew[23:8];
        end

        //If the number is negative, take the 2's complement of the result 
        if(in1[15]) begin
          result = ~result +1;
        end

      end
     end

    `OPi2f: begin 

      //If in1[15] then it's negative, assign the 2's complement val calculated
      if(in1[15]) begin
        signBit =1; 
        tempResult = absValue;
      end 
      else begin
        signBit = 0;
        tempResult = absValue;
      end

      //Assign value to a 24 bit buffer and pad with zeros
      valueNew = {tempResult, 8'b0};
      //Make a mantissa by indexing the buffer at 15-numzero +7 and 15-numzero
      mantissa = valueNew[((15-numZero)+7) -: 7];
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
    
    `OPaddf: begin 
      
      //Check if the inputs are the same, first the exponent/mantissa
      if(in1[14:0] == in2[14:0]) begin 
        //If the sign isn't the same then the result is zero.
        if(in1[15] != in2[15]) begin
           result = 0; 
        end
      end
      //Check if either of the inputs is zero and set the result to the other if so
      else if(!in1) begin
        result = in2;
      end
      else if(!in2) begin
        result = in1;
      end

      //If above case isn't met, then enter the main loop
      else begin
        //find which input is greater by comparing exponents 
        if(in1[14:7] > in2[14:7]) begin
          bgVal = in1; smVal = in2;
        end
        else begin
          bgVal = in2; smVal =in1;
        end

        //assign mantissa values with a 2 bit offset 
        bgMant = {2'b00, bgVal[6:0]}; 
        smMant = {2'b00, smVal[6:0]};
        
        //find the difference between the larger and smaller input
        diff = bgVal - smVal;
        //Shift the smaller mantissa by this difference
        smMant = smMant >> diff; 
        
        //if inputs share the same sign then enter the next branch
        if(bgVal[15] == smVal[15]) begin
          //Add mantissas if same sign
          rsltMant = smMant + bgMant;
        end
        //If signs aren't the same subtract the mantissas
        else begin
          rsltMant = bgMant + smMant;
        end
        
        //set the sign bit
        signBit = bgVal[15];          
        //set the exponent value to that of the larger value's exponent with +1
        expVal = bgVal[14:7]+1;
        //Also account for offset in the resulting mantissa.
        mantissa = rsltMant[7:1];
        //Concatenate these values together to form result
        result = {signBit, expVal, mantissa};

        //Look at overflow/underflow and set to the max/min based on case
        //DDT: A lot of the addf portion might be incorrect other than cases at 
        //beginning 
      end

     end

    `OPmulf: begin 
      
      //find the sign by xoring signs of each input   
      signBit = in1[15]^in2[15];
      
      //Append 1 as top bit for both mantissas
      tem1 = {1'b1,in1[6:0]};
      tem2 = {1'b1,in1[6:0]};
      
  
      //Multiply these new mantissas
      temV = tem1*tem2;
     
      //Get the exponent values for the inputs 
      expVal1 = in1[14:7];
      expVal2 = in2[14:7];
      
      /*
      //Mantissa = new mantissa[13:6]
      if(temV[15])begin 
        temexpVal = 1; 
        mantissa[6:0] = temV[13:6];
        //mantissa[6:0] = temV[14:8];
      end
      
      else begin 
        temexpVal = 0; 
        mantissa[6:0] = temV[13:6]; 
        //mantissa[6:0] = temV[13:7]; 
      end
      */

      //mantissa = new mantissa[13:6]
      mantissa = temV[13:6];
      
      //add the exponents together and subtract the bias value
      expVal = expVal1 + expVal2 - 127;

      
      //Concatenate all values together
      result = {signBit,expVal,mantissa};
      
     end

    default: begin result = in1; end
  endcase
end
endmodule
